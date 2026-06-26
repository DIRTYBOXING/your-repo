# Security Rotation Log

Use this log when rotating real secrets in provider dashboards and CI.

| Timestamp (UTC) | Operator | System         | Secret Name                   | Environment | Action | Verification Result | Notes |
| --------------- | -------- | -------------- | ----------------------------- | ----------- | ------ | ------------------- | ----- |
| PENDING         | PENDING  | Stripe         | STRIPE_SECRET_KEY             | staging     | rotate | pending             |       |
| PENDING         | PENDING  | Stripe         | STRIPE_WEBHOOK_SECRET         | staging     | rotate | pending             |       |
| PENDING         | PENDING  | Mux            | MUX_TOKEN_SECRET              | staging     | rotate | pending             |       |
| PENDING         | PENDING  | Mux            | MUX_WEBHOOK_SECRET            | staging     | rotate | pending             |       |
| PENDING         | PENDING  | Firebase       | service-account-or-secret-set | staging     | rotate | pending             |       |
| PENDING         | PENDING  | GitHub Actions | deployment-secret-set         | staging     | rotate | pending             |       |

## Verification Checklist

- deployment completed with new secrets
- staging smoke tests passed
- webhook delivery confirmed
- playback path confirmed
- old fallback secret removed after verification
