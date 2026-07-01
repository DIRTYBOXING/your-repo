# DFC Streaming Doctrine v1

## Objective

`streaming_doctrine_v1`

DFC wins combat streaming by owning the event lane end-to-end: ingest, entitlement, playback, replay, and clip velocity. The doctrine is not to be the loudest broadcaster. The doctrine is to be the fastest, most disciplined operator in the paid watch path.

## Platform Position

- DFC does not compete with promotions. DFC promotes promotions.
- DFC should support the full market: major rights holders, independent promoters, local shows, and overlooked cards that would never receive broadcaster-grade exposure on their own.
- External platforms, social platforms, and partner broadcasters are awareness and acquisition lanes. DFC should still own the canonical event page, metadata, artwork resolution, pricing, checkout, entitlement, replay, and operator controls.
- The commercial edge is not giant overhead. The commercial edge is modern infrastructure, integrated AI, human operator judgment, and a combat-native product stack that helps promoters sell more without requiring broadcaster-scale budgets.
- The small promotion is not a side case. The small promotion is a core strategic customer because DFC can convert limited local reach into global discoverability, geo-priced commerce, and long-tail replay value.

## North Star

- Primary watch surface stays on DFC-owned playback for PPV, premium live cards, and replay libraries.
- External platforms are acquisition lanes, not the canonical paid product.
- Startup speed, rights enforcement, replay readiness, and clip turnaround are one operating system.
- Sub-second claims are only valid when the low-latency tier is actually enabled and monitored.

## Default Stack

- Primary platform: Mux live ingest with signed HLS playback on DFC-owned surfaces.
- Secondary platform: SRT and RTMP contribution feeds for venue and production workflows.
- Secondary platform: Replay and clip factory for immediate post-event monetization.
- Conditional platform: WebRTC premium rooms only when `lowLatencyTier` is enabled and the product truly benefits from interactivity.
- Guardrail lane: Entitlements, signed playback, DRM posture, and observability for premium rights windows.

## Decision Rules

1. Default all PPV and premium live events to Mux ingest plus signed HLS playback.
2. Escalate to WebRTC only when latency changes product value, such as judges, corners, watch-alongs, or real-time betting overlays.
3. Keep checkout, entitlement, playback authorization, replay readiness, and post-event clip publishing inside DFC-controlled services.
4. Treat YouTube, TikTok, Instagram, and partner embeds as audience acquisition or highlight distribution, not the main paid experience.
5. Prioritize resilient startup, bitrate ladder quality, and replay availability before expanding protocol surface area.

## Messaging Key

DFC does not try to outspend the incumbents or replace the promotions. DFC out-operates the market by helping every event sell better through one combat-native stack for metadata, promotion, payments, playback, replay, and clip speed.

## Operator Notes

- If a request asks for a third-party primary watch surface, push the canonical experience back to DFC-owned playback.
- If low latency is requested while `lowLatencyTier` is off, tell the truth and optimize HLS startup instead of pretending the stack is already sub-second.
- Premium title fights and replay libraries require entitlement checks, signed playback, DRM posture, and session visibility.
- The event is not finished when the live stream ends. The replay lane and clip lane must be hot within minutes.

## Risk Flags

- `low_latency_tier_disabled`
- `external_platform_requested`
- `rights_guardrails_required`
- `global_scale_resilience_required`

## Interface Contract

Every machine or prompt surface implementing this doctrine should return or display:

- `primaryPlatform`
- `secondaryPlatforms`
- `messagingKey`
- `operatorNotes`
- `riskFlags`

## Placement

- Backend callable: `functions/content/content_brain.js` via `streamingDoctrineV1`
- Flutter operator lens: `lib/features/content_brain/screens/content_brain_screen.dart`
- Prompt layer: `.github/prompts/dfc-brain.prompt.md`
- Prompt interface: `.github/prompts/dfc-brain-interface.prompt.md`
- VS Code heartbeat: `scripts/dfc_brain_heartbeat.mjs` via `.vscode/tasks.json`
