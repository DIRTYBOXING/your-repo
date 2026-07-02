import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/image_assets.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// Faces of Women's Combat — DFC Global Empowerment Feature
/// Showcases the most inspiring, skilled, and influential women fighters from around the world, with a special spotlight on AU/NZ athletes and icons like Cristine Fereano, Bec Rawlings, and Cassy.
class WomenFighterProfile {
  final String name;
  final String country;
  final String specialty;
  final String photoUrl;
  final String? modelShotUrl;
  final String? fightShotUrl;
  final String bio;
  final List<String> achievements;
  final String inspiration;
  final String? videoUrl;
  final String? quote;
  final Map<String, String>? socialLinks;

  WomenFighterProfile({
    required this.name,
    required this.country,
    required this.specialty,
    required this.photoUrl,
    this.modelShotUrl,
    this.fightShotUrl,
    required this.bio,
    this.achievements = const [],
    this.inspiration = '',
    this.videoUrl,
    this.quote,
    this.socialLinks,
  });
}

class FacesOfWomenFightersPage extends StatelessWidget {
  final List<WomenFighterProfile> profiles;
  const FacesOfWomenFightersPage({required this.profiles, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade900,
        title: const Text(
          'Faces of Women\'s Combat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(36),
          child: Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              '“There are always two parts to the rose: the flower and the thorns.”',
              style: TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [...profiles.map((p) => _buildProfileCard(context, p))],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, WomenFighterProfile p) {
    return Card(
      color: Colors.purple.shade800.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.symmetric(vertical: 16),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.modelShotUrl != null)
                            _imageBox(p.modelShotUrl!, 'Model'),
                          if (p.fightShotUrl != null)
                            _imageBox(p.fightShotUrl!, 'Fighter'),
                          if (p.modelShotUrl == null && p.fightShotUrl == null)
                            DfcCircleAvatar(
                              imageUrl: p.photoUrl,
                              radius: 36,
                              backgroundColor: Colors.purple.shade700,
                            ),
                          const SizedBox(width: 20),
                          Expanded(child: _profileDetails(p)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (p.modelShotUrl != null)
                                _imageBox(p.modelShotUrl!, 'Model'),
                              if (p.fightShotUrl != null)
                                _imageBox(p.fightShotUrl!, 'Fighter'),
                              if (p.modelShotUrl == null &&
                                  p.fightShotUrl == null)
                                DfcCircleAvatar(
                                  imageUrl: p.photoUrl,
                                  radius: 36,
                                  backgroundColor: Colors.purple.shade700,
                                ),
                              const SizedBox(width: 20),
                              Expanded(child: _profileDetails(p)),
                            ],
                          ),
                        ],
                      );
              },
            ),
            if (p.videoUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: DfcNetworkImage(url: p.videoUrl!),
                  ),
                ),
              ),
            if (p.quote != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  '“${p.quote}”',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            if (p.socialLinks != null && p.socialLinks!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 10,
                  children: p.socialLinks!.entries
                      .map(
                        (entry) => InkWell(
                          onTap: () async {
                            final url = Uri.parse(entry.value);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          child: Chip(
                            label: Text(
                              entry.key,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.purple.shade900,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _profileDetails(WomenFighterProfile p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          p.country,
          style: const TextStyle(fontSize: 15, color: Colors.white70),
        ),
        Text(
          p.specialty,
          style: const TextStyle(fontSize: 14, color: Colors.white54),
        ),
        const SizedBox(height: 8),
        Text(p.bio, style: const TextStyle(fontSize: 15, color: Colors.white)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: p.achievements
              .map(
                (a) => Chip(
                  label: Text(a),
                  backgroundColor: Colors.purple.shade700,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        Text(
          'Inspiration: ${p.inspiration}',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _imageBox(String url, String label) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: ImageAssets.resolveImage(url),
          fit: BoxFit.cover,
          onError: (_, _) {},
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// Usage Example:
/// FacesOfWomenFightersPage(profiles: [
///   WomenFighterProfile(
///     name: 'Cassy',
///     country: 'Australia',
///     specialty: 'Muay Thai',
///     photoUrl: 'https://example.com/cassy.jpg',
///     modelShotUrl: 'https://example.com/cassy_model.jpg',
///     fightShotUrl: 'https://example.com/cassy_fight.jpg',
///     bio: 'A trailblazer for women in AU/NZ combat sports, inspiring a new generation...',
///     modelShotUrl: 'https://example.com/cassy_model.jpg',
///     fightShotUrl: 'https://example.com/cassy_fight.jpg',
///     videoUrl: 'https://example.com/cassy_highlight.mp4',
///     quote: 'Strength is not just in the fists, but in the heart.',
///     socialLinks: {'Instagram': 'https://instagram.com/cassy'},
///     achievements: ['World Champion', 'Role Model'],
///     inspiration: 'Empowering women worldwide',
///   ),
///   // ...more profiles
/// ])
