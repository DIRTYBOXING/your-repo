# DFC Secrets And Access Inventory

Use this document to track where each critical DFC secret lives, who owns it, and how to recover it if a machine disappears.

Do not store actual secret values in this file.

## How To Use This File

For every critical secret or admin account, record:

1. the service name
2. the exact variable or credential name
3. where the live secret is stored
4. who can rotate it
5. what breaks if it is missing
6. the last reviewed date

## Recommended Storage Policy

Use these locations in order of preference:

1. cloud secret store for production secrets
2. password manager for operator recovery data
3. local `.env` only for development convenience

DFC-specific source-of-truth locations verified in this repo on 2026-04-14:

- local Stripe, SendGrid, and n8n development secrets: `functions/.env`
- local Google ADC path: `GOOGLE_APPLICATION_CREDENTIALS` in shell environment or local `.env`
- repo and CI secret metadata: GitHub repo `DIRTYBOXING/Data-Fight-Central`
- Firebase project in active use: `datafightcentral`
- local operator shell validation path: PowerShell on the primary dev machine

## Inventory Template

| Service           | Secret or access item                 | Storage location                                                                                                          | Owner     | Rotation path                                          | Impact if lost                      | Last reviewed |
| ----------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | --------- | ------------------------------------------------------ | ----------------------------------- | ------------- |
| GitHub            | repository admin access               | GitHub account access for `DIRTYBOXING/Data-Fight-Central` plus operator password manager and 2FA backup                  | DFC owner | GitHub security settings and repository admin controls | cannot push or recover repo         | 2026-04-14    |
| Google / Firebase | primary admin account                 | Google account used to administer Firebase project `datafightcentral` plus operator password manager and recovery methods | DFC owner | Google account security                                | cannot deploy or manage Firebase    | 2026-04-14    |
| Google Cloud      | service account JSON path             | local `GOOGLE_APPLICATION_CREDENTIALS` path with encrypted backup outside repo                                            | DFC owner | GCP IAM and service account key rotation               | functions and admin flows may fail  | 2026-04-14    |
| Stripe            | `STRIPE_SECRET_KEY`                   | `functions/.env` locally and deployment secret/config path for production                                                 | DFC owner | Stripe dashboard developers API keys                   | payments fail                       | 2026-04-14    |
| Stripe            | `STRIPE_WEBHOOK_SECRET`               | `functions/.env` locally and deployed webhook secret path for `handleStripeWebhook`                                       | DFC owner | Stripe webhook endpoint config                         | payment webhooks fail               | 2026-04-14    |
| Stripe            | `STRIPE_WEBHOOK_SECRET_CONNECT`       | `functions/.env` locally and deployed webhook secret path for `stripeConnectWebhook`                                      | DFC owner | Stripe Connect webhook endpoint config                 | onboarding and status webhooks fail | 2026-04-14    |
| Stripe            | `STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS` | `functions/.env` locally and deployed webhook secret path for `stripeSubscriptionWebhook`                                 | DFC owner | Stripe subscription webhook endpoint config            | subscriptions drift or fail         | 2026-04-14    |
| SendGrid          | `SENDGRID_API_KEY`                    | `functions/.env` locally or user shell environment, with production secret store for live delivery                        | DFC owner | SendGrid API key management                            | no email delivery                   | 2026-04-14    |
| SendGrid          | verified sender access                | SendGrid dashboard plus operator password manager for account access; sender expected from `FROM_EMAIL`                   | DFC owner | SendGrid sender identity                               | mail blocked or rejected            | 2026-04-14    |
| Domain / DNS      | registrar login                       | registrar account in operator password manager                                                                            | DFC owner | registrar dashboard                                    | public site and redirects at risk   | 2026-04-14    |
| Firebase Hosting  | deploy permission                     | Google account access to project `datafightcentral` and Firebase CLI auth on operator machine                             | DFC owner | Google IAM                                             | cannot ship web updates             | 2026-04-14    |
| GitHub Actions    | workflow secrets                      | GitHub repository settings for `DIRTYBOXING/Data-Fight-Central`                                                           | DFC owner | repo secrets UI                                        | CI and automation fail              | 2026-04-14    |

## Critical Recovery Notes

For each service, answer these questions outside the table if needed:

1. Is there a second admin account?
2. Is 2FA enabled?
3. Are backup codes stored offline?
4. Does any credential exist only on one machine today?

## DFC Hard Rule

No production-critical secret should exist only in one place and no business-critical account should rely on one device alone.

## Verified References

- `docs/ENV_VARS.md`
- `docs/runbooks/DFC_PLATFORM_SURVIVAL_CHECKLIST.md`
- `docs/runbooks/STRIPE_CONNECT_V2_RUNBOOK.md`

## Review Cadence

1. review this inventory monthly
2. review it immediately after any provider change
3. review it immediately after any machine loss or suspected compromise
