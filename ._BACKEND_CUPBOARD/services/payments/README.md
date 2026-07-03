# payments

Canonical owner for checkout, receipt reconciliation, and entitlement issuance.

Requirements:

- Idempotent receipt handling
- webhook signature verification
- strong audit trail for purchase state transitions

Smoke check:

- checkout complete -> entitlement issued exactly once
