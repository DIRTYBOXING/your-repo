import 'package:datafightcentral/features/settings/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// UNIT TESTS — SettingsService persistence
/// ═══════════════════════════════════════════════════════════════════════════
void main() {
  group('SettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults are all true', () async {
      final service = SettingsService();
      // Wait for async load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(service.notificationsEnabled, true);
      expect(service.emailNotifications, true);
      expect(service.darkMode, true);
      expect(service.analyticsEnabled, true);
    });

    test('setNotifications persists value', () async {
      final service = SettingsService();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await service.setNotifications(false);
      expect(service.notificationsEnabled, false);

      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_notifications'), false);
    });

    test('setDarkMode persists value', () async {
      final service = SettingsService();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await service.setDarkMode(false);
      expect(service.darkMode, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_dark_mode'), false);
    });

    test('setAnalytics persists value', () async {
      final service = SettingsService();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await service.setAnalytics(false);
      expect(service.analyticsEnabled, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_analytics'), false);
    });

    test('loads persisted values on init', () async {
      SharedPreferences.setMockInitialValues({
        'settings_notifications': false,
        'settings_email_notifications': false,
        'settings_dark_mode': false,
        'settings_analytics': false,
      });

      final service = SettingsService();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(service.notificationsEnabled, false);
      expect(service.emailNotifications, false);
      expect(service.darkMode, false);
      expect(service.analyticsEnabled, false);
    });

    test('notifies listeners on change', () async {
      final service = SettingsService();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      int notifyCount = 0;
      service.addListener(() => notifyCount++);

      await service.setNotifications(false);
      await service.setDarkMode(false);

      expect(notifyCount, 2);
    });
  });
}
