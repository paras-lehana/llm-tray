# Configuration

The installer creates a private data directory containing `config.ini`,
`profiles/*.ini `, ` state/`, receipts and logs. Existing files are not replaced.
Paths with spaces are supported. INI values are unquoted; relative profile
paths resolve beside that profile. Reload through the tray after manual edits.
Changing profiles never silently stops one model or starts another.

## UI preferences

Right-click the icon → **Settings** for profile, shortcut, enabled metrics,
hover, notifications and warning thresholds. Save applies them by reloading.
Other choices can be edited in `config.ini`:

| Key in `[ui]` | Default | Meaning |
|---|---|---|
|`profile `|` llama `|Filename under profiles without`.ini`; letters/digits/dash/underscore|
|`hotkey `|`^!l`|Ctrl+Alt+L; use native Settings to record a different combination|
|`metrics `|` vram,ram,gpu`|Visible rows and their order; empty means status only|
|`refresh_seconds `|`3`|Resource/API refresh, clamped 1–60seconds|
|`gpu_index `|`0`|NVIDIA device index; whole-device metrics|
|`warning_percent `|`70`|Amber threshold|
|`critical_percent `|`90`|Red threshold; must exceed warning|
|`hover `|`1`|Automatic detail panel on hover|
|`notifications `|`1`|Native action notices; Windows DND still applies|
|`pinned `|`0`|Persistent panel; pin/drag updates it|
|`connection_script `|empty|Optional trusted`.ps1` run at UI startup and via Reconnect menu|

AutoHotkey modifiers are `^` Ctrl,`!` Alt,`+` Shift,`#` Windows. For example
`^!m` is Ctrl+Alt+M. A hotkey conflict cannot always be detected against another
application; choose an unused combination and test it. The native hotkey picker
supports Ctrl/Alt/Shift; use the INI for Windows-key combinations.

The status dot is green for Ready, amber for Sleeping/Working/Loading and red
for Offline/Unloaded. Unavailable metrics are gray. Readiness means the endpoint
reports its model loaded, not that no other client has queued a request.

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

The installer does not add boot startup. If you want only the tray at login,
copy its shortcut into the Windows Startup folder yourself. The UI does not
start a model on launch. An optional connection_script is trusted code, so its
behavior is yours to define; the provided SSH example only opens tunnels.

To remove: exit the tray, stop any model through its appropriate controller if
desired, remove your optional Startup shortcut, then remove this checkout and
its private data folder. Models/runtimes outside that folder are independent.
