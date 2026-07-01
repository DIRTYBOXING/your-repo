# 🚀 DFC PRE-FLIGHT LAUNCH CHECKLIST

Run this sequence before opening the gates to the public.

## 1. DATABASE & SECURITY 🛡️
- [ ] **Firestore Rules Deployed:** Confirm `firebase deploy --only firestore:rules` ran successfully.
- [ ] **Indexes Built:** Ensure all composite indexes (e.g., `events` sorted by `date`) are deployed via `firestore.indexes.json`.
- [ ] **App Check Enforced:** Enable Firebase App Check in the console to reject non-genuine app traffic.

## 2. COMMERCE & PAYOUTS 💸
- [ ] **Stripe Webhook Secret:** Ensure `stripe.webhook_secret` is set in Google Cloud Secret Manager / Firebase Config.
- [ ] **Stripe Live Keys:** Swap out `pk_test` for `pk_live` when ready for real transactions.
- [ ] **Stripe Connect:** Verify Promoters can successfully complete the Connect Onboarding flow in test mode.
- [ ] **Split Validation:** Run a dummy PPV purchase and verify `revenueSplits` equal exactly 100%.

## 3. CLOUD RUN & OCTANE ENGINE 🎬
- [ ] **GPU Quota:** Request a quota increase for NVIDIA L4 or T4 GPUs in your primary Google Cloud region.
- [ ] **Deploy Octane:** `gcloud run deploy dfc-octane-engine --image <image-url> --no-allow-unauthenticated --gpu=1`
- [ ] **IAM Roles:** Ensure `datafightcentral@appspot.gserviceaccount.com` has the `Cloud Run Invoker` role.

## 4. INTEGRITY & OBSERVABILITY 🧠
- [ ] **Trigger Self-Check:** Manually run the `systemIntegrityCheck` function and confirm the Control Room shows a "GREEN" status.
- [ ] **Mux Webhooks:** Confirm Mux is pointing its webhooks to your production `muxWebhook` Cloud Function URL.
- [ ] **BigQuery Export:** Confirm the Firebase Extension is actively streaming `revenueEvents` and `telemetry` to your dataset.

## 5. APP STORES & DEPLOYMENT 📦
- [ ] **Health Permissions (iOS):** Verify `NSHealthShareUsageDescription` is properly set in `Info.plist`.
- [ ] **Activity Permissions (Android):** Verify `ACTIVITY_RECOGNITION` is requested properly for Google Fit.
- [ ] **Web Deployment:** Push to `master` and ensure GitHub Actions successfully builds and deploys to Firebase Hosting.

---

### 🚨 GO / NO-GO DECISION
If any of the above items are unchecked or failing, **DO NOT LAUNCH**. 
If all systems are green, welcome to the new era of combat sports.