# PowerShell script to update Dart/Flutter dependencies and VS Code extensions
# Run this script regularly to keep your project up to date

Write-Host "Updating Flutter/Dart dependencies..."
flutter pub upgrade

Write-Host "Checking for outdated packages..."
flutter pub outdated

Write-Host "Updating VS Code extensions..."
code --list-extensions | ForEach-Object { code --install-extension $_ --force }

Write-Host "All dependencies and extensions updated!"
