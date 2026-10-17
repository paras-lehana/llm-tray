# Pinned, portable AutoHotkey installer. No model download or boot startup.
param([string]$InstallDir=(Join-Path $PSScriptRoot 'local-data\runtime'),[string]$DataDir=(Join-Path $PSScriptRoot 'local-data'))
$ErrorActionPreference='Stop'
$destinationRoot=[IO.Path]::GetFullPath($InstallDir).TrimEnd('\')
$dataPath=[IO.Path]::GetFullPath($DataDir).TrimEnd('\')
$version='2.0.30'
$expected='1e0ece7ecb2d5646e55758150472677996a57f9db5c83d2996d8b47b9e2f31a4'
$url="https://github.com/AutoHotkey/AutoHotkey/releases/download/v$version/AutoHotkey_$version.zip"
$downloads=Join-Path $destinationRoot 'downloads'
$destination=Join-Path $destinationRoot "tools\AutoHotkey-$version"
$widget=$dataPath
New-Item -ItemType Directory -Force -Path $downloads,$widget | Out-Null
$archive=Join-Path $downloads "AutoHotkey_$version.zip"
if (-not (Test-Path -LiteralPath $archive)) { Invoke-WebRequest -UseBasicParsing $url -OutFile $archive }
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLower() -ne $expected) {
    throw 'AutoHotkey archive hash mismatch. No executable installed.'
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (-not (Test-Path -LiteralPath $destination)) {
    # Inspect every destination before extraction; never allow archive traversal.
    $zip=[IO.Compression.ZipFile]::OpenRead($archive)
    try {
        foreach($entry in $zip.Entries) {
            $target=[IO.Path]::GetFullPath((Join-Path $destination $entry.FullName))
            if (-not $target.StartsWith($destination+'\',[StringComparison]::OrdinalIgnoreCase) -or
                $entry.FullName -match ':|(^|[\\/])\.\.([\\/]|$)' -or
                (($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000) {
                throw 'Unsafe path in AutoHotkey archive.'
            }
        }
    } finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($archive,$destination)
}
$exe=Join-Path $destination 'AutoHotkey64.exe'
if (-not (Test-Path -LiteralPath $exe)) { throw 'Portable AutoHotkey64.exe is missing.' }
# Verify an existing installation against the verified archive, not mere presence.
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try {
    $entry=$zip.GetEntry('AutoHotkey64.exe')
    $stream=$entry.Open()
    $sha=[Security.Cryptography.SHA256]::Create()
    try { $expectedExe=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') }
    finally { $stream.Dispose(); $sha.Dispose() }
} finally { $zip.Dispose() }
if ((Get-FileHash -LiteralPath $exe).Hash -ne $expectedExe) { throw 'Installed executable differs from archive.' }

$profiles=Join-Path $dataPath 'profiles'
New-Item -ItemType Directory -Force -Path $profiles | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $dataPath 'config.ini'))) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'examples\config.ini') -Destination $dataPath
}
foreach($file in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'examples\profiles') -Filter '*.ini') {
    $target=Join-Path $profiles $file.Name
    if (-not (Test-Path -LiteralPath $target)) { Copy-Item -LiteralPath $file.FullName -Destination $target }
}
$shell=New-Object -ComObject WScript.Shell
$shortcut=$shell.CreateShortcut((Join-Path $dataPath 'LLM Tray.lnk'))
$shortcut.TargetPath=$exe
$shortcut.Arguments='"'+(Join-Path $PSScriptRoot 'src\LLMTray.ahk')+'" "'+$dataPath+'"'
$shortcut.WorkingDirectory=$dataPath
$shortcut.Description='LLM Tray: hover for resources, Ctrl+Alt+L to toggle your model'
$shortcut.Save()
@{version=$version;archive_sha256=$expected;executable_sha256=$expectedExe.ToLower();executable=$exe;data=$dataPath;source=$url} | ConvertTo-Json | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $dataPath 'installation.json')
Write-Output "Installed. Edit $profiles\llama.ini, then open $dataPath\LLM Tray.lnk. No startup entry or model start added."
