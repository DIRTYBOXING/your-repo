# DFC PPV Implementation Checklist

Purpose: turn the PPV product blueprint map into one ranked implementation sequence that can be executed inside the repo without ambiguity.

Use this after strategy is agreed and before opening feature branches or batching work.

---

## 1. Priority Rules

Work in this order:

1. revenue path before promotion polish
2. launch-pack generation before activation automation
3. landing-page standardization before new campaign variants
4. settlement visibility before scaling partner payouts

Do not build low-signal cosmetics ahead of checkout, event detail, launch-pack, or settlement gaps.

---

## 2. Now

These are the highest-value PPV implementation tasks based on the current codebase.

### 2.1 Standardize the event detail and landing-page modules

Goal: every PPV event page should present the same conversion-critical structure.

Deliver:

- hero poster block
- date, venue, timezone block
- trailer or approved clip block
- countdown block
- price and what’s-included block
- replay policy block
- trust marks and promoter block

Primary files:

- `lib/features/ppv/screens/ppv_event_detail_screen.dart`
- `lib/features/ppv/screens/ppv_event_detail_simple_screen.dart`

Definition of done:

- all PPV event pages share one consistent information model
- no event page ships without price, replay policy, or approved poster handling

### 2.2 Build the launch-pack generator

Goal: one operator flow should generate event posters, fight cards, countdown assets, and caption bundles from a canonical event record.

Deliver:

- event-level launch-pack action
- derivative size generation
- launch-pack asset manifest
- export or download entry point

Primary files:

- `lib/features/promoter/screens/promoter_control_room_screen.dart`
- `lib/features/promoter/screens/poster_generator_screen.dart`
- `lib/features/promoter/screens/event_poster_command_screen.dart`

Definition of done:

- a promoter or operator can generate the launch pack without manually assembling assets from multiple screens

### 2.3 Build the activation distribution center

Goal: issue fighter, gym, creator, promoter, and sponsor packs from one event workspace.

Deliver:

- recipient list per event
- pack status per recipient
- referral link assignment
- copy delivery or export
- send-log or handoff status

Primary files:

- `lib/features/promoter/screens/promoter_portal_screen.dart`
- `lib/features/promoter/screens/war_room_screen.dart`
- `lib/features/promoter/screens/share_event_screen.dart`

Definition of done:

- one event can move from launch-pack generation to outbound activation without leaving the promoter workspace

---

## 3. Next

### 3.1 Countdown control surface

Goal: show what is scheduled, sent, blocked, or failed during the launch window.

Primary files:

- `lib/features/promoter/screens/promoter_control_room_screen.dart`
- `lib/features/ppv/screens/ppv_command_chat_screen.dart`

Definition of done:

- operators can tell whether T-24h, T-6h, T-1h, and live-now assets are actually armed

### 3.2 Event-to-settlement ledger

Goal: connect purchases, referrals, replay state, promoter totals, and payout status at the event level.

Primary files:

- `lib/features/monetization/screens/promoter_payout_dashboard_screen.dart`
- `lib/features/monetization/screens/promoter_reconciliation_screen.dart`
- `lib/shared/services/stripe_payment_engine.dart`
- `lib/shared/services/creator_payout_engine.dart`

Definition of done:

- one event has one visible ledger view for commerce, attribution, and payout status

### 3.3 Post-event replay and highlight pack workflow

Goal: turn replay readiness into a standardized outbound content sequence instead of an ad hoc post-fight process.

Definition of done:

- replay-ready state triggers a replay pack and highlight work queue

---

## 4. Later

### 4.1 Sponsor-specific delivery console

Goal: issue sponsor-safe creative with tracking and placement status.

### 4.2 Operator analytics for pack performance

Goal: compare which pack variants, recipients, and channels drove purchases.

### 4.3 Event-template cloning

Goal: clone a successful PPV package, schedule, and activation map into the next event with minimal setup.

---

## 5. Repo-Backed Delivery Sequence

Execute work in this sequence:

1. landing-page modules
2. launch-pack generator
3. activation distribution center
4. countdown control
5. settlement ledger
6. replay pack automation

This is the ranked implementation checklist for the current PPV blueprint.
