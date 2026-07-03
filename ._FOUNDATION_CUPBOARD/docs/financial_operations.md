# Financial Operations

## Stripe Integration

- **Payout schedules** — Promoters: weekly rolling; Fighters: per-event + 7-day hold; Creators: monthly
- **Dispute handling** — Auto-evidence submission, chargeback monitoring dashboard
- **Refund handling** — Full refund within 24h pre-event; Partial refund policy post-event
- **Chargeback monitoring** — Alert at 0.5% rate, emergency action at 0.75%
- **Multi-currency** — AUD (primary), USD, GBP, EUR, BRL, INR via Stripe automatic conversion
- **Connect accounts** — Promoter/fighter onboarding via Stripe Connect V2

## Revenue Streams

| Stream           | Model                 | Split           |
| ---------------- | --------------------- | --------------- |
| PPV events       | Per-event purchase    | Platform 20–30% |
| Subscriptions    | Monthly tiers         | 100% platform   |
| Marketplace      | Transaction fee       | 15% platform    |
| Sponsorships     | Placement + analytics | 20% platform    |
| Merchandise      | Storefront commission | 25% platform    |
| Fighter tip jars | Direct contribution   | 10% platform    |

## Accounting

- Revenue reports (daily automated, monthly reconciliation)
- Tax reports (per-country GST/VAT calculation via Stripe Tax)
- Payout logs (full audit trail in Firestore + BigQuery)
- Ledger exports (CSV/PDF for external accounting systems)
- Financial dashboard (real-time revenue, MRR, churn, LTV)

## Reconciliation

- Stripe webhook → order confirmation → Firestore update → BigQuery sync
- Daily automated reconciliation: Stripe balance vs Firestore orders
- Monthly manual audit: platform revenue vs payout totals
- Discrepancy alerts: auto-flag if variance > 0.1%

## Compliance

- PCI DSS Level 1 (via Stripe — no raw card data touches DFC servers)
- Australian GST handling (10% on domestic transactions)
- International tax compliance (Stripe Tax handles per-jurisdiction)
- Financial record retention: 7 years minimum
