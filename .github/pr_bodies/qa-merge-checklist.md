## DFC Pre-Merge QA Checklist

> Paste this entire block into your PR description. Check each box as it's verified.
> This checklist is the **single gate** for merging into `main`.

---

#### QA Summary
- **Code hygiene**
  - [ ] Run `pre-commit` hooks and fix all failures.
  - [ ] Run linters: `black --check`, `ruff`, `isort`.
  - [ ] Run static type checks: `mypy` and resolve critical errors.
  - [ ] Ensure no TODOs or debug prints remain in production code.
- **Unit and smoke tests**
  - [ ] Unit tests for seat hold, payments wrapper, webhook verification pass.
  - [ ] Integration smoke tests for checkout → webhook → ticket issuance pass.
  - [ ] Test coverage reported for critical modules meets threshold.
- **Security scan**
  - [ ] Run image vulnerability scan (Trivy) and block on critical CVEs.
  - [ ] Repo secrets scan completed and no secrets committed.
- **Local integration**
  - [ ] Bootstrap dev stack and run migrations locally.
  - [ ] Start app and confirm `/api/v1/health` returns OK.

---

#### Pre Merge PR Review
- **Functional correctness**
  - [ ] `POST /api/v1/checkout` enforces idempotency and returns `client_secret`.
  - [ ] Seat hold reserve call runs before PaymentIntent creation.
  - [ ] Outbox row is written inside the same DB transaction as order creation.
  - [ ] Webhook endpoint verifies Stripe signature and is idempotent.
  - [ ] Ticket issuer consumer issues signed QR payloads and writes tickets rows.
- **Reliability and data integrity**
  - [ ] Orders created with `idempotency_key` unique constraint.
  - [ ] Seat hold Lua script tested under concurrent reservations.
  - [ ] Outbox publisher marks published and supports retries and dead letter handling.
  - [ ] Reconciliation job skeleton exists and has tests for mismatch detection.
- **Security and compliance**
  - [ ] Stripe keys and Connect onboarding use secure redirect URIs and state tokens.
  - [ ] Promoter payouts blocked until KYC verified.
  - [ ] FitCoin endpoints disabled by default and region gated.
  - [ ] Chargeback webhook handling implemented and tested.
- **Observability**
  - [ ] Prometheus metrics instrumented for checkout, webhooks, seat hold, ticket issuance.
  - [ ] Grafana dashboards created or referenced in PR.
  - [ ] Alert rules added for webhook failures, outbox backlog, seat hold spikes.
- **Documentation**
  - [ ] Promoter Quickstart reviewed and includes widget snippet and deep link example.
  - [ ] Runbooks added for deploy failure, finance reconciliation, and ticket issuance.
  - [ ] API docs updated for new endpoints and request/response contracts.
- **Tests and CI**
  - [ ] CI pipeline runs `ci` and `test-atlas-backend` jobs successfully.
  - [ ] Smoke tests included in CI and pass in PR runs.
  - [ ] Pre-merge performance test for seat-hold under load executed.

---

#### Staging Deploy Script
Run these steps after merge and attach outputs to the PR.

1. **Trigger deploy**
   - [ ] Trigger staging deploy workflow.
2. **Apply migrations**
   - [ ] `psql $DATABASE_URL -f atlas_backend/db/migrations/002_social_buy.sql`
3. **Health check**
   - [ ] `curl -sS https://<staging-host>/api/v1/health | jq` returns status ok.
4. **Seat hold smoke**
   - [ ] `POST /api/v1/seat-hold/hold` returns hold token for available SKU.
5. **Checkout skeleton smoke**
   - [ ] `POST /api/v1/checkout` returns `order_id` and `client_secret`.
6. **Stripe webhook simulation**
   - [ ] Use Stripe CLI to forward `payment_intent.succeeded` and confirm webhook returns 200.
7. **Ticket issuance verification**
   - [ ] Confirm tickets created for order and email/wallet pass queued or sent.
8. **Gate validate smoke**
   - [ ] `POST /api/v1/tickets/validate` returns valid and logs scan audit.

---

#### SLO Table and Alerts
- **Backend availability**
  - **Target** 99.9% monthly
  - **Alert** < 99.5% → PagerDuty
- **Checkout success rate**
  - **Target** > 99% per 24h
  - **Alert** < 98% → PagerDuty
- **Webhook delivery success**
  - **Target** > 99.9% per 1h
  - **Alert** < 99% → Slack then PagerDuty
- **Ticket issuance latency p95**
  - **Target** < 1.5s
  - **Alert** > 2.5s → Slack
- **Reconciliation mismatch rate**
  - **Target** 0% (operational)
  - **Alert** > 0.1% → PagerDuty and finance runbook

Add alert rules for:
- Webhook signature failures > 1% in 15m.
- Outbox backlog > 1000 rows.
- Seat hold failure rate spike > 0.5% in 5m.
- Chargeback rate > 0.5% gross in 24h.

---

#### Security and Legal Guardrails
- **KYC gating**
  - [ ] No promoter transfers until Stripe Connect KYC verified.
  - [ ] Payouts job checks `promoters.kyc_status` before transfer.
- **FitCoin pilot**
  - [ ] FitCoin features disabled by default.
  - [ ] Require `LEGAL_SIGNOFF=true` to enable pilot in staging or prod.
  - [ ] Custodial ledger only until legal signoff for withdrawals.
- **Chargeback policy**
  - [ ] `charge.dispute.created` webhook freezes related promoter payouts.
  - [ ] Finance incident created and PagerDuty notified.
- **Secrets and rotation**
  - [ ] No secrets in repo. CI uses GitHub Secrets or KMS.
  - [ ] Document owner and rotation schedule for Stripe keys.
- **Privacy**
  - [ ] T&Cs and privacy notice updated for promoters and buyers.
  - [ ] Data deletion endpoint implemented and tested.

---

#### Post Merge Launch Criteria
- **Beta readiness**
  - [ ] Invite 10 promoters for controlled beta.
  - [ ] Offer reduced DFC fee and FitCoin bonus for early adopters.
- **Stability**
  - [ ] Staging smoke flow stable for 24 hours with no critical alerts.
  - [ ] No reconciliation mismatches after nightly job.
- **Operational readiness**
  - [ ] Runbooks validated and oncall assigned.
  - [ ] Metrics dashboards and alerts verified.
- **Legal and finance**
  - [ ] Legal signoff for FitCoin pilot if enabled.
  - [ ] Finance confirms payout reconciliation and test transfer.

---

#### Runbooks Rollback and Recovery
- **Rollback**
  - [ ] Revert merge commit if critical production issue: `git revert <merge-commit-sha>`.
  - [ ] Trigger rollback deploy and confirm health.
- **Reprocess outbox**
  - [ ] Steps to re-run outbox publisher and consumer for missed events documented.
- **Incident triage**
  - [ ] Collect logs: `kubectl -n dfc logs deploy/dfc-backend --tail=500`.
  - [ ] Freeze payouts if finance impacted and notify PagerDuty.
  - [ ] Postmortem template and owner assigned.

---

#### Acceptance and Signoff
- [ ] All checklist items above completed and attached evidence in PR.
- [ ] Code owners approved and CI green.
- [ ] Staging verification logs attached.
- [ ] Product, Legal, and Finance signoff obtained for launch.
- [ ] Tag release and schedule production deploy window.

---

Use this checklist as the single source of truth for PR readiness. When editors return, refine any wording, add project‑specific links, and attach dashboards and runbook links. If you want, I will now generate the **ready‑to‑commit file** `.github/pr_bodies/qa-merge-checklist.md` with this exact content so you can paste it into the repo.
