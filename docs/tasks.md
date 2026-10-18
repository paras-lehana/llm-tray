# Task log

Last updated: 2026-10-18 (Asia/Kolkata).

## 2026-10-18 - Resource cleanup brushes

| # | Task | Status | Notes |
|---|---|---|---|
|1|Brush beside VRAM/RAM/GPU|Implemented and installed|Native named controls, drawn brushes and Settings visibility tested.|
|2|Free resources, at least the LLM|Implemented; live memory measurement deferred|All brushes call scoped Stop/unload; active remote chat preserved. No arbitrary app killing.|

- Read project/shared guidance and UI design skill; branch
  feat/resource-cleanup-20261018; native Windows scope.
- Added unload-only brushes, progress/error feedback, disabled busy controls,
  menu action and Settings visibility. Kept configured model lifecycle owner.
- Native fixture exposed optional-field/exception StrictMode bugs in Ollama
  status; fixed with two regressions. Render inspection caught normalized native
  button styles; BM_SETSTYLE fixes the brushes, with style assertions added.
- 22offline tests pass in55.104s;12actual AHK status checks and6native cleanup
  checks pass. PowerShell parsing and AHK validation pass.
- Actual Settings off/on/reload yields0/3buttons and preserves owner preferences.
  Actual rendered window inspected; desktop capture shows lock screen. Physical
  pointer/drag/toast validation pending; unlock requested. Remote Qwen remains
  active and was not stopped for a memory-reclamation measurement.

[Report](tasks/2026-10-18-cleanup/2026-10-18-cleanup-v0.1.6.md).

## 2026-10-18 - Remote Copilot experiment interruption

| # | Task | Status | Notes |
|---|---|---|---|
|1|Investigate repeated remote connection failure|Diagnosed; current transport passes; fresh editor replay pending|Requested model stop interrupted an active remote chat. Configuration was already correct.|

- 06:11–06:13 IST - Correlated00:21:01 requested stop with remote termination
  at00:21:03 and repeated00:21–00:23 socket errors; three preceding Qwen UI
  requests succeeded. The last model task had14492 input tokens, not a context
  rejection. Current production process was already restored at06:01.
- 06:13–06:15 IST - Installed remote Node/Undici: native-thinking greeting
  11.629s, tool request20.676s, instruction-file final58.991s. All complete SSE
  streams; correct tool arguments and all3 instruction answers.
- 06:16 IST - Correct alias and131072 context through direct and mirrored URLs;
  original production process remains. No editor typing or model restart.
- Added experiment-downtime regression instructions and remote diagnosis
  guidance. Private parent installation guidance updated; global adapters
  already route to the relevant sources and are unchanged.
- Publication: evidence4717178 and canonical closeout902e2a5 pushed to main
  and docs/remote-outage-20261018. Model health remained OK afterward.
- Validation:20 offline tests pass in30.594s, PowerShell parsing and AHK
  validation pass;50published files audited clean and73relative links resolve.

[Report](tasks/2026-10-18-remote-outage/2026-10-18-remote-outage-v1.0.md).

## 2026-10-18 - Hover delay and transparency

| # | Task | Status | Notes |
|---|---|---|---|
|1|Subtle widget transparency|Done|10% installed; actual alpha 230; tested 0% and 25% too.|
|2|One-second hover|Done|Brief passes hidden; leave resets timer; final measured opening 1052 ms.|
|3|Settings controls|Done|Saved alternate values through actual controls, restored 1 s / 10%.|

- 23:56 IST (17 October) - Reloaded the tray with shared dwell and native alpha.
- 00:02 IST - Native Settings save/reload and four timing runs pass.
- 00:03 IST - Eight-second drag: p95/max error 0/0 px, 258 samples.
- 00:05 IST - 20 behavior tests and 12 AHK status/recovery checks pass.
- Reviewed Settings screenshot; private config remains at 1000 ms and 10%.
- 00:09 IST - Implementation 0a8dc99 and source prerelease v0.1.5 published.
  Windows CI39058881135 passes. Public audit: 48 files / zero findings;
  69 relative links resolve. Final tray hidden/unpinned; model process unchanged.

[Report](tasks/2026-10-17-hover-transparency/2026-10-18-hover-transparency-v0.1.5.md).

## 2026-10-17 - Remote connection recovery

| # | Task | Status | Notes |
|---|---|---|---|
|1|Repair remote model connection|Restored; editor replay pending|Model and tunnels restarted; remote text/thinking/tool-call streams pass; automatic connection repair enabled.|

- 23:21 IST - Both owned tunnels and the local model were stopped. Remote port
  is now free; tunnel log records an earlier bind failure. Copilot log matches
  the screenshot's connection reset and network retries.
- 23:22-23:23 IST - Restored both loopback forwards and the guarded model server.
- 23:24-23:29 IST - Remote streams complete in 1.789s without thinking, 10.215s
  with thinking, and 14.062s for a tool-call response using remote VS Code Node.
- 23:29-23:33 IST - Added asynchronous, non-overlapping helper retries and
  per-host tunnel recovery. Three new tunnel tests and twelve AHK checks pass.
  Fixed initial timer replacement found during deployment; actual startup logs
  now show connection setup after about 2s. Editor draft preserved.
- 23:39 IST - Implementation e1716ea and source prerelease 0.1.4 published.
  Windows CI39056683095 passes all 20 behavior tests and 12 AHK checks.
  Audit: 47 files, zero findings; 62 relative links resolve. Shared lesson
  fe2ba07 published separately; both hosts' shared instruction links check OK.

[Report](tasks/2026-10-17-remote-recovery/2026-10-17-remote-recovery-v0.1.4.md).

## 2026-10-17 - Tray sign-in startup

| # | Task | Status | Notes |
|---|---|---|---|
|1|Restore the tray after restart|Done|Startup entry installed; exact shortcut launched and native hover verified. Full next reboot not forced.|

- 23:14 IST - Registered the existing installation for user sign-in and launched
  the exact shortcut. Its custom data directory and Qwen profile are preserved.
- 23:15 IST - Repeated shortcut launch leaves one tray. Seventeen controller/
  startup tests pass in 30.016s; eleven actual AHK status checks pass.
- 23:16 IST - Production-only hover/show/hide passes. Windows lists LLM Tray
  in Startup; installer opt-in and normal rerun preserve settings/registration.
  No model loaded. Six PowerShell parsers and AHK syntax validation pass.
- 23:20 IST - Implementation ac46b56 pushed to main; Windows CI39055357160
  passes. Public audit: 45 files, zero findings; 56 relative links resolve.
  Version 0.1.3 published. Icon verified on the main taskbar beside overflow.

[Report](tasks/2026-10-17-sign-in-startup/2026-10-17-sign-in-startup-v0.1.3.md).

## 2026-10-17 - Remote profile and tray border

| # | Task | Status | Notes |
|---|---|---|---|
|1|Make PC model available in remote VS Code|Partial verification|Named profile corrected; both remote hosts answer; actual picker check awaits the remote desktop becoming visible.|
|2|Green/orange tray border|Done|Installed and rendered Ready/Offline/Sleeping/Loading colors verified.|

- 22:20–22:24 IST — Found remote windows use a named profile while the Qwen
  provider existed only in Default. Added it to that profile, preserving
  providers, comments and unrelated settings. Copied only this model's proven
  128K capability/tool mapping. Private backups are outside Git.
- 22:25 IST — Installed the border update. Actual AHK status suite: 11 passes.
- 22:27 IST — Both remote hosts return REMOTE_OK from the PC model in 1.160s
  and 0.901s. Existing loopback tunnels retained; no server model installed.
- 22:29–22:32 IST — Render checks: 240 frame pixels match expected green or
  orange in each of four states. Native-sized PNGs reviewed and hash-listed.
- 22:34 IST — Windows virtual-desktop API confirms all VS Code windows are
  outside the active desktop. Configuration is complete; no chat draft edited.
- 22:39 IST — Implementation bffa8fe is published on main. Windows CI39052298183
  passes, including 13 backend tests, AHK status checks, parsing and installer
  validation. Public audit: 42 files/zero findings; 48 relative links resolve.
  [Source prerelease 0.1.2](https://github.com/paras-lehana/llm-tray/releases/tag/v0.1.2).

[Report](tasks/2026-10-17-remote-profile-border/2026-10-17-remote-profile-border-v0.1.2.md).

## 2026-10-17 - Smooth panel dragging

| # | Task | Status | Notes |
|---|---|---|---|
|1|Fix unsmooth dragging|Done|Native mouse-down fix installed; live, hover-panel and slow-endpoint movement checks pass.|

- 22:04 IST — Baseline: panel stayed at the starting position during almost
  the entire eight-second held-button trace; p95 tracking error 222 px.
- 22:06 IST — Native mouse-down movement and asynchronous status polling
  installed; live trace p95/max error 0/0 px. Model process preserved.
- 22:10 IST — Initially unpinned hover panel also tracks at 0/0 px and pins
  on drag. Thirteen existing backend tests pass in 23.849 seconds.
- 22:10 IST — Corrected fixture passes all 11 state checks and the five-second
  endpoint drag stress check. Model process unchanged; only passive requests.
- 22:12 IST — Settings, reload/persisted position and unpin/hide pass. Five
  PowerShell parsers and AHK syntax pass; public audit: 39 files, zero findings.

[Drag fix report](tasks/2026-10-17-smooth-drag/2026-10-17-smooth-drag-v0.1.1.md).

- 22:14 IST — Published implementation f1a89ec on main; Windows CI39050696922
  passes, including actual AHK status checks. Forty relative links resolve.
- 22:16 IST — One anomalous repeat is retained in the report. Added actual
  cursor sampling and immediate stop on interference; final eight-second run
  passes at 0/0 px, no interference. Tray unpinned; model left running.
- 22:18 IST — Probe refinement and canonical closeout pushed as ce641cc.
  [Version 0.1.1](https://github.com/paras-lehana/llm-tray/releases/tag/v0.1.1)
  is the source prerelease for this fix; runtime/model dependencies stay external.

## 2026-10-17 - Tray-first controller and remote workspaces

Implementation published as b1356f3 on main; Windows CI39045470914 passed. Version0.1.0.

- Actual hover/hide, pin/drag, Settings, default/changed shortcut and power
  click lifecycle tests pass. Hidden GPU setting and pinned position survive
  reload; custom data argument is preserved. A conflicting shortcut is refused.
- Qwen custom launcher remains monitored with native1800second idle sleep.
- Two remote loopback tunnels answer the PC model; Copilot provider is added.
  No editor typing; actual remote chat/file-read validation remains pending.
- 13 offline tests pass17.546s; four PowerShell parsers and AHK syntax pass.
- Fresh pinned installer extraction and repeat config preservation pass.
- Public repo created; README, three provider examples, SSH guide, reviewed
  UI crops and LinkedIn/Medium drafts prepared. No social posts or cloud calls.
- Old lab launcher shortcuts now point at the new tray; no boot startup.

[Forwardable report](tasks/2026-10-17-tray-first/2026-10-17-tray-first-v0.1.0.md).

Final native checks: tray-click pin/unpin passes, missing GPU data is labeled
without disabling model controls, default Ctrl+Alt+L and GPU0 are restored.
The panel is left hidden/unpinned; model listener and both SSH tunnels remain
alive. Current runtime process arguments confirm1800second idle and128K.
Legacy lab docs63379c8 pushed,37tests pass15.233s; public audit171files/0findings.

Canonical A-G summary is saved in prompts.md. The published report distinguishes
configured remote transport from pending fresh editor verification. No social
posting was performed; the0.1.0source release is marked preliminary.


## Agent Deferred

| # | Item | Deferred On | Reason | Status |
|---|---|---|---|---|
|1|Hover/transparency request|2026-10-18|All requested implementation completed; no new deferred item.|Done|

## Agent Suggestions

| # | Suggestion | Raised On | Priority | Status |
|---|---|---|---|---|
|1|Keep 1 second / 10% initially; adjust in Settings for preference or readability.|2026-10-18|Low|Available to owner|
