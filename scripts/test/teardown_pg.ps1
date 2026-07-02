$ErrorActionPreference = 'Stop'

$containerName = $env:PG_CONTAINER_NAME
if ([string]::IsNullOrWhiteSpace($containerName)) { $containerName = 'dfc-pg-test' }

$existing = docker ps -a --format "{{.Names}}" | Where-Object { $_ -eq $containerName }
if ($existing) {
  docker rm -f $containerName | Out-Null
  Write-Host "Removed $containerName"
}
else {
  Write-Host "Container $containerName not found"
}
