# Shared, dependency-free functions. Dot-source for tests; no side effects.
Set-StrictMode -Version Latest

function Read-TrayIni([string]$Path) {
    $sections=@{}; $section=''
    foreach($raw in [IO.File]::ReadAllLines($Path)) {
        $line=$raw.Trim()
        if (-not $line -or $line.StartsWith(';') -or $line.StartsWith('#')) { continue }
        if ($line -match '^\[([\w-]+)\]$') {
            $section=$Matches[1]; if (-not $sections.ContainsKey($section)) { $sections[$section]=@{} }; continue
        }
        if (-not $section -or $line -notmatch '^([\w-]+)=(.*)$') { throw "Invalid INI line in $Path" }
        $sections[$section][$Matches[1]]=$Matches[2].Trim()
    }
    return $sections
}

function Resolve-ProfilePath([string]$Path,[string]$Base) {
    if (-not $Path) { throw 'Required path is empty. Configure your model profile first.' }
    if (-not [IO.Path]::IsPathRooted($Path)) { $Path=Join-Path $Base $Path }
    return [IO.Path]::GetFullPath($Path)
}

function Read-ModelProfile([string]$Path) {
    $all=Read-TrayIni $Path
    if (-not $all.ContainsKey('model')) { throw 'Profile needs a [model] section.' }
    $p=$all.model
    if ($p.backend -notin @('llama','ollama','custom')) { throw 'Unknown backend.' }
    if ($p.status -notin @('llama','ollama','health')) { throw 'Unknown status protocol.' }
    $u=[Uri]$p.endpoint
    if ($u.Scheme -ne 'http' -or $u.Host -notin @('127.0.0.1','localhost','[::1]') -or
        $u.UserInfo -or $u.AbsolutePath -ne '/' -or $u.Query -or $u.Fragment) {
        throw 'Use an HTTP loopback endpoint without credentials, path, query or fragment.'
    }
    $p.endpoint=$p.endpoint.TrimEnd('/')
    if (-not $p.name -or $p.name -match '[\r\n]') { throw 'Model name is required.' }
    if ($p.backend -in @('llama','ollama') -and -not $p.model_id) { throw 'Model ID is required.' }
    $p['_base']=Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    return $p
}

function Get-ModelState($Profile,[int]$Timeout=2) {
    $path=switch($Profile.status) {'llama' {'/props'} 'ollama' {'/api/ps'} default {'/health'}}
    try {
        $data=Invoke-RestMethod ($Profile.endpoint+$path) -TimeoutSec $Timeout
        if ($Profile.status -eq 'llama') {
            if ($Profile.model_id -and $data.model_alias -ne $Profile.model_id) { return 'Other model' }
            if ($data.PSObject.Properties['is_sleeping'] -and $data.is_sleeping) { return 'Sleeping' }
            return 'Ready'
        }
        if ($Profile.status -eq 'ollama') {
            if (@($data.models | Where-Object { $_.name -eq $Profile.model_id -or $_.model -eq $Profile.model_id }).Count) { return 'Ready' }
            return 'Unloaded'
        }
        return 'Ready'
    } catch {
        $response=$_.Exception.Response
        if ($response) {
            if ([int]$response.StatusCode -eq 503) { return 'Loading' }
            return 'Endpoint error'
        }
        return 'Offline'
    }
}

function ConvertTo-WindowsArgument([string]$Value) {
    # CommandLineToArgvW rules: escape quotes and trailing backslashes, not shell text.
    return '"'+[regex]::Replace([regex]::Replace($Value,'(\\*)"','$1$1\"'),'(\\+)$','$1$1')+'"'
}

function Test-PortFree([Uri]$Endpoint) {
    $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Endpoint.Port)
    $listener.Server.ExclusiveAddressUse=$true
    try { $listener.Start(); return $true } catch { return $false } finally { $listener.Stop() }
}

function Get-OwnedServer([string]$Receipt,$Profile) {
    if (-not (Test-Path -LiteralPath $Receipt)) { return $null }
    $saved=Get-Content -LiteralPath $Receipt -Raw | ConvertFrom-Json
    $p=Get-Process -Id $saved.pid -ErrorAction SilentlyContinue
    if (-not $p) { return $null }
    $expected=Resolve-ProfilePath $Profile.executable $Profile._base
    if ($p.Path -ne $expected -or $p.Path -ne $saved.executable -or
        $p.StartTime.ToUniversalTime().Ticks.ToString() -ne $saved.start_ticks -or
        $saved.endpoint -ne $Profile.endpoint -or $saved.model_id -ne $Profile.model_id) {
        throw 'Saved process identity differs; stop/start refused.'
    }
    return $p
}

function Get-LlamaArguments($Profile) {
    $model=Resolve-ProfilePath $Profile.model_path $Profile._base
    if (-not (Test-Path -LiteralPath $model -PathType Leaf)) { throw 'Configured GGUF is missing.' }
    foreach($key in @('gpu_layers','context_size','idle_seconds')) {
        if ($Profile[$key] -notmatch '^\d+$') { throw "Invalid $key." }
    }
    if ([int]$Profile.context_size -lt 512 -or [int]$Profile.idle_seconds -lt 1) { throw 'Context/idle values are too small.' }
    $arguments=@('-m',$model,'--alias',$Profile.model_id,'--host','127.0.0.1','--port',([Uri]$Profile.endpoint).Port.ToString(),
        '--gpu-layers',$Profile.gpu_layers,'--ctx-size',$Profile.context_size,'--sleep-idle-seconds',$Profile.idle_seconds)
    if ($Profile.extra_args_file) {
        $extra=Get-Content -LiteralPath (Resolve-ProfilePath $Profile.extra_args_file $Profile._base) -Raw | ConvertFrom-Json
        if ($extra -isnot [array]) { throw 'extra_args_file must contain a JSON array.' }
        foreach($value in $extra) {
            if ($value -isnot [string] -or $value -match '[\x00\r\n]') { throw 'Every extra argument must be a one-line string.' }
            if ($value -match '^(--host|--port|--alias|-m|--model|--sleep-idle-seconds)(=|$)') { throw 'Extra arguments cannot replace endpoint, identity or idle settings.' }
        }
        $arguments+=@($extra)
    }
    return ,$arguments
}

function Invoke-CustomScript([string]$Path,$Profile,[string]$LogDir) {
    $full=Resolve-ProfilePath $Path $Profile._base
    if ([IO.Path]::GetExtension($full) -ne '.ps1' -or -not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw 'Custom action must name an existing trusted .ps1 script.'
    }
    $args=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$full)
    $stamp=[Guid]::NewGuid().ToString('N')
    $p=Start-Process -FilePath (Join-Path $PSHOME 'powershell.exe') -ArgumentList (($args | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' ') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $LogDir "$stamp.out.log") -RedirectStandardError (Join-Path $LogDir "$stamp.err.log")
    # Windows PowerShell can lose ExitCode when a pass-through child exits
    # before its handle was opened. Retain it before waiting.
    $null=$p.Handle
    # Don't terminate arbitrary descendants on timeout. Report the live action.
    if (-not $p.WaitForExit(600000)) { throw "Custom script still running (PID $($p.Id)); check its logs before retrying." }
    $p.Refresh()
    if ($p.ExitCode -ne 0) { throw "Custom script failed (exit $($p.ExitCode)); inspect action logs." }
}

function Invoke-ModelAction($Profile,[string]$Action,[string]$StateDir) {
    $state=Get-ModelState $Profile
    $receipt=Join-Path $StateDir 'process.json'
    if ($state -in @('Other model','Endpoint error','Loading')) { throw "Endpoint is $state; no action taken." }
    if ($Action -eq 'Toggle') { $Action=if ($state -eq 'Ready') {'Stop'}else{'Start'} }
    if ($Profile.backend -eq 'ollama') {
        if ($state -eq 'Offline') { throw 'Start the Ollama application first. The tray controls models, not its daemon.' }
        $installed=Invoke-RestMethod ($Profile.endpoint+'/api/tags') -TimeoutSec 5
        if (-not @($installed.models | Where-Object { $_.name -eq $Profile.model_id -or $_.model -eq $Profile.model_id }).Count) { throw 'Configured Ollama model is not installed; pull it yourself first.' }
        $keep=if ($Action -eq 'Stop') {0}else{if($Profile.keep_alive){$Profile.keep_alive}else{'30m'}}
        $body=@{model=$Profile.model_id;prompt='';stream=$false;keep_alive=$keep} | ConvertTo-Json
        Invoke-RestMethod ($Profile.endpoint+'/api/generate') -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 600 | Out-Null
    } elseif ($Action -eq 'Start' -and $state -eq 'Sleeping') {
        Invoke-RestMethod ($Profile.endpoint+'/tokenize') -Method Post -ContentType 'application/json' -Body '{"content":""}' -TimeoutSec 600 | Out-Null
    } elseif ($Action -eq 'Start' -and $state -eq 'Ready') {
        return $state
    } elseif ($Profile.backend -eq 'custom') {
        $script=if ($Action -eq 'Stop') {$Profile.stop_script}else{$Profile.start_script}
        Invoke-CustomScript $script $Profile $StateDir
    } elseif ($Profile.backend -eq 'llama') {
        $owned=Get-OwnedServer $receipt $Profile
        if ($Action -eq 'Stop') {
            if (-not $owned -and $state -eq 'Offline') { return 'Offline' }
            if (-not $owned) { throw 'This tray did not start that server. Use its own stop script through a custom profile.' }
            # Stop only the verified exact process. Never kill by name or process tree.
            $owned.Kill(); if (-not $owned.WaitForExit(20000)) { throw 'Owned server has not stopped.' }
        } else {
            if ($owned) { throw 'Owned server exists but is not ready; inspect its log.' }
            if (-not (Test-PortFree ([Uri]$Profile.endpoint))) { throw 'Endpoint port is already occupied; no server launched.' }
            $exe=Resolve-ProfilePath $Profile.executable $Profile._base
            if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'llama-server executable is missing.' }
            $arguments=Get-LlamaArguments $Profile
            $stamp=Get-Date -Format 'yyyyMMdd-HHmmssfff'
            $p=Start-Process -FilePath $exe -ArgumentList (($arguments | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' ') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $StateDir "$stamp.out.log") -RedirectStandardError (Join-Path $StateDir "$stamp.err.log")
            $saved=@{pid=$p.Id;executable=$exe;start_ticks=$p.StartTime.ToUniversalTime().Ticks.ToString();endpoint=$Profile.endpoint;model_id=$Profile.model_id}
            $saved | ConvertTo-Json | Set-Content -LiteralPath $receipt -Encoding UTF8
        }
    }
    $deadline=[DateTime]::UtcNow.AddSeconds(600)
    do {
        $state=Get-ModelState $Profile
        if ($Action -eq 'Start' -and $state -eq 'Ready') { return 'Ready' }
        if ($Action -eq 'Stop' -and $state -in @('Offline','Unloaded')) { return $state }
        if ($state -in @('Other model','Endpoint error')) { throw "Unexpected endpoint: $state." }
        Start-Sleep -Milliseconds 500
    } while ([DateTime]::UtcNow -lt $deadline)
    throw "Action timed out; last state $state. Check logs before retrying."
}
