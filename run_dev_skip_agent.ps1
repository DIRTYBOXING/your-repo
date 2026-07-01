# Simple runner to execute dev_skip_agent.ps1 and capture logs

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

# Use UTF8 without BOM to avoid log corruption
$logPath = Join-Path $PSScriptRoot 'dev_skip_agent_run.log'

& "$PSScriptRoot\dev_skip_agent.ps1" 2>&1 | Out-File -FilePath $logPath -Encoding utf8

Write-Host "Wrote: $logPath"
