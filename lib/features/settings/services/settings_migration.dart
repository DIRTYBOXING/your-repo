import 'package:shared_preferences/shared_preferences.dart';

const String settingsVersionKey = 'settings_version';
const String settingsThemeModeKey = 'settings_theme_mode';
const String settingsThemeExplicitKey = 'theme_explicitly_set';
const int currentSettingsVersion = 2;

Future<void> migrateSettingsIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  final version = prefs.getInt(settingsVersionKey) ?? 0;

  if (version >= currentSettingsVersion) {
    return;
  }

  if (version < 1 && !prefs.containsKey(settingsThemeModeKey)) {
    await prefs.setString(settingsThemeModeKey, 'neon');
  }

  if (version < currentSettingsVersion) {
    final userExplicit = prefs.getBool(settingsThemeExplicitKey) ?? false;
    if (!userExplicit) {
      await prefs.setString(settingsThemeModeKey, 'dark');
    }
    await prefs.setInt(settingsVersionKey, currentSettingsVersion);
  }
}
