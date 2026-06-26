#!/usr/bin/env bash
# Install the DFC pre-commit hook into .git/hooks/
set -euo pipefail
HOOK_SRC="scripts/pre-commit"
HOOK_DST=".git/hooks/pre-commit"
cp "$HOOK_SRC" "$HOOK_DST"
chmod +x "$HOOK_DST"
echo "✓ Pre-commit hook installed at $HOOK_DST"
