# LLM Tray 0.1.4 - Recover remote model access

Date: 2026-10-17, Asia/Kolkata. Project: llm-tray, branch main.
Private host names and raw editor logs are omitted from this public report.

## Request and outcome

> this did not work on [remote SSH host]

The owner's screenshot showed Copilot retries followed by `fetch failed: read
ECONNRESET`. The selected custom model was already present in the remote window.
The PC model and both dedicated tunnels are restored. Remote streamed text,
thinking and function-call output now complete. The tray checks the connection
helper every 60 seconds and reports failure/recovery. The existing high-thinking
model settings, 128K context and native 30-minute idle sleep remain unchanged.

## What failed

- The PC restarted at 22:54:51. The model was not running when inspected.
  Tray startup had deliberately not been configured to load model weights.
- At 23:14:47, the dedicated tunnel's startup attempt failed with `remote port
  forwarding failed for listen port 18888`. The old script stopped at the first
  failed host; no periodic retry or visible failure report followed.
- The remote Copilot log records a 300-second network failure at 23:13:41,
  followed by ECONNRESET at 23:15:23. At 23:21, the remote loopback port had no
  listener and both dedicated PC tunnel processes were absent.
- The earlier port owner was no longer available to identify. A stale remote
  forward after the restart is plausible, but not established as its cause.
  No firewall, SSH daemon or existing editor connection was changed.

Previous API checks proved reachability while the components were running;
they did not cover recovery across a PC reboot. Model startup and tunnel
startup are separate prerequisites. A live tray icon alone proves neither.

## Recovery and measured checks

The existing guarded launcher passed its RAM/VRAM checks and started the same
configured model. Dedicated reverse forwards were re-established on loopback.
The active named VS Code profile already had the correct custom URL/model ID;
its providers, credentials, instructions and chat draft were left unchanged.

| Actual remote probe | First data | Visible/complete response | Result |
|---|---|---|---|
| Streamed greeting, thinking disabled for this probe | 1.522s | 1.789s total | REMOTE_OK, complete SSE stream |
| Streamed greeting, thinking enabled | 0.343s reasoning | 10.053s visible; 10.215s total | REMOTE_OK, complete SSE stream |
| Streamed tool-call output from installed remote VS Code Node runtime | 12.103s | 14.062s total | Correct function name and valid JSON arguments |

The Node probe used the remote editor's installed Node v24.21.0 and the exact
configured loopback chat URL. Its tool was a harmless synthetic function; no
remote command was requested or executed by the model. These short transport
checks do not certify a complete instruction-heavy Copilot conversation.
The user's actual chat was not replayed because editor input remains restricted.

## Permanent changes

- Optional `connection_retry_seconds`: 0 keeps startup/manual behavior;
  60 checks the idempotent helper each minute. Initial startup still runs after
  one second. The retry timer must not replace that initial callback.
- The tray polls a handle to its exact connection child asynchronously. It
  prevents overlap, logs state changes, and requests a notification on failure
  and recovery. Repeated failures do not create a notification every minute.
- Tunnel operations use a configuration-specific mutex and atomic receipts.
  A failed host does not prevent attempts for others. Start/Status treat a
  reboot-reused PID as stale; Stop refuses it. Foreign processes remain untouched.
- Retries reopen connections only. They do not load a stopped model. After a
  full reboot, Start the model once; after native idle sleep, the next request
  wakes it automatically. Disable retries before deliberately stopping tunnels.

OpenSSH documents that
[ExitOnForwardFailure does not test the final forwarded destination](https://man.openbsd.org/ssh_config#ExitOnForwardFailure).
VS Code documents the selected
[Custom Endpoint provider](https://code.visualstudio.com/docs/agent-customization/language-models).

## Validation and limits

- Seventeen existing controller/startup tests passed; three new tunnel tests
  passed after correcting a test harness that buffered JSON until a deliberate
  terminating error. CI runs the complete 20-test suite together.
- Twelve actual AHK checks passed. The new fixture fails its first helper,
  retries a 15-second helper on a 10-second interval, and verifies no overlap,
  prompt initial invocation, failure logging and recovery logging. It uses no
  SSH connections or model inference. Visible Windows toasts are not asserted.
- Installed tray reloaded without restarting the model. Native hover/show/hide
  passed; the log records successful initial connection setup in about 2s.
- Six PowerShell files parse. AHK syntax validation passed; the final revised
  source also executes in the 12-check suite. No browser/mobile UI applies.
- A full reboot/network-disconnect test and replay of the user's actual Copilot
  workflow remain unperformed. Normal SSH sessions and existing listeners were
  preserved. Periodic repair only operates while the tray is running.

## File inventory and commands

| File | Change |
|---|---|
| src/LLMTray.ahk | Initial/periodic helper scheduling, child handles, failure/recovery notices |
| scripts/tunnels.ps1 | Mutex, per-host isolation, stale-PID handling, atomic receipts |
| examples/config.ini | Opt-in retry setting |
| tests/test_tunnels.py | Three ownership/concurrency/failure-isolation tests |
| tests/check_tray_status.py | Actual asynchronous connection recovery fixture |
| AGENTS.md | Remote transport and reboot regression requirements |
| README.md / CHANGELOG.md | 0.1.4 release and report links |
| docs/configuration.md / docs/remote-access.md | Retry setup, lifecycle prerequisites, diagnosis |
| docs/testing.md | New checks and their limits |
| .github/README.md / docs/tasks/README.md | Discovery indexes |
| docs/tasks.md / docs/prompts.md | Timeline, original request and canonical closeout |
| This report | Evidence, failure analysis and measured scope |

Commands used: the existing guarded Start action; tunnel Start/Status;
`python -m unittest discover -s tests -v` and targeted tunnel rerun; actual AHK
status suite; PowerShell parsing and AHK `/validate`; native hover helper;
read-only SSH listener/log inspection; remote Python and Node streaming probes.
Private connection configuration now sets a 60-second retry interval.

The context-maintenance skill was applied to project regression rules and one
shared troubleshooting lesson. Shared Codex/Claude routing remains unchanged;
the shared lesson is published from an isolated checkout to preserve unrelated
owner changes in the Windows instructions repository. No new dependencies.
Shared troubleshooting commit: `fe2ba07` on copilot-configs main, with its own
prompt/task logs. Both existing Linux hosts passed `install.sh --check` with
all links OK. No shared import/installer changed and no cloud model smoke call
was made. The owner's Windows checkout was not fast-forwarded over unrelated
uncommitted changes; only this task's temporary edit there was removed after
publishing the shared lesson from the isolated checkout.

## Publication receipt

Implementation `e1716eac5f3bddc92711d436761cf79553fcb193` is published on main.
[Windows CI 39056683095](https://github.com/paras-lehana/llm-tray/actions/runs/39056683095)
passed all 20 behavior tests, 12 actual AHK checks, parsing, fresh installation
and public audit. Local public audit: 47 tracked files, zero findings; 62 relative
documentation links resolve. [Source prerelease v0.1.4](https://github.com/paras-lehana/llm-tray/releases/tag/v0.1.4)
is published. Final passive inspection still reports the model Ready and both
original restored tunnel PIDs alive; no duplicate tunnel has accumulated.
