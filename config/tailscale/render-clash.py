#!/usr/bin/env python3
"""Render the Clash extension for the current Mac; only prints public config."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys


def render(status, route, interface):
    if status.get('BackendState') != 'Running':
        raise ValueError('Log in first: sudo tailscale up --timeout=30s')
    match = re.search(r'^\s*interface:\s*(utun\d+)\s*$', route, re.MULTILINE)
    if not match:
        raise ValueError('No Tailscale subnet route. Run sudo tailscale set --accept-routes=true.')
    addresses = re.findall(r'^\s*inet6?\s+(\S+)', interface, re.MULTILINE)
    addresses = {address.split('%')[0] for address in addresses}
    if not addresses.intersection(status.get('TailscaleIPs', [])):
        raise ValueError('The home subnet route is not on a Tailscale interface. Enable accepted routes first.')
    suffix = status.get('MagicDNSSuffix', '').rstrip('.')
    if not re.fullmatch(r'[a-zA-Z0-9.-]+\.ts\.net', suffix):
        raise ValueError('No valid Tailscale MagicDNS suffix found.')
    template = Path(__file__).with_name('clash-verge.js').read_text()
    return template.replace('"__TAILSCALE_INTERFACE__"', json.dumps(match[1])).replace(
        '"__MAGIC_DNS_SUFFIX__"', json.dumps(suffix))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, help='Write a file instead of stdout')
    args = parser.parse_args()
    executable = shutil.which('tailscale')
    if not executable:
        parser.error('Install the Homebrew tailscale formula first.')
    try:
        status = json.loads(subprocess.check_output([executable, 'status', '--json'], text=True, timeout=10))
        route = subprocess.check_output(['/sbin/route', '-n', 'get', '192.168.31.2'], text=True, timeout=5)
        match = re.search(r'^\s*interface:\s*(utun\d+)\s*$', route, re.MULTILINE)
        if not match:
            raise ValueError('Enable subnet routes: sudo tailscale set --accept-routes=true')
        interface = subprocess.check_output(['/sbin/ifconfig', match[1]], text=True, timeout=5)
        script = render(status, route, interface)
        if args.output:
            args.output.write_text(script)
            print(f'Generated {args.output} for {match[1]}.', file=sys.stderr)
        else:
            print(script, end='')
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
