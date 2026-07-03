import 'package:flutter/material.dart';

/// A reusable, animated button with a pulsing neon glow and shockwave tap effect.
class DetonateButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const DetonateButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  State<DetonateButton> createState() => _DetonateButtonState();
}

class _DetonateButtonState extends State<DetonateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final p = _pulseCtrl.value;
        return GestureDetector(
          onTap: widget.onPressed,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 80),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    widget.color.withOpacity(0.7 + p * 0.1),
                    widget.color.withOpacity(0.4 + p * 0.1),
                  ],
                ),
                border: Border.all(
                  color: widget.color.withOpacity(0.3 + p * 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.15 + p * 0.2),
                    blurRadius: 16 + p * 12,
                    spreadRadius: 2 + p * 4,
                  ),
                  BoxShadow(
                    color: widget.color.withOpacity(0.05),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white.withOpacity(0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
