import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/ppv_continue_watching_row.dart';

class PpvStorefrontScreen extends StatelessWidget {
  const PpvStorefrontScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          'DFC STOREFRONT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Hero Event Banner
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.neonMagenta.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neonMagenta.withValues(alpha: 0.5)),
            ),
            child: const Center(
              child: Text(
                "HERO EVENT: LIVE NOW",
                style: TextStyle(
                  color: AppColors.neonMagenta,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Continue Watching
          const PpvContinueWatchingRow(), // wired via Provider
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
