# 🛡️ DFC Release Integrity Preflight Checklist

Use this checklist to gate all pull request merges, canary promotions, and public deployments to ensure repository hygiene, secure credential isolation, and financial compliance.

---

## 1. Code & Secrets Hygiene

- [ ] **Secrets Scan Baseline**: Run `./scripts/scan-secrets.sh` to check for leaked API tokens (Stripe, Firebase, GitHub, etc.) or credentials in git history. Verify that any new false positives are added to `.gitleaks.toml` under the `[allowlist]` block.
- [ ] **Environment Isolation**: Ensure no `.env`, `.env.local`, or private JSON service accounts are committed. All secrets must be referenced via Google Cloud Secret Manager or application default credentials (ADC).
- [ ] **Debug Endpoints Disabled**: Confirm all testing mock routes, debug ports, or sandbox bypass parameters in `server/apiStubs.js` are disabled or guarded by environment variables (`REQUIRE_AUTH_FOR_PPV=true`).

---

## 2. Code Quality & Lint Gates

- [ ] **Linter Check**: Execute `npm run lint` and verify zero errors in the Express backend and helper scripts.
- [ ] **Build Validation**: Run the Docker compose build (`npm run start:compose`) locally to confirm that dependencies resolve correctly and that the production image builds without compiler errors.
- [ ] **Flutter / Dart Diagnostics**: For client-side releases, run `flutter analyze` and verify that no critical warnings remain in the UI features or service integrations.

---

## 3. Financial & Ledger Integrity

- [ ] **Idempotency Verification**: Execute the self-contained verification suite to confirm that Stripe webhook replays do not result in duplicate purchases or double-charging:
  ```bash
  node scripts/verify_reconciliation_flow.js
  ```
- [ ] **Reconciliation Run**: Verify that the on-demand reconciliation endpoint `/api/admin/reconciliation/run` returns zero mismatches between paid purchases and wallet debits.
- [ ] **Stripe Connect Lock**: Confirm Stripe Connect KYC verification flags are active so payouts cannot be initiated to unverified or partially onboarded promoter accounts.

---

## 4. Telemetry & Compliance

- [ ] **Prometheus Exporters**: Confirm the DFC metrics endpoint is serving live counters for:
  * `dfc_wallet_reconciliation_mismatch_ratio`
  * `dfc_wallet_reconciliation_mismatch_cents`
  * `dfc_wallet_reconciliation_runs_total`
- [ ] **PII Telemetry Anonymization**: Double-check that all analytics logs and Prometheus metrics do not harvest personally identifiable information (PII) like raw billing addresses, emails, or phone numbers.
- [ ] **Legal Disclaimers**: For public demonstrations, confirm that all user interfaces and mock transaction lists display the "Demo Data - Simulated Transactions" notice.
