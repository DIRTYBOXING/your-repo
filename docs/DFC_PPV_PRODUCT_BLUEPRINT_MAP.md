# DFC PPV Product Blueprint Map

Purpose: map the DFC PPV master package onto the code that exists today, identify what is already built, and name the highest-value gaps that must be closed for a complete PPV operating system.

---

## 1. Product Surfaces Already In The Repo

### 1.1 Discovery and commerce

| Blueprint block | Current surface                | File                                                    |
| --------------- | ------------------------------ | ------------------------------------------------------- |
| PPV hub         | PPV hub entry                  | `lib/features/ppv/screens/ppv_hub_screen.dart`          |
| PPV marketplace | store listing                  | `lib/features/ppv/screens/ppv_store_screen.dart`        |
| event detail    | event purchase and detail view | `lib/features/ppv/screens/ppv_event_detail_screen.dart` |
| library         | owned or unlocked PPV library  | `lib/features/ppv/screens/ppv_library_screen.dart`      |
| checkout        | checkout and purchase sheet    | `lib/features/ppv/widgets/ppv_checkout_sheet.dart`      |
| access control  | paywall and access wrapper     | `lib/features/ppv/widgets/ppv_gate.dart`                |

### 1.2 Watch, broadcast, and replay

| Blueprint block    | Current surface                        | File                                                                |
| ------------------ | -------------------------------------- | ------------------------------------------------------------------- |
| live watch         | live watch screen                      | `lib/features/ppv/screens/ppv_live_watch_screen.dart`               |
| command chat       | command and event chat                 | `lib/features/ppv/screens/ppv_command_chat_screen.dart`             |
| notification prefs | event reminders and preferences        | `lib/features/ppv/screens/ppv_notification_preferences_screen.dart` |
| playback service   | PPV retrieval and sanitization         | `lib/shared/services/ppv_service.dart`                              |
| Mux integration    | stream status and playback integration | `lib/shared/services/mux_streaming_service.dart`                    |

### 1.3 Promoter operations

| Blueprint block    | Current surface                    | File                                                                                                                |
| ------------------ | ---------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| promoter dashboard | high-level promoter view           | `lib/features/promoter/screens/promoter_dashboard_screen.dart`                                                      |
| control room       | event readiness and launch control | `lib/features/promoter/screens/promoter_control_room_screen.dart`                                                   |
| media upload       | media ingestion entry              | `lib/features/promoter/screens/promoter_media_upload_screen.dart`                                                   |
| poster tooling     | poster builder flow                | `lib/features/promoter/screens/poster_generator_screen.dart`                                                        |
| rights intake      | rights capture                     | `lib/features/promoter/screens/promoter_rights_intake_screen.dart`                                                  |
| event management   | event manager and detail screens   | `lib/features/promoter/screens/event_manager_screen.dart`, `lib/features/promoter/screens/event_detail_screen.dart` |

### 1.4 Monetization and settlement-adjacent surfaces

| Blueprint block           | Current surface                    | File                                                                      |
| ------------------------- | ---------------------------------- | ------------------------------------------------------------------------- |
| payout engine             | creator payout orchestration       | `lib/shared/services/creator_payout_engine.dart`                          |
| payment engine            | promoter revenue and payment logic | `lib/shared/services/stripe_payment_engine.dart`                          |
| promoter payout dashboard | monetization surface               | `lib/features/monetization/screens/promoter_payout_dashboard_screen.dart` |
| promoter reconciliation   | reconciliation surface             | `lib/features/monetization/screens/promoter_reconciliation_screen.dart`   |
| revenue wallet            | wallet surface                     | `lib/features/monetization/screens/revenue_wallet_hub_screen.dart`        |

---

## 2. Blueprint Blocks And Current Status

| Master-package block           | Status  | Evidence                                                                                       |
| ------------------------------ | ------- | ---------------------------------------------------------------------------------------------- |
| launch pack system             | partial | docs and poster tooling exist, but no single in-product pack generator                         |
| activation packs               | partial | social and promoter surfaces exist, but pack issuance is manual                                |
| content pack generation        | partial | social payload docs and automation systems exist, but no unified event pack UI                 |
| promotion calendar             | partial | docs exist, but calendar is not enforced as one workflow                                       |
| landing page blueprint         | partial | PPV event detail exists, but module consistency and trust layout need standardization          |
| poster and sizing blueprint    | partial | templates and media handling exist, but derivative generation and pack exports are not unified |
| countdown automation           | partial | reminders and scheduling patterns exist, but not a single operator-grade countdown console     |
| replay and highlight lifecycle | partial | replay support exists, but post-event launch-pack generation is not standardized               |
| settlement engine              | partial | payout and reconciliation surfaces exist, but dedicated event settlement flow is not finished  |

---

## 3. Highest-Value Product Gaps

### 3.1 Launch-pack generator

What is missing:

- one workflow that generates the launch pack, recipient packs, and countdown assets for a specific event

Suggested implementation home:

- promoter control room
- poster generator and event poster command surfaces

Files likely involved:

- `lib/features/promoter/screens/promoter_control_room_screen.dart`
- `lib/features/promoter/screens/poster_generator_screen.dart`
- `lib/features/promoter/screens/event_poster_command_screen.dart`

### 3.2 Activation distribution center

What is missing:

- one screen where an operator can issue fighter, gym, creator, and sponsor packs with links, copy, and status tracking

Suggested implementation home:

- promoter portal or war room

Files likely involved:

- `lib/features/promoter/screens/promoter_portal_screen.dart`
- `lib/features/promoter/screens/war_room_screen.dart`
- `lib/features/promoter/screens/share_event_screen.dart`

### 3.3 Standardized landing-page modules

What is missing:

- enforced page structure across all PPV event pages for poster, countdown, price, trailer, fight card, replay policy, and trust marks

Suggested implementation home:

- PPV event detail screen

Files likely involved:

- `lib/features/ppv/screens/ppv_event_detail_screen.dart`
- `lib/features/ppv/screens/ppv_event_detail_simple_screen.dart`

### 3.4 Event-to-settlement lifecycle

What is missing:

- one event-level lifecycle that joins purchase counts, access, replay state, referrals, creator attribution, and promoter reconciliation

Suggested implementation home:

- promoter payout dashboard and promoter reconciliation screen

Files likely involved:

- `lib/features/monetization/screens/promoter_payout_dashboard_screen.dart`
- `lib/features/monetization/screens/promoter_reconciliation_screen.dart`
- `lib/shared/services/stripe_payment_engine.dart`
- `lib/shared/services/creator_payout_engine.dart`

### 3.5 Countdown control surface

What is missing:

- a single launch operator surface that shows which countdowns are scheduled, sent, failed, or waiting on media approval

Suggested implementation home:

- promoter control room or command chat

Files likely involved:

- `lib/features/promoter/screens/promoter_control_room_screen.dart`
- `lib/features/ppv/screens/ppv_command_chat_screen.dart`

---

## 4. Recommended Build Order

1. Standardize the PPV landing page so every event can convert cleanly.
2. Build the launch-pack generator tied to canonical approved media.
3. Build the activation distribution center for fighters, gyms, creators, and sponsors.
4. Add countdown orchestration status to the control room.
5. Finish the event-to-settlement ledger and reconciliation flow.

This order matters because launch materials and activation are worthless if the event detail, checkout, and watch flow are not consistent.

---

## 5. Definition Of Done For The Blueprint

The DFC PPV master package is fully productized when an operator can:

1. create or select an event
2. upload approved media
3. generate all launch and activation packs from the event record
4. issue referral links and pack downloads by audience
5. launch countdowns from one control surface
6. direct buyers through a consistent landing page and checkout flow
7. run live, replay, highlights, and settlement from the same event lifecycle

Until then, the blueprint is correct but only partially embodied in the product.
