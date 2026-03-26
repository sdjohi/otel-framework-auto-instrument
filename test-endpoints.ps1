<#
.SYNOPSIS
    Sends HTTP requests to the OtelSqlDemo API to generate trace data.
.DESCRIPTION
    Calls each API endpoint multiple times to produce a variety of SQL spans
    that you can inspect in Grafana/Tempo.
#>

$ErrorActionPreference = "Stop"
$baseUrl = "http://localhost:9000/api/products"

Write-Host "=== Generating traffic to OtelSqlDemo API ===" -ForegroundColor Cyan
Write-Host ""

# GET all products
Write-Host "[1/5] GET $baseUrl" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri $baseUrl -Method Get
Write-Host "  Returned $($response.Count) products" -ForegroundColor Green
Start-Sleep -Milliseconds 500

# GET single product (id=1)
Write-Host "[2/5] GET $baseUrl/1" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$baseUrl/1" -Method Get
Write-Host "  Product: $($response.Name) - `$$($response.Price)" -ForegroundColor Green
Start-Sleep -Milliseconds 500

# GET single product (id=3)
Write-Host "[3/5] GET $baseUrl/3" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri "$baseUrl/3" -Method Get
Write-Host "  Product: $($response.Name) - `$$($response.Price)" -ForegroundColor Green
Start-Sleep -Milliseconds 500

# POST new product
Write-Host "[4/5] POST $baseUrl (create new product)" -ForegroundColor Yellow
$body = @{ Name = "OTel Test Widget"; Price = 19.99 } | ConvertTo-Json
$response = Invoke-RestMethod -Uri $baseUrl -Method Post -Body $body -ContentType "application/json"
Write-Host "  Created: Id=$($response.Id), Name=$($response.Name)" -ForegroundColor Green
Start-Sleep -Milliseconds 500

# GET all products again (to see the new one)
Write-Host "[5/5] GET $baseUrl (after insert)" -ForegroundColor Yellow
$response = Invoke-RestMethod -Uri $baseUrl -Method Get
Write-Host "  Returned $($response.Count) products" -ForegroundColor Green

# Rapid-fire some more requests to build up trace data
Write-Host ""
Write-Host "Sending 10 rapid GET requests..." -ForegroundColor Yellow
for ($i = 1; $i -le 100; $i++) {
    $id = Get-Random -Minimum 1 -Maximum 6
    Invoke-RestMethod -Uri "$baseUrl/$id" -Method Get | Out-Null
    Write-Host "  [$i/10] GET /api/products/$id" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "=== Done! ===" -ForegroundColor Green
Write-Host "Open Grafana at http://localhost:3000 to inspect traces." -ForegroundColor Cyan
Write-Host "Navigate to: Explore -> Tempo -> Search -> Service Name = 'OtelSqlDemo'" -ForegroundColor Cyan
Write-Host ""
Write-Host "What to look for in trace details:" -ForegroundColor Yellow
Write-Host "  - HTTP spans for each API call" -ForegroundColor White
Write-Host "  - Child SQL spans with db.system = 'mssql'" -ForegroundColor White
Write-Host "  - db.query.text attribute containing the actual SQL statement" -ForegroundColor White
Write-Host "    (requires OTEL_DOTNET_AUTO_SQLCLIENT_NETFX_ILREWRITE_ENABLED=true)" -ForegroundColor White
