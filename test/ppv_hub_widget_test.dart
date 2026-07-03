import 'package:dfc_app/core/theme/glass_panel.dart';
import 'package:dfc_app/features/ppv/screens/ppv_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PpvHubScreen builds and contains GlassCard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PpvHubScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(GlassCard), findsWidgets);
  });
}
