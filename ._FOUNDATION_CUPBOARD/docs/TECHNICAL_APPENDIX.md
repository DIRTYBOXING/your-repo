# 📊 DFC Technical Integrity Appendix

This appendix details the staging canary audit process, payment idempotency controls, and reproducible commands used to verify the transaction stability of **Data Fight Central (DFC)**. 

---

## 1. Staging Canary Build Info

* **Staging Canary Version**: `v1.4.2-canary.7`
* **Target Release Commit**: `build-sha-8f2c3b5d91a0`
* **Reconciliation Run ID**: `REC-20260702-0941`
* **Verification Timestamp**: `2026-07-02T16:54:02+10:00`

---

## 2. Enforced Payment Idempotency Logic

To protect against duplicate payment processing (which can occur due to network failures, client retries, or Stripe webhook duplicates), DFC employs in-memory/database session validation:

1. When a webhook event is received at `/api/webhook/payment`, the payload is parsed and the Stripe `sessionId` is extracted.
2. The handler queries the `purchaseStore` to see if a purchase with that `sessionId` already exists.
3. If it exists, DFC bypasses duplicate record creation, returns the existing purchase and entitlement, and sets a `replayed: true` flag.
4. If it is a new session, a new purchase record is created and the corresponding user PPV entitlement is granted.

---

## 3. Reproducible Verification Commands

Run the following commands from the root directory of your local workspace to verify system hygiene and financial reconciliation:

### A. Secrets Leakage Scan
Scan the recent commits to ensure no active keys or environments are checked in:
```bash
./scripts/scan-secrets.sh
```
*(Requires `gitleaks` to be installed and available in the environment path).*

### B. Single-Command Integrity Suite
Starts the API server internally, simulates checkouts, replays webhook payloads to verify idempotency, and runs the reconciliation engine to assert ledger balance:
```bash
node scripts/verify_reconciliation_flow.js
```

---

## 4. Simulated Ledger Audit Trail

> [!IMPORTANT]
> **SIMULATED DATA DISCLAIMER**: The transactions listed below represent synthetic test payloads generated on the staging sandbox for validation purposes. No actual customer funds or live identities are contained in this log.

| Transaction ID | Buyer ID (Mock) | Merchant ID (Mock) | Gross Amount (USD) | Stripe Charge ID (Simulated) | Reconciliation Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `TX-82910` | `usr_buyer_772` | `mer_seller_004` | `$49.99` | `ch_sim_3M8a19` | **MATCHED** (Idempotent) |
| `TX-82911` | `usr_buyer_109` | `mer_seller_012` | `$120.00` | `ch_sim_9K1b04` | **MATCHED** (Idempotent) |
| `TX-82912` | `usr_buyer_441` | `mer_seller_004` | `$15.50` | `ch_sim_2P0c91` | **MATCHED** (Idempotent) |
| `TX-82913` | `usr_buyer_083` | `mer_seller_099` | `$85.00` | `ch_sim_7Y5d82` | **MATCHED** (Idempotent) |
| `TX-82914` | `usr_buyer_512` | `mer_seller_031` | `$200.00` | `ch_sim_4Q3e20` | **MATCHED** (Idempotent) |
