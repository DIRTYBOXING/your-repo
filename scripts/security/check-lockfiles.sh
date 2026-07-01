#!/usr/bin/env bash
set -euo pipefail

echo "Checking lockfile policy for changed Node manifests..."

if [ -n "${GITHUB_BASE_REF:-}" ]; then
  BASE="origin/${GITHUB_BASE_REF}"
  if git rev-parse --verify "$BASE" >/dev/null 2>&1; then
    mapfile -t changed_packages < <(git diff --name-only "$BASE...HEAD" -- '**/package.json' | tr -d '\r')
  else
    mapfile -t changed_packages < <(git diff --name-only HEAD~1..HEAD -- '**/package.json' | tr -d '\r')
  fi
else
  mapfile -t changed_packages < <(git diff --name-only HEAD~1..HEAD -- '**/package.json' | tr -d '\r')
fi

if [ "${#changed_packages[@]}" -eq 0 ]; then
  echo "No package.json changes detected; lockfile policy passed"
  exit 0
fi

violations=0
for package_json in "${changed_packages[@]}"; do
  dir=$(dirname "$package_json")
  if [ ! -f "$dir/package-lock.json" ] && [ ! -f "$dir/yarn.lock" ] && [ ! -f "$dir/pnpm-lock.yaml" ] && [ ! -f "$dir/bun.lockb" ]; then
    echo "Missing lockfile for changed manifest: $dir"
    violations=1
  fi
done

if [ "$violations" -ne 0 ]; then
  echo "Lockfile policy failed"
  exit 1
fi

echo "Lockfile policy passed"
