"""Exercise actual native brush buttons against a disposable model endpoint.

Uses targeted button messages only; never types into editors or loads a model.
Run on Windows with --ahk and --output, like check_tray_status.py.
"""
import argparse
import configparser
import ctypes
from ctypes import wintypes
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parents[1]
USER = ctypes.WinDLL('user32', use_last_error=True)
CALLBACK = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
USER.SendMessageW.argtypes = [wintypes.HWND, wintypes.UINT,
                             wintypes.WPARAM, wintypes.LPARAM]
USER.SendMessageW.restype = ctypes.c_ssize_t
USER.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
USER.GetWindowThreadProcessId.argtypes = [wintypes.HWND,
                                        ctypes.POINTER(wintypes.DWORD)]
USER.EnumWindows.argtypes = [CALLBACK, wintypes.LPARAM]
USER.EnumChildWindows.argtypes = [wintypes.HWND, CALLBACK, wintypes.LPARAM]
USER.IsWindowEnabled.argtypes = [wintypes.HWND]
USER.GetWindowLongW.argtypes = [wintypes.HWND, ctypes.c_int]


def controls(pid: int, prefix: str = 'Free LLM resources (') -> dict[str, int]:
    """Find descriptive native button names only in our owned child process."""
    found = {}

    @CALLBACK
    def child(hwnd: int, unused: int) -> bool:
        text = ctypes.create_unicode_buffer(512)
        USER.GetWindowTextW(hwnd, text, 512)
        if text.value.startswith(prefix):
            found[text.value] = hwnd
        return True

    @CALLBACK
    def window(hwnd: int, unused: int) -> bool:
        owner = wintypes.DWORD()
        USER.GetWindowThreadProcessId(hwnd, ctypes.byref(owner))
        if owner.value == pid:
            USER.EnumChildWindows(hwnd, child, 0)
        return True

    USER.EnumWindows(window, 0)
    return found


def read_ini(path: Path) -> configparser.ConfigParser:
    """Read AHK and PowerShell INI files, including UTF-16 output."""
    result = configparser.ConfigParser()
    raw = path.read_bytes()
    result.read_string(raw.decode('utf-16' if raw.startswith(b'\xff\xfe')
                                 else 'utf-8-sig'))
    return result


def wait_for(check, timeout: float = 15) -> None:
    """Bound asynchronous UI/controller checks without guessing completion."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            if check():
                return
        except (OSError, configparser.Error):
            pass
        time.sleep(0.05)
    raise AssertionError('Timed out waiting for native cleanup result')


def main() -> None:
    """Verify each brush, in-flight exclusion, error feedback and visibility."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ahk', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    state = {'loaded': True, 'fail': False, 'posts': []}
    checks = []

    class Handler(BaseHTTPRequestHandler):
        """Emulate Ollama unloading one model while another remains loaded."""
        def log_message(self, *unused: object) -> None:
            pass

        def do_GET(self) -> None:
            models = [{'name': 'other-app-model'}]
            if self.path == '/api/tags' or state['loaded']:
                models.append({'name': 'fixture'})
            payload = json.dumps({'models': models}).encode()
            self.send_response(200)
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def do_POST(self) -> None:
            request = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
            state['posts'].append(request)
            time.sleep(1.5)
            if state['fail']:
                self.send_error(500, 'Synthetic unload failure')
                return
            assert request['model'] == 'fixture'
            assert request['keep_alive'] == 0
            state['loaded'] = False
            self.send_response(200)
            self.send_header('Content-Length', '2')
            self.end_headers()
            self.wfile.write(b'{}')

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    runtime = ROOT / 'local-data'
    runtime.mkdir(exist_ok=True)
    try:
        with tempfile.TemporaryDirectory(dir=runtime, prefix='cleanup-') as folder:
            folder = Path(folder)
            for name in ['LLMTray.ahk', 'control.ps1', 'Backend.ps1']:
                shutil.copyfile(ROOT / 'src' / name, folder / name)
            (folder / 'profiles').mkdir()
            (folder / 'profiles' / 'fixture.ini').write_text(
                '[model]\nname=Cleanup test\nbackend=ollama\nstatus=ollama\n'
                f'endpoint=http://127.0.0.1:{server.server_port}\nmodel_id=fixture\n',
                encoding='utf-16')
            config = ('[ui]\nprofile=fixture\nhotkey=^!+F11\n'
                      'metrics=vram,ram,gpu\nrefresh_seconds=1\n'
                      'notifications=0\nhover=0\npinned=0\n')
            (folder / 'config.ini').write_text(config, encoding='utf-16')
            with (folder / 'output.log').open('wb') as log:
                child = subprocess.Popen(
                    [str(args.ahk), '/ErrorStdOut', str(folder / 'LLMTray.ahk'), str(folder)],
                    stdout=log, stderr=log, creationflags=subprocess.CREATE_NO_WINDOW)
                try:
                    live = lambda: read_ini(folder / 'telemetry.ini')['live']['state']
                    wait_for(lambda: live() == 'Ready')
                    buttons = controls(child.pid)
                    assert len(buttons) == 3, buttons
                    assert all(USER.GetWindowLongW(h, -16) & 0xF == 0xB
                               for h in buttons.values()), 'Brush must retain native owner-draw style'
                    for metric in ['VRAM', 'RAM', 'GPU']:
                        state['loaded'] = True
                        wait_for(lambda: live() == 'Ready')
                        before = len(state['posts'])
                        hwnd = buttons[f'Free LLM resources ({metric})']
                        if metric == 'GPU':
                            # Native keyboard activation, without editor input.
                            USER.SendMessageW(hwnd, 0x100, 0x20, 0)
                            USER.SendMessageW(hwnd, 0x101, 0x20, 0)
                        else:
                            USER.SendMessageW(hwnd, 0xF5, 0, 0)  # BM_CLICK
                        wait_for(lambda: live() == 'Working')
                        assert all(not USER.IsWindowEnabled(h) for h in buttons.values())
                        for duplicate in buttons.values():
                            USER.SendMessageW(duplicate, 0xF5, 0, 0)
                        wait_for(lambda: live() == 'Unloaded')
                        assert len(state['posts']) == before + 1
                        assert USER.GetWindowLongW(hwnd, -16) & 0xF == 0xB
                        assert read_ini(folder / 'action.ini')['result']['status'] == 'Unloaded'
                        checks.append({'brush': metric, 'unloaded': True,
                                       'disabled_while_busy': True, 'no_overlap': True})
                    # Repeating cleanup after completion must never preload.
                    before = len(state['posts'])
                    USER.SendMessageW(next(iter(buttons.values())), 0xF5, 0, 0)
                    wait_for(lambda: live() == 'Working')
                    wait_for(lambda: live() == 'Unloaded')
                    assert len(state['posts']) == before + 1 and not state['loaded']
                    checks.append({'already_unloaded_stays_unloaded': True})
                    state.update(loaded=True, fail=True)
                    wait_for(lambda: live() == 'Ready')
                    USER.SendMessageW(next(iter(buttons.values())), 0xF5, 0, 0)
                    wait_for(lambda: live() == 'Working')
                    wait_for(lambda: live() == 'Ready')
                    assert read_ini(folder / 'action.ini')['result']['status'] == 'error'
                    assert state['loaded']
                    assert all(USER.IsWindowEnabled(h) for h in buttons.values())
                    assert controls(child.pid, 'Action failed.')
                    checks.append({'failed_unload_reports_error': True,
                                   'buttons_reenabled': True})
                finally:
                    if sys.exc_info()[0]:
                        for name in ['tray.log', 'action.ini', 'output.log']:
                            path = folder / name
                            if path.exists():
                                raw = path.read_bytes()
                                print(name, raw.decode('utf-16' if raw.startswith(b'\xff\xfe') else 'utf-8-sig', errors='replace'), flush=True)
                    child.terminate()
                    child.wait(timeout=10)
            assert not (folder / 'output.log').read_text(errors='replace').strip()
            (folder / 'config.ini').write_text(config + 'cleanup_buttons=0\n', encoding='utf-16')
            child = subprocess.Popen(
                [str(args.ahk), '/ErrorStdOut', str(folder / 'LLMTray.ahk'), str(folder)],
                creationflags=subprocess.CREATE_NO_WINDOW)
            try:
                time.sleep(2)
                assert child.poll() is None
                assert not controls(child.pid)
                checks.append({'cleanup_buttons_disabled_by_config': True})
            finally:
                child.terminate()
                child.wait(timeout=10)
    finally:
        server.shutdown()
        server.server_close()
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps({'checks': checks, 'posts': state['posts']}, indent=2))
    print(f'PASS {len(checks)} native cleanup checks; all requests unload only.')


if __name__ == '__main__':
    main()
