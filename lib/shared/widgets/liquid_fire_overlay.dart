import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIQUID FIRE OVERLAY — GPU-Accelerated Win Probability Visualization
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Wraps any widget with a viscous, generative fire effect driven by
/// AI win probability [0.0 → 1.0]. Offloads rendering to the GPU via
/// a GLSL fragment shader so the CPU stays free for data streaming.
///
/// Usage:
///   LiquidFireOverlay(
///     winProbability: 0.85, // from AI predictor
///     child: MyFightPredictorCard(),
///   )
///
/// ═══════════════════════════════════════════════════════════════════════════
class LiquidFireOverlay extends StatefulWidget {
  /// AI win probability / hype level [0.0 → 1.0].
  /// 0.0 = no fire. 0.6 = orange. 0.8+ = white-hot.
  final double winProbability;

  /// Widget beneath the fire overlay.
  final Widget? child;

  /// Minimum intensity to show fire (prevents shimmering at low values).
  final double threshold;

  const LiquidFireOverlay({
    super.key,
    required this.winProbability,
    this.child,
    this.threshold = 0.15,
  });

  @override
  State<LiquidFireOverlay> createState() => _LiquidFireOverlayState();
}

class _LiquidFireOverlayState extends State<LiquidFireOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  ui.FragmentProgram? _program;
  bool _shaderFailed = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // free-running ticker for uTime

    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/liquid_fire.frag');
      if (mounted) {
        setState(() => _program = program);
      }
    } catch (e) {
      debugPrint('LiquidFireOverlay: Shader load failed — $e');
      if (mounted) setState(() => _shaderFailed = true);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intensity = widget.winProbability.clamp(0.0, 1.0);

    // Below threshold or shader unavailable → just show child
    if (intensity < widget.threshold || _shaderFailed || _program == null) {
      return widget.child ?? const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _ticker,
              builder: (context, _) {
                return CustomPaint(
                  painter: _LiquidFirePainter(
                    program: _program!,
                    time: _ticker.value,
                    intensity: intensity,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LiquidFirePainter extends CustomPainter {
  final ui.FragmentProgram program;
  final double time;
  final double intensity;

  _LiquidFirePainter({
    required this.program,
    required this.time,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader()
      ..setFloat(0, time) // uTime
      ..setFloat(1, size.width) // uSize.x
      ..setFloat(2, size.height) // uSize.y
      ..setFloat(3, intensity); // uIntensity

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(_LiquidFirePainter old) => true; // repaints every frame
}
