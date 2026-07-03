import 'package:flutter/material.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neon_glow_button.dart';

class WhosWhoScreen extends StatelessWidget {
  const WhosWhoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "WHO'S WHO IN COMBAT",
          style: TextStyle(
            color: Colors.cyanAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THE COMPLETE ECOSYSTEM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Everyone gets their lights and action. Discover the faces, minds, and architects behind the adrenaline.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Ring Girls & Creators
            _buildEcosystemCategory(
              context,
              title: 'RING GIRLS & CREATORS',
              subtitle: 'The glamour, energy, and face of fight night.',
              icon: Icons.star_border,
              accentColor: Colors.pinkAccent,
              imageHint: 'Models, Influencers, Ring Girls',
            ),
            
            // Promoters & Matchmakers
            _buildEcosystemCategory(
              context,
              title: 'PROMOTERS & MATCHMAKERS',
              subtitle: 'The architects building the biggest cards.',
              icon: Icons.business_center,
              accentColor: Colors.purpleAccent,
              imageHint: 'CEOs, Matchmakers, Event Directors',
            ),
            
            // Coaches & Gyms
            _buildEcosystemCategory(
              context,
              title: 'COACHES & DOJO MASTERS',
              subtitle: 'The unsung heroes forging champions.',
              icon: Icons.sports_martial_arts,
              accentColor: Colors.greenAccent,
              imageHint: 'Head Coaches, BJJ Blackbelts, Striking Gurus',
            ),
            
            // Cutmen & Medical
            _buildEcosystemCategory(
              context,
              title: 'CUTMEN & MEDICAL TEAM',
              subtitle: 'Keeping the fighters safe in the crossfire.',
              icon: Icons.medical_services,
              accentColor: Colors.redAccent,
              imageHint: 'Cutmen, Ringside Doctors, Physios',
            ),

            // Media & Broadcasters
            _buildEcosystemCategory(
              context,
              title: 'MEDIA & BROADCASTERS',
              subtitle: 'The voices amplifying the sport.',
              icon: Icons.mic,
              accentColor: Colors.orangeAccent,
              imageHint: 'Commentators, Journalists, Podcasters',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEcosystemCategory(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String imageHint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Icon(icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      imageHint,
                      style: const TextStyle(color: Colors.white54, fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                    Icon(Icons.arrow_forward_ios, color: accentColor, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
