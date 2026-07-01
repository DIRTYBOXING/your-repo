#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/security-reports"
mkdir -p "${OUT_DIR}"

BRANCH_REPORT="${OUT_DIR}/gitleaks-branch-delta.json"
FULL_REPORT="${OUT_DIR}/gitleaks-full-history.json"
PLAN_FILE="${OUT_DIR}/gitleaks-remediation-plan.txt"

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks is not installed. Install it first (https://github.com/gitleaks/gitleaks)."
  exit 127
fi

cd "${ROOT_DIR}"

echo "[scan-secrets] Running branch-delta scan against origin/master..HEAD"
if gitleaks detect --source . --log-opts "origin/master..HEAD" --report-format json --report-path "${BRANCH_REPORT}"; then
  echo "[scan-secrets] Branch-delta scan clean"
else
  echo "[scan-secrets] Branch-delta leaks found"
fi

echo "[scan-secrets] Running full-history scan"
if gitleaks detect --source . --report-format json --report-path "${FULL_REPORT}"; then
  echo "[scan-secrets] Full-history scan clean"
else
  echo "[scan-secrets] Full-history leaks found"
fi

{
  echo "Gitleaks remediation checklist"
  echo ""
  echo "1) Rotate exposed credentials first (Stripe, PayPal, DB, CI tokens)."
  echo "2) Purge secrets from history via git-filter-repo or BFG after rotation."
  echo "3) Force-push cleaned branches and coordinate with contributors to re-clone."
  echo "4) Enable GitHub secret scanning + push protection on default/protected branches."
  echo "5) Keep this report set as incident evidence and close with key-rotation timestamps."
} > "${PLAN_FILE}"

echo "[scan-secrets] Reports generated:"
echo "  - ${BRANCH_REPORT}"
echo "  - ${FULL_REPORT}"
echo "  - ${PLAN_FILE}"
