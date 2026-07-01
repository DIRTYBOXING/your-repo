# PR Title
Communications Suite and Blueprint Pages — promoter entry and engineering variant

## PR Description
This PR adds the canonical communications package and visual blueprint pages to the main site, wires a main-site navigation card into the promoter funnel, and adds Playwright coverage and minimal staging seed scripts for blueprint verification.

### What this PR delivers
- Canonical communications suite document
  - docs/DFC_MASTER_COMMUNICATIONS_SUITE_2026.md
- Visual blueprint page (dark grid style) with test hooks
  - web/blueprint.html
- Engineering / print variant of the blueprint page with test hooks
  - web/blueprint-engineering.html
- Main-site navigation card and asset for blueprint entry
  - assets/nav_card_blueprint.svg
  - web/index.html nav update
- Promoter funnel link to blueprint
  - web/promoters.html
- README discoverability updates linking to the communications suite
  - README.md
- Playwright visual audit coverage for blueprint pages and stricter checks for hero/canvas/CTA hooks
  - test/visual/dfc_platform_audit.spec.ts
- Minimal staging seed scripts for blueprint demo content
  - scripts/seed_blueprint_demo.js
  - scripts/seed_blueprint_demo.cjs

### Branch and commit
- Branch: feat/communications-blueprint
- Commit: 516ef406
- PR URL: https://github.com/DIRTYBOXING/Data-Fight-Central/pull/new/feat/communications-blueprint

## QA Checklist
- Visual check: blueprint.html and blueprint-engineering.html render in Chrome and Firefox with no console errors.
- Navigation: main site nav card links to /blueprint.html and opens in a new tab.
- Promoter funnel: promoters.html contains the blueprint link and loads blueprint content.
- Playwright: run npx playwright test test/visual/dfc_platform_audit.spec.ts --project=chromium --grep "Blueprint" and confirm PASS for blueprint tests.
- Data-test hooks: verify presence of data-test="blueprint-hero", data-test="blueprint-canvas", and data-test="blueprint-cta" on blueprint pages.
- Accessibility: blueprint pages include semantic headings and alt text for hero images.
- No diagnostics: run flutter analyze and repo linters; no new errors from touched files.
- Staging seed: run node scripts/seed_blueprint_demo.js against emulator/staging and confirm demo content appears on blueprint and promoter pages.

## Reviewer Notes
- This PR is communications-only. It intentionally stages only the blueprint, nav asset, README updates, Playwright checks, and seed scripts.
- The Playwright audit for blueprint pages is green.
- Existing WARNs in the full suite are unrelated and reflect runtime data gaps on non-communications routes.
- Admin or ops should run the seed script in emulator/staging before running the full visual audit.
- The engineering variant is optimized for print/export and includes the same test hooks as the public blueprint page.

## Screenshot Callouts
- Blueprint hero: verify hero image and headline render; check data-test="blueprint-hero".
- Blueprint canvas: verify the visual blueprint canvas loads; check data-test="blueprint-canvas".
- Blueprint CTA: verify CTA opens promoter funnel; check data-test="blueprint-cta".
- Engineering variant: verify print layout and data-test="engineering-blueprint-canvas".

Attach desktop and mobile screenshots for each callout in the PR.

## Merge Checklist
- [x] All blueprint Playwright tests pass locally.
- [x] Seed script validated in emulator or staging.
- [x] No diagnostics on touched files.
- [x] PR description includes QA checklist and reviewer notes.
- [ ] Screenshots attached for hero, canvas, CTA, and engineering variant.

## Staging Deploy Steps
1. Start emulators or staging environment:
   - firebase emulators:start --only hosting,firestore,functions,auth
2. Seed demo content:
   - node scripts/seed_blueprint_demo.js
3. Serve web locally or deploy to staging hosting:
   - npx serve web -l 8088
   - or firebase deploy --only hosting --project dfc-staging
4. Run Playwright blueprint tests:
   - npx playwright test test/visual/dfc_platform_audit.spec.ts --project=chromium --grep "Blueprint"

## Post-Merge Tasks
- Add the blueprint nav card to production navigation after staging checks pass.
- Publish the communications doc to the internal comms folder and share with John and promoter contacts.
- Create a short email/social pack from docs/DFC_MASTER_COMMUNICATIONS_SUITE_2026.md.
- Schedule a short demo with John to walk the blueprint and promoter funnel.

## Rollback Plan
If a critical issue appears after merge:
1. git checkout main
2. git pull origin main
3. git revert 516ef406
4. git push origin main

Then re-run Playwright and smoke tests.

## Next Priorities
1. Seed production-like events/posters/feed posts for promoter funnel live examples.
2. Finish admin sales UI and secure admin/settings numeric rate storage.
3. Deploy and validate revenue split function and entitlement flow in staging.
4. Complete promotional image generator integration and social tile templates.
5. Run full Playwright suite and eliminate remaining WARNs with seeded runtime data or stronger fallbacks.
