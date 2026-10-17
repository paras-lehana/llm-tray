# Task log

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
