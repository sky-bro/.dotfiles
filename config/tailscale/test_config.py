"""Offline checks for reusable macOS Tailscale configuration."""
import contextlib
import io
import importlib.util
import plistlib
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

def module(filename):
    spec = importlib.util.spec_from_file_location(filename, Path(__file__).with_name(filename))
    result = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(result)
    return result


proxy = module('configure-proxy.py')
renderer = module('render-clash.py')


class ConfigurationTests(unittest.TestCase):
    def test_different_computer(self):
        script = renderer.render(
            {'BackendState': 'Running', 'TailscaleIPs': ['100.70.1.2'],
             'MagicDNSSuffix': 'tail12345.ts.net'},
            '    interface: utun3\n', '    inet 100.70.1.2 --> 100.70.1.2\n')
        self.assertIn('"utun3"', script)
        self.assertIn('"tail12345.ts.net"', script)
        self.assertNotIn('__TAILSCALE_INTERFACE__', script)

    def test_clash_interface_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'not on a Tailscale interface'):
            renderer.render(
                {'BackendState': 'Running', 'TailscaleIPs': ['100.70.1.2']},
                'interface: utun6\n', 'inet 198.18.0.1\n')

    def test_logged_out_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'Log in first'):
            renderer.render({'BackendState': 'NeedsLogin'}, '', '')

    def test_intel_service_and_custom_port_dry_run(self):
        with tempfile.TemporaryDirectory() as folder:
            directory = Path(folder)
            service = directory / 'sh.brew.tailscale.plist'
            original = plistlib.dumps({
                'Label': service.stem,
                'ProgramArguments': ['/usr/local/opt/tailscale/bin/tailscaled'],
                'EnvironmentVariables': {'EXISTING': 'preserved'},
            })
            service.write_bytes(original)
            output = io.StringIO()
            with patch.object(proxy, 'Path', return_value=directory), \
                 patch('sys.argv', ['configure-proxy.py', '--proxy-url', 'http://127.0.0.1:7890']), \
                 patch.object(proxy.subprocess, 'run') as run, contextlib.redirect_stdout(output):
                proxy.main()
            self.assertEqual(service.read_bytes(), original)
            run.assert_not_called()
            self.assertIn('HTTPS_PROXY=http://127.0.0.1:7890', output.getvalue())

    def test_waits_for_old_service_to_disappear(self):
        def result(code):
            return subprocess.CompletedProcess([], code)
        with patch.object(proxy.subprocess, 'run', side_effect=[
                result(0), result(0), result(0), result(113)]) as run, \
             patch.object(proxy.time, 'sleep') as sleep:
            proxy.unload('sh.brew.tailscale')
        self.assertEqual(run.call_count, 4)
        sleep.assert_called_once_with(0.25)


if __name__ == '__main__':
    unittest.main()
