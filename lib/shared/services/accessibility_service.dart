import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ACCESSIBILITY SERVICE — Screen Reader, High Contrast, Text Scaling
/// ═══════════════════════════════════════════════════════════════════════════

enum TextScale { small, normal, large, extraLarge }

enum ContrastMode { normal, high, darkHighContrast }

enum ReducedMotionMode { system, off, on }

class AccessibilitySettings {
  final TextScale textScale;
  final ContrastMode contrastMode;
  final ReducedMotionMode reducedMotion;
  final bool screenReaderOptimized;
  final bool boldText;
  final bool hapticFeedback;
  final bool soundEffects;
  final double touchTargetSize;

  const AccessibilitySettings({
    this.textScale = TextScale.normal,
    this.contrastMode = ContrastMode.normal,
    this.reducedMotion = ReducedMotionMode.system,
    this.screenReaderOptimized = false,
    this.boldText = false,
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.touchTargetSize = 48.0,
  });

  AccessibilitySettings copyWith({
    TextScale? textScale,
    ContrastMode? contrastMode,
    ReducedMotionMode? reducedMotion,
    bool? screenReaderOptimized,
    bool? boldText,
    bool? hapticFeedback,
    bool? soundEffects,
    double? touchTargetSize,
  }) => AccessibilitySettings(
    textScale: textScale ?? this.textScale,
    contrastMode: contrastMode ?? this.contrastMode,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    screenReaderOptimized: screenReaderOptimized ?? this.screenReaderOptimized,
    boldText: boldText ?? this.boldText,
    hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    soundEffects: soundEffects ?? this.soundEffects,
    touchTargetSize: touchTargetSize ?? this.touchTargetSize,
  );

  Map<String, dynamic> toMap() => {
    'textScale': textScale.name,
    'contrastMode': contrastMode.name,
    'reducedMotion': reducedMotion.name,
    'screenReaderOptimized': screenReaderOptimized,
    'boldText': boldText,
    'hapticFeedback': hapticFeedback,
    'soundEffects': soundEffects,
    'touchTargetSize': touchTargetSize,
  };

  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) =>
      AccessibilitySettings(
        textScale: TextScale.values.firstWhere(
          (t) => t.name == map['textScale'],
          orElse: () => TextScale.normal,
        ),
        contrastMode: ContrastMode.values.firstWhere(
          (c) => c.name == map['contrastMode'],
          orElse: () => ContrastMode.normal,
        ),
        reducedMotion: ReducedMotionMode.values.firstWhere(
          (r) => r.name == map['reducedMotion'],
          orElse: () => ReducedMotionMode.system,
        ),
        screenReaderOptimized: map['screenReaderOptimized'] ?? false,
        boldText: map['boldText'] ?? false,
        hapticFeedback: map['hapticFeedback'] ?? true,
        soundEffects: map['soundEffects'] ?? true,
        touchTargetSize: (map['touchTargetSize'] ?? 48.0).toDouble(),
      );
}

class AccessibilityService with ChangeNotifier {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  bool _initialized = false;
  AccessibilitySettings _settings = const AccessibilitySettings();
  bool _isScreenReaderActive = false;

  static const _prefsKey = 'accessibility_settings';

  bool get initialized => _initialized;
  AccessibilitySettings get settings => _settings;
  bool get isScreenReaderActive => _isScreenReaderActive;

  // Legacy getters for backward compatibility
  bool get highContrastEnabled => _settings.contrastMode != ContrastMode.normal;
  bool get reducedMotion => shouldReduceMotion;
  double get textScale => textScaleFactor;

  double get textScaleFactor {
    switch (_settings.textScale) {
      case TextScale.small:
        return 0.85;
      case TextScale.normal:
        return 1.0;
      case TextScale.large:
        return 1.25;
      case TextScale.extraLarge:
        return 1.5;
    }
  }

  FontWeight get fontWeight =>
      _settings.boldText ? FontWeight.bold : FontWeight.normal;

  bool get shouldReduceMotion {
    switch (_settings.reducedMotion) {
      case ReducedMotionMode.system:
        return false;
      case ReducedMotionMode.off:
        return false;
      case ReducedMotionMode.on:
        return true;
    }
  }

  Duration get animationDuration =>
      shouldReduceMotion ? Duration.zero : const Duration(milliseconds: 300);

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('♿ AccessibilityService: Initializing...');

    await _loadSettings();
    _detectScreenReader();

    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_prefsKey);
      if (json != null) {
        final map = <String, dynamic>{};
        for (final pair in json.split('|')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            final key = parts[0];
            final value = parts[1];
            if (value == 'true' || value == 'false') {
              map[key] = value == 'true';
            } else if (double.tryParse(value) != null) {
              map[key] = double.parse(value);
            } else {
              map[key] = value;
            }
          }
        }
        _settings = AccessibilitySettings.fromMap(map);
      }
    } catch (e) {
      debugPrint('AccessibilityService: Load settings failed: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _settings.toMap();
      final json = map.entries.map((e) => '${e.key}:${e.value}').join('|');
      await prefs.setString(_prefsKey, json);
    } catch (e) {
      debugPrint('AccessibilityService: Save settings failed: $e');
    }
  }

  void _detectScreenReader() {
    _isScreenReaderActive = false;
  }

  Future<void> updateSettings(AccessibilitySettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  // Legacy methods for backward compatibility
  void setHighContrast(bool enabled) {
    updateSettings(
      _settings.copyWith(
        contrastMode: enabled ? ContrastMode.high : ContrastMode.normal,
      ),
    );
  }

  void setReducedMotionLegacy(bool enabled) {
    updateSettings(
      _settings.copyWith(
        reducedMotion: enabled ? ReducedMotionMode.on : ReducedMotionMode.off,
      ),
    );
  }

  void setTextScaleLegacy(double scale) {
    final textScale = scale <= 0.9
        ? TextScale.small
        : scale <= 1.1
        ? TextScale.normal
        : scale <= 1.35
        ? TextScale.large
        : TextScale.extraLarge;
    updateSettings(_settings.copyWith(textScale: textScale));
  }

  // New API methods
  Future<void> setTextScaleEnum(TextScale scale) async {
    await updateSettings(_settings.copyWith(textScale: scale));
  }

  Future<void> setContrastMode(ContrastMode mode) async {
    await updateSettings(_settings.copyWith(contrastMode: mode));
  }

  Future<void> setReducedMotionMode(ReducedMotionMode motion) async {
    await updateSettings(_settings.copyWith(reducedMotion: motion));
  }

  Future<void> setScreenReaderOptimized(bool enabled) async {
    await updateSettings(_settings.copyWith(screenReaderOptimized: enabled));
  }

  Future<void> setBoldText(bool enabled) async {
    await updateSettings(_settings.copyWith(boldText: enabled));
  }

  Future<void> setHapticFeedback(bool enabled) async {
    await updateSettings(_settings.copyWith(hapticFeedback: enabled));
  }

  Future<void> setSoundEffects(bool enabled) async {
    await updateSettings(_settings.copyWith(soundEffects: enabled));
  }

  Future<void> resetToDefaults() async {
    await updateSettings(const AccessibilitySettings());
  }

  /// Get semantic label for DFC-specific icons.
  String semanticLabel(String key) {
    const labels = {
      'pink_shield': 'Victim-safe gym with Pink Shield certification',
      'dfc_partner': 'DFC verified partner gym',
      'elite_badge': 'Elite tier gym',
      'mentor_badge': 'Gym with resident mentor',
      'neon_orb': 'Decorative animated orb',
      'live_indicator': 'Live fight in progress',
      'ppv_badge': 'Pay-per-view event',
    };
    return labels[key] ?? key;
  }

  /// WCAG 2.1 AA contrast ratio checker.
  bool meetsContrastRatio(Color foreground, Color background) {
    final fLuminance = foreground.computeLuminance();
    final bLuminance = background.computeLuminance();
    final ratio = (fLuminance > bLuminance)
        ? (fLuminance + 0.05) / (bLuminance + 0.05)
        : (bLuminance + 0.05) / (fLuminance + 0.05);
    return ratio >= 4.5; // WCAG AA standard for normal text
  }

  ColorScheme getHighContrastColorScheme(Brightness brightness) {
    if (_settings.contrastMode == ContrastMode.normal) {
      return brightness == Brightness.dark
          ? const ColorScheme.dark()
          : const ColorScheme.light();
    }

    return _settings.contrastMode == ContrastMode.darkHighContrast
        ? const ColorScheme.dark(
            primary: Colors.yellow,
            secondary: Colors.cyan,
            surface: Colors.black,
            error: Colors.red,
            onError: Colors.white,
          )
        : const ColorScheme.highContrastLight(
            primary: Colors.blue,
            secondary: Colors.purple,
            onSecondary: Colors.white,
          );
  }

  Widget wrapWithSemantics(
    Widget child, {
    String? label,
    String? hint,
    String? value,
    bool? button,
    bool? header,
    bool? link,
    bool? image,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      value: value,
      button: button,
      header: header,
      link: link,
      image: image,
      onTap: onTap,
      child: child,
    );
  }

  void announce(
    String message, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, textDirection);
  }

  double get minTouchTarget => _settings.touchTargetSize;

  Widget ensureTouchTarget(Widget child) {
    return SizedBox(
      width: minTouchTarget,
      height: minTouchTarget,
      child: Center(child: child),
    );
  }
}

extension AccessibilityContext on BuildContext {
  AccessibilityService get accessibility => AccessibilityService();

  TextStyle applyAccessibility(TextStyle style) {
    final service = AccessibilityService();
    return style.copyWith(
      fontSize: (style.fontSize ?? 14) * service.textScaleFactor,
      fontWeight: service.settings.boldText
          ? FontWeight.bold
          : style.fontWeight,
    );
  }
}
