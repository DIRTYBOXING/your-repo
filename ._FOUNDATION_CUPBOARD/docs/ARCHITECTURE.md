# DataFightCentral 2026 AI-Native Architecture

## Core Principle

> DataFightCentral is a centralized **Fight Intelligence, Health, and Promotion platform**
> that supports fighters, promoters, gyms, and fans across the entire journey —
> from **preparation → performance → recovery → opportunity → legacy**.
>
> **AI = support system, not authority.**
> **Data = context, not obsession.**
> **People = the priority.**

---

## 1. Global App Structure

```
/auth          → Sign In / Sign Up / Google
/onboarding    → Role selection (ONE TIME)
/app           → Main shell (everyone enters here)
```

Nothing else is allowed until `/app` is stable.

---

## 2. Folder Structure

```
lib/
├── main.dart                          # Entry point
├── firebase_options.dart              # Firebase config
│
├── app/                               # App shell & routing
│   ├── app_root.dart                  # MaterialApp wrapper
│   ├── app_router.dart                # GoRouter config
│   └── auth_gate.dart                 # Auth state listener
│
├── core/                              # Shared infrastructure
│   ├── config/                        # Environment configs
│   ├── constants/                     # App-wide constants
│   │   └── app_constants.dart         # Roles, enums, flags
│   ├── theme/                         # Design system
│   │   └── app_theme.dart             # Colors, typography
│   └── utils/                         # Helpers
│       └── database_seeder.dart       # Demo data
│
├── shared/                            # Reusable components
│   ├── models/                        # Data models
│   │   ├── user_model.dart
│   │   ├── fighter_model.dart
│   │   ├── signal_model.dart          # FightWire signals
│   │   └── stats/
│   │       └── combat_stats.dart
│   ├── services/                      # Firebase & API
│   │   ├── services.dart              # Barrel export
│   │   ├── auth_service.dart
│   │   ├── fighter_service.dart
│   │   ├── performance_service.dart
│   │   ├── social_service.dart
│   │   └── analytics_service.dart
│   └── widgets/                       # Shared UI
│       ├── widgets.dart               # Barrel export
│       ├── signal_card.dart           # SignalCard system
│       ├── neon_button.dart
│       └── gradient_card.dart
│
└── features/                          # Feature modules
    │
    ├── auth/                          # Authentication
    │   ├── screens/
    │   │   ├── sign_in_screen.dart
    │   │   ├── sign_up_screen.dart
    │   │   └── google_sign_in_screen.dart
    │   └── controllers/
    │       └── auth_controller.dart
    │
    ├── onboarding/                    # First-time setup
    │   ├── screens/
    │   │   └── onboarding_screen.dart
    │   └── controllers/
    │       └── onboarding_controller.dart
    │
    ├── home/                          # App shell
    │   └── screens/
    │       └── home_screen.dart       # Bottom nav + IndexedStack
    │
    ├── dashboard/                     # Command Center
    │   └── screens/
    │       └── command_center_screen.dart
    │
    ├── training/                      # Training & Health (flagship)
    │   └── screens/
    │       └── training_dashboard_screen.dart
    │
    ├── social/                        # FightWire
    │   └── screens/
    │       ├── feed_screen.dart       # Preview on dashboard
    │       └── fightwire_screen.dart  # Full page with tabs
    │
    ├── wellness/                      # Mental Health & Support
    │   └── screens/
    │       └── wellness_screen.dart
    │
    ├── culture/                       # Culture & Honours
    │   └── screens/
    │       └── culture_screen.dart
    │
    ├── discovery/                     # Maps & Gyms
    │   └── screens/
    │       └── discovery_screen.dart
    │
    ├── profile/                       # User profile
    │   └── screens/
    │       └── profile_screen.dart
    │
    ├── promoter/                      # Promoter tools (future)
    │   └── screens/
    │       └── promoter_dashboard_screen.dart
    │
    └── partner_portal/                # Business tools (future)
        └── screens/
            └── partner_screen.dart
```

---

## 3. Dashboard Structure (Command Center)

The dashboard answers: **"What do I need to know right now?"**

### A. Readiness Snapshot (Top)

Purpose: "Am I okay to push today?"

| Metric        | Source                | Widget          |
| ------------- | --------------------- | --------------- |
| Resting HR    | Device or manual      | `ReadinessCard` |
| Sleep Quality | Self-report or device | `ReadinessCard` |
| Hydration     | Tap toggle            | `ReadinessCard` |
| Stress Level  | Slider                | `ReadinessCard` |

→ AI summary line below: "Based on your inputs, today looks moderate."

### B. Performance Signals (Middle)

Purpose: "What should I know?"

Each signal uses `SignalCard`:

- Status: Green / Amber / Red
- Title
- 1-sentence AI explanation
- One suggested action

**Signals:**

- Load vs Recovery
- Injury Risk
- Consistency Score

### C. FightWire Preview (Bottom)

Purpose: "What's happening in the fight world?"

Uses `FightWireSignal` widget:

- Event tonight
- Short-notice replacement
- Camp opening
- Mentor availability

Each item has: Source, Region, Action button.

### D. Insights & Guidance

- AI Coach daily insight
- Mental health reminder (rotating)
- Recovery reminder if red-lined

---

## 4. SignalCard System

### Widget Types

```dart
// Status-based signal card
SignalCard(
  title: 'Load vs Recovery',
  status: SignalStatus.green,  // green | amber | red
  explanation: 'Training balanced with recovery.',
  action: 'View trend',
)

// FightWire live signal
FightWireSignal(
  type: 'Opportunity',
  title: 'Short-notice replacement - 170lbs',
  source: 'Verified Promoter',
  region: 'Las Vegas, NV',
  timeAgo: '2h ago',
  isUrgent: true,
)

// Readiness indicator
ReadinessCard(
  label: 'Resting HR',
  value: '62 bpm',
  icon: Icons.favorite,
  status: SignalStatus.green,
)
```

---

## 5. Auth Flow

### Single Source of Truth

```
users/{uid}
  email: string
  displayName: string
  role: fan | fighter | coach | promoter | gym | clinician
  onboardingComplete: boolean
  createdAt: timestamp
```

### Rules

- ❌ No role-based UI until stable
- ✅ Everyone enters same `/app` shell
- ✅ Role stored ONCE during onboarding
- ✅ `onboardingComplete` gates re-entry

---

## 6. AI Architecture

### AI Roles

| Role      | Purpose                      |
| --------- | ---------------------------- |
| Explainer | Why a graph moved            |
| Reminder  | Water, sleep, deload         |
| Support   | Mental health language       |
| Connector | Suggest mentor, gym, service |

### AI Rules

- ❌ Never predict injuries
- ❌ Never diagnose conditions
- ❌ Never push supplements
- ❌ Never shame users
- ✅ Calm, non-judgmental, non-clinical

---

## 7. Monetization (Clean & Ethical)

### Subscription Tiers

| Tier      | Access                       |
| --------- | ---------------------------- |
| Free      | Awareness + browsing         |
| Fighter   | Analytics + AI coaching      |
| Promoter  | FightWire tools + visibility |
| Supporter | Culture + insights           |

### ❌ Never

- Gambling
- Alcohol promotion
- Violence glorification
- Hidden commissions

---

## 8. Why This Wins

This app:

- ✅ Reduces harm
- ✅ Supports mental health
- ✅ Creates opportunity
- ✅ Amplifies promoters
- ✅ Respects fighters

**Funding Eligibility:**

- Google Health grants
- Mental health funding
- Sports innovation funding

---

_Last updated: February 2026_
