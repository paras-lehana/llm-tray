# Remote Copilot interruption during model experiments

18 October 2026, Asia/Kolkata. LLM Tray remains version0.1.5; this is an
operational investigation and documentation change, not a new binary release.
[Owner input](owner-input.md). Branch: `docs/remote-outage-20261018`.

## Outcome

The remote model route works now. The reported `other side closed` errors
coincide with an explicitly requested stop of the shared PC model during the
Strata experiment. The stop interrupted an active remote Copilot request.
The assistant caused this availability interruption; changing the owner's
firewall, SSH configuration, model quantization or context size would not
repair that missing model listener.

The normal Qwen server had already been restored at06:01 before this follow-up.
This investigation did not restart it, change editor configuration, type in
the editor, or stop the model/tunnels. It revalidated the actual remote path
and left the same production process available. Native thinking,128K context,
CPU q8KV and1800-second idle sleep remain unchanged. The owner can retry the
failed chat; old error cards do not disappear when the server comes back.

## Evidence and timeline

| Time IST | Evidence |
|---|---|
|00:20:13.188|Remote Copilot log: Qwen request succeeds in41.738s.|
|00:20:40.550|Another Qwen request succeeds in25.531s.|
|00:20:56.718|Another Qwen request succeeds in13.521s.|
|00:21:01.846|Production launcher's `stop.request` is written.|
|00:21:03.046|Remote Copilot logs `TypeError: terminated`; Qwen request ends as `networkError` after4.814s.|
|00:21:05|Tray records Offline. The model's stop receipt says `requested_stop`.|
|00:21:08–00:23:07|Remote Copilot records repeated `fetch failed` / `SocketError: other side closed`, matching the screenshot time.|
|02:03:16|Tray records Ready after restoration between experiments.|
|03:48:29|Tray records the later experiment outage.|
|06:01:10|Tray records Ready after final production restoration.|
|06:13–06:15|New remote native-thinking and complete tool-result streaming checks pass.|
|06:16|Direct and mirrored local URLs return the correct alias and131072 context; original06:01 model process remains running.|

The model's last pre-stop task was actively processing a14492-token prompt,
with a14462-token cached prefix; it has no completion entry. This was not a
131K-context rejection. The remote listener is bound only to127.0.0.1:18888.
The live dedicated tunnel was started before this outage and still connects.

The screenshot's exact client UUIDs were not found in the examined logs.
Attribution uses matching time, model, remote error stack, explicit stop
receipt, active model task and the preceding successful requests. It does not
claim an exact UUID correlation. No evidence here establishes a firewall fault
or a failure of the native idle-wake feature.

## Current remote verification

The probe used the remote editor's installed Node v24.21.0 and its installed
Undici HTTP implementation, through the configured18888 loopback URL to the
PC's `qwen3.6-35b-a3b-q4`. It parsed SSE chunks, assembled tool-call fragments,
checked the end marker and retained reasoning in the follow-up history.
The native thinking setting was left enabled. Probe-only limits were1024
output tokens and180seconds per request; production output limits remain
16384. Temperature0.6 and top_p0.95 match the configured provider.

| Probe | First data | First final text | Complete | Result |
|---|---:|---:|---:|---|
|Thinking-enabled greeting|0.953s|11.443s|11.629s|Exact `REMOTE_OK`; HTTP200, stop, SSE DONE|
|Instruction file tool request|10.326s|Tool call only|20.676s|`read_fixture`, valid JSON path `AGENTS.md`, finish `tool_calls`, DONE|
|Returned file → final answer|13.026s|52.139s|58.991s|All3 instruction answers correct, HTTP200, stop, DONE|

The two-turn tool exchange took79.667seconds. The fixture was the actual
pre-change public LLM Tray AGENTS.md, copied to a private remote diagnostics
folder. It correctly quoted that tray startup must not load the model, status
polling must not call `/slots`, and editor typing is unauthorized. The probe
provided the fixture content itself; it did not execute model-selected shell
commands or pretend to invoke Copilot's file tools. This is transport and small
instruction verification, not a new coding benchmark or a fresh editor UI pass.

Both Default and the owner's active named profile already contain the correct
remote custom endpoint, Qwen alias,98304 input budget and16384 output budget.
No registry/provider/settings modification was needed. The PC's direct8080
and mirrored18888 model-list requests both return the same alias/context.
At06:16 the process RSS is19.18GiB; whole-GPU use is6622MiB with3432MiB free.
These are snapshots, not peak requirements or allocations owned solely by Qwen.

## Operational correction

The project regression instructions and the private parent installation guide
now require announcing experiment downtime, checking active requests and waiting
for them to finish. A temporary idle gap between agent tool turns must not be
treated as proof the owner finished chatting. Remote streaming, including a
tool-result/final-answer cycle, must be checked after restoration. This is an
agent operating rule, not an automated lock or a zero-downtime guarantee.
The remote-access guide now explains this failure mode.

The agent-context-maintenance skill was applied. The shared Codex entry point,
Claude router and context-maintenance guide were reviewed; their existing
routing already covers these project rules, so no global adapter or shared
instruction repository change was needed. No new runtime dependency, firewall
rule, boot-start loop or additional inference engine was introduced.

## Other findings and limits

- The remote log separately records `gpt-5-mini` helper requests rejected with
  `model_not_supported` before the outage. Successful Qwen requests appear
  between those failures. This distinct Copilot helper issue was preserved in
  evidence; provider identity/settings were not guessed or changed to mask it.
- A fresh replay in the actual Copilot editor remains unperformed under the
  owner's no-editor-typing restriction. The owner's historical UI requests
  succeeded before the stop; that is historical evidence, not today's UI pass.
- No new restart, load/unload, long-context quality, tray interaction or native
  idle-wake cycle was attempted. Existing lifecycle evidence remains separate.

## Validation and files

Read: parent/project AGENTS, shared Codex guide, Claude router, platform/logging
rules, troubleshooting/server-access/Git guidance, context-maintenance skill,
Codex integration README, remote host facts/service-registry excerpts, project
README/DESIGN/tasks/prompts/remote-access/testing, the previous recovery report,
tunnel implementation, active profile registry, model/tray/client logs and stop
receipts. Private host settings and raw transcripts remain outside publication.

Checks: installed remote Node/Undici three-request probe; direct and mirrored
model-list/props; model process identity; PowerShell parser; AHK `/validate`;
offline controller/startup/tunnel suite; public-content audit and relative-link
verification. All20 offline tests pass in30.594seconds; PowerShell parsing and
AHK validation pass. The public audit checks50tracked files with zero findings,
and all73relative documentation links resolve. No UI/source code changed, so native interaction tests were not
repeated and the installed0.1.5 version is retained.

| File | Change |
|---|---|
|`AGENTS.md`|Regression rule for experiment interruption and complete remote tool cycle|
|`docs/remote-access.md`|Requested-stop diagnosis and downtime procedure|
|`docs/tasks/README.md`|Incident report index|
|`docs/tasks.md`|Task status and measured timeline|
|`docs/prompts.md`|Sanitized request, preflight and canonical final response|
|`docs/tasks/2026-10-18-remote-outage/owner-input.md`|Owner request and screenshot description|
|This report|Cause, evidence, current verification and limits|

Outside Git: the parent installation AGENTS gained the same operational
constraint; private Node/Python diagnostic scripts and evidence stay in ignored
local-data and the remote private diagnostics directory. No model weights or
credentials were read into the publication set.
