$ErrorActionPreference = 'Stop'

$root = git rev-parse --show-toplevel 2>$null
if (-not $root) {
    $root = (Get-Location).Path
}

Set-Location $root

Write-Host 'Running PPV poster heuristics check...'

$patterns = @(
    'ImageAssets\.isLocalAsset\(.*posterUrl',
    "posterUrl!\.startsWith\('assets/ppv/'\)"
)

$targets = @('lib/features/ppv')
$excludes = @(
    'lib/shared/models/ppv_presentation_model.dart',
    'lib/shared/services/ppv_service.dart'
)

$failures = 0

foreach ($pattern in $patterns) {
    foreach ($target in $targets) {
        $matches = & git grep -n -E -- $pattern -- $target 2>$null
        if (-not $matches) {
            continue
        }

        $filtered = @($matches)
        foreach ($exclude in $excludes) {
            $filtered = @($filtered | Where-Object { $_ -notmatch ('^' + [regex]::Escape($exclude) + ':') })
        }

        if ($filtered.Count -gt 0) {
            Write-Host "Found forbidden poster heuristic '$pattern':"
            $filtered | ForEach-Object { Write-Host $_ }
            $failures++
        }
    }
}

if ($failures -gt 0) {
    Write-Host ''
    Write-Host 'ERROR: PPV UI must use PPVPresentationModel instead of poster heuristics.'
    exit 2
}

Write-Host 'PPV poster heuristics check passed.'
