# 🦄 UNICORN GODMODE: DFC Rapid-Fire Prompts for VS Code + Copilot

## Flutter Components & Social Video Features

// Create a complete Flutter widget for vertical swipeable reels with overlays and engagement buttons.
// Generate VideoOverlay widget UI (likes, comments, title, description, positioned over video).
// Implement a comments drawer for videos with real-time updates and input field.
// Scaffold an upload flow for short videos, including picker, trim UI, progress, and metadata.
// Add error and loading state handling to all video/network widgets in the feed.
// Make a ShortVideoCard with thumbnail, title, and play button for video search results.

## DFC Service Layer — Rapid Scaffold

// Scaffold a new DFC ChangeNotifier singleton service with Firestore CRUD, following the pattern in services.dart barrel.
// Add a new Firestore collection handler with fromMap/toMap, timestamps, and proper error handling.
// Wire a new service into lib/shared/services/services.dart barrel export with hide if needed.
// Create a StreamBuilder-powered screen that listens to a Firestore collection in real time.
// Scaffold a Cloud Function (Node/TS) under functions/ that triggers on Firestore document write.

## DFC Bot Ecosystem

// Add a new Genie persona to lib/features/genie/genie_persona.dart with name, avatar, system prompt, and capabilities list.
// Register a new bot in BotOrchestratorService with capabilities, status, and action logging.
// Scaffold a new bot service following FightCampCoachBotService pattern — singleton, ChangeNotifier, Firestore-backed.
// Add a route to router_config.dart using dfcSlidePage transition and wire it to BottomNav or command center.

## DFC Health & Device Integration

// Scaffold a wearable device connector service (Fitbit/Google Fit/Apple HealthKit) with auth, sync, and data normalization.
// Create a biometric data model (heart rate, HRV, SpO2, sleep, steps) with Firestore serialization.
// Build a real-time health dashboard widget using DesignTokens neon theme and StreamBuilder.
// Add hydration/nutrition tracking with daily targets, reminders, and trend analysis.
// Wire health data into ShidoWisdomEngine for recovery and periodization recommendations.

## DFC Theme & UI — Neon Cyberpunk

// Build a DFC-styled card widget using DesignTokens (bgCard, neonCyan, neonGreen, neonAmber, neonRed).
// Create an animated stat ring widget with glow effect using DFC design tokens.
// Scaffold a new feature screen with AppBar, neon gradient background, and card grid layout.
// Add shimmer loading placeholders matching DFC dark theme for any list/grid screen.

## Firebase & Backend

// Write Firestore security rules for a new collection with auth-based read/write and field validation.
// Add a composite Firestore index to firestore.indexes.json for a multi-field query.
// Scaffold a Firebase Cloud Function (australia-southeast1) that processes a Firestore trigger.
// Create a Firestore batch write utility for seeding test data via DatabaseSeeder pattern.

## Debugging & Dev Velocity

// Pinpoint the source of this build error and suggest a fix: (paste error/stack)
// Run flutter analyze and fix all issues in the output.
// Create unit tests for (Widget/Class/FunctionName) in test/ following existing patterns.
// Add integration test to ensure the video uploader flows end-to-end and handles errors gracefully.
// Trace a null reference crash — show me the widget tree path and the likely null source.

## UI Polish & Accessibility

// Add shimmer loading effect to any screen when data is loading.
// Ensure all overlay buttons have minimum touch target and accessible labels.
// Refactor repeated UI patterns into shared widgets under lib/shared/widgets/.
// Add responsive breakpoints for web/tablet/mobile using LayoutBuilder.

## GoRouter & Navigation

// Add a new GoRoute to router_config.dart with dfcSlidePage transition.
// Wire a new tab into HomeScreen IndexedStack — update \_widgetOptions and BottomNavigationBar in sync.
// Create a nested route with path parameters for detail screens (e.g., /fighters/:fighterId).

## Git / GitHub Actions / CI-CD

// Detect why my GitHub Actions deploy step is failing given this error: (paste error)
// Add a step to azure-pipelines.yml for Flutter web builds with demo/real auth modes.
// Create a pre-commit hook that runs dart format and flutter analyze.

## Copilot Power User

// Explain what this file does in plain English.
// Refactor this file to reduce nesting and improve readability.
// Suggest 3 architectural improvements for maintainability/scalability.
// List all dependencies from pubspec.yaml and describe their roles.
// Show me all exports in services.dart that hide symbols and explain why.

## DFC-Specific Scoped Commands

// @workspace What services handle payments and revenue?
// @workspace Where is the Samurai AI swarm coordinator and what does it orchestrate?
// @workspace List all screens under lib/features/admin/screens/ and summarize their purpose.
// @workspace Find all Firestore collection names used across the codebase.
// @workspace Which services use ChangeNotifier singleton pattern?

---

**Pro Tip**: Paste any of these into Copilot Chat or as code comments — Copilot responds with context-aware DFC solutions.

**Keep adding your own prompts here for unstoppable productivity.**
