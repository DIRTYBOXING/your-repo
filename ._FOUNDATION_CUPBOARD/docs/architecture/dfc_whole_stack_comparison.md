# DFC Whole Stack Comparison

Version: 2026-04-18
Status: current-base vs better-refit comparison
Audience: product, app, PPV, streaming, operator, promoter, backend

Related:

- `docs/DFC_STACK_BLUEPRINT_V1.md`
- `docs/architecture/dfc_ppv_system_snapshot.md`
- `docs/architecture/dfc_streaming_0_90_day_foundation.md`
- `docs/runbooks/DFC_PPV_LIVE_EVENT_OPS_RUNBOOK.md`
- `docs/DFC_DEVELOPER_ONBOARDING.md`
- `docs/DFC_PPV_PUBLIC_READINESS_PLAN.md`

## Purpose

This is the whole DFC stack in one compareable view.

Use it when the question is:

- what do we already have
- what page owns the user experience
- what function lane owns the behavior
- what smoke lane proves it works
- what we are refitting into the better version

This document is not a rewrite plan detached from the repo.
It is the base that is already in front of us, compared against the better version we are shaping.

## Canonical build rule

For DFC, every real unit of work should be thought about as:

`page surface -> function lane -> smoke lane`

If a page has no clear backend owner, it is weak.
If a function lane has no page that proves it, it is floating.
If neither has a smoke lane, it is not ready.

## 1. Whole-stack summary

| Layer                  | Current DFC base                                                                                                       | Better refit target                                                                        |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| App shell              | Flutter app shell with shared drawers, shell top bar, bottom nav, routed feature pages                                 | cleaner shared chrome, stronger trust posture, page-by-page visual consistency             |
| Core tabs              | Feed, PPV, Explore, Social, Profile in the main home shell                                                             | same core shell, but each tab refit as a serious product surface                           |
| Control plane          | Firebase Auth, Firestore, Storage, Functions, Messaging, Analytics, Crashlytics, Performance, Remote Config, App Check | keep as canonical control plane                                                            |
| Money plane            | Stripe across PPV, subscriptions, purchases, payouts, promo paths                                                      | one clearer purchase authority and operator-readable money flow                            |
| Media plane            | Mux live, playback, signed playback, replay hooks                                                                      | keep Mux, harden the DFC-owned watch path around it                                        |
| PPV authority          | strongest current path is Flutter -> Firebase Functions -> Firestore PPV records -> access resolver                    | make that path explicit and remove ambiguity                                               |
| Extra entitlement lane | standalone `entitlements-service` exists and already has smoke coverage                                                | use as compatibility or support lane until convergence is complete, not as competing truth |
| Automation             | Firebase Functions, scripts, n8n, post-event automation, publisher-style flows                                         | keep DFC-owned state authoritative, keep automation replaceable                            |
| Intelligence lane      | `atlas_backend`, predictor services, AI integrations, content systems                                                  | use as support systems, not the source of PPV truth                                        |
| Ops proof              | readiness checks, entitlement smoke, Mux auth smoke, operator runbooks                                                 | make every critical page and function lane provable through repeatable smoke lanes         |

## 2. Page surfaces comparison

### App shell

| Surface                   | Current base                                                                                                                    | Better refit                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Home shell                | `lib/features/home/screens/home_screen.dart` with active tabs Feed, PPV, Explore, Social, Profile                               | same shell, stronger shared chrome, no toy cues, tighter consistency across pages        |
| Shared drawer and top bar | `lib/shared/widgets/dfc_nav_drawer.dart`, `lib/shared/widgets/dfc_shell_top_bar.dart`, `lib/shared/widgets/dfc_bottom_nav.dart` | restrained operator-grade shell, stable actions, cleaner spacing, cleaner state handling |

### Feed and discovery pages

| Surface    | Current base                                                        | Better refit                                                                           |
| ---------- | ------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| Feed       | `lib/features/social/screens/dfc_feed_screen.dart` in the first tab | modern professional social feed, combat-native, cleaner cards and ranking clarity      |
| Explore    | `lib/features/discovery/screens/explore_screen.dart` in the shell   | better category hierarchy, stronger event and creator discovery, less noise            |
| Social hub | `lib/features/social/screens/social_hub_screen.dart` in the shell   | clearer community and connector surfaces without weakening trust in the product        |
| Profile    | `lib/features/profile/screens/profile_screen_v2.dart` in the shell  | cleaner identity, purchase history, subscriptions, creator and promoter proof surfaces |

### PPV pages

| Surface           | Current base                                                                                             | Better refit                                                                                              |
| ----------------- | -------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| PPV hub           | `lib/features/ppv/screens/ppv_hub_screen.dart`                                                           | already moving toward product-grade storefront; continue refining around trust, hierarchy, and conversion |
| Event detail      | `lib/features/ppv/screens/ppv_event_detail_screen.dart`                                                  | clearer event truth, price truth, promo truth, and access state                                           |
| Checkout sheet    | `lib/features/ppv/widgets/ppv_checkout_sheet.dart` and `lib/features/ppv/widgets/ppv_payment_sheet.dart` | one premium checkout experience, minimal friction, no visual clutter                                      |
| Live watch        | `lib/features/ppv/screens/ppv_live_watch_screen.dart`                                                    | stable watch-critical screen with explicit entitlement and playback states                                |
| Store and library | `lib/features/ppv/screens/ppv_store_screen.dart`, PPV library routes                                     | clearer ownership of bought content, replay, and subscription value                                       |
| Command chat      | `/ppv/:ppvId/command-chat` route and related PPV chat surface                                            | optional energy layer behind the trusted paid watch path, never replacing it                              |

### Promoter and operator pages

| Surface                         | Current base                                                                                                                   | Better refit                                                                  |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| Promoter control and dashboards | promoter and PPV dashboard surfaces across `lib/features/promoter/**` and PPV promoter screens                                 | operator-grade campaign, event, payout, and stream control pages              |
| Admin and ops                   | command center and operator surfaces across `lib/features/admin/**`, `lib/features/dashboard/**`, `lib/features/operations/**` | stronger operational clarity, fewer decorative cues, more direct system truth |
| Messaging and social response   | messaging routes and inbox surfaces                                                                                            | clearer response loops between paid events, support, and audience conversion  |

## 3. Function lanes comparison

### PPV purchase lane

| Lane                    | Current base                                                       | Better refit                                                                   |
| ----------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| Main purchase authority | `functions/stripe/ppv.js`, `functions/stripe/payments.js`          | keep as the canonical purchase lane for app-owned PPV                          |
| Client payment entry    | `lib/features/ppv/services/ppv_payment_service.dart`               | continue pushing hosted checkout as the primary web path, remove mixed stories |
| Current reality         | client PaymentIntent flow is retired, hosted checkout is preferred | make the hosted path visually and operationally dominant                       |

### PPV access and entitlement lane

| Lane                      | Current base                                                                                                                         | Better refit                                             |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| Canonical access resolver | `functions/ppv/access_state.js` and `checkPPVAccess` callable usage reflected by `lib/features/ppv/services/ppv_access_service.dart` | one explicit server-side access truth before playback    |
| Access data               | Firestore collections including `ppv_access`, `ppv_purchases`, `ppv_checkout_sessions`, `ppv_payment_intents`                        | clearer canonical purchase ledger and entitlement ledger |
| Current problem           | multiple authorities still coexist                                                                                                   | converge, do not multiply                                |

### Standalone entitlement proxy lane

| Lane              | Current base                                                                                   | Better refit                                                                                 |
| ----------------- | ---------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Dedicated service | `entitlements-service/server.js`                                                               | keep as compatibility, proxy, rehearsal, or advanced token lane until convergence is settled |
| Existing value    | already has readiness and smoke support, useful for local verification and proxy compatibility | do not let it silently become a second business-truth authority                              |

### Streaming and playback lane

| Lane            | Current base                                                                                    | Better refit                                                               |
| --------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Mux integration | `functions/streaming/mux.js`, `functions/streaming/live.js` and watch-side playback integration | keep Mux as the media plane and tighten DFC-owned playback rules around it |
| Watch path      | PPV watch surfaces plus signed playback behavior                                                | make watch states explicit, predictable, and operator-readable             |
| Replay hooks    | post-event automation and replay helpers in `functions/automation/**`                           | faster replay readiness and clearer replay entitlement behavior            |

### Automation and content lanes

| Lane                | Current base                                                        | Better refit                                                                                     |
| ------------------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Firebase automation | callable and scheduled Functions, event and post-event automation   | keep DFC logic in Functions or Cloud Run-style services, not provider-owned workflow state       |
| n8n lane            | workflow glue exists in repo and docs                               | keep it subordinate to Firestore truth, split publisher from content-brain style logic           |
| AI and Python lane  | `atlas_backend`, predictor services, intelligence and media tooling | keep as assistive lane for ranking, intelligence, moderation, and automation, not purchase truth |

## 4. Control-plane comparison

| Plane                       | Current base                                                                              | Better refit                                                                                          |
| --------------------------- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Identity and auth           | Firebase Auth                                                                             | keep                                                                                                  |
| Durable workflow state      | Firestore                                                                                 | keep as system ledger                                                                                 |
| Asset storage               | Cloud Storage                                                                             | keep for posters, uploads, clips, replays, generated assets                                           |
| Runtime execution           | Firebase Functions is strongest current execution lane; standalone services exist in repo | keep Functions for app-triggered logic, move only heavy long-running work into separate service lanes |
| Money                       | Stripe                                                                                    | keep, but collapse duplicate stories around it                                                        |
| Media                       | Mux                                                                                       | keep, do not replace with homegrown live stack                                                        |
| Email and notifications     | SendGrid plus Firebase notifications                                                      | keep as specialized providers                                                                         |
| Containers and infra extras | Docker, Postgres, Redis, n8n, serverless, atlas services                                  | keep as supporting runtime tools where they add leverage without becoming the control plane           |

## 5. Smoke-lane comparison

The smoke lanes already exist. The better version is to make them part of the base definition of done.

| Smoke lane                     | Current base                                                                          | Better refit                                                                             |
| ------------------------------ | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Flutter page safety            | `flutter analyze` on touched pages and shared widgets                                 | required for every page-by-page refit                                                    |
| Entitlement proxy start        | `PPV: Start Entitlement Proxy`                                                        | keep as local runtime entry for PPV verification                                         |
| Runtime readiness              | `PPV: Runtime Readiness Check`                                                        | keep as the strict gate against broken local transport or accidental production fallback |
| Local entitlement smoke        | `PPV: Smoke Entitlement Proxy` and `npm --prefix entitlements-service run test:smoke` | keep as proof that the support lane still behaves                                        |
| Safe Mux check                 | `PPV: Smoke Mux Auth`                                                                 | keep as read-only media validation                                                       |
| Full priority lane             | `PPV: Priority 1 Verification Lane`                                                   | keep as the minimum combined proof for watch-critical backend work                       |
| Destructive operator rehearsal | `PPV: Smoke Mux Credential Delivery`                                                  | keep operator-only, never treat as the default smoke lane                                |

## 6. What stays, what changes

### Keep

- Flutter as the product surface
- Firebase plus GCP as the control plane
- Stripe as the money plane
- Mux as the media plane
- Firestore as the workflow and entitlement ledger
- page-by-page refit as the safest product method
- smoke lanes as the proof layer

### Change

- change mixed PPV authority into one declared purchase and access path
- change noisy premium UI into restrained trusted surfaces
- change disconnected page logic into page -> function -> smoke ownership
- change tribal operator knowledge into runbook-backed operations
- change floating automation into lanes that stay subordinate to DFC state

### Do not do

- do not rebuild live media from scratch
- do not introduce a second entitlement authority
- do not replace DFC-owned watch surfaces with social platform surfaces
- do not do cosmetic page work without checking the backing function lane
- do not claim readiness without the smoke lane proving it

## 7. Page-by-page refit order

If the work proceeds page by page, this is the cleanest compare order:

1. shared shell chrome
2. feed tab
3. PPV hub
4. PPV event detail
5. PPV checkout surfaces
6. PPV live watch
7. explore tab
8. social tab
9. profile tab
10. promoter and operator control pages

Each page should be compared using the same four questions:

1. what does the page promise the user
2. what function lane makes that promise true
3. what smoke lane proves it still works
4. what visual and structural refit makes it feel like DFC at its best

## 8. Practical reading of the stack

The current DFC base is already strong enough to build from.

The app shell exists.
The PPV surfaces exist.
The Firebase Functions lane exists.
The access resolver exists.
The Mux lane exists.
The entitlement proxy and smoke lanes exist.

The better version is not a brand-new stack.
The better version is this stack, cleaned up, made explicit, and made consistent page by page and function by function.
