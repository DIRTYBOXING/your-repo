# DFC PPV Cross-Device QA Checklist

## Breakpoint Rules

| Device class | Width range | Expected layout |
|---|---|---|
| Mobile | up to 480px | Single column, sticky bottom commerce rail |
| Small Tablet | 481px to 768px | 2-column poster grid, sticky rail remains |
| Tablet / Laptop | 769px to 1024px | 2 to 3-column grid, centered hero, overlays visible |
| Desktop | 1025px and above | Full-bleed hero, 3+ column grid, compact sticky CTA |

## Device QA Matrix

| Device class | Layout pass | Commerce pass | Player pass | Accessibility pass | Performance pass | Screenshot path |
|---|---|---|---|---|---|---|
| Desktop | | | | | | docs/qa-screenshots/desktop-ppv.png |
| Laptop | | | | | | docs/qa-screenshots/laptop-ppv.png |
| iPad / Tablet | | | | | | docs/qa-screenshots/tablet-ppv.png |
| iPhone / Phone | | | | | | docs/qa-screenshots/mobile-ppv.png |

## Core Checks

| Item | What to check | Selector / data-test | Pass / Fail |
|---|---|---|---|
| Sticky Buy CTA | Buy rail is visible and actionable | data-test="buy-cta-{id}" |
| Entitlement success | Entitlement unlock hook appears after purchase | data-test="entitlement-success-{ppvId}" |
| Watch now hook | Watch transition is exposed | data-test="watch-now-{ppvId}" |
| Watch root shell | Watch container is visible | data-test="ppv-watch-root-{ppvId}" |
| Offer review cards | Pending offers visible in admin review | data-test="offer-review-{id}" |
| Poster template cards | Creative template cards visible | data-test="poster-template-{key}" |
| No console errors | Browser console remains clean | Browser console |

## Screenshot Attachments

Attach one screenshot per device class for:
- PPV hero and poster grid
- Sticky commerce rail (buy/watch)
- Post-purchase entitlement state
- Player/watch shell
- Admin offer review queue

## Suggested Validation Commands

- npx playwright test test/visual/ppv_surfaces.spec.ts --project=mobile430 --project=tablet768 --project=chromium
- PLAYWRIGHT_API_BASE=https://staging.dfc.example npx playwright test test/visual/ppv_purchase_e2e.spec.ts --project=mobile430 --project=tablet768 --project=chromium
- npx playwright test test/visual/admin_offers.spec.ts --project=mobile430 --project=tablet768 --project=chromium
- npx lighthouse https://staging.dfc.example/events/demo-eternal-80 --preset=desktop --only-categories=performance,accessibility,best-practices,seo
- npx lighthouse https://staging.dfc.example/events/demo-eternal-80 --preset=mobile --only-categories=performance,accessibility,best-practices,seo

## Acceptance Thresholds

| Metric | Threshold |
|---|---|
| Entitlement success rate | >= 99.5% |
| Median player startup | < 3s |
| Lighthouse accessibility | >= 90 |
| Lighthouse performance | >= 80 |
