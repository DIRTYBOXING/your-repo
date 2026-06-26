#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# DFC — Firebase Functions Staging Deploy + Validation
#
# Usage:
#   STAGING_URL=https://staging.datafightcentral.com \
#   GCP_PROJECT=dfc-staging \
#     ./scripts/firebase_deploy_staging.sh
#
# Prerequisites:
#   - firebase CLI authenticated: firebase login
#   - gcloud authenticated: gcloud auth application-default login
#   - GOOGLE_APPLICATION_CREDENTIALS set (for seed scripts)
#   - node >= 18, npx, playwright installed (npm ci in root and functions/)
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

PROJECT="${GCP_PROJECT:-dfc-staging}"
STAGING_URL="${STAGING_URL:-}"
SKIP_SEED="${SKIP_SEED:-false}"
SKIP_SMOKE="${SKIP_SMOKE:-false}"
SKIP_LIGHTHOUSE="${SKIP_LIGHTHOUSE:-true}"

if [[ -z "$STAGING_URL" ]]; then
  echo "❌  STAGING_URL is required."
  echo "    Example: STAGING_URL=https://staging.datafightcentral.com $0"
  exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   DFC — Firebase Staging Deploy + Validation                 ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║   Project       : %-44s ║\n" "$PROJECT"
printf "║   Staging URL   : %-44s ║\n" "$STAGING_URL"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Install function deps ────────────────────────────────────────────
echo "▶ [1/6] Installing function dependencies ..."
(cd functions && npm ci --prefer-offline)
echo "  ✓ functions/node_modules ready"

# ── Step 2: Deploy functions ─────────────────────────────────────────────────
echo ""
echo "▶ [2/6] Deploying Firebase functions → $PROJECT ..."
firebase deploy --only functions --project "$PROJECT"
echo "  ✓ Functions deployed"

# ── Step 3: Deploy Firestore rules and indexes ───────────────────────────────
echo ""
echo "▶ [3/6] Deploying Firestore rules and indexes ..."
firebase deploy --only firestore --project "$PROJECT"
echo "  ✓ Firestore rules + indexes deployed"

# ── Step 4: Seed staging data ─────────────────────────────────────────────────
if [[ "$SKIP_SEED" == "true" ]]; then
  echo ""
  echo "▶ [4/6] Seed — SKIPPED (SKIP_SEED=true)"
else
  echo ""
  echo "▶ [4/6] Seeding staging data ..."
  if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
    echo "  ⚠  GOOGLE_APPLICATION_CREDENTIALS not set — skipping Firestore seed."
    echo "     Set it to a service account JSON with Firestore Editor role."
  else
    STAGING_URL="$STAGING_URL" node scripts/seed_sales_config.js && echo "  ✓ Sales config seeded"
    STAGING_URL="$STAGING_URL" node scripts/seed_demo_orders.js  && echo "  ✓ Demo orders seeded"
  fi
fi

# ── Step 5: Playwright smoke ─────────────────────────────────────────────────
if [[ "$SKIP_SMOKE" == "true" ]]; then
  echo ""
  echo "▶ [5/6] Playwright — SKIPPED (SKIP_SMOKE=true)"
else
  echo ""
  echo "▶ [5/6] Running Playwright discovery smoke ..."
  PLAYWRIGHT_BASE_URL="$STAGING_URL" npx playwright test \
    --project=chromium \
    test/visual/ppv_surfaces.spec.ts \
    --reporter=line || {
      echo "  ⚠  Playwright smoke had failures — check output above."
      echo "     Continuing (non-fatal for staging validation)."
  }
fi

# ── Step 6: Lighthouse (optional) ────────────────────────────────────────────
if [[ "$SKIP_LIGHTHOUSE" == "true" ]]; then
  echo ""
  echo "▶ [6/6] Lighthouse — SKIPPED (SKIP_LIGHTHOUSE=true)"
else
  echo ""
  echo "▶ [6/6] Running Lighthouse budget check ..."
  if command -v lighthouse &>/dev/null; then
    lighthouse "$STAGING_URL" \
      --config-path=config/lighthouse.thresholds.json \
      --output=json \
      --output-path=reports/lighthouse-staging.json \
      --chrome-flags="--headless" || {
        echo "  ⚠  Lighthouse budget check failed — check reports/lighthouse-staging.json"
    }
  else
    echo "  ⚠  lighthouse CLI not found — run: npm install -g lighthouse"
  fi
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   ✓ Staging deploy + validation complete                     ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║   Next:                                                      ║"
echo "║   1. Run a Stripe test checkout against $STAGING_URL         ║"
echo "║   2. Confirm ppv_purchases + entitlements written in         ║"
echo "║      Firestore Console for project $PROJECT                  ║"
echo "║   3. Confirm Mux playback token issued (check function logs) ║"
echo "║   4. Promote with: ./scripts/canary_deploy.sh $PROJECT 5    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
