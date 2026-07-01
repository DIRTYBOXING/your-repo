# Dev Workflow — VS Code Insiders + Cloud Shell + GCP/Firebase (DFC)

## 1) Prerequisites
- VS Code **Insiders** installed
- `gcloud` installed
- Firebase CLI installed (`npm i -g firebase-tools`)
- Access to GCP project: `datafightcentral`
- Service account created (recommended) for deploys

## 2) Cloud Shell bootstrap
In Cloud Shell:

1. Login + set project
- `gcloud auth login`
- `gcloud config set project datafightcentral`

2. Ensure region
- `gcloud config set compute/region australia-southeast1`

3. (Recommended) Activate service account
- `gcloud auth activate-service-account <SA_EMAIL> --key-file=<path-to-json>`

## 3) Repo setup
From your workspace:
- Ensure Node deps exist (functions):
  - `cd functions && npm ci`

- Ensure Flutter deps exist (frontend):
  - `cd dfc_frontend/dfc_app && flutter pub get`

## 4) Deploy Firebase Functions
From repo root (or `functions/`, depending on your setup):
- `firebase deploy --only functions`

If you use a dedicated `functions` directory:
- `firebase deploy --only functions --project datafightcentral`

## 5) Deploy Firestore rules + indexes
- `firebase deploy --only firestore:rules`
- `firebase deploy --only firestore:indexes`

## 6) Stripe webhook test workflow
1. Confirm webhook endpoint:
- In Stripe Dashboard → Developers → Webhooks
- Use your function URL (or Cloud Functions URL)

2. Test delivery from Stripe test mode
- Use the correct webhook secret in:
  - `STRIPE_WEBHOOK_SECRET`

3. Verify entitlement write:
- Confirm Firestore doc(s) updated where Flutter expects:
  - `entitlements/{purchaseId}` with:
    - `userId`
    - `scope: event:<eventId>` (must match Flutter)
    - `active: true`

## 7) Mux playback test workflow
1. Create a PPV event + create/attach a stream
2. Call (or trigger) the callable:
- `getMuxPlaybackUrl` with `ppvEventId`
3. In Flutter:
- verify stream loads only when entitlement is true

## 8) Local verification (optional)
If you use Firebase emulators:
- `firebase emulators:start`

Test flows:
- Stripe webhook handler via local forwarding (if applicable)
- entitlement gate + Mux callable

## 9) Operational notes
- Never hard-code secrets in repo code
- Use `firebase functions:secrets:set <NAME>` for tokens/keys
- For social publishing keys:
  - set env vars in Firebase secrets or GCP Secret Manager

## 10) Suggested “one-command” sequence
(Adapt paths to your environment)
- `cd functions && npm ci`
- `firebase deploy --only functions --project datafightcentral`
- `firebase deploy --only firestore:rules --project datafightcentral`

