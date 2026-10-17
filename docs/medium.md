---
platform: medium
project: llm-tray
source_idea: Making local model availability and memory use visible in Windows
angle: tech build story
status: draft
version: 1.0
last_updated: 2026-10-17
word_count: 1441
published_url: ""
---

# I Put My LLM Beside the Clock

My local coding model shares an RTX 3080 with 10 GB of VRAM, 64 GB of system RAM,
and the applications I actually use. I wanted to see whether the model was
available and release its memory without opening a terminal. The first version
put a floating panel on the desktop. I quickly wanted something smaller.

That became [LLM Tray](https://github.com/paras-lehana/llm-tray): a Windows
notification-area icon with three resource rows, a model-status dot, and a
detail panel on hover. Pin the panel while investigating a load. Drag it out
of the way. Press Ctrl+Alt+L when you want to toggle the model.

It is an early release, with its limits documented. I care more about being
clear about what the button will do than filling the screen with controls.

## What should fit in a tray icon?

Very little. A normal Windows tray icon may be16 pixels across. Trying to pack
three readable numeric values and full labels into that space produces noise.
The icon therefore uses three colored meter rows, marked V, R and G, plus a
small status indicator. Exact memory values belong in the hover panel, where
there is room to distinguish used memory from total capacity.

The rows show whole-device VRAM, system RAM and GPU utilization. This detail
matters. A browser, video player or game can consume GPU memory while the model
is asleep. A meter that calls all of that memory “the model” would give the
wrong answer to the very question the tool is meant to help with.

You can hide metrics and change their order. Thresholds determine when usage
turns amber or red. Model state also has a word: Ready, Sleeping, Working or
Offline. Color alone is not enough to explain whether your next message can
reach an inference server. Missing NVIDIA data is displayed as unavailable,
rather than quietly turned into a reassuring zero.

## Why did I keep the larger panel?

The larger view was useful; its constant presence was the problem. Hover now
reveals it, and moving away hides it. A pin keeps it open. Dragging the header
pins the panel and stores its position for the next launch. Closing the panel
does not stop a model that might still be answering in another application.

The implementation uses AutoHotkey v2 and native Windows surfaces. Memory comes
from Windows, and supported GPU counters come directly from the existing NVIDIA
driver's [NVML library](https://docs.nvidia.com/deploy/nvml-api/). There is no
browser runtime and no new command-line monitoring process every few seconds.
That is an architectural choice, not a claim that the application has zero cost.

Shell behavior required actual testing. A hidden tray icon can report the
overflow arrow's position through
[Shell_NotifyIconGetRect](https://learn.microsoft.com/en-us/windows/win32/api/shellapi/nf-shellapi-shell_notifyicongetrect).
The hover logic checks the actual button before opening the panel, so hovering
over the general overflow arrow does not pretend you selected this model.
The click and keyboard controls remain available when hovering is disabled.

## What does stopping a model mean?

It depends on the runtime. With a supported llama.cpp server, the built-in
profile can add a native 30-minute idle-sleep setting. Sleep keeps the listener
available, unloads the model, and reloads it when a new task arrives. A manual
Stop ends the owned server process. There is then no listener to receive a chat
request until the user starts it again.

Those states deserve different language. “Offline” should not suggest that
chatting will automatically start a process that no longer exists. “Sleeping”
should not look like a broken installation. The controller uses passive status
polling so that looking at the meter does not repeatedly wake a sleeping model.
The available native sleep flags still need checking against your installed
llama.cpp version; the tray cannot add a feature to an older inference engine.

Ollama has a different ownership model. The tray talks to an existing daemon,
preloads a chosen installed model, or asks it to unload that model with
`keep_alive: 0`. It leaves the daemon alone. The
[Ollama generation API](https://docs.ollama.com/api/generate) documents that
keep-alive control. Other clients can supply their own keep-alive values, so
the tray's setting is not a permanent global promise about every future request.

## Does sleep keep all my context?

No. This was one of the most useful distinctions from the wider local-model
experiments. Live KV state and the saved conversation are different things.
Unloading a model can release its live cache as well as the weights. Your
editor may retain messages and resend them, but that can require processing
the prompt again. A large advertised context window does not remove that work.

> Decide how you want memory released, then test what the next real request
> does. A green status indicator is not proof of a fast coding conversation.

The project does not change reasoning settings or claim to improve model
quality. It also does not fix a large instruction payload, a slow prompt pass,
missing file reads or an agent waiting for permission. Those problems need
their own measurements. I kept them separate in
[Local Coding Lab](https://github.com/paras-lehana/local-coding-lab), the research
project from which this controller was extracted.

## How do you connect an existing launcher?

The public examples cover llama.cpp, Ollama and a custom PowerShell pair. A
custom profile points at a start script and a stop script. This is useful when
your existing launcher already has memory checks, logging or temperature limits.
The controller can keep that policy in place instead of inventing a second
way to operate the same process.

For the built-in launcher, stopping requires the recorded PID, executable,
creation time and configured identity to match. A process name by itself is
insufficient. Another instance may belong to a benchmark, a different model
or a different person. If ownership cannot be established, the controller
refuses the stop and tells you to use the original launcher's control path.

Custom scripts are trusted local code and run with your user permissions.
They should return an exit code and actually finish the requested action.
One live test found that Windows PowerShell could lose the child exit code
unless the process handle was opened before waiting. The model had stopped,
but the interface reported failure. That is exactly the sort of mismatch a
health check alone would have missed.

## Can remote VS Code use the PC?

Yes, with the right connection. In an SSH workspace, localhost may identify
the remote server, while another provider may execute on the PC. The optional
tunnel helper creates a reverse loopback forward on each selected host. One
connection can also provide a local mirror, giving both execution locations
the same endpoint address without opening a public model listener.

The existing servers already had services on port 8080, so the installation
used another available port. Nothing needed to be stopped to make room.
The helper uses existing SSH identities and known-host checking, and its own
recorded processes. It does not rewrite the SSH sessions that VS Code already
uses for files and terminals. A disconnected network needs an explicit reconnect;
there is no endless retry loop hiding a failed connection.

Two remote Linux hosts returned a small test response from the PC model.
That establishes the transport path. It does not certify full editor behavior,
instruction retrieval or long-context latency. Both workspaces still share one
model and its queue. The PC also needs to remain awake, and remote users must
be trusted because loopback access does not isolate processes on the same host.

## What is ready to try?

The Windows installer fetches a pinned AutoHotkey archive, checks its digest,
and preserves existing settings. It does not download model weights, install
an inference engine or add boot startup. You configure your existing executable
and model, then launch the tray shortcut. Python is needed for the automated
tests, not for normal use. A native Settings dialog handles the everyday choices.

Actual hover, hide, pin, drag and global shortcut behavior were exercised on
Windows 11. Offline tests cover foreign model refusal, stale process receipts,
custom-script failures and the Ollama API contract. A real Ollama model was
not loaded for this release. AMD and Intel GPU counters, a clean-machine UI
pass and mixed-DPI monitor transitions also remain outside the verified scope.

My reusable lessons are simple. Give sleep and stop different meanings. Measure
the whole device honestly. Preserve the original launcher's ownership checks.
Test the interface people click, including its failure messages. Keep a small
API success separate from a complete coding-session success.

The [repository](https://github.com/paras-lehana/llm-tray) includes configuration
examples, remote-access instructions and the test report. Try it with your own
launcher and tell me what you would remove from the panel. Small tools become
more useful when they earn the space they occupy.

## Title options

1. I Put My LLM Beside the Clock — preferred: describes the actual product.
2. My Local Model Needed a Stop Button
3. A Windows Tray for Local Models
