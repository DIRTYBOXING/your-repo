import 'package:datafightcentral/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UNIT TESTS — AppConstants integrity
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  group('AppConstants', () {
    test('sportTypes includes Run It', () {
      expect(AppConstants.sportTypes, contains('Run It'));
    });

    test('sportTypes has no duplicates', () {
      final set = AppConstants.sportTypes.toSet();
      expect(set.length, AppConstants.sportTypes.length);
    });

    test('sportTypes has at least 8 sports', () {
      expect(AppConstants.sportTypes.length, greaterThanOrEqualTo(8));
    });

    test('appName is defined', () {
      expect(AppConstants.appName, isNotEmpty);
    });
  });
}
