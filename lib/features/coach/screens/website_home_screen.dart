import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/website_hero.dart';
import '../widgets/dfc_responsive.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DATAFIGHTCENTRAL.COM STOREFRONT
/// The public face of the platform. Premium, SEO-friendly, and responsive.
/// ═══════════════════════════════════════════════════════════════════════════
class WebsiteHomeScreen extends StatelessWidget {
  const WebsiteHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: WebsiteHero()),

          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: DfcResponsive.isDesktop(context) ? 120 : 20,
              vertical: 40,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  'UPCOMING PPV EVENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "PPV Row Widget Maps Here",
                      style: TextStyle(color: AppColors.neonCyan),
                    ),
                  ),
                ),

                const SizedBox(height: 60),
                const Text(
                  'GLOBAL FIGHT DIRECTORY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.neonMagenta.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Fighter/Gym Directories Map Here",
                      style: TextStyle(color: AppColors.neonMagenta),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
