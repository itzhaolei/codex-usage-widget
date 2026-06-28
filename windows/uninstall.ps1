$ErrorActionPreference = "SilentlyContinue"

$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$installDir = Join-Path $codexHome "usage-widget"
$startupDir = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupDir "Quota Bubble.lnk"

Get-Process powershell, pwsh -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like "*QuotaBubble.ps1*" } |
    Stop-Process -Force

Remove-Item -Force $shortcutPath
Remove-Item -Force (Join-Path $installDir "QuotaBubble.ps1")
Remove-Item -Force (Join-Path $installDir "windows-state.json")
Write-Host "Quota Bubble Windows files removed."
