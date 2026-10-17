"""Exercise real Windows shortcuts in an isolated Startup folder; never log off."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.name == 'nt', 'Windows sign-in startup')
class StartupTests(unittest.TestCase):
    def setUp(self):
        (ROOT / 'local-data').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='startup test ', dir=ROOT / 'local-data')
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.data = self.folder / 'custom data'
        self.data.mkdir()
        self.startup = self.folder / 'startup folder'
        self.exe = self.folder / 'runtime with spaces' / 'AutoHotkey64.exe'
        self.exe.parent.mkdir()
        self.exe.write_bytes(b'fixture; never executed')
        (self.data / 'installation.json').write_text(json.dumps({'executable': str(self.exe)}))
        (self.data / 'config.ini').write_text('[ui]\nprofile=preserve-me\n')

    def run_ps(self, args, ok=True):
        result = subprocess.run(['powershell.exe', '-NoProfile', '-NonInteractive',
                                 '-ExecutionPolicy', 'Bypass', *args],
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode == 0, ok, result.stderr + result.stdout)
        return result.stdout if ok else result.stderr

    def startup_action(self, action, *, data=None, ok=True):
        result = self.run_ps(['-File', str(ROOT / 'scripts' / 'startup.ps1'),
                              '-Action', action, '-DataDir', str(data or self.data),
                              '-StartupDir', str(self.startup)], ok=ok)
        return json.loads(result) if ok else result

    def test_enable_repeat_disable_and_custom_paths(self):
        self.assertFalse(self.startup_action('Status')['registered'])
        first = self.startup_action('Enable')
        self.assertTrue(first['registered'])
        self.assertTrue(first['matches_configuration'])
        self.assertEqual(first['target'], str(self.exe))
        self.assertEqual(first['arguments'], f'"{ROOT / "src" / "LLMTray.ahk"}" "{self.data}"')
        unrelated = self.startup / 'unrelated.txt'
        unrelated.write_text('keep')
        self.assertEqual(first, self.startup_action('Enable'))
        self.assertEqual(len(list(self.startup.glob('*.lnk'))), 1)
        self.assertEqual(first, self.startup_action('Status'))
        self.assertEqual((self.data / 'config.ini').read_text(), '[ui]\nprofile=preserve-me\n')
        self.assertFalse(self.startup_action('Disable')['registered'])
        self.assertFalse(self.startup_action('Disable')['registered'])
        self.assertEqual(unrelated.read_text(), 'keep')

    def test_foreign_shortcut_is_preserved(self):
        self.startup.mkdir()
        script = self.folder / 'foreign.ps1'
        def quote(path): return "'" + str(path).replace("'", "''") + "'"
        script.write_text("$s=New-Object -ComObject WScript.Shell\n"
                          f"$l=$s.CreateShortcut({quote(self.startup / 'LLM Tray.lnk')})\n"
                          f"$l.TargetPath={quote(self.exe)}\n"
                          "$l.Description='Foreign shortcut'\n$l.Save()\n", encoding='utf-8-sig')
        self.run_ps(['-File', str(script)])
        before = (self.startup / 'LLM Tray.lnk').read_bytes()
        for action in ('Enable', 'Disable'):
            self.assertIn('another configuration', self.startup_action(action, ok=False))
        self.assertFalse(self.startup_action('Status')['matches_configuration'])
        self.assertEqual(before, (self.startup / 'LLM Tray.lnk').read_bytes())

    def test_other_data_directory_cannot_replace_or_remove_entry(self):
        self.startup_action('Enable')
        for action in ('Enable', 'Disable'):
            self.assertIn('another configuration', self.startup_action(action, data=self.folder / 'different data', ok=False))
        self.assertTrue(self.startup_action('Status')['matches_configuration'])

    def test_missing_installation_fails_before_creating_shortcut(self):
        receipt = self.data / 'installation.json'
        receipt.unlink()
        self.assertIn('installation.json is missing', self.startup_action('Enable', ok=False))
        receipt.write_text(json.dumps({'executable': str(self.exe)}))
        self.exe.unlink()
        self.assertIn('executable is missing', self.startup_action('Enable', ok=False))
        self.assertFalse(self.startup_action('Status')['registered'])


if __name__ == '__main__':
    unittest.main()
