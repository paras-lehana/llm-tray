# Design and behavior

The job: see whether the model is available and reclaim its memory without
opening a terminal. A 16–32 pixel icon has three colored meter rows and a small
status dot. Exact labels and values belong in the hover panel; tiny full numeric
strings are not legible at normal Windows tray sizes.

Dark slate background #16202D, ink #E8EFF7, muted #AABACB; green #86E3A7,
amber #FFD07D and red #FF9A9E. Segoe UI. State has a word as well as a color.
The tray has a two-pixel frame at 32px: green #86E3A7 for Ready and orange
#FFAD5C otherwise. Contrast against the slate background is 10.60:1 and
8.90:1 respectively. The frame survives scaling to a normal 16px tray icon;
the tooltip distinguishes stopped, sleeping, loading and unavailable states.
One primary action: toggle model. Secondary controls: pin, settings, close.
Tray click pins/opens; hover alone never changes model state. Escape hides and
unpins. The title can be dragged; dragging pins. Settings are a keyboard-usable
native dialog. No web framework, metrics subprocess loop or runtime Python.

UI config is an INI file, profiles are separate INI files. Actions use fixed
PowerShell entry points, strict local endpoint checks and a named mutex.
Built-in llama.cpp creates and owns a server; custom profiles call reviewed
PowerShell scripts; Ollama loads/unloads one model through its existing daemon.
Monitoring is passive and independent of lifecycle ownership.

Automatic opening requires a continuous one-second dwell over the actual tray
button. Both Windows mouse-move callbacks and the 100 ms hover poll share that
rule; leaving clears it. Deliberate click/pin bypasses the delay. Settings offers
0–10 seconds, with the field disabled when automatic hover is off.

The detail panel uses native layered-window alpha: 10% transparent by default,
configurable from 0–50%. Settings and the tray icon remain opaque. This is not
acrylic blur; text is composited too. No animation or extra dependency is needed.
The default is intentionally subtle; stronger transparency depends on the
underlying desktop and can reduce readability.

The title starts the Windows move loop on WM_LBUTTONDOWN, not a release-time
Text Click callback. During movement, status completion, metrics and hover
work are deferred; WM_EXITSIZEMOVE schedules one position save. Status uses
asynchronous WinHTTP, nonblocking completion checks and a single outstanding
request. A two-second deadline is evaluated when the panel is not moving.
These choices keep network waits and INI writes out of the drag path.

No secret values are required. SSH uses existing identities and host checking.
Optional tunnels listen on remote loopback only; they do not edit existing SSH
sessions, containers, firewall rules or public routing.
