# Payments verify-session and webhook handler (reference)

This folder contains a reference Node/Express implementation for:
- `POST /payments/webhook` — provider webhook receiver (signature verification placeholder)
- `POST /internal/payments/verify-session` — idempotent internal endpoint used to create orders, entitlements, and ledger entries

This implementation is intentionally minimal and safe:
- Uses `pg` for Postgres access.
- Idempotency: checks `webhook_events` and `orders` before writes.
- All writes for an event are performed in a single DB transaction.
- Includes test skeletons and example environment variables.

## Environment variables
- `PG_CONN` — Postgres connection string (e.g., postgres://user:pass@localhost:5432/dfc)
- `PORT` — port to run the Express server (default 8080)
- `WEBHOOK_SECRET` — provider webhook secret (used by signature verification; placeholder in this reference)

## How to run locally (example)
1. Install dependencies:
   ```
   cd backend/payments
   npm ci
   ```
2. Start server:
   ```
   PG_CONN="postgres://user:pass@localhost:5432/dfc_test" node index.js
   ```
3. Run tests:
   ```
   npm test
   ```

## Notes
- Replace the signature verification placeholder with your provider SDK (Stripe, Adyen, etc.).
- Ensure DB migrations from Patch A and rights/takedown migration are applied before running.
