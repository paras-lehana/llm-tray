# Prompt log - LLM Tray

Last updated:2026-10-17 (Asia/Kolkata).

| # | Date | Topic | Type | Status | Link |
|---|---|---|---|---|---|
|1|2026-10-17|Tray-first controller and remote access|Feature|Published; remote UI pending|[Entry](#tray-first-controller-and-remote-access)|
|2|2026-10-17|Smooth panel dragging|Bug Fix|Done|[Entry](#smooth-panel-dragging)|
|3|2026-10-17|Remote profile and status border|Config / Bug Fix|Configured; picker verification pending|[Entry](#remote-profile-and-status-border)|
|4|2026-10-17|Tray sign-in startup|Bug Fix|Done; published 0.1.3|[Entry](#tray-sign-in-startup)|
|5|2026-10-17|Remote connection recovery|Bug Fix|Restored; published 0.1.4; editor replay pending|[Entry](#remote-connection-recovery)|

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


## Remote profile and status border

Date: 2026-10-17, 22:38 IST. Project: llm-tray; branch: main.
Type: Config / Bug Fix. Files changed: 15 public files, private profile settings.

### Original prompt

> cant find the llm on remote servers via vscode, can you check, windows already open. its just remote server login , the llm would run from local like here. i think we just need simple configuration.
> Also that icon can have a border around that can have green if ON and orange if the model is off.

### Pre-flight

- Preserve existing providers and editor drafts (project AGENTS.md).
- Keep host-specific settings private (llm-tray repository rules).
- Test the actual model picker and both icon states (native UI regression checks).

The UI and context-maintenance skills were reused. Sources, commands, file
inventory and limitations are recorded in the linked report. The remote desktop
question remains unanswered; configuration/API checks are distinct from UI proof.

### Canonical closeout

**A. Updated:** Your remote windows use **Agentic Coder**, but Qwen was configured only in **Default**. I added **PC Qwen3.6 Q4 - Thinking - 128K - SSH** to the correct profile. Inference still runs on your PC.

The tray now has a **green border when Ready** and an **orange border when off, sleeping, or loading**.

**B. Verification:** Both remote servers answered through the PC model in **1.16s and 0.90s**. Eleven status checks and four icon-state checks passed. Existing providers/settings were preserved. Code, documentation and reviewed icons are published as [bffa8fe](https://github.com/paras-lehana/llm-tray/commit/bffa8fe); [report and file inventory](https://github.com/paras-lehana/llm-tray/blob/main/docs/tasks/2026-10-17-remote-profile-border/2026-10-17-remote-profile-border-v0.1.2.md).

**C. Status**

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|2|Icon border|green if ON and orange if the model is off|DONE|Installed and color-checked.|
|1|Remote VS Code|cant find the llm on remote servers via vscode|PARTIALLY DONE|Profile fixed and connections tested; picker verification pending.|

**D. Finding:** The remote VS Code windows are on another Windows virtual desktop, which prevented the live click check. No chat drafts were edited.

**E. Pending**

| Item | Status | Reason |
|---|---|---|
|Remote model-picker check|Pending|Requires the desktop containing those VS Code windows.|

**F. Next step:** In each remote window, open Copilot’s model picker and select **PC Qwen3.6 Q4 - Thinking - 128K - SSH**. No remote model installation is needed. [VS Code model setup guide](https://code.visualstudio.com/docs/agent-customization/language-models).

**G. Forwardable summary**

```text
LLM Tray — remote configuration corrected and status border installed (version 0.1.2)

What's done
- The remote development windows used a different settings profile from the local window. The PC's Qwen model is now configured in that profile, with the existing model limits preserved.
- Both remote servers successfully received short answers from the model running on the PC. No model was installed on either server, and existing connections were retained.
- The tray icon now has a green border when the model is ready and an orange border when it is off, sleeping or loading. The detailed hover status remains available.
- Existing providers and unrelated settings were preserved. The changes and test results are documented in the public repository.

Suggested next steps
- Switch to the Windows desktop containing the remote development windows and select the configured Qwen model.
- Complete one small chat there. Connection tests passed, but the actual model-picker check is still pending.
```


## Tray sign-in startup

Original request:
> cant see the icon after restart, please we need it everytime..

Project: llm-tray; branch: main. User explicitly requested persistent startup.
The previous default opt-out is not an approval gate for this request. Keep
installed files/data on the E-drive; use the standard per-user Windows Startup
shortcut. Start the tray without loading a model. No editor input or reboot.

Pre-flight: after reboot there was no tray process or startup entry. Read
project AGENTS, README, DESIGN, configuration/testing/task/prompt logs, the
installer, shared guide/router/logging protocol and context-maintenance skill.
Project regression guidance updated; shared adapters still point to it.

[Forwardable report and file inventory](tasks/2026-10-17-sign-in-startup/2026-10-17-sign-in-startup-v0.1.3.md).
Canonical A-G closeout:

**A. Fixed:** The icon is running beside the clock and is now configured to start automatically whenever you sign into Windows.

**B. Verified:** The startup entry was missing. Added a [Windows sign-in shortcut](https://support.microsoft.com/en-gb/windows/experience/startup-boot/configure-startup-applications-in-windows) pointing to your existing installation. Repeated launches leave one tray; hover and settings preservation passed. **17 tests, 11 tray-status checks and Windows CI passed.** Published `v0.1.3`, commit `ac46b56`. [Report and changed-file inventory](https://github.com/paras-lehana/llm-tray/blob/main/docs/tasks/2026-10-17-sign-in-startup/2026-10-17-sign-in-startup-v0.1.3.md).

**C. Your request**

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|1|Restore persistent tray|cant see the icon after restart, please we need it everytime..|DONE|Enabled sign-in startup and verified the actual shortcut and visible icon.|

**D. Additional work:** Added reusable startup enable/disable controls, regression tests and documentation. Starting the tray does not load the model.

**E. Remaining verification**

| Item | Status | Reason |
|---|---|---|
|Full reboot check|Deferred|Tested the exact startup shortcut without interrupting your session.|

**F. Recommendation:** Keep tray startup enabled. Use **Ctrl+Alt+L** when you want to start the model; its current orange border reflects the stopped model.

**G. Copyable summary**

```text
LLM Tray - available automatically after Windows sign-in (version 0.1.3, installed 17 October 2026, 23:20 IST)

What's done
- Fixed the missing startup registration that left the tray absent after a restart. The icon is running and visible beside the Windows clock.
- The existing model selection, resource display and shortcut settings are preserved. Starting the tray does not automatically load the model or reserve its graphics memory.
- Reopening the launcher leaves one tray instance. The actual icon and hover panel were checked, and automated Windows checks passed.
- The public project now includes startup controls, setup instructions and regression coverage.

Suggested next steps
- Leave tray startup enabled and use the model toggle when needed.
- Confirm the icon returns after the next normal restart. A full reboot was deliberately not forced during the current session; verification used the exact registered startup launcher.
```


## Remote connection recovery

Original request (host redacted for publication):
> this did not work on [remote SSH host]

Screenshot: Copilot retries, then fetch failed / read ECONNRESET with the
PC Qwen thinking model selected. No screenshot or raw transcript published.

Pre-flight: project llm-tray on main; read project AGENTS, task/remote guides,
shared server-access/troubleshooting guidance and Windows/VPS host facts.
Preserve the existing editor draft and providers. Inspect model, tunnel and
client logs independently; test actual remote streamed output.

[Report and file inventory](tasks/2026-10-17-remote-recovery/2026-10-17-remote-recovery-v0.1.4.md).
Canonical A-G closeout:

**A. Connection restored.** After reboot, the PC model was stopped and its SSH tunnel had failed to start. **Both are running now.**

**B. Tested from the remote server:**

| Test | Completed in |
|---|---:|
| Streamed reply without thinking | 1.8 seconds |
| Streamed reply with thinking | 10.2 seconds |
| Streamed tool call using remote VS Code's Node runtime | 14.1 seconds |

These are small transport tests, not a full coding-workflow benchmark. Your normal thinking settings remain unchanged. **20 behavior tests, 12 tray checks and Windows CI passed.** Published `v0.1.4`, commit `e1716ea`. [Report and changed-file inventory](https://github.com/paras-lehana/llm-tray/blob/main/docs/tasks/2026-10-17-remote-recovery/2026-10-17-remote-recovery-v0.1.4.md).

**C. Your request**

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|1|Repair remote connection|this did not work...|DONE|Restored the model and tunnels; verified remote streaming and tool-call output.|

**D. Additional fixes:** Enabled connection checks every **60 seconds**, with failure/recovery notifications and protection against overlapping attempts. Updated the public documentation and shared troubleshooting guidance.

**E. Remaining verification**

| Item | Status | Reason |
|---|---|---|
|Your original Copilot conversation|Not replayed|Preserved your chat; no editor input sent.|
|Full reboot recovery|Not forced|Tested startup/retry behavior without restarting your PC.|

**F. Next step:** Click **Try Again** in that chat. After a full reboot, **Ctrl+Alt+L** starts the model; tray startup reconnects the tunnels. Native idle sleep can wake automatically on the next message.

**G. Copyable summary**

```text
LLM Tray - remote connection restored (version 0.1.4, live 17 October 2026, 23:39 IST)

What's done
- Found that the computer restart left the model stopped and the dedicated remote connection unavailable. Both are now running again.
- Verified complete remote replies with thinking enabled and disabled, plus valid streamed function-call output using the remote editor's runtime. These checks took approximately two, ten and fourteen seconds respectively.
- Added automatic connection checks every minute, failure and recovery notices, and safeguards against duplicate attempts. Existing thinking settings were preserved.
- Published the fix, documentation and regression checks. Automated Windows validation passed.

Suggested next steps
- Retry the original editor conversation. It was preserved and was not automatically replayed during diagnosis.
- Start the model once after a full computer restart. Automatic connection repair does not load the model itself.
- Assess larger coding conversations separately: successful short connection tests do not establish their response time or correctness.
```
