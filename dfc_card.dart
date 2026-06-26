import 'dart:ui';
import 'package:flutter/material.dart';

class DfcCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double height;
  final double width;
  final bool glow;

  const DfcCard({
    super.key,
    required this.child,
    this.onTap,
    this.height = 140,
    this.width = double.infinity,
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        height: height,
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Glass layer
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
              ),

              // Neon glow
              if (glow)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: -4,
                      ),
                    ],
                  ),
                ),

              // Content
              Padding(padding: const EdgeInsets.all(16), child: child),
            ],
          ),
        ),
      ),
    );
  }
}
