# DFC Daily Monster Loop

This is the daily operating rhythm for keeping Data Fight Central alive, healthy, and growing.

## Daily Must-Do

Run these every day before major edits, deploys, or content pushes.

1. Run `DFC: Daily Must-Do Sweep`
2. Keep `docs/runbooks/DFC_PLATFORM_SURVIVAL_CHECKLIST.md` open when checking platform risk, expiries, and dependency health
3. Read the latest health report in `reports/health/latest.md`
4. If the report is `red`, do not ship until the blocking items are understood
5. If the report is `amber`, fix the highest-risk item before adding new complexity
6. If the report is `green`, continue building and growth work

## Daily Growth Loop

Run this once per day when you want DFC to improve, not just stay stable.

1. Run `DFC: Daily Growth Sweep`
2. Review outdated Flutter packages
3. Review outdated Node packages in root and `functions`
4. Decide which upgrades are safe now and which need a dedicated branch
5. Build web demo to confirm the user-facing lane still works

## Daily Delivery Loop

Use this when you want the system to send you the status summary.

1. Run `DFC: Daily Email Sweep`
2. Enter one or more recipient emails when prompted
3. Read the delivered report and act on the priority actions section first

## Full Confidence Loop

Use this before demos, partner conversations, launch pushes, or high-visibility days.

1. Run `DFC: Full Daily Command Sweep`
2. Let smoke validation complete
3. Read `reports/health/latest.md`
4. If payment, auth, or smoke status is unhealthy, pause expansion work and repair flow first

## What The App Needs Most Often

- Clean analyzer state
- Passing Flutter tests
- A fresh health report
- Periodic smoke validation
- Dependency review before drift becomes painful
- Stripe and backend secrets staying valid
- Build confirmation for the web lane

## Decision Rules

- Green: keep building and growth shipping
- Amber: fix the biggest operational drag today
- Red: stop feature expansion and repair health first

## Weekly Upgrade Review

Do this at least once each week.

1. Run `DFC: Daily Growth Sweep`
2. Open `docs/runbooks/DFC_PLATFORM_SURVIVAL_CHECKLIST.md`
3. Open `reports/health/latest.json`
4. Review major version jumps first
5. Prioritize security-sensitive packages, payments, Firebase, auth, and runtime dependencies
6. Turn large upgrades into dedicated tasks instead of mixing them into feature work

## Daily Mission

DFC is no longer just code. It is a living platform.

Your job each day is:

- keep it healthy
- keep it observable
- keep it shippable
- keep it growing
