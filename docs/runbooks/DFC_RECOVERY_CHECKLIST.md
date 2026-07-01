# DFC Recovery Checklist

Use this if your main PC is lost, stolen, dead, or unavailable.

Goal: regain control of Data Fight Central fast, verify access, and get a clean replacement machine operational without guessing.

## Golden Rule

If the old machine is missing or potentially compromised, treat all locally stored sessions, browser cookies, and copied secrets as exposed until proven otherwise.

## First 15 Minutes

1. Confirm whether the machine is only unavailable or potentially stolen.
2. Sign in to GitHub from a safe device and confirm the DFC repo is intact.
3. Sign in to Google / Firebase / Google Cloud from a safe device.
4. Sign in to Stripe from a safe device.
5. Sign in to your password manager from a safe device.
6. Sign in to the primary DFC email account from a safe device.

## Immediate Containment

Complete these if theft, compromise, or unknown access is possible.

1. Revoke GitHub sessions and review authorized devices.
2. Revoke Google account sessions and review recent security activity.
3. Revoke Stripe sessions and review team access.
4. Revoke SendGrid sessions if applicable.
5. Revoke any saved browser or cloud IDE sessions tied to the old machine.
6. Rotate any secret that was stored only on the old machine or in local `.env` files.

## Service Recovery Order

Recover DFC in this order:

1. GitHub repository access
2. Primary email access
3. Google / Firebase / Google Cloud access
4. Stripe access
5. Secret storage access
6. Domain / DNS access
7. SendGrid / comms access
8. App store / distribution access if used

## Required Accounts To Verify

Mark each one as `verified`, `rotated`, or `blocked`.

| Service          | Why it matters                      | What to verify                                  |
| ---------------- | ----------------------------------- | ----------------------------------------------- |
| GitHub           | source code and workflows           | repo access, 2FA, session history               |
| Google account   | gateway to Firebase and GCP         | 2FA, recovery options, recent devices           |
| Firebase         | auth, hosting, firestore, storage   | project access and deploy ability               |
| Google Cloud     | service accounts, IAM, billing      | IAM health, billing, service account access     |
| Stripe           | payments, webhooks, Connect         | dashboard access, webhook health, team access   |
| SendGrid         | operational email                   | API key access, verified sender, account health |
| Domain / DNS     | public routing and redirect control | registrar access, DNS integrity                 |
| Password manager | recovery of all other services      | vault access, emergency kit, backup codes       |

## Secret Rotation Priority

Rotate these first if the old machine may be compromised:

1. `STRIPE_SECRET_KEY`
2. `STRIPE_WEBHOOK_SECRET`
3. `STRIPE_WEBHOOK_SECRET_CONNECT`
4. `STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS`
5. `SENDGRID_API_KEY`
6. any Google service account key file that existed locally
7. any `.env` file values used in local scripts

## New Machine Recovery Flow

1. Install Git.
2. Install Flutter.
3. Install Node.js.
4. Install Firebase CLI.
5. Clone the repo.
6. Restore secrets from the password manager or secret store.
7. Restore any required service account file to a safe local path.
8. Run dependency install and health checks.
9. Verify web run, analyzer, and any required deploy lanes.

## Minimum Verification Before You Resume Work

1. `git pull` works against the DFC repo.
2. `flutter pub get` works.
3. `flutter analyze` runs.
4. the app can run in demo mode.
5. Firebase project access is confirmed.
6. Stripe dashboard access is confirmed.
7. password manager access is confirmed.

## What To Record During Recovery

Write down:

1. date and time of incident
2. whether the old machine is lost, stolen, or hardware-dead
3. which sessions were revoked
4. which keys were rotated
5. which services are verified back online
6. what is still blocked

## Recovery Exit Criteria

Recovery is complete when all of these are true:

1. DFC code is reachable from GitHub on the new machine.
2. core secrets are restored from a non-local source.
3. any exposed secrets have been rotated.
4. Firebase and Stripe access are verified.
5. the app runs locally on the replacement machine.
