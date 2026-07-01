# DFC 2.0 System Architecture Map

```
═══════════════════════════════════════════════════════════════════════════════
██████╗  █████╗ ████████╗ █████╗     ███████╗██╗ ██████╗ ██╗  ██╗████████╗
██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗    ██╔════╝██║██╔════╝ ██║  ██║╚══██╔══╝
██║  ██║███████║   ██║   ███████║    █████╗  ██║██║  ███╗███████║   ██║
██║  ██║██╔══██║   ██║   ██╔══██║    ██╔══╝  ██║██║   ██║██╔══██║   ██║
██████╔╝██║  ██║   ██║   ██║  ██║    ██║     ██║╚██████╔╝██║  ██║   ██║
╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝    ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝
                     ██████╗███████╗███╗   ██╗████████╗██████╗  █████╗ ██╗
                    ██╔════╝██╔════╝████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗██║
                    ██║     █████╗  ██╔██╗ ██║   ██║   ██████╔╝███████║██║
                    ██║     ██╔══╝  ██║╚██╗██║   ██║   ██╔══██╗██╔══██║██║
                    ╚██████╗███████╗██║ ╚████║   ██║   ██║  ██║██║  ██║███████╗
                     ╚═════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
═══════════════════════════════════════════════════════════════════════════════
               THE COMBAT SPORTS OPERATING SYSTEM - COMPLETE ARCHITECTURE
═══════════════════════════════════════════════════════════════════════════════
```

## 🏗️ HIGH-LEVEL ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER CLIENT (UI LAYER)                         │
│  ┌─────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │Dashboard│ │  Social  │ │Marketplace│ │ Streaming│ │ Training │           │
│  │ Screens │ │   Feed   │ │   Shop   │ │   PPV    │ │   Hub    │           │
│  └────┬────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘           │
│       └───────────┴────────────┴────────────┴────────────┘                  │
│                                    │                                        │
│                    ┌───────────────┴───────────────┐                        │
│                    │   ROLE DASHBOARD CONTROLLER   │                        │
│                    │  (Fighter/Coach/Gym/Promoter) │                        │
│                    └───────────────┬───────────────┘                        │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        UNIFIED EVENT BUS (DFCEventBus)                      │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                │
│  │ Priority Queue │  │   Topic Subs   │  │    Metrics     │                │
│  │ Critical→Low   │  │  Pub/Sub Hub   │  │   TTL/Replay   │                │
│  └────────────────┘  └────────────────┘  └────────────────┘                │
└────────────────────────────────────┬────────────────────────────────────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         │                           │                           │
         ▼                           ▼                           ▼
┌─────────────────┐      ┌─────────────────────┐      ┌─────────────────┐
│  ATLAS 2.0      │◄────►│    SWARM 3.0        │◄────►│   AI SERVICES   │
│  Intelligence   │      │   Orchestrator      │      │     Layer       │
│  ─────────────  │      │   ───────────────   │      │   ───────────   │
│  • Signal Corr  │      │   • Self-Healing    │      │   • GenieAI     │
│  • Predictions  │      │   • Memory System   │      │   • SentryAI    │
│  • Insights     │      │   • Autonomy Modes  │      │   • MarketingAI │
│  • Health Track │      │   • 53 Agents       │      │   • + 6 more    │
└─────────────────┘      └─────────────────────┘      └─────────────────┘
         │                           │                           │
         └───────────────────────────┼───────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ENGINE LAYER (25 Engines)                      │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  CONTENT ENGINES                                                       │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │ContentScanner│ │FeedRanking   │ │ContentRotate │ │ContentTransf │  │ │
│  │  │(38 bots)     │ │Engine        │ │Engine        │ │ormer         │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  INTELLIGENCE ENGINES                                                  │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │CombatIntel   │ │HealthIntel   │ │SportsScience │ │QuantumOptim  │  │ │
│  │  │Engine        │ │Engine        │ │Engine        │ │Service       │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │  SOCIAL & DISTRIBUTION                                                 │ │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  │ │
│  │  │SocialEngine  │ │SponsorFeed   │ │MetaverseAds  │ │DFCNexus      │  │ │
│  │  │(8 platforms) │ │Engine        │ │Engine        │ │(10 modules)  │  │ │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            SAMURAI ORCHESTRATOR                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     7 GENIE PERSONAS                                 │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │   │
│  │  │ SHIDO   │ │ SAGE    │ │ ROCKY   │ │ VICTOR  │ │ NURTURE │       │   │
│  │  │ Master  │ │ Scholar │ │ Motivate│ │ Victory │ │ Wellness│       │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘       │   │
│  │  ┌─────────┐ ┌─────────┐                                            │   │
│  │  │ PHOENIX │ │ LEGACY  │                                            │   │
│  │  │Comeback │ │ History │                                            │   │
│  │  └─────────┘ └─────────┘                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FIREBASE / CLOUD LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  Firestore   │  │   Storage    │  │    Auth      │  │  Functions   │   │
│  │  (Database)  │  │   (Media)    │  │   (Users)    │  │  (73 APIs)   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  Analytics   │  │  Crashlytics │  │  Remote Cfg  │  │     Stripe   │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 COMPLETE INVENTORY

### 🧠 AI PERSONAS (7)

| Persona     | Emoji | Role                | Specialization                                     |
| ----------- | ----- | ------------------- | -------------------------------------------------- |
| **Shido**   | 🥋    | Master Coach        | Technical analysis, fight strategy, deep knowledge |
| **Sage**    | 📚    | Scholar             | Combat history, statistics, research               |
| **Rocky**   | 🥊    | Motivator           | Encouragement, pump-up, mental prep                |
| **Victor**  | 🏆    | Victory Guide       | Competition prep, winning mindset                  |
| **Nurture** | 💚    | Wellness            | Recovery, nutrition, injury prevention             |
| **Phoenix** | 🔥    | Comeback Specialist | Overcoming setbacks, resilience                    |
| **Legacy**  | 👑    | Historian           | Fighter legacy, records, hall of fame              |

### ⚙️ ENGINES (25)

| Engine                 | File                                  | Function                        |
| ---------------------- | ------------------------------------- | ------------------------------- |
| DFC AI Powerhouse      | `dfc_ai_powerhouse.dart`              | 38 scanner bots + 8 promo bots  |
| Samurai Core           | `samurai_core_engine.dart`            | 6 autonomous pillars            |
| Samurai Orchestrator   | `samurai_orchestrator.dart`           | Persona routing & conversation  |
| Content Transformer    | `samurai_content_transformer.dart`    | 8-platform content variants     |
| Social Engine          | `dfc_social_engine.dart`              | Cross-platform distribution     |
| Content Rotation       | `content_rotation_engine.dart`        | 6-hour auto-swap                |
| Combat Intelligence    | `combat_intelligence_engine.dart`     | Fighter profiling & predictions |
| Health Intelligence    | `health_intelligence_engine.dart`     | Wellness & recovery signals     |
| Sports Science         | `sports_science_engine.dart`          | Biometrics & periodization      |
| Sponsor Feed           | `sponsor_feed_engine.dart`            | Paid content priority           |
| Metaverse Ads          | `metaverse_ad_campaign_engine.dart`   | Virtual ad campaigns            |
| DFC Nexus              | `dfc_nexus.dart`                      | 10-module mega-intelligence     |
| Quantum Optimizer      | `quantum_optimization_service.dart`   | Fight prediction algorithms     |
| Feed Ranking           | `feed_ranking_engine.dart`            | Content prioritization          |
| Auto Feed Orchestrator | `auto_feed_orchestrator_service.dart` | Source normalization            |
| Video Pipeline         | `video_pipeline_service.dart`         | Content ingestion               |
| Performance Service    | `performance_service.dart`            | Athlete stats tracking          |
| Analytics Service      | `analytics_service.dart`              | Firebase analytics wrapper      |
| Notification Service   | `notification_service.dart`           | Push notifications              |
| Streaming Service      | `streaming_service.dart`              | Live event handling             |
| Payment Service        | `payment_service.dart`                | Stripe integration              |
| Moderation Service     | `moderation_service.dart`             | Content safety                  |
| Social Service         | `social_service.dart`                 | Posts & interactions            |
| Auth Service           | `auth_service.dart`                   | User authentication             |
| **[NEW] Event Bus**    | `dfc_event_bus.dart`                  | Unified pub/sub                 |

### 🤖 AI SERVICES (9)

| Service                | Purpose                           |
| ---------------------- | --------------------------------- |
| GenieAI                | Conversational AI with 7 personas |
| SentryAI               | Content moderation & safety       |
| MarketingAI            | Campaign generation               |
| RecommendationAI       | Personalized suggestions          |
| MatchmakingAI          | Fight matchmaking                 |
| PredictionAI           | Fight outcome prediction          |
| NutritionAI            | Diet & meal planning              |
| InjuryPreventionAI     | Risk assessment                   |
| TrainingOptimizationAI | Program design                    |

### 🐝 SWARM AGENTS (53)

**Content Scanners (38)**

- UFC Scanner, Bellator Scanner, ONE Scanner, PFL Scanner
- YouTube Combat, Instagram Combat, Twitter/X Combat
- News Aggregator, Reddit Combat, Discord Combat
- And 28 more specialized scanners...

**Promo Bots (8)**

- Twitter Promo Bot, Instagram Promo Bot
- TikTok Promo Bot, YouTube Promo Bot
- Facebook Promo Bot, LinkedIn Promo Bot
- Discord Promo Bot, Email Campaign Bot

**Coordinator Agents (7)**

- Content Coordinator, Distribution Coordinator
- Health Coordinator, Training Coordinator
- Social Coordinator, Payment Coordinator
- Streaming Coordinator

---

## 🆕 DFC 2.0 ADDITIONS

### Event Bus (`dfc_event_bus.dart`)

The neural highway connecting all 25 engines.

```dart
// Event Categories
enum EventCategory {
  content,    // Feed, posts, media
  combat,     // Fights, predictions, matchmaking
  health,     // Wellness, recovery, injury
  training,   // Load, sessions, periodization
  social,     // Messaging, reactions, follows
  payment,    // Transactions, subscriptions
  streaming,  // Live events, PPV
  moderation, // Safety, flags, bans
  swarm,      // Agent coordination
  system,     // Meta events, health checks
}

// Priority Queues
enum EventPriority {
  critical,   // Safety, payments, emergencies
  high,       // User actions, live events
  normal,     // Standard operations
  low,        // Analytics, logging
  background, // Cleanup, optimization
}
```

**Features:**

- Pub/Sub with topic subscriptions
- Priority queues (critical → background)
- TTL (Time-To-Live) for events
- Replay capability for missed events
- Built-in metrics tracking
- `EventBusEngine` mixin for easy integration

### ATLAS 2.0 (`atlas_2_intelligence.dart`)

The god-brain that reads all signals and predicts the future.

```dart
// Signal Domains
enum SignalDomain {
  combat,     // Fight analysis, predictions
  health,     // Wellness, recovery
  training,   // Load, periodization
  content,    // Feed, engagement
  social,     // Graph, messaging
  commerce,   // Payments, sales
  streaming,  // Live events, viewers
  safety,     // Moderation, compliance
}

// Operational Modes
enum AtlasMode {
  observer,   // Read-only
  advisor,    // Recommendations
  autopilot,  // Auto-execute
  emergency,  // Crisis mode
}
```

**Capabilities:**

- Cross-domain signal correlation
- Predictive analytics
- Actionable insights with suggested actions
- Platform health monitoring
- Pattern detection & memory
- Auto-execute in autopilot mode

### Swarm 3.0 (`swarm_3_orchestrator.dart`)

Next-generation hive mind with memory and autonomy.

```dart
// Autonomy Levels
enum SwarmAutonomy {
  manual,     // Human triggers all
  guided,     // Swarm suggests, human approves
  supervised, // Swarm acts, human can override
  autonomous, // Full auto-pilot
}

// Agent Health
enum AgentHealth {
  healthy,    // All good
  degraded,   // Needs attention
  failing,    // In recovery
  dead,       // Needs manual intervention
}
```

**Features:**

- Self-healing with 5-stage recovery
- Persistent memory per agent
- Learning from success/failure patterns
- Autonomy modes with approval workflow
- ATLAS 2.0 integration

### Role Dashboards (`role_dashboard_controller.dart`)

Personalized views for every DFC user type.

| Role         | Dashboard Focus                                            |
| ------------ | ---------------------------------------------------------- |
| **Fighter**  | Readiness, training, health, upcoming fights, career stats |
| **Coach**    | Athlete roster, team performance, sessions, revenue        |
| **Gym**      | Members, classes, staff, facilities, financials            |
| **Promoter** | Events, fighters, sales, streaming, matchmaking            |
| **Fan**      | Favorites, predictions, social, rewards, watch history     |

---

## 📁 FILE STRUCTURE

```
lib/
├── core/
│   ├── config/
│   │   └── router_config.dart
│   ├── constants/
│   │   └── app_constants.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── dashboard/
│   ├── home/
│   ├── social/
│   ├── marketplace/
│   ├── streaming/
│   ├── training/
│   ├── onboarding/
│   └── search/
└── shared/
    ├── models/
    ├── services/
    │   ├── dfc_event_bus.dart          ← [NEW] Event Bus
    │   ├── atlas_2_intelligence.dart   ← [NEW] ATLAS 2.0
    │   ├── swarm_3_orchestrator.dart   ← [NEW] Swarm 3.0
    │   ├── role_dashboard_controller.dart ← [NEW] Role Dashboards
    │   ├── samurai_swarm_coordinator.dart
    │   ├── dfc_ai_powerhouse.dart
    │   ├── samurai_orchestrator.dart
    │   └── ... (20+ more services)
    └── widgets/

functions/
├── ai/            ← AI functions
├── campaign/      ← Campaign functions
├── config/        ← Config management
├── feeds/         ← Feed functions
├── streaming/     ← Streaming functions
├── stripe/        ← Payment functions
├── index.ts       ← Main exports
└── helpers/       ← Shared utilities

docs/
├── ARCHITECTURE.md
├── AI_SYSTEM_ARCHITECTURE.md
├── DFC_2_SYSTEM_MAP.md  ← [THIS FILE]
└── ...
```

---

## 🔌 DATA FLOW

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           USER INTERACTION                               │
│                   (Tap, Scroll, Post, Purchase, etc.)                   │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER UI LAYER                                   │
│   • Role Dashboard decides what to show                                   │
│   • Event Bus receives user action                                        │
│   • UI updates optimistically                                             │
└───────────────────────────────────┬───────────────────────────────────────┘
                                    │
              ┌─────────────────────┴─────────────────────┐
              │           DFC EVENT BUS                   │
              │   • Routes event to relevant engines      │
              │   • Priority queue processing             │
              │   • Broadcasts to all subscribers         │
              └───────────────────┬───────────────────────┘
                                  │
       ┌──────────────────────────┼──────────────────────────┐
       │                          │                          │
       ▼                          ▼                          ▼
┌─────────────┐          ┌─────────────┐          ┌─────────────┐
│   Engine A  │          │   Engine B  │          │   Engine C  │
│  (Process)  │          │  (Process)  │          │  (Process)  │
└──────┬──────┘          └──────┬──────┘          └──────┬──────┘
       │                        │                        │
       └────────────────────────┼────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                         ATLAS 2.0 (God Brain)                             │
│   • Correlates signals from all engines                                   │
│   • Generates insights & predictions                                      │
│   • Suggests actions to Swarm                                             │
└───────────────────────────────────┬───────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                        SWARM 3.0 (Hive Mind)                              │
│   • Coordinates 53 agents                                                 │
│   • Self-heals failing agents                                             │
│   • Learns from outcomes                                                  │
│   • Executes actions (based on autonomy mode)                             │
└───────────────────────────────────┬───────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                        FIREBASE (Persistence)                             │
│   • Firestore writes                                                      │
│   • Cloud Functions triggers                                              │
│   • Analytics logging                                                     │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 BOOT SEQUENCE

```dart
// 1. Initialize Firebase
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// 2. Boot Event Bus
final eventBus = DFCEventBus();

// 3. Boot ATLAS 2.0
final atlas = Atlas2Intelligence();
await atlas.boot(mode: AtlasMode.observer);

// 4. Boot Swarm 3.0
final swarm = Swarm3();
await swarm.boot(
  autonomy: SwarmAutonomy.guided,
  coordinator: SamuraiSwarmCoordinator(),
);

// 5. Boot Samurai Swarm (legacy coordinator)
final coordinator = SamuraiSwarmCoordinator();
await coordinator.bootSwarm();

// 6. Initialize Role Dashboard
final dashboard = RoleDashboardController();
await dashboard.initialize(userId);

// 7. Run App
runApp(const DataFightCentralApp());
```

---

## 📈 METRICS ENDPOINTS

| Endpoint                          | Data                                                            |
| --------------------------------- | --------------------------------------------------------------- |
| `eventBus.getMetrics()`           | Events processed, queue sizes, subscriber counts                |
| `atlas.getMetrics()`              | Events processed, insights generated, predictions, health score |
| `swarm.getMetrics()`              | Agent health, recoveries, learning cycles, autonomy level       |
| `coordinator.getHealthSnapshot()` | Full swarm health with all 53 agents                            |

---

## 🔒 SECURITY BOUNDARIES

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          PUBLIC (Unauthenticated)                        │
│   • Public event listings                                                │
│   • Fighter profiles (public data)                                       │
│   • General feed content                                                 │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       AUTHENTICATED USER                                 │
│   • Personal dashboard                                                   │
│   • Social interactions                                                  │
│   • Predictions & favorites                                              │
│   • Basic purchases                                                      │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      ROLE-SPECIFIC ACCESS                                │
│   Fighter: Training data, health metrics, fight contracts                │
│   Coach: Athlete roster, session management                              │
│   Gym: Member management, financials                                     │
│   Promoter: Event management, contracts, revenue                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          ADMIN ONLY                                      │
│   • ATLAS mode control                                                   │
│   • Swarm autonomy control                                               │
│   • Moderation overrides                                                 │
│   • System health dashboard                                              │
│   • Agent force-healing                                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## ✅ VERIFICATION CHECKLIST

- [x] Event Bus created with priority queues
- [x] ATLAS 2.0 with cross-domain correlation
- [x] Swarm 3.0 with self-healing & memory
- [x] Role Dashboard Controller for 5 user types
- [x] All components integrate via Event Bus
- [x] Documentation complete

---

_Last Updated: January 2025_
_Version: DFC 2.0_
