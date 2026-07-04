# Internal Architecture Mapping (Data Fight Central - Private)

This document maps out the core architecture of the private Data Fight Central backend. It contains proprietary flows, collection mappings, secure integrations, and execution loops designed to support a robust, live-production combat sports platform.

---

## 🗺️ High-Level System Map

```mermaid
graph TD
    %% Clients
    Flutter[Flutter client / App]
    Web[Web client / Landing Page]

    %% Webhooks & Gateways
    Stripe[Stripe Gateway] -->|Webhook: /stripeWebhook| Gen2_Stripe[stripeWebhook Gen2 Cloud Run]
    Mux[Mux Video Stream Engine] -->|Webhook: /muxWebhook| Gen2_Mux[muxWebhook Gen2 Cloud Run]

    %% Cloud Function Triggers & Queue
    Telemetry[Telemetry Collection] -->|Firestore document.write| onTelWrite[onTelemetryWrite Cloud Function]
    onTelWrite -->|Enqueue| AIQueue[(aiQueue Firestore Collection)]

    Scheduled_AI[schedule: every 15 mins] -->|Run Model| runReadiness[runReadinessModel Cloud Function]
    runReadiness -->|Dequeue & Analyze| AIQueue
    runReadiness -->|Generate Insights| Insights[(ai_insights Firestore Collection)]

    %% Split Billing & Finance
    RevEvents[(revenueEvents Collection)] -->|Firestore document.create| onRevCreate[onRevenueEventCreate Cloud Function]
    onRevCreate -->|Calculate Splits: DFC 10%, Promoter 60%, Fighter 30%| PayoutBalances[(payoutBalances Collection)]

    %% System Auditing
    Scheduled_SelfCheck[schedule: every 6 hours] -->|Audit Databases| systemCheck[systemIntegrityCheck Cloud Function]
    systemCheck -->|Generate Report| Reports[(selfCheckReports Collection)]

    %% Database
    Gen2_Stripe -->|Unlock PPVs & Write Revenue| DB[(Cloud Firestore)]
    Gen2_Mux -->|Toggle Live State & Log Sessions| DB

    classDef secure fill:#1a1a2e,stroke:#00f2fe,stroke-width:1px,color:#fff;
    classDef database fill:#0f171e,stroke:#393e46,stroke-width:1px,color:#d1d1d1;
    class Telemetry,onTelWrite,runReadiness,onRevCreate,systemCheck,Gen2_Stripe,Gen2_Mux secure;
    class AIQueue,Insights,RevEvents,PayoutBalances,Reports,DB database;
```

---

## 📂 Core Collection Mapping & Rules

| Collection Name    | Strategy              | Description / Usage                                                                                                     |
| :----------------- | :-------------------- | :---------------------------------------------------------------------------------------------------------------------- |
| `users`            | Secure Document (UID) | Contains profile schemas, onboarding flags, and role assignments (`fan`, `fighter`, `promoter`, `admin`, `superadmin`). |
| `ppvEvents`        | Shared Collection     | Tracks digital pay-per-view matchups, stream details, `streamId`, pricing keys, and live state (`isActive`).            |
| `ppvPurchases`     | Audit Collection      | Keeps cryptographically and gateway-verified purchases mapping a `userId` to an `eventId`.                              |
| `revenueEvents`    | Economic Log          | Primary financial stream populated securely via checked webhook operations.                                             |
| `payoutBalances`   | Split Ledger          | Increment ledger aggregating raw earnings in cents allocated to DFC, promoters, or fighter pools.                       |
| `aiQueue`          | Processing Queue      | Buffer collection logging fighter telemetry waitlisted for Vertex AI/Gemini evaluation slices.                          |
| `ai_insights`      | Analytical State      | Holds compiled readiness score, fatigue indices, and injury risk projections.                                           |
| `selfCheckReports` | Integrity Auditing    | Automated reporting logs asserting system health, tracking anomalies, and flagging orphaned records.                    |

---

## 🔐 Credentials & Security Governance

- **Secret Manager Integration:** All secure API keys (PayPal, Stripe, SendGrid, Mux, Gemini) are housed in GCP Secret Manager and bound as direct env injections on necessary runtimes.
- **Write Access Guards:** Critical databases and collections have active rules asserting identity tokens; administrative functions are gated on explicit security assertions.
