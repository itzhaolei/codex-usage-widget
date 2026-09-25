param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Version,
  [int]$BuildNumber = 1,
  [string]$Flutter = "flutter"
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$BuildRoot = Join-Path $Root "build\windows"
$PublishDir = Join-Path $Root "windows\publish"

Push-Location $Root
try {
  & $Flutter pub get
  if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed with exit code $LASTEXITCODE" }

  & $Flutter build windows --release --build-name=$Version --build-number=$BuildNumber
  if ($LASTEXITCODE -ne 0) { throw "Flutter Windows build failed with exit code $LASTEXITCODE" }

  # Flutter has used both build/windows/runner/Release and
  # build/windows/x64/runner/Release over its supported Windows releases.
  $candidate = Get-ChildItem -Path $BuildRoot -Recurse -Filter "*.exe" -File |
    Where-Object {
      $_.Name -in @("quota_bubble.exe", "QuotaBubble.exe") -and
      $_.FullName -match "[\\/]runner[\\/]Release[\\/](quota_bubble|QuotaBubble)\.exe$"
    } |
    Select-Object -First 1
  if ($null -eq $candidate) {
    throw "Flutter Windows executable was not found below $BuildRoot"
  }

  if (Test-Path $PublishDir) { Remove-Item $PublishDir -Recurse -Force }
  New-Item $PublishDir -ItemType Directory -Force | Out-Null
  Copy-Item (Join-Path $candidate.Directory.FullName "*") $PublishDir -Recurse -Force

  # Keep the installer and update bridge filename used by existing releases.
  $flutterExe = Join-Path $PublishDir $candidate.Name
  $releaseExe = Join-Path $PublishDir "QuotaBubble.exe"
  if ($candidate.Name -ne "QuotaBubble.exe") {
    if (Test-Path $releaseExe) { Remove-Item $releaseExe -Force }
    Rename-Item $flutterExe "QuotaBubble.exe"
  }
  if (-not (Test-Path $releaseExe)) { throw "QuotaBubble.exe was not published" }

  Write-Output $releaseExe
}
finally {
  Pop-Location
}
