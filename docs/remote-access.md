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
`[ui] connection_script` to it. Reconnect remote access in the tray reruns it
without duplicating a live owned tunnel. There is no background reconnect loop.
After Wi-Fi/SSH loss, use that menu or run Start again. Stop/Status use the same
command with `-Action Stop ` or`-Action Status`; only owned, matching SSH PIDs are
stopped. Exiting the tray leaves established tunnels and the model unchanged.

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
