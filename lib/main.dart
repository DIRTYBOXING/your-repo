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
  // Replace with your actual Stripe Publishable Key (pk_test_... or pk_live_...)
  Stripe.publishableKey = 'pk_test_your_stripe_publishable_key_here';
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
