@echo off
setlocal
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0rocket_recover_vscode.ps1" -WorkspacePath "%~dp0.." %*
endlocal
