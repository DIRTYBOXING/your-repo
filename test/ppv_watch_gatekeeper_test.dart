import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:datafightcentral/lib/features/ppv/screens/ppv_watch_gatekeeper_screen.dart';
import 'package:datafightcentral/lib/features/ppv/screens/ppv_live_watch_screen.dart';
import 'package:datafightcentral/lib/features/ppv/services/ppv_access_service.dart';
import 'package:datafightcentral/lib/features/ppv/widgets/ppv_gate.dart';

class MockPPVAccessService extends Mock implements PPVAccessService {}

void main() {
  late MockPPVAccessService mockService;

  setUp(() {
    mockService = MockPPVAccessService();
  });

  Future<void> pumpGatekeeper(WidgetTester tester,
      {required bool hasAccess}) async {
    when(() => mockService.hasAccessForUser(
          any<String>(),
          any<String>(),
        )).thenAnswer((_) async => hasAccess);

    await tester.pumpWidget(
      MaterialApp(
        home: PPVWatchGatekeeperScreen(
          ppvId: 'ppv-ibc-03',
          userId: 'test-user',
          accessService: mockService,
        ),
      ),
    );

    // First frame (loading)
    await tester.pump();
    // Resolve async access check
    await tester.pumpAndSettle();
  }

  testWidgets('shows live watch screen when user has access',
      (WidgetTester tester) async {
    await pumpGatekeeper(tester, hasAccess: true);

    expect(find.byType(PPVLiveWatchScreen), findsOneWidget);
    expect(find.byType(PpvGate), findsNothing);
  });

  testWidgets('shows PpvGate paywall when user does NOT have access',
      (WidgetTester tester) async {
    await pumpGatekeeper(tester, hasAccess: false);

    expect(find.byType(PpvGate), findsOneWidget);
    expect(find.byType(PPVLiveWatchScreen), findsNothing);
  });

  testWidgets('shows error + retry when access check throws',
      (WidgetTester tester) async {
    when(() => mockService.hasAccessForUser(
          any<String>(),
          any<String>(),
        )).thenThrow(Exception('network down'));

    await tester.pumpWidget(
      MaterialApp(
        home: PPVWatchGatekeeperScreen(
          ppvId: 'ppv-ibc-03',
          userId: 'test-user',
          accessService: mockService,
        ),
      ),
    );

    await tester.pump(); // loading
    await tester.pumpAndSettle(); // error

    expect(find.textContaining('Unable to check access'), findsOneWidget);
    expect(find.textContaining('network down'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}
