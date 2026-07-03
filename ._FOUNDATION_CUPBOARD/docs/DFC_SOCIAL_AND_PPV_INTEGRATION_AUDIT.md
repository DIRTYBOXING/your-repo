# DFC Social And PPV Integration Audit

## Executive Verdict

The current live n8n nodes are not good enough to be called a full DFC brain or a full PPV growth engine.

They are good enough for a proof-of-concept social helper, but not good enough for:

- a production DFC Content Brain
- a multi-platform PPV launch machine
- a serious comparison against Meta, TikTok, and YouTube operating standards

The strongest part of DFC today is the PPV commerce and playback spine in Firebase, Stripe, and Mux. The weakest part is the live hosted n8n workflow and the gap between claimed social targets and real platform-specific publishing support.

## Live n8n Verdict

### Workflow: `DFC brain`

Current live nodes:

1. Webhook Trigger
2. Rewrite with Gemini
3. Prepare Data
4. Post to Facebook Page
5. Send Email via SendGrid
6. Combine Results
7. Format Response
8. Respond to Webhook

Verdict:

- Good enough for: single-lane Facebook posting plus operator email
- Not good enough for: DFC Content Brain, PPV orchestration, platform routing, approval gating, retry handling, analytics, callback tracking, or structured content-pack generation

### Workflow: `DFC Content Brain: AI Fight Content Generator`

Current live coverage:

- PPV event webhook
- user registration webhook
- payment webhook
- Firestore writes
- Slack notices
- Stripe charge creation
- countdown scheduler
- a Stripe AI helper branch

Verdict:

- Too mixed for one workflow
- Not shaped like the DFC app contract
- Not safe as the canonical content-brain lane

## PPV Node Standard

If DFC wants a real PPV operating workflow, these are the nodes or services that matter:

1. Event intake
2. Poster and metadata prep
3. Price and offer selection
4. Checkout session or payment intent
5. Payment webhook confirmation
6. Access grant and entitlement write
7. Playback token or signed URL generation
8. Stream health and replay readiness
9. Social seeding and push notifications
10. Refund, dispute, and audit logging

## What DFC Already Has For PPV

| Capability                          | Current DFC status                           | Source                                       |
| ----------------------------------- | -------------------------------------------- | -------------------------------------------- |
| Hosted Stripe PPV checkout          | Real                                         | `functions/stripe/ppv.js`                    |
| Payment webhooks granting access    | Real                                         | `functions/stripe/payments.js`               |
| Entitlement layer                   | Real                                         | `functions/stripe/entitlements.js`           |
| Signed playback and live ingest     | Real                                         | `functions/streaming/mux.js`                 |
| App-side purchase and access checks | Real                                         | `lib/features/ppv/services/ppv_service.dart` |
| Auto-seeded PPV promo posts         | Real, but social maturity varies by platform | `functions/automation/event_seeder.js`       |

Verdict:

PPV is materially stronger than social publishing. DFC already has the bones of a real owned PPV platform. The weak point is distribution and social automation, not checkout or playback.

## Social Platform Comparison

Assumption for the big four comparison: Facebook, Instagram, TikTok, and YouTube.

| Platform  | DFC current state | What is real now                                                                                                             | What is missing to be enterprise-grade                                                                                                                                                       | Score |
| --------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| Facebook  | Partial but real  | Direct Graph API posting exists in the native publisher, and the live n8n workflow can post to Facebook                      | No robust retry queue, no comments or webhook ingestion, no ad conversion loop, no audience sync, no page insights pipeline, no approval workflow in the live path                           | 6/10  |
| Instagram | Partial           | Native publisher can create and publish an image post through the Instagram Graph flow; DMs also exist elsewhere in the repo | No Reels lane, no Stories lane, no real carousel assembly, no creator collab tags, no insights ingestion, no video publishing workflow                                                       | 5/10  |
| TikTok    | Weak              | DFC names TikTok in target platform lists and has a separate connector-style worker path for clips                           | No real TikTok branch in the native publisher, no official upload flow in the main PPV/social engine, no Spark Ads or creator authorization lane, no mature retry or analytics loop          | 2/10  |
| YouTube   | Weak/manual       | DFC has strong owned streaming through Mux, and the content engine generates YouTube copy                                    | The current native publisher does not automate a real YouTube publish; it returns pending manual for community content, and there is no true Shorts upload branch in the core publish engine | 3/10  |

## Platform-by-Platform Detail

### Facebook

What DFC has:

- Direct page feed or photo posting in the native publisher
- Facebook branch in the live n8n proof-of-concept workflow
- Facebook Messenger outreach support elsewhere in the repo

What Facebook at full power expects:

- page publishing
- image and video workflows
- comments and engagement ingestion
- insights and campaign attribution
- retargeting and paid conversion signals
- webhook-driven state sync

Verdict:

Facebook is the most mature external social lane in DFC today, but it is still closer to a direct posting bot than a full growth operating system.

### Instagram

What DFC has:

- image publishing through Graph API
- caption generation
- Instagram DM tooling

What Instagram at full power expects:

- feed posts
- Reels
- Stories
- carousel publishing
- collaborator tags
- creator partnership and approval workflows
- post insights and engagement sync

Verdict:

Instagram is only half-built. DFC can post an image with caption, but the high-growth lanes for fight promotion are Reels, Stories, and collab distribution. Those are not fully present.

### TikTok

What DFC has:

- TikTok appears in target platform lists
- a separate hypebot worker references a TikTok connector pattern

What TikTok at full power expects:

- short-form video upload
- rate-limit and retry controls
- creator whitelisting
- caption plus sound plus thumbnail handling
- moderation and approval workflow
- performance and engagement telemetry

Verdict:

TikTok is mostly strategic intent right now, not an integrated primary lane in the main DFC publisher.

### YouTube

What DFC has:

- strong owned video posture through Mux for DFC playback
- YouTube copy generation in the native content engine

What YouTube at full power expects:

- Shorts upload
- long-form upload
- thumbnail and metadata publish
- channel analytics
- community posts where available
- live event scheduling and routing

Verdict:

DFC is stronger at owned playback than YouTube automation. That is strategically correct for PPV, but it means YouTube is still a weak acquisition lane in automation terms.

## Big-Four Comparison

Compared to the big four platform standards, DFC currently looks like this:

- Strong on owned PPV checkout, access, and playback
- Medium on Facebook publishing
- Medium-low on Instagram publishing
- Low on TikTok automation
- Low on YouTube automation

That means DFC is not behind on the money lane. It is behind on the platform-distribution lane.

## Blunt Answer

Are the current nodes good enough?

- For a demo: yes
- For a real DFC superpower platform: no

What is good enough already?

- PPV checkout and entitlement backbone
- Mux-based owned playback direction
- Facebook as a first publisher branch

What is not good enough yet?

- TikTok as a real first-class publish lane
- YouTube as a real automated acquisition lane
- Instagram Reels and Stories automation
- a separated DFC Content Brain and DFC Publisher in live n8n
- unified retry, approval, postback, and analytics loops

## Recommended Minimum Next Shape

### DFC Content Brain

1. Webhook request
2. Normalize request
3. Build structured prompt
4. Generate JSON content pack
5. Parse and validate JSON
6. Respond with structured content only

### DFC Publisher

1. Webhook publish request
2. Normalize publish payload
3. Route by platform
4. Facebook branch
5. Instagram branch
6. TikTok branch
7. YouTube branch
8. Retry and dead-letter branch
9. Operator notification
10. Callback and analytics write-back

### PPV Orchestrator

1. Event create
2. Poster build
3. Checkout create
4. Payment confirm
5. Grant access
6. Sign playback
7. Push and drip scheduling
8. Replay ready
9. Social proof callback
10. Settlement and audit update
