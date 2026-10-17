"""Tunnel ownership and failure isolation without SSH connections or models."""
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.name == 'nt' and shutil.which('ssh.exe'), 'Windows OpenSSH')
class TunnelTests(unittest.TestCase):
    def setUp(self):
        (ROOT / 'local-data').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=ROOT / 'local-data', prefix='tunnel-test-')
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.config = self.folder / 'tunnels.json'

    def ps(self, code):
        script = self.folder / 'run.ps1'
        script.write_text("$ErrorActionPreference='Stop'\n" + code, encoding='utf-8-sig')
        return subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive',
                               '-ExecutionPolicy', 'Bypass', '-File', str(script)],
                              capture_output=True, text=True, timeout=20)

    def invocation(self, action):
        return f"& '{ROOT / 'scripts' / 'tunnels.ps1'}' -ConfigFile '{self.config}' -Action {action}"

    def host(self, name='fixture.invalid', mirror=False, port=18080):
        return {'name': name, 'remote_port': port, 'local_port': 8080, 'local_mirror': mirror}

    def test_bad_host_does_not_skip_later_host(self):
        self.config.write_text(json.dumps({'hosts': [self.host('-invalid'), self.host()]}))
        r = self.ps(self.invocation('Status') + ' | ForEach-Object { $_ | ConvertTo-Json }')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('fixture.invalid', r.stdout)
        self.assertIn('safe SSH host alias', r.stdout + r.stderr)

    def test_stale_pid_is_not_stopped_and_start_checks_port(self):
        listener = socket.socket()
        listener.bind(('127.0.0.1', 0))
        listener.listen()
        self.addCleanup(listener.close)
        self.config.write_text(json.dumps({'hosts': [self.host(mirror=True, port=listener.getsockname()[1])]}))
        code = f"""New-Item -ItemType Directory -Path '{self.folder / 'tunnels'}' | Out-Null
@{{pid=$PID;start_ticks='1'}} | ConvertTo-Json | Set-Content '{self.folder / 'tunnels' / 'fixture.invalid.json'}'
{self.invocation('Status')} | ConvertTo-Json
try {{{self.invocation('Stop')}; throw 'Stop should refuse'}} catch {{if($_ -notmatch 'identity changed'){{throw}}}}
try {{{self.invocation('Start')}; throw 'Start should detect occupied mirror'}} catch {{if($_ -notmatch 'mirror port is unavailable'){{throw}}}}
Write-Output 'FOREIGN_PROCESS_SURVIVED'
"""
        r = self.ps(code)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn('"Running":  false', r.stdout)
        self.assertIn('FOREIGN_PROCESS_SURVIVED', r.stdout)

    def test_concurrent_operation_is_refused(self):
        self.config.write_text(json.dumps({'hosts': []}))
        code = f"""$hash=[Security.Cryptography.SHA256]::Create()
$key=([BitConverter]::ToString($hash.ComputeHash([Text.Encoding]::UTF8.GetBytes('{self.config}'.ToLowerInvariant())))).Replace('-','')
$hash.Dispose()
$mutex=New-Object Threading.Mutex($false,('Local\\LLMTrayTunnels_'+$key))
$locked=$mutex.WaitOne(0)
try {{
    & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File '{ROOT / 'scripts' / 'tunnels.ps1'}' -ConfigFile '{self.config}' -Action Start
    if($LASTEXITCODE -eq 0){{throw 'Concurrent operation was allowed'}}
}} finally {{if($locked){{$mutex.ReleaseMutex()}}; $mutex.Dispose()}}
Write-Output 'LOCK_CHECK_PASSED'
"""
        r = self.ps(code)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn('already running', r.stdout + r.stderr)
        self.assertIn('LOCK_CHECK_PASSED', r.stdout)


if __name__ == '__main__':
    unittest.main()
