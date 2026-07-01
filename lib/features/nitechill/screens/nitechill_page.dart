import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NIGHTCHILL — "Buy a Coffee, Not a Coffin"
// Program 2 of the DataFightCentral Foundation
// Crisis intervention · DV protection · Poverty/homeless support · Mind health
// 100% free — funded by DFC revenue + grants
// ═══════════════════════════════════════════════════════════════════════════════

class NitechillPage extends StatefulWidget {
  const NitechillPage({super.key});

  @override
  State<NitechillPage> createState() => _NitechillPageState();
}

class _NitechillPageState extends State<NitechillPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breatheCtrl;
  late Animation<double> _breathe;

  int _coffeesGiven = 0;
  int _livesReached = 0;
  int _safePlaces = 0;
  int _mentorsActive = 0;

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _breathe = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
    _loadStats();
  }

  @override
  void dispose() {
    _breatheCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('platform_config')
          .doc('nightchill_stats')
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        if (mounted) {
          setState(() {
            _coffeesGiven = d['coffeesGiven'] ?? 0;
            _livesReached = d['livesReached'] ?? 0;
            _safePlaces = d['safePlaces'] ?? 0;
            _mentorsActive = d['mentorsActive'] ?? 0;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sos, color: Colors.redAccent, size: 28),
                tooltip: 'Emergency SOS',
                onPressed: () => context.push('/nitechill/crisis'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A0030), Color(0xFF0D0D1A)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      AnimatedBuilder(
                        animation: _breathe,
                        builder: (_, _) => Transform.scale(
                          scale: _breathe.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.deepPurple.shade300.withValues(
                                    alpha: 0.4,
                                  ),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.coffee,
                              size: 48,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NightChill',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Colors.amberAccent, Colors.deepPurple],
                        ).createShader(rect),
                        child: const Text(
                          'Buy a Coffee, Not a Coffin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'For those at the bottom — the lost, the hurting, the survivors.\nHope. Help. A way back up.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sosBanner(),
                const SizedBox(height: 20),
                _sectionLabel('IMPACT', Icons.favorite),
                const SizedBox(height: 8),
                _impactStats(),
                const SizedBox(height: 24),
                _sectionLabel('PROGRAMS', Icons.shield),
                const SizedBox(height: 12),
                _programCard(
                  icon: Icons.sos,
                  title: 'Crisis Intervention',
                  subtitle:
                      'SOS alerts, safety tracking, 24/7 crisis contacts, mind health support',
                  color: Colors.redAccent,
                  gradient: [const Color(0xFF4A0000), const Color(0xFF2D0000)],
                  onTap: () => context.push('/nitechill/crisis'),
                ),
                const SizedBox(height: 12),
                _programCard(
                  icon: Icons.shield,
                  title: 'DV Protection',
                  subtitle:
                      'Safety planning, escape resources, legal aid, anonymous support',
                  color: Colors.pinkAccent,
                  gradient: [const Color(0xFF3D0030), const Color(0xFF1A0018)],
                  onTap: () => context.push('/nitechill/dv-protection'),
                ),
                const SizedBox(height: 12),
                _programCard(
                  icon: Icons.home,
                  title: 'Poverty & Homeless Support',
                  subtitle:
                      'Shelters, food banks, clothing, job help, free training',
                  color: Colors.tealAccent,
                  gradient: [const Color(0xFF002D2D), const Color(0xFF001A1A)],
                  onTap: () => context.push('/nitechill/homeless-support'),
                ),
                const SizedBox(height: 24),
                _sectionLabel('BREATHE', Icons.air),
                const SizedBox(height: 8),
                _selfCareReminders(),
                const SizedBox(height: 24),
                _sectionLabel('SURVIVOR STORIES', Icons.auto_stories),
                const SizedBox(height: 8),
                _survivorStoriesPreview(),
                const SizedBox(height: 24),
                _sectionLabel('GIVE BACK', Icons.handshake),
                const SizedBox(height: 8),
                _mentorshipCard(),
                const SizedBox(height: 24),
                _donateCard(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NightChill is a program of the DataFightCentral Foundation.\n'
                    '100% free. Funded by DFC revenue and grants.\n'
                    'Every coffee bought keeps someone alive.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sosBanner() {
    return GestureDetector(
      onTap: () => context.push('/nitechill/crisis'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade900, Colors.red.shade800],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _breathe,
              builder: (_, _) => Opacity(
                opacity: _breathe.value,
                child: const Icon(Icons.sos, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IN CRISIS? TAP HERE NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Instant access to crisis support, safety alerts, and emergency contacts',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _impactStats() {
    return Row(
      children: [
        _statBox('☕', '$_coffeesGiven', 'Coffees\nGiven'),
        const SizedBox(width: 8),
        _statBox('💛', '$_livesReached', 'Lives\nReached'),
        const SizedBox(width: 8),
        _statBox('🏠', '$_safePlaces', 'Safe\nPlaces'),
        const SizedBox(width: 8),
        _statBox('🤝', '$_mentorsActive', 'Active\nMentors'),
      ],
    );
  }

  Widget _statBox(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _programCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _selfCareReminders() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade900.withValues(alpha: 0.5),
            Colors.deepPurple.shade900.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Text(
            'Take a moment. You deserve it.',
            style: TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CareChip(emoji: '💧', text: 'Drink water'),
              _CareChip(emoji: '🚿', text: 'Shower'),
              _CareChip(emoji: '🪥', text: 'Brush teeth'),
              _CareChip(emoji: '💙', text: 'You matter'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _survivorStoriesPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: Colors.purpleAccent.withValues(alpha: 0.6),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '"I was sleeping on the street. NightChill connected me to a gym '
                  'that gave me a locker, a shower, and a reason to get up. Now I '
                  "train three days a week and I'm six months clean.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— Anonymous, Melbourne',
              style: TextStyle(
                color: Colors.purpleAccent.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              icon: const Icon(
                Icons.auto_stories,
                color: Colors.purpleAccent,
                size: 16,
              ),
              label: const Text(
                'Read More Stories',
                style: TextStyle(color: Colors.purpleAccent),
              ),
              onPressed: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mentorshipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade900.withValues(alpha: 0.5),
            Colors.cyan.shade900.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Become a Mentor',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Offer a coffee, share your story, or help someone else's child. "
            "You don't need qualifications — just a caring heart.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.volunteer_activism, size: 16),
                  label: const Text('Volunteer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.coffee, size: 16),
                  label: const Text('Buy a Coffee'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amberAccent,
                    side: const BorderSide(color: Colors.amberAccent),
                  ),
                  onPressed: () => context.push('/donate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _donateCard() {
    return GestureDetector(
      onTap: () => context.push('/donate'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade900, Colors.deepOrange.shade900],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.coffee, color: Colors.white, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buy a Coffee, Save a Life',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Every donation goes directly to crisis support, food, shelter, and training — not admin.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple.shade300, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.deepPurple.shade200,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CareChip extends StatelessWidget {
  final String emoji;
  final String text;
  const _CareChip({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }
}
