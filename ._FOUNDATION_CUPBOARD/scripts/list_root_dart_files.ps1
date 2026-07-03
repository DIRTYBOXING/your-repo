$ErrorActionPreference = "Stop"

$rootDartFiles = Get-ChildItem -File -Filter *.dart | Sort-Object Name

Write-Host "ROOT_DART_COUNT=$($rootDartFiles.Count)"
Write-Host "---ROOT_DART_FILES---"
$rootDartFiles | ForEach-Object { Write-Host $_.Name }

$libNames = Get-ChildItem -Path lib -Recurse -File -Filter *.dart | Select-Object -ExpandProperty Name
$duplicates = $rootDartFiles | Where-Object { $libNames -contains $_.Name }
$orphans = $rootDartFiles | Where-Object { $libNames -notcontains $_.Name }

Write-Host "---DUPLICATE_IN_LIB---"
$duplicates | Sort-Object Name | ForEach-Object { Write-Host $_.Name }

Write-Host "---ORPHAN_BY_NAME---"
$orphans | Sort-Object Name | ForEach-Object { Write-Host $_.Name }
