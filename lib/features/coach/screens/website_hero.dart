import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class WebsiteHero extends StatelessWidget {
  const WebsiteHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D1A), AppColors.bg],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'THE GLOBAL COMBAT OS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'PPV • Fighters • Gyms • Neural Coach',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('ENTER PLATFORM'),
          ),
        ],
      ),
    );
  }
}
