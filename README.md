# OtelSqlDemo — .NET Framework 4.8 + OTel Auto-Instrumentation + SqlClient

Self-hosted ASP.NET Web API (.NET Framework 4.8) that queries SQL Server LocalDB via `System.Data.SqlClient`, instrumented with **OpenTelemetry .NET auto-instrumentation** (zero-code). Traces, logs, and metrics are exported to **Grafana LGTM** (Tempo + Loki + Prometheus).

> This app uses OWIN self-host + LocalDB for simplicity. For IIS-hosted apps the instrumentation is identical but config is more involved — see [IIS notes](#iis-notes) below.

## Quick Start

```powershell
dotnet build                # 1. Build
docker compose up -d        # 2. Start Grafana LGTM (localhost:3000, OTLP on :4318)
.\install-otel.ps1          # 3. Download OTel auto-instrumentation
.\run-with-otel.ps1         # 4. Launch app with profiler (API on localhost:9000)
.\test-endpoints.ps1        # 5. Generate traffic (separate terminal)
```

Then open http://localhost:3000 → Explore → **Tempo** → Service Name = `OtelSqlDemo`.

### Prerequisites

.NET 4.8 targeting pack, .NET SDK 6+, [SQL Server LocalDB](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/sql-server-express-localdb), Docker, PowerShell 5.1+.

## Key Settings

| Variable | Value | Why |
|---|---|---|
| `OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED` | `true` | Captures raw SQL query text (`db.query.text`) — without this, only stored proc names are recorded |
| `OTEL_DOTNET_AUTO_LOGS_ENABLE_NLOG_BRIDGE` | `true` | Forwards NLog records to OTLP (disabled by default) |
| `OTEL_DOTNET_AUTO_LOGS_INCLUDE_FORMATTED_MESSAGE` | `true` | Includes the rendered message body in exported logs |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | gRPC is **not supported** on .NET Framework |

All env vars are set in `run-with-otel.ps1`. See the full list in the [OTel .NET config docs](https://opentelemetry.io/docs/zero-code/net/configuration/).

## API Endpoints

| Method | URL | Description |
|---|---|---|
| GET | `/api/products` | List all products |
| GET | `/api/products/{id}` | Get product by ID |
| POST | `/api/products` | Create product (`{"Name":"...","Price":12.99}`) |

## IIS Notes

For IIS-hosted ASP.NET apps instead of OWIN self-host:

- `COR_ENABLE_PROFILING`, `COR_PROFILER*`, `OTEL_DOTNET_AUTO_HOME` must be set per Application Pool via `<environmentVariables>` in `applicationHost.config` (IIS 10+) — they **cannot** go in `Web.config`
- Most `OTEL_*` settings can go in `Web.config` `<appSettings>`, but [not all](https://opentelemetry.io/docs/zero-code/net/configuration/#configuration-methods)
- Each Application Pool is a separate `w3wp.exe` process with its own OTel SDK instance — **one pool = one service name**
- If multiple apps share one pool, the first app to start sets the `OTEL_*` config for all ([source](https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/blob/main/docs/iis-instrumentation.md#configuration))

## Reference Links

- [Getting Started](https://opentelemetry.io/docs/zero-code/net/getting-started/) · [Configuration](https://opentelemetry.io/docs/zero-code/net/configuration/) · [Instrumentations](https://opentelemetry.io/docs/zero-code/net/instrumentations/) · [Troubleshooting](https://opentelemetry.io/docs/zero-code/net/troubleshooting/)
- [IIS instrumentation guide](https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/blob/main/docs/iis-instrumentation.md) · [NLog logs bridge](https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/blob/main/docs/nlog-bridge.md)

## Cleanup

```powershell
docker compose down
Remove-Item -Recurse -Force .\otel-dotnet-auto
# Optional: drop LocalDB database
SqlLocalDB.exe stop MSSQLLocalDB
SqlLocalDB.exe delete MSSQLLocalDB
```
