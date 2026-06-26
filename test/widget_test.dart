import 'package:datafightcentral/core/theme/app_colors.dart';
import 'package:datafightcentral/shared/widgets/neon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme and Widgets', () {
    testWidgets('NeonCard renders correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: NeonCard(child: Text('Test Content'))),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
      expect(find.byType(NeonCard), findsOneWidget);
    });

    test('AppColors has correct neon values', () {
      // Verify key colors are defined correctly
      expect(AppColors.neonBlue, const Color(0xFF00D9FF));
      expect(AppColors.neonCyan, const Color(0xFF00FFF0));
      expect(AppColors.neonGreen, const Color(0xFF00FF9D));
      expect(AppColors.neonRed, const Color(0xFFFF2D55));
    });

    test('AppColors gradients are defined', () {
      expect(AppColors.bgGrad, isA<LinearGradient>());
      expect(AppColors.neonGrad, isA<LinearGradient>());
    });
  });
}
