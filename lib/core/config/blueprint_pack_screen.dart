import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';

class BlueprintPackScreen extends StatefulWidget {
  const BlueprintPackScreen({super.key});

  @override
  State<BlueprintPackScreen> createState() => _BlueprintPackScreenState();
}

class _BlueprintPackScreenState extends State<BlueprintPackScreen> {
  int activeCategory = 0;
  final categories = [
    "Training",
    "Nutrition",
    "Mindset",
    "Recovery",
    "Fight Prep",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "BLUEPRINT PACK",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final active = activeCategory == i;
                  return GestureDetector(
                    onTap: () => setState(() => activeCategory = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: active
                            ? DesignTokens.neonGreen.withValues(alpha: 0.2)
                            : DesignTokens.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? DesignTokens.neonGreen
                              : Colors.white10,
                        ),
                      ),
                      child: Text(
                        categories[i].toUpperCase(),
                        style: TextStyle(
                          color: active
                              ? DesignTokens.neonGreen
                              : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildBlueprintCard(
                    "Striking Fundamentals",
                    "Footwork, jab mechanics, distance control.",
                    () => context.push('/blueprint-pack/detail'),
                  ),
                  _buildBlueprintCard(
                    "Weight-Cut Protocol",
                    "Hydration, sodium control, sauna cycles.",
                    () {},
                  ),
                  _buildBlueprintCard(
                    "Fight Week Checklist",
                    "Gear, nutrition, mindset, recovery.",
                    () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueprintCard(
    String title,
    String description,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
