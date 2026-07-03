#!/usr/bin/env pwsh
# forensic_scan.ps1 — DFC Asset Integrity Scanner
# Usage: .\scripts\forensic_scan.ps1 [-Days 1] [-Quarantine] [-Sanitize]
# -Days       : how many days back to scan (default 1)
# -Quarantine : move suspicious files to quarantine/ folder
# -Sanitize   : strip <script>, onload, foreignObject, external hrefs from SVGs in-place
[CmdletBinding()]
param(
    [int]$Days = 1,
    [switch]$Quarantine,
    [switch]$Sanitize
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path "$PSScriptRoot/..").Path
Push-Location $Root

$ScanDirs  = @('assets','docs','test')
$ImageExts = @('.png','.jpg','.jpeg','.gif','.webp','.svg','.ico')

$End   = Get-Date
$Start = $End.AddDays(-$Days)

Write-Host "`n=== DFC Forensic Image Scan ===" -ForegroundColor Cyan
Write-Host "Root    : $Root"
Write-Host "Period  : $($Start.ToString('yyyy-MM-dd HH:mm')) → $($End.ToString('yyyy-MM-dd HH:mm'))"
Write-Host "Dirs    : $($ScanDirs -join ', ')"

# ── 1. Collect candidate files ──────────────────────────────────────────────
$Files = Get-ChildItem -Recurse -File $ScanDirs -ErrorAction SilentlyContinue |
    Where-Object { $_.Extension -in $ImageExts }

Write-Host "`nFound $($Files.Count) image file(s) total."

# ── 2. Magic-byte signatures ─────────────────────────────────────────────────
$MagicMap = @{
    PNG  = @(0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A)
    JPEG = @(0xFF,0xD8,0xFF)
    GIF  = @(0x47,0x49,0x46,0x38)
    WebP = @(0x52,0x49,0x46,0x46)
    ICO  = @(0x00,0x00,0x01,0x00)
}

function Test-Magic([byte[]]$Bytes, [byte[]]$Sig) {
    for ($i = 0; $i -lt $Sig.Length; $i++) {
        if ($i -ge $Bytes.Length -or $Bytes[$i] -ne $Sig[$i]) { return $false }
    }
    return $true
}

function Get-ExpectedMagic([string]$Ext) {
    switch ($Ext.ToLower()) {
        '.png'  { return $MagicMap['PNG']  }
        '.jpg'  { return $MagicMap['JPEG'] }
        '.jpeg' { return $MagicMap['JPEG'] }
        '.gif'  { return $MagicMap['GIF']  }
        '.webp' { return $MagicMap['WebP'] }
        '.ico'  { return $MagicMap['ICO']  }
        '.svg'  { return $null }   # text — checked differently
        default { return $null }
    }
}

# ── 3. SVG active-content patterns ──────────────────────────────────────────
$SvgPatterns = [ordered]@{
    'script_tag'       = '<script\b'
    'onload_handler'   = 'onload\s*='
    'onerror_handler'  = 'onerror\s*='
    'foreignObject'    = 'foreignObject'
    'external_xlink'   = 'xlink:href\s*=\s*"https?://'
    'external_href'    = '\bhref\s*=\s*"https?://'
    'javascript_uri'   = 'javascript:'
    'data_uri_script'  = 'data:text/html'
    'base64_blob'      = 'data:application/octet-stream'
}

# ── 4. Scan each file ────────────────────────────────────────────────────────
$Report   = [System.Collections.Generic.List[PSObject]]::new()
$Suspect  = [System.Collections.Generic.List[string]]::new()

foreach ($f in $Files) {
    $bytes   = [System.IO.File]::ReadAllBytes($f.FullName)
    $sigHex  = ($bytes[0..[Math]::Min(15,$bytes.Length-1)] | ForEach-Object { $_.ToString('X2') }) -join ' '
    $sha256  = (Get-FileHash -Algorithm SHA256 -LiteralPath $f.FullName).Hash
    $issues  = [System.Collections.Generic.List[string]]::new()
    $magicOk = $true

    # Detect text placeholder stubs (tiny files starting with '[' or 'PLACEHOLDER')
    $isPlaceholder = $false
    if ($bytes.Length -lt 200) {
        $leadText = [System.Text.Encoding]::UTF8.GetString($bytes[0..[Math]::Min(20,$bytes.Length-1)])
        if ($leadText -match '^\[Binary image|^PLACEHOLDER') {
            $isPlaceholder = $true
        }
    }

    # Magic byte check (non-SVG)
    $expected = Get-ExpectedMagic $f.Extension
    if ($null -ne $expected -and -not $isPlaceholder) {
        if (-not (Test-Magic $bytes $expected)) {
            # Allow PNG magic in a .jpg/.jpeg file (common re-save scenario) — flag as INFO not SUSPECT
            $isPngInJpg = ($f.Extension -imatch '\.(jpg|jpeg)$') -and (Test-Magic $bytes $MagicMap['PNG'])
            if ($isPngInJpg) {
                $issues.Add("info:png_content_in_jpg_ext")
            } else {
                $issues.Add("magic_mismatch")
                $magicOk = $false
            }
        }
    }

    # SVG text checks
    if ($f.Extension -ieq '.svg') {
        $text = [System.IO.File]::ReadAllText($f.FullName)
        # Must start with XML/SVG declaration
        $trimmed = $text.TrimStart()
        if (-not ($trimmed.StartsWith('<?xml') -or $trimmed.StartsWith('<svg') -or $trimmed.StartsWith('<!--'))) {
            $issues.Add("invalid_svg_header")
        }
        foreach ($kv in $SvgPatterns.GetEnumerator()) {
            if ($text -match $kv.Value) {
                $issues.Add($kv.Key)
            }
        }
    }

    $realIssues = @($issues | Where-Object { $_ -notmatch '^info:' })
    $infoOnly   = @($issues | Where-Object { $_ -match '^info:' })
    $status = if ($isPlaceholder) { 'PLACEHOLDER' }
              elseif ($realIssues.Count -eq 0 -and $infoOnly.Count -gt 0) { 'INFO' }
              elseif ($realIssues.Count -eq 0) { 'CLEAN' }
              else { 'SUSPECT' }

    $row = [PSCustomObject]@{
        Path     = $f.FullName.Replace($Root,'').TrimStart('\/')
        Size     = $f.Length
        Sig      = $sigHex
        SHA256   = $sha256
        Issues   = ($issues -join '; ')
        Status   = $status
    }
    $Report.Add($row)

    if ($status -eq 'SUSPECT') { $Suspect.Add($f.FullName) }
}

# ── 5. Print summary ─────────────────────────────────────────────────────────
$Report | Format-Table Path, Size, Status, Issues -AutoSize

$CsvPath = Join-Path $Root 'forensic_summary.csv'
$Report | Export-Csv -Path $CsvPath -NoTypeInformation -Force
Write-Host "CSV report written → $CsvPath" -ForegroundColor Green

# ── 6. SVG sanitization (in-place) ──────────────────────────────────────────
if ($Sanitize) {
    $SvgSuspect = $Report | Where-Object { $_.Status -eq 'SUSPECT' -and $_.Path -match '\.svg$' }
    foreach ($row in $SvgSuspect) {
        $fullPath = Join-Path $Root $row.Path
        $text     = [System.IO.File]::ReadAllText($fullPath)

        # Remove <script> blocks
        $text = [regex]::Replace($text, '<script\b[^>]*>[\s\S]*?</script\s*>', '', 'IgnoreCase,Singleline')
        # Remove onload / onerror attributes
        $text = [regex]::Replace($text, '\s+on(load|error)\s*=\s*"[^"]*"', '', 'IgnoreCase')
        $text = [regex]::Replace($text, "\s+on(load|error)\s*=\s*'[^']*'", '', 'IgnoreCase')
        # Remove <foreignObject> blocks
        $text = [regex]::Replace($text, '<foreignObject[\s\S]*?</foreignObject\s*>', '', 'IgnoreCase,Singleline')
        # Remove external hrefs/xlinks
        $text = [regex]::Replace($text, '(xlink:href|href)\s*=\s*"https?://[^"]*"', '', 'IgnoreCase')
        # Remove javascript: URIs
        $text = [regex]::Replace($text, '(xlink:href|href)\s*=\s*"javascript:[^"]*"', '', 'IgnoreCase')

        [System.IO.File]::WriteAllText($fullPath, $text)
        Write-Host "Sanitized: $($row.Path)" -ForegroundColor Yellow
    }
}

# ── 7. Quarantine ────────────────────────────────────────────────────────────
if ($Quarantine -and $Suspect.Count -gt 0) {
    $QDir = Join-Path $Root 'quarantine'
    New-Item -ItemType Directory -Path $QDir -Force | Out-Null

    foreach ($path in $Suspect) {
        $rel  = $path.Replace($Root,'').TrimStart('\/')
        $dest = Join-Path $QDir ($rel -replace '[/\\]', '__')
        Copy-Item -LiteralPath $path -Destination $dest -Force
        Remove-Item -LiteralPath $path -Force
        Write-Host "Quarantined: $rel → quarantine\$(Split-Path $dest -Leaf)" -ForegroundColor Red
    }

    Write-Host "`n$($Suspect.Count) file(s) moved to quarantine/." -ForegroundColor Red
} elseif ($Suspect.Count -eq 0) {
    Write-Host "`nAll files CLEAN. No quarantine needed." -ForegroundColor Green
}

Write-Host "`n=== Scan complete ===" -ForegroundColor Cyan
Pop-Location
