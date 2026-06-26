# Setup Guide

import 'package:firebase_core/firebase_core.dart';
import 'database_seeder.dart';
import '../../firebase_options.dart';
import 'dart:developer' as \_logger;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
options: DefaultFirebaseOptions.currentPlatform,
);
if (AppConstants.demoMode) {
await DatabaseSeeder().seedInitialData();
}
print('✅ Database seeded successfully!');
exit(0);
}

GoRouter router = GoRouter(
routes: [
GoRoute(
path: '/pink-diamond-map',
builder: (context, state) => const PinkDiamondMentorMapScreen(),
),
],
);

## Plug-In & Wired Device Setup

1. Ensure dependencies are up to date (`flutter pub upgrade`).
2. Plug-in module lives in `lib/features/plug_in`.
3. To add new devices:
   - Extend `PlugInService` for device discovery/integration.
   - Use `PlugInController` for state management.
   - Add UI in `PlugInScreen`.
4. Run unit tests in `lib/features/plug_in/plug_in_test.dart`.
5. For hardware integration, add packages (e.g., usb_serial, bluetooth).
