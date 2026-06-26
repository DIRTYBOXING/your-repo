import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class BlueprintDetailScreen extends StatelessWidget {
  const BlueprintDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "STRIKING FUNDAMENTALS",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _buildGuideSection(
            "Footwork",
            "Maintain balance, stay light on the balls of your feet, control angles to cut the cage.",
          ),
          _buildGuideSection(
            "Jab Mechanics",
            "Snap, retract fast, keep your opposite shoulder high to protect the chin.",
          ),
          _buildGuideSection(
            "Distance Control",
            "Use feints, probe with the lead hand, and manage range constantly.",
          ),
          const SizedBox(height: 32),
          const Text(
            "CHECKLIST",
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildChecklistItem("Warm-up 10 min", true),
          _buildChecklistItem("Shadowboxing 3 rounds", false),
          _buildChecklistItem("Bag work 5 rounds", false),
        ],
      ),
    );
  }

  Widget _buildGuideSection(String title, String body) {
    return Container(
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
              color: DesignTokens.neonGreen,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text, bool done) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: Icon(
          done ? Icons.check_circle : Icons.circle_outlined,
          color: done ? DesignTokens.neonGreen : Colors.white38,
        ),
        title: Text(
          text,
          style: TextStyle(
            color: done ? Colors.white70 : Colors.white,
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
