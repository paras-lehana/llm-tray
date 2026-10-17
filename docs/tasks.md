# Task log

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
