# DFC Promoter Package
# Version: 2026.2 | Status: Ready for Outreach

## Positioning

### One-line pitch
Sell more seats, keep your brand. DFC powers live PPV with secure checkout, reliable streaming, and replay revenue.

### 30-second pitch
DFC helps promoters launch and monetize events fast: branded event pages, secure ticketing, low-latency live delivery, and automatic replay publishing. You keep control of your audience and your brand identity while we run the infrastructure, payments, and delivery workflow.

## Who this is for
- Fight promoters
- Gym owners
- Head coaches and trainers running paid live classes
- Event organizers with regional or national cards

## What promoters get
- Branded event pages with your title treatment, poster, and card details
- Secure checkout and entitlement unlock flow
- Live stream delivery and replay publishing
- Promo-code support for partner campaigns
- Dashboard visibility into conversion, revenue, and replay performance
- Onboarding and live-event readiness support

## How the DFC promoter flow works

### 1) Event intake and setup
Promoter submits event data, media assets, pricing, and schedule.

Input checklist:
- Event title
- Date and local start time
- Venue and city
- Price and capacity
- Main/co-main and card draft
- Live only, replay only, or live plus replay

### 2) Build and publish
DFC provisions event surfaces and media handling.

Platform actions:
- Create event page shell
- Provision secure checkout path
- Generate signed upload URLs for media
- Validate MIME type and size, then scan uploads

### 3) Promote
Promoter uses outreach kit and social assets.

Optional DFC assist:
- Discovery placement
- Localized promotional channels
- Campaign templates

### 4) Go live
Promoter streams to DFC ingest. DFC distributes HLS playback to viewers.

Live checks:
- Ingest health
- Manifest generation
- Playback startup
- Checkout to entitlement path

### 5) Replay and long-tail sales
Post-event pipeline transcodes and publishes replay variants.

Replay options:
- Included with ticket
- Standalone replay product

### 6) Settlement
Revenue and fees are recorded in promoter reporting with recurring settlement cadence.

## Asset requirements

| Asset | Purpose | Specs |
|---|---|---|
| Hero video | Landing hero and social | 1080p MP4, 8 to 12 second loop, H.264, under 10 MB |
| Poster | Social and email header | 1200x628 PNG |
| Thumbnail | Event card surfaces | 640x360 JPG |
| Teaser clips | Reels and short-form | 9 to 15 second vertical MP4, 1080x1920 |
| One-pager PDF | Sales outreach | A4, 300 dpi |
| Email banner | Campaigns | 600x200 PNG |

## Outreach templates

### Initial promoter outreach
Subject: Fill your next event with a cleaner PPV flow

Hi [Name],

We help promoters launch paid live events with branded pages, secure checkout, and replay delivery.

You keep your audience and brand control. DFC handles streaming, payments, and delivery.

If useful, I can send a one-page launch plan for your next event with setup steps and promo templates.

Best,
[Your name]

### Buyer confirmation
Subject: Your ticket is confirmed for [Event]

Thanks for booking.
Join link: [link]
Start time: [time]
Replay: available after event close

Team DFC

### Social post
Live with [Promoter] this [Day] at [Time]. Limited seats. Book now: [link] #LivePPV #CombatSports

### SMS
[Promoter] live event [Day] [Time]. Limited seats. Book: [short link]

## 30-second hero script

### 0-5s
Cut: coach and class/event energy.
Text: Train Live with [Promoter]

### 5-15s
VO: Join live coaching and fight-night coverage with [Promoter]. Real time. Real feedback.

### 15-25s
On-screen flow: Book -> Join Live -> Replay

### 25-30s
CTA: Limited seats. Book now. [URL]

## Technical checklist for product and ops

### Event creation
- Endpoint receives event metadata and returns event URL
- Signed upload URL endpoints for hero and poster assets

### Streaming
- RTMP ingest or encoder integration
- Viewer HLS playback path
- Ingest and manifest health checks

### Replay
- Adaptive HLS transcode ladder
- Thumbnail generation
- Replay metadata write and publish

### Ticketing and payout
- Secure checkout
- Ticket token and entitlement flow
- Confirmation delivery
- Settlement and fee visibility

### Security controls
- Short-TTL signed upload URLs
- Malware/AV scanning on uploaded assets
- Rate limits and quota guardrails

### CI and verification
- Smoke test for landing content and CTA
- Signed upload test with small fixture asset
- Replay manifest presence check
- Artifact retention for visual and smoke reports

## KPIs to track
- Conversion rate (visit to purchase)
- Sell-out rate (sold/capacity)
- Average ticket price
- Replay view rate and replay conversion
- Time to first sale after launch
- Stream health (startup failures, buffering, errors)

## Promoter FAQ

### Do promoters keep the audience?
Yes. Promoters keep brand and audience ownership.

### How do payouts work?
Settlements run on agreed cadence with transparent fee reporting.

### What gear is needed?
Stable internet and supported encoder setup. DFC provides a readiness checklist.

### Can replay be sold separately?
Yes. Replay can be bundled or sold as standalone.

### What support is included?
Onboarding, technical readiness checks, and live-event runbook support.

## DFC contact-safe rules
- Never imply promoter approval until confirmed in writing
- Never publish links publicly before event confirmation
- Never claim guaranteed sales outcomes
- Keep first-contact concise and concrete

## Internal next actions
1. Keep this page as the canonical promoter copy source.
2. Link this package from promoter onboarding surfaces.
3. Add Playwright smoke for promoter hero headline and CTA.
4. Add CI upload smoke for signed URL, storage, and metadata write.
5. Run a 2-3 promoter pilot and update copy from real feedback.
