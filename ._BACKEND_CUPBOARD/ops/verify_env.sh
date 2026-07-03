#!/usr/bin/env bash
set -euo pipefail

status=0

ok() {
  echo "OK: $1"
}

warn() {
  echo "WARN: $1"
}

fail() {
  echo "FAIL: $1"
  status=1
}

check_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "${cmd} is installed"
    return 0
  fi

  fail "${cmd} is missing"
  return 1
}

echo "== DFC environment preflight =="

check_cmd docker || true
check_cmd gh || true
check_cmd gcloud || true

if command -v docker >/dev/null 2>&1; then
  if docker version >/dev/null 2>&1; then
    ok "Docker daemon reachable"
  else
    fail "Docker daemon not reachable (check Docker Desktop + WSL integration)"
  fi
fi

if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    ok "GitHub CLI authenticated"
  else
    fail "GitHub CLI not authenticated"
    warn "Run: gh auth login"
  fi
fi

if command -v gcloud >/dev/null 2>&1; then
  project="$(gcloud config get-value project 2>/dev/null || true)"
  active_account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null || true)"

  if [[ -n "$active_account" ]]; then
    ok "gcloud active account: ${active_account}"
  else
    fail "gcloud has no active account"
    warn "Run: gcloud auth login"
  fi

  if [[ -z "$project" || "$project" == "(unset)" ]]; then
    fail "gcloud project is unset"
    warn "Run: gcloud config set project YOUR_GCP_PROJECT_ID"
  else
    ok "gcloud project: ${project}"
  fi
fi

echo
if [[ "$status" -ne 0 ]]; then
  echo "Environment preflight: FAILED"
  exit 1
fi

echo "Environment preflight: PASSED"
