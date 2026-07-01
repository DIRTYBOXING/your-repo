import 'package:flutter/material.dart';

class DfcGradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const DfcGradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = const LinearGradient(
      colors: [Color(0xFFFF2E7E), Color(0xFF00E0FF)], // Pink -> Cyan
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
