import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/dfc_themes.dart';
import 'settings_migration.dart';

/// ════════════════════════════════════════════════════════════════════════
/// Settings Service — Persisted via SharedPreferences
/// Exposes ChangeNotifier so the widget tree can react to changes
/// ════════════════════════════════════════════════════════════════════════
class SettingsService extends ChangeNotifier {
  // ── Keys ──────────────────────────────────────────────────────────────
  static const _kNotifications = 'settings_notifications';
  static const _kEmailNotifications = 'settings_email_notifications';
  static const _kDarkMode = 'settings_dark_mode';
  static const _kAnalytics = 'settings_analytics';
  static const _kThemeMode = settingsThemeModeKey;
  static const _kContentMode = 'settings_content_mode';
  static const _kSensoryMode = 'settings_sensory_mode';

  // ── State ─────────────────────────────────────────────────────────────
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _darkMode = true;
  bool _analyticsEnabled = true;
  bool _loaded = false;
  DFCThemeMode _themeMode = DFCThemeMode.dark;

  /// Content mode: 'family' = standard/lighter view, '18plus' = full mode
  String _contentMode = '18plus';

  /// Sensory mode: 'standard' = soft glow only, 'hardcore' = full haptics + strobes
  String _sensoryMode = 'standard';

  // ── Getters ───────────────────────────────────────────────────────────
  bool get notificationsEnabled => _notificationsEnabled;
  bool get emailNotifications => _emailNotifications;
  bool get darkMode => _darkMode;
  bool get analyticsEnabled => _analyticsEnabled;
  bool get loaded => _loaded;
  DFCThemeMode get themeMode => _themeMode;

  /// Returns 'family' or '18plus'
  String get contentMode => _contentMode;

  /// Quick check — true when 18+ full mode is unlocked
  bool get isAdultMode => _contentMode == '18plus';

  /// Quick check — true when in family-safe mode (default)
  bool get isFamilyMode => _contentMode == 'family';

  /// Sensory mode getter
  String get sensoryMode => _sensoryMode;

  /// True when haptics + flash effects are at full intensity
  bool get isHardcoreMode => _sensoryMode == 'hardcore';

  SettingsService() {
    _loadFromDisk();
  }

  // ── Load ──────────────────────────────────────────────────────────────
  Future<void> _loadFromDisk() async {
    await migrateSettingsIfNeeded();
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool(_kNotifications) ?? true;
    _emailNotifications = prefs.getBool(_kEmailNotifications) ?? true;
    _darkMode = prefs.getBool(_kDarkMode) ?? true;
    _analyticsEnabled = prefs.getBool(_kAnalytics) ?? true;
    final themeName = prefs.getString(_kThemeMode) ?? 'dark';
    _themeMode = DFCThemeMode.values.firstWhere(
      (m) => m.name == themeName,
      orElse: () => DFCThemeMode.dark,
    );
    _contentMode = prefs.getString(_kContentMode) ?? 'family';
    _sensoryMode = prefs.getString(_kSensoryMode) ?? 'standard';
    _loaded = true;
    notifyListeners();
  }

  // ── Setters (persist + notify) ────────────────────────────────────────
  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }

  Future<void> setEmailNotifications(bool value) async {
    _emailNotifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEmailNotifications, value);
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
  }

  Future<void> setAnalytics(bool value) async {
    _analyticsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAnalytics, value);
  }

  Future<void> setThemeMode(DFCThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
    await prefs.setBool(settingsThemeExplicitKey, true);
    await prefs.setInt(settingsVersionKey, currentSettingsVersion);
  }

  /// Set content mode: 'family' or '18plus'
  Future<void> setContentMode(String mode) async {
    _contentMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kContentMode, mode);
  }

  /// Toggle between family and 18+ mode
  Future<void> toggleContentMode() async {
    await setContentMode(_contentMode == 'family' ? '18plus' : 'family');
  }

  /// Set sensory mode: 'standard' or 'hardcore'
  Future<void> setSensoryMode(String mode) async {
    _sensoryMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSensoryMode, mode);
  }

  /// Toggle between standard and hardcore sensory mode
  Future<void> toggleSensoryMode() async {
    await setSensoryMode(_sensoryMode == 'standard' ? 'hardcore' : 'standard');
  }
}
