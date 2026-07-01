# 🚀 DFC COMBAT OS — MASTER SYSTEM MAP & PIPELINE SPEC

**VERSION:** 1.0.0 (Penthouse/Lambo-Grade)
**INFRASTRUCTURE:** Firebase + Google Cloud + Flutter
**STATUS:** LIVE & WIRED

This document is the absolute source of truth for the Data Fight Central (DFC) ecosystem. Every line, every node, every pipeline, and every connection is mapped here.

---

## 1. 🧬 IDENTITY & REGULATORY DOMAIN
**The foundation. Who is on the platform and what are they allowed to do.**

### Nodes (Firestore)
- `users`: Keyed by Firebase Auth UID. Contains `displayName`, `photoUrl`, `roles` array (fighter, coach, promoter, official, medical, sponsor, admin).
- `fighters`: Links to `users`. Contains `record`, `weightClass`, `stance`, `gymId`.
- `gyms`: Links to `users` (owner). Contains `location`, `logoUrl`.

### Connections
- **App ↔ Firebase Auth ↔ Firestore:** Login generates token. Custom claims inject `roles` into the token.
- **Firestore Security Rules:** Enforce that a `fighter` only writes to their own `fighters` doc, and `gym_owner` only writes to their `gyms` doc.

---

## 2. 🥊 COMPETITION & EVENT DOMAIN
**The engine that builds the fights and records the history.**

### Nodes (Firestore)
- `events`: The show itself. `promoterId`, `date`, `location`, `status`.
- `fights`: The matchups. Links `fighterA`, `fighterB` to `eventId`.
- `fightStats`: The live telemetry. `strikesLanded`, `powerAvg`.
- `judgesScores`: The official scorecards.
- `fouls`: Rule infractions.

### Connections
- **Promoter Dashboard ↔ Firestore:** Promoters write `events` and `fights`.
- **Officials Tablet ↔ Firestore:** Judges write `judgesScores`, refs write `fouls`.
- **Firestore ↔ Cloud Functions:** Writing `judgesScores` triggers the final `fight` result calculation.

---

## 3. 💰 COMMERCE: PPV & STOREFRONT DOMAIN
**The money machine. Netflix-style storefront and gating.**

### Nodes (Firestore)
- `ppvEvents`: The storefront display. `price`, `streamUrl`, `isActive`, `tags`.
- `ppvPurchases`: The receipt. `userId`, `eventId`, `status: paid`.
- `watchHistory`: The "Continue Watching" state. `lastPositionSeconds`.

### Connections
- **App (Buy) ↔ Stripe Webhook ↔ Cloud Function:** Stripe processes payment, triggers webhook, writes to `ppvPurchases`.
- **App (Watch) ↔ `validatePpvAccess` (Function):** User clicks "Watch". Function cross-references `ppvEvents` + `ppvPurchases` -> Returns secure `streamUrl` OR paywall.

---

## 4. 📺 BROADCAST: STREAMING & REPLAY DOMAIN
**The visual pipeline. Pro-grade delivery.**

### Nodes (Firestore)
- `streamSessions`: Observability. Tracks quality, buffering, device.

### Connections
- **Mux/Stream ↔ Webhooks ↔ Cloud Functions:** Streaming provider fires webhooks on stream start/stop/error.
- **Cloud Functions ↔ Firestore:** Updates `ppvEvents.isActive` and logs `streamSessions` for QA analysis.

---

## 5. ⚕️ MEDICAL & SAFETY DOMAIN
**The human shield. Zero compromises on fighter welfare.**

### Nodes (Firestore)
- `medicalChecks`: Vitals, concussion tests, doctor clearance.
- `injuries`: Tracked recovery timelines.
- `suspensions`: Regulatory stand-downs.

### Connections
- **Medical Tablet ↔ Firestore:** Ringside docs write `medicalChecks`.
- **Firestore ↔ `applyMedicalSuspensionOnCheck` (Function):** If `medicalChecks` shows a KO or severe injury, function auto-generates a `suspensions` document.
- **Firestore ↔ App:** Promoters and Matchmakers are physically blocked in the UI from booking a fighter with an active `suspensions` doc.

---

## 6. 💸 FINANCE & PAYOUTS DOMAIN
**Transparent, automated wealth distribution.**

### Nodes (Firestore)
- `payouts`: `basePurse`, `winBonus`, `netPayout`.
- `revenueEvents`: Ticket sales, sponsor injections.

### Connections
- **Promoter Dashboard ↔ `calculatePayoutsForEvent` (Function):** Promoter hits "Calculate". Function reads `fights` (to find winners) + `ppvPurchases` -> writes `payouts` docs for each fighter.
- **Firestore ↔ Fighter App:** Fighter gets push notification: "Purse ready. Transferring to bank."

---

## 7. 🧠 AI & TELEMETRY DOMAIN (THE SUPER-BRAIN)
**The intelligence layer. Wearables to AI to UI.**

### Nodes (Firestore & GCP)
- `telemetry`: Raw HR, HRV, Power from wearables.
- `aiInsights`: The processed intelligence (`readiness`, `fatigue`, `injuryRisk`).
- **BigQuery:** Long-term storage of all `telemetry` and `fights`.
- **Vertex AI:** Google's ML pipeline.

### Connections
- **Devices ↔ App ↔ Firestore (`telemetry`):** Constant data stream.
- **Firestore ↔ BigQuery:** Data exports automatically.
- **BigQuery ↔ Vertex AI ↔ Cloud Functions:** Vertex analyzes the data, Function writes the summary back to Firestore `aiInsights`.
- **Firestore (`aiInsights`) ↔ Neural Coach UI:** Teddy Atlas / SamurAI reads the insight and speaks it to the fighter.

---

## 8. 📱 FEED & SOCIAL DOMAIN
**The heartbeat of the community.**

### Nodes (Firestore)
- `feedPosts`: Mixed content. `type: 'clip' | 'news' | 'ppvPromo' | 'result'`.

### Connections
- **Scanners/AI ↔ Firestore:** `ContentScannerEngine` writes external news to `feedPosts`.
- **Cloud Functions ↔ Firestore:** When a fight finishes, Function auto-generates a `result` post in `feedPosts`.
- **Firestore ↔ FeedScreen:** Real-time stream listening, updating the UI instantly without pull-to-refresh.

---

## 9. ⚙️ THE CI/CD PIPELINE (VS CODE TO WORLD)
**How we deploy without breaking the machine.**

### Nodes
- **VS Code:** Development.
- **GitHub:** Version Control.
- **GitHub Actions:** CI/CD Runner.
- **Firebase:** Hosting, Functions, Rules.

### Connections (The Deploy Flow)
1. You write code in VS Code.
2. You `git push main`.
3. GitHub Actions spins up.
4. It runs Flutter tests.
5. It deploys `firestore.rules`.
6. It deploys `functions/src/index.ts`.
7. It builds `flutter build web` and deploys to Firebase Hosting (`datafightcentral.com`).

*This is the hyper-speed missile pipeline. One push, entire empire updates.*