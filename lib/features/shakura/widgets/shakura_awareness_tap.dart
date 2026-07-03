import 'package:flutter/material.dart';

class ShakuraAwarenessTap extends StatefulWidget {
  final VoidCallback onTap;

  const ShakuraAwarenessTap({super.key, required this.onTap});

  @override
  State<ShakuraAwarenessTap> createState() => _ShakuraAwarenessTapState();
}

class _ShakuraAwarenessTapState extends State<ShakuraAwarenessTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Creates a soft, continuous breathing effect (2.5 second cycle)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
            gradient: LinearGradient(
              colors: [
                Colors.pinkAccent.withValues(alpha: 0.9),
                Colors.purpleAccent.withValues(alpha: 0.4),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Awareness Tap • Friend / Family',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
