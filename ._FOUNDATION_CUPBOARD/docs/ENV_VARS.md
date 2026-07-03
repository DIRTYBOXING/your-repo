# Environment variables and credentials

This project uses several third-party services. Do NOT commit real secrets to
this repository. Use `.env` (gitignored) for local development and a secret
store for CI/CD or production.

## Required for full functionality

- `OPENAI_API_KEY` — OpenAI API key (chat / embeddings).
- `PINECONE_API_KEY` — Pinecone API key for vector storage.
- `PINECONE_ENVIRONMENT` — Pinecone environment/region.
- `PINECONE_INDEX` — Pinecone index name.
- `GOOGLE_APPLICATION_CREDENTIALS` — Path to Google service account JSON for `firebase-admin`.
- `FIREBASE_PROJECT_ID` — Firebase project id.

## Stripe Connect V2

For Firebase Functions and Stripe marketplace flows, keep these values in
`functions/.env` locally and in your deployment secret/config path for production.

- `STRIPE_SECRET_KEY` — Stripe secret key. Must be valid and unexpired.
- `STRIPE_WEBHOOK_SECRET` — General Stripe webhook signing secret for `handleStripeWebhook`.
- `STRIPE_WEBHOOK_SECRET_CONNECT` — Connect V2 webhook signing secret for `stripeConnectWebhook`.
- `STRIPE_WEBHOOK_SECRET_SUBSCRIPTIONS` — Subscription lifecycle webhook signing secret for `stripeSubscriptionWebhook`.
- `PLATFORM_SUBSCRIPTION_PRICE_ID` — Connected-account partner subscription price.
- `BASE_URL` — Public app URL used for Stripe return/cancel URLs.

Current deployed Connect V2 webhook URLs:

- `https://stripeconnectwebhook-drxosqpmwq-ts.a.run.app`
- `https://stripesubscriptionwebhook-drxosqpmwq-ts.a.run.app`

Current live monthly partner subscription price created for this repo:

- `price_1TLSeeBSoM6ez8FYlBH6N7F8`

Operational notes:

- The webhook provisioning script is `scripts/provision_stripe_connect_v2_webhooks.mjs`.
- VS Code task: `Stripe: Provision Connect V2 Webhooks`.
- If Stripe rejects webhook creation with `Invalid API Key` or `Expired API Key`, rotate `STRIPE_SECRET_KEY` first and rerun provisioning.

## Mux streaming and replay

DFC now supports two modes:

- production mode: real Mux live ingest, signed playback, webhook-driven replay
- rehearsal mode: PPV lane + test ingest path without real Mux credentials

Required values for real Mux mode:

- `MUX_TOKEN_ID`
- `MUX_TOKEN_SECRET`
- `MUX_SIGNING_KEY_ID`
- `MUX_SIGNING_PRIVATE_KEY`
- `MUX_WEBHOOK_SECRET`

Optional guarded smoke-lane value:

- `PPV_SMOKE_TOKEN` — shared secret for the read-only `testMuxAuth` callable. When set, the production-safe smoke lane requires the same token from the caller before probing Mux.

Where these go:

- local developer machine: root `.env` for app-level reference and `functions/.env` where local functions need them
- deployed Firebase Functions: Secret Manager, not source control
- if `PPV_SMOKE_TOKEN` is enabled, keep it in root `.env` for smoke scripts, `functions/.env` for local emulator validation, and Firebase Secret Manager for deployed callable protection

Recommended Firebase secret commands:

```powershell
firebase functions:secrets:set MUX_TOKEN_ID --project datafightcentral
firebase functions:secrets:set MUX_TOKEN_SECRET --project datafightcentral
firebase functions:secrets:set MUX_SIGNING_KEY_ID --project datafightcentral
firebase functions:secrets:set MUX_SIGNING_PRIVATE_KEY --project datafightcentral
firebase functions:secrets:set MUX_WEBHOOK_SECRET --project datafightcentral
firebase functions:secrets:set PPV_SMOKE_TOKEN --project datafightcentral
```

Important operational note:

- do not use `firebase functions:config:set mux.*` for the new Mux path in this repo
- the active streaming functions read Mux values through Firebase Functions secret bindings in `functions/config/index.js`

Default-safe verification path:

- `node scripts/smoke_mux_auth.mjs` resolves the Functions base URL production-first and calls the read-only `testMuxAuth` callable via `httpsCallableFromURL`
- `node scripts/smoke_mux_credential_delivery.mjs` is still available, but it is destructive and should only be used for operator rehearsal when you explicitly want real credential delivery side effects

Rehearsal-mode truth:

- promoters can still create a PPV lane and test operational flow without Mux
- rehearsal mode does not provide real Mux playback, real signed tokens, or real replay generation
- once the five secrets exist, the same control-room flow upgrades to real Mux provisioning

## Mission Control and PPV storefront frontend

The new Mission Control cockpit and premium PPV storefront read their runtime
configuration from Flutter compile-time defines first and then fall back to
`assets/.env` for local non-web runs.

Current runtime precedence in the app:

- preferred for web and release builds: `--dart-define`
- local fallback for desktop/mobile dev: `assets/.env`
- note: `assets/.env` is intentionally skipped on some web/release paths

Required frontend variables for the new live DFC surfaces:

- `DFC_OPERATOR_FUNCTION_URL` — full HTTPS URL for `operatorAction`
- `DFC_OPERATOR_ID` — operator identity sent in signed Mission Control calls
- `DFC_OPERATOR_SECRET` — shared HMAC secret for Mission Control actions. Treat this as privileged and only inject it into trusted internal operator builds, never the public storefront build.
- `DFC_PPV_STOREFRONT_BASE` — Functions base URL used by `createPpvStorefrontOrder` and `confirmPpvStorefrontOrder`
- `DFC_PPV_AUTO_CONFIRM_SANDBOX` — set to `true` only for sandbox/demo flows that should auto-confirm the order after creation

Current deployed base values:

- Functions base: `https://australia-southeast1-datafightcentral.cloudfunctions.net`
- Operator action endpoint: `https://australia-southeast1-datafightcentral.cloudfunctions.net/operatorAction`
- Storefront base: `https://australia-southeast1-datafightcentral.cloudfunctions.net`

Example local `assets/.env` entries:

```env
DFC_OPERATOR_FUNCTION_URL=https://australia-southeast1-datafightcentral.cloudfunctions.net/operatorAction
DFC_OPERATOR_ID=ops_alpha
DFC_OPERATOR_SECRET=replace-with-internal-operator-secret
DFC_PPV_STOREFRONT_BASE=https://australia-southeast1-datafightcentral.cloudfunctions.net
DFC_PPV_AUTO_CONFIRM_SANDBOX=true
```

Example operator build run command:

```powershell
flutter run -d windows `
   --dart-define=DFC_OPERATOR_FUNCTION_URL="https://australia-southeast1-datafightcentral.cloudfunctions.net/operatorAction" `
   --dart-define=DFC_OPERATOR_ID="ops_alpha" `
   --dart-define=DFC_OPERATOR_SECRET="replace-with-internal-operator-secret" `
   --dart-define=DFC_PPV_STOREFRONT_BASE="https://australia-southeast1-datafightcentral.cloudfunctions.net" `
   --dart-define=DFC_PPV_AUTO_CONFIRM_SANDBOX=true
```

Example public storefront web build command:

```powershell
flutter build web --no-tree-shake-icons `
   --dart-define=DFC_PPV_STOREFRONT_BASE="https://australia-southeast1-datafightcentral.cloudfunctions.net" `
   --dart-define=DFC_PPV_AUTO_CONFIRM_SANDBOX=false
```

Operational rule:

- do not inject `DFC_OPERATOR_SECRET` into a public consumer web build
- reserve operator credentials for trusted internal builds only

## SendGrid Email

DFC already includes the SendGrid package in the `functions` workspace.

Required local variables in `functions/.env`:

- `SENDGRID_API_KEY` — your SendGrid Mail Send API key
- `FROM_EMAIL` — a verified sender address in SendGrid

Recommended local shell commands on Windows PowerShell:

```powershell
$env:SENDGRID_API_KEY = "SG_REPLACE_WITH_REAL_KEY" # pragma: allowlist secret
$env:FROM_EMAIL = "info@datafightcentral.com"
```

To make them persistent for your user profile on Windows:

```powershell
[Environment]::SetEnvironmentVariable("SENDGRID_API_KEY", "SG_REPLACE_WITH_REAL_KEY", "User") # pragma: allowlist secret
[Environment]::SetEnvironmentVariable("FROM_EMAIL", "info@datafightcentral.com", "User")
```

Quick validation paths:

- VS Code task: `SendGrid: Dry Run Config Check`
- VS Code task: `SendGrid: Send Test Email`
- DFC health report email tasks also reuse these variables

If test email sending fails, verify:

- the API key has Mail Send permission
- the sender address is verified in SendGrid
- the key is available in either your shell environment or `functions/.env`

## n8n Integration

DFC uses `n8n` mainly through webhook URLs. In this repo, those values belong in `functions/.env`.

Use these variables in `functions/.env`:

```env
N8N_BASE_URL=https://your-subdomain.app.n8n.cloud
N8N_WEBHOOK_URL=https://your-subdomain.app.n8n.cloud/webhook/dfc-event-seed
N8N_CONTENT_BRAIN_URL=https://your-subdomain.app.n8n.cloud/webhook/dfc-content-brain
N8N_PROMOTE_WEBHOOK_URL=https://your-subdomain.app.n8n.cloud/webhook/dfc-publisher
N8N_API_KEY=your_n8n_api_key_if_required
```

For the repo-hosted local stack, also pin and set the Docker/runtime variables in the root `.env`:

```env
N8N_IMAGE=n8nio/n8n:1.89.2
N8N_HOST=localhost
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/
N8N_EDITOR_BASE_URL=http://localhost:5678
N8N_BASIC_AUTH_USER=dfc_admin
N8N_BASIC_AUTH_PASSWORD=change-me-local-only
N8N_ENCRYPTION_KEY=replace-with-32-plus-char-secret
N8N_PROXY_HOPS=1
N8N_REDIS_DB=1
N8N_EXECUTIONS_DATA_MAX_AGE=168
```

What goes where:

- Put `N8N_BASE_URL`, `N8N_WEBHOOK_URL`, `N8N_CONTENT_BRAIN_URL`, `N8N_PROMOTE_WEBHOOK_URL`, and optional `N8N_API_KEY` in `functions/.env`
- Keep workflow logic, credentials for downstream apps, and node configuration inside your `DFC-n8n` instance
- If your webhook endpoints are public and do not require bearer auth, `N8N_API_KEY` can stay empty

What DFC already does:

- `functions/content/content_brain.js` reads `N8N_CONTENT_BRAIN_URL` and optional `N8N_API_KEY`
- legacy automation paths read `N8N_WEBHOOK_URL`
- local smoke scripts can call a local `n8n` instance on port `5678`
- `docker-compose.yml` now runs `n8n` in queue mode with Redis plus a dedicated `n8n-worker` service for production-shaped local automation

If you run `n8n` locally instead of on `n8n.cloud`, use values like:

```env
N8N_IMAGE=n8nio/n8n:1.89.2
N8N_BASE_URL=http://localhost:5678
N8N_WEBHOOK_URL=http://localhost:5678/webhook/dfc-event-seed
N8N_CONTENT_BRAIN_URL=http://localhost:5678/webhook/dfc-content-brain
N8N_PROMOTE_WEBHOOK_URL=http://localhost:5678/webhook/dfc-publisher
N8N_API_KEY=
```

Operational note:

- The native publisher is now the primary path for some content flows, so `n8n` is optional for those lanes unless you specifically want the DFC-n8n workflows active.
- The local dev command is `docker compose up -d db redis n8n n8n-worker`; do not use ad hoc `docker run n8nio/n8n:latest` anymore.

## Meta / Facebook page targeting

DFC now supports an explicit Meta target key so the publisher does not rely on whichever Facebook account currently resolves as `me`.

Use these variables in local `.env` or your deployed secret store:

```env
FACEBOOK_TARGET_KEY=datafightcentral
FACEBOOK_PAGE_LABEL=Data Fight Central
FACEBOOK_OWNER_PROFILE=Heath Ewart
FACEBOOK_BUSINESS_PORTFOLIO=Dirty Boxer Australia
FACEBOOK_PAGE_ID=997025300171474
FACEBOOK_PAGE_ACCESS_TOKEN=EAAB...
IG_BUSINESS_ACCOUNT_ID=1784...

FACEBOOK_GRAY_MERCY_PAGE_ID=
FACEBOOK_GRAY_MERCY_PAGE_ACCESS_TOKEN=
IG_GRAY_MERCY_BUSINESS_ACCOUNT_ID=
FACEBOOK_DIRTY_BOXER_PAGE_ID=
FACEBOOK_DIRTY_BOXER_PAGE_ACCESS_TOKEN=
IG_DIRTY_BOXER_BUSINESS_ACCOUNT_ID=
```

Current canonical target mapping in the repo:

- `datafightcentral` — page target `Data Fight Central`, page ID `997025300171474`, owned by business portfolio `Dirty Boxer Australia`, administered by `Heath Ewart`
- `gray_mercy_gym` — page target `Gray Mercy Gym`, owned/administered by `Heath Ewart`
- `dirty_boxer_australia` — page target `Dirty Boxer Australia`, owned/administered by `Heath Ewart`
- `heath_ewart` — admin login identity only; Graph API automation should not publish to a personal profile

Operational rules:

- Set `FACEBOOK_TARGET_KEY=datafightcentral` for the main DFC publisher lane unless you are deliberately switching to another managed page.
- Prefer page IDs and page access tokens over `me` in workflow nodes.
- For the hosted n8n publisher webhook, include `facebookTargetKey`, `facebookPageId`, and `facebookPageLabel` in the publish request when you want to override the default page.
- If n8n still reports `An active access token must be used to query information about the current user`, the workflow structure is fine and the credential token needs to be replaced.

## Google setup (recommended for now)

1. Create a Google Cloud project and enable Firestore / Firebase.
2. Create a service account with `Firestore Admin` and `Storage Admin` as needed.
3. Download the service account JSON and place it somewhere safe on your dev
   machine (do not commit it).
4. Set `GOOGLE_APPLICATION_CREDENTIALS` to the absolute path of that JSON or put
   the JSON file path into your `.env` as `GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json`.

## Local development

- Copy `.env.example` to `.env` and populate values.
- The backend loads `.env` automatically using `python-dotenv`.

## CI / Production

- Use GitHub Actions secrets or Google Secret Manager.
- Example GitHub secret names: `OPENAI_API_KEY`, `PINECONE_API_KEY`, `GCP_SA_KEY`.
- For Firebase deploys from CI, prefer using a dedicated CI service account and
  `google-gcloud` auth steps in your workflow.

## Security notes

- Rotate keys periodically.
- Grant the minimum required IAM roles on service accounts.
- Never paste secrets into chat or PRs.
