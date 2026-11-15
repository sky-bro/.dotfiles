"""The shell entrypoint only dispatches; domain behavior lives in the shared CLI."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name('passmenu.sh')
class EntrypointTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / 'bin'
        self.bin.mkdir()
        self.log = self.home / 'calls.json'
        self.bundle = self.home / '.local/share/vicinae/extensions/pass-passwords/assets/pass-cli.cjs'
        self.bundle.parent.mkdir(parents=True)
        self.bundle.touch()
        program = f'#!{sys.executable}\n' + 'import json, os, pathlib, sys\npathlib.Path(os.environ["TEST_LOG"]).write_text(json.dumps([pathlib.Path(sys.argv[0]).name, *sys.argv[1:]]))\n'
        for name in ('node', 'vicinae'):
            file = self.bin / name
            file.write_text(program)
            file.chmod(0o755)
        self.env = {**os.environ, 'HOME': str(self.home), 'PATH': f'{self.bin}:{os.environ["PATH"]}', 'TEST_LOG': str(self.log)}
    def run_cli(self, *args):
        return subprocess.run(['/bin/bash', str(SCRIPT), *args], env=self.env, capture_output=True, text=True, timeout=5)
    def test_default_opens_native_command(self):
        self.assertEqual(self.run_cli().returncode, 0)
        self.assertEqual(json.loads(self.log.read_text()), ['vicinae', 'cmd', 'launch', '@sky-bro/pass-passwords:passwords'])
    def test_list_uses_bundled_shared_backend(self):
        self.assertEqual(self.run_cli('--list').returncode, 0)
        self.assertEqual(json.loads(self.log.read_text()), ['node', str(self.bundle), '--list'])
    def test_copy_forwards_name_literally(self):
        name = '-site/space $(touch SHOULD_NOT_EXIST)'
        self.assertEqual(self.run_cli('--copy', name).returncode, 0)
        self.assertEqual(json.loads(self.log.read_text()), ['node', str(self.bundle), '--copy', name])
        self.assertFalse((self.home / 'SHOULD_NOT_EXIST').exists())
    def test_missing_bundle_is_actionable(self):
        self.bundle.unlink()
        result = self.run_cli('--list')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Build the Passwords extension', result.stderr)
        self.assertFalse(self.log.exists())
if __name__ == '__main__':
    unittest.main()
