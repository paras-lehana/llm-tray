# Use the PC model in remote VS Code

In an SSH workspace,`localhost` may mean the remote host. VS Code providers can
also run locally, depending on the client/harness. Provide the same loopback
URL on both sides rather than exposing the model to the internet.

The optional script opens a dedicated authenticated SSH connection with a
reverse forward. It preserves existing VS Code SSH sessions and their dynamic
ports. It never changes SSH host checking, sshd, firewall or Docker services.

## Setup

1. Confirm `ssh my-server` already works with your existing identity and known
   host key. Use a host alias from your SSH config; no password storage here.
2. Check the chosen port is unused on the remote and PC. The example uses 18080;
   use another, such as18888, if occupied or reserved. Do not stop its occupant.
3. Copy `examples/tunnels.json` into your private data folder; replace aliases
   and ports. Keep `local_port` equal to the PC model listener's port.
4. Enable `local_mirror` on exactly one host. This also forwards PC loopback's
   chosen port through that host back to the PC model, so the URL works from
   either a local or remote model provider.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\tunnels.ps1 `
  -ConfigFile .\local-data\tunnels.json -Action Start
```

The remote listens only on127.0.0.1. Confirm the server's sshd configuration
does not force GatewayPorts to a public bind, then check with `ss -lntp`.
The script requests a loopback bind; your SSH server must honor it.

Verify from the remote host:

```bash
curl --fail http://127.0.0.1:18080/v1/models
```

For automatic connection setup when the tray starts, create a trusted `.ps1`
wrapper calling the command above with absolute paths, and set
`[ui] connection_script` to it. Add `connection_retry_seconds=60` to check/reopen
tunnels once a minute while the tray is running, or leave 0 for startup/manual
only. Reconnect remote access reruns it immediately without duplicating a live
owned tunnel. The initial startup attempt is not postponed by the retry timer.
Failures and recovery are logged and notified; one failing host does not skip
the others. Only one helper/operation runs per configuration at a time.
Stop/Status use the same
command with `-Action Stop ` or`-Action Status`; only owned, matching SSH PIDs are
stopped. Disable periodic retries and reload before deliberately using Stop,
otherwise the next check reconnects. Exiting the tray leaves established tunnels
and the model unchanged. Stale/reused PIDs after reboot are never killed; Start
can create a new tunnel when the configured port is available.

## Copilot custom endpoint

Open **Manage Models → Custom Endpoint** and create a distinct provider named
`PC model over SSH `. Use your model's exact API ID from`/v1/models`, and URL
`http://127.0.0.1:18080/v1/chat/completions` for chat completions. Use your actual
context/output limits and only advertise capabilities the runtime supports.
An unauthenticated loopback model may need a harmless placeholder API key.

Select that entry in each remote chat's model picker. Existing chats do not
necessarily switch when configuration changes. In recent native VS Code builds,
the provider registry is `chatLanguageModels.json` in the active local user
profile; the model provider's execution location can still differ.

**Check the window's profile first.** A remote window may use a named profile
while your local window uses Default. Default's registry is normally
`%APPDATA%\Code\User\chatLanguageModels.json`; a named profile has its own
`%APPDATA%\Code\User\profiles\<profile-id>\chatLanguageModels.json`. Adding a
model only to Default will not make it available in that separate profile.
Use Manage Models from the intended remote window so VS Code opens the right
file. Preserve its existing providers. If your integration uses model-specific
capability overrides, those settings also need to exist in the active profile.

The model still runs on the PC. The remote server needs a working loopback
tunnel, not a model download. Verify `/v1/models` and a short chat request from
each server, then reopen that window's model picker and select the custom
entry. Successful API tests alone do not prove the entry is visible in the UI.

Official reference: [VS Code language models and Custom Endpoint setup](https://code.visualstudio.com/docs/agent-customization/language-models).

For instruction-heavy projects, keep the same proven tool/context limits as
your local integration. A short API reply proves reachability, not instruction
retrieval, agent permissions or editor latency. Test a small actual file read
in a fresh conversation before relying on a large coding session.

## Continue

In the environment where Continue runs, add an OpenAI-compatible model with
`apiBase: http://127.0.0.1:18080/v1`, your exact model ID, and its actual context
limits. Do not overwrite unrelated providers or secrets. Check the installed
extension's timeout units; they have differed across adapters/versions.
This repo does not install or patch editor extensions.

## Operational limits

The PC must be awake, the model listener must be started and SSH must remain
connected. Native sleep is fine: the listener wakes the model on a new request.
Manual Stop is different and requires Start. Multiple remote workspaces share
the same model and server queue; two connections do not mean two GPUs.

The local mirror depends on its chosen remote host as well as the PC. Keep a
separate direct8080model entry for local-only work if you need that independence.
Loopback limits network exposure; other users/processes on that remote host may
still access the endpoint. Do not use an unauthenticated tunnel on an untrusted
shared server. Private hostnames/keys belong in local config, not this repo.

## Connection reset after a restart

The tray, model server and tunnel are separate processes. Starting the tray
does not load the model. After a full PC restart, Start the model once (or use
your configured hotkey); native idle sleep can then wake on the next request.
If Copilot reports a generic firewall/network error such as ECONNRESET:

1. Check the PC's direct `/v1/models` and passive `/props` endpoint. If stopped,
   Start the model; a larger context setting cannot fix a missing listener.
2. Check the dedicated tunnel receipt/error log and the remote loopback listener.
   An old remote forwarding connection may temporarily retain the chosen port
   after a hard restart. Do not kill another listener; wait/retry or select an
   unused port deliberately. Do not change firewall/sshd rules by guesswork.
3. Check `/v1/models` and a small streamed chat from the remote host. Validate
   thinking and tool-call chunks separately; health-only checks are insufficient.
4. Retry the editor request only after the route is working. Full instruction/
   tool workflows can still be slow and are a separate quality/latency test.

OpenSSH's [ExitOnForwardFailure](https://man.openbsd.org/ssh_config#ExitOnForwardFailure)
checks creation of forwarding listeners; it does not prove the final model
destination is reachable. Keep the model availability check separate.
