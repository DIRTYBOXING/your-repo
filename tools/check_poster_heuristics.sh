#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "Running PPV poster heuristics check..."

PATTERNS=(
  "ImageAssets\.isLocalAsset\(.*posterUrl"
  "posterUrl!\.startsWith\('assets/ppv/'\)"
)

TARGETS=(
  "lib/features/ppv"
)

EXCLUDES=(
  "lib/shared/models/ppv_presentation_model.dart"
  "lib/shared/services/ppv_service.dart"
)

failures=0

for pattern in "${PATTERNS[@]}"; do
  for target in "${TARGETS[@]}"; do
    matches="$(git grep -n -E "$pattern" -- "$target" || true)"
    if [[ -z "$matches" ]]; then
      continue
    fi

    filtered="$matches"
    for exclude in "${EXCLUDES[@]}"; do
      filtered="$(printf '%s\n' "$filtered" | grep -v "^${exclude}:" || true)"
    done

    if [[ -n "$filtered" ]]; then
      echo "Found forbidden poster heuristic '$pattern':"
      echo "$filtered"
      failures=$((failures + 1))
    fi
  done
done

if [[ $failures -gt 0 ]]; then
  echo ""
  echo "ERROR: PPV UI must use PPVPresentationModel instead of poster heuristics."
  exit 2
fi

echo "PPV poster heuristics check passed."
