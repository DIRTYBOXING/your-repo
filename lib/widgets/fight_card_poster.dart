import 'package:flutter/material.dart';

class FightCardPosterSimple extends StatelessWidget {
  final String posterUrl;

  const FightCardPosterSimple({super.key, required this.posterUrl});

  @override
  Widget build(BuildContext context) {
    if (posterUrl.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2E), Colors.black],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/logos/dfc_hex_badge.png',
            width: 80,
            height: 80,
            opacity: const AlwaysStoppedAnimation(0.3),
          ),
        ),
      );
    }

    // Local asset path
    if (posterUrl.startsWith('assets/')) {
      return Image.asset(
        posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A0A2E), Colors.black],
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/logos/dfc_hex_badge.png',
              width: 60,
              height: 60,
              opacity: const AlwaysStoppedAnimation(0.4),
            ),
          ),
        ),
      );
    }

    return Image.network(
      posterUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator(color: Colors.red));
      },
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2E), Colors.black],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/logos/dfc_hex_badge.png',
            width: 60,
            height: 60,
            opacity: const AlwaysStoppedAnimation(0.4),
          ),
        ),
      ),
    );
  }
}
