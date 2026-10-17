# LLM Tray 0.1.2 — remote VS Code profile and status border

2026-10-17, Asia/Kolkata. Configuration and icon changes are installed.

## A. Outcome

Done: the tray icon now has a green frame when the model is Ready and an
orange frame when it is stopped, sleeping, loading or unavailable. Hover text
still gives the exact state; resource bars still report whole-device usage.

Remote setup is configured and API-tested, with UI verification pending:
both remote VS Code windows use a named profile. The local model had been
registered only in Default. The named profile now has the same SSH model
entry and its existing proven 128K capability settings. Both remote hosts
answered a short request through the existing tunnel to the Windows PC.
Inference stays on the PC; no model was installed on either remote host.

## B. Technical changes

### Profile correction

The local VS Code profile association store identifies both SSH workspaces
with the same named profile. Its `chatLanguageModels.json` initially contained
only the Copilot provider, while Default contained the custom Qwen provider.
This explains why configuring Default earlier did not make the model available
to those windows.

Added `PC Qwen over SSH` to the named profile's registry and preserved every
existing provider. The model entry is **PC Qwen3.6 Q4 - Thinking - 128K - SSH**,
ID `qwen3.6-35b-a3b-q4`, using loopback port 18888. Existing dedicated SSH
connections already forward that port back to the PC's port 8080. One local
mirror provides the same URL to a provider executing on the PC.

Copied only this model's `chat.agentHost.copilot.modelCapabilityOverrides`
entry: 131072 context, 98304 prompt, 16384 output, built-in tools, excluding
custom/MCP tools as in the existing tested local configuration. Existing
settings, JSONC comments and unrelated providers were preserved and compared
after writing. Private backups and host-specific files remain outside Git.
No permissions, unrelated model defaults, editor drafts or server services
were changed. Existing chats were not silently switched from their model.

### Tray frame

`src/LLMTray.ahk` passes a border color to its existing native icon renderer.
The two-pixel frame on the 32px bitmap is `#86E3A7` for Ready and `#FFAD5C`
otherwise. Header marks are inset so they do not collide with the frame.
The original detailed status dot and text remain. Green and orange contrast
against the background at 10.60:1 and 8.90:1 respectively.

Reviewed renderings, actual 32px dimensions:

![Ready with green frame](../../../assets/tray-ready.png)
![Offline with orange frame](../../../assets/tray-offline.png)

### File inventory

- `src/LLMTray.ahk`: border color mapping and drawing.
- `assets/tray-ready.png`, `assets/tray-offline.png`, `assets/SHA256SUMS`:
  reviewed icon renderings and publication hashes.
- `README.md`, `CHANGELOG.md`, `docs/DESIGN.md`: 0.1.2 behavior and colors.
- `docs/remote-access.md`: profile-specific registry setup and endpoint checks.
- `AGENTS.md`, `docs/testing.md`: remote profile/picker and icon-state checks.
- `.github/README.md`, `docs/tasks/README.md`: report/navigation links.
- `docs/tasks.md`, `docs/prompts.md`, this report: evidence and closeout.
- Private named-profile registry/settings: owner configuration only, not Git.

No runtime dependencies were added. Existing native AHK/PowerShell architecture
and the 30-minute model idle policy remain intact.

## C. Request status

| # | Pointer Task | Original Pointer Text | Status | What Was Done |
|---|---|---|---|---|
|2|State-colored icon border|that icon can have a border around that can have green if ON and orange if the model is off|DONE|Installed green Ready/orange other-state frame; rendered colors checked.|
|1|Remote VS Code model|cant find the llm on remote servers via vscode, can you check, windows already open. its just remote server login , the llm would run from local like here. i think we just need simple configuration.|PARTIALLY DONE|Correct profile configured; both remote API checks pass. Actual picker interaction is pending desktop access.|

## D. Validation and findings

| Check | Result |
|---|---|
|Remote host A `/v1/models`|Correct PC model returned|
|Remote host B `/v1/models`|Correct PC model returned|
|Remote host A small generation|REMOTE_OK, 1.160 seconds|
|Remote host B small generation|REMOTE_OK, 0.901 seconds|
|Named-profile registry merge|Existing provider entries preserved|
|Named-profile settings merge|Existing parsed values/comments preserved; one model override added|
|Actual AHK status suite|11 checks pass, passive endpoints only|
|AHK syntax and installed stderr|Pass; no runtime error output|
|Ready frame|All 240 frame pixels equal #86E3A7|
|Offline, Sleeping, Loading frames|All 240 frame pixels equal #FFAD5C in each case|
|Native-sized visual inspection|Ready and Offline rendered PNGs inspected|
|Windows CI39052298183|Pass: backend/status checks, parsers, installer and audit|
|Public content/link audit|42 tracked files, zero findings; 48 relative links, zero missing|

Pixel evidence comes from the actual drawing buffer of a disposable,
instrumented copy of the same AHK source running against controlled status
responses. It is not a photograph of the Windows notification area. The
installed production tray was reloaded separately and reported Ready. No real
model stop was needed to test the orange state.

The first image inspection attempt used an unavailable Python imaging package;
Windows' existing drawing API was used instead, with no dependency installed.
The background control-click attempt did not complete and its exact disposable
helper process was stopped. No chat text was entered.

Windows reports all three VS Code windows as shell-cloaked. The documented
virtual-desktop interface also returns false for “on current desktop” for
each window. This confirms why foreground/physical click verification was
unavailable; an open window is not necessarily on the currently active desktop.
The earlier class-factory attempt used the wrong COM class ID and failed;
the corrected documented interface returned the above results successfully.

## E. Pending

| Item | Status | Reason / next check |
|---|---|---|
|Remote model picker and actual editor chat|Pending|Switch to the desktop containing the remote windows, open Copilot's model picker, choose the configured Qwen entry, then test a small fresh chat when authorized.|

The desktop-switch question was sent while other checks continued. The owner
has not yet replied. The current desktop and existing chat drafts were left
alone. API success is not claimed as a completed editor conversation.

## F. Recommendation

Use Manage Models from the target window when adding providers: it opens that
window's profile configuration. Keep the same model listener and dedicated
loopback tunnels; another server-side installation is unnecessary.

## Sources and commands

Read project AGENTS, README, design, remote-access guide, task/prompt logs,
AHK source and existing setup helper. Shared Codex/router/platform/logging
instructions and applicable Windows, Git, Python, testing and troubleshooting
sources were already read in this conversation; server-access guidance and
host facts were read for this request. UI and context-maintenance skill
guidance was reused. Project regression guidance was updated; shared adapters
did not need changes. No unrelated shared-repository files were edited.

Commands: SSH `/v1/models` and short chat requests, native AHK `/validate`,
`tests/check_tray_status.py`, native drawing-buffer checks, scoped profile
merge/verification, Windows UI Automation and virtual-desktop queries, public
content audit and Markdown link checks. Browser/mobile tests do not apply.
Routine backend lifecycle tests run in Windows CI; they were not repeatedly
rerun locally for this isolated icon change.

Primary references: [VS Code Custom Endpoint models](https://code.visualstudio.com/docs/agent-customization/language-models)
and [Microsoft's virtual-desktop membership API](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ivirtualdesktopmanager-iswindowoncurrentvirtualdesktop).

Published implementation: [bffa8fe](https://github.com/paras-lehana/llm-tray/commit/bffa8fe6abe6374a3321ece4694b2d3540985845),
main; [Windows CI](https://github.com/paras-lehana/llm-tray/actions/runs/39052298183).

## Original request

> cant find the llm on remote servers via vscode, can you check, windows already open. its just remote server login , the llm would run from local like here. i think we just need simple configuration.
> Also that icon can have a border around that can have green if ON and orange if the model is off.
