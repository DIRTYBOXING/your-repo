import 'dart:async';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// BEAST MODE SERVICE — Maximum Promotional Power Amplifier
/// ═══════════════════════════════════════════════════════════════════════════
///
/// When Beast Mode activates, the entire promotional engine goes into OVERDRIVE:
///  • 3x content generation frequency
///  • 2.5x viral potential multiplier
///  • 2x campaign reach amplification
///  • Auto-scheduling aggressive posting cadence
///  • All promotional bots at maximum capacity
///  • Hyper-aggressive SEO boost
///  • Enhanced social media distribution
///  • Real-time performance tracking
///
/// Use when you need to PUSH HARDER THAN EVER:
///  - Event launch week
///  - Ticket sales push
///  - Fighter spotlight campaign
///  - Crisis management / damage control
///  - Viral moment capitalization
///  - Product launch blitz
///  - End-of-quarter revenue push
/// ═══════════════════════════════════════════════════════════════════════════

enum BeastModeIntensity {
  off,
  turbo, // 2x multiplier
  beast, // 3x multiplier
  nuclear, // 5x multiplier (USE CAREFULLY!)
}

extension BeastModeIntensityExt on BeastModeIntensity {
  String get label {
    switch (this) {
      case BeastModeIntensity.off:
        return 'OFF';
      case BeastModeIntensity.turbo:
        return 'TURBO';
      case BeastModeIntensity.beast:
        return 'BEAST';
      case BeastModeIntensity.nuclear:
        return 'NUCLEAR';
    }
  }

  String get emoji {
    switch (this) {
      case BeastModeIntensity.off:
        return '😴';
      case BeastModeIntensity.turbo:
        return '⚡';
      case BeastModeIntensity.beast:
        return '🔥';
      case BeastModeIntensity.nuclear:
        return '💥';
    }
  }

  double get multiplier {
    switch (this) {
      case BeastModeIntensity.off:
        return 1.0;
      case BeastModeIntensity.turbo:
        return 2.0;
      case BeastModeIntensity.beast:
        return 3.0;
      case BeastModeIntensity.nuclear:
        return 5.0;
    }
  }
}

class BeastModeStats {
  final int contentAmplified;
  final int campaignsBoost;
  final double totalReachIncrease;
  final double viralBoost;
  final Duration activeDuration;
  final DateTime? activatedAt;

  const BeastModeStats({
    this.contentAmplified = 0,
    this.campaignsBoost = 0,
    this.totalReachIncrease = 0.0,
    this.viralBoost = 0.0,
    this.activeDuration = Duration.zero,
    this.activatedAt,
  });

  BeastModeStats copyWith({
    int? contentAmplified,
    int? campaignsBoost,
    double? totalReachIncrease,
    double? viralBoost,
    Duration? activeDuration,
    DateTime? activatedAt,
  }) {
    return BeastModeStats(
      contentAmplified: contentAmplified ?? this.contentAmplified,
      campaignsBoost: campaignsBoost ?? this.campaignsBoost,
      totalReachIncrease: totalReachIncrease ?? this.totalReachIncrease,
      viralBoost: viralBoost ?? this.viralBoost,
      activeDuration: activeDuration ?? this.activeDuration,
      activatedAt: activatedAt ?? this.activatedAt,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// BEAST MODE SERVICE — Singleton Power Manager
/// ═══════════════════════════════════════════════════════════════════════════
class BeastModeService extends ChangeNotifier {
  static final BeastModeService _instance = BeastModeService._internal();
  factory BeastModeService() => _instance;
  BeastModeService._internal();

  // ─── State ─────────────────────────────────────────────────────────────
  BeastModeIntensity _intensity = BeastModeIntensity.off;
  BeastModeStats _stats = const BeastModeStats();
  DateTime? _activatedAt;
  Timer? _durationTimer;
  final _controller = StreamController<BeastModeIntensity>.broadcast();

  // ─── Getters ───────────────────────────────────────────────────────────
  BeastModeIntensity get intensity => _intensity;
  bool get isActive => _intensity != BeastModeIntensity.off;
  double get multiplier => _intensity.multiplier;
  BeastModeStats get stats => _stats;
  DateTime? get activatedAt => _activatedAt;
  Stream<BeastModeIntensity> get intensityStream => _controller.stream;

  /// Content generation frequency multiplier
  double get contentFrequencyMultiplier => _intensity.multiplier;

  /// Viral potential boost (additive %)
  double get viralPotentialBoost {
    switch (_intensity) {
      case BeastModeIntensity.off:
        return 0.0;
      case BeastModeIntensity.turbo:
        return 0.25; // +25%
      case BeastModeIntensity.beast:
        return 0.50; // +50%
      case BeastModeIntensity.nuclear:
        return 1.00; // +100%
    }
  }

  /// Campaign reach amplification multiplier
  double get reachMultiplier => _intensity.multiplier * 1.5;

  /// Hype score boost (additive %)
  double get hypeScoreBoost {
    switch (_intensity) {
      case BeastModeIntensity.off:
        return 0.0;
      case BeastModeIntensity.turbo:
        return 0.30; // +30%
      case BeastModeIntensity.beast:
        return 0.60; // +60%
      case BeastModeIntensity.nuclear:
        return 1.20; // +120%
    }
  }

  /// Auto-posting cadence reduction (minutes)
  int get postingCadenceMinutes {
    switch (_intensity) {
      case BeastModeIntensity.off:
        return 60; // 1 hour
      case BeastModeIntensity.turbo:
        return 30; // 30 min
      case BeastModeIntensity.beast:
        return 15; // 15 min
      case BeastModeIntensity.nuclear:
        return 5; // 5 min (RAPID FIRE!)
    }
  }

  /// Bot performance multiplier
  double get botPerformanceMultiplier => _intensity.multiplier;

  // ─── Actions ───────────────────────────────────────────────────────────

  /// Activate Beast Mode with chosen intensity
  void activate(BeastModeIntensity intensity) {
    if (intensity == BeastModeIntensity.off) {
      deactivate();
      return;
    }

    _intensity = intensity;
    _activatedAt = DateTime.now();
    _startDurationTracking();
    _controller.add(_intensity);
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        '🔥 BEAST MODE ACTIVATED: ${intensity.label} (${intensity.multiplier}x)',
      );
    }
  }

  /// Deactivate Beast Mode
  void deactivate() {
    if (_intensity == BeastModeIntensity.off) return;

    _intensity = BeastModeIntensity.off;
    _durationTimer?.cancel();
    _durationTimer = null;
    _controller.add(_intensity);
    notifyListeners();

    if (kDebugMode) {
      debugPrint('😴 Beast Mode deactivated. Stats: ${_formatStats()}');
    }
  }

  /// Toggle Beast Mode (cycles: OFF -> TURBO -> BEAST -> NUCLEAR -> OFF)
  void toggle() {
    switch (_intensity) {
      case BeastModeIntensity.off:
        activate(BeastModeIntensity.turbo);
        break;
      case BeastModeIntensity.turbo:
        activate(BeastModeIntensity.beast);
        break;
      case BeastModeIntensity.beast:
        activate(BeastModeIntensity.nuclear);
        break;
      case BeastModeIntensity.nuclear:
        deactivate();
        break;
    }
  }

  /// Quick activate Beast mode (default intensity)
  void quickBeast() => activate(BeastModeIntensity.beast);

  /// Nuclear mode shortcut
  void goNuclear() => activate(BeastModeIntensity.nuclear);

  // ─── Tracking ─────────────────────────────────────────────────────────

  void trackContentAmplified(int count) {
    _stats = _stats.copyWith(contentAmplified: _stats.contentAmplified + count);
    notifyListeners();
  }

  void trackCampaignBoosted() {
    _stats = _stats.copyWith(campaignsBoost: _stats.campaignsBoost + 1);
    notifyListeners();
  }

  void trackReachIncrease(double increase) {
    _stats = _stats.copyWith(
      totalReachIncrease: _stats.totalReachIncrease + increase,
    );
    notifyListeners();
  }

  void trackViralBoost(double boost) {
    _stats = _stats.copyWith(viralBoost: _stats.viralBoost + boost);
    notifyListeners();
  }

  void resetStats() {
    _stats = const BeastModeStats();
    notifyListeners();
  }

  // ─── Internal ─────────────────────────────────────────────────────────

  void _startDurationTracking() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_activatedAt != null) {
        final duration = DateTime.now().difference(_activatedAt!);
        _stats = _stats.copyWith(activeDuration: duration);
        notifyListeners();
      }
    });
  }

  String _formatStats() {
    return 'Content: ${_stats.contentAmplified}, '
        'Campaigns: ${_stats.campaignsBoost}, '
        'Reach: +${_stats.totalReachIncrease.toStringAsFixed(0)}, '
        'Viral: +${_stats.viralBoost.toStringAsFixed(1)}%, '
        'Duration: ${_formatDuration(_stats.activeDuration)}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _controller.close();
    super.dispose();
  }
}
