param(
  [switch]$Apply
)

$ErrorActionPreference = "Stop"

$targetDir = "lib/features/legacy_root"
$quarantineDir = ".github/quarantine"

$rootDart = Get-ChildItem -File -Filter *.dart | Sort-Object Name

if ($rootDart.Count -eq 0) {
  Write-Host "No root-level Dart files found."
  exit 0
}

Write-Host "Found $($rootDart.Count) root-level Dart files."
Write-Host "Target module: $targetDir"

if (-not (Test-Path -LiteralPath $targetDir)) {
  if ($Apply) {
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
  } else {
    Write-Host "[DRY-RUN] mkdir $targetDir"
  }
}

foreach ($file in $rootDart) {
  $dest = Join-Path $targetDir $file.Name
  if ($Apply) {
    git mv -- $file.FullName $dest
    Write-Host "MOVED: $($file.Name) -> $dest"
  } else {
    Write-Host "[DRY-RUN] git mv -- $($file.FullName) $dest"
  }
}

$stray = ".github/workflows/dfc folder unamed.txt"
if (Test-Path -LiteralPath $stray) {
  if (-not (Test-Path -LiteralPath $quarantineDir)) {
    if ($Apply) {
      New-Item -ItemType Directory -Path $quarantineDir -Force | Out-Null
    } else {
      Write-Host "[DRY-RUN] mkdir $quarantineDir"
    }
  }

  $destStray = Join-Path $quarantineDir "dfc-folder-unnamed.txt"
  if ($Apply) {
    git mv -- $stray $destStray
    Write-Host "QUARANTINED: $stray -> $destStray"
  } else {
    Write-Host "[DRY-RUN] git mv -- $stray $destStray"
  }
}

$readmePath = Join-Path $targetDir "README.md"
$readme = @"
# Legacy Root Migration Bucket

This folder temporarily contains Dart files migrated from repository root.

Purpose:
- Eliminate root-level code leakage.
- Preserve file history via `git mv`.
- Enable incremental migration into domain/feature-specific folders.

Next action:
- Move files from this bucket into `screens`, `widgets`, `services`, `controllers`, and `models` per feature.
"@

if ($Apply) {
  Set-Content -LiteralPath $readmePath -Value $readme -Encoding UTF8
  Write-Host "WROTE: $readmePath"
} else {
  Write-Host "[DRY-RUN] write $readmePath"
}

Write-Host "Done. Apply mode: $Apply"
