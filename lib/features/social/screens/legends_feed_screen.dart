import 'package:flutter/material.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/glass_panel.dart';

class LegendsFeedScreen extends StatelessWidget {
  const LegendsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ultimate Legends Events'),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Event Card 1
          _eventCard(
            context,
            title: 'ULTIMATE LEGENDS FIGHT NIGHT',
            date: 'Friday 24th April 2026',
            venue: 'Melbourne Pavilion',
            description:
                'Featuring an action-packed card of the best up & coming Professional fighters in the country.\n\nPROFESSIONAL BOXING - K1 - KICKBOXING - MUAY THAI',
            posterAsset: ImageAssets.bgEvent,
            contact:
                'Joey [contact via DFC] for SPONSORSHIP OPPORTUNITIES, VIP TABLES & TICKETS.',
          ),
          const SizedBox(height: 24),
          // Legends Group Photo
          GlassPanel(
            backgroundColor: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      ImageAssets.legendsGroupPhoto,
                      fit: BoxFit.cover,
                      height: 180,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(
                        height: 180,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF1A0A2E),
                              Color(0xFF0A2D1A),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.sports_mma,
                            size: 48,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ultimate Legends Team',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Celebrating the legends and community behind Ultimate Legends Promotions.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          // Event Card 2
          _eventCard(
            context,
            title: 'ULTIMATE LEGENDS FIGHT NIGHT',
            date: 'Friday 24th April 2026',
            venue: 'Melbourne Pavilion',
            description:
                'PRO BOXING INTERNATIONAL BOUT\nAUSTRALIA VS INDIA\nJORDAN ROESLER VS DEEPAK TANWAR',
            posterAsset: ImageAssets.bgPromo,
            contact:
                'Joey [contact via DFC] for SPONSORSHIP OPPORTUNITIES, VIP TABLES & TICKETS.',
          ),
          // Add more event cards as needed, each with its own poster and details
        ],
      ),
    );
  }

  Widget _eventCard(
    BuildContext context, {
    required String title,
    required String date,
    required String venue,
    required String description,
    required String posterAsset,
    required String contact,
  }) {
    return GlassPanel(
      backgroundColor: Colors.grey[900],
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: ImageAssets.resolveImage(posterAsset),
                fit: BoxFit.cover,
                height: 180,
                width: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A0A2E), Color(0xFF0A2D1A)],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sports_mma,
                          size: 36,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              venue,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              contact,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
