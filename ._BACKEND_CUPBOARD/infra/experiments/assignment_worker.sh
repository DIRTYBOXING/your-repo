#!/usr/bin/env bash
set -euo pipefail

# Assignment worker for validating deterministic assignments at scale.
# Recalculates assignments for a sample user set and asserts no drift.

EXPERIMENT_ID="${1:-}"
USER_IDS_FILE="${2:-/tmp/sample_user_ids.txt}"
DB_DSN="${DB_DSN:-postgres://localhost:5432/dfc}"

if [[ -z "$EXPERIMENT_ID" ]]; then
  echo "Usage: $0 <experimentId> [userIdsFile]"
  exit 1
fi

if [[ ! -f "$USER_IDS_FILE" ]]; then
  echo "User IDs file not found: $USER_IDS_FILE"
  exit 1
fi

echo "Validating deterministic assignment for experiment=$EXPERIMENT_ID"

PASS=0
FAIL=0

while IFS= read -r USER_ID; do
  [[ -z "$USER_ID" ]] && continue

  # Query current assignment from DB
  CURRENT="$(psql "$DB_DSN" -tAc \
    "SELECT variant FROM assignments WHERE \"experimentId\"='${EXPERIMENT_ID}' AND \"userId\"='${USER_ID}' LIMIT 1;")"

  # Load experiment configVersion and variants for deterministic recompute
  EXP_ROW="$(psql "$DB_DSN" -tA -F '|' -c \
    "SELECT COALESCE(\"configVersion\", 1), array_to_string(\"variants\", ',') FROM experiments WHERE \"experimentId\"='${EXPERIMENT_ID}' LIMIT 1;")"

  CONFIG_VERSION="$(echo "$EXP_ROW" | cut -d'|' -f1 | xargs)"
  VARIANTS_CSV="$(echo "$EXP_ROW" | cut -d'|' -f2 | xargs)"

  if [[ -z "$CURRENT" || -z "$CONFIG_VERSION" || -z "$VARIANTS_CSV" ]]; then
    echo "MISSING assignment for user=$USER_ID experiment=$EXPERIMENT_ID"
    FAIL=$((FAIL + 1))
    continue
  fi

  # Recompute assignment deterministically
  EXPECTED="$(dart ./backend/experiments/assignment_service.dart \
    --compute "$USER_ID" "$EXPERIMENT_ID" "$CONFIG_VERSION" "$VARIANTS_CSV" || true)"

  if [[ "$CURRENT" == "$EXPECTED" ]]; then
    PASS=$((PASS + 1))
  else
    echo "DRIFT user=$USER_ID expected=$EXPECTED actual=$CURRENT"
    FAIL=$((FAIL + 1))
  fi
done < "$USER_IDS_FILE"

echo "results: pass=$PASS fail=$FAIL"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
