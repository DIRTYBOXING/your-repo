#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# DFC PPV Commerce — Canary Deploy Script
#
# Usage:
#   STAGING_URL=https://staging.datafightcentral.com \
#     ./scripts/canary_deploy.sh [gcp-project-id] [canary-percent]
#
# Arguments:
#   $1 — GCP project ID (default: dfc-staging)
#   $2 — canary traffic percent (default: 5; informational only — set at LB)
#
# Prerequisites:
#   - firebase CLI authenticated: firebase login
#   - STAGING_URL env var set
#   - node, npx, playwright installed
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

PROJECT="${1:-dfc-staging}"
CANARY_PERCENT="${2:-5}"
STAGING_URL="${STAGING_URL:-}"
SKIP_SEED="${SKIP_SEED:-false}"
SKIP_SMOKE="${SKIP_SMOKE:-false}"

if [[ -z "$STAGING_URL" ]]; then
  echo "❌  STAGING_URL is required."
  echo "    Example: STAGING_URL=https://staging.datafightcentral.com $0"
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   DFC PPV Commerce — Canary Deploy                           ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║   Project       : %-44s ║\n" "$PROJECT"
printf "║   Canary %%      : %-44s ║\n" "$CANARY_PERCENT%"
printf "║   Staging URL   : %-44s ║\n" "$STAGING_URL"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Deploy functions ────────────────────────────────────────────────
echo "▶ [1/5] Deploying Firebase functions to $PROJECT ..."
firebase deploy --only functions --project "$PROJECT"
echo "  ✓ Functions deployed"

# ── Step 2: Warmup wait ──────────────────────────────────────────────────────
echo ""
echo "▶ [2/5] Waiting 15s for function cold-start warmup ..."
sleep 15
echo "  ✓ Warmup complete"

# ── Step 3: Seed staging data ────────────────────────────────────────────────
if [[ "$SKIP_SEED" != "true" ]]; then
  echo ""
  echo "▶ [3/5] Seeding staging data ..."
  if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    echo "  ⚠  GOOGLE_APPLICATION_CREDENTIALS not set — skipping Firestore seed."
  else
    node scripts/seed_sales_config.js && echo "  ✓ Sales config seeded"
    node scripts/seed_demo_orders.js  && echo "  ✓ Demo orders seeded"
  fi
else
  echo "▶ [3/5] Seed skipped (SKIP_SEED=true)"
fi

# ── Step 4: Smoke tests ──────────────────────────────────────────────────────
if [[ "$SKIP_SMOKE" != "true" ]]; then
  echo ""
  echo "▶ [4/5] Running smoke tests against $STAGING_URL ..."

  PLAYWRIGHT_BASE_URL="$STAGING_URL" \
  PLAYWRIGHT_API_BASE="$STAGING_URL/api" \
  npx playwright test \
    test/visual/ppv_surfaces.spec.ts \
    test/visual/ppv_purchase_e2e.spec.ts \
    test/visual/admin_offers.spec.ts \
    --project=chromium \
    --project=mobile \
    --reporter=list \
    --timeout=120000 \
  && echo "  ✓ Smoke tests passed" \
  || {
    echo ""
    echo "  ✗ Smoke tests FAILED — aborting canary."
    echo "  Rollback: git checkout <previous-tag> && firebase deploy --only functions --project $PROJECT"
    exit 1
  }
else
  echo "▶ [4/5] Smoke tests skipped (SKIP_SMOKE=true)"
fi

# ── Step 5: Canary instructions ──────────────────────────────────────────────
echo ""
echo "▶ [5/5] Canary promotion — manual traffic shift required"
echo ""
echo "  All automated checks passed. Shift $CANARY_PERCENT% of production traffic"
echo "  to this deployment using your load balancer or traffic manager."
echo ""
echo "  Monitor for 24–48 hours:"
echo "    • Grafana: monitoring/grafana/ppv-commerce-dashboard.json"
echo "    • Entitlement success rate must stay > 99.5%"
echo "    • Purchase success rate must stay > 90%"
echo "    • DLQ exhausted alerts: should stay at 0"
echo ""
echo "  Rollback command (if needed):"
echo "    firebase functions:delete <functionName> --project $PROJECT"
echo "    git checkout <previous-tag> && firebase deploy --only functions --project $PROJECT"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   ✅  Canary deploy pipeline complete                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
