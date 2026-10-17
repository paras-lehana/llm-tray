"""Behavior tests use synthetic endpoints and disposable child processes only."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.name == 'nt', 'PowerShell backend targets Windows')
class BackendTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='llm-tray-test-')
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)

    def ps(self, code, *, ok=True):
        path = self.folder/'run.ps1'
        path.write_text("$ErrorActionPreference='Stop'\n. '"+str(ROOT/'src'/'Backend.ps1')+"'\n"+code, encoding='utf-8-sig')
        result = subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(path)], capture_output=True, text=True, timeout=30)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result.stdout.strip()+result.stderr.strip()

    def endpoint(self, *, sleeping=False, other=False, ollama=False):
        state = {'loaded': not sleeping, 'calls': [], 'installed': True}
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args): pass
            def do_GET(self):
                state['calls'].append(self.path)
                if self.path == '/props':
                    body = {'model_alias': 'foreign' if other else 'fixture', 'is_sleeping': not state['loaded']}
                elif self.path in ('/api/ps', '/api/tags'):
                    body = {'models': [{'name': 'fixture', 'model': 'fixture'}] if (state['installed'] if self.path.endswith('tags') else state['loaded']) else []}
                else:
                    self.send_error(404); return
                self.send_response(200); self.send_header('Content-Type', 'application/json'); self.end_headers(); self.wfile.write(json.dumps(body).encode())
            def do_POST(self):
                data = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                state['calls'].append((self.path, data))
                state['loaded'] = data.get('keep_alive') != 0
                self.send_response(200); self.send_header('Content-Type', 'application/json'); self.end_headers(); self.wfile.write(b'{}')
        server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        profile = self.folder/'profile.ini'
        profile.write_text('[model]\nname=Fixture\nbackend='+('ollama' if ollama else 'llama')+'\nstatus='+('ollama' if ollama else 'llama')+f'\nendpoint=http://127.0.0.1:{server.server_port}\nmodel_id=fixture\nexecutable=powershell.exe\n', encoding='utf8')
        return profile, state

    def test_external_endpoint_rejected(self):
        p, _ = self.endpoint()
        p.write_text(p.read_text().replace('127.0.0.1', 'example.com'))
        self.assertIn('loopback', self.ps(f"Read-ModelProfile '{p}'", ok=False))

    def test_passive_sleep_status_does_not_wake(self):
        p, state = self.endpoint(sleeping=True)
        self.assertEqual(self.ps(f"Get-ModelState (Read-ModelProfile '{p}')"), 'Sleeping')
        self.assertFalse(state['loaded'])
        self.assertEqual(state['calls'], ['/props'])

    def test_wake_uses_empty_tokenize(self):
        p, state = self.endpoint(sleeping=True)
        self.assertEqual(self.ps(f"Invoke-ModelAction (Read-ModelProfile '{p}') Start '{self.folder}'"), 'Ready')
        self.assertIn(('/tokenize', {'content': ''}), state['calls'])

    def test_foreign_model_refuses_action(self):
        p, state = self.endpoint(other=True)
        self.assertIn('Other model', self.ps(f"Invoke-ModelAction (Read-ModelProfile '{p}') Stop '{self.folder}'", ok=False))
        self.assertEqual(state['calls'], ['/props'])

    def test_unowned_server_refuses_stop(self):
        p, state = self.endpoint()
        self.assertIn('did not start', self.ps(f"Invoke-ModelAction (Read-ModelProfile '{p}') Stop '{self.folder}'", ok=False))
        self.assertTrue(state['loaded'])

    def test_stale_receipt_refuses_live_pid(self):
        p, _ = self.endpoint()
        code = f"""$profile=Read-ModelProfile '{p}'
$profile.executable=(Get-Process -Id $PID).Path
@{{pid=$PID;executable=$profile.executable;start_ticks='1';endpoint=$profile.endpoint;model_id='fixture'}}|ConvertTo-Json|Set-Content '{self.folder/'process.json'}'
Get-OwnedServer '{self.folder/'process.json'}' $profile
"""
        self.assertIn('identity differs', self.ps(code, ok=False))

    def test_ollama_unloads_only_selected_model(self):
        p, state = self.endpoint(ollama=True)
        self.assertEqual(self.ps(f"Invoke-ModelAction (Read-ModelProfile '{p}') Stop '{self.folder}'"), 'Unloaded')
        self.assertIn(('/api/generate', {'model': 'fixture', 'prompt': '', 'stream': False, 'keep_alive': 0}), state['calls'])

    def test_ollama_load_requires_installed_weights(self):
        p, state = self.endpoint(ollama=True, sleeping=True)
        state['installed'] = False
        self.assertIn('not installed', self.ps(f"Invoke-ModelAction (Read-ModelProfile '{p}') Start '{self.folder}'", ok=False))
        self.assertTrue(all(isinstance(x, str) for x in state['calls']))

    def test_custom_success_and_exit_failure(self):
        good, bad = self.folder/'good.ps1', self.folder/'bad.ps1'
        good.write_text('exit 0'); bad.write_text('exit 17')
        for path, expected in [(good, True), (bad, False)]:
            result = self.ps(f"Invoke-CustomScript '{path}' @{{_base='{self.folder}'}} '{self.folder}'", ok=expected)
            if not expected: self.assertIn('exit 17', result)

    def test_custom_path_with_spaces(self):
        path = self.folder/'my action.ps1'; marker = self.folder/'marker.txt'
        path.write_text(f"'done' | Set-Content -LiteralPath '{marker}'\nexit 0")
        self.ps(f"Invoke-CustomScript '{path}' @{{_base='{self.folder}'}} '{self.folder}'")
        self.assertEqual(marker.read_text().strip(), 'done')

    def test_occupied_port_detected_without_stopping_service(self):
        p, _ = self.endpoint()
        self.assertEqual(self.ps(f"$p=Read-ModelProfile '{p}'; Test-PortFree ([Uri]$p.endpoint)"), 'False')

    def test_extra_arguments_cannot_replace_listener(self):
        model = self.folder/'file.gguf'; model.write_bytes(b'fixture')
        extra = self.folder/'args.json'; extra.write_text('["--host=0.0.0.0"]')
        code=f"Get-LlamaArguments @{{model_path='{model}';_base='{self.folder}';gpu_layers='0';context_size='8192';idle_seconds='1800';endpoint='http://127.0.0.1:8080';model_id='fixture';extra_args_file='{extra}'}}"
        self.assertIn('cannot replace', self.ps(code, ok=False))

    def test_owned_unresponsive_child_can_still_be_stopped(self):
        code=f"""$exe=(Get-Process -Id $PID).Path
$child=Start-Process -FilePath $exe -ArgumentList '-NoProfile -NonInteractive -Command Start-Sleep -Seconds 120' -WindowStyle Hidden -PassThru
$null=$child.Handle
try {{
 $profile=@{{backend='llama';status='llama';endpoint='http://127.0.0.1:1';model_id='fixture';executable=$exe;_base='{self.folder}'}}
 @{{pid=$child.Id;executable=$exe;start_ticks=$child.StartTime.ToUniversalTime().Ticks.ToString();endpoint=$profile.endpoint;model_id='fixture'}}|ConvertTo-Json|Set-Content '{self.folder/'process.json'}'
 Invoke-ModelAction $profile Stop '{self.folder}'
 $child.Refresh()
 if(-not $child.HasExited){{throw 'Owned child survived stop'}}
}}finally{{if(-not $child.HasExited){{$child.Kill()}};$child.Dispose()}}
"""
        self.assertEqual(self.ps(code), 'Offline')


if __name__ == '__main__': unittest.main()
