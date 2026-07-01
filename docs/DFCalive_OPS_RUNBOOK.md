# DFCalive Ops Runbook — Pilot Event

## Purpose

Step-by-step runbook to execute a pilot PPV event end-to-end and capture all audit artifacts.

---

## Pre-flight (48+ hours before event)

### 1. Promoter Onboarding

- [ ] Promoter completed Stripe Connect V2 onboarding (test mode for pilot).
- [ ] Connected Account ID captured: `acct_________________`
- [ ] Signed Pilot Licence uploaded to `ops/audit/<event>/pilot_licence.pdf`
- [ ] Statutory Declaration uploaded to `ops/audit/<event>/statdec.pdf`
- [ ] Promoter contact details confirmed and stored.

### 2. Infrastructure Verification

- [ ] Ingest endpoint (RTMP/SRT) is live and tested with sample stream.
- [ ] CDN edge token validation deployed to staging.
- [ ] DRM license server reachable from test player.
- [ ] Playback token service running (`POST /mint` returns valid JWT).
- [ ] Local entitlement proxy verification lane passes before operator rehearsal starts.

```bash
# Health check playback token service
curl -s https://dfc-playback-token-<hash>.a.run.app/health
```

```powershell
# Local PPV runtime verification from the repo root
npm --prefix entitlements-service start
node scripts/ppv_runtime_readiness_check.mjs
npm --prefix entitlements-service run test:smoke
```

- [ ] `node scripts/ppv_runtime_readiness_check.mjs` returns `"ready": true`.
- [ ] `npm --prefix entitlements-service run test:smoke` passes.
- [ ] If local verification is used, `PPV_FUNCTIONS_BASE_URL` is set or Firebase emulator env vars are active so the proxy does not fall through to production by default.

### 3. Assets and Marketing

- [ ] OG image generated and uploaded to `assets/events/<event_slug>_og.jpg`
- [ ] 3 OG variants created for A/B testing.
- [ ] Social posts scheduled per 30-day calendar (see DFCalive_SOCIAL_PACK.md).
- [ ] Event page live with JSON-LD structured data.
- [ ] Event URL added to sitemap.xml.

```bash
# Verify OG image accessible
curl -I https://www.datafightcentral.com/assets/events/<event_slug>_og.jpg
# Should return 200
```

### 4. Payment Test

```bash
export STRIPE_SECRET_KEY_TEST="STRIPE_TEST_KEY_FROM_SECRET_STORE" # pragma: allowlist secret
export CONNECTED_ACCOUNT_ID="acct_REPLACE_ME"

curl -s -X POST https://api.stripe.com/v1/payment_intents \
  -u ${STRIPE_SECRET_KEY_TEST}: \
  -d amount=5000 \
  -d currency=aud \
  -d "payment_method_types[]=card" \
  -d "transfer_data[destination]=${CONNECTED_ACCOUNT_ID}" \
  -d "application_fee_amount"=2000 \
  > ops/audit/<event>/stripe_paymentintent.json
```

- [ ] `ops/audit/<event>/stripe_paymentintent.json` contains `transfer_data.destination` and `application_fee_amount`.

### 5. Signed Upload Test

```bash
# Replace SIGNED_URL and test file
curl -v -X PUT -H "Content-Type: image/jpeg" \
  --data-binary @test.jpg "SIGNED_URL_HERE" \
  > ops/audit/<event>/curl_signed_upload.txt 2>&1
```

- [ ] Upload returns 200 or 201.

---

## Event Day

### 6. Deploy Production Build

```bash
# From repo root
flutter build web --release --dart-define=WEB_DEMO_MODE=false
firebase deploy --only hosting --project datafightcentral
```

- [ ] Production URL loads correctly.
- [ ] `firebase.auth().currentUser` non-null after sign-in and page reload.

### 7. End-to-End Purchase Test (Sandbox)

1. Open production URL in Edge browser.
2. Sign in as test buyer.
3. Complete PPV checkout using Stripe test card `4242 4242 4242 4242`.
4. Confirm:
   - [ ] Webhook `payment_intent.succeeded` processed (check Cloud Functions logs).
   - [ ] `sessionId` created and stored in audit DB.
   - [ ] Playback JWT minted and returned to client.
   - [ ] Player loads manifest and plays stream.
5. Save artifacts:
   - [ ] `ops/audit/<event>/playback_token_meta.txt` (metadata only, no secrets)
   - [ ] `ops/audit/<event>/preview_signin.har` (HAR export from browser)
   - [ ] `ops/audit/<event>/edge-debug-console.txt` (console output)

### 8. Watermark Verification

```bash
# Package sample with session watermark
ffmpeg -i sample_recording.mp4 \
  -vf "drawtext=text='sess_test_pilot':fontcolor=white:fontsize=24:x=10:y=H-th-10:alpha=0.05" \
  -c:v libx264 -crf 18 -c:a copy watermarked_sample.mp4

# Run extraction tool (production: use forensic library)
# node scripts/extract_watermark.js --input watermarked_sample.mp4
```

- [ ] Extraction maps sample to `sessionId`.
- [ ] Save `ops/audit/<event>/watermark_extraction.json`.

### 9. Social Automation Trigger

```bash
# Trigger auto-clip generation
# gcloud functions call generateClip --data '{"eventId":"<event_id>","startTime":"00:12:30","duration":15}'
```

- [ ] 15s clip generated and uploaded to CDN.
- [ ] OG image updated with highlight frame.
- [ ] Social posts triggered per schedule.
- [ ] Save `ops/audit/<event>/clip_15s_meta.json`.

### 10. SEO Verification

```bash
# Ping search engines
curl "https://www.google.com/ping?sitemap=https://www.datafightcentral.com/sitemap.xml"
curl "https://www.bing.com/ping?sitemap=https://www.datafightcentral.com/sitemap.xml"
```

- [ ] Save `ops/audit/<event>/sitemap_ping.txt`.
- [ ] Event page passes Google Rich Results Test.

---

## Post-Event

### 11. Audit Bundle Export

Verify `ops/audit/<event>/` contains:

- [ ] `pilot_licence.pdf`
- [ ] `statdec.pdf`
- [ ] `stripe_paymentintent.json`
- [ ] `playback_token_meta.txt`
- [ ] `watermark_extraction.json`
- [ ] `preview_signin.har`
- [ ] `edge-debug-console.txt`
- [ ] `clip_15s_meta.json`
- [ ] `sitemap_ping.txt`

### 12. Post-Pilot Lockdown

- [ ] Rotate any temporary keys used during pilot.
- [ ] Tighten CORS to production origins only.
- [ ] Review and tighten storage rules.
- [ ] Schedule daily audit bundle backup to secure bucket.
- [ ] Debrief with promoter — capture feedback.

---

## Rollback Commands

### Revert hosting to previous commit

```bash
git revert <bad-commit-sha> --no-edit
git push origin main
firebase deploy --only hosting --project datafightcentral
```

### Delete preview channel

```bash
firebase hosting:channel:delete preview-fix --project datafightcentral
```

### Restore CORS

```bash
gsutil cors set storage.cors.json gs://datafightcentral.firebasestorage.app
```

### Restore storage rules

```bash
firebase deploy --only storage --project datafightcentral
```

---

## Monitoring During Event

### Key Metrics to Watch

| Metric                  | Target  | Alert Threshold |
| ----------------------- | ------- | --------------- |
| Playback success rate   | ≥ 99.5% | < 98%           |
| Token issuance latency  | < 200ms | > 500ms         |
| Webhook processing time | < 1s    | > 3s            |
| CDN cache hit ratio     | > 90%   | < 70%           |
| Error rate (Sentry)     | < 0.1%  | > 1%            |

### Quick Debug Commands

```bash
# Check Cloud Functions logs
firebase functions:log --project datafightcentral --only stripeWebhook

# Check Cloud Run logs for playback token service
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=dfc-playback-token" --limit 50 --project datafightcentral

# Check Firestore audit entries
# (use Firebase Console > Firestore > playback_sessions collection)
```

---

## Emergency Contacts

| Role             | Contact                             | Escalation                               |
| ---------------- | ----------------------------------- | ---------------------------------------- |
| Head of Dev      | —                                   | First responder for all technical issues |
| Promoter         | —                                   | Content and stream quality issues        |
| Stripe Support   | https://support.stripe.com          | Payment processing issues                |
| Firebase Support | https://firebase.google.com/support | Hosting, Auth, Firestore issues          |
| CDN Provider     | —                                   | Delivery and edge issues                 |
