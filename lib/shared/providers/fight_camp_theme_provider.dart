/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CAMP THEME PROVIDER - Dynamic Theme Switching
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Provides reactive theme changes based on fight countdown phase.
/// Includes animated glow widgets and phase indicator components.
///
/// Usage:
///   final themeProvider = context.watch(FightCampThemeProvider);
///   Color glowColor = themeProvider.currentGlowColor;
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/fight_camp_service.dart';

/// Fight Camp Theme Provider - Manages dynamic theming
class FightCampThemeProvider extends ChangeNotifier {
  final FightCampService _fightCampService = FightCampService();

  // Animation state
  double _pulseIntensity = 1.0;
  bool _isPulsing = false;
  Timer? _pulseTimer;

  // Constructor
  FightCampThemeProvider() {
    _fightCampService.addListener(_onFightCampChanged);
    _startPulseAnimation();
  }

  void _onFightCampChanged() {
    notifyListeners();
  }

  void _startPulseAnimation() {
    _isPulsing = true;
    double phase = 0;

    _pulseTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      phase += 0.1;
      _pulseIntensity = 0.7 + (math.sin(phase) * 0.3);
      notifyListeners();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THEME GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Current fight camp phase
  FightCampPhase get currentPhase => _fightCampService.currentPhase;

  /// Current theme configuration
  FightCampTheme get currentTheme => _fightCampService.currentTheme;

  /// Primary color for current phase
  Color get primaryColor => _fightCampService.currentTheme.primary;

  /// Accent color for current phase
  Color get accentColor => _fightCampService.currentTheme.accent;

  /// Glow color for current phase
  Color get glowColor => _fightCampService.currentTheme.glow;

  /// Gradient colors for current phase
  List<Color> get gradientColors =>
      _fightCampService.currentTheme.gradientColors;

  /// Phase name string
  String get phaseName => _fightCampService.currentTheme.phaseName;

  /// Phase description
  String get phaseDescription =>
      _fightCampService.currentTheme.phaseDescription;

  /// Phase icon
  IconData get phaseIcon => _fightCampService.currentTheme.phaseIcon;

  /// Countdown string
  String get countdownString => _fightCampService.countdownString;

  /// Days until fight
  int get daysUntilFight => _fightCampService.daysUntilFight;

  /// Is fight day
  bool get isFightDay => _fightCampService.isFightDay;

  /// Has scheduled fight
  bool get hasFight => _fightCampService.hasFightScheduled;

  /// Current pulse intensity (0.0 - 1.0)
  double get pulseIntensity => _pulseIntensity;

  /// Is pulsing active
  bool get isPulsing => _isPulsing;

  // ═══════════════════════════════════════════════════════════════════════════
  // DYNAMIC GLOW INTENSITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get glow intensity based on phase urgency
  double get glowIntensity {
    switch (currentPhase) {
      case FightCampPhase.baseCamp:
        return 0.3;
      case FightCampPhase.fightCamp:
        return 0.5;
      case FightCampPhase.approaching:
        return 0.7;
      case FightCampPhase.fightWeek:
        return 0.9;
      case FightCampPhase.fightDay:
        return 1.0;
      case FightCampPhase.recovery:
        return 0.4;
      case FightCampPhase.noFight:
        return 0.3;
    }
  }

  /// Get animated glow intensity (with pulse)
  double get animatedGlowIntensity => glowIntensity * _pulseIntensity;

  /// Get glow blur radius for box shadows
  double get glowBlurRadius => 20.0 * animatedGlowIntensity;

  /// Get glow spread radius
  double get glowSpreadRadius => 5.0 * animatedGlowIntensity;

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE TRANSITION HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get interpolated color between phases (for smooth transitions)
  Color lerpToNextPhase(double t) {
    final nextPhase = _getNextPhase(currentPhase);
    final nextTheme = _getThemeForPhase(nextPhase);
    return Color.lerp(primaryColor, nextTheme.primary, t) ?? primaryColor;
  }

  FightCampPhase _getNextPhase(FightCampPhase phase) {
    switch (phase) {
      case FightCampPhase.baseCamp:
        return FightCampPhase.fightCamp;
      case FightCampPhase.fightCamp:
        return FightCampPhase.approaching;
      case FightCampPhase.approaching:
        return FightCampPhase.fightWeek;
      case FightCampPhase.fightWeek:
        return FightCampPhase.fightDay;
      case FightCampPhase.fightDay:
        return FightCampPhase.recovery;
      case FightCampPhase.recovery:
        return FightCampPhase.baseCamp;
      case FightCampPhase.noFight:
        return FightCampPhase.baseCamp;
    }
  }

  FightCampTheme _getThemeForPhase(FightCampPhase phase) {
    switch (phase) {
      case FightCampPhase.baseCamp:
        return FightCampTheme.baseCamp;
      case FightCampPhase.fightCamp:
        return FightCampTheme.fightCamp;
      case FightCampPhase.approaching:
        return FightCampTheme.approaching;
      case FightCampPhase.fightWeek:
        return FightCampTheme.fightWeek;
      case FightCampPhase.fightDay:
        return FightCampTheme.fightDay;
      case FightCampPhase.recovery:
        return FightCampTheme.recovery;
      case FightCampPhase.noFight:
        return FightCampTheme.noFight;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Start pulse animation
  void startPulsing() {
    if (!_isPulsing) {
      _startPulseAnimation();
    }
  }

  /// Stop pulse animation
  void stopPulsing() {
    _isPulsing = false;
    _pulseTimer?.cancel();
    _pulseIntensity = 1.0;
    notifyListeners();
  }

  /// Set custom pulse intensity
  void setPulseIntensity(double intensity) {
    _pulseIntensity = intensity.clamp(0.0, 1.0);
    notifyListeners();
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _fightCampService.removeListener(_onFightCampChanged);
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME-AWARE WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

/// Container with animated phase-aware glow
class PulseGlowContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsets? padding;
  final Color? overrideColor;

  const PulseGlowContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    // In a real app, this would use Provider/Riverpod to get the theme
    // For now, we'll use the singleton service
    final fightCampService = FightCampService();

    return AnimatedBuilder(
      animation: fightCampService,
      builder: (context, _) {
        final glowColor = overrideColor ?? fightCampService.currentTheme.glow;

        return Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: glowColor.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// Animated builder for Listenable
class AnimatedBuilder extends StatefulWidget {
  final Listenable animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  State<AnimatedBuilder> createState() => _AnimatedBuilderState();
}

class _AnimatedBuilderState extends State<AnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      oldWidget.animation.removeListener(_handleChange);
      widget.animation.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_handleChange);
    super.dispose();
  }

  DateTime? _lastSetState;
  void _handleChange() {
    final now = DateTime.now();
    if (_lastSetState == null ||
        now.difference(_lastSetState!).inMilliseconds > 100) {
      _lastSetState = now;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.child);
  }
}

/// Phase indicator badge
class PhaseIndicatorBadge extends StatelessWidget {
  final bool compact;

  const PhaseIndicatorBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final fightCampService = FightCampService();

    return AnimatedBuilder(
      animation: fightCampService,
      builder: (context, _) {
        final theme = fightCampService.currentTheme;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: theme.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: theme.glow.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                theme.phaseIcon,
                color: Colors.white,
                size: compact ? 14 : 18,
              ),
              const SizedBox(width: 6),
              Text(
                theme.phaseName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fight countdown widget
class FightCountdownWidget extends StatelessWidget {
  final bool showPhase;
  final bool large;

  const FightCountdownWidget({
    super.key,
    this.showPhase = true,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final fightCampService = FightCampService();

    return AnimatedBuilder(
      animation: fightCampService,
      builder: (context, _) {
        final theme = fightCampService.currentTheme;
        final countdown = fightCampService.countdownString;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPhase) ...[
              const PhaseIndicatorBadge(),
              SizedBox(height: large ? 16 : 8),
            ],
            Text(
              countdown,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: large ? 48 : 24,
                fontWeight: FontWeight.bold,
                color: theme.primary,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: theme.glow.withValues(alpha: 0.8),
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
            if (fightCampService.nextFight != null) ...[
              SizedBox(height: large ? 8 : 4),
              Text(
                'vs ${fightCampService.nextFight!.opponent}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: large ? 18 : 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Neon text with phase-aware color
class PhaseNeonText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? overrideColor;

  const PhaseNeonText({
    super.key,
    required this.text,
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.overrideColor,
  });

  @override
  Widget build(BuildContext context) {
    final fightCampService = FightCampService();

    return AnimatedBuilder(
      animation: fightCampService,
      builder: (context, _) {
        final color = overrideColor ?? fightCampService.currentTheme.primary;

        return Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            shadows: [
              Shadow(color: color.withValues(alpha: 0.8), blurRadius: 10),
              Shadow(color: color.withValues(alpha: 0.5), blurRadius: 20),
            ],
          ),
        );
      },
    );
  }
}
