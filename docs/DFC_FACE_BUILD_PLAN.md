# DFC Face Build Plan

## Purpose
Define when and where to build the DFC face so frontend, backend, product, and ops can ship a public and operational surface that matches the DFC spine.

## What the DFC face means
The DFC face is the public and operational frontend surface backed by the current DFC spine. It includes:

- public feed and event discovery
- event detail pages and promotional cards
- auth and onboarding flows
- protected ops surfaces for promotions and monitoring

## When to build it

### Week 0
- Freeze the spine and the frontend API contract.
- Lock the minimum feed, event, auth, and ops screens.
- Confirm current Firestore collections and backend dependencies.

### Weeks 1 to 2
- Build the MVP UI against mocked or seeded data.
- Deliver home feed, event detail, auth, onboarding, and a protected ops health route.

### Weeks 3 to 4
- Integrate the live backend and Firestore state.
- Add feature flags and secret-backed configuration.
- Validate that seeded promotions appear in the current feed surface.

### Weeks 5 to 7
- Improve responsive behavior, accessibility, and empty states.
- Add smoke tests for feed loading, health checks, and protected ops screens.

### Weeks 8 to 9
- Ship to staging with real deployment wiring.
- Run manual QA, smoke checks, and rollout rehearsals.

### Weeks 10 to 12
- Promote to production.
- Monitor feed behavior, latency, and promo visibility.
- Close remaining UI and operational gaps.

## Where to build it

### Repo surfaces
- Primary Flutter app in `lib/`
- Additional isolated frontend work in `dfc_frontend/dfc_app/` when needed
- API contracts in `docs/API_CONTRACTS/`
- Operational docs in `docs/`

### Branch strategy
- Feature work: `feat/face/<slice>`
- Integration: `integrate/face-backend`
- Release candidate: `release/face-staging`

### Environment strategy
- Local: Flutter plus Firestore-backed seed data
- Staging: Firebase Hosting or staging app distribution connected to a candidate backend revision
- Production: Firebase Hosting and mobile release lanes backed by the live `dfc-backend` Cloud Run service

## MVP face slices
- Home feed using Firestore-backed feed items
- Event detail page for canonical event objects
- Auth and onboarding
- Protected ops route for promo and health visibility
- Basic media display and signed-link handling

## Delivery rules
- Keep business logic in backend services and Firestore-backed orchestration.
- Keep the face consumer-oriented: the UI should render ranked and seeded outputs, not compute ranking logic itself.
- Treat promotions as data, not hardcoded layout content.
- Validate every staging build against backend health endpoints.

## Immediate next steps
1. Use [docs/API_CONTRACTS/face.md](c:/Data-Fight-Central-safe-bridge/docs/API_CONTRACTS/face.md) as the contract for frontend integration.
2. Use [scripts/seed_promo.py](c:/Data-Fight-Central-safe-bridge/scripts/seed_promo.py) to create a seeded event and promotion path for the feed.
3. Add a protected `/ops/promotions` route after the initial feed and event screens are stable.
