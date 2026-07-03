import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/router_config.dart';

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
