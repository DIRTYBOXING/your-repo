# Playwright CI Matrix Setup

## Required GitHub Actions Secrets

- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `PAYPAL_CLIENT_ID`
- `PAYPAL_CLIENT_SECRET`
- `JWT_SECRET` or `SESSION_SECRET`
- `CHECKOUT_BASE_URL`

Set these in GitHub repository settings:
`Settings -> Secrets and variables -> Actions`

## Required CI Environment Variables

- `PLAYWRIGHT_BASE_URL=http://127.0.0.1:8088`
- `PLAYWRIGHT_STATIC_WEB_BASE=http://127.0.0.1:8088`
- `PLAYWRIGHT_API_BASE=http://127.0.0.1:3000`
- `PLAYWRIGHT_POSTER_BASE=http://127.0.0.1:3000`
- `PLAYWRIGHT_EXPECT_AUTH=1`
- `PLAYWRIGHT_STRICT_SMOKE=1`
- `REQUIRE_AUTH_FOR_PPV=true`

## Browser Matrix

Use this Playwright matrix in CI:
- `chromium`
- `firefox`
- `webkit`

## CI Notes

- Strict mode (`PLAYWRIGHT_STRICT_SMOKE=1`) converts skip conditions into failures.
- This keeps the smoke lane honest and prevents false green runs.
