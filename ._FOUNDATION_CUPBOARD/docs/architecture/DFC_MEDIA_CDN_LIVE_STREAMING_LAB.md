# DFC Live Streaming Lab (Media CDN + Live Streaming API)

Status: R&D and staging canonical lab for live ingest -> transcode -> CDN -> playback validation.

## Purpose

Goal:

- Build a repeatable workflow that transcodes a live feed, stores manifests and segments in Cloud Storage, serves them via Media CDN, and validates playback with player smoke checks.

Deliverable:

- A staging pipeline that produces HLS and DASH outputs, serves them through Media CDN from GCS origin, and is blocked from promotion unless entitlement, mux, poster, and Playwright checks pass.

## Architecture (Text Diagram)

Venue encoder (FFmpeg SRT RTMP)
-> Live Streaming API Input
-> Live Streaming API Channel (transcoder)
-> Cloud Storage bucket (manifests + segments)
-> Media CDN (origin = GCS path)
-> Player (Shaka VLC web player)

Supporting services:

- Entitlement service
- Payments
- CDN purge and prewarm
- Monitoring (Cloud Monitoring and optional Prometheus)
- Clips pipeline
- Moderation queue
- Maps for venue pages

## Prerequisites

- Google Cloud project with billing enabled.
- Cloud Shell access (recommended).
- IAM permissions for Live Streaming API, Cloud Storage, Monitoring, and IAM.
- Local tools: FFmpeg, Playwright, jq, gh CLI (optional).
- Repo files listed in this document present in your workspace.

## Cloud Shell Commands (Step by Step)

### 1) Create GCS bucket

```bash
PROJECT=$(gcloud config get-value project)
BUCKET="dfc-live-${PROJECT}"
gsutil mb -p "$PROJECT" -l us-central1 "gs://${BUCKET}"
gsutil versioning set on "gs://${BUCKET}"
```

### 2) Enable required APIs

```bash
gcloud services enable livestream.googleapis.com \
  compute.googleapis.com \
  storage.googleapis.com \
  monitoring.googleapis.com \
  iam.googleapis.com
```

### 3) Create input and channel

```bash
PROJECT=$(gcloud config get-value project)

# Create input
gcloud livestream inputs create dfc-input \
  --region=us-central1 \
  --type=rtmp

# Create channel outputting to GCS
gcloud livestream channels create dfc-channel \
  --region=us-central1 \
  --input="projects/${PROJECT}/locations/us-central1/inputs/dfc-input" \
  --output-uri="gs://${BUCKET}/events/champions-collide-2026/"
```

### 4) Start test signal with FFmpeg

```bash
# Replace with the RTMP ingest URL from the input
FFMPEG_RTMP_URL="rtmp://<input-host>/<stream-key>"

ffmpeg -re -f lavfi -i testsrc=size=1280x720:rate=30 \
  -f lavfi -i sine=frequency=1000:sample_rate=44100 \
  -c:v libx264 -preset veryfast -b:v 2500k \
  -c:a aac -b:a 128k \
  -f flv "$FFMPEG_RTMP_URL"
```

### 5) Verify manifests in GCS

```bash
gsutil ls "gs://${BUCKET}/events/champions-collide-2026/"
gsutil cat "gs://${BUCKET}/events/champions-collide-2026/master.m3u8"
```

### 6) Configure Media CDN origin and endpoint

- Cloud Console -> Network services -> Media CDN.
- Create origin using the event path in your bucket.
- Create endpoint and route for master.m3u8 and segments.

### 7) Validate playback via CDN URL

- Play endpoint URL with Shaka or VLC.
- Confirm startup, rendition switching, and segment fetch success.

### 8) Create monitoring dashboard

Track at least:

- cache hit ratio
- cache miss ratio
- edge and origin latency
- origin errors
- egress

## Repo Artifacts (Current Canonical Paths)

The following files already exist in this repository and are the canonical lab hooks:

- .github/workflows/ppv-staging-gate.yml
- ops/check_posters.sh
- ops/mux_smoke.sh
- ops/weekly_sweep.sh
- ops/live_streaming_codelab_setup.sh
- ops/live_streaming_ffmpeg_test_signal.sh
- ops/integration_enforcement.sh
- docs/runbooks/DFC_PPV_ONE_CLICK_ROLLBACK.md
- tests/playwright/player-poster.spec.ts

Recommended workspace shape for app layering:

```text
/repo-root
  /apps/web
  /apps/flutter_app
  /packages/ui
  /ops
  /tests/playwright
  /.github/workflows
  /docs/architecture
  /docs/runbooks
```

## Staging Gate and Smoke Integration

### Run production gate checks

```bash
npm run ppv:gate
```

### Bootstrap live streaming lab resources

```bash
npm run live:lab:setup -- champions-collide-2026
```

### Push FFmpeg test signal

```bash
npm run live:lab:ffmpeg -- rtmp://<input-host>/<stream-key>
```

### Run poster checks

```bash
bash ops/check_posters.sh dfc-media-bucket champions-collide-2026 edge-us.cdn.dfc.example.com
```

### Run mux smoke

```bash
bash ops/mux_smoke.sh
```

### Run Playwright smoke

```bash
npx playwright test tests/playwright/player-poster.spec.ts --project=chromium
```

### Run weekly sweep

```bash
bash ops/weekly_sweep.sh champions-collide-2026
```

### Enforce full integration lane (gate + sweep)

```bash
npm run integration:enforce -- champions-collide-2026
```

## Layer-by-Layer Integration Checklist

### Ingest

- [ ] RTMP or SRT input configured.
- [ ] Encoder test signal verified.
- [ ] Backup ingest path documented.

### Transcoding and packaging

- [ ] Channel outputs HLS and DASH.
- [ ] ABR ladder validated for target devices.
- [ ] Segment duration tuned for latency target.

### Origin and CDN

- [ ] GCS object path exists and is readable.
- [ ] Media CDN origin points at correct event path.
- [ ] CDN endpoint serves master.m3u8 and media assets with 200.
- [ ] Purge and prewarm steps documented and tested.

### Player and entitlements

- [ ] Server-side entitlement check blocks non-entitled playback.
- [ ] Entitled playback succeeds for test token.
- [ ] Playwright smoke passes for poster, CTA, and manifest reachability.

### Payments

- [ ] Checkout success path grants entitlement idempotently.
- [ ] Receipt and entitlement records are reconcilable.
- [ ] Device and region fallback policy documented.

### Social and clips

- [ ] Clip pipeline writes to storage and serves through CDN.
- [ ] Moderation state required before publish.

### Maps and venue pages

- [ ] Maps key restricted by referrer/domain.
- [ ] Venue page has stable map and directions path.

### AI and analytics

- [ ] Playback and commerce telemetry emitted.
- [ ] Analytics store receives startup, rebuffer, entitlement, checkout events.

### SRE and security

- [ ] Dashboards and alerts configured.
- [ ] Synthetic checks available.
- [ ] Rollback runbook and branch protection active.

## Operational Snippets

### One-click rollback flag posture

```bash
curl -X POST "https://flags-api.dfc.example.com/flip" \
  -H "Authorization: Bearer ${FLAG_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"FEATURE_SHELL_V2":false,"FEATURE_PLAY_SKIN":false,"FEATURE_PPV_STORE":true}'
```

### CI run URL pattern

```text
https://github.com/<OWNER>/<REPO>/actions/runs/<RUN_ID>
```

## Immediate Next Steps

1. Ensure required GitHub secrets are configured:
   - GCP_SA_KEY
   - GCP_PROJECT_ID
   - ENTITLEMENT_HEALTH_URL
   - MUX_AUTH_URL
   - MUX_API_TOKEN
   - TEST_ENTITLEMENT_TOKEN
   - FLAG_API_TOKEN
   - CDN_API_KEY
2. Push changes to staging and run gate.
3. Save successful run URL as promotion proof.

## Notes

- Keep this lab as the canonical R&D and staging workflow reference.
- Any production promotion should include gate evidence and rollback readiness proof.
