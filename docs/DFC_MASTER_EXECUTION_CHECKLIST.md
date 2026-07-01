# DFC Master Execution Checklist

Last verified: 2026-04-14
Status: Canonical execution checklist
Rule: Add nothing here until it has been checked against the repo. Do not duplicate items that already exist in code, in shipped commits, or in another active workstream.

## How To Use This

- This is the single master tick list for DFC execution.
- Every item must be one of: `VERIFIED IMPLEMENTED`, `VERIFIED PARTIAL`, `VERIFIED MISSING`, or `DEFERRED`.
- `VERIFIED IMPLEMENTED` means the capability exists in the repo now.
- `VERIFIED PARTIAL` means there is real code or UI for it, but the business loop is not fully closed.
- `VERIFIED MISSING` means there is no canonical working implementation yet.
- Do not open a new task until you first check this list and the referenced files.

## Verified Snapshot

- Verified implemented: 3 major domains are already strong today: PPV commerce, social graph/feed surfaces, and canonical media asset foundations.
- Verified partial: 7 major domains have real code but still need loop-closing work: control plane, media ingestion enforcement, rights moderation, promoter rights intake, broadcast operations, creator monetization, discovery, and AI orchestration.
- Verified missing: 2 high-leverage domains remain missing as canonical systems: settlement visibility and a real goodwill/community engine.

## 1. Core Control Plane

- `VERIFIED PARTIAL` DFC self-diagnostic stack exists.
  Evidence:
  - `lib/dfc_core/dfc_capabilities_report.dart`
  - `lib/dfc_core/dfc_self_diagnostic.dart`
  - `lib/dfc_core/dfc_priority_matrix.dart`
  - `lib/dfc_core/dfc_roadmap_engine.dart`
- `VERIFIED PARTIAL` VS Code control plane exists with launch configs, tasks, and MCP support, but shared workspace policy still has local drift outside the committed cleanup.
  Evidence:
  - `.vscode/tasks.json`
  - `.vscode/launch.json`
  - `.vscode/mcp.json`
  - `.vscode/settings.json`

### Tick List

- [x] Self-diagnostic report, priority matrix, and roadmap engine exist.
- [x] Friend-requests validation task now points at the live social path.
- [ ] Finish control-plane cleanup so the committed workspace policy matches the intended local state.
- [ ] Remove or normalize remaining `.vscode` local drift only after verifying each hunk is repo-safe.

## 2. Media Ingestion, Metadata, And Rights

- `VERIFIED IMPLEMENTED` Canonical media asset spine exists.
  Evidence:
  - `lib/dfc_core/dfc_capabilities_report.dart`
  - `docs/DFC_MEGALODON_BUILD_PATH.md`
- `VERIFIED PARTIAL` Rights-safe moderation pipeline exists on the backend and in moderation surfaces, but end-to-end enforcement is not closed on every publish/render path.
  Evidence:
  - `functions/images/rights.js`
  - `lib/core/config/router_config.dart`
  - `lib/features/moderation/screens/moderation_dashboard_screen.dart`

### Tick List

- [x] Media asset model and canonical ingestion foundation exist.
- [x] Rights approval, rejection, revocation, takedown, and audit logging exist server-side.
- [x] Moderation dashboard route exists.
- [ ] Route every remaining social, story, reel, replay, fighter, and gym upload through the canonical media asset ingestion path.
- [ ] Enforce approval state at every feed and playback surface, not just at ingest/admin layers.
- [ ] Add full duplicate detection, derivative generation, and universal publish gating for all asset types.

## 3. Seed And Feed Pipeline

- `VERIFIED PARTIAL` Feed orchestration and region feed materialization exist.
  Evidence:
  - `functions/feeds/waterfall.js`
  - `functions/materializeRegionFeed.js`
  - `functions/feeds/auto_feed_scheduler.js`
  - `functions/pipeline/sync.js`
- `VERIFIED PARTIAL` Native content publishing exists across multiple channels.
  Evidence:
  - `functions/content/social_publisher.js`
  - `functions/content/content_brain.js`
  - `functions/content/factory.js`

### Tick List

- [x] Waterfall feed scoring and promotion conveyor exists.
- [x] Region feed materialization exists.
- [x] Native social publisher exists with Gemini plus direct platform API flow.
- [ ] Unify all seed inputs into one canonical event -> metadata -> feed -> broadcast -> settlement pipeline contract.
- [ ] Make the DFC in-app feed the same source of truth that drives outbound social distribution.
- [ ] Close the loop so replay, highlights, and results automatically feed back into DFC surfaces and creator/promoter workflows.

## 4. PPV Commerce And Access

- `VERIFIED IMPLEMENTED` PPV event, library, gate, checkout, watch, payment, notification, and access surfaces exist.
  Evidence:
  - `lib/features/ppv/screens/ppv_hub_screen.dart`
  - `lib/features/ppv/screens/ppv_store_screen.dart`
  - `lib/features/ppv/screens/ppv_library_screen.dart`
  - `lib/features/ppv/screens/ppv_live_watch_screen.dart`
  - `lib/features/ppv/widgets/ppv_gate.dart`
  - `lib/features/ppv/widgets/ppv_checkout_sheet.dart`
  - `lib/features/ppv/services/ppv_access_service.dart`
  - `functions/stripe/ppv.js`
  - `functions/stripe/entitlements.js`
  - `functions/entitlement.js`
- `VERIFIED PARTIAL` Dynamic pricing and multi-rail commerce exist, but settlement visibility and region-specific operating rules are not fully unified.
  Evidence:
  - `functions/stripe/dynamic_pricing.js`
  - `functions/paypal/payments.js`
  - `lib/features/ppv/models/ppv_revenue_models.dart`

### Tick List

- [x] Core PPV store, watch, gate, and library are in place.
- [x] Stripe-backed PPV logic exists.
- [x] PayPal order and capture flow exists.
- [x] Round-by-round and regional pricing foundations exist in codebase references and comparison surfaces.
- [ ] Standardize the canonical event -> checkout -> entitlement -> playback -> replay -> settlement lifecycle across all PPV entry points.
- [ ] Verify country-by-country payout/compliance assumptions before promising automated settlement in every region.

## 5. Broadcast And Replay Operations

- `VERIFIED PARTIAL` Mux live stream creation, signed playback, stream disable, and stream-status watching exist.
  Evidence:
  - `functions/streaming/mux.js`
  - `functions/streaming/live.js`
  - `functions/streaming/ppv_expiry.js`
  - `functions/streaming/notifications.js`
  - `lib/features/promoter/screens/promoter_control_room_screen.dart`
- `VERIFIED PARTIAL` Promoter control room exists, including Mux stream credential creation and status surfaces.
  Evidence:
  - `lib/features/promoter/screens/promoter_control_room_screen.dart`

### Tick List

- [x] Mux live stream and signed playback backend exists.
- [x] Promoter control room can issue stream credentials.
- [x] Replay pipeline foundations exist.
- [ ] Close operator-grade go-live workflow: preview confidence, launch state, failure handling, and replay publish state.
- [ ] Enforce rights and approval checks before go-live and replay release.
- [ ] Add one canonical event operations log linking stream events, playback state, rights state, and settlement signals.

## 6. Promoter Onboarding, Rights Intake, And Event Ops

- `VERIFIED PARTIAL` Promoter onboarding, promoter rights intake, promoter portal, and control room surfaces exist.
  Evidence:
  - `lib/features/onboarding/screens/promoter_onboarding_screen.dart`
  - `lib/features/onboarding/controllers/promoter_onboarding_controller.dart`
  - `lib/features/promoter/screens/promoter_portal.dart`
  - `lib/features/promoter/screens/promoter_rights_intake_screen.dart`
  - `lib/features/promoter/screens/promoter_control_room_screen.dart`
  - `functions/sendPromoterEmail.js`

### Tick List

- [x] Promoter onboarding and portal surfaces exist.
- [x] Rights-intake entry point exists.
- [x] SendGrid promoter outreach function exists.
- [ ] Make rights intake mandatory for the full event lifecycle, not optional or informational.
- [ ] Link poster/media approval, stream launch, settlement, and replay state directly to promoter onboarding status.
- [ ] Turn promoter onboarding into a single non-exclusive distribution contract workflow instead of scattered capability islands.

## 7. Social Graph, Community, And Distribution

- `VERIFIED IMPLEMENTED` Social feed, reels, stories, comments, groups, members, friend flows, and cross-platform publishing surfaces exist.
  Evidence:
  - `lib/features/social/screens/social_feed_screen.dart`
  - `lib/features/social/screens/reels_feed_screen.dart`
  - `lib/features/social/screens/create_story_screen.dart`
  - `lib/features/social/screens/comment_thread_screen.dart`
  - `lib/features/social/screens/member_directory_screen.dart`
  - `lib/features/social/screens/friend_requests_screen.dart`
  - `lib/features/social/screens/cross_platform_publish_screen.dart`
  - `lib/widgets/fight_social_feed.dart`

### Tick List

- [x] Core social surfaces exist.
- [x] Member directory is verified rendering cleanly after the recent fix.
- [x] Friend-request analysis task now validates successfully.
- [ ] Consolidate feed ranking and social distribution around one canonical source of truth instead of parallel feed islands.
- [ ] Ensure rights-safe media enforcement is applied to all social publishing paths.
- [ ] Tighten sponsor insertion, promotional coverage logic, and event-aware feed ranking into one explicit engine.

## 8. Creator, Influencer, And Referral Economy

- `VERIFIED PARTIAL` Creator payout engine, creator commerce surfaces, and influencer consent/upload flows exist.
  Evidence:
  - `lib/shared/services/creator_payout_engine.dart`
  - `lib/shared/services/creator_economy_service.dart`
  - `lib/features/creative_hub/screens/creator_hub_dashboard_screen.dart`
  - `lib/features/creator/screens/creator_deal_room.dart`
  - `lib/features/monetization/screens/creator_commerce_screen.dart`
  - `functions/influencer/influencer.js`

### Tick List

- [x] Creator economy hooks exist.
- [x] Influencer consent capture and revocation exist.
- [ ] Build canonical creator referral attribution for PPV, replay, sponsor, and campaign conversions.
- [ ] Connect creator economics directly to settlement visibility instead of demo or isolated service logic.
- [ ] Standardize creator launch packs, referral links, and payout ledgers across events.

## 9. Settlement, Ledger, And Trust

- `VERIFIED PARTIAL` Promoter payout dashboard surface and Stripe reconciliation logic exist, but the canonical cross-role settlement dashboard is still missing.
  Evidence:
  - `lib/features/monetization/screens/promoter_payout_dashboard_screen.dart`
  - `functions/stripe/reconciliation.js`
  - `functions/stripe/connect.js`
  - `functions/automation/prediction_payouts.js`
- `VERIFIED MISSING` Canonical settlement visibility for promoter, fighter, gym, creator, reserve, dispute, and payout status in one place.

### Tick List

- [x] Payout dashboard scaffold exists.
- [x] Stripe Connect and reconciliation foundations exist.
- [ ] Build one authoritative settlement dashboard tied to live event, purchase, refund, dispute, reserve, and payout data.
- [ ] Surface promoter trust, reserve logic, and payout state clearly enough to support repeat bookings.
- [ ] Link creator, fighter, gym, and promoter splits to the same canonical ledger.

## 10. Discovery, Regions, And International Expansion

- `VERIFIED PARTIAL` Region materialization, maps, global fight map, and discovery surfaces exist.
  Evidence:
  - `functions/materializeRegionFeed.js`
  - `lib/features/discovery/screens/global_fight_marketplace_screen.dart`
  - `lib/features/earthmap/screens/global_fight_map_screen.dart`
  - `lib/features/maps/screens/community_map_screen.dart`

### Tick List

- [x] Region and map-driven discovery foundations exist.
- [x] Region feed materialization exists.
- [ ] Build region activation playbooks into actual promoter/gym onboarding workflows.
- [ ] Add localized event acquisition, pricing, and creator distribution loops for target regions such as Punjab and Pakistan.
- [ ] Verify payout and compliance rails per territory before automating cross-border settlement promises.

## 11. Sponsorship, Promotional Coverage, And Brand Surfaces

- `VERIFIED PARTIAL` Sponsor dashboards, sponsorship marketplace routes, sponsor deck surfaces, and sponsored feed cards exist.
  Evidence:
  - `lib/features/monetization/screens/sponsor_dashboard_screen.dart`
  - `lib/features/sponsorship/screens/sponsorship_marketplace_screen.dart`
  - `lib/features/sponsorship/screens/sponsor_deck_screen.dart`
  - `lib/features/fightwire/screens/fightwire_screen.dart`
  - `lib/features/factory/screens/fight_factory_screen.dart`

### Tick List

- [x] Sponsor-facing and sponsored-content surfaces exist.
- [x] Promotional coverage concepts appear across feed, marketplace, and promoter/event tooling.
- [ ] Unify sponsor inventory, campaign attribution, and promotional coverage metrics into one measurable system.
- [ ] Connect sponsor surfaces to creator referrals, event promotion packs, and settlement reporting.

## 12. AI And Automation

- `VERIFIED PARTIAL` AI orchestration, AI content generation, AI social publisher, and multiple AI-assisted product surfaces exist.
  Evidence:
  - `functions/ai_orchestrator.js`
  - `functions/ai/content.js`
  - `functions/content/social_publisher.js`
  - `lib/features/ai_brain/screens/ai_brain_screen.dart`
  - `lib/features/social/screens/viral_ai_coach_screen.dart`
- `VERIFIED PARTIAL` AI is present in many islands, but not yet normalized into one explicit cross-platform engine.

### Tick List

- [x] AI-assisted services and UI surfaces exist.
- [x] Native Gemini-driven content publishing exists.
- [ ] Normalize AI hooks across media ingestion, feed ranking, promoter trust, creator growth, and settlement insights.
- [ ] Keep AI assistive and auditable, not free-running beyond role boundaries.

## 13. Goodwill And Community Uplift

- `VERIFIED MISSING` There is no canonical goodwill engine module yet.
  Evidence:
  - `lib/dfc_core/dfc_capabilities_report.dart`

### Tick List

- [ ] Build one real goodwill/community engine instead of scattering uplift intent across screens and seeded copy.
- [ ] Tie sponsor-funded initiatives, gym support programs, and hardship/community campaigns to measurable workflows.

## Execution Order: Do Not Skip

1. Close rights enforcement across all ingestion, feed, broadcast, and replay surfaces.
2. Close promoter onboarding into one mandatory rights-intake and event-ops workflow.
3. Build the canonical settlement dashboard and unified ledger.
4. Unify seed and feed into one event -> metadata -> social -> broadcast -> settlement loop.
5. Canonicalize creator referral attribution and sponsor campaign measurement.
6. Activate region-specific onboarding and pricing loops only after settlement and rights are trustworthy.
7. Build the goodwill/community engine only after the commercial core is stable.

## Explicitly Do Not Duplicate

- Do not build another PPV store, social feed, promoter portal, sponsor dashboard, or AI content system unless replacing a verified broken one.
- Do not add new checklists for these same workstreams. Update this file instead.
- Do not mark any item complete without reading the file or running the validation path in the current session.
