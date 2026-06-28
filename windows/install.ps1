param(
    [switch]$NoStartupShortcut
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE ".codex" }
$installDir = Join-Path $codexHome "usage-widget"
$scriptsDir = Join-Path $codexHome "scripts"
$startupDir = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupDir "Quota Bubble.lnk"

New-Item -ItemType Directory -Force -Path $installDir, $scriptsDir | Out-Null
Copy-Item -Force (Join-Path $repoRoot "scripts\codex-usage-snapshot.mjs") (Join-Path $scriptsDir "codex-usage-snapshot.mjs")
Copy-Item -Force (Join-Path $repoRoot "windows\QuotaBubble.ps1") (Join-Path $installDir "QuotaBubble.ps1")
Copy-Item -Force (Join-Path $repoRoot "assets\icon.png") (Join-Path $installDir "icon.png")

if (-not $NoStartupShortcut) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$installDir\QuotaBubble.ps1`""
    $shortcut.WorkingDirectory = $installDir
    $shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,44"
    $shortcut.Save()
}

Start-Process "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$installDir\QuotaBubble.ps1`""
Write-Host "Quota Bubble installed for Windows."
