# Backend Overview (Data Fight Central - Private)

This document provides a technical walkthrough of the core private backend services, secure entry points, and deployment setups for Data Fight Central.

---

## ⚡ Cloud Functions & Engine Specs

All entry points reside in `functions/src/index.ts` and compile cleanly to standard Node ESM execution bundles under `functions/lib/index.js`.

### 💰 Webhook Engines

1. **`stripeWebhook` (HTTP Gen2 / us-central1)**
   - **Endpoint URL:** `https://stripewebhook-drxosqpmwq-uc.a.run.app`
   - **Responsibility:** Captures completed Stripe checkout events, decodes user and event metadata, writes a purchase state to `ppvPurchases` to unlock fan streaming privileges immediately, and posts a secure entry to `revenueEvents`.
   - **Configuration:** Running on 256MiB Gen2 memory limit, utilizing direct environment parameters pointing to Secret Manager keys rather than legacy firebase configs.

2. **`muxWebhook` (HTTP Gen2 / australia-southeast1)**
   - **Endpoint URL:** `https://muxwebhook-drxosqpmwq-ts.a.run.app` (failed state, redeploy pending)
   - **Responsibility:** Listens for streaming status changes directly from Mux (e.g., `video.live_stream.active`). Automatically updates Firestore PPV status flags so the user-facing app immediately updates video players.
   - **Location:** Deployed inside `australia-southeast1` to colocate with local Firestore database transactions for ultra-low latency updates.

---

## 💸 Robotic Payout Split Engine

The Financial Division engine (`onRevenueEventCreate`) runs automated logic immediately upon write detections inside the `revenueEvents` transactional table.

- **Split Configuration Formula:**
  $$\text{Payout Cents} = \text{Revenue Amount} \times 100$$
  $$\text{DFC Platform (10\%)} = \lfloor\text{Payout Cents} \times 0.1\rfloor$$
  $$\text{Promoter (60\%)} = \lfloor\text{Payout Cents} \times 0.6\rfloor$$
  $$\text{Fighter Pool (30\%)} = \text{Payout Cents} - \text{DFC Platform} - \text{Promoter}$$
- **Transactional Guarantee:** Performed via batch transactions (`admin.firestore().batch()`) ensuring that DFC platform, Gym Promoters, and competing Fight card profiles receive incremental allocations successfully or fail as a single unit, preventing split drift.

---

## 🧠 Telemetry Queue & Vertex AI Engine

Hardware sensor packets are normalized to allow continuous monitoring of fighter health while mitigating cold starts:

1. **Write Hook (`onTelemetryWrite`):** Captures incoming sensor entries from Wearable/IoT streams, strips identifying records, and pushes fighter identification parameters to `aiQueue`.
2. **Scheduled Model Processing (`runReadinessModel`):**
   - Scheduled cron: `every 15 minutes`
   - Safely loads batches of 10 queue documents.
   - Feeds window intervals to Vertex AI / Gemini API to formulate advanced Readiness, Fatigue, and Injury indicators.
   - Updates `ai_insights` and clears the queue item.

---

## ⚙️ Development Command Glossary

From project root:

```bash
# Clean transpilation
npm --prefix ./functions run build

# Local Emulator suite launch (for off-grid design testing)
firebase emulators:start

# Dry-run validation of backend specifications
firebase deploy --only functions --dry-run
```
