import 'package:datafightcentral/core/utils/helpline_directory.dart';
import 'package:flutter_test/flutter_test.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UNIT TESTS — HelplineDirectory country lookup & fallback
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  group('HelplineDirectory', () {
    test('supportedCountries is non-empty and contains expected entries', () {
      expect(HelplineDirectory.supportedCountries.isNotEmpty, true);
      expect(HelplineDirectory.supportedCountries, contains('Australia'));
      expect(HelplineDirectory.supportedCountries, contains('United States'));
      expect(HelplineDirectory.supportedCountries, contains('United Kingdom'));
      expect(HelplineDirectory.supportedCountries, contains('Japan'));
      expect(HelplineDirectory.supportedCountries, contains('Brazil'));
    });

    test('has exactly 20 supported countries', () {
      expect(HelplineDirectory.supportedCountries.length, 20);
    });

    test('forCountry returns correct data for known country', () {
      final au = HelplineDirectory.forCountry('Australia');
      expect(au, isNotNull);
      expect(au!.countryCode, 'AU');
      expect(au.flag, '🇦🇺');
      expect(au.emergency, '000');
      expect(au.helplines.isNotEmpty, true);
      expect(au.helplines.first.name, 'Lifeline');
    });

    test('forCountry is case-insensitive', () {
      final us1 = HelplineDirectory.forCountry('united states');
      final us2 = HelplineDirectory.forCountry('United States');
      final us3 = HelplineDirectory.forCountry('UNITED STATES');
      expect(us1, isNotNull);
      expect(us2, isNotNull);
      expect(us3, isNotNull);
      expect(us1!.countryCode, 'US');
      expect(us2!.countryCode, 'US');
      expect(us3!.countryCode, 'US');
    });

    test('forCountry returns null for unknown country', () {
      expect(HelplineDirectory.forCountry('Narnia'), isNull);
      expect(HelplineDirectory.forCountry('Mars'), isNull);
    });

    test('forCountry returns null for empty or null input', () {
      expect(HelplineDirectory.forCountry(null), isNull);
      expect(HelplineDirectory.forCountry(''), isNull);
    });

    test('fallback has international data', () {
      final fallback = HelplineDirectory.fallback;
      expect(fallback.countryCode, 'INTL');
      expect(fallback.countryName, 'International');
      expect(fallback.flag, '🌍');
      expect(fallback.helplines.isNotEmpty, true);
      expect(fallback.helplines.first.name, 'Find A Helpline');
    });

    test('resolve returns country helplines for known country', () {
      final uk = HelplineDirectory.resolve('United Kingdom');
      expect(uk.countryCode, 'GB');
      expect(uk.emergency, '999');
      expect(uk.helplines.any((h) => h.name == 'Samaritans'), true);
    });

    test('resolve returns fallback for unknown country', () {
      final result = HelplineDirectory.resolve('Atlantis');
      expect(result.countryCode, 'INTL');
      expect(result.countryName, 'International');
    });

    test('resolve returns fallback for null input', () {
      final result = HelplineDirectory.resolve(null);
      expect(result.countryCode, 'INTL');
    });

    test('every supported country has at least one helpline', () {
      for (final country in HelplineDirectory.supportedCountries) {
        final data = HelplineDirectory.forCountry(country);
        expect(data, isNotNull, reason: '$country should be found');
        expect(
          data!.helplines.isNotEmpty,
          true,
          reason: '$country should have helplines',
        );
        expect(
          data.emergency.isNotEmpty,
          true,
          reason: '$country should have emergency number',
        );
      }
    });

    test('HelplineEntry stores name, number, and optional url', () {
      final entry = const HelplineEntry('Test Line', '123', url: 'https://test.com');
      expect(entry.name, 'Test Line');
      expect(entry.number, '123');
      expect(entry.url, 'https://test.com');

      final noUrl = const HelplineEntry('Basic', '456');
      expect(noUrl.url, isNull);
    });
  });
}
