# LLM Tray 0.1.1 — smooth panel dragging

Date: 2026-10-17, Asia/Kolkata. Request: **“the dragging is not smooth”**.

## A. Business outcome

Done: the panel follows the pointer while the title is held. Dragging an
unpinned hover panel pins it, and its location survives restarting the tray.
The fix is installed on the owner's PC. Model inference was not restarted.

Extra finding: the previous release tested final position, not continuous
movement. That test was insufficient and has been supplemented with sampled
pointer/window tracking and a deliberately slow status endpoint.

## B. Cause and implementation

The title used an AutoHotkey Text `Click` event, which starts on release rather
than providing the initial mouse-down needed for a normal drag. It then posted
the native move message and scheduled a position write mid-interaction. The
same UI thread also issued synchronous status requests. Those could hold up
input while an endpoint was slow. The reproduced baseline demonstrates the
drag initiation failure; it does not independently attribute all stutter to
network polling.

Changes:

- `src/LLMTray.ahk`: route title mouse-down to the Windows move loop; exclude
  action buttons. Defer meter painting, hover checking, status completion and
  action-completion work during a drag. Persist position once after release.
- The same file now keeps one asynchronous passive status request outstanding,
  polls completion without waiting, and checks a two-second deadline when not
  dragging. Telemetry uses one INI section write instead of six separate writes.
- `tests/measure-drag.ps1`: explicitly selected process, native mouse movement,
  sampled tracking error, input-target verification and restored location.
- `tests/check_tray_status.py`: launch the actual AHK UI against disposable
  HTTP fixtures; verify state transitions, delayed-response recovery and only
  passive endpoint access. Optional interactive drag stress mode.
- `.github/workflows/ci.yml`: run the actual AHK status checks after the pinned
  installer and syntax validation. The mouse probe remains explicit opt-in.
- `AGENTS.md`: add continuous-drag regression requirements. `README.md` and
  `CHANGELOG.md`: describe 0.1.1 and the user-visible behavior.
- `docs/DESIGN.md` and `docs/testing.md`: record the architecture and repeatable
  checks. `docs/tasks.md`, `docs/prompts.md`, `docs/tasks/README.md`,
  `.github/README.md` and this report preserve results and navigation.

No runtime dependencies were added. AutoHotkey remains the native UI;
PowerShell remains the explicit model-action backend. Python is for tests.

Primary references: Microsoft's [WinHTTP Open mode documentation](https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-open),
[completion checking](https://learn.microsoft.com/en-us/windows/win32/winhttp/iwinhttprequest-waitforresponse),
and [native move-loop entry](https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-entersizemove).
The AutoHotkey documentation URL returned HTTP 403; event behavior was checked
against the installed runtime rather than presented as a successful web read.

## C. Owner pointer

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|1|Smooth panel dragging|the dragging is not smooth|DONE|Installed native mouse-down dragging and nonblocking status polling; tested live and with a stalled endpoint.|

## D. Measured evidence

Eight-second paths, single Windows 11 desktop at 100% scaling. Windows'
full-window drag option was already enabled and was not changed.

| Case | Samples | p95 error | Maximum error | Longest unchanged position |
|---|---:|---:|---:|---:|
|Before: production 0.1.0|259|222 px|227.2 px|7978.6 ms|
|After: live model status|258|0 px|0 px|124.7 ms|
|After: initially unpinned hover panel|261|0 px|0 px|124.0 ms|
|After: fake endpoint delays five seconds|259|0 px|0 px|125.7 ms|
|Final installed repeat, actual cursor also checked|258|0 px|0 px|123.6 ms|

The path deliberately slows at its turns, so an unchanged integer position
does not by itself indicate a stall. The before/after tracking error is the
stronger result. Sampling is approximately 31 ms on this system; **these are
window-coordinate observations, not display FPS or physical input latency**.
No claim of universally zero latency is made.

Other verification:

- 13 existing backend tests pass in 23.849 seconds.
- Actual AHK fixture run: 11 state checks plus one slow-endpoint drag pass.
  Ready, Sleeping, Other model, Loading, Endpoint error, Offline and recovery
  are covered; Ollama Ready/Unloaded/Ready and generic health are covered too.
  Requests are exclusively `/props`, `/api/ps` and `/health`.
- Real tray hover/show/leave/hide/show passes. Drag from hover pins the panel.
- Settings opens and closes. Reload preserves position 1784,1240; unpin/hide
  works. Native panel screenshot inspected; no styling regression observed.
- Five public PowerShell files parse; AutoHotkey syntax validation passes.
- Model process identity and creation time match before and after; no new
  generation or model lifecycle test was needed for this drag-only change.
- The installed tray is left running and unpinned; model settings are intact.

Raw JSON traces and own-panel screenshots are private in `local-data/`.
The script checks the selected process and panel under the pointer before
sending input. No editor keystrokes were sent.

## E. Pending and limits

All items in this request are complete. Mixed-DPI monitor transitions and
display-frame timing remain uncertified. This change does not address model
generation latency or the earlier pending remote editor conversation checks.
No owner decision is needed for this fix.

## F. Next improvements

Retain both held-button movement and slow-endpoint checks for future UI
changes. A drag that merely ends at a different position is not adequate proof.
Test mixed-DPI monitors when that setup becomes relevant.

## Appendix: validation details and sources read

Commands used: `python -m unittest discover -s tests -v`, AutoHotkey
`/ErrorStdOut /validate`, PowerShell parser checks, `tests/measure-drag.ps1`,
`tests/check_tray_status.py --drag`, native hover/settings helpers and public
content/link audits. The report distinguishes simulated HTTP from live model
status. Browser/mobile checks do not apply to this native Windows surface.

The status fixture initially reused a previous child's telemetry, and its
1.5-second delay did not reliably exceed the application deadline. The fixture
was corrected to clear telemetry before each launch and delay five seconds.
The corrected full run passed; failed fixture attempts are not counted as
successful checks.

One later repeat reported 17.2 px p95 / 523 px maximum error, with the window
moving ahead of the commanded pointer path during its first second. That run
did not sample the actual cursor, so external mouse input cannot be confirmed
or excluded retrospectively. The probe now samples it and stops immediately
on unexpected movement. The final eight-second repeat had no detected input
interference and 0/0 px tracking error. This failed repeat is retained in the
private traces rather than silently discarded.

Read: project AGENTS, README, design, task/prompt logs, testing guide, existing
AHK/backend test/CI/audit sources; shared Codex guide, platform rules, Claude
topic router, Windows host facts, logging protocol and applicable v2 discovery,
testing, troubleshooting, coding, Git and Python guidance. Used the UI skill's
interaction guidance and context-maintenance skill. Shared Claude/Codex routing
was reviewed; this product-specific regression belongs in the project AGENTS,
so neither adapter needed editing. Earlier unrelated shared-repository edits
were left alone. Promotion drafts remain unchanged for this small bug fix.

Implementation: [f1a89ec](https://github.com/paras-lehana/llm-tray/commit/f1a89ec1500ab545cb4300e6a88ace0513a4cca1),
main. [Windows CI 39050696922](https://github.com/paras-lehana/llm-tray/actions/runs/39050696922)
passed. Public audit: 39 tracked files, zero findings; relative-link check:
40 links, zero missing. Final documentation and probe refinements follow the
implementation commit; publication receipts are recorded in the task log.
