# 🌐 DFC MASTER ARCHITECTURE MAP

This is the unified Combat OS.

## 1. CLIENT LAYER (Flutter)
- **Penthouse UI:** `app/lib/features/...`
- **Control Room:** Flutter Web Admin Dashboard for platform-wide visibility.
- **State Management:** `Provider` architecture with centralized Services.
- **Responsive Engine:** Dynamic layout adaptation across Mobile, Tablet, and Web.

## 2. EDGE & DELIVERY (GCP & Firebase)
- **Firebase Hosting:** Global CDN serving the Flutter Web application.
- **Cloud Storage:** Secure vault for profile photos, event posters, and rendered MP4s.
- **Firebase App Check:** Cryptographic verification to block bots and scrapers.

## 3. DATA & INTELLIGENCE (Firestore)
- **Identity:** `users`, `fighters`, `gyms`.
- **Events:** `events`, `fights`, `ppvEvents`.
- **Commerce:** `ppvPurchases`, `revenueEvents`, `revenueSplits`.
- **AI/Health:** `telemetry`, `ai_insights`, `medical_checks`, `suspensions`.

## 4. COMPUTE & AUTOMATION (Cloud Functions - Node.js)
- **Money In:** `stripeWebhook`, `createCheckoutSession`.
- **Money Out:** `runPayoutEngine`, `processStripePayout`.
- **System Integrity:** `systemIntegrityCheck`, `autoFix`.
- **AI Integration:** `onTelemetryWrite`, `runReadinessModel`.
- **Event Triggers:** `muxWebhook`.

## 5. HEAVY COMPUTE & RENDERING (Cloud Run - Python/CUDA)
- **Octane Engine:** `main.py` running in an `nvidia/cuda` Docker container.
- **Hardware Acceleration:** NVENC FFmpeg pipeline for blistering fast video stitching.
- **API Layer:** FastAPI securely handling IAM-authenticated POST requests from Firebase.

## 6. EXTERNAL ECOSYSTEM
- **Stripe:** Checkout Sessions (In), Connect Transfers (Out).
- **Mux:** Live RTMP ingest and HLS playback delivery.
- **Google Fit / Apple HealthKit:** Raw biometric ingestion from wearables.
- **OpenAI / Gemini:** SamurAI neural responses and coaching logic.

## 7. SECURITY & GUARDRAILS
- **Firestore Rules:** Total lockdown. Clients cannot manipulate balances, purchases, or telemetry.
- **IAM Service Accounts:** Secure server-to-server communication between Firebase and Cloud Run.
- **Self-Healing Pipeline:** Cron jobs detecting and flagging orphaned or malicious data patterns.