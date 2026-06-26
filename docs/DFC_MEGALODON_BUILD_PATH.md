# DFC Megalodon Build Path

Execution note: the canonical deduplicated execution source of truth now lives in `docs/DFC_MASTER_EXECUTION_CHECKLIST.md`. Use this file for strategy and architecture context, but update the master execution checklist for actual build status.

## Rule Zero

Every content, commerce, and distribution feature in DFC must emit four things:

- metadata
- rights declarations
- audit logs
- payout signals

That is the dividing line between a hobby upload surface and a platform that can scale across promoters, creators, regions, replays, and settlement.

## What Is Implemented Now

This repository now has the first production-grade spine for media ingestion:

- `media_assets` collection-ready schema via `MediaAssetModel`
- image and video ingestion in `MediaUploadService` with:
  - SHA-256 and MD5 hashing
  - rights owner and rights type capture
  - approval and safety status fields
  - auditable storage path generation
  - `media_audit_logs` write on ingest
- event poster uploads wired through the new ingestion flow
- event documents now support canonical `mediaIds` and `posterMediaId`

This is the correct root layer for A, B, and C.

## A. Media Ingestion Pipeline

Goal: every uploaded asset becomes a first-class media record, not just a URL.

Current state:

- event poster ingestion is wired to the shared pipeline
- media assets capture hashes, rights, dimensions, and storage path

Next build steps:

1. Route all post, story, reel, replay, fighter photo, and gym banner uploads through `MediaUploadService.ingestImageAsset()` or `ingestVideoAsset()`.
2. Add derivative generation for thumbnails and responsive poster sizes.
3. Move high-risk processing to workers/functions for virus scan, OCR, and duplicate detection.

## B. Moderation + Rights System

Goal: DFC can prove what was uploaded, who declared rights, and how publication was approved.

Current state:

- media assets already store `rightsOwner`, `rightsType`, `rightsDeclaration`, `approvalStatus`, and `safetyStatus`
- media ingest writes audit logs

Next build steps:

1. Add a dedicated media moderation queue sourced from `media_assets` where `approvalStatus == pendingReview`.
2. Extend moderator tools to approve, reject, quarantine, and annotate media assets.
3. Add takedown workflow fields: `takedownRequestedAt`, `takedownReason`, `quarantinedAt`, `quarantinedBy`.

## C. Metadata Model

Goal: one shared schema powers discovery, moderation, rights, playback, and analytics.

Current state:

- `MediaAssetModel` is the canonical media schema for DFC uploads
- events can now point to canonical media asset IDs instead of raw poster URLs only

Next build steps:

1. Add `licenseProofUrl`, `sourceUrl`, `regionRights`, and `expiresAt` to the asset schema.
2. Add duplicate-detection indexes on `hashSha256`.
3. Expose media asset summaries in promoter dashboards and admin review tools.

## D. Promoter Onboarding + Rights Intake

Goal: a promoter cannot publish at scale without declaring ownership, permissions, and payout identity.

Recommended build:

1. Add rights-intake fields to promoter onboarding:
   - business name
   - rights contact
   - permitted territories
   - license proof upload
2. Require poster upload to choose one:
   - owned
   - licensed
   - permissioned
   - editorial
3. Store onboarding and rights artifacts as media assets or secure documents with audit trails.

## E. Go-Live Streaming Control Room

Goal: DFC runs as an actual event operations surface.

Recommended build:

1. Event-level stream object:
   - ingest endpoint
   - stream key reference
   - preview URL
   - health state
   - start window
   - replay asset ID
2. Stream events should write to operations logs and settlement signals.
3. Replay publishing should create canonical `MediaAssetModel` records of kind `replay` and `highlight`.

## F. Settlement Dashboard

Goal: every commercial event closes with an auditable settlement trail.

Recommended build:

1. Use Stripe Connect v2 for promoter and creator payout entities.
2. Settlement models should track:
   - gross sales
   - refunds
   - disputes
   - reserve holds
   - promoter split
   - creator split
   - fighter split
3. Link payout rows back to event IDs, media campaigns, and referral sources.

## G. Creator Referral Engine

Goal: growth becomes attributable and payable.

Recommended build:

1. Every creator gets a code and referral ledger.
2. Every conversion records:
   - event ID
   - creator ID
   - campaign ID
   - gross/net amount
   - payout status
3. Creator clips and promotional assets should reuse the media asset pipeline so rights and attribution stay aligned.

## Legal Guardrails

- Never treat upload as proof of ownership.
- Require rights declaration at ingestion time.
- Keep immutable audit evidence for moderation and takedown workflows.
- Use canonical media asset IDs in event, post, replay, and campaign data so unpublish/quarantine can propagate safely.
- Keep editorial and licensed content explicitly separate from owned content.

## Recommended Next Execution Order

1. Route social post/stories/reels through the new asset ingestion service.
2. Add media moderation queue screens backed by `media_assets`.
3. Add promoter rights-intake forms and license proof uploads.
4. Add replay/highlight ingestion using the same asset model.
5. Build settlement dashboards only after event, asset, and referral metadata are canonical.
