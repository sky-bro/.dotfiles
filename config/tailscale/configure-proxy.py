#!/usr/bin/env python3
"""Configure the Homebrew macOS daemon's proxy; dry run unless --apply."""
import argparse
import datetime
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile
import time
from urllib.parse import urlsplit


def unload(label):
    target = f'system/{label}'
    present = subprocess.run(['launchctl', 'print', target], capture_output=True)
    if present.returncode == 0:
        subprocess.run(['launchctl', 'bootout', target], check=True)
    # bootout returns before launchd has necessarily removed the job.
    deadline = time.monotonic() + 15
    while subprocess.run(['launchctl', 'print', target], capture_output=True).returncode == 0:
        if time.monotonic() >= deadline:
            raise RuntimeError(f'Timed out waiting for {label} to stop.')
        time.sleep(0.25)


def load(path):
    command = ['launchctl', 'bootstrap', 'system', str(path)]
    # launchd can still report EIO briefly after the job disappears from print.
    deadline = time.monotonic() + 10
    while True:
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode == 0:
            return
        if time.monotonic() >= deadline:
            raise RuntimeError(result.stderr.strip() or 'launchctl bootstrap failed.')
        time.sleep(0.5)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--proxy-url', default='http://127.0.0.1:7897',
                        help='Clash local HTTP proxy (default: %(default)s)')
    args = parser.parse_args()
    try:
        proxy = urlsplit(args.proxy_url)
        valid_proxy = (proxy.scheme == 'http' and proxy.hostname in
                       ('127.0.0.1', 'localhost', '::1') and proxy.port and
                       not proxy.username and not proxy.password and
                       proxy.path in ('', '/') and not proxy.query and not proxy.fragment)
    except ValueError:
        valid_proxy = False
    if not valid_proxy:
        parser.error('--proxy-url must be a local HTTP proxy URL with a port and no credentials.')
    candidates = [Path('/Library/LaunchDaemons') / name for name in
                  ('sh.brew.tailscale.plist', 'homebrew.mxcl.tailscale.plist')]
    existing = [path for path in candidates if path.exists()]
    if len(existing) != 1:
        parser.error('Expected exactly one Homebrew system service; start it with sudo brew services start tailscale.')
    path = existing[0]
    original = path.read_bytes()
    config = plistlib.loads(original)
    commands = config.get('ProgramArguments') or []
    executables = [f'{prefix}/opt/tailscale/bin/tailscaled'
                   for prefix in ('/opt/homebrew', '/usr/local')]
    if not commands or commands[0] not in executables or config.get('Label') != path.stem:
        parser.error('Unexpected daemon executable; inspect the service manually.')
    desired = {'HTTP_PROXY': args.proxy_url,
               'HTTPS_PROXY': args.proxy_url,
               'NO_PROXY': 'localhost,127.0.0.1,::1'}
    environment = config.setdefault('EnvironmentVariables', {})
    changes = [key for key, value in desired.items() if environment.get(key) != value]
    if not changes:
        print('Proxy configuration already matches.')
        if args.apply:
            if os.geteuid() != 0:
                parser.error('--apply requires sudo in a real terminal.')
            label = config['Label']
            if subprocess.run(['launchctl', 'print', f'system/{label}'], capture_output=True).returncode:
                load(path)
                print(f'Started {label}.')
        return
    for key in changes:
        print(f'Set {key}={desired[key]}')
    if not args.apply:
        print('Dry run. Use sudo /usr/bin/python3 config/tailscale/configure-proxy.py --apply.')
        return
    if os.geteuid() != 0:
        parser.error('--apply requires sudo in a real terminal.')
    environment.update(desired)
    backup_dir = Path('/Library/Application Support/dotfiles/tailscale-backups')
    backup_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
    backup = backup_dir / f'{path.name}.{stamp}.backup'
    shutil.copy2(path, backup)
    metadata = path.stat()
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix='.tailscale-proxy-')
    try:
        with os.fdopen(fd, 'wb') as stream:
            plistlib.dump(config, stream)
        os.chmod(temporary, metadata.st_mode & 0o777)
        os.chown(temporary, metadata.st_uid, metadata.st_gid)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    label = config['Label']
    try:
        unload(label)
        load(path)
    except (subprocess.CalledProcessError, RuntimeError) as error:
        shutil.copy2(backup, path)
        try:
            unload(label)
            load(path)
        except (subprocess.CalledProcessError, RuntimeError) as recovery_error:
            parser.exit(1, f'Apply failed: {error}\nOriginal plist restored, but service restart failed: {recovery_error}\nBackup: {backup}\n')
        parser.exit(1, f'Apply failed: {error}\nOriginal configuration restored and service restarted. Backup: {backup}\n')
    print(f'Applied and restarted {label}. Backup: {backup}')


if __name__ == '__main__':
    main()
