"""Exercise the actual AHK status UI with a disposable, passive HTTP server.

Optional --drag drives the mouse in an unlocked desktop. Without that option
this checks status transitions without keyboard/mouse input or real inference.
"""
import argparse
import configparser
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    """Launch only disposable tray instances; always stop children we own."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ahk', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--drag', action='store_true')
    args = parser.parse_args()
    runtime = ROOT / 'local-data'
    runtime.mkdir(exist_ok=True)
    state = {'code': 200, 'delay': 0, 'body': {}, 'calls': []}
    results = []

    class Handler(BaseHTTPRequestHandler):
        """Return controlled success, slow and error responses over loopback."""

        def log_message(self, *unused: object) -> None:
            pass

        def do_GET(self) -> None:
            state['calls'].append(self.path)
            code, delay, body = state['code'], state['delay'], state['body']
            time.sleep(delay)
            payload = json.dumps(body).encode()
            try:
                self.send_response(code)
                self.send_header('Content-Length', str(len(payload)))
                self.end_headers()
                self.wfile.write(payload)
            except (BrokenPipeError, ConnectionResetError):
                pass  # A timed-out client is an expected fixture outcome.

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    try:
        with tempfile.TemporaryDirectory(dir=runtime, prefix='status-') as name:
            folder = Path(name)
            source = folder / 'LLMTray.ahk'
            shutil.copyfile(ROOT / 'src' / 'LLMTray.ahk', source)
            (folder / 'profiles').mkdir()
            (folder / 'config.ini').write_text(
                '[ui]\nprofile=fixture\nhotkey=^!+F11\nnotifications=0\n'
                'refresh_seconds=1\nhover=0\npinned=0\n', encoding='utf-16')

            def wait_state(expected: str, timeout: float = 7) -> None:
                """Observe rendered telemetry rather than duplicate parsing."""
                deadline = time.monotonic() + timeout
                last = ''
                while time.monotonic() < deadline:
                    if child.poll() is not None:
                        raise AssertionError('Tray exited unexpectedly')
                    try:
                        cfg = configparser.ConfigParser()
                        raw = (folder / 'telemetry.ini').read_bytes()
                        cfg.read_string(raw.decode(
                            'utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8-sig'))
                        last = cfg.get('live', 'state', fallback='')
                        if last == expected:
                            results.append({'status': expected, 'pass': True})
                            return
                    except (OSError, UnicodeError, configparser.Error):
                        pass
                    time.sleep(0.05)
                raise AssertionError(f'Expected {expected}, last state {last}')

            for protocol in ['llama', 'ollama', 'health']:
                (folder / 'telemetry.ini').unlink(missing_ok=True)
                state.update(code=200, delay=0, body={
                    'model_alias': 'fixture', 'models': [{'name': 'fixture'}]})
                (folder / 'profiles' / 'fixture.ini').write_text(
                    '[model]\nname=Disposable status test\nbackend=custom\n'
                    f'status={protocol}\nmodel_id=fixture\n'
                    f'endpoint=http://127.0.0.1:{server.server_port}\n',
                    encoding='utf-16')
                with (folder / 'output.log').open('wb') as log:
                    child = subprocess.Popen(
                        [str(args.ahk), '/ErrorStdOut', str(source), str(folder)],
                        stdout=log, stderr=log,
                        creationflags=subprocess.CREATE_NO_WINDOW)
                    try:
                        wait_state('Ready')
                        if protocol == 'llama':
                            state['body'] = {'model_alias': 'fixture', 'is_sleeping': True}
                            wait_state('Sleeping')
                            state['body'] = {'model_alias': 'foreign'}
                            wait_state('Other model')
                            state['code'] = 503
                            wait_state('Loading')
                            state['code'] = 500
                            wait_state('Endpoint error')
                            state.update(code=200, delay=5,
                                         body={'model_alias': 'fixture'})
                            wait_state('Offline')
                            if args.drag:
                                # A pending slow request must not hold the mouse.
                                probe = args.output.with_suffix('.drag.json')
                                subprocess.run([
                                    'powershell.exe', '-NoProfile',
                                    '-ExecutionPolicy', 'Bypass', '-File',
                                    str(ROOT / 'tests' / 'measure-drag.ps1'),
                                    '-TrayProcessId', str(child.pid),
                                    '-OutputPath', str(probe)], check=True,
                                    timeout=30, creationflags=subprocess.CREATE_NO_WINDOW)
                                results.append({'slow_endpoint_drag': True})
                            state['delay'] = 0
                            wait_state('Ready')
                        elif protocol == 'ollama':
                            state['body'] = {'models': []}
                            wait_state('Unloaded')
                            state['body'] = {'models': [{'model': 'fixture'}]}
                            wait_state('Ready')
                    finally:
                        child.terminate()
                        child.wait(timeout=10)
                error = (folder / 'output.log').read_text(errors='replace')
                if error.strip():
                    raise AssertionError(error)
    finally:
        server.shutdown()
        server.server_close()
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(
            {'checks': results, 'requests': state['calls']}, indent=2))
    assert set(state['calls']) == {'/props', '/api/ps', '/health'}, state['calls']
    print(f'PASS {len(results)} tray checks; passive endpoints only.')


if __name__ == '__main__':
    main()
