## Summary
Implements one-click social buy flow so fans can purchase tickets or PPV directly from a promoter/fighter profile or DFC storefront.

Key features
- Concrete `POST /api/v1/checkout` with idempotency, seat-hold, Stripe PaymentIntent, outbox write
- `POST /api/v1/webhooks/payments` with Stripe signature verification and outbox publishing
- `services/outbox.py` — polling publisher that processes outbox table events
- `services/ticket_issuer/` — consumer that dispatches `payment.succeeded` and issues signed QR tickets
- `web/deeplink/dfc-deeplink.html` — mobile deep link handler (native app fallback to web)
- `docs/promoter_quickstart.md` — one-page promoter onboarding with ref codes, widget, and payout steps
- Web widget already at `web/widget/widget.js`

## Files added/modified
- `atlas_backend/routers/checkout.py`
- `atlas_backend/routers/webhooks.py`
- `atlas_backend/services/outbox.py`
- `atlas_backend/services/ticket_issuer/` (consumer, ticket_issuer)
- `web/deeplink/dfc-deeplink.html`
- `docs/promoter_quickstart.md`
- `atlas_backend/main.py` (wired new routers)
- `experiments/widget_ab_plan.md` (A/B experiment plan)
- `docs/promoter_social_kit.md` (promoter social kit)
- `scripts/staging_smoke.sh` (automated smoke verification)
- `prometheus/rules/dfc_alerts.yml` (alert rules)
- `grafana/dashboards/dfc_oneclick_dashboard.json` (Grafana dashboard)

## Checklist
- [ ] CI lint and unit tests pass
- [ ] test-atlas-backend job runs migrations, Postgres + Redis, smoke tests
- [ ] Staging deploy successful and /api/v1/health returns ok
- [ ] `POST /api/v1/checkout` returns order_id + client_secret
- [ ] Stripe CLI test: payment_intent.succeeded delivered and outbox row created
- [ ] Ticket issuance: tickets table populated after payment; order = paid
- [ ] Promoter Quickstart reviewed and published
- [ ] Staging smoke script passes all 8 steps

## Reviewers
- @DIRTYBOXING/backend
- @DIRTYBOXING/platform

## Labels
- area:backend
- area:platform
- type:feature
- priority:critical

## Notes for reviewers
This is the revenue-critical path. Review Stripe PaymentIntent creation, idempotency, webhook signature verification, and outbox reliability. Ensure no card data is logged.
