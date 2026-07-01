import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class GymHeader extends StatelessWidget {
  final String name;
  final String location;
  final String imageUrl;

  const GymHeader({
    super.key,
    required this.name,
    required this.location,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: DesignTokens.bgCard,
            image: imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: DesignTokens.neonGreen.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: Colors.white10),
          ),
          child: imageUrl.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Colors.white24,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 20),
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: DesignTokens.neonGreen,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              location,
              style: const TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
