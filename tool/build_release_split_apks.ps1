Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot

flutter build apk --release --split-per-abi

Write-Host ""
Write-Host "Split APKs generated in build\app\outputs\flutter-apk" -ForegroundColor Green
