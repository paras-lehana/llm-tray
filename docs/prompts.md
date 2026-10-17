# Prompt log - LLM Tray

Last updated:2026-10-17 (Asia/Kolkata).

| # | Date | Topic | Type | Status | Link |
|---|---|---|---|---|---|
|1|2026-10-17|Tray-first controller and remote access|Feature|Published; remote UI pending|[Entry](#tray-first-controller-and-remote-access)|
|2|2026-10-17|Smooth panel dragging|Bug Fix|Done|[Entry](#smooth-panel-dragging)|

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


## Smooth panel dragging

Date: 2026-10-17, 22:16 IST. Project: llm-tray; branch: main.
Type: Bug Fix. Files changed: 14.

### Original prompt

> the dragging is not smooth

### Pre-flight context

- Test the actual Windows panel, including movement during status checks (project: llm-tray).
- Preserve the running model and editor drafts (project AGENTS.md).
- Record and publish the fix with its test results (existing public repository).

UI interaction and context-maintenance skills were applied. Read-source details,
full file inventory and failed attempts are in the linked task report.

### Canonical closeout

**A. Done:** Fixed and installed. Hold the panel’s title to drag it; movement now starts immediately on mouse-down.

**B. Verified:** Live and slow-endpoint drag tests passed with **0 px sampled tracking error**. All 13 backend tests and 11 status checks passed, along with position persistence and Windows CI. Drag/status code, regression tests, CI and documentation are updated; no runtime dependencies added. Published fix: [f1a89ec](https://github.com/paras-lehana/llm-tray/commit/f1a89ec1500ab545cb4300e6a88ace0513a4cca1). [Full report and file inventory](https://github.com/paras-lehana/llm-tray/blob/main/docs/tasks/2026-10-17-smooth-drag/2026-10-17-smooth-drag-v0.1.1.md).

**C. Request status**

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|1|Smooth dragging|the dragging is not smooth|DONE|Fixed drag initiation and blocking status checks.|

**D. Additional findings:** The previous test checked only the final position. New tests measure continuous movement and detect mouse interference. Your model stayed running.

**E. Pending:** None for this fix. Movement between monitors with different scaling remains untested.

**F. Suggestion:** Keep the slow-endpoint movement test in future release checks.

**G. Forwardable summary**

```text
LLM Tray — dragging fix installed (version 0.1.1, 17 October 2026)

What's done
- The panel now starts moving when its title is pressed and follows the pointer while held. Dragging also pins the panel, and its position survives restarting the controller.
- Slow model-status checks no longer block movement. Resource meters pause during dragging and resume after release.
- Movement was tested with the running model and a deliberately delayed test server. The final recorded checks showed no sampled position error. Existing controller tests and automated Windows checks also passed.
- The model stayed running throughout the fix. The public repository includes the changes, repeatable checks and a report documenting both successful and failed test attempts.

Suggested next steps
- Keep continuous dragging and delayed-response checks in future releases.
- Test movement between differently scaled monitors before claiming support for that setup.
```
