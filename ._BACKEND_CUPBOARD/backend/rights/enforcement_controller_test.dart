// test/backend/rights/enforcement_controller_test.dart
import 'package:flutter_test/flutter_test.dart';

import '../../../backend/rights/controllers/enforcement_controller.dart';
import '../../../backend/rights/enforcement_service.dart';

void main() {
  group('EnforcementController', () {
    final service = EnforcementService();
    final controller = EnforcementController(service);

    test('getRights returns rights JSON structure', () async {
      final json = await controller.getRights('sample-id');
      expect(json['contentId'], equals('sample-id'));
      expect(json.containsKey('allowedRegions'), isTrue);
    });

    test('enforceForRegion returns allowed boolean', () async {
      final json = await controller.enforceForRegion('sample-id', 'US');
      expect(json['allowed'], isA<bool>());
    });

    test('takedown returns request metadata', () async {
      final json = await controller.takedown('sample-id', reason: 'test');
      expect(json.containsKey('requestId'), isTrue);
      expect(json['status'], equals('open'));
    });
  });
}
