import 'package:datafightcentral/shared/widgets/dfc_shell_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestShell(double width) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: DFCHomeShellTopBar(
              onOpenMessaging: () {},
              onOpenFriendRequests: () {},
              onOpenDashboard: () {},
              onOpenAccountMenu: () {},
              inboxBadgeStream: Stream.value(2),
              friendRequestBadgeStream: Stream.value(1),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('top bar collapses actions into overflow menu on narrow widths', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestShell(280));
    await tester.pumpAndSettle();

    expect(find.byTooltip('More actions'), findsOneWidget);
    expect(find.byTooltip('Open inbox'), findsNothing);
    expect(find.byTooltip('Open friend requests'), findsNothing);
  });

  testWidgets('top bar shows direct actions on wider widths', (tester) async {
    await tester.pumpWidget(buildTestShell(420));
    await tester.pumpAndSettle();

    expect(find.byTooltip('More actions'), findsNothing);
    expect(find.byTooltip('Open inbox'), findsOneWidget);
    expect(find.byTooltip('Open friend requests'), findsOneWidget);
    expect(find.byTooltip('Open command dashboard'), findsOneWidget);
  });
}
