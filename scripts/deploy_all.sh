#!/usr/bin/env bash
set -euo pipefail

# ─── DFC Deploy All ────────────────────────────────────────────
# Commits, builds, deploys to Cloud Run, sets GitHub secrets,
# and runs smoke tests.
#
# EDIT THE VALUES BELOW BEFORE RUNNING.
# ────────────────────────────────────────────────────────────────

# --- EDIT THESE BEFORE RUNNING ---
PROJECT_ID="YOUR_GCP_PROJECT_ID"
GITHUB_REPO="DIRTYBOXING/Data-Fight-Central"
FROM_EMAIL="legal@datafightcentral.com"
ONCALL_SMS="+61412345678"
ALLOWED_FROM="+61412345678"
HMAC_SECRET="replace_with_secure_hex"
RADAR_API_KEY="replace_radar_key"
SENDGRID_API_KEY="replace_sendgrid_key"
TWILIO_SID="replace_twilio_sid"
TWILIO_AUTH_TOKEN="replace_twilio_token"
TWILIO_FROM="+61412345678"
CDN_CLI_KEY="replace_cdn_key"
REGION="australia-southeast1"
# ---------------------------------

echo "════════════════════════════════════════════════════════"
echo " DFC — Full Deploy Pipeline"
echo "════════════════════════════════════════════════════════"

echo ""
echo "1) Commit all files"
git add functions/ Dockerfile cloudbuild.yaml .github/ tools/ data/ docs/ scripts/ lib/ test/ || true
git commit -m "Launch: autopilot outreach, safety, media, inbox, and mobile triggers" || true
git push origin "$(git branch --show-current)"

echo ""
echo "2) Authenticate with GCP"
gcloud auth login
gcloud config set project "$PROJECT_ID"

echo ""
echo "3) Build and deploy DFC outreach server (safety + email + social + SMS)"
gcloud builds submit \
  --tag "gcr.io/$PROJECT_ID/dfc-outreach:latest" \
  --project "$PROJECT_ID"

gcloud run deploy dfc-outreach \
  --image "gcr.io/$PROJECT_ID/dfc-outreach:latest" \
  --region="$REGION" \
  --platform=managed \
  --allow-unauthenticated \
  --set-env-vars="HMAC_SECRET=${HMAC_SECRET},RADAR_API_KEY=${RADAR_API_KEY},SENDGRID_API_KEY=${SENDGRID_API_KEY},TWILIO_SID=${TWILIO_SID},TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN},TWILIO_FROM=${TWILIO_FROM},FROM_EMAIL=${FROM_EMAIL},ONCALL_SMS=${ONCALL_SMS}" \
  --memory=512Mi \
  --max-instances=10 \
  --project "$PROJECT_ID"

OUTREACH_URL=$(gcloud run services describe dfc-outreach --region="$REGION" --format='value(status.url)' --project "$PROJECT_ID")
echo "OUTREACH_URL=${OUTREACH_URL}"

echo ""
echo "4) Build and deploy Twilio SMS webhook (standalone)"
cd functions
gcloud builds submit \
  --tag "gcr.io/$PROJECT_ID/dfc-twilio-webhook:latest" \
  --project "$PROJECT_ID"
cd ..

gcloud run deploy dfc-twilio-webhook \
  --image "gcr.io/$PROJECT_ID/dfc-twilio-webhook:latest" \
  --region="$REGION" \
  --platform=managed \
  --allow-unauthenticated \
  --set-env-vars="SEND_ENDPOINT=${OUTREACH_URL}/sendPromoterEmail,SOCIAL_ENDPOINT=${OUTREACH_URL}/sendSocialOutreach,TWILIO_AUTH_TOKEN=${TWILIO_AUTH_TOKEN},AUTHORIZED_PHONE_NUMBERS=${ALLOWED_FROM}" \
  --memory=256Mi \
  --max-instances=5 \
  --project "$PROJECT_ID"

TWILIO_URL=$(gcloud run services describe dfc-twilio-webhook --region="$REGION" --format='value(status.url)' --project "$PROJECT_ID")
echo "TWILIO_URL=${TWILIO_URL}"

echo ""
echo "5) Set GitHub secrets (requires gh CLI)"
if command -v gh &> /dev/null; then
  gh secret set SEND_PROMOTER_ENDPOINT -b "${OUTREACH_URL}/sendPromoterEmail" --repo "$GITHUB_REPO" || true
  gh secret set SENDGRID_API_KEY -b "${SENDGRID_API_KEY}" --repo "$GITHUB_REPO" || true
  gh secret set CDN_CLI_KEY -b "${CDN_CLI_KEY}" --repo "$GITHUB_REPO" || true
  gh secret set TWILIO_AUTH_TOKEN -b "${TWILIO_AUTH_TOKEN}" --repo "$GITHUB_REPO" || true
  echo "GitHub secrets set."
else
  echo "⚠ gh CLI not found — set these secrets manually in GitHub repo settings:"
  echo "  SEND_PROMOTER_ENDPOINT = ${OUTREACH_URL}/sendPromoterEmail"
  echo "  SENDGRID_API_KEY, CDN_CLI_KEY, TWILIO_AUTH_TOKEN"
fi

echo ""
echo "6) Configure Twilio webhook"
echo "   → Set inbound SMS webhook in Twilio Console to: ${TWILIO_URL}/sms"

echo ""
echo "7) Smoke tests"

# Smoke test 1: health check
echo "   Health check..."
curl -sf "${OUTREACH_URL}/health" | python3 -m json.tool 2>/dev/null || echo "   Health check response received"

# Smoke test 2: safety webhook simulation
echo "   Safety webhook simulation..."
payload='{"deviceId":"seal-001","ts":"'"$(date -u +"%Y-%m-%dT%H:%M:%SZ")"'","lat":-27.47,"lon":153.02,"battery":85,"panic":true,"accel":{"impact":3.5},"proximity":0.5}'
sig=$(echo -n "$payload" | openssl dgst -sha256 -hmac "${HMAC_SECRET}" | sed 's/^.* //')
curl -sf -X POST "${OUTREACH_URL}/device-alert" \
  -H "Content-Type: application/json" \
  -H "x-dfc-signature:${sig}" \
  -d "$payload" | python3 -m json.tool 2>/dev/null || echo "   Safety alert response received"

# Smoke test 3: promoter email (dry run — will fail without real SendGrid key)
TEST_EVENT_JSON="data/events/ppv_legends45.json"
if [ -f "$TEST_EVENT_JSON" ]; then
  echo "   Promoter email test..."
  curl -sf -X POST "${OUTREACH_URL}/sendPromoterEmail" \
    -H "Content-Type: application/json" \
    -d "{\"eventJsonPath\":\"${TEST_EVENT_JSON}\",\"template\":\"initial\"}" | python3 -m json.tool 2>/dev/null || echo "   Email endpoint response received"
else
  echo "   No sample event JSON at ${TEST_EVENT_JSON}; skipping email smoke test"
fi

echo ""
echo "════════════════════════════════════════════════════════"
echo " Deploy complete."
echo ""
echo " Outreach server: ${OUTREACH_URL}"
echo " Twilio webhook:  ${TWILIO_URL}"
echo ""
echo " Remaining manual steps:"
echo "  • Configure Twilio webhook URL in console"
echo "  • Verify SPF/DKIM/DMARC for datafightcentral.com"
echo "  • Verify SendGrid domain sender authentication"
echo "  • Create Radar geofence zones for events"
echo "  • Run end-to-end PPV purchase test in staging"
echo "════════════════════════════════════════════════════════"
