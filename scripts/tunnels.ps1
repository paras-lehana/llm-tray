# Explicitly owned SSH tunnels. No edits to SSH config or existing VS Code sessions.
param(
    [Parameter(Mandatory=$true)][string]$ConfigFile,
    [ValidateSet('Start','Stop','Status')][string]$Action='Start'
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot '..\src\Backend.ps1')
$path=[IO.Path]::GetFullPath($ConfigFile)
$cfg=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
$folder=Join-Path (Split-Path -Parent $path) 'tunnels'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$ssh=(Get-Command ssh.exe -ErrorAction Stop).Source
function Invoke-ConfiguredTunnel($item) {
    if ($item.name -notmatch '^[A-Za-z0-9_.-]+$' -or $item.name.StartsWith('-')) { throw 'Use an existing safe SSH host alias.' }
    foreach($port in @($item.remote_port,$item.local_port)) {
        if ([int]$port -lt 1024 -or [int]$port -gt 65535) { throw 'Use an unprivileged port from1024–65535.' }
    }
    $receipt=Join-Path $folder ($item.name+'.json')
    $owned=$null
    if (Test-Path -LiteralPath $receipt) {
        $old=Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
        $owned=Get-Process -Id $old.pid -ErrorAction SilentlyContinue
        if ($owned -and ($owned.Path -ne $ssh -or $owned.StartTime.ToUniversalTime().Ticks.ToString() -ne $old.start_ticks)) {
            if ($Action -eq 'Stop') { throw 'SSH PID identity changed; nothing stopped.' }
            # A reboot can reuse a saved PID. Never touch that foreign process;
            # Start may create a new owned tunnel if its listener is available.
            $owned=$null
        }
    }
    if ($Action -eq 'Status') {
        [PSCustomObject]@{Host=$item.name;Running=[bool]$owned;PID=if($owned){$owned.Id}else{$null};Port=$item.remote_port}
        return
    }
    if ($Action -eq 'Stop') {
        if ($owned) { $owned.Kill(); $owned.WaitForExit(10000) | Out-Null }
        return
    }
    if ($owned) {
        if ($old.remote_port -ne $item.remote_port -or $old.local_port -ne $item.local_port -or
            ($old.PSObject.Properties['local_mirror'] -and $old.local_mirror -ne $item.local_mirror)) {
            throw 'Tunnel configuration changed. Stop the owned tunnel, then Start to apply it.'
        }
        Write-Output "$($item.name): tunnel already running"; return
    }
    if ($item.local_mirror -and -not (Test-PortFree ([Uri]("http://127.0.0.1:"+$item.remote_port)))) {
        throw 'Local mirror port is unavailable. Choose another remote_port; existing listeners are untouched.'
    }
    $args=@('-N','-T','-o','BatchMode=yes','-o','ConnectTimeout=10','-o','ExitOnForwardFailure=yes','-o','ServerAliveInterval=30','-o','ServerAliveCountMax=3',
        '-R',("127.0.0.1:{0}:127.0.0.1:{1}" -f $item.remote_port,$item.local_port))
    if ($item.local_mirror) {
        # Same URL works for VS Code providers running locally or remotely.
        $args+=@('-L',("127.0.0.1:{0}:127.0.0.1:{0}" -f $item.remote_port))
    }
    $args+=$item.name
    $p=Start-Process -FilePath $ssh -ArgumentList (($args | ForEach-Object { ConvertTo-WindowsArgument $_ }) -join ' ') -WindowStyle Hidden -PassThru -RedirectStandardError (Join-Path $folder ($item.name+'.err.log')) -RedirectStandardOutput (Join-Path $folder ($item.name+'.out.log'))
    @{pid=$p.Id;start_ticks=$p.StartTime.ToUniversalTime().Ticks.ToString();host=$item.name;remote_port=$item.remote_port;local_port=$item.local_port;local_mirror=[bool]$item.local_mirror} | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath ($receipt+'.tmp')
    Move-Item -LiteralPath ($receipt+'.tmp') -Destination $receipt -Force
    Start-Sleep -Seconds 2
    if ($p.HasExited) { throw "SSH tunnel exited for $($item.name). Inspect its error log." }
    Write-Output "$($item.name): owned SSH PID $($p.Id), remote loopback:$($item.remote_port)"
}

# Serialize operations on this configuration across manual and periodic runs.
$hasher=[Security.Cryptography.SHA256]::Create()
try { $key=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($path.ToLowerInvariant())))).Replace('-','') }
finally { $hasher.Dispose() }
$mutex=New-Object Threading.Mutex($false,('Local\LLMTrayTunnels_'+$key))
$locked=$false
$failures=@()
try {
    if ($Action -ne 'Status') {
        try { $locked=$mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $locked=$true }
        if (-not $locked) { throw 'A tunnel operation is already running for this configuration.' }
    }
    foreach($item in $cfg.hosts) {
        try { Invoke-ConfiguredTunnel $item }
        catch {
            $message="$($item.name): $($_.Exception.Message)"
            $failures+=$message
            Write-Warning $message
        }
    }
    if ($failures.Count) { throw ($failures -join ' | ') }
} finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
