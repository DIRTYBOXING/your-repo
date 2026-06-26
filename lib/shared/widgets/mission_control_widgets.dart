import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LiveBadge extends StatelessWidget {
  final String label;
  final bool isLive;

  const LiveBadge({super.key, this.label = 'Live Now', this.isLive = true});

  @override
  Widget build(BuildContext context) {
    if (!isLive) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Live broadcast status',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.error.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignalPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const SignalPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const MetricChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.accentCyan),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownTimerBanner extends StatelessWidget {
  final DateTime targetDate;

  const CountdownTimerBanner({super.key, required this.targetDate});

  @override
  Widget build(BuildContext context) {
    final duration = targetDate.difference(DateTime.now());
    final totalMinutes = duration.isNegative ? 0 : duration.inMinutes;
    final days = (totalMinutes ~/ (60 * 24)).toString().padLeft(2, '0');
    final hours = ((totalMinutes ~/ 60) % 24).toString().padLeft(2, '0');
    final minutes = (totalMinutes % 60).toString().padLeft(2, '0');

    return Semantics(
      label: 'Countdown to event start',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.background.withValues(alpha: 0.86),
              AppTheme.surfaceDark.withValues(alpha: 0.96),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.accentCyan.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_rounded,
              color: AppTheme.accentCyan,
              size: 16,
            ),
            const SizedBox(width: 10),
            _TimeSegment(value: days, label: 'D'),
            const SizedBox(width: 6),
            _TimeSegment(value: hours, label: 'H'),
            const SizedBox(width: 6),
            _TimeSegment(value: minutes, label: 'M'),
          ],
        ),
      ),
    );
  }
}

class CinematicHero extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String? eyebrow;
  final Widget? actionButton;
  final Widget? secondaryAction;
  final bool isLive;
  final DateTime? countdownTarget;
  final List<Widget> badges;
  final List<Widget> metrics;
  final double height;

  const CinematicHero({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.actionButton,
    this.secondaryAction,
    this.isLive = false,
    this.countdownTarget,
    this.badges = const <Widget>[],
    this.metrics = const <Widget>[],
    this.height = 500,
  });

  @override
  Widget build(BuildContext context) {
    final heroBadges = <Widget>[
      if (isLive) const LiveBadge(),
      if (!isLive && countdownTarget != null)
        CountdownTimerBanner(targetDate: countdownTarget!),
      ...badges,
    ];
    final actionWidgets = [
      actionButton,
      secondaryAction,
    ].whereType<Widget>().toList();

    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppTheme.surfaceDark,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppTheme.surfaceDark,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 56,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.52),
                  AppTheme.background,
                ],
                stops: const [0, 0.42, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.background.withValues(alpha: 0.72),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 10, runSpacing: 10, children: heroBadges),
                const Spacer(),
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 0.98,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 24),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Text(
                    subtitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (metrics.isNotEmpty)
                  Wrap(spacing: 10, runSpacing: 10, children: metrics),
                if (metrics.isNotEmpty) const SizedBox(height: 24),
                Wrap(spacing: 12, runSpacing: 12, children: actionWidgets),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TimeSegment extends StatelessWidget {
  final String value;
  final String label;

  const _TimeSegment({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
