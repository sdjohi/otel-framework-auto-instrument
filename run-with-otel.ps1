<#
.SYNOPSIS
    Launches OtelSqlDemo.exe with OpenTelemetry .NET auto-instrumentation enabled.

.DESCRIPTION
    Sets CLR Profiler and OTel environment variables for the current process, then starts the app.
    No admin privileges required — all env vars are process-scoped.

    IMPORTANT: OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED=true enables IL rewriting
    of SqlCommand so that db.query.text is populated for raw SQL queries (not just stored procedures).

.PARAMETER ExePath
    Path to the built executable. Defaults to bin\Debug\net48\OtelSqlDemo.exe.
#>

param(
    [string]$ExePath = "$PSScriptRoot\bin\Debug\net48\OtelSqlDemo.exe"
)

$ErrorActionPreference = "Stop"

$InstallDir = "$PSScriptRoot\otel-dotnet-auto"

if (-not (Test-Path $InstallDir)) {
    Write-Host "ERROR: OTel auto-instrumentation not found at $InstallDir" -ForegroundColor Red
    Write-Host "Run .\install-otel.ps1 first." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $ExePath)) {
    Write-Host "ERROR: Application not found at $ExePath" -ForegroundColor Red
    Write-Host "Build the project first: dotnet build" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Starting OtelSqlDemo with OpenTelemetry Auto-Instrumentation ===" -ForegroundColor Cyan
Write-Host ""

# --- .NET Framework CLR Profiler (process-scoped, no admin needed) ---
$env:COR_ENABLE_PROFILING = "1"
$env:COR_PROFILER = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
$env:COR_PROFILER_PATH_32 = "$InstallDir\win-x86\OpenTelemetry.AutoInstrumentation.Native.dll"
$env:COR_PROFILER_PATH_64 = "$InstallDir\win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"

# --- OTel Auto-Instrumentation home ---
$env:OTEL_DOTNET_AUTO_HOME = $InstallDir

# --- Service identification ---
$env:OTEL_SERVICE_NAME = "OtelSqlDemo"

# --- Exporter configuration (OTLP over HTTP, to grafana/otel-lgtm) ---
$env:OTEL_TRACES_EXPORTER = "otlp"
$env:OTEL_METRICS_EXPORTER = "otlp"
$env:OTEL_LOGS_EXPORTER = "otlp"
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:4318"
$env:OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf"  # gRPC is NOT supported on .NET Framework

# --- SqlClient-specific: enable IL rewrite to capture raw SQL query text ---
$env:OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED = "true"

# --- Pick up the custom OWIN HTTP tracing middleware ActivitySource ---
$env:OTEL_DOTNET_AUTO_TRACES_ADDITIONAL_SOURCES = "OtelSqlDemo.Http"

# --- Logs: include the formatted message so it shows up in Loki ---
$env:OTEL_DOTNET_AUTO_LOGS_INCLUDE_FORMATTED_MESSAGE = "true"

# --- NLog bridge: disabled by default, must be explicitly enabled ---
$env:OTEL_DOTNET_AUTO_LOGS_ENABLE_NLOG_BRIDGE = "true"

# --- Logging (optional, useful for debugging instrumentation issues) ---
$env:OTEL_LOG_LEVEL = "info"
$env:OTEL_DOTNET_AUTO_LOG_DIRECTORY = "$PSScriptRoot\otel-logs"
$env:OTEL_DOTNET_AUTO_LOGGER = "file"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  OTEL_SERVICE_NAME                                   = $env:OTEL_SERVICE_NAME"
Write-Host "  OTEL_EXPORTER_OTLP_ENDPOINT                        = $env:OTEL_EXPORTER_OTLP_ENDPOINT"
Write-Host "  OTEL_EXPORTER_OTLP_PROTOCOL                        = $env:OTEL_EXPORTER_OTLP_PROTOCOL"
Write-Host "  OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED  = $env:OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED"
Write-Host "  COR_ENABLE_PROFILING                                = $env:COR_ENABLE_PROFILING"
Write-Host "  OTEL_DOTNET_AUTO_HOME                               = $env:OTEL_DOTNET_AUTO_HOME"
Write-Host ""
Write-Host "Starting: $ExePath" -ForegroundColor Green
Write-Host ""

& $ExePath
