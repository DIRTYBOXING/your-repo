#!/usr/bin/env bash
set -euo pipefail

# Edit this list to any 3-5 workspaces for each batch.
WORKSPACES=(
  "api"
  "chuckya-radar/control-room-frontend"
  "chuckya-radar/device-verifier"
  "chuckya-radar/metrics-server"
  "chuckya-radar/radar-server"
)

BRANCH="chore/add-lockfiles-batch-1"

if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
fi

for ws in "${WORKSPACES[@]}"; do
  if [ ! -d "$ws" ]; then
    echo "Skipping $ws — directory not found"
    continue
  fi

  pushd "$ws" >/dev/null
  if [ -f package.json ] && [ ! -f package-lock.json ] && [ ! -f yarn.lock ] && [ ! -f pnpm-lock.yaml ] && [ ! -f bun.lockb ]; then
    echo "Generating package-lock.json for $ws"
    npm ci --package-lock-only --ignore-scripts
    git add package-lock.json
    git commit -m "chore: add package-lock.json for $ws (reproducible installs)"
  else
    echo "No lockfile needed or already present in $ws"
  fi
  popd >/dev/null
done

echo
echo "All lockfile commits created on branch: $BRANCH"
echo "Push and open PR with:"
echo "  git push origin $BRANCH"
echo "  gh pr create --base master --head $BRANCH --title \"chore: add lockfiles batch 1\" --body \"Adds package-lock.json for selected workspaces.\""
