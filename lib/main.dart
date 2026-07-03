import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/router_config.dart';

// Services
import 'core/auth/persistent_auth_service.dart';
import 'core/auth/biometric_unlock_service.dart';
import 'core/astrohealth/astrohealth_service.dart';
import 'core/matchmaking/matchmaking_radar_service.dart';

void main() async {
  // Ensure Flutter engine is initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase (The single brain of DFC)
  await Firebase.initializeApp();

  // 2. Initialize Stripe
  // Load Stripe Key securely from the environment via dart-define
  const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PK_TEST',
    defaultValue: '',
  );

  if (stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = stripePublishableKey;
  } else {
    debugPrint('WARNING: STRIPE_PK_TEST not found in environment.');
  }
  await Stripe.instance.applySettings();

  // 3. Boot Core Platform Services (AstroHealth, Radar, Auth)
  debugPrint('Booting Core DFC Services...');
  
  // Example initialization for Singleton/Locator-based services
  final persistentAuth = PersistentAuthService();
  final biometrics = BiometricUnlockService();
  final radar = MatchmakingRadarService();
  final astroHealth = AstroHealthService();

  // Perform any async boot-ups needed before UI
  await persistentAuth.hasValidSession();
  
  runApp(const ProviderScope(child: DataFightCentralApp()));
}

class DataFightCentralApp extends StatelessWidget {
  const DataFightCentralApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Data Fight Central',
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
