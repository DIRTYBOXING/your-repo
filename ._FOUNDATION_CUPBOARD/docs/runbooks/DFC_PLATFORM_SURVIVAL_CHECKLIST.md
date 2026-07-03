# DFC Platform Survival Checklist

This runbook is the single source of truth for what Data Fight Central depends on to stay alive, monetize, communicate, and scale.

Use it when:

- something stops working and you need to isolate which dependency failed
- a key, token, sender, webhook, or integration may have expired
- you want a weekly operating checklist instead of guessing
- you need to know what DFC must protect before expanding further

Related runbooks:

- `docs/runbooks/DFC_RECOVERY_CHECKLIST.md`
- `docs/runbooks/DFC_SECRETS_AND_ACCESS_INVENTORY.md`
- `docs/runbooks/DFC_NEW_MACHINE_SETUP.md`

## Survival Rule

If any tier 1 item is unhealthy, DFC is in platform protection mode. Stop expansion work and repair the foundation first.

## Tier 1: Core Platform Dependencies

These are the services DFC depends on for basic survival.

| Dependency                         | Why it matters                           | Primary config or code path                                         | Weekly check                                                               |
| ---------------------------------- | ---------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Firebase Hosting                   | Web app delivery                         | `firebase.json`, `web/`, hosting deploy tasks                       | Confirm the live site loads and current web build deploys cleanly          |
| Firebase Auth                      | Login and identity                       | `lib/shared/services/auth_service.dart`, Firebase Console Auth      | Confirm sign-in works on web and authorized domains are correct            |
| Firestore                          | Primary app data                         | `firestore.rules`, `firestore.indexes.json`, `lib/shared/services/` | Confirm reads and writes succeed for a real user journey                   |
| Firebase Storage                   | media, posters, uploads                  | `storage.rules`, upload services, content pipeline                  | Confirm uploads and reads work for at least one recent asset               |
| Firebase Functions Gen 2           | backend logic and webhooks               | `functions/index.js`, `functions/`                                  | Confirm deploy works and `healthCheck` exists                              |
| Google Cloud service account / ADC | admin access, pipelines, AI, storage     | `GOOGLE_APPLICATION_CREDENTIALS`, Firebase Admin usage              | Confirm the credential exists, is readable, and still has required roles   |
| Base URL and public domain         | checkout redirects, public access, links | `BASE_URL`, hosting config                                          | Confirm public URLs resolve correctly and redirects land on the right host |

## Tier 2: Revenue and Entitlements

These keep money flowing and partner onboarding alive.

| Dependency             | Why it matters                  | Primary config or code path                                                             | Weekly check                                                            |
| ---------------------- | ------------------------------- | --------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Stripe secret key      | payment API access              | `functions/config/index.js`, `functions/stripe/`                                        | Verify against `GET /v1/account`                                        |
| Stripe webhook secrets | webhook authenticity            | `STRIPE_WEBHOOK_SECRET*`, `functions/stripe/connect.js`, `functions/stripe/payments.js` | Confirm webhook endpoints still exist and recent events process cleanly |
| Stripe Connect V2      | promoter onboarding and payouts | `functions/stripe/connect.js`, Stripe dashboard                                         | Confirm a connected account can still onboard and update status         |
| Subscription price IDs | paid plans and monetization     | `PLATFORM_SUBSCRIPTION_PRICE_ID` and related Stripe config                              | Confirm active prices still exist in Stripe                             |
| Entitlement flow       | feature gating after purchase   | `functions/stripe/entitlements.js`, client payment services                             | Confirm a successful payment grants the expected entitlement            |
| PayPal                 | secondary payment lane          | `functions/paypal/payments.js`                                                          | Confirm credentials are present if this lane is expected to be live     |

## Tier 3: Communications and Safety Response

These keep DFC able to notify users, partners, and operators.

| Dependency              | Why it matters                    | Primary config or code path                                                                                     | Weekly check                                                         |
| ----------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| SendGrid                | email delivery, reports, outreach | `SENDGRID_API_KEY`, `FROM_EMAIL`, `functions/sendPromoterEmail.js`, `functions/scripts/sendgrid_test_email.cjs` | Run `SendGrid: Dry Run Config Check`, then live test send            |
| Verified sender address | email deliverability              | SendGrid sender verification, `FROM_EMAIL`                                                                      | Confirm sender is still verified                                     |
| Twilio                  | SMS and safety escalation         | `functions/smsWebhook.js`, `functions/safety-webhook.js`                                                        | Confirm auth token, sending number, and on-call recipients are valid |
| Firebase Messaging      | push notifications                | Flutter messaging setup, Firebase Console                                                                       | Confirm at least one test device can still receive push              |
| Slack webhooks          | operational alerts                | `functions/takedown.js`, `functions/canaryGuard/index.js`                                                       | Confirm webhook URLs still post messages                             |

## Tier 4: Streaming, Media, and Event Delivery

These support PPV, replay, clips, and media distribution.

| Dependency                    | Why it matters                        | Primary config or code path                                 | Weekly check                                                               |
| ----------------------------- | ------------------------------------- | ----------------------------------------------------------- | -------------------------------------------------------------------------- |
| Mux                           | live video, playback, signed playback | `functions/streaming/mux.js`, `functions/streaming/live.js` | Confirm token IDs, webhook secret, and signed playback settings are valid  |
| Firebase Storage bucket       | source media and generated assets     | `FIREBASE_STORAGE_BUCKET`, content pipeline services        | Confirm recent writes and reads succeed                                    |
| Playback / DRM endpoints      | premium content protection            | `functions/drm-license-exchange.js`, PPV docs               | Confirm endpoints resolve and test license exchange works if PPV is active |
| YouTube API / stream key lane | livestream and publishing support     | `YOUTUBE_API_KEY`, `--dart-define` usage, social publisher  | Confirm keys and quotas are still valid                                    |
| OG clip SSR / CDN origin      | share cards and event previews        | `server/og-clip-ssr.js`                                     | Confirm generated OG pages and assets load correctly                       |

## Tier 5: Automation, Growth, and Intelligence

These are not always required for basic uptime, but they matter for DFC to grow, automate, and scale.

| Dependency                              | Why it matters                              | Primary config or code path                                       | Weekly check                                                        |
| --------------------------------------- | ------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------- |
| Gemini / Genkit                         | AI summaries and assistive flows            | `GEMINI_KEY`, `genkit/`, `functions/config/index.js`              | Confirm credentials load and one model-backed path still responds   |
| OpenAI                                  | image or content generation paths           | env usage across `lib/` and docs                                  | Confirm the key is present only if these features are in active use |
| Redis                                   | content and worker orchestration            | `REDIS_URL`, content pipeline services                            | Confirm Redis is reachable if pipeline workers are enabled          |
| n8n                                     | automation webhooks and content brain flows | `N8N_*` env vars, content automation functions                    | Confirm URLs and API keys are current                               |
| Social publisher tokens                 | DFC outbound growth lanes                   | `functions/content/social_publisher.js`                           | Confirm each claimed live social network still has valid tokens     |
| Genius Sports / data feeds              | event or sports data ingestion              | `functions/feeds/genius_sports.js`                                | Confirm credentials if that ingestion lane is active                |
| Cloudinary / image generation providers | visual automation                           | `functions/automation/event_seeder.js`, image generation services | Confirm keys only for lanes you intend to operate                   |

## Tier 6: Observability and Recovery

These tell you when the platform is weakening before users do.

| Dependency          | Why it matters                      | Primary config or code path                                 | Weekly check                                           |
| ------------------- | ----------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------ |
| DFC health report   | consolidated platform health signal | `scripts/dfc_health_report.ps1`, `reports/health/latest.md` | Run it and read the priority actions                   |
| Flutter analyzer    | client code integrity               | `flutter analyze`                                           | Keep analyzer clean                                    |
| Flutter tests       | regression guard                    | `flutter test`                                              | Run the suite and investigate new failures             |
| Web build           | shipping confidence                 | `Flutter: Build Web Sandbox` and release builds             | Confirm build succeeds before major pushes             |
| Crashlytics         | production crash visibility         | Flutter Firebase setup                                      | Confirm events are arriving                            |
| Firebase Analytics  | usage and funnel visibility         | app analytics service                                       | Confirm new sessions and events appear                 |
| Remote Config       | operational control over flags      | Firebase Remote Config                                      | Confirm critical fallback values are present           |
| GitHub Actions / CI | scheduled and pre-merge checks      | `.github/workflows/`                                        | Confirm workflows still run and required secrets exist |

## Daily Survival Checklist

- [ ] Run `DFC: Daily Must-Do Sweep`
- [ ] Read `reports/health/latest.md`
- [ ] Run `flutter test` or `Run Flutter Tests`
- [ ] Confirm the latest web path still builds if you are shipping anything material
- [ ] Confirm Stripe status is healthy before touching PPV or subscriptions
- [ ] Confirm no critical auth, Firestore, or Functions outage exists in Firebase Console
- [ ] If email reporting matters today, run the SendGrid dry run or a live test email

## Weekly Survival Checklist

- [ ] Run `DFC: Full Daily Command Sweep`
- [ ] Review `reports/health/latest.json` for dependency drift
- [ ] Verify Firebase Auth sign-in on the real web lane
- [ ] Verify Firestore read and write on a real account flow
- [ ] Verify one Storage upload and one Storage read
- [ ] Verify `healthCheck` callable or equivalent backend health path
- [ ] Verify Stripe secret, webhook endpoints, and at least one payment path assumption
- [ ] Verify SendGrid sender and test-email lane
- [ ] Verify key social or notification integrations you currently depend on
- [ ] Review Crashlytics, Analytics, and Functions logs for silent failures
- [ ] Review expiring domains, billing accounts, quotas, and provider notices
- [ ] Review outdated Flutter, root Node, and `functions` dependencies

## Monthly Survival Checklist

- [ ] Rotate keys that should not live indefinitely
- [ ] Review Google Cloud IAM roles and remove excess privileges
- [ ] Review Firebase rules, storage rules, and public exposure assumptions
- [ ] Review Stripe products, prices, webhook destinations, and Connect onboarding health
- [ ] Review Mux, Twilio, SendGrid, and social provider billing or plan limits
- [ ] Review all GitHub secrets and local `.env` expectations against reality
- [ ] Confirm backups, audit exports, and incident runbooks still make sense

## Expiry and Failure Watchlist

Use this as the short list for things that usually fail silently.

| Watch item                   | Failure symptom                             | Action                                            |
| ---------------------------- | ------------------------------------------- | ------------------------------------------------- |
| API key expired or revoked   | 401, 403, webhook failures, empty responses | rotate key, update secret store, rerun validation |
| Webhook secret drift         | payments succeed in provider but not in DFC | reprovision webhook secret and replay test event  |
| Sender verification removed  | email send fails or drops                   | reverify sender/domain in SendGrid                |
| OAuth or social token expiry | posting lane fails silently                 | refresh the provider token and retest posting     |
| Service account path broken  | admin code fails locally or in pipeline     | fix `GOOGLE_APPLICATION_CREDENTIALS` and IAM      |
| Domain / DNS / hosting drift | links or callbacks go to the wrong place    | verify `BASE_URL`, hosting target, and DNS        |
| Dependency drift             | builds become fragile, security debt grows  | schedule upgrade branch before breakage compounds |
| Billing or quota exhaustion  | integrations stop with no code change       | check provider dashboards and quotas immediately  |

## What Needs Attention Right Now

This is the honest current status based on work already done in this repo.

- SendGrid delivery is implemented, but live validation is still blocked until `SENDGRID_API_KEY` and a verified `FROM_EMAIL` are configured.
- The DFC health report currently trends `red` because dependency drift is high, not because the app is fully down.
- Stripe Connect V2 was validated in this session, but other optional external lanes were not fully revalidated end to end today.
- Social publisher integrations exist in code for Facebook, Instagram, X, Threads, YouTube, LinkedIn, and Bluesky, but each token should be treated as unverified until explicitly tested.
- Mux, Twilio, PayPal, Redis-backed content pipeline lanes, Genius Sports, and n8n are present in code but should be considered operationally unverified unless you are actively using and testing them.
- A secret-like SendGrid string was found in shared config and removed from `functions/config/index.js`. If that value was ever real, rotate it immediately.

## Operator Rule

DFC survives by protecting the stack in this order:

1. Identity and data
2. Payments and entitlements
3. Communications and alerts
4. Streaming and content delivery
5. Automation and growth
6. Upgrades before drift becomes damage
