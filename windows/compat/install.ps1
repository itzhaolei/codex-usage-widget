$ErrorActionPreference = "Stop"
$installer = Get-ChildItem -Path $PSScriptRoot -Filter "*Windows-Setup.exe" | Select-Object -First 1
if (-not $installer) { throw "Quota Bubble graphical installer was not found." }

Start-Process $installer.FullName -ArgumentList "/SILENT", "/CLOSEAPPLICATIONS", "/RESTARTAPPLICATIONS"
