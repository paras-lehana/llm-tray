# Configuration

The installer creates a private data directory containing `config.ini`,
`profiles/*.ini `, ` state/`, receipts and logs. Existing files are not replaced.
Paths with spaces are supported. INI values are unquoted; relative profile
paths resolve beside that profile. Reload through the tray after manual edits.
Changing profiles never silently stops one model or starts another.

## UI preferences

Right-click the icon → **Settings** for profile, shortcut, enabled metrics,
hover delay, panel transparency, notifications and warning thresholds. Save applies them by reloading.
Other choices can be edited in `config.ini`:

| Key in `[ui]` | Default | Meaning |
|---|---|---|
|`profile `|` llama `|Filename under profiles without`.ini`; letters/digits/dash/underscore|
|`hotkey `|`^!l`|Ctrl+Alt+L; use native Settings to record a different combination|
|`metrics `|` vram,ram,gpu`|Visible rows and their order; empty means status only|
|`cleanup_buttons`|`1`|Show a brush beside each panel metric; all brushes stop/unload only the configured LLM. Also available in Settings.|
|`refresh_seconds `|`3`|Resource/API refresh, clamped 1–60seconds|
|`gpu_index `|`0`|NVIDIA device index; whole-device metrics|
|`warning_percent `|`70`|Amber threshold|
|`critical_percent `|`90`|Red threshold; must exceed warning|
|`hover `|`1`|Automatic detail panel on hover|
|`hover_delay_ms`|`1000`|Continuous hover before opening, 0–10000 ms; Settings displays seconds. Leaving resets the timer.|
|`panel_transparency_percent`|`10`|Whole-panel transparency, 0–50%; 0 is opaque. Does not affect the tray icon or Settings.|
|`notifications `|`1`|Native action notices; Windows DND still applies|
|`pinned `|`0`|Persistent panel; pin/drag updates it|
|`connection_script `|empty|Optional trusted`.ps1` run at UI startup and via Reconnect menu|
|`connection_retry_seconds`|`0`|Opt-in periodic connection helper, 10-3600 seconds; requires an idempotent script. `0` means startup/manual only.|

AutoHotkey modifiers are `^` Ctrl,`!` Alt,`+` Shift,`#` Windows. For example
`^!m` is Ctrl+Alt+M. A hotkey conflict cannot always be detected against another
application; choose an unused combination and test it. The native hotkey picker
supports Ctrl/Alt/Shift; use the INI for Windows-key combinations.

The status dot is green for Ready, amber for Sleeping/Working/Loading and red
for Offline/Unloaded. Unavailable metrics are gray. Readiness means the endpoint
reports its model loaded, not that no other client has queued a request.

Brushes and **Free LLM resources** in the tray menu run the profile's existing
Stop action. This is deliberate: an already stopped model must never start
because cleanup was clicked again. Cleanup uses the same process ownership,
custom stop script or Ollama model identity checks as normal Stop. It ends any
reply from that model, including a remote workspace's reply. Busy controls are
disabled until the action finishes; failures remain visible and are logged.
No other application is guessed to be disposable. Free GPU memory, system RAM,
Windows file cache and current GPU activity are different measures; the readings
are refreshed after the stop, not reset to artificial zeros.

The hover delay applies to automatic opening only; clicking to open/pin remains
immediate. Disable hover if you want manual opening only. Delay 0 opens on the
next check (about 100 ms), not with a hard real-time guarantee. Windows scheduling
can add a little to any chosen delay. Transparency is ordinary whole-window
alpha, including text, not background blur. Use a lower percentage if your
wallpaper makes the panel harder to read. Settings stays opaque for legibility.

## llama.cpp

Edit `profiles/llama.ini`. Required fields are executable, GGUF path, model ID,
endpoint and numeric layer/context/idle settings. Start logs are stored in
`state/<profile>/`. This controller is not a model fit calculator; select settings
for your actual hardware and existing workload.

For advanced options, point `extra_args_file` to a JSON array:

```json
["--flash-attn", "on", "--cache-type-k", "q8_0", "--cache-type-v", "q8_0", "--no-kv-offload"]
```

Those flags depend on your model and runtime. They are an example, not universal
performance advice. Endpoint/identity/idle flags cannot be replaced through
this array. The runtime must support native idle sleep. A failed load does not
trigger an infinite restart loop. Inspect its log and adjust explicitly.

The process receipt contains PID, creation time, executable and model/endpoint
identity. Stop requires a matching live process. If another launcher started
your server, configure a custom stop script instead of trying to adopt it.

## Ollama

Start the normal Ollama application first and pull your chosen model using its
own CLI. Set `model_id` to the exact installed name, including tag, and select
the `ollama` profile. LLM Tray checks `/api/tags` and never downloads weights.

Start sends an empty prompt to `/api/generate` with the configured `keep_alive`
(default `30m`). Stop sends ` keep_alive: 0`. A future normal request can reload
that model. Other clients may override keep_alive, and their usage resets the
runtime's idle behavior. See [Ollama's API](https://docs.ollama.com/api/generate).

## Your own PowerShell launcher

Set `backend=custom`, choose ` status=llama`, ` ollama `or` health`, and set existing
`start_script ` and`stop_script` paths. Scripts run as the current user, hidden,
without an interactive prompt. Exit0on success, nonzero on failure. The tray
then verifies endpoint state. Do not place passwords in these files.

Example start adapter for an existing managed launcher:

```powershell
$ErrorActionPreference='Stop'
& 'E:\llm\start-server.ps1'
# If calling a native .exe instead, propagate its nonzero exit code.
```

Example stop adapter for that launcher's existing ownership-aware stop action:

```powershell
$ErrorActionPreference='Stop'
& 'E:\llm\stop-server.ps1'
```

The stop script must actually stop/unload the chosen model. Do not use broad
`taskkill /IM` or process-name kills. A custom-script timeout is reported without
killing arbitrary child trees; inspect logs and the reported PID before retrying.
The `health` status mode only knows whether `/health` returns success; it cannot
identify models or native sleep. Prefer the protocol-specific mode.

## Startup and removal

Sign-in startup is an explicit choice. For a new install, use
`install.ps1 -StartAtSignIn`. For an existing installation:

```powershell
# Omit -DataDir if you use the default local-data folder.
.\scripts\startup.ps1 -Action Enable -DataDir 'E:\llm\tray'
.\scripts\startup.ps1 -Action Status -DataDir 'E:\llm\tray'
.\scripts\startup.ps1 -Action Disable -DataDir 'E:\llm\tray'
```

Enable creates one **LLM Tray.lnk** in the current user's Windows Startup
folder. Its target is the installed AutoHotkey executable; arguments preserve
the checkout and data directory, including spaces. Repeating Enable updates
that entry. Another configuration's shortcut is never overwritten or removed.
No administrator rights or system service are required. Launching the shortcut
again replaces the same tray instance instead of accumulating duplicates.

This runs at **sign-in**, not before login. It follows Microsoft's documented
[Startup-folder approach](https://support.microsoft.com/en-gb/windows/experience/startup-boot/configure-startup-applications-in-windows).
`Status` reports registration; Windows **Settings > Apps > Startup** or Task
Manager can independently disable it. If registered but not starting, check
that Windows setting, confirm the source/runtime/data drive is available,
and open the shortcut through `shell:startup` to check for an error. Disable
the old entry before moving your checkout, then enable from the new location.

The UI does not start a model on launch. An optional `connection_script` is
trusted code, so its behavior is yours to define; the provided SSH example
only opens tunnels. Windows may place the icon under **Show hidden icons**;
drag this icon beside the clock to keep it visible outside overflow.

For a retry-safe connection helper, set `connection_retry_seconds=60` and reload
the tray. The initial run is immediate after startup; further runs are periodic
while the tray is open, with one helper active at a time. Exit code 0 means
success; a script must exit nonzero on failure. First failure and recovery are
logged and notified without a toast every minute. Notification visibility still
depends on Windows settings. This monitors the helper's result, not every remote
endpoint. Set the interval to 0 and reload before deliberately stopping tunnels.

To remove: disable startup using the command above, exit the tray, stop any
model through its appropriate controller if desired, then remove this checkout
and its private data folder. Models/runtimes outside that folder are independent.
