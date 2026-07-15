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
$versionSource = Join-Path $repoRoot "VERSION"
if (-not (Test-Path $versionSource)) {
    $manifestPath = Join-Path $repoRoot ".codex-plugin\plugin.json"
    if (Test-Path $manifestPath) {
        $version = (Get-Content $manifestPath -Raw | ConvertFrom-Json).version
    } else { $version = "3.0.2" }
} else { $version = (Get-Content $versionSource -Raw).Trim() }

Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe' OR Name = 'pwsh.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -like "*QuotaBubble.ps1*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Start-Sleep -Milliseconds 500

New-Item -ItemType Directory -Force -Path $installDir, $scriptsDir | Out-Null
Copy-Item -Force (Join-Path $repoRoot "scripts\codex-usage-snapshot.mjs") (Join-Path $scriptsDir "codex-usage-snapshot.mjs")
Copy-Item -Force (Join-Path $repoRoot "windows\QuotaBubble.ps1") (Join-Path $installDir "QuotaBubble.ps1")
Copy-Item -Force (Join-Path $repoRoot "assets\icon.png") (Join-Path $installDir "icon.png")
Set-Content -Path (Join-Path $installDir "VERSION") -Value $version -Encoding ASCII

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
Write-Host "Quota Bubble $version installed for Windows."
