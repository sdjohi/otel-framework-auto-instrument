<#
.SYNOPSIS
    Downloads and installs OpenTelemetry .NET Auto-Instrumentation for Windows.

.DESCRIPTION
    Downloads the official release ZIP and PowerShell module from the
    opentelemetry-dotnet-instrumentation GitHub releases.
    After installation, use run-with-otel.ps1 to launch the app with instrumentation.
#>

$ErrorActionPreference = "Stop"

$Version = "v1.14.1"
$InstallDir = "$PSScriptRoot\otel-dotnet-auto"
$baseUrl = "https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/$Version"

Write-Host "=== OpenTelemetry .NET Auto-Instrumentation Installer ===" -ForegroundColor Cyan
Write-Host "Version: $Version"
Write-Host ""

# Step 1: Download the Windows ZIP
$zipUrl = "$baseUrl/opentelemetry-dotnet-instrumentation-windows.zip"
$zipPath = "$PSScriptRoot\otel-dotnet-auto-windows.zip"

if (-not (Test-Path $zipPath)) {
    Write-Host "Downloading Windows instrumentation ZIP..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "Downloaded: $zipPath" -ForegroundColor Green
} else {
    Write-Host "ZIP already downloaded: $zipPath" -ForegroundColor DarkGray
}

# Step 2: Extract to install directory
if (Test-Path $InstallDir) {
    Write-Host "Removing existing installation..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $InstallDir
}

Write-Host "Extracting to: $InstallDir" -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
Write-Host "Extracted successfully." -ForegroundColor Green

# Step 3: Download the PowerShell module (helper functions for env var setup)
$psmUrl = "$baseUrl/OpenTelemetry.DotNet.Auto.psm1"
$psmPath = "$InstallDir\OpenTelemetry.DotNet.Auto.psm1"

Write-Host "Downloading PowerShell module..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $psmUrl -OutFile $psmPath -UseBasicParsing
Write-Host "Downloaded: $psmPath" -ForegroundColor Green

Write-Host ""
Write-Host "=== Installation complete ===" -ForegroundColor Green
Write-Host "Installation directory: $InstallDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Start the Grafana LGTM stack:  docker compose up -d" -ForegroundColor White
Write-Host "  2. Run the app with OTel:          .\run-with-otel.ps1" -ForegroundColor White
Write-Host "  3. Generate traffic:                .\test-endpoints.ps1" -ForegroundColor White
Write-Host "  4. View traces in Grafana:          http://localhost:3000" -ForegroundColor White
