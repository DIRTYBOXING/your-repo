import 'package:datafightcentral/core/config/router_config.dart' as rc;
import 'package:datafightcentral/features/monetization/screens/promoter_payout_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('ledger row navigates to reconciliation screen', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const PromoterPayoutDashboardScreen(enableLiveDataLoad: false)),
        GoRoute(
          path: '/reconciliation',
          name: rc.RouteConstants.promoterReconciliationPath,
          builder: (context, state) => Scaffold(body: Text('reconciliation:${state.extra as String? ?? 'none'}')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('LEDGER'));
    await tester.pumpAndSettle();

    expect(find.text('Logan Main Event'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('ledger-row-EVT-2026-001')));
    await tester.pumpAndSettle();

    expect(find.text('reconciliation:EVT-2026-001'), findsOneWidget);
  });
}
