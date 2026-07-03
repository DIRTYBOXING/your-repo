# DFC New Machine Setup

Use this guide to get DFC working on a replacement PC or another laptop.

Goal: go from blank machine to running app with verified access.

## Before You Start

You need access to:

1. the DFC GitHub repo
2. the password manager or secret store
3. the Google / Firebase account
4. Stripe if payment work is required

## Install Base Tooling

Install these first:

1. Git
2. Flutter SDK
3. Node.js and npm
4. Firebase CLI
5. PowerShell 7
6. Docker Desktop
7. WSL 2 with Ubuntu
8. VS Code with Flutter and Dart extensions

For VS Code add these remote/container extensions as part of the base setup:

1. Remote - WSL
2. Dev Containers
3. Docker

## Choose The Right Shell

Use each shell for a specific job:

1. PowerShell for Windows-side setup, WSL commands, Docker Desktop checks, and the existing Flutter web demo lane.
2. Git Bash for lightweight Git work when you prefer Bash on Windows.
3. Ubuntu on WSL 2 for Docker, backend services, Dev Containers, Node, Python, and Linux-first tooling.

Keep Flutter web plus Chrome debugging on the Windows workspace unless you explicitly move that workflow into Linux. The current DFC fastest daily lane still assumes the Windows-side Flutter toolchain.

## Clone The Repo

```powershell
git clone https://github.com/DIRTYBOXING/Data-Fight-Central.git
Set-Location "Data Fight Central"
```

## Bootstrap WSL And Docker For DFC

Verify Docker Desktop plus Ubuntu wiring from the repo root:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/wsl_dfc_bootstrap.ps1 -Action Verify
```

If Ubuntu is missing, install it first:

```powershell
wsl --install -d Ubuntu
```

Once Ubuntu exists, sync this repo into the Linux filesystem and open it in a WSL-backed VS Code window:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/wsl_dfc_bootstrap.ps1 -Action Open
```

The default Linux repo path used by the bootstrap script is:

```text
/home/<your-user>/src/data-fight-central
```

This avoids the slower Windows filesystem path when Docker and Linux tools are doing the work.

## Enable Docker Desktop WSL Integration Manually

If `scripts/wsl_dfc_bootstrap.ps1 -Action Verify` warns that Ubuntu is installed but Docker is not exposed inside the distro, use the Docker Desktop UI instead of editing Docker config files by hand.

1. open Docker Desktop
2. go to `Settings`
3. open `Resources` then `WSL Integration`
4. turn on `Enable integration with my default WSL distro` if you want this globally
5. turn on the explicit `Ubuntu` toggle in the distro list
6. click `Apply & restart`

After Docker Desktop restarts, verify the bridge from PowerShell:

```powershell
wsl -d Ubuntu bash -lc 'docker --version && docker compose version'
```

If Docker Desktop still reports that `docker` is not available inside Ubuntu:

1. run `wsl --shutdown`
2. start Docker Desktop again
3. rerun the verify command above

Do not hand-edit `%APPDATA%\Docker\settings-store.json` as part of the normal recovery path. Use the Docker Desktop UI so the integration state survives restarts cleanly.

## Fix Ubuntu Default User

If Ubuntu opens as `root`, switch it to a normal dev user before relying on WSL-backed daily workflows.

Inside Ubuntu, create a real operator account if needed:

```bash
adduser <your-user>
usermod -aG sudo <your-user>
```

Then set that user as the default in `/etc/wsl.conf` while preserving the existing boot settings:

```ini
[boot]
systemd=true

[user]
default=<your-user>
```

From PowerShell, reload WSL and confirm the default user changed:

```powershell
wsl --shutdown
wsl -d Ubuntu whoami
```

Expected result: the command returns your operator username rather than `root`.

## Open The Dev Container

From the WSL-backed VS Code window:

1. confirm the status bar shows `WSL: Ubuntu`
2. run `Dev Containers: Reopen in Container`
3. use the container session for Node, Python, Docker Compose, backend services, and operator scripts

The committed `.devcontainer` setup is intended to talk to Docker Desktop through WSL rather than running a second nested Docker daemon.

## Restore Secrets

Restore or configure these before running production-linked flows:

1. `functions/.env`
2. any required root `.env` values used locally
3. `GOOGLE_APPLICATION_CREDENTIALS` pointing to a valid service account JSON
4. any local shell environment values used for SendGrid, Stripe, or n8n

Do not copy unknown old `.env` files from an untrusted machine. Prefer fresh values from the source of truth.

## Install Dependencies

```powershell
flutter pub get
npm install
Push-Location functions
npm install
Pop-Location
```

## Verify Local Access

Run these checks in order:

```powershell
git status
flutter --version
firebase --version
flutter pub get
flutter analyze
```

For WSL plus Docker validation also run:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/wsl_dfc_bootstrap.ps1 -Action Verify
```

Validated against the current DFC workspace on 2026-04-14:

- `git status` works on `DIRTYBOXING/Data-Fight-Central`
- `flutter --version` is available on the operator machine
- `firebase --version` is available on the operator machine
- `scripts/run_with_env.ps1` exists for demo-mode launch
- the local demo URL is expected at `http://127.0.0.1:8088/`

## Verify DFC Runtime

Use the normal fastest lane first:

1. run the demo mode from VS Code or existing task setup
2. confirm the app loads
3. confirm basic navigation works

If using terminal scripts:

```powershell
pwsh -ExecutionPolicy Bypass -File scripts/run_with_env.ps1 -Action run -Mode demo
```

## Verify Firebase Access

Check these:

1. Firebase project is visible in CLI or console
2. Firestore reads work
3. Storage access works if uploads are needed
4. Functions deploy path is available if backend work is needed

## Verify Payment Access

Only if you are working on monetization or PPV:

1. confirm Stripe dashboard access
2. confirm local webhook secrets are present if needed
3. confirm the configured secret key is valid

## Recommended First-Day Recovery Validation

Run this order on a new machine:

1. `flutter pub get`
2. `flutter analyze`
3. demo web run
4. one Firebase-authenticated path if auth is active
5. one storage/media path if upload work matters today
6. one payment check if PPV or subscriptions matter today

## If Something Fails

Use this order to debug:

1. confirm repo cloned correctly
2. confirm `.env` and shell variables exist
3. confirm `GOOGLE_APPLICATION_CREDENTIALS` points to a real file
4. confirm Firebase CLI is authenticated
5. confirm package installs completed in root and `functions`
6. confirm no local path assumptions still point to the old machine

## Definition Of Done

The new machine is ready when:

1. code is synced from GitHub
2. dependencies are installed
3. analyzer runs
4. DFC opens locally
5. critical secrets are sourced from secure storage, not memory or guesswork

## Current Validation Scope

This guide was validated against the live repo structure and local operator toolchain on 2026-04-14. A clean second-machine rehearsal is still recommended after any major auth, Firebase, or Stripe change.
