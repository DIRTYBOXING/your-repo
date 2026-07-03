$ErrorActionPreference = "Stop"

Write-Host "Running DFC architecture checks..."

$issues = @()

$rootDart = Get-ChildItem -File -Filter *.dart | Select-Object -ExpandProperty Name
if ($rootDart.Count -gt 0) {
  $issues += "Root-level Dart files detected: $($rootDart.Count)"
}

$requiredDirs = @(
  "lib/domain/entities",
  "lib/domain/repositories",
  "lib/domain/usecases",
  "lib/features/maps",
  "lib/features/gyms",
  "lib/features/rankings",
  "lib/features/prediction",
  "lib/features/health",
  "lib/features/devices",
  "lib/features/ai"
)

foreach ($dir in $requiredDirs) {
  if (-not (Test-Path -LiteralPath $dir)) {
    $issues += "Missing required directory: $dir"
  }
}

$serviceFilesInScreens = Get-ChildItem -Recurse -File -Path lib/features/*/screens -Filter *service*.dart -ErrorAction SilentlyContinue
if ($serviceFilesInScreens) {
  $issues += "Service files are inside screens directories."
}

if ($issues.Count -eq 0) {
  Write-Host "PASS: Architecture checks passed."
  exit 0
}

Write-Host "FAIL: Architecture checks found issues:"
$issues | ForEach-Object { Write-Host " - $_" }
exit 1
