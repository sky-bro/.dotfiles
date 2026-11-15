"""Offline checks for reusable macOS Tailscale configuration."""
import contextlib
import io
import importlib.util
import json
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
travel = module('travel.py')


class ConfigurationTests(unittest.TestCase):
    def test_travel_preserves_custom_configuration_and_is_idempotent(self):
        original = {'proxies': [{'name': 'my-proxy', 'type': 'direct'},
                                {'name': 'TAILSCALE-LAN', 'type': 'direct', 'interface-name': 'utun7'}],
                    'rules': ['DOMAIN,example.com,my-proxy'],
                    'dns': {'nameserver-policy': {'+.example.com': '1.1.1.1'}},
                    'tun': {'route-exclude-address': ['10.1.0.0/16']}}
        updated = travel.configure(original, 'utun0', 'tail12345.ts.net')
        self.assertEqual(original['proxies'][1]['interface-name'], 'utun7')
        self.assertEqual(updated['proxies'][-1]['interface-name'], 'utun0')
        self.assertIn('DOMAIN,example.com,my-proxy', updated['rules'])
        self.assertEqual(updated['dns']['nameserver-policy']['+.example.com'], '1.1.1.1')
        self.assertIn('10.1.0.0/16', updated['tun']['route-exclude-address'])
        self.assertEqual(updated, travel.configure(updated, 'utun0', 'tail12345.ts.net'))

    def test_managed_wrapper_retains_custom_main_and_refreshes_interface(self):
        custom = 'function main(config) { config.custom = "preserved"; return config; }\n'
        script = travel.extension(custom, 'utun7', 'tail12345.ts.net')
        script = travel.extension(script, 'utun0', 'tail12345.ts.net')
        self.assertEqual(script.count(travel.BEGIN), 1)
        self.assertIn(custom.strip(), script)
        self.assertNotIn('"utun7"', script)
        js = script + '\nprocess.stdout.write(JSON.stringify(main({})));'
        result = subprocess.run(['node', '-e', js], capture_output=True, text=True, check=True)
        self.assertEqual(json.loads(result.stdout),
                         travel.configure({'custom': 'preserved'}, 'utun0', 'tail12345.ts.net'))

    def test_invalid_or_incomplete_managed_script_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'markers'):
            travel.extension('function main(c) {return c;}\n' + travel.BEGIN,
                             'utun0', 'tail12345.ts.net')

    def test_installed_symlink_finds_repository_template(self):
        with tempfile.TemporaryDirectory() as folder:
            link = Path(folder) / 'tailscale-travel'
            link.symlink_to(Path(travel.__file__).resolve())
            with patch.object(travel, '__file__', str(link)):
                script = travel.extension('function main(c) { return c; }',
                                          'utun0', 'tail12345.ts.net')
            self.assertIn('"utun0"', script)

    def test_foreign_fake_ip_filter_mode_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'blacklist'):
            travel.configure({'dns': {'fake-ip-filter-mode': 'whitelist'}},
                             'utun0', 'tail12345.ts.net')

    def test_failed_route_restore_reenables_route_acceptance(self):
        with patch.object(travel, 'command', side_effect=['', RuntimeError('failed')]), \
             patch.object(travel.subprocess, 'run') as run:
            with self.assertRaisesRegex(RuntimeError, 'failed'):
                travel.restore_routes('tailscale', 'utun0')
        self.assertIn('--accept-routes=true', run.call_args.args[0])

    def test_stale_controller_socket_does_not_hide_custom_socket(self):
        with tempfile.TemporaryDirectory() as folder:
            app = Path(folder)
            (app / 'config.yaml').write_text(json.dumps({'external-controller-unix': '/working.sock'}))
            def controller(path, secret):
                result = unittest.mock.Mock()
                if str(path) != '/working.sock':
                    result.request.side_effect = OSError('stale socket')
                return result
            with patch.object(travel.Path, 'exists', return_value=True), \
                 patch.object(travel, 'Controller', side_effect=controller) as create:
                travel.find_controller({'secret': 'synthetic-secret', 'external-controller-unix': '/stale.sock'}, app)
            self.assertEqual(str(create.call_args.args[0]), '/working.sock')

    def test_failed_reload_restores_files_and_live_mode_and_tun(self):
        with tempfile.TemporaryDirectory() as folder:
            app = Path(folder)
            (app / 'profiles').mkdir()
            config = {'mode': 'rule', 'tun': {'enable': False}, 'custom': 'preserved'}
            original = json.dumps(config).encode()
            script = b'function main(config) { return config; }\n'
            (app / 'clash-verge.yaml').write_bytes(original)
            (app / 'profiles/Script.js').write_bytes(script)
            calls = []
            def request(method, endpoint, data=None):
                if method == 'GET':
                    return {'mode': 'global', 'tun': {'enable': True}}
                if method == 'PUT':
                    calls.append(json.loads(data['payload']))
                    if len(calls) == 1:
                        raise RuntimeError('synthetic reload rejection')
            controller = unittest.mock.Mock(request=request)
            def command(args, **kwargs):
                return json.dumps({'BackendState': 'Running'}) if 'status' in args else ''
            with patch.object(travel, 'APP_DIR', app), \
                 patch.object(travel.Path, 'home', return_value=app), \
                 patch.object(travel.shutil, 'which', return_value='tailscale'), \
                 patch.object(travel.sys, 'platform', 'darwin'), \
                 patch.object(travel, 'command', side_effect=command), \
                 patch.object(travel, 'find_controller', return_value=controller), \
                 patch.object(travel, 'tailscale_identity', return_value=('utun0', 'tail12345.ts.net')), \
                 patch.object(travel, 'interface_for', return_value='utun0'), \
                 patch('sys.argv', ['tailscale-travel']), \
                 contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                with self.assertRaises(SystemExit) as error:
                    travel.main()
            self.assertEqual(error.exception.code, 1)
            self.assertEqual((app / 'clash-verge.yaml').read_bytes(), original)
            self.assertEqual((app / 'profiles/Script.js').read_bytes(), script)
            self.assertEqual(calls[1], {**config, 'mode': 'global', 'tun': {'enable': True}})

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
