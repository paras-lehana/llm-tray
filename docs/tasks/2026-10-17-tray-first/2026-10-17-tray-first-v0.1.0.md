# LLM Tray: remote workspaces and tray controls — v0.1.0

Date: 17 October 2026, Windows 11. This is the product/lifecycle follow-up to Local
Coding Lab, not a new model comparison or a Copilot latency fix.

## Outcome

The controller is a separate reusable Windows project with three provider
examples. It lives in the notification area and shows exact values on hover.
The panel can be pinned and dragged. Metrics, shortcut, thresholds and profile
are configurable. Two remote Linux hosts reach the PC model through private
SSH connections. Public source: https://github.com/paras-lehana/llm-tray.

![Actual ready panel](../../../assets/panel-ready.png)

## Owner requirements

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|1|Remote model access|“configure locall llm on my remote server too”|PARTIALLY DONE|Both remote hosts answer through SSH; Copilot entry added. Fresh editor conversation not typed.|
|2|Tray hover panel|“widget looks good if i hover above the icon in taskbar”|DONE|Panel hidden by default; actual hover/leave checked.|
|3|Pin and drag|“show pin icon…pined…dragging possible”|DONE|Pin control, draggable header, persisted position.|
|4|Compact resource icon|“icon size, small VRAM RAM GPU stuff in rows and that ready icon”|DONE|V/R/G rows and status dot; exact numbers in panel.|
|5|Public repository|“make a public github repo”|DONE|Independent public LLM Tray repository.|
|6|Customization|“choose what to show…change shortcut…which llm to start”|DONE|Native Settings and INI profiles; llama.cpp, Ollama, custom scripts.|
|7|Guide and promotion|“good readme and promotion”|DONE|Installation/config/remote guides and LinkedIn/Medium drafts; no social posting.|

## Implementation and decisions

- `src/LLMTray.ahk`: tray icon generated in memory, Windows RAM/NVML counters,
  bounded passive endpoint checks, hover, pin/drag, settings and hotkey.
- `src/Backend.ps1`: profile parsing, local endpoint validation, provider
  actions, ownership receipts, subprocess exit handling and bounded readiness.
- `src/control.ps1`: endpoint mutex, per-profile logs and atomic action result.
- `scripts/tunnels.ps1`: separate owned SSH connections, reverse loopback
  forwarding, optional local mirror, explicit reconnect and exact-PID stop.
- `install.ps1`: pinned AutoHotkey 2.0.30, verified archive and executable,
  preservation of private config, explicit-launch shortcut.
- `examples/`: UI settings, three profiles and generic SSH configuration.
- `tests/test_backend.py`, CI workflow and audit: offline behavior tests,
  syntax checks, installer verification and reviewed publication set.
- README/configuration/remote/testing/design docs, changelog, license and
  third-party notices explain controls, scope and maintenance.
- Project AGENTS and thin Claude/Copilot adapters route the native regression
  cases. Shared owner routers were reviewed; their routing did not need changes.
- Draft promotion files describe the actual product and its limits.

Your existing Qwen3.6 Q4/128K CPU-KV model remains selected, with native 1800-second
idle sleep. The custom profile delegates to the existing monitored launcher;
no placement, quantization, reasoning or hardware tuning changed. All new local
installation/data stays on the E-drive. No Windows boot startup is added.

## Verification and measured results

| Check | Evidence / limit |
|---|---|
|Native tray hover|Actual icon → panel → leave → hide → hover passes.|
|Pin and drag|Actual pin persists; drag moved panel from 1740,1023 to 750,780.|
|Settings|Actual save hides GPU and changes shortcut; reload preserves private data path and pinned position. Defaults restored.|
|Global shortcut|Ctrl+Alt+L and Ctrl+Alt+Shift+L stop/start pass. Occupied Ctrl+Alt+M is refused; Ctrl+Alt+L restored.|
|Power click|Actual status click stops then starts the monitored model; both final action results succeed.|
|Installer/syntax|Fresh pinned extraction and repeat install preserve config; four PowerShell parsers and AHK validation pass.|
|Offline behavior|13 tests pass in 17.546 seconds, including stopping an owned unresponsive disposable child.|
|Remote host A|Small reply REMOTE_OK in 6.036 s, including wake from sleep.|
|Remote host B|Small reply REMOTE_OK in 0.957 s; model already awake.|
|Remote binding|Both remote listeners verified 127.0.0.1 only, port 18888.|
|Editor configuration|Distinct PC Qwen over SSH entry, same 128K / 98304 input / 16384 output and native-tool limits. Existing direct entry preserved.|
|Model latency|Not fixed or benchmarked here. Previous full Copilot greeting took about 7m42s.|
|Ollama|API contract tested with fixtures; real installed daemon had no weights.|

The short remote prompts temporarily disabled thinking for those diagnostic
requests only. Production thinking settings remain unchanged. The two replies
are sequential transport checks, not comparable model-quality benchmarks.
No editor typing, cloud inference or OpenRouter spending occurred in this task.

## Problems found and fixed

The first bundled owner setup command was rejected by automatic approval review
with only “blocked by policy.” Configuration and network binding checks were
separated; the scoped loopback setup then succeeded without an approval bypass.

Both remote port 8080listeners belonged to other services; port 18080also could
not be bound on Windows. Port 18888 was verified available and used. Existing
services and VS Code SSH sessions were preserved.

PowerShell lost a child process exit code after a successful custom stop, causing
a false error notification. Opening its handle before waiting corrected this;
the test now covers both exit 0 and exit 17. Actual shortcut cycle passed again.

Native AutoHotkey Reload discarded the custom data-directory argument, returning
to setup after Settings saved. Explicit relaunch now retains that argument.
This is a release regression case. A native shortcut probe also found Ctrl+Alt+M
reserved by another application after this tray was stopped. The Settings dialog
now rejects occupied shortcuts; Ctrl+Alt+Shift+L passed a real lifecycle cycle.
Windows UI Automation also strips ampersands
from accessible titles; the panel uses a plain title for reliable native tests.

Some shell versions do not forward useful hover events. The fallback uses the
actual icon bounds and native UI Automation to distinguish its button from the
general overflow arrow. No screenshot polling or background shell scan is used.

## Publication and evidence

Raw checks remain in private local-data/. Published panel and Settings crops were
visually reviewed, and their exact hashes are allowlisted. All code is Windows
native; browser/mobile web checks are inapplicable. Launch drafts contain
1145 LinkedIn characters and 1441 Medium words before metadata/title options.
Neither draft was posted to a social account. CI/publication status is recorded
in the prompt closeout and task log.

## Remaining limits and next steps

Verify a fresh Copilot chat and real file read in each remote workspace when
editor interaction is authorized. A successful API test does not establish
instruction retrieval, full context delivery, permissions or acceptable latency.
Windows DND may suppress visible notification presentation even when Windows
acknowledges a notification. Clean-machine desktop behavior, mixed-DPI movement,
AMD/Intel counters and a signed packaged executable are not certified.

Sleep discards live KV; clients must resend retained history. Manual Stop ends
the listener and needs Start. Two remote workspaces share one queue. The local
mirror also needs its SSH host; the preserved direct local model entry remains
available independently. Reconnect is explicit after network loss.

## Owner request (remote hostnames redacted)

> also please configure locall llm on my remote server too (they are open in
> other windows like [remote server A] and [remote server B])
>
> And i dont that kind of widget, that widget looks good if i hover above the
> icon in taskbar. so i guess i wanted an icon which stays in the task tray.
> You can also show pin icon in this widget so that it can be pined, and also
> dragging possible.
>
> the tray icon i am talking about should be of icon size, small VRAM RAM GPU
> stuff in rows and that ready icon. Just like task manager has icon.
>
> Also make a public github repo, make customisation possible so we can choose
> what to show and also have good readme and promotion for this. instruct how
> can we change shortcut, configure which llm to start (maybe people can make
> a simple script, or point it to it, or b y default we give popular option like
> llama etc).
