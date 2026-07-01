# ⚠️ Note for AI agents and developers

#

# This file contains markdown links to project files and documentation for reference/documentation purposes only. These links are NOT meant to be resolved as local files from the `.github` directory. Ignore any VS Code or linter warnings about missing files—they are not errors and do not affect the codebase or build process.

# DataFightCentral AI Guide

## Architecture & Entry

## Data & Models

- Firestore naming, validation rules, and dropdown enums sit in [lib/core/constants/app_constants.dart](lib/core/constants/app_constants.dart); extend these lists before persisting new collections or roles.
- Data models live under [lib/shared/models](lib/shared/models) and usually extend `Equatable`. Prefer constructing Firestore mappers similar to [user_model.dart](lib/shared/models/user_model.dart) and [fighter_model.dart](lib/shared/models/fighter_model.dart) to keep serialization consistent.
- Review [docs/DATA_MODELS.md](docs/DATA_MODELS.md) and [docs/FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md) before introducing new fields so indexes and security rules stay aligned.

## Services & Integrations

- Firestore logic is encapsulated in [lib/shared/services](lib/shared/services); update [services.dart](lib/shared/services/services.dart) when you add a service so feature layers can `import 'services.dart'`.
- `AuthService` handles registration, consent logging, profile updates, and onboarding flags; respect `AppConstants.authEnabled` toggles so the app can run in demo mode.
- `OnboardingController` in [features/onboarding/controllers](lib/features/onboarding/controllers/onboarding_controller.dart) saves journey metadata to `user_onboarding` and updates `users.onboardingCompleted`; always call `authService.refreshUserProfile()` after writes.
- `PerformanceService` + [shared/models/stats/combat_stats.dart](lib/shared/models/stats/combat_stats.dart) power the dashboard by reading the `fighter_stats/{fighterId}` doc; seed data with [lib/core/utils/database_seeder.dart](lib/core/utils/database_seeder.dart) when Firestore is empty.
- `SocialService` streams `posts` and writes via `createPost`; Feed UI owns filtering/state, so keep service APIs minimal and Firestore-specific.
- `AnalyticsService` wraps `FirebaseAnalytics`; log new flows here instead of calling the SDK directly to keep auditing centralized.

## Feature Modules & UI

- Modules live in [lib/features](lib/features) under domain folders (`dashboard`, `social`, `marketplace`, etc.). Each exposes `screens/` widgets that plug into GoRouter or the `HomeScreen` tab bar.
- [lib/features/home/screens/home_screen.dart](lib/features/home/screens/home_screen.dart) hosts the bottom navigation using an `IndexedStack`; add new tabs by updating `_widgetOptions` and the `BottomNavigationBar` in sync.
- The dashboard ([features/dashboard/screens/dashboard_screen.dart](lib/features/dashboard/screens/dashboard_screen.dart)) demonstrates the pattern: fetch data via a service in `initState`, render cards/charts with `AppTheme`, and route via `context.push` using RouterConfig paths.

## Firebase & Secrets

- Firebase is initialized with generated [lib/firebase_options.dart](lib/firebase_options.dart); keep it updated via `flutterfire configure` whenever you add platforms.
- Firestore security rules ship in [firestore.rules](firestore.rules); redeploy them whenever collections change.
- Authentication + analytics require enabled providers in Firebase Console (see [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md)); Google sign-in is stubbed in `AuthService.signInWithGoogle` and needs OAuth configuration before use.

## Developer Workflow

- Install deps and hydrate Firebase config per [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md): `flutter pub get`, supply `google-services.json`, and optionally run a Firestore seed via `DatabaseSeeder().seedInitialData()` in a throwaway script.
- Local run: `flutter run` (prefer `-d chrome` or `-d android` depending on platform). Common hot reload issues stem from pending Firebase auth setup.
- Deployment commands live in [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md): `flutter build appbundle` for Play Store, `flutter build ios` + Xcode archive for App Store.
- Keep documentation in sync (especially [docs/IMPLEMENTATION_SUMMARY.md](docs/IMPLEMENTATION_SUMMARY.md)) when shipping new pillars so stakeholders see what’s ready.

## Gotchas

- Many lists use placeholder documents like `fighters/current_user`; update these IDs or seed data before demoing dashboards.
- Provider + GoRouter rely on `ChangeNotifier`; don’t perform heavy Firestore operations inside `build`—fetch in services/controllers and expose Futures/Streams to widgets.
- Always prefer shared widgets ([lib/shared/widgets](lib/shared/widgets)) for buttons/text fields to keep UX consistent with the neon theme.

## AI Agent Guardrails (Non-Negotiable)

- Agents must not change panel sizes, shared layout infrastructure, router structure, or core widget architecture unless explicitly requested by a human maintainer.
- Agents should adapt content payloads, imagery, metadata, and ranking only, while preserving existing DFC UI composition and design tokens.
- For feed work, prefer service-layer changes (`lib/shared/services`) over screen-level layout changes.
- Never silently replace existing navigation patterns, `IndexedStack` tab wiring, or reusable shared widgets.

## Automatic Feed Flow (Fight Content)

- Default ingestion flow: `source intake -> normalize -> rank -> publish`.
- Source scope includes combat promotions and media channels (for example UFC, YouTube combat feeds, trusted fight news, and approved studio partners such as Paramount Studio).
- Use `AutoFeedOrchestratorService` for cross-source normalization and keep source trust rules in service constants.
- Keep all external links domain-validated before amplification, and route high-risk content through trust/safety services before promotion.
