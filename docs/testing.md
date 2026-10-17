# Testing and scope

Run on Windows with Python 3.12 or later:

```powershell
python -m unittest discover -s tests -v
```

The offline suite uses synthetic HTTP endpoints and disposable scripts. It
checks passive sleep status, explicit wake, wrong-model refusal, unowned/stale
process refusal, occupied ports, custom scripts with spaces, child exit codes,
Ollama's load/unload contract and forbidden endpoint overrides. It never loads
weights or sends editor conversations anywhere. CI also parses PowerShell,
validates AutoHotkey syntax, exercises a fresh pinned installation and scans
Git's publication set. This is not a clean-machine interactive desktop test.

## Native acceptance

Use a dedicated controller instance, preserve other applications and test:

1. Start with the panel hidden; hover the actual tray icon, move to the panel,
   then away. It must show and hide without starting inference.
2. Hover the general overflow arrow: it must not open this model's panel.
3. Pin, move and reload; verify position. Unpin and move away; it must hide.
4. Open Settings, change a metric and shortcut, save, verify both. Use a custom
   data directory to detect lost arguments on reload. Restore the default.
5. Toggle a real controlled model through shortcut and status click. Check
   API identity, exact process lifecycle and notification result.
6. Verify unavailable GPU data is labeled, and all status/usage colors are
   legible. Metrics must not be presented as per-model allocations.
7. For SSH, verify remote loopback binding and a small inference response,
   then test actual editor file reads separately when authorized.

## Release evidence

The [v0.1.0 task report](tasks/2026-10-17-tray-first/2026-10-17-tray-first-v0.1.0.md)
contains measured results and failure fixes. Raw host transcripts and settings
are deliberately excluded from Git. Published images are crops of this UI,
reviewed and SHA256-listed in assets/SHA256SUMS.

Actual owner runtime: llama.cpp with a custom monitored launcher. Native
sleep/wake behavior was measured in the preceding Local Coding Lab release;
this release preserves its 1800-second idle setting. Do not present those older
accelerated tests as a newly elapsed 30-minute soak.

Ollama has only simulated API coverage here. The installed daemon had no local
models, and the controller task did not require downloading one. NVIDIA GPU
metrics are implemented; AMD/Intel GPU metrics and mixed-DPI monitor transitions
are not certified. Full remote Copilot UI verification remains distinct from
successful remote API requests; this task did not type in the editor.
