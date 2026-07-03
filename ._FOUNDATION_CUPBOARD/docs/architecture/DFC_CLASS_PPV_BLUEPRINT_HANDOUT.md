# DFC PPV Blueprint Handout (Class Version)

This handout is the operating model for Data Fight Central as a professional combat sports platform.

## Priority Lock (Current Phase)

- Priority 1: Social media experience (feed, posting, messaging, creator visibility).
- Priority 2: Pay-per-view experience (event page, checkout, entitlement, player, replay).
- Any feature outside Social or PPV is out of scope for this phase unless explicitly approved.
- Build depth before breadth: finish core user flow quality in these two pillars before expanding.

## Core Positioning

- DFC is a platform: social + PPV + creator tools.
- Gameplay language is allowed only inside prediction features.
- Commerce surfaces must use professional product language and verified payment/entitlement flows.

## 3-Layer System

1. UI Layer

- Poster, event card, checkout CTA, secure playback entry.
- No fake promotions, no mock commerce actions in production surfaces.

2. Platform Logic Layer

- Entitlement validation, user auth, playback authorization.
- Runtime readiness must return ready:true before any release lane is considered healthy.

3. Infrastructure Layer

- GCS poster storage, CDN edge, serverless functions, CI gate, rollback lane.
- Every deploy lane must pass fail-closed checks.

## Release Flow (Fail-Closed)

1. Runtime readiness check.
2. Mux auth smoke.
3. Poster object + CDN verification.
4. Visual playback smoke.
5. Release only if all checks pass.

## Ownership Map

- Product: positioning, language policy, and approval gates.
- Platform engineering: entitlement and Mux runtime health.
- Infrastructure/DevOps: CI gates, CDN, storage verification, rollback path.
- QA: visual smoke and release evidence capture.

## Anti-Drift Guardrails

- No demo placeholders in payment or entitlement paths.
- No game-language CTAs in PPV checkout/player surfaces.
- Duplicate widgets must stay behaviorally aligned.
- Any gate that cannot confirm success must fail.

## Page-by-Page Execution Rule

Work one page at a time with one shared direction.

For each page, complete this sequence before moving to the next page:

1. Define the page purpose in one sentence.
2. Define the primary user action (what must work every time).
3. Define backend truth owner (function/service that makes it real).
4. Define smoke check for that page path.
5. Implement UI and behavior changes.
6. Verify quality and capture pass/fail evidence.
7. Freeze the page and move to the next page.

## Maturity Behavior Standard

Replace immature behavior with professional execution discipline:

- No random design changes without user-flow reason.
- No conflicting opinions left unresolved in code.
- No hidden assumptions: write decisions in docs first, then implement.
- No feature mixing: Social and PPV priorities stay separate but aligned.
- No moving goalposts mid-page: agree scope first, then deliver.
- No demo shortcuts in production-critical paths.

## Shared Decision Model (How We Stay Aligned)

- One page owner: responsible for final implementation quality.
- One technical owner: responsible for backend truth and reliability.
- One acceptance checklist: pass criteria agreed before coding.
- One source of truth: this handout plus page-specific checklist notes.

If a change does not clearly improve Social or PPV outcomes, defer it.

## Suggested Page Order (Execution Direction)

1. Social feed home
2. Create post
3. Messaging inbox/thread
4. PPV hub
5. PPV event detail
6. PPV checkout
7. PPV entitlement gate
8. PPV live/replay player

Only proceed to the next page after current page passes the acceptance checklist.

## First 48-Hour Practical Checklist

1. Enable PPV staging gate workflow and verify required secrets.
2. Run gate once on staging branch and capture artifacts.
3. Rehearse rollback using the runbook.
4. Confirm on-call escalation owners and response targets.

## Required Secrets for CI

- GCP_SA_KEY
- GCP_PROJECT_ID
- ENTITLEMENT_PROXY_URL
- PPV_FUNCTIONS_BASE_URL
- MUX_AUTH_URL
- MUX_API_TOKEN
- TEST_ENTITLEMENT_TOKEN
- SLACK_WEBHOOK_URL (optional, but recommended)

## Acceptance Criteria

- Gate fails when readiness is false.
- Gate fails when Mux auth smoke is not ok.
- Gate fails when poster or CDN checks fail.
- Gate passes only when all production checks pass.
- Post-deploy audit confirms no game/demo drift in commerce UI.

## Execution Success Criteria

- Team can explain current page scope in under 60 seconds.
- Team can name the exact backend truth path for that page.
- Team has one agreed visual and behavior standard per page.
- Team decisions are documented before implementation drift occurs.
- Social and PPV quality increase each page cycle without scope chaos.
