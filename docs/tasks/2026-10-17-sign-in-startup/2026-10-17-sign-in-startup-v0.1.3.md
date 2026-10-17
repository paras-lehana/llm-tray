# LLM Tray 0.1.3 - Available after sign-in

Date: 2026-10-17, Asia/Kolkata. Repository: paras-lehana/llm-tray, branch main.

## Request and outcome

> cant see the icon after restart, please we need it everytime..

The tray now has an explicit per-user sign-in registration, and is running on
the owner's PC. Its resource panel and existing custom model profile work.
The model remains stopped until requested; the tray alone does not load weights.

## Cause and implementation

After the recorded 22:54:51 boot, there was no AutoHotkey tray process and no
LLM Tray entry in the user's Startup folder, Run entries or relevant scheduled
tasks. The old installer intentionally did not register startup. A shortcut on
the install drive did not make it launch when Windows signed in.

The new startup manager creates a single LLM Tray.lnk in the current user's
Startup folder. It points at the existing installed AutoHotkey executable and
passes the full source path and custom data directory as quoted arguments.
Enable is repeatable; Disable removes only a matching managed entry. A foreign
entry or another data configuration is refused. Status reports registration,
not an unconditional promise that Windows cannot disable startup independently.

The installer adds `-StartAtSignIn` as an explicit opt-in. A normal installer
rerun preserves any existing startup choice. No dependency, service, elevated
task, model download, GPU setting or model-start behavior was introduced.

This uses Microsoft's documented
[Startup-folder mechanism](https://support.microsoft.com/en-gb/windows/experience/startup-boot/configure-startup-applications-in-windows).
It runs after the user signs in, not before login. Source/runtime/data paths
must remain available; disable and re-enable registration when moving them.

## Evidence

| Check | Result |
|---|---|
| Controller and startup behavior suite | 17 tests pass in 30.016s |
| Startup cases | Repeated enable/disable, spaced paths, config preservation, foreign/other-data refusal, missing runtime |
| Actual registered shortcut | Launched twice; one production tray process remains |
| Startup discovery | Windows Win32_StartupCommand lists LLM Tray in Startup |
| Model loading | No llama-server process before or after tray launches |
| Native UI | Actual icon hover/show/leave/hide/re-hover passes; offline panel screenshot inspected |
| Existing configuration | Qwen profile and UI config hashes unchanged by installer |
| Installer opt-in and normal rerun | Real installed runtime verified; registration survives rerun without flag |
| Actual AHK state transitions | 11 checks pass against synthetic passive endpoints |
| Parsing | Six PowerShell files and AutoHotkey validation pass |
| Actual reboot after the fix | Not performed; user's current session preserved |

The first hover attempt overlapped a disposable AHK test fixture and correctly
reported two icons. After that fixture completed, the production-only hover
check passed. Process enumeration confirmed a single production instance;
this was a test scheduling collision, not evidence of duplicate startup.

Private receipts, UI crops and exact host configuration remain outside Git.
The current UI correctly reports Offline with an orange frame. This release
does not retest editor latency, remote chat, model quality or idle-sleep timing.
Windows can put the icon in overflow or disable a startup entry through Startup
apps; the configuration guide explains those controls. A full reboot check is
deferred to a normal user restart, rather than interrupting ongoing work.

## File inventory

| File | Change |
|---|---|
| scripts/startup.ps1 | Enable, Disable and Status for one owned user startup shortcut |
| install.ps1 | Explicit opt-in flag; normal install preserves startup choice |
| tests/test_startup.py | Four real-shortcut behavior tests in isolated folders |
| AGENTS.md | Authorized opt-in startup and regression requirements |
| README.md | 0.1.3 setup instructions and report link |
| docs/configuration.md | Startup, Windows controls, relocation and removal instructions |
| docs/testing.md | Shortcut behavior coverage and native acceptance case |
| CHANGELOG.md | 0.1.3 release notes |
| .github/README.md | Startup tools and report discovery |
| docs/tasks/README.md | Report index |
| docs/tasks.md | Current task state and measured timeline |
| docs/prompts.md | Original prompt and canonical A-G closeout |
| This report | Cause, evidence, constraints and file inventory |

Commands: `python -X utf8 -m unittest discover -s tests -v`, the actual AHK
status-check script, PowerShell AST parsing, AutoHotkey `/validate`, startup
Enable/Status, `install.ps1 -StartAtSignIn`, normal installer rerun, and the
private native hover helper. Public audit/link validation and CI are recorded
in the publication receipt below. Browser/mobile tests do not apply to this
Windows startup change. No editor input or full reboot was sent.

## Instruction maintenance

Read project AGENTS, README, DESIGN, task/prompt logs, configuration/testing
guides, installer and controller sources. Re-read the maintained Codex guide,
shared Claude router and logging protocol. Applied the context-maintenance
skill to the product regression: project AGENTS owns it. The Codex/Claude
adapters already route to that source and remain unchanged. Shared platform,
Windows host, testing and Git guidance had been read earlier in this session.

## Publication receipt

Implementation **ac46b564d5cc4abdbd09492523b3620cf720945e** is published on main.
[Windows CI 39055357160](https://github.com/paras-lehana/llm-tray/actions/runs/39055357160)
passed, including a fresh portable install, behavior tests, native AHK status
checks and content audit. Local public audit: 45 tracked files, zero findings;
56 relative documentation links resolve. The production icon was also found
beside the overflow arrow on the main taskbar, rather than only in overflow.
[Source prerelease v0.1.3](https://github.com/paras-lehana/llm-tray/releases/tag/v0.1.3)
is published. No signed executable or model weights are bundled.
