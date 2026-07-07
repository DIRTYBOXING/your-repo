<#
  fix-image-assets.ps1

  Purpose:
    - Detect image files under DFC_UNIFIED whose file content (magic bytes) does not match their file extension.
    - Offer a DryRun mode to list mismatches.
    - Optionally convert mismatched files using ImageMagick (if installed) or rename them to the correct extension.
    - Stage changes and create a single commit at the end.

  Usage:
    pwsh ./scripts/fix-image-assets.ps1 -DryRun
    pwsh ./scripts/fix-image-assets.ps1 -ConvertWithMagick

  Notes:
    - This script stages changes with git add -A and commits once at the end.
    - It will not remove original files unless conversion succeeds.
#>

param(
  [switch]$DryRun,
  [switch]$ConvertWithMagick
)

function Read-Bytes {
  param($path, $count)
  $fs = [System.IO.File]::OpenRead($path)
  try {
    $bytes = New-Object byte[] $count
    $read = $fs.Read($bytes, 0, $count)
    if ($read -lt $count) {
      $bytes = $bytes[0..($read-1)]
    }
    return ,$bytes
  } finally {
    $fs.Close()
  }
}

$extensions = @("*.png","*.jpg","*.jpeg","*.gif","*.webp")
$badFiles = @()

Write-Output "Scanning image files under DFC_UNIFIED for magic byte mismatches..."

Get-ChildItem -Path .\DFC_UNIFIED -Recurse -Include $extensions -File | ForEach-Object {
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
    $isWebp = $sig.Substring(0,8) -match "52494646" # RIFF header for webp

    $ext = [System.IO.Path]::GetExtension($path).ToLowerInvariant()
    $mismatch = $false
    switch ($ext) {
      ".png" { if (-not $isPng) { $mismatch = $true } }
      ".jpg" { if (-not $isJpeg) { $mismatch = $true } }
      ".jpeg" { if (-not $isJpeg) { $mismatch = $true } }
      ".gif" { if (-not $isGif) { $mismatch = $true } }
      ".webp" { if (-not $isWebp) { $mismatch = $true } }
      default { $mismatch = $false }
    }

    if ($mismatch) {
      $badFiles += $path
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
  Write-Output "Dry run mode. No changes will be made."
  exit 0
}

foreach ($f in $badFiles) {
  $ext = [System.IO.Path]::GetExtension($f).ToLowerInvariant()
  $dir = [System.IO.Path]::GetDirectoryName($f)
  $base = [System.IO.Path]::GetFileNameWithoutExtension($f)

  # Determine actual type by magic bytes
  $fs = [System.IO.File]::OpenRead($f)
  $bytes = New-Object byte[] 8
  $fs.Read($bytes,0,8) | Out-Null
  $fs.Close()
  $sig = -join ($bytes | ForEach-Object { $_.ToString("X2") })
  $newExt = $null
  if ($sig.StartsWith("89504E47")) { $newExt = ".png" }
  elseif ($sig.StartsWith("FFD8FF")) { $newExt = ".jpg" }
  elseif ($sig.StartsWith("47494638")) { $newExt = ".gif" }
  elseif ($sig.Substring(0,8) -match "52494646") { $newExt = ".webp" }
  else { $newExt = $ext } # unknown, keep original

  $newPath = Join-Path $dir ($base + $newExt)

  if ($ConvertWithMagick -and (Get-Command magick -ErrorAction SilentlyContinue)) {
    Write-Output "Converting $f -> $newPath using ImageMagick"
    magick convert $f $newPath
    if (Test-Path $newPath) {
      Remove-Item $f -Force
      Write-Output "Replaced $f with $newPath"
      git add $newPath
      git rm --cached --ignore-unmatch $f
    } else {
      Write-Output "Conversion failed for $f"
    }
  } else {
    Write-Output "Renaming $f -> $newPath"
    Rename-Item -Path $f -NewName ($base + $newExt) -Force
    git add $newPath
  }
}

Write-Output "Committing image fixes..."
git commit -m "fix(assets): normalize image file extensions to match content (Asset Integrity fixes)" || Write-Output "No changes to commit"
