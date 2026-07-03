# Devcontainer & VS Code Super Mode Guide

## Purpose

This README documents the devcontainer, workspace settings, and the daily developer flow so new and existing engineers can get productive quickly and reproduce the environment used for CI and PR validation.

---

## Quick start

**Clone repo and open in VS Code**

```bash
git clone <repo-url>
code <repo-folder>
```

**Accept recommended extensions** when prompted, then **Reopen in Container** (Command Palette → Remote-Containers: Reopen in Container). The container runs `.devcontainer/post-create.sh` automatically.

---

## Prerequisites

- Docker Desktop (or equivalent) installed and running
- VS Code with Remote Development extension
- `gh` CLI configured for PR creation (optional)
- Local network access to package registries (apt, pip, dart)

---

## Daily developer flow

1. **Open in container**: Reopen in Container to ensure consistent environment.
2. **Format and lint**:

```bash
dart format .
dart analyze
```

3. **Run unit tests**:

```bash
dart test
```

4. **Run feed smoke** (quick end‑to‑end check):

- From VS Code Tasks → **run_feed_smoke**
- Or:

```bash
./ci/run_feed_smoke.sh --env staging
```

5. **Commit and push**:

```bash
git add -A
git commit -m "your message"
git push origin your-branch
```

6. **Open PR** using prepared PR body files:

```bash
gh pr create --title "..." --body-file pr_body_feed_ranking.md
```

---

## Devcontainer details

- **Location**: `.devcontainer/`
- **Key files**:
  - `Dockerfile` — base image, Dart SDK, Python deps
  - `devcontainer.json` — extensions, postCreateCommand
  - `post-create.sh` — runs `dart pub get` and installs Python deps
- **Notes**: The container installs Dart and Python packages (e.g., `numpy`) for KPI scripts. If you need Flutter, uncomment and configure the Flutter install in the Dockerfile.

---

## VS Code workspace files

- **Location**: `.vscode/`
- **Key files**:
  - `settings.json` — format on save, analyzer settings
  - `tasks.json` — `run_feed_smoke`, `dart: format`, `dart: analyze`
  - `launch.json` — test and orchestrator run configs
  - `extensions.json` — recommended extensions
  - `keybindings.json` — quick keys for smoke task and terminal

---

## Running KPI scripts

**Extract a 24h sample**

```bash
python3 tools/extract_feed_sample.py --hours 24 --out /tmp/feed-sample.json
```

**Compute metrics**

```bash
python3 tools/compute_feed_metrics.py /tmp/feed-sample.json --output /tmp/feed-metrics.json
```

---

## CI integration

- **Workflow**: `.github/workflows/ci-feed-smoke.yml` runs on PRs that touch `services/`, `tools/`, `lib/core/config/`, and `test/`.
- **Artifacts**: feed smoke uploads `feed-smoke-artifacts` for logs and metrics.

---

## Troubleshooting

- **Devcontainer build fails**: check Docker resources and proxy settings; rebuild container from Command Palette.
- **Dart not found**: ensure Dockerfile installed Dart and `PATH` includes `/usr/lib/dart/bin`. Rebuild container.
- **Extensions not auto-installed**: open Extensions view and install recommended list manually.
- **Post-create errors**: open container terminal and run `.devcontainer/post-create.sh` to inspect logs.

---

## Safety and backups

- Workspace files are tracked in Git; use branches and small PRs.
- Enable VS Code **Settings Sync** to back up personal settings and extensions.

---

## Contact and next steps

- For onboarding, team contacts, or monitoring dashboards, see the main project README or ask in the team channel.
- After setup, you can open PRs for your feature branches or request additional onboarding docs.
