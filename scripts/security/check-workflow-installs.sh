#!/usr/bin/env bash
set -euo pipefail

echo "Checking workflow install hardening..."

violations=0

if grep -RInE --include='*.yml' --include='*.yaml' 'run:\s*npm install(\s|$)' .github/workflows | grep -v -- '--ignore-scripts' >/tmp/s6505_npm_install.txt; then
  echo "ERROR: Found npm install without --ignore-scripts in workflows"
  cat /tmp/s6505_npm_install.txt
  violations=1
fi

if grep -RInE --include='*.yml' --include='*.yaml' 'run:\s*npm ci(\s|$)' .github/workflows | grep -v -- '--ignore-scripts' >/tmp/s6505_npm_ci.txt; then
  echo "ERROR: Found npm ci without --ignore-scripts in workflows"
  cat /tmp/s6505_npm_ci.txt
  violations=1
fi

if [ "$violations" -ne 0 ]; then
  echo "Workflow hardening checks failed"
  exit 1
fi

echo "Workflow install hardening checks passed"
