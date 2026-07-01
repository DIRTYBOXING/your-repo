import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/core/constants/content_policy.dart';
import 'package:datafightcentral/shared/services/content_safety_service.dart';

void main() {
  group('ContentPolicy', () {
    test('prohibitedCategories is not empty', () {
      expect(ContentPolicy.prohibitedCategories.isNotEmpty, isTrue);
      expect(
        ContentPolicy.prohibitedCategories.length,
        greaterThanOrEqualTo(10),
      );
    });

    test('reportReasons includes key categories', () {
      final reasons = ContentPolicy.reportReasons;
      expect(reasons, contains('Adult or sexual content'));
      expect(reasons, contains('Gambling or betting'));
      expect(reasons, contains('Stalking or predatory behaviour'));
      expect(reasons, contains('Harassment or bullying'));
    });

    test('encouragedContent is sport-focused', () {
      final enc = ContentPolicy.encouragedContent;
      expect(enc.any((e) => e.toLowerCase().contains('training')), isTrue);
      expect(enc.any((e) => e.toLowerCase().contains('recovery')), isTrue);
    });

    test('enforcement tiers are 1-4', () {
      expect(ContentPolicy.enforcementTiers.keys, containsAll([1, 2, 3, 4]));
    });

    test('crisisHelplines include AU and NZ', () {
      final names = ContentPolicy.crisisHelplines
          .map((h) => h['name']!)
          .toList();
      expect(names.any((n) => n.contains('Australia')), isTrue);
      expect(names.any((n) => n.contains('NZ')), isTrue);
    });

    test('minimumAge is 13', () {
      expect(ContentPolicy.minimumAge, 13);
    });
  });

  group('ContentSafetyService.checkText', () {
    late ContentSafetyService service;

    setUp(() {
      service = ContentSafetyService();
    });

    test('clean sport text passes', () {
      final result = service.checkText(
        'Great sparring session today! Working on my jab-cross combo.',
      );
      expect(result.passed, isTrue);
      expect(result.flaggedTerms, isEmpty);
    });

    test('flags gambling keywords', () {
      final result = service.checkText('Place your bets on the main event!');
      expect(result.passed, isFalse);
      expect(result.flaggedTerms, contains('place your bets'));
    });

    test('flags adult content keywords', () {
      final result = service.checkText('Check my OnlyFans link');
      expect(result.passed, isFalse);
      expect(result.flaggedTerms, contains('onlyfans'));
    });

    test('flags drug keywords', () {
      final result = service.checkText('buy drugs cheap');
      expect(result.passed, isFalse);
      expect(result.flaggedTerms, contains('buy drugs'));
    });

    test('flags toxic content', () {
      final result = service.checkText('kys loser');
      expect(result.passed, isFalse);
      expect(result.flaggedTerms, contains('kys'));
    });

    test('empty text passes', () {
      expect(service.checkText('').passed, isTrue);
      expect(service.checkText('   ').passed, isTrue);
    });

    test('isTextClean returns boolean', () {
      expect(service.isTextClean('Training hard!'), isTrue);
      expect(service.isTextClean('Check onlyfans'), isFalse);
    });

    test('multiple violations detected', () {
      final result = service.checkText(
        'Check my onlyfans, also place your bets on the casino!',
      );
      expect(result.passed, isFalse);
      expect(result.flaggedTerms.length, greaterThanOrEqualTo(3));
    });
  });
}
