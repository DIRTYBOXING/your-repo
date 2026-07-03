# Data Fight Central Launch Readiness Checklist

Use this list as the single source of truth for launch-critical flow checks.

## 1) Core PPV and FightPipe Flow

- [x] FightPipe primary event actions route into real PPV flow (`/ppv` and `/ppv/ppv-ibc-03/watch`).
- [x] Replay action from FightPipe routes to PPV watch screen.
- [ ] Confirm all FightPipe event CTAs map to valid PPV events in production data.
- [ ] Validate checkout links open correctly for each PPV card in `PpvHubScreen`.
- [ ] Validate watch route fallback behavior when PPV ID is missing or stale.

## 2) Navigation and Buttons

- [ ] Home top actions: messaging, friends, requests all open correct routes.
- [ ] Bottom navigation tabs remain stable with no state loss on tab switch.
- [ ] No dead-end buttons across home, social, marketplace, maps, profile, settings.
- [ ] Back navigation behaves safely from auth-gated and deep-link screens.

## 3) Messaging and Friends

- [ ] Start chat from friend list and confirm thread opens.
- [ ] Send/receive message in a real or test conversation.
- [ ] Friend request send/accept/decline path completes without stale UI.
- [ ] Empty-state handling is clear for no friends/no messages.

## 4) Feed, Social, and Content Surfaces

- [ ] Social feed loads with no errors on first open.
- [ ] Post creation succeeds and appears in stream.
- [ ] Any ranking/highlight logic shows consistent ordering.
- [ ] External links are valid and safe-domain checked.

## 5) Maps and Location Flow

- [ ] Community map opens on web and mobile.
- [ ] Web fallback UI shows helpful guidance when embedded map is unavailable.
- [ ] User can recover from denied location permission.

## 6) Auth, Subscription, and Payments

- [ ] Login/register/logout all work in selected auth mode.
- [ ] Onboarding completion flag persists and refreshes profile state.
- [ ] Subscription screens render without runtime exceptions.
- [ ] Payment/checkout UX has clear success/failure messaging.

## 7) Quality Gates

- [x] `flutter analyze` passes with no new launch-blocking issues.
- [ ] Critical smoke run on Chrome passes.
- [ ] Critical smoke run on Windows (if target) passes.
- [ ] Manual regression notes captured before release candidate tag.

## 8) Launch Sign-Off

- [ ] Product flow is simple: users can discover, buy, and watch PPV from any entry point.
- [ ] No placeholder text in launch-critical paths.
- [ ] No known blocker left without owner and ETA.
- [ ] Final go/no-go review complete.

## Notes

- Updated during this pass:
  - `lib/features/fight_pipe/screens/fight_pipe_screen.dart`: CTA actions now navigate to real PPV routes.
  - `lib/features/landing/screens/dfc_landing_hero_screen.dart`: hero CTAs, pricing actions, and footer links now route into the real watch, sign-in, and partner funnels.
  - `lib/shared/services/social_service.dart`: demo feed behavior is now limited to demo/guest/anonymous sessions so real-auth runs no longer inherit seeded social content.
  - `lib/shared/services/map_marker_service.dart`: seeded marker fallback is now limited to demo/guest mode so real-auth runs rely on Firestore-backed map data.
  - `lib/app/app_root.dart`: the preview banner is now demo-only and no longer undermines real-auth mode.
  - `lib/shared/models/event_model.dart`, `lib/features/social/widgets/dfc_event_card.dart`, and `lib/features/social/widgets/dfc_live_carousel.dart`: shared event media selection now prefers real non-generic artwork across feed surfaces.
  - `src/index.ts` and `src/routes/audit.ts`: the audit service now reports DB health, validates payloads, enforces request-role checks, and signs entries when `AUDIT_HMAC_SECRET` is configured.
  - `flutter analyze`: clean (`No issues found`).
- Launch-critical blockers are tracked by the unchecked items in sections 1-8 above.
- General TODO backlog surfaced by the orchestrator audit:
  - `lib/features/services/external_feed_service.dart`: duplicate placeholder file exists, but the active runtime imports `lib/shared/services/external_feed_service.dart`.
  - `lib/features/shared/services/auto_feed_orchestrator_service.dart`: duplicate placeholder file exists, but the active runtime imports `lib/shared/services/auto_feed_orchestrator_service.dart`.
  - `lib/features/shared/services/email_campaign_service.dart`: duplicate placeholder file exists, but admin screens import `lib/shared/services/email_campaign_service.dart`.
  - `lib/features/social/screens/group_detail_screen.dart`: edit-navigation TODO still present.
  - `src/feeds/publish.ts`: persistence and moderation write path still TODO.
  - `functions/index_backup.js`: legacy backup file still contains historical TODOs, but it is not part of the active runtime.
- Stale checklist references removed by audit:
  - the earlier references to `lib/shared/services/ppv_service.dart` and `lib/shared/widgets/fightwire_feed.dart` no longer match the current active file layout.
  - the duplicate feature-path service placeholders above are cleanup debt, not proof of missing launch-path implementations.
- Keep this checklist updated after each test run.
