import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class WeightCutScreen extends StatelessWidget {
  const WeightCutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "WEIGHT-CUT TRACKER",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHydrationCard(0.65),
            const SizedBox(height: 24),
            _buildSectionTitle("WEIGHT LOG"),
            _buildWeightChart(),
            const SizedBox(height: 24),
            _buildSectionTitle("RISK LEVEL"),
            _buildRiskIndicator("medium"),
            const SizedBox(height: 24),
            _buildSectionTitle("DAILY CHECKLIST"),
            _buildChecklistTile("Morning weigh-in", true),
            _buildChecklistTile("Hydration target", false),
            _buildChecklistTile("Sauna session", false),
            const SizedBox(height: 24),
            _buildSectionTitle("NUTRITION"),
            _buildNutritionCard("Breakfast: Oats + Berries", "320 kcal"),
            _buildNutritionCard("Lunch: Chicken + Rice", "540 kcal"),
            const SizedBox(height: 24),
            _buildSectionTitle("SLEEP & RECOVERY"),
            _buildSleepCard("7h 45m"),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: DesignTokens.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildHydrationCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.neonCyan.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: DesignTokens.neonCyan, size: 20),
              SizedBox(width: 8),
              Text(
                "HYDRATION",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(DesignTokens.neonCyan),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${(progress * 100).round()}% of daily target (3.5L)",
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          const Center(
            child: Text(
              "Live Weight Trend (UI-only)",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                "-2.4 kg",
                style: TextStyle(
                  color: DesignTokens.neonMagenta,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskIndicator(String level) {
    final Color color = level == "high"
        ? DesignTokens.neonRed
        : level == "medium"
        ? DesignTokens.neonAmber
        : DesignTokens.neonGreen;
    final String label = level == "high"
        ? "HIGH RISK"
        : level == "medium"
        ? "MODERATE RISK"
        : "OPTIMAL";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Monitor sodium intake closely today.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistTile(String task, bool done) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? DesignTokens.neonGreen.withValues(alpha: 0.3)
              : Colors.white10,
        ),
      ),
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          color: done ? DesignTokens.neonGreen : Colors.white38,
        ),
        title: Text(
          task,
          style: TextStyle(
            color: done ? Colors.white70 : Colors.white,
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionCard(String meal, String calories) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.neonGold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant,
              color: DesignTokens.neonGold,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              meal,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            calories,
            style: const TextStyle(
              color: DesignTokens.neonGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard(String hours) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bedtime,
              color: Colors.deepPurpleAccent,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Total Sleep Logged",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            hours,
            style: const TextStyle(
              color: Colors.deepPurpleAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
