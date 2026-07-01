<#
  Usage:
    pwsh ./scripts/fix-image-assets.ps1 -DryRun
    pwsh ./scripts/fix-image-assets.ps1
#>

param(
  [switch]$DryRun
)

$extensions = @("*.png","*.jpg","*.jpeg","*.gif","*.webp")
$badFiles = @()

Write-Output "Scanning image files under assets for magic byte mismatches..."

Get-ChildItem -Path .\assets -Recurse -Include $extensions -File -ErrorAction SilentlyContinue | ForEach-Object {
  $path = $_.FullName
  try {
    $fs = [System.IO.File]::OpenRead($path)
    $bytes = New-Object byte[] 8
    $fs.Read($bytes,0,8) | Out-Null
    $fs.Close()

    $sig = -join ($bytes | ForEach-Object { $_.ToString("X2") })
    $isPng = $sig.StartsWith("89504E47")
    $isJpeg = $sig.StartsWith("FFD8FF")
    $isGif = $sig.StartsWith("47494638")
    $isWebp = $sig.StartsWith("52494646")

    $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
    $mismatch = $false
    switch ($ext) {
      ".png" { if (-not $isPng) { $mismatch = $true } }
      ".jpg" { if (-not $isJpeg) { $mismatch = $true } }
      ".jpeg" { if (-not $isJpeg) { $mismatch = $true } }
      ".gif" { if (-not $isGif) { $mismatch = $true } }
      ".webp" { if (-not $isWebp) { $mismatch = $true } }
    }

    if ($mismatch) {
      $badFiles += [PSCustomObject]@{ Path = $path; Sig = $sig; Ext = $ext }
      Write-Output "MISMATCH: $path (sig:$sig ext:$ext)"
    }
  } catch {
    Write-Output "Error reading $path: $_"
  }
}

if ($badFiles.Count -eq 0) {
  Write-Output "No mismatched image assets found."
  exit 0
}

Write-Output "`nFound $($badFiles.Count) mismatched files.`n"

if ($DryRun) {
  Write-Output "Dry run mode. No changes made."
  exit 0
}

foreach ($entry in $badFiles) {
  $f = $entry.Path
  $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
  $dir = [System.IO.Path]::GetDirectoryName($f)
  $base = [System.IO.Path]::GetFileNameWithoutExtension($f)

  $newExt = switch -Regex ($entry.Sig) {
    '^89504E47' { '.png'; break }
    '^FFD8FF' { '.jpg'; break }
    '^47494638' { '.gif'; break }
    '^52494646' { '.webp'; break }
    default { $ext }
  }

  $newPath = Join-Path $dir ($base + $newExt)

  if ($newPath -ne $f) {
    Write-Output "Renaming $f -> $newPath"
    Rename-Item -Path $f -NewName ($base + $newExt) -Force
  }
}

Write-Output "Done. Stage changes with: git add -A"
