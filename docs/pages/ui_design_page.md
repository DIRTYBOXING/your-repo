# UI and Design Page

## Purpose
Design tokens, component library, wireframes, and E2E test mapping for product UI.

## Design Tokens
- Source file: `design/tokens.json`

## Core Components
- PrimaryButton
- HeroCard
- CheckoutBar
- EntitlementBanner

Props and analytics hooks should be documented in component README docs.

## Wireframes
- Landing Home
- Creator Landing
- Checkout
- Creator Studio
- Creator Dashboard
- Payments Ops

## E2E Tests
- `tests/e2e/subscription_flow.spec.js`
- `tests/e2e/idempotency.spec.js`

## Run Commands

```bash
cd ui
npm ci
npm run build
npx cypress run --spec tests/e2e/subscription_flow.spec.js
```

## Owners
- Design: @design
- Frontend: @frontend

## Acceptance Criteria
- Components render with token system.
- Subscription flow passes E2E tests.
