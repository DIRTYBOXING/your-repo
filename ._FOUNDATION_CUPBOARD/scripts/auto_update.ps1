# Automated update script for Dart/Flutter dependencies and VS Code extensions
# Run this script manually or schedule it for automation

Write-Host "Checking for outdated packages..."
flutter pub outdated > outdated_report.txt

Write-Host "Upgrading all dependencies to latest versions..."
flutter pub upgrade --major-versions

Write-Host "Updating VS Code extensions..."
code --list-extensions | ForEach-Object { code --install-extension $_ --force }

Write-Host "Update complete! See outdated_report.txt for details."

# Optional: Add notification or commit logic here
# Example: Send email, Slack, or auto-commit changes
