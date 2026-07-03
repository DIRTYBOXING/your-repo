import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GYM PROFILE HUB — Social Interconnector
/// Route (example): /gym-profile
/// ═══════════════════════════════════════════════════════════════════════════
class GymProfileScreen extends StatelessWidget {
  const GymProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050510),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Gym Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _GlassPanel(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.deepPurpleAccent,
                  child: Icon(Icons.fitness_center, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Titan MMA • Logan, QLD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Striking • Grappling • Youth Programs',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Social Interconnectors
          const _SectionHeader('Social Interconnectors'),
          const _GlassPanel(
            child: Row(
              children: [
                _SocialChip(icon: Icons.camera_alt, label: 'Instagram'),
                SizedBox(width: 8),
                _SocialChip(icon: Icons.play_circle_fill, label: 'YouTube'),
                SizedBox(width: 8),
                _SocialChip(icon: Icons.music_note, label: 'TikTok'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Localized Gym Feed
          const _SectionHeader('Gym Datatrain Feed'),
          const _GlassPanel(
            child: Column(
              children: [
                _FeedTile(
                  title: 'New Fight Team Tryouts — August Intake',
                  subtitle: 'Auto-Feed • Gym Announcement',
                  icon: Icons.campaign,
                ),
                Divider(color: Colors.white12, height: 16),
                _FeedTile(
                  title: 'Highlight Reel: Sparring Night',
                  subtitle: 'Imported via Auto-Feed Orchestrator',
                  icon: Icons.play_circle_fill,
                ),
                Divider(color: Colors.white12, height: 16),
                _FeedTile(
                  title: 'Coach Seminar: Muay Thai Clinch',
                  subtitle: 'Event Routing • Tap to view details',
                  icon: Icons.school,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Business Porthole: Membership & PPV
          const _SectionHeader('Business Porthole'),
          _GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join & Support',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Book Trial',
                        icon: Icons.event_available,
                        color: Colors.cyanAccent,
                        onTap: () {
                          // TODO: Route to gym booking flow
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Buy PPV',
                        icon: Icons.live_tv,
                        color: Colors.deepPurpleAccent,
                        onTap: () {
                          // TODO: Route to gym-hosted PPV events
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Sponsor Gym',
                        icon: Icons.handshake,
                        color: Colors.orangeAccent,
                        onTap: () {
                          // TODO: Open sponsorship contact form
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.cyanAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SocialChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: const Color(0xFF101020),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      avatar: Icon(icon, size: 16, color: Colors.cyanAccent),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
      ),
    );
  }
}

class _FeedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _FeedTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.4),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}