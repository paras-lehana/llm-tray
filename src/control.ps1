param(
    [Parameter(Mandatory=$true)][string]$DataDir,
    [Parameter(Mandatory=$true)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$Profile,
    [ValidateSet('Start','Stop','Toggle')][string]$Action='Toggle'
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'Backend.ps1')
$data=[IO.Path]::GetFullPath($DataDir)
$state=Join-Path $data ('state\'+$Profile)
New-Item -ItemType Directory -Force -Path $state | Out-Null
$status='error'; $message='Action failed.'; $locked=$false; $mutex=$null
try {
    $p=Read-ModelProfile (Join-Path $data ('profiles\'+$Profile+'.ini'))
    $sha=[Security.Cryptography.SHA256]::Create()
    try { $id=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($p.endpoint)))).Replace('-','') } finally {$sha.Dispose()}
    $mutex=[Threading.Mutex]::new($false,('Local\LLMTray-'+$id))
    $locked=$mutex.WaitOne(0)
    if (-not $locked) { throw 'Another action for this endpoint is already running.' }
    $status=Invoke-ModelAction $p $Action $state
    $message=switch($status) {
        'Ready' {'Model ready. Idle unloading is controlled by your runtime.'}
        'Unloaded' {'Model unloaded. A new Ollama request can load it again.'}
        default {'Model stopped. Start it before sending another message.'}
    }
} catch { $message=$_.Exception.Message -replace '[\r\n]+',' ' } finally {
    if ($locked) {$mutex.ReleaseMutex()}
    if ($mutex) {$mutex.Dispose()}
    $result=Join-Path $data 'action.ini'
    "[result]`r`nstatus=$status`r`nmessage=$message" | Set-Content -LiteralPath ($result+'.tmp') -Encoding Unicode
    Move-Item -LiteralPath ($result+'.tmp') -Destination $result -Force
}
if ($status -eq 'error') {exit 1}
