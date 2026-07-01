import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../widgets/gym_header.dart';
import '../widgets/coach_tile.dart';
import '../widgets/fighter_tile.dart';
import '../widgets/schedule_tile.dart';
import '../widgets/gym_media_grid.dart';

class GymProfileScreen extends StatelessWidget {
  const GymProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "GYM HQ",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GymHeader(
              name: "STORM MMA ACADEMY",
              location: "Brisbane, Australia",
              imageUrl: "",
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("COACHES", DesignTokens.neonMagenta),
            const CoachTile(name: "John Scida", specialty: "Head Coach"),
            const CoachTile(name: "Leo Fury", specialty: "Striking Coach"),
            const SizedBox(height: 32),
            _buildSectionTitle("ROSTER", DesignTokens.neonCyan),
            const FighterTile(name: "Kai Storm", record: "12-2-0"),
            const FighterTile(name: "Max Steel", record: "8-1-0"),
            const SizedBox(height: 32),
            _buildSectionTitle("TRAINING SCHEDULE", DesignTokens.neonGreen),
            const ScheduleTile(
              day: "Mon",
              session: "Striking",
              time: "6:00 PM",
            ),
            const ScheduleTile(
              day: "Wed",
              session: "Grappling",
              time: "6:00 PM",
            ),
            const ScheduleTile(
              day: "Fri",
              session: "Sparring",
              time: "6:00 PM",
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("MEDIA", Colors.white),
            const GymMediaGrid(media: ["", "", "", "", "", ""]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
