# OtelSqlDemo — .NET Framework 4.8 + OTel Auto-Instrumentation + SqlClient

A self-hosted ASP.NET Web API (.NET Framework 4.8) that queries **SQL Server LocalDB** via
`System.Data.SqlClient`. It uses **OpenTelemetry .NET auto-instrumentation** (zero-code) to
capture SQL traces and export them to the **Grafana LGTM** stack (Grafana + Tempo + Loki + Prometheus).

## Goal

Verify that OTel auto-instrumentation captures **SQL statements** (`db.query.text`) in traces
when using `System.Data.SqlClient` on .NET Framework.

> **Key setting:** `OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED=true` enables IL rewriting
> of `SqlCommand` on .NET Framework so that `CommandText` is available for all queries — not just
> stored procedures. Without this, `db.query.text` is empty for raw SQL.

## Prerequisites

| Requirement | Notes |
|---|---|
| **.NET 4.8 targeting pack** | Comes with Visual Studio |
| **.NET SDK 6+** | For `dotnet build` with SDK-style csproj targeting net48 |
| **SQL Server LocalDB** | Pre-installed with Visual Studio; or install [SQL Server Express LocalDB](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/sql-server-express-localdb) |
| **Docker** | For the Grafana LGTM container |
| **PowerShell 5.1+** | For the automation scripts |

## Quick Start

### 1. Build the application

```powershell
dotnet build
```

### 2. Start the observability backend

```powershell
docker compose up -d
```

This starts `grafana/otel-lgtm` with:
- **Grafana** at http://localhost:3000 (login: `admin` / `admin`)
- **OTLP HTTP** receiver at http://localhost:4318

### 3. Install OpenTelemetry auto-instrumentation

```powershell
.\install-otel.ps1
```

Downloads the official OTel .NET auto-instrumentation binaries into `.\otel-dotnet-auto\`.

### 4. Run the app with instrumentation

```powershell
.\run-with-otel.ps1
```

This sets all the required CLR Profiler and OTel environment variables, then launches the app.
The API will be available at http://localhost:9000.

### 5. Generate traffic

In a separate terminal:

```powershell
.\test-endpoints.ps1
```

### 6. View traces in Grafana

1. Open http://localhost:3000
2. Go to **Explore** → select **Tempo** as the data source
3. Search by **Service Name** = `OtelSqlDemo`
4. Click on a trace to see its spans

## What to look for

In the trace details, you should see:

- **HTTP spans** — one per API request (`GET /api/products`, etc.)
- **SQL spans** (child of the HTTP span) with attributes:
  - `db.system` = `mssql`
  - `db.name` = `OtelSqlDemo`
  - `db.query.text` = the actual SQL statement (e.g., `SELECT Id, Name, Price, CreatedAt FROM Products ORDER BY Id`)
  - `server.address` = `(LocalDB)\MSSQLLocalDB`

### Testing without IL rewrite

To verify the impact of `OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED`:

1. In `run-with-otel.ps1`, change the value to `"false"`
2. Restart the app and send more requests
3. Observe that `db.query.text` is **missing** for raw SQL queries (only present for stored procedures)

## Project Structure

```
├── OtelSqlDemo.csproj              # .NET Framework 4.8 SDK-style project
├── OtelSqlDemo.sln                 # Solution file
├── Program.cs                      # OWIN self-host entry point (port 9000)
├── Startup.cs                      # OWIN/WebApi route configuration
├── DatabaseInitializer.cs          # LocalDB database & table creation + seeding
├── Controllers/
│   └── ProductsController.cs       # Web API controller with raw SqlClient queries
├── docker-compose.yml              # Grafana LGTM (Grafana + Tempo + Loki + Prometheus)
├── install-otel.ps1                # Downloads OTel .NET auto-instrumentation
├── run-with-otel.ps1               # Launches app with CLR Profiler & OTel env vars
├── test-endpoints.ps1              # Generates HTTP traffic for trace collection
└── README.md                       # This file
```

## API Endpoints

| Method | URL | Description |
|---|---|---|
| GET | `/api/products` | List all products |
| GET | `/api/products/{id}` | Get a single product by ID |
| POST | `/api/products` | Create a product (`{"Name":"...","Price":12.99}`) |

## Key OTel Environment Variables

| Variable | Value | Purpose |
|---|---|---|
| `COR_ENABLE_PROFILING` | `1` | Enables CLR Profiler (required for .NET Framework) |
| `COR_PROFILER` | `{918728DD-...}` | OTel profiler CLSID |
| `OTEL_SERVICE_NAME` | `OtelSqlDemo` | Service name shown in traces |
| `OTEL_EXPORTER_OTLP_PROTOCOL` | `http/protobuf` | gRPC is **not supported** on .NET Framework |
| `OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED` | `true` | **Captures raw SQL query text** (not just stored procs) |

## Cleanup

```powershell
# Stop the observability stack
docker compose down

# Remove the OTel installation
Remove-Item -Recurse -Force .\otel-dotnet-auto

# Drop the LocalDB database (optional)
SqlLocalDB.exe stop MSSQLLocalDB
SqlLocalDB.exe delete MSSQLLocalDB
```
