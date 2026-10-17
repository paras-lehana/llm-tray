# Prompt log - LLM Tray

Last updated:2026-10-17 (Asia/Kolkata).

| # | Date | Topic | Type | Status | Link |
|---|---|---|---|---|---|
|1|2026-10-17|Tray-first controller and remote access|Feature|Published; remote UI pending|[Entry](#tray-first-controller-and-remote-access)|

## Tray-first controller and remote access

Project:llm-tray; branch:main; owner authorized a separate public GitHub repo.
Original owner pointers are preserved with server aliases redacted in the
[task report](tasks/2026-10-17-tray-first/2026-10-17-tray-first-v0.1.0.md).

Pre-flight: separate reusable project under the E-drive; installed model uses
128K CPU KV and1800seconds idle; local interface remains loopback; two SSH
workspaces share the PC model. Existing services own remote8080. Do not type
in editors or change model/driver/BIOS settings. Publication excludes private
configuration, server hostnames, keys, weights and editor transcripts.

Sources read: project/shared AGENTS; shared platform, logging, topic router,
Windows host facts and server-access guidance; existing lab README, methodology,
tasks, desktop implementation, editor config scripts; UI/design, content
publishing/master prompt and context-maintenance skills. Native runtime and
installed VS Code source were inspected. Primary Microsoft, AutoHotkey and
Ollama documentation supports implementation choices. Shared adapters unchanged;
project AGENTS and thin Claude/Copilot adapters carry the new regression cases.

## Canonical A-G closeout

A. **Published and running:** [LLM Tray](https://github.com/paras-lehana/llm-tray).

- Small tray icon with VRAM/RAM/GPU meters and model status.
- Hover for details; pin and drag the panel when needed.
- **Ctrl+Alt+L** toggles your model. Right-click → **Settings** changes metrics, shortcut and profile.
- Both remote workspaces can reach your PC model. Select **PC Qwen3.6 Q4 - Thinking - 128K - SSH** under **PC Qwen over SSH**. Fresh editor conversations remain untested.

B. **Implementation and tests:** native AutoHotkey/PowerShell controller, configurable llama.cpp/Ollama/custom-script profiles, SSH helper, installer and documentation. Your Qwen settings, 128K context and 30-minute idle sleep remain unchanged.

Actual hover/pin/drag, settings, click and shortcut tests passed; **13 backend tests and Windows CI passed**. Remote API replies took approximately **6 seconds including wake**, then **1 second**. These do not establish Copilot conversation speed. Implementation: `b1356f3`; lab documentation: `63379c8`, both on `main`. [Full report and file inventory](https://github.com/paras-lehana/llm-tray/blob/main/docs/tasks/2026-10-17-tray-first/2026-10-17-tray-first-v0.1.0.md).

C. **Your requested items**

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|2|Hover panel|“hover above the icon”|DONE|Tray-first; details hide when you leave.|
|3|Pin and drag|“pined…dragging possible”|DONE|Pin button and saved position.|
|4|Compact meters|“small VRAM RAM GPU…ready icon”|DONE|Three meter rows and status dot.|
|5|Public repository|“make a public github repo”|DONE|Public source and setup guide.|
|6|Customization|“choose what to show…change shortcut”|DONE|Settings plus configurable model/scripts.|
|7|Promotion|“good readme and promotion”|DONE|README and LinkedIn/Medium drafts; no social posts.|
|1|Remote access|“configure locall llm on my remote server too”|PARTIALLY DONE|Configured and API-tested on both; fresh Copilot UI test pending.|

D. **Additional fixes:** corrected settings reload, false failure notifications and shortcut-conflict detection. Existing remote services were preserved; SSH uses loopback port **18888**. Windows may keep the icon under its **^** tray overflow.

E. **Remaining verification**

| Item | Status | Reason |
|---|---|---|
|Remote Copilot chat/file reads|Pending|Your instruction to avoid editor typing remains active.|
|Real Ollama model, mixed-DPI UI|Unverified|Ollama has simulated API coverage; desktop checks used this PC.|

F. **My recommendation:** use the 30-minute idle sleep during coding and manual Stop when you want memory released immediately. Begin remote testing with a fresh chat and one small file-read request. This controller improves visibility and control; the earlier slow Copilot responses remain unresolved.

```text
LLM Tray — local model controls beside the Windows clock (version 0.1.0, live 17 October 2026, 21:06 IST)

What's done
- A compact tray meter shows graphics memory, system memory, GPU activity and model status.
- Hover opens details. The panel can be pinned and dragged, and users can choose their metrics, shortcut and model launcher.
- The project is public, with setup instructions, examples and draft launch posts.
- Both remote development environments can reach the PC model through private connections. Short response checks passed; full editor conversations still need verification.
- Existing model settings and automatic idle unloading were preserved. The controller and model remain available.

Suggested next steps
- Verify one small file-reading conversation in each remote workspace before a large coding task.
- Use idle unloading during normal work and the manual stop control when memory is needed immediately.
- Assess editor response time separately; this release does not resolve the previously observed slow replies.
```
