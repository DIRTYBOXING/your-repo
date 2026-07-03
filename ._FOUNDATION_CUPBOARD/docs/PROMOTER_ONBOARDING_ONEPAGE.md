# DFC Promoter Onboarding (One Page)

## Purpose
Launch a cinematic PPV event fast with AI-assisted offers and creative while keeping promoter control and payout clarity.

## 1) Create Event
- Go to PPV event creation.
- Set title, date/time, location, and base PPV price.
- Add poster and teaser media links.
- Publish event draft.

Expected result:
- Event document created in `events`.
- Sales bootstrap seeds pending AI offers in `promotions`.

## 2) Review AI Offers
- Open Admin Sales: `/#/admin/sales`.
- Go to Offer Review tab.
- Approve or reject each pending offer.

Expected result:
- Approved offer: `reviewStatus=approved`, `active=true`.
- Rejected offer: `reviewStatus=rejected`, `active=false`.

## 3) Review Creative Templates
- In Admin Sales, open Creative Review tab.
- Validate template style and sponsor fit.
- Approve selected template variants.

Expected result:
- Creative template review writes to `creative_templates` with review metadata.

## 4) Validate Commerce Flow
- Run seeded demo order path.
- Trigger purchase and webhook.
- Confirm entitlement and watch-now hooks.

Required hooks:
- `data-test=buy-cta-{id}`
- `data-test=entitlement-success-{ppvId}`
- `data-test=watch-now-{ppvId}`

## 5) Run Cross-Device QA
- Desktop, laptop, tablet, phone.
- Verify hero, sticky rail, checkout, entitlement unlock, and playback shell.
- Attach screenshots to `docs/BLUEPRINT_QA_CHECKLIST.md`.

## 6) Go Live (Staging -> Canary -> Full)
- Stage: deploy functions and run Playwright + Lighthouse.
- Canary: route small traffic slice for 24-48h.
- Full: scale after metric stability.

## Commands
```bash
firebase deploy --only functions --project dfc-staging
node scripts/seed_sales_config.js
node scripts/seed_demo_orders.js
PLAYWRIGHT_BASE_URL=https://staging.dfc.example npx playwright test test/visual/ppv_surfaces.spec.ts --project=mobile --project=tablet768 --project=desktop
PLAYWRIGHT_BASE_URL=https://staging.dfc.example PLAYWRIGHT_API_BASE=https://staging.dfc.example npx playwright test test/visual/ppv_purchase_e2e.spec.ts --project=mobile --project=tablet768 --project=desktop
```

## Success Metrics
- Entitlement success rate >= 99.5%
- Median player startup < 3s
- Playwright PPV lane green for mobile/tablet/desktop
- Lighthouse accessibility >= 90
