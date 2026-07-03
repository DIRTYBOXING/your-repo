import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A reusable widget that provides the explosive cosmic background and
/// detonation effects seen on the registration screen.
class CosmicBackgroundFx extends StatefulWidget {
  final bool isDetonating;
  final Widget child;

  const CosmicBackgroundFx({
    super.key,
    required this.isDetonating,
    required this.child,
  });

  @override
  State<CosmicBackgroundFx> createState() => _CosmicBackgroundFxState();
}

class _CosmicBackgroundFxState extends State<CosmicBackgroundFx>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _detonateCtrl;

  final _rng = math.Random();
  late final List<_Ember> _embers;
  late final List<_Shard> _shards;

  @override
  void initState() {
    super.initState();
    _embers = List.generate(60, (_) => _Ember.random(_rng));
    _shards = List.generate(40, (_) => _Shard.random(_rng));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _detonateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didUpdateWidget(covariant CosmicBackgroundFx oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDetonating && !oldWidget.isDetonating) {
      _detonateCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _detonateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 0: Cosmic background
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, _) => CustomPaint(
            painter: _CosmicBackgroundPainter(
              pulse: _pulseCtrl.value,
              embers: _embers,
            ),
            size: Size.infinite,
          ),
        ),

        // Layer 1: Dark overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.5),
                Colors.black.withOpacity(0.7),
                const Color(0xFF020810).withOpacity(0.9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Layer 2: Detonation FX
        if (widget.isDetonating)
          AnimatedBuilder(
            animation: _detonateCtrl,
            builder: (context, _) => CustomPaint(
              painter: _IgnitionPainter(
                progress: _detonateCtrl.value,
                shards: _shards,
              ),
              size: Size.infinite,
            ),
          ),

        // Layer 3: Child content
        widget.child,
      ],
    );
  }
}

// Data classes and Painters (moved from register_screen.dart)

class _Shard {
  final double angle, speed, size, rotSpeed;
  final Color color;

  _Shard(
      {required this.angle,
      required this.speed,
      required this.size,
      required this.color,
      required this.rotSpeed});

  factory _Shard.random(math.Random r) {
    const colors = [
      AppTheme.neonMagenta,
      AppTheme.neonCyan,
      AppTheme.neonGreen,
      Color(0xFFFF2D55),
      Color(0xFFFF9800),
      Colors.white,
    ];
    return _Shard(
      angle: r.nextDouble() * math.pi * 2,
      speed: 0.3 + r.nextDouble() * 0.7,
      size: 1.0 + r.nextDouble() * 4.0,
      color: colors[r.nextInt(colors.length)],
      rotSpeed: (r.nextDouble() - 0.5) * 6,
    );
  }
}

class _Ember {
  final double x, y, speed, size;
  final Color color;

  _Ember(
      {required this.x,
      required this.y,
      required this.speed,
      required this.size,
      required this.color});

  factory _Ember.random(math.Random r) {
    const colors = [
      AppTheme.neonMagenta,
      AppTheme.neonCyan,
      Color(0xFFB100FF),
      Color(0xFF00D9FF),
    ];
    return _Ember(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.1 + r.nextDouble() * 0.5,
      size: 0.5 + r.nextDouble() * 1.8,
      color: colors[r.nextInt(colors.length)],
    );
  }
}

class _CosmicBackgroundPainter extends CustomPainter {
  final double pulse;
  final List<_Ember> embers;
  _CosmicBackgroundPainter({required this.pulse, required this.embers});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF0A0518), Color(0xFF050D1A), Color(0xFF020810)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    for (final n in [
      [0.25, 0.3, AppTheme.neonMagenta, 0.05],
      [0.75, 0.55, AppTheme.neonCyan, 0.04],
      [0.5, 0.8, AppTheme.neonGreen, 0.03],
    ]) {
      canvas.drawCircle(
        Offset((n[0] as double) * size.width, (n[1] as double) * size.height),
        size.width * 0.35,
        Paint()
          ..color = (n[2] as Color).withOpacity((n[3] as double))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80),
      );
    }

    for (final e in embers) {
      final t = (pulse * e.speed + e.x * 3) % 1.0;
      final px = (e.x + t * 0.15) % 1.0 * size.width;
      final py = (e.y - t * 0.3 + 1.0) % 1.0 * size.height;
      final a = (0.15 + math.sin(t * math.pi) * 0.25).clamp(0.0, 1.0);

      canvas.drawCircle(Offset(px, py), e.size + 2,
          Paint()..color = e.color.withOpacity(a * 0.15)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(Offset(px, py), e.size * 0.4, Paint()..color = e.color.withOpacity(a));
    }

    final rng = math.Random(77);
    for (int i = 0; i < 60; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final s = rng.nextDouble() * 1.2 + 0.3;
      final b = (rng.nextDouble() * 0.6 + 0.2).clamp(0.0, 1.0);
      canvas.drawCircle(Offset(x, y), s, Paint()..color = Colors.white.withOpacity(b));
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicBackgroundPainter old) => old.pulse != pulse;
}

class _IgnitionPainter extends CustomPainter {
  final double progress;
  final List<_Shard> shards;

  _IgnitionPainter({required this.progress, required this.shards});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.6);

    for (int i = 0; i < 3; i++) {
      final delay = i * 0.12;
      final t = ((progress - delay) / (1.0 - delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final radius = t * size.width * 0.8;
      final alpha = ((1.0 - t) * 0.35).clamp(0.0, 1.0);
      final ringColor = [AppTheme.neonMagenta, AppTheme.neonCyan, AppTheme.neonGreen][i];

      canvas.drawCircle(center, radius, Paint()..color = ringColor.withOpacity(alpha)..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1.0 - t));
      canvas.drawCircle(center, radius, Paint()..color = ringColor.withOpacity(alpha * 0.15)..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * (1.0 - t)));
    }

    if (progress < 0.3) {
      final flashAlpha = ((0.3 - progress) / 0.3 * 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(center, 30 + progress * 100, Paint()..color = Colors.white.withOpacity(flashAlpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    }

    for (final shard in shards) {
      final t = progress;
      final dist = shard.speed * t * size.width * 0.5;
      final fadeIn = (t / 0.1).clamp(0.0, 1.0);
      final fadeOut = ((1.0 - t) / 0.4).clamp(0.0, 1.0);
      final alpha = (fadeIn * fadeOut * 0.8).clamp(0.0, 1.0);

      final px = center.dx + math.cos(shard.angle) * dist;
      final py = center.dy + math.sin(shard.angle) * dist + t * t * 80;

      canvas.drawCircle(Offset(px, py), shard.size + 3, Paint()..color = shard.color.withOpacity(alpha * 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset(px, py), shard.size * 0.5, Paint()..color = shard.color.withOpacity(alpha));
    }
  }

  @override
  bool shouldRepaint(covariant _IgnitionPainter old) => old.progress != progress;
}
