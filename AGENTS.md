# LLM Tray

## Scope
Native Windows tray controller for local inference. Read README.md,
docs/DESIGN.md and docs/tasks.md before edits. Shared owner policy is routed
through the installed Codex guide; this file remains portable for contributors.

## Architecture
AutoHotkey v2 renders the tray, hover/pinned panel and settings. Windows/NVML
provide whole-device metrics. PowerShell handles explicit model actions and
optional SSH tunnels. Config/state/binaries belong outside Git in local-data/.

## Critical Project Rules
- Loopback only by default. No telemetry, credentials, model downloads, blanket
  process-name kills, boot startup or model startup merely from launching UI.
- Exact process identity and creation time are required before stopping an
  owned child. Custom scripts are explicitly trusted user code.
- Poll passive status only. Never wake sleeping llama.cpp through /slots.
- Keep the tray visible; panel is hidden unless hovered or explicitly pinned.
- Use bounded requests and prevent overlapping model actions. Exit leaves
  the model alone. Preserve editor drafts; no editor typing is authorized.
- Windows-specific surface: browser/mobile/public-URL tests do not apply.
- Keep source and reviewed screenshots public, host configurations private.

## Browser Test Cases / Native Equivalents
- Actual tray hover reveals panel; moving away hides it; click/pin retains it.
- Drag a pinned panel, restart, verify position persists and is on-screen.
- Hold the title and trace a continuous path: the panel must track while the
  button is down, including slow/offline status endpoints. Measure tracking
  error with tests/measure-drag.ps1; final-position-only checks miss stutter.
- Metrics, order, unavailable GPU, thresholds and shortcut can be configured.
- Settings reload must preserve a non-default data directory and pinned position.
- Tray menu and global shortcut toggle with notifications and correct state.
- Manual Stop frees model memory; Sleep stays wakeable by the next request.
- Refuse foreign/stale process receipts; no second start under concurrency.
- Remote SSH endpoint returns the PC model and answers a small request.

## Required Validation
PowerShell parsing, offline controller tests, AutoHotkey /validate, actual
native interactions and public-content audit before commit/push. Report real
provider checks separately from simulated APIs. Update prompts/tasks, one
forwardable task report and changelog. Visible closeout includes owner A-G.

## Known Operational Notes
Sleep discards live KV; the client must resend history. Whole-GPU metrics
include games and other apps. The controller does not improve model latency.
Windows may put a new tray icon in overflow; users can drag it beside the clock.
