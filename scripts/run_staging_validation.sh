#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# DFC PPV Commerce — Staging Validation Script
#
# Usage:
#   STAGING_URL=https://staging.datafightcentral.com ./scripts/run_staging_validation.sh
#
# Steps:
#   1. Seed demo orders + sales config into Firestore (requires GOOGLE_APPLICATION_CREDENTIALS)
#   2. Run Playwright E2E suite against staging URL
#   3. Run Lighthouse CI against staging URL
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

STAGING_URL="${STAGING_URL:-}"
SKIP_SEED="${SKIP_SEED:-false}"
SKIP_PLAYWRIGHT="${SKIP_PLAYWRIGHT:-false}"
SKIP_LIGHTHOUSE="${SKIP_LIGHTHOUSE:-false}"
PLAYWRIGHT_PROJECTS="${PLAYWRIGHT_PROJECTS:-chromium,tablet768,mobile}"

# ── Validate ────────────────────────────────────────────────────────────────
if [[ -z "$STAGING_URL" ]]; then
  echo "❌  STAGING_URL is required. Set it before running this script."
  echo "    Example: STAGING_URL=https://staging.datafightcentral.com $0"
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   DFC PPV Commerce — Staging Validation Pipeline         ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║   STAGING_URL : $STAGING_URL"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Seed ─────────────────────────────────────────────────────────────
if [[ "$SKIP_SEED" != "true" ]]; then
  echo "▶ [1/3] Seeding demo data..."
  if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    echo "  ⚠  GOOGLE_APPLICATION_CREDENTIALS not set — skipping Firestore seed."
    echo "     Set it to a service account key to seed against real Firestore."
  else
    node scripts/seed_sales_config.js && echo "  ✓ Sales config seeded"
    node scripts/seed_demo_orders.js  && echo "  ✓ Demo orders seeded"
  fi
else
  echo "  ⏭  Seed skipped (SKIP_SEED=true)"
fi

# ── Step 2: Playwright E2E ───────────────────────────────────────────────────
if [[ "$SKIP_PLAYWRIGHT" != "true" ]]; then
  echo ""
  echo "▶ [2/3] Running Playwright E2E against $STAGING_URL ..."

  PROJECT_FLAGS=""
  IFS=',' read -ra PROJECTS <<< "$PLAYWRIGHT_PROJECTS"
  for p in "${PROJECTS[@]}"; do
    PROJECT_FLAGS="$PROJECT_FLAGS --project=$p"
  done

  PLAYWRIGHT_BASE_URL="$STAGING_URL" \
  PLAYWRIGHT_API_BASE="$STAGING_URL/api" \
  npx playwright test \
    test/visual/ppv_surfaces.spec.ts \
    test/visual/ppv_purchase_e2e.spec.ts \
    test/visual/admin_offers.spec.ts \
    $PROJECT_FLAGS \
    --reporter=list \
  && echo "  ✓ Playwright tests passed" \
  || { echo "  ✗ Playwright tests FAILED"; exit 1; }
else
  echo "  ⏭  Playwright skipped (SKIP_PLAYWRIGHT=true)"
fi

# ── Step 3: Lighthouse CI ────────────────────────────────────────────────────
if [[ "$SKIP_LIGHTHOUSE" != "true" ]]; then
  echo ""
  echo "▶ [3/3] Running Lighthouse CI against $STAGING_URL ..."

  if ! command -v lhci &>/dev/null; then
    echo "  Installing @lhci/cli locally..."
    npm install --no-save @lhci/cli >/dev/null 2>&1
  fi

  npx lhci collect \
    --url="$STAGING_URL" \
    --url="$STAGING_URL/ppv" \
    --url="$STAGING_URL/admin/sales" \
    --settings.preset=desktop \
  && npx lhci assert \
    --config=config/lighthouse.thresholds.json \
  && echo "  ✓ Lighthouse thresholds passed" \
  || { echo "  ✗ Lighthouse CI FAILED"; exit 1; }
else
  echo "  ⏭  Lighthouse skipped (SKIP_LIGHTHOUSE=true)"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   ✅  Staging validation complete                        ║"
echo "╚══════════════════════════════════════════════════════════╝"
