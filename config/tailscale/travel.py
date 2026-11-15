#!/usr/bin/env python3
"""Repair the Mac's Tailscale/Clash travel setup; --check only inspects it."""
import argparse
import copy
import datetime
import http.client
import ipaddress
import json
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time


APP_DIR = Path.home() / 'Library/Application Support/io.github.clash-verge-rev.clash-verge-rev'
NETWORKS = ['192.168.31.0/24', '192.168.5.0/24', '100.64.0.0/10', 'fd7a:115c:a1e0::/48']
LAN = 'TAILSCALE-LAN'
BEGIN = '// BEGIN dotfiles tailscale-travel (managed)'
END = '// END dotfiles tailscale-travel (managed)'


def command(args, timeout=15):
    result = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if result.returncode:
        # Do not echo command output: a daemon or proxy can include credentials.
        raise RuntimeError(f'{Path(args[0]).name} {args[1]} failed (exit {result.returncode}).')
    return result.stdout


def read_yaml(path):
    text = path.read_text()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        # macOS ships Ruby/Psych; no pip, Homebrew or third-party YAML install.
        result = subprocess.run([
            '/usr/bin/ruby', '-ryaml', '-rjson', '-e',
            'puts JSON.generate(YAML.safe_load(STDIN.read, aliases: true))',
        ], input=text, capture_output=True, text=True, timeout=10)
        if result.returncode:
            raise RuntimeError(f'Cannot safely parse {path.name}.')
        return json.loads(result.stdout)


class Controller:
    def __init__(self, path, secret=''):
        self.path = str(path)
        self.secret = secret

    def request(self, method, endpoint, data=None):
        connection = http.client.HTTPConnection('localhost', timeout=20)
        sock = socket.socket(socket.AF_UNIX)
        sock.settimeout(20)
        try:
            sock.connect(self.path)
            connection.sock = sock
            headers = {'Content-Type': 'application/json'}
            if self.secret:
                headers['Authorization'] = f'Bearer {self.secret}'
            connection.request(method, endpoint,
                               None if data is None else json.dumps(data), headers)
            response = connection.getresponse()
            body = response.read()
            if response.status >= 300:
                raise RuntimeError(f'Clash {method} {endpoint}: HTTP {response.status}.')
            return json.loads(body) if body else None
        finally:
            connection.close()
            sock.close()


def find_controller(config, app_dir=APP_DIR):
    paths = [Path(f'/var/run/clash-verge-service/users/{os.getuid()}/verge-mihomo.sock')]
    for settings in (config, read_yaml(app_dir / 'config.yaml')):
        if settings.get('external-controller-unix'):
            paths.append(Path(settings['external-controller-unix']))
    for path in paths:
        if path.exists():
            controller = Controller(path, config.get('secret', ''))
            try:
                controller.request('GET', '/version')
                return controller
            except (OSError, RuntimeError, http.client.HTTPException):
                # A stale service socket must not hide a working custom socket.
                continue
    raise RuntimeError('Open Clash Verge and wait for its core to start, then retry.')


def interface_for(address):
    route = command(['/sbin/route', '-n', 'get', address], timeout=5)
    match = re.search(r'^\s*interface:\s*(\S+)\s*$', route, re.MULTILINE)
    return match[1] if match else ''


def tailscale_identity(status):
    interface = interface_for('100.100.100.100')
    if not re.fullmatch(r'utun\d+', interface):
        raise RuntimeError('No Tailscale interface; start Tailscale first.')
    addresses = command(['/sbin/ifconfig', interface])
    ips = {x.split('%')[0] for x in re.findall(r'^\s*inet6?\s+(\S+)', addresses, re.MULTILINE)}
    if not ips.intersection(status.get('TailscaleIPs', [])):
        raise RuntimeError('The MagicDNS route is not on a Tailscale interface.')
    suffix = status.get('MagicDNSSuffix', '').rstrip('.')
    if not re.fullmatch(r'[a-zA-Z0-9.-]+\.ts\.net', suffix):
        raise RuntimeError('No valid Tailscale MagicDNS suffix.')
    return interface, suffix


def configure(config, interface, suffix):
    result = copy.deepcopy(config)
    dns = result.setdefault('dns', {})
    if dns.get('fake-ip-filter-mode', 'blacklist') != 'blacklist':
        raise RuntimeError('Expected fake-ip-filter-mode: blacklist; merge this configuration manually.')
    result['proxies'] = [p for p in result.get('proxies', []) if p.get('name') != LAN]
    result['proxies'].append({'name': LAN, 'type': 'direct', 'interface-name': interface})
    tun = result.setdefault('tun', {})
    tun['route-exclude-address'] = list(dict.fromkeys(tun.get('route-exclude-address', []) + NETWORKS))
    dns['fake-ip-filter'] = list(dict.fromkeys(
        dns.get('fake-ip-filter', ['*.lan', '*.local', '*.arpa']) + ['+.home.k4i.top', f'+.{suffix}']))
    dns.setdefault('nameserver-policy', {}).update({
        '+.home.k4i.top': f'udp://192.168.31.2:53#{LAN}',
        f'+.{suffix}': f'udp://100.100.100.100:53#{LAN}',
    })
    rules = [f'DOMAIN-SUFFIX,home.k4i.top,{LAN}', f'DOMAIN-SUFFIX,{suffix},{LAN}']
    rules += [f'{"IP-CIDR6" if ":" in net else "IP-CIDR"},{net},{LAN},no-resolve' for net in NETWORKS]
    result['rules'] = rules + [r for r in result.get('rules', []) if r not in rules]
    return result


def live_settings(config, running):
    """Retain GUI mode/TUN state in both apply and rollback payloads."""
    result = copy.deepcopy(config)
    result['mode'] = running['mode']
    result.setdefault('tun', {})['enable'] = running.get('tun', {}).get('enable', False)
    return result


def extension(existing, interface, suffix):
    if BEGIN in existing or END in existing:
        pattern = rf'\n?{re.escape(BEGIN)}\n.*?\n{re.escape(END)}\n?'
        existing, count = re.subn(pattern, '', existing, flags=re.DOTALL)
        if count != 1 or BEGIN in existing or END in existing:
            raise RuntimeError('Unrecognized managed script markers; inspect Script.js manually.')
    if not re.search(r'\bfunction\s+main\s*\(', existing):
        raise RuntimeError('Global Script.js must define function main(config).')
    template = Path(__file__).resolve().with_name('clash-verge.js').read_text()
    generated = template.replace('"__TAILSCALE_INTERFACE__"', json.dumps(interface)).replace(
        '"__MAGIC_DNS_SUFFIX__"', json.dumps(suffix))
    # Run the user's existing main first, then apply our overlay. A later run
    # replaces just this marked block, preserving all original custom logic.
    return existing.rstrip() + '\n\n' + BEGIN + '''
{
  const previousMain = main;
  const applyTailscale = (() => {
''' + generated + '''
    return main;
  })();
  main = function(config, ...args) {
    return applyTailscale(previousMain(config, ...args));
  };
}
''' + END + '\n'


def write_atomic(path, content):
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=f'.{path.name}.')
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(content)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def restore_routes(executable, interface):
    command([executable, 'set', '--accept-routes=false'])
    try:
        command([executable, 'set', '--accept-routes=true', '--accept-dns=true', '--exit-node='])
    except Exception:
        # Always try to restore route acceptance if the second call failed.
        subprocess.run([executable, 'set', '--accept-routes=true'], capture_output=True, timeout=15)
        raise
    for _ in range(10):
        if all(interface_for(ip) == interface for ip in ['192.168.31.2', '192.168.31.248', '192.168.5.1']):
            return
        time.sleep(0.3)
    raise RuntimeError('Home subnet routes were not installed; check route approval in Tailscale admin.')


def verify(port):
    failed = []
    jobs = [
        ('Home DNS', ['dig', '+time=4', '+tries=1', '+short', '@192.168.31.2', 'flame.nas.home.k4i.top']),
        ('Split DNS', ['dig', '+time=4', '+tries=1', '+short', '@100.100.100.100', 'flame.nas.home.k4i.top']),
    ]
    for label, cmd in jobs:
        try:
            output = command(cmd)
            if '192.168.31.248' not in output.split():
                raise RuntimeError('unexpected DNS answer')
            print(f'OK {label}: 192.168.31.248')
        except (RuntimeError, subprocess.TimeoutExpired):
            failed.append(label)
            print(f'FAIL {label}')
    for label, url, proxy in [
        ('Home HTTPS direct', 'https://flame.nas.home.k4i.top/', False),
        ('Home HTTPS via Clash', 'https://flame.nas.home.k4i.top/', True),
        ('Public HTTPS via Clash', 'https://www.google.com/', True),
    ]:
        cmd = ['curl', '-sS', '-L', '-o', '/dev/null', '-w', '%{http_code}',
               '--connect-timeout', '5', '--max-time', '20']
        cmd += ['--proxy', f'http://127.0.0.1:{port}'] if proxy else ['--noproxy', '*']
        try:
            code = command(cmd + [url], timeout=25).strip()
            if code != '200':
                raise RuntimeError('unexpected HTTP status')
            print(f'OK {label}: HTTP {code}')
        except (RuntimeError, subprocess.TimeoutExpired):
            failed.append(label)
            print(f'FAIL {label}')
    if failed:
        raise RuntimeError('Applied, but verification failed: ' + ', '.join(failed))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Read-only inspection; do not repair')
    args = parser.parse_args()
    if sys.platform != 'darwin':
        parser.error('This command supports macOS with Homebrew Tailscale and Clash Verge Rev.')
    executable = shutil.which('tailscale')
    if not executable:
        parser.error('Install the Homebrew tailscale formula first.')
    try:
        # Refuse travel mode on the actual home LAN; leave that route direct.
        local = command(['/sbin/ifconfig'])
        for ip in re.findall(r'^\s*inet\s+(\S+)', local, re.MULTILINE):
            if any(ipaddress.ip_address(ip) in ipaddress.ip_network(net) for net in NETWORKS[:2]):
                raise RuntimeError('Connected to the home LAN. Follow the home-mode steps in docs/TAILSCALE.md.')
        source = APP_DIR / 'clash-verge.yaml'
        script_path = APP_DIR / 'profiles/Script.js'
        original_config = source.read_bytes()
        original_script = script_path.read_bytes()
        config = read_yaml(source)
        controller = find_controller(config)
        running = controller.request('GET', '/configs')
        status = json.loads(command([executable, 'status', '--json']))
        if not args.check:
            command([executable, 'set', '--accept-routes=true', '--accept-dns=true', '--exit-node='])
            if status.get('BackendState') != 'Running':
                command([executable, 'up', '--timeout=30s'], timeout=35)
                status = json.loads(command([executable, 'status', '--json']))
        if status.get('BackendState') != 'Running':
            raise RuntimeError('Tailscale is stopped or needs login; run tailscale up in your terminal.')
        interface, suffix = tailscale_identity(status)
        configured_interface = next((p.get('interface-name') for p in config.get('proxies', []) if p.get('name') == LAN), None)
        print(f'Tailscale: {interface}; saved Clash binding: {configured_interface}')
        routes_ok = True
        for ip in ['192.168.31.2', '192.168.31.248', '192.168.5.1']:
            actual = interface_for(ip)
            routes_ok = routes_ok and actual == interface
            print(f'Route {ip}: {actual}')
        if args.check:
            if configured_interface != interface or not routes_ok:
                raise RuntimeError('Repair needed: run tailscale-travel without --check.')
            return
        updated = live_settings(configure(config, interface, suffix), running)
        new_script = extension(original_script.decode(), interface, suffix).encode()
        stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
        backup = Path.home() / '.local/state/dotfiles-backups' / f'{stamp}-tailscale-travel'
        backup.mkdir(parents=True, mode=0o700)
        write_atomic(backup / 'clash-verge.yaml', original_config)
        write_atomic(backup / 'Script.js', original_script)
        print(f'Backup: {backup}')
        try:
            controller.request('PATCH', '/configs', {'tun': {'enable': False}})
            write_atomic(script_path, new_script)
            write_atomic(source, (json.dumps(updated, indent=2, ensure_ascii=False) + '\n').encode())
            controller.request('PUT', '/configs?force=true', {'payload': json.dumps(updated)})
        except Exception:
            write_atomic(script_path, original_script)
            write_atomic(source, original_config)
            try:
                restored = live_settings(config, running)
                controller.request('PUT', '/configs?force=true', {'payload': json.dumps(restored)})
            except Exception:
                print('Clash rollback reload failed; restart Clash Verge. Saved files were restored.', file=sys.stderr)
            raise
        # TUN recreation can remove an overlapping route: reinstall AFTER it.
        restore_routes(executable, interface)
        controller.request('POST', '/cache/dns/flush')
        print(f'Clash binding refreshed: {interface}; home routes restored.')
        verify(running.get('mixed-port') or 7897)
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired, http.client.HTTPException) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
