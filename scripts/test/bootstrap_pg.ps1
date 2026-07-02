$ErrorActionPreference = 'Stop'

$containerName = $env:PG_CONTAINER_NAME
if ([string]::IsNullOrWhiteSpace($containerName)) { $containerName = 'dfc-pg-test' }

$user = $env:POSTGRES_USER
if ([string]::IsNullOrWhiteSpace($user)) { $user = 'dfc' }

$pass = $env:POSTGRES_PASSWORD
if ([string]::IsNullOrWhiteSpace($pass)) { $pass = 'dfc' }

$db = $env:POSTGRES_DB
if ([string]::IsNullOrWhiteSpace($db)) { $db = 'dfc_test' }

$port = $env:POSTGRES_PORT
if ([string]::IsNullOrWhiteSpace($port)) { $port = '5432' }

$existing = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $containerName }
if ($existing) {
  docker rm -f $containerName | Out-Null
}

docker run -d --name $containerName `
  -e "POSTGRES_USER=$user" `
  -e "POSTGRES_PASSWORD=$pass" `
  -e "POSTGRES_DB=$db" `
  -p "${port}:5432" `
  postgres:15 | Out-Null

$env:PG_CONN = "postgres://${user}:${pass}@localhost:${port}/${db}"
Write-Host "PG_CONN=$($env:PG_CONN)"
Write-Host "Waiting for PostgreSQL readiness..."

for ($i = 0; $i -lt 60; $i++) {
  docker exec $containerName pg_isready -U $user -d $db 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "PostgreSQL is ready in container $containerName"
    exit 0
  }
  Start-Sleep -Seconds 1
}

throw "PostgreSQL did not become ready in time"
