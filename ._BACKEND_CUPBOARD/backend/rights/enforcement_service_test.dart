// test/backend/rights/enforcement_service_test.dart
import 'package:flutter_test/flutter_test.dart';

import '../../../backend/rights/enforcement_service.dart';

void main() {
  group('EnforcementService', () {
    final service = EnforcementService();

    test('loadContentRights returns a ContentRights stub', () async {
      final rights = await service.loadContentRights('sample-id');
      expect(rights, isNotNull);
      expect(rights?.contentId, equals('sample-id'));
    });

    test('evaluateForRegion allows known region', () async {
      final result = await service.evaluateForRegion('sample-id', 'US');
      expect(result.allowed, isTrue);
      expect(result.reason, equals('allowed'));
    });

    test('evaluateForRegion blocks unknown region', () async {
      final result = await service.evaluateForRegion('sample-id', 'ZZ');
      expect(result.allowed, isFalse);
      expect(
        result.reason,
        anyOf(equals('region_blocked'), equals('no_rights_found')),
      );
    });
  });
}
