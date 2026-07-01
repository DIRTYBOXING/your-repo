import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ADRENALINE CONTROLLER — Haptics, Flash & Sensory Triggers
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Central orchestrator for the "Adrenaline Gate" sensory effects:
///   • Haptic patterns for combat impacts
///   • Flash overlay triggers
///   • Intensity tracking
///
/// Usage:
///   final ctrl = AdrenalineController();
///   ctrl.fireJab();          // light tap
///   ctrl.fireCross();        // double-tap
///   ctrl.fireKO();           // escalating buzz
///   ctrl.updateIntensity(0.85); // sets the hype level
///
/// Respects `sensoryEnabled` toggle from SettingsService.
///
/// ═══════════════════════════════════════════════════════════════════════════
class AdrenalineController extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────
  double _intensity = 0.0;
  bool _sensoryEnabled = true;
  bool _hasVibrator = false;

  double get intensity => _intensity;
  bool get sensoryEnabled => _sensoryEnabled;

  AdrenalineController() {
    _checkVibration();
  }

  Future<void> _checkVibration() async {
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
    } catch (_) {
      _hasVibrator = false;
    }
  }

  // ── Configuration ─────────────────────────────────────────────────────
  void setSensoryEnabled(bool enabled) {
    _sensoryEnabled = enabled;
    notifyListeners();
  }

  void updateIntensity(double value) {
    _intensity = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  // ── Haptic Patterns ───────────────────────────────────────────────────

  /// Light jab — 10ms buzz
  Future<void> fireJab() async {
    if (!_sensoryEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 10);
    } else {
      await HapticFeedback.lightImpact();
    }
  }

  /// Heavy cross — double tap pattern [wait, buzz, wait, buzz]
  Future<void> fireCross() async {
    if (!_sensoryEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(pattern: [0, 50, 10, 50]);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Body shot — medium impact
  Future<void> fireBodyShot() async {
    if (!_sensoryEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 30);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// KO — escalating roar (three increasingly long bursts)
  Future<void> fireKO() async {
    if (!_sensoryEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(pattern: [0, 50, 40, 100, 40, 200]);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Submission lock — sustained buzz
  Future<void> fireSubmission() async {
    if (!_sensoryEnabled) return;
    if (_hasVibrator) {
      await Vibration.vibrate(duration: 300);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  /// Decision/round bell — short signature tap
  Future<void> fireRoundBell() async {
    if (!_sensoryEnabled) return;
    await HapticFeedback.selectionClick();
  }
}
