#!/usr/bin/env bash
set -euo pipefail

echo "Checking actions lockfile policy for workflow changes..."

if [ -n "${GITHUB_BASE_REF:-}" ]; then
  BASE="origin/${GITHUB_BASE_REF}"
  if git rev-parse --verify "$BASE" >/dev/null 2>&1; then
    mapfile -t changed_workflows < <(git diff --name-only "$BASE...HEAD" -- '.github/workflows/**' | tr -d '\r')
  else
    mapfile -t changed_workflows < <(git diff --name-only HEAD~1..HEAD -- '.github/workflows/**' | tr -d '\r')
  fi
else
  mapfile -t changed_workflows < <(git diff --name-only HEAD~1..HEAD -- '.github/workflows/**' | tr -d '\r')
fi

if [ "${#changed_workflows[@]}" -eq 0 ]; then
  echo "No workflow changes detected; actions lockfile policy passed"
  exit 0
fi

if [ ! -f ".github/actions.lock.json" ]; then
  echo "WARNING: Workflows changed but .github/actions.lock.json does not exist yet"
  echo "Bootstrap with workflow_dispatch on .github/workflows/actions-lockfile-maintenance.yml"
  echo "Skipping strict actions lockfile enforcement until bootstrap is complete"
  exit 0
fi

if [ -n "${GITHUB_BASE_REF:-}" ]; then
  BASE="origin/${GITHUB_BASE_REF}"
  if git rev-parse --verify "$BASE" >/dev/null 2>&1; then
    changed_lockfile=$(git diff --name-only "$BASE...HEAD" -- '.github/actions.lock.json' | tr -d '\r')
  else
    changed_lockfile=$(git diff --name-only HEAD~1..HEAD -- '.github/actions.lock.json' | tr -d '\r')
  fi
else
  changed_lockfile=$(git diff --name-only HEAD~1..HEAD -- '.github/actions.lock.json' | tr -d '\r')
fi

if [ -z "$changed_lockfile" ]; then
  echo "Workflows changed but .github/actions.lock.json was not updated"
  echo "Run: npx gh-actions-lockfile generate"
  exit 1
fi

echo "Actions lockfile policy passed"
