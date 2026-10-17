# Explicit, per-user sign-in startup. This never starts a model or edits profiles.
[CmdletBinding()]
param(
    [ValidateSet('Enable','Disable','Status')][string]$Action='Status',
    [string]$DataDir=(Join-Path $PSScriptRoot '..\local-data'),
    [string]$StartupDir=[Environment]::GetFolderPath('Startup')
)
$ErrorActionPreference='Stop'
$dataPath=[IO.Path]::GetFullPath($DataDir).TrimEnd('\')
$startupPath=[IO.Path]::GetFullPath($StartupDir)
$scriptPath=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\src\LLMTray.ahk'))
$linkPath=Join-Path $startupPath 'LLM Tray.lnk'
$arguments='"'+$scriptPath+'" "'+$dataPath+'"'
$description='LLM Tray sign-in startup (managed by llm-tray)'
$shell=New-Object -ComObject WScript.Shell
$registered=Test-Path -LiteralPath $linkPath -PathType Leaf
$shortcut=$null
$owned=$false
if ($registered) {
    $shortcut=$shell.CreateShortcut($linkPath)
    $owned=$shortcut.Description -ceq $description -and $shortcut.Arguments -ceq $arguments
}
if ($registered -and -not $owned -and $Action -ne 'Status') {
    throw 'LLM Tray.lnk already belongs to another configuration. It was not changed. Disable it using its original checkout/data directory first.'
}
if ($Action -eq 'Enable') {
    $receiptPath=Join-Path $dataPath 'installation.json'
    if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) { throw 'Run install.ps1 for this data directory first: installation.json is missing.' }
    $receipt=Get-Content -LiteralPath $receiptPath -Raw | ConvertFrom-Json
    $exe=[string]$receipt.executable
    if (-not $exe -or -not [IO.Path]::IsPathRooted($exe) -or -not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Installed AutoHotkey executable is missing. Repair the installation first.' }
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf) -or -not (Test-Path -LiteralPath (Join-Path $dataPath 'config.ini') -PathType Leaf)) { throw 'Tray source or config.ini is missing. Repair the installation first.' }
    New-Item -ItemType Directory -Force -Path $startupPath | Out-Null
    $shortcut=$shell.CreateShortcut($linkPath)
    $shortcut.TargetPath=$exe
    $shortcut.Arguments=$arguments
    $shortcut.WorkingDirectory=$dataPath
    $shortcut.Description=$description
    $shortcut.WindowStyle=7
    $shortcut.Save()
    $registered=$true
    $owned=$true
} elseif ($Action -eq 'Disable' -and $owned) {
    Remove-Item -LiteralPath $linkPath
    $registered=$false
    $owned=$false
    $shortcut=$null
}
[pscustomobject]@{
    registered=$registered
    matches_configuration=$owned
    shortcut=$linkPath
    target=$(if($shortcut){$shortcut.TargetPath}else{$null})
    arguments=$(if($shortcut){$shortcut.Arguments}else{$null})
    data=$dataPath
    note='Runs the tray at user sign-in. Windows Startup apps can independently disable this entry. The tray does not load a model on launch.'
} | ConvertTo-Json
