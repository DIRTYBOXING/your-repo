param(
  [switch]$Persist
)

# Set locale env vars for current session
$env:LC_ALL = "de"
$env:LC_MESSAGES = "en-us"
$env:LANG = "zh-cn"
$env:LANGUAGE = "fr"
Write-Host "Locale environment variables set for current session."

if ($Persist) {
  Write-Host "Persisting to user environment variables (setx). You may need to restart your shell."
  setx LC_ALL "de" | Out-Null
  setx LC_MESSAGES "en-us" | Out-Null
  setx LANG "zh-cn" | Out-Null
  setx LANGUAGE "fr" | Out-Null
  Write-Host "Persisted locale variables to user environment."
}
