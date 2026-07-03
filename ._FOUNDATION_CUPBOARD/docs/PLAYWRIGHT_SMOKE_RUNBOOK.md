# Playwright Smoke Runbook

This runbook executes the smoke suite for auth, wallet, AI modal, Shakura, and poster checks.

## 1) Start required services

- Flutter/static surface (for promoter and template pages)
- API service (for wallet/auth checks)
- Optional poster service (for poster health checks)

## 2) Set environment variables

### PowerShell

```powershell
$env:PLAYWRIGHT_STATIC_WEB_BASE="http://127.0.0.1:8088"
$env:PLAYWRIGHT_BASE_URL="http://127.0.0.1:8088"
$env:PLAYWRIGHT_API_BASE="http://127.0.0.1:3000"
$env:PLAYWRIGHT_POSTER_BASE="http://127.0.0.1:8787"
$env:PLAYWRIGHT_EXPECT_AUTH="1"
$env:PLAYWRIGHT_PPV_USER_ID="smoke_user"
$env:PLAYWRIGHT_PPV_EVENT_ID="999"
```

## 3) Run smoke suite

```bash
npx playwright test test/visual/wallet_ai_shakura_smoke.spec.ts --project=chromium --grep "@smoke"
```

Run across all configured projects (desktop + mobile + cross-browser):

```bash
npx playwright test test/visual/wallet_ai_shakura_smoke.spec.ts --grep "@smoke"
```

Run strict mode (fails instead of skip when a dependency is missing):

```powershell
$env:PLAYWRIGHT_STRICT_SMOKE="1"
npx playwright test test/visual/wallet_ai_shakura_smoke.spec.ts --project=chromium --grep "@smoke"
```

## 4) Interpret skips

Tests are designed to skip when dependencies are not available:

- Static UI tests skip if `PLAYWRIGHT_STATIC_WEB_BASE` does not serve pages like `/promoters.html`.
- API tests skip if `PLAYWRIGHT_API_BASE` is missing.
- Poster checks skip if `PLAYWRIGHT_POSTER_BASE` is missing.

## 5) Minimum strict lane for CI

For CI, fail on unexpected skips by ensuring all endpoints are present and environment variables are set.
Set `PLAYWRIGHT_STRICT_SMOKE=1` in CI to enforce this.
