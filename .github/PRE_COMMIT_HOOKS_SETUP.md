# Pre-Commit Hooks Setup for DIRTYBOXING/Data-Fight-Central

Pre-commit hooks prevent secrets, large files, and dangerous patterns from being committed. Runs **locally before git commit** (blocks bad commits immediately).

---

## Installation

### 1. Install pre-commit Framework (One-time)

**macOS/Linux**:
```bash
pip install pre-commit
# or
brew install pre-commit
```

**Windows (PowerShell)**:
```powershell
pip install pre-commit
# or use chocolatey
choco install pre-commit
```

### 2. Install Git Hooks in Your Repo

```bash
cd Data-Fight-Central
pre-commit install
```

This creates `.git/hooks/pre-commit` and `.git/hooks/commit-msg` (don't edit manually).

### 3. Verify Installation

```bash
ls -la .git/hooks/
# Should see: pre-commit, commit-msg, pre-push (if configured)
```

---

## Configuration: `.pre-commit-config.yaml`

Create this file in the repo root:

```yaml
# Pre-commit configuration for DIRTYBOXING/Data-Fight-Central
# Install: pip install pre-commit && pre-commit install

repos:
  # ============================================================================
  # Secret Scanning: Detect leaked credentials, API keys, tokens
  # ============================================================================
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        name: Detect secrets (API keys, passwords, tokens)
        entry: detect-secrets scan --all-files --baseline .secrets.baseline
        language: python
        types: [text]
        pass_filenames: false
        stages: [commit]

  # Alternative/Complementary: TruffleHog (more comprehensive)
  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.63.0
    hooks:
      - id: trufflehog
        name: TruffleHog (credential detection)
        entry: trufflehog git file://
        language: system
        stages: [commit]
        pass_filenames: false

  # ============================================================================
  # Large File Detection: Block > 10MB files (use Git LFS instead)
  # ============================================================================
  - repo: local
    hooks:
      - id: no-large-files
        name: No large files
        entry: scripts/hooks/no-large-files.sh
        language: script
        types: [file]
        stages: [commit]

  # ============================================================================
  # Git Attributes: Enforce LFS for binary files
  # ============================================================================
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-added-large-files
        name: Check for large files (>10MB)
        args: ['--maxkb=10240']  # 10MB limit
        stages: [commit]

  # ============================================================================
  # Commit Message Validation
  # ============================================================================
  - repo: https://github.com/compilerla/conventional-pre-commit
    rev: v2.3.0
    hooks:
      - id: conventional-pre-commit
        name: Conventional commit format
        entry: conventional-pre-commit
        language: node
        stages: [commit-msg]

  # ============================================================================
  # Dart/Flutter Linting (optional, can be slow)
  # ============================================================================
  - repo: local
    hooks:
      - id: flutter-format
        name: Flutter format
        entry: flutter format
        language: system
        types: [dart]
        stages: [commit]
        pass_filenames: true

  # ============================================================================
  # JSON/YAML Validation
  # ============================================================================
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-json
        name: Validate JSON
        types: [json]
      - id: check-yaml
        name: Validate YAML
        types: [yaml]
      - id: check-toml
        name: Validate TOML
        types: [toml]

  # ============================================================================
  # Filename & Path Checks
  # ============================================================================
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-case-conflict
        name: Check for case conflicts
      - id: check-symlinks
        name: Check for symlinks
      - id: destroyed-symlinks
        name: Check for destroyed symlinks
      - id: mixed-line-ending
        name: Fix mixed line endings
        args: ['--fix=lf']

  # ============================================================================
  # Merge Conflict Markers
  # ============================================================================
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: check-merge-conflict
        name: Check for merge conflicts

  # ============================================================================
  # .env Secrets Check (dangerous patterns)
  # ============================================================================
  - repo: local
    hooks:
      - id: no-env-secrets
        name: Block .env files with secrets
        entry: scripts/hooks/block-env-secrets.sh
        language: script
        types: [text]
        stages: [commit]

# ============================================================================
# Configuration
# ============================================================================
default_language_version:
  python: python3

# Run on all files on `pre-commit run --all-files`
files: ^(lib|server|poster-worker|promotion-worker|entitlements-service|\.github|tools)

# Exclude patterns
exclude: |
  (?x)^(
    build/|
    dist/|
    node_modules/|
    flutter_web/|
    \.next/|
    \.dart_tool/|
    \.firebase/|
    \.secrets\.baseline
  )
```

---

## Custom Hook Scripts

### Script 1: `scripts/hooks/no-large-files.sh`

Blocks files > 10MB:

```bash
#!/bin/bash
# Block large files (> 10MB)

MAXSIZE=$((10 * 1024 * 1024))  # 10MB in bytes

for file in "$@"; do
  if [ -f "$file" ]; then
    filesize=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    
    if [ "$filesize" -gt "$MAXSIZE" ]; then
      echo "❌ File too large ($file: $(numfmt --to=iec $filesize))"
      echo "   Use Git LFS for binary files:"
      echo "   git lfs track '$file' && git add .gitattributes"
      exit 1
    fi
  fi
done

exit 0
```

Save to `.git/hooks/pre-commit` or create at `scripts/hooks/no-large-files.sh`.

### Script 2: `scripts/hooks/block-env-secrets.sh`

Prevents committing `.env` files with secrets:

```bash
#!/bin/bash
# Block .env files containing secrets

for file in "$@"; do
  if [[ "$file" == *.env* ]]; then
    # Check for common secret patterns
    if grep -qE "API_KEY|SECRET|TOKEN|PASSWORD|PRIVATE_KEY|DATABASE_URL" "$file"; then
      echo "❌ Secrets detected in $file:"
      grep -E "API_KEY|SECRET|TOKEN|PASSWORD|PRIVATE_KEY|DATABASE_URL" "$file" | head -3
      echo ""
      echo "   Store secrets in:"
      echo "   - GitHub Org Secrets (.github/workflows/)"
      echo "   - .env.local (add to .gitignore)"
      echo "   - Firebase Cloud Secret Manager"
      exit 1
    fi
  fi
done

exit 0
```

### Script 3: `scripts/hooks/block-dangerous-imports.sh`

Blocks dangerous imports in critical files:

```bash
#!/bin/bash
# Block dangerous imports (eval, exec, etc. in server code)

for file in "$@"; do
  if [[ "$file" == server/* ]] && [[ "$file" == *.js ]]; then
    if grep -qE "eval\(|Function\(|exec\(|child_process\.spawn" "$file"; then
      echo "❌ Dangerous function in server code: $file"
      grep -nE "eval\(|Function\(|exec\(|child_process\.spawn" "$file"
      echo ""
      echo "   Use safer alternatives:"
      echo "   - No eval/Function: Use JSON parsing, template engines"
      echo "   - No child_process.spawn: Use libraries like execa"
      exit 1
    fi
  fi
done

exit 0
```

---

## Initialize Secrets Baseline

On first run, create a baseline to avoid flagging existing secrets (that should be rotated):

```bash
# Create baseline (one-time)
detect-secrets scan --all-files --baseline .secrets.baseline

# Add to git
git add .secrets.baseline
git commit -m "chore: add detect-secrets baseline"
```

---

## Usage

### Run Hooks on Commit
```bash
git add file.js
git commit -m "feat: add new feature"
# Hooks run automatically, block if issues found
```

### Run Hooks Manually
```bash
# Run on staged files
pre-commit run

# Run on all files
pre-commit run --all-files

# Run specific hook
pre-commit run no-large-files --all-files
```

### Bypass Hooks (Emergency Only)
```bash
# NOT recommended, only for critical hotfixes
git commit --no-verify -m "hotfix: emergency deploy"

# Log the override
echo "$(date): Bypassed pre-commit hooks for hotfix" >> SECURITY_ROTATION.md
```

---

## Integration with CI/CD

### GitHub Actions: Run Pre-Commit in CI

Create `.github/workflows/pre-commit.yml`:

```yaml
name: Pre-commit Checks

on:
  pull_request:
    branches: [master, develop]

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - uses: pre-commit/action@v3.0.0
```

This runs pre-commit on every PR to catch issues CI picks up on before merge.

---

## Troubleshooting

### "Hook failed but I need to commit anyway"
- ✅ **Fix the issue** (remove secrets, reduce file size, etc.)
- ⚠️ **Last resort**: Use `--no-verify`, but log it

### "detect-secrets reports too many false positives"
- Tune `.secrets.baseline`:
  ```bash
  detect-secrets scan --all-files --baseline .secrets.baseline
  ```
- Or configure allowlist in `.pre-commit-config.yaml`

### "Pre-commit is too slow (Flutter)"
- Set `stages: [manual]` for slow hooks in `.pre-commit-config.yaml`
- Run manually before final commit: `pre-commit run --hook-stage manual`

### "I need to update a hook version"
- Update `.pre-commit-config.yaml` and run:
  ```bash
  pre-commit autoupdate
  pre-commit run --all-files
  ```

---

## Team Onboarding

Send to team:

```markdown
## Pre-Commit Hooks Now Required

We've added pre-commit hooks to catch secrets, large files, and bad commits before they reach GitHub.

**Setup (one-time)**:
```bash
pip install pre-commit
pre-commit install
```

**What it does**:
- 🔐 Detects API keys, tokens, passwords
- 📦 Blocks files > 10MB (use Git LFS instead)
- ✅ Validates JSON/YAML/Dart
- ✨ Checks commit message format

**If a hook fails**:
1. Read the error message
2. Fix the issue (remove secret, use .env.local, etc.)
3. `git add` again and commit

**Questions?** See `.github/PRE_COMMIT_SETUP.md`
```

---

## Quick Checklist

- [ ] Install pre-commit: `pip install pre-commit`
- [ ] Create `.pre-commit-config.yaml` in repo root
- [ ] Create custom hook scripts in `scripts/hooks/`
- [ ] Run `pre-commit install` in local repo
- [ ] Test hooks: `pre-commit run --all-files`
- [ ] Commit `.pre-commit-config.yaml` and hooks
- [ ] Create `.secrets.baseline` (one-time baseline)
- [ ] Add GitHub Actions workflow for pre-commit CI checks
- [ ] Update CONTRIBUTING.md or team wiki with setup steps
- [ ] Announce to team

---

## Next Steps

✅ **Phase 1**: GitHub Billing & Budget Setup (complete)
✅ **Phase 2**: Webhook Enforcement Script (complete)
✅ **Phase 3**: Branch Protection Policy (complete)
✅ **Phase 4**: Pre-Commit Hooks (complete)

**Final Step**: Daily Runbook & Audit Log Setup (coming next)
