#!/usr/bin/env bash
set -euo pipefail

# One-click weekly hardening sweep for Social + PPV ops.
# Returns PASS/FAIL summary and non-zero exit code on failure.

EVENT_ID="${1:-${EVENT_ID:-champions-collide-2026}}"
STAGING_BASE="${STAGING_BASE:-https://staging.dfc.example.com}"
GCS_BUCKET="${GCS_BUCKET:-dfc-media-bucket}"
CDN_EDGE_HOST="${CDN_EDGE_HOST:-edge-us.cdn.dfc.example.com}"
ENTITLEMENT_HEALTH_URL="${ENTITLEMENT_HEALTH_URL:-}"
REPO_SLUG="${REPO_SLUG:-DIRTYBOXING/Data-Fight-Central}"
TRIGGER_GATE="${TRIGGER_GATE:-1}"
WATCH_GATE="${WATCH_GATE:-1}"

FAILURES=0

log() {
  printf '\n[%s] %s\n' "$(date '+%H:%M:%S')" "$1"
}

fail_step() {
  echo "FAIL: $1" >&2
  FAILURES=$((FAILURES + 1))
}

pass_step() {
  echo "PASS: $1"
}

run_cmd() {
  local name="$1"
  shift
  if "$@"; then
    pass_step "$name"
  else
    fail_step "$name"
  fi
}

log "1) Run/verify PPV staging gate"
if [[ "$TRIGGER_GATE" == "1" ]]; then
  if command -v gh >/dev/null 2>&1; then
    if gh workflow run ppv-staging-gate.yml --repo "$REPO_SLUG" -f EVENT_ID="$EVENT_ID" -f STAGING_BASE="$STAGING_BASE"; then
      pass_step "Trigger PPV staging gate"
      if [[ "$WATCH_GATE" == "1" ]]; then
        run_id="$(gh run list --repo "$REPO_SLUG" --workflow "PPV Staging Gate" --limit 1 --json databaseId --jq '.[0].databaseId')"
        if [[ -n "$run_id" && "$run_id" != "null" ]]; then
          echo "Run URL: https://github.com/${REPO_SLUG}/actions/runs/${run_id}"
          if ! gh run watch "$run_id" --repo "$REPO_SLUG" --exit-status; then
            fail_step "PPV staging gate run"
          else
            pass_step "PPV staging gate run"
          fi
        else
          fail_step "Resolve latest gate run id"
        fi
      fi
    else
      fail_step "Trigger PPV staging gate"
    fi
  else
    fail_step "gh CLI not installed for gate trigger"
  fi
else
  echo "SKIP: gate trigger disabled (TRIGGER_GATE=0)"
fi

log "2) Poster quick check"
run_cmd "Poster + CDN checks" bash ops/check_posters.sh "$GCS_BUCKET" "$EVENT_ID" "$CDN_EDGE_HOST"

log "3) Entitlement health"
if [[ -z "$ENTITLEMENT_HEALTH_URL" ]]; then
  fail_step "ENTITLEMENT_HEALTH_URL not set"
else
  health_payload="$(curl -fsS "$ENTITLEMENT_HEALTH_URL" || true)"
  echo "$health_payload"
  if echo "$health_payload" | grep -Eq '"ready"[[:space:]]*:[[:space:]]*true'; then
    pass_step "Entitlement health ready=true"
  else
    fail_step "Entitlement health ready=true"
  fi
fi

log "4) Player smoke"
run_cmd "Playwright player/poster smoke" npx playwright test tests/playwright/player-poster.spec.ts --project=chromium --reporter=line

log "5) CDN edge hit ratio (manual dashboard check)"
if [[ -n "${CDN_EDGE_HIT_RATIO:-}" ]]; then
  ratio="${CDN_EDGE_HIT_RATIO}"
  if awk "BEGIN {exit !($ratio >= 90)}"; then
    pass_step "CDN edge hit ratio >= 90%"
  else
    fail_step "CDN edge hit ratio >= 90%"
  fi
else
  echo "MANUAL: verify edge hit ratio > 90% in CDN dashboard"
fi

log "6) Runbook and on-call channel check"
if [[ -f "docs/runbooks/DFC_PPV_ONE_CLICK_ROLLBACK.md" ]]; then
  pass_step "Rollback runbook present"
else
  fail_step "Rollback runbook present"
fi

echo
if [[ "$FAILURES" -eq 0 ]]; then
  echo "WEEKLY HARDENING SWEEP: PASS"
  exit 0
fi

echo "WEEKLY HARDENING SWEEP: FAIL ($FAILURES checks failed)" >&2
exit 1
