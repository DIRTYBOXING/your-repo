# Terminal Integration: PowerShell + WSL + VS Code (Quick Start)

This guide documents the recommended workspace settings and profile fallbacks to ensure reliable terminal shell integration for PowerShell (Windows) and WSL (Linux) when using VS Code Insiders.

---

## 1. Workspace settings (already applied)

The workspace [.vscode/settings.json](../../.vscode/settings.json) includes these high-value settings:

- Shell integration
  - terminal.integrated.shellIntegration.enabled: true
  - terminal.integrated.suggest.enabled: true
  - terminal.integrated.stickyScroll.enabled: true
  - terminal.integrated.shellIntegration.showCommandGuide: true
  - terminal.integrated.enablePersistentSessions: true
- Profiles
  - Windows: PowerShell, PowerShell Core
  - Linux (WSL): bash, zsh
- Performance
  - files.watcherExclude excludes node_modules, .dart_tool, build, .pub-cache, .git
  - git.autofetch: true
  - git.enableSmartCommit: false

---

## 2. PowerShell one-time policy (run once)

If execution policy is undefined, run in an elevated PowerShell or your user PowerShell:

```powershell
if ((Get-ExecutionPolicy -Scope LocalMachine) -eq "Undefined" -and (Get-ExecutionPolicy -Scope CurrentUser) -eq "Undefined") {
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
}
```

## 3. PowerShell profile fallback

Open your profile:

```powershell
code-insiders $PROFILE
```

Add this snippet:

```powershell
if ($env:TERM_PROGRAM -eq "vscode") {
  . "$(code-insiders --locate-shell-integration-path pwsh)"
}
```

## 4. WSL bash fallback

Open bashrc in WSL:

```bash
code-insiders ~/.bashrc
```

Add this snippet:

```bash
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code-insiders --locate-shell-integration-path bash)"
```

## 5. Verify integration (quick checks)

1. Reload VS Code window.
2. Open a new terminal tab (PowerShell or WSL).
3. Hover the terminal tab title. Shell Integration should show Rich or Basic.
4. Run quick checks:

```bash
# WSL
pwd; git status --short; flutter --version

# PowerShell
Get-Location; git status --short; flutter --version
```

5. If suggestions feel stale, run Command Palette -> Terminal: Clear Suggest Cached Globals.

## 6. Troubleshooting

- If shell integration does not load, confirm code-insiders is on PATH and code-insiders --locate-shell-integration-path <shell> returns a path.
- If code-insiders is not available, use code instead in the snippets above.
- If terminal prompt or cwd tracking is wrong, check for conflicting ~/.bashrc or PowerShell profile lines that override prompt or cd behavior.

## 7. Optional personal profile setup

If preferred, copy the snippets into your personal PowerShell and WSL profiles so they persist across machines.

## 8. Contact

If you hit a persistent issue, attach:

- pwsh -c "Get-ExecutionPolicy -List"
- code-insiders --locate-shell-integration-path pwsh
- ssh -v output (if SSH agent issues)

Then open an issue in the repo devops board.
