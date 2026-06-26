# DFCalive Technical Spec

## Purpose

Minimal secure flow for ingest → paywall → DRM → playback token → promoter payouts.

## Architecture Overview

| Layer        | Implementation                                                      | DFC Component                               |
| ------------ | ------------------------------------------------------------------- | ------------------------------------------- |
| Ingest       | RTMP/SRT → Transcoder (K8s + FFmpeg or MediaLive)                   | `dfc-content-pipeline/live-publisher`       |
| Packaging    | CMAF / LL-HLS segments; server-side forensic watermark              | `dfc-content-pipeline/video-worker`         |
| DRM          | Widevine + FairPlay license server (third-party or self-hosted)     | Future: `backend/drm-license/`              |
| Delivery     | CloudFront / Fastly with token validation at edge                   | CDN + `backend/edge-validator/`             |
| Payments     | Stripe Connect V2; PaymentIntent or Checkout → webhook → token mint | `backend/playback-token/`                   |
| Storage      | GCS for segments and VOD; signed PUT URLs for uploads               | `gs://datafightcentral.firebasestorage.app` |
| AI Marketing | Auto-clip (FFmpeg), OG generation, LLM captions                     | Cloud Functions `australia-southeast1`      |
| Monitoring   | Sentry, Grafana, BigQuery, watermark logs                           | `monitoring/` + `ops/audit/`                |

## Key Endpoints

### Payment and Playback

| Method | Path                                | Role                                            |
| ------ | ----------------------------------- | ----------------------------------------------- |
| `POST` | `/api/events`                       | Create event (promoter)                         |
| `POST` | `/api/events/:id/assets/signed-url` | Request signed upload URL                       |
| `POST` | `/api/payments/create-intent`       | Create Stripe PaymentIntent                     |
| `POST` | `/webhook/stripe`                   | Stripe webhook handler (verify signature)       |
| `POST` | `/api/playback/mint`                | Mint playback JWT (internal, called by webhook) |
| `GET`  | `/manifest/:eventId.m3u8`           | HLS manifest (CDN validated)                    |
| `POST` | `/api/drm/license`                  | License server endpoint                         |

### AI Marketing

| Method | Path                     | Role                                           |
| ------ | ------------------------ | ---------------------------------------------- |
| `POST` | `/api/clips/generate`    | Trigger 15s auto-clip from event recording     |
| `POST` | `/api/og/generate`       | Generate OG image for event                    |
| `POST` | `/api/captions/generate` | LLM caption generation (3 variants + hashtags) |
| `POST` | `/api/social/schedule`   | Schedule social posts with A/B variants        |

## Payment Flow

```
Client                  Backend                 Stripe              Webhook Handler
  │                       │                       │                       │
  ├─ Request checkout ───►│                       │                       │
  │                       ├─ PaymentIntent ──────►│                       │
  │                       │  (transfer_data +     │                       │
  │                       │   application_fee)    │                       │
  │  ◄── clientSecret ────┤                       │                       │
  ├─ Confirm payment ────►│──────────────────────►│                       │
  │                       │                       ├─ payment_intent ─────►│
  │                       │                       │  .succeeded           │
  │                       │                       │                       ├─ verify sig
  │                       │                       │                       ├─ create sessionId
  │                       │                       │                       ├─ store audit mapping
  │                       │                       │                       ├─ mint JWT
  │  ◄── playback JWT ────┤◄──────────────────────┤◄──────────────────────┤
  │                       │                       │                       │
```

### PaymentIntent Creation (backend)

```bash
curl -s -X POST https://api.stripe.com/v1/payment_intents \
  -u ${STRIPE_SECRET_KEY}: \
  -d amount=5000 \
  -d currency=aud \
  -d "payment_method_types[]=card" \
  -d "transfer_data[destination]=${CONNECTED_ACCOUNT_ID}" \
  -d "application_fee_amount"=2000
```

- **amount**: event PPV price in cents (5000 = $50.00 AUD)
- **application_fee_amount**: DFC platform fee in cents (2000 = $20.00 = 40%)
- **transfer_data.destination**: promoter's Stripe Connected Account ID

## Playback Token (JWT)

### Payload

```json
{
  "iss": "dfc-backend",
  "sub": "playback",
  "eventId": "evt_123",
  "userId": "uid_abc",
  "sessionId": "sess_456",
  "iat": 1700000000,
  "exp": 1700000900
}
```

### Rules

- Algorithm: `RS256` (asymmetric — private key signs, public key verifies at edge)
- TTL: **10 minutes** (short-lived; client refreshes via backend)
- Claims validated at edge: `iss`, `exp`, `eventId` (must match requested manifest path)
- Signing key rotation: monthly, with 24-hour overlap window

## CDN Edge Validation

```
Client ──► CDN Edge ──► Origin (manifest)
              │
              ├─ Extract Bearer token from Authorization header
              ├─ Verify RS256 signature with public key
              ├─ Check exp > now
              ├─ Check eventId matches manifest path
              ├─ If valid: allow request to origin
              └─ If invalid: return 403 Forbidden
```

Implementation: Lambda@Edge (CloudFront) or Fastly VCL compute.

## DRM License Flow

1. Player requests DRM license with session info (Widevine or FairPlay).
2. License server validates playback JWT and session state.
3. If valid, issues license bound to session. Otherwise 403.
4. Player decrypts and plays content.

## Forensic Watermarking

### Insertion (packaging stage)

- Insert invisible session watermark into video segments at packager.
- Map `sessionId → buyerId` in audit database.
- Store mapping in `ops/audit/<event>/watermark_log.json`.

### Extraction

- Given leaked content file, extraction tool recovers embedded `sessionId`.
- Cross-reference audit DB to identify buyer.
- Generate DMCA takedown with watermark evidence.

### Test command (visible overlay for dev only)

```bash
ffmpeg -i input.mp4 \
  -vf "drawtext=text='{{SESSION_ID}}':fontcolor=white:fontsize=24:x=10:y=H-th-10:alpha=0.05" \
  -c:v libx264 -crf 18 -c:a copy output_watermarked.mp4
```

Production: use robust forensic watermarking library (not visible text).

## Storage and Upload Security

- Promoter uploads use **signed PUT URLs** (short TTL, single-use).
- Storage rules enforce owner-only write paths.
- Public read only for approved/published assets.
- Lifecycle rules: draft assets deleted after 30 days; VOD retained per contract.

## Security Requirements

- Stripe webhook signature verification on every request (`stripe.webhooks.constructEvent`).
- JWT private key stored in GCP Secret Manager (never in code or env files).
- CORS restricted to production origins: `datafightcentral.com`, `datafightcentral.web.app`.
- Key rotation: JWT signing keys rotated monthly.
- All audit artifacts stored in secure bucket with versioning enabled.

## Acceptance Criteria (MVP)

- [ ] Promoter can onboard via Stripe Connect V2 and create event with uploaded assets.
- [ ] Buyer completes PaymentIntent and receives working playback JWT within 2 seconds.
- [ ] Player plays HLS stream with DRM license issued for valid session.
- [ ] Invalid/expired JWT returns 403 at CDN edge.
- [ ] Watermark extraction maps leaked content to `sessionId` with ≥ 95% accuracy.
- [ ] Audit bundle auto-generated per event in `ops/audit/<event>/`.

## Environment Variables (backend services)

```
STRIPE_SECRET_KEY          # Stripe secret (Secret Manager)
STRIPE_WEBHOOK_SECRET      # Stripe webhook signing secret (Secret Manager)
JWT_PRIVATE_KEY_PATH       # Path to RS256 private key (mounted from Secret Manager)
JWT_PUBLIC_KEY_PATH         # Path to RS256 public key (for edge distribution)
GCP_PROJECT                # datafightcentral
GCP_REGION                 # australia-southeast1
FIREBASE_PROJECT_ID        # datafightcentral
SENTRY_DSN                 # Sentry error tracking
```
