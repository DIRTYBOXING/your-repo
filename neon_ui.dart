import 'package:flutter/material.dart';

class NeonText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final double blurRadius;
  final double letterSpacing;
  final TextAlign textAlign;

  const NeonText(
    this.text, {
    super.key,
    this.color = Colors.redAccent,
    this.fontSize = 24,
    this.fontWeight = FontWeight.w900,
    this.blurRadius = 16,
    this.letterSpacing = 2.0,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        shadows: [
          BoxShadow(color: color, blurRadius: blurRadius),
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: blurRadius * 2),
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: blurRadius * 4),
        ],
      ),
    );
  }
}

class NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 16,
              spreadRadius: -4,
            ),
          ],
          gradient: const LinearGradient(
            colors: [Color(0xFF02030A), Color(0xFF041727)],
          ),
        ),
        child: NeonText(
          label,
          color: color,
          fontSize: 16,
          blurRadius: 8,
          letterSpacing: 3,
        ),
      ),
    );
  }
}
