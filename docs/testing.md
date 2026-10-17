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
Startup tests create real shortcuts in an isolated folder: repeated enable,
disable, paths with spaces, missing runtime and foreign-entry preservation.
They never change the tester's real sign-in settings or launch an executable.

## Native acceptance

Use a dedicated controller instance, preserve other applications and test:

1. Start with the panel hidden; hover the actual tray icon, move to the panel,
   then away. It must show and hide without starting inference.
2. Hover the general overflow arrow: it must not open this model's panel.
3. Pin, move and reload; verify position. Unpin and move away; it must hide.
   Hold the title and trace a continuous path for at least eight seconds. The
   panel must follow before release; repeat with a slow status endpoint and
   with an initially unpinned hover panel.
4. Open Settings, change a metric and shortcut, save, verify both. Use a custom
   data directory to detect lost arguments on reload. Restore the default.
5. Toggle a real controlled model through shortcut and status click. Check
   API identity, exact process lifecycle and notification result.
6. Verify unavailable GPU data is labeled, and all status/usage colors are
   legible. Metrics must not be presented as per-model allocations.
7. For SSH, verify remote loopback binding and a small inference response,
   then test actual editor file reads separately when authorized.
8. For remote windows, inspect the actual VS Code profile. Confirm the custom
   provider and its limits there, then check the picker in each intended window.
   A registry in Default does not cover a named profile.
9. Check the tray frame against Ready and Offline/Sleeping/Loading fixtures:
   green for Ready, orange otherwise. Verify both the rendered border and the
   descriptive tooltip; do not infer availability from resource usage bars.
10. Opt into sign-in startup with a custom data directory. Launch the exact
    Startup shortcut and confirm the profile, metrics and one tray instance;
    launch it again and verify no duplicate or model load. Check registration
    survives an installer rerun without the opt-in flag. Report a direct
    shortcut test separately from a full sign-out/reboot, which requires the
    user's agreement because it interrupts their session.

## Release evidence

The [0.1.1 drag report](tasks/2026-10-17-smooth-drag/2026-10-17-smooth-drag-v0.1.1.md)
records the reproduced failure and sampled before/after movement. To repeat
the actual AHK status checks without a model or mouse input:

```powershell
python tests/check_tray_status.py --ahk .\local-data\runtime\AutoHotkey64.exe --output .\local-data\status-checks.json
```

Supply the path to your installed AutoHotkey executable. Add `--drag` only on
an unlocked desktop with the mouse idle. That option creates a disposable
tray and measures movement while a fake endpoint takes five seconds to reply.
No model weights or inference requests are involved. CI runs status checks
without `--drag` after installing AutoHotkey.

To measure your already-running tray, find its PID and run:

```powershell
.\tests\measure-drag.ps1 -TrayProcessId 12345 -OutputPath .\local-data\drag.json
```

The explicit opt-in probe sends mouse input only after checking the target is
an LLMTray.ahk process and its panel is under the pointer. It pins/opens the
panel, traces a path, saves sampled pointer/window positions, and restores the
original location. If the actual pointer leaves the commanded path, it stops
and marks the run inconclusive rather than fighting the user's mouse. It
leaves the panel pinned. `-UseVisiblePanel` instead
starts with an already-visible hover panel to test automatic pinning. It fails
on p95 tracking error above 12 px or unchanged position over 150 ms. These are
regression thresholds, not display-frame-rate or physical mouse latency claims.

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
