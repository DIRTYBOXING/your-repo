import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';

import 'package:datafightcentral/features/social/screens/dfc_feed_screen.dart';
import 'package:datafightcentral/shared/services/auth_service.dart';
import 'package:datafightcentral/shared/services/social_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    SocialService.enableDemoModeForTests();
  });

  testWidgets('DFCFeedScreen displays current feed chrome', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
          Provider<SocialService>(create: (_) => SocialService()),
        ],
        child: const MaterialApp(home: DFCFeedScreen()),
      ),
    );

    // The feed initializes async streams/services in initState.
    // Use bounded pumping because the screen has continuous animations.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byType(ListView), findsWidgets);
  });
}
