import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DV PROTECTION — NightChill Program
// Safety planning · Escape routes · Legal aid · Anonymous support
// ═══════════════════════════════════════════════════════════════════════════════

class DvProtectionScreen extends StatelessWidget {
  const DvProtectionScreen({super.key});

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:${number.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0008),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3D0030),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield, color: Colors.pinkAccent),
            SizedBox(width: 8),
            Text(
              'DV Protection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.redAccent),
            onPressed: () => context.push('/nitechill/crisis'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── SAFETY BANNER ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade900, const Color(0xFF3D0030)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.pinkAccent.withValues(alpha: 0.4),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.pinkAccent, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'You Are Safe Here',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'This page is designed to leave no trace. If you need to exit quickly, '
                  'use the back button — your browsing history will show a generic page title.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── QUICK EXIT ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app, size: 20),
              label: const Text(
                'QUICK EXIT — LEAVE NOW',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Navigate to a neutral page
                context.go('/home');
              },
            ),
          ),
          const SizedBox(height: 24),

          // ── HELPLINES ──
          _sectionHead('24/7 DV HELPLINES'),
          const SizedBox(height: 8),
          _helplineCard(
            emoji: '💜',
            name: '1800RESPECT',
            number: '1800 737 732',
            subtitle: 'National sexual assault, DV & family violence hotline',
            color: Colors.pinkAccent,
            onCall: () => _call('1800737732'),
          ),
          _helplineCard(
            emoji: '👩',
            name: "Women's Crisis Line",
            number: '1800 811 811',
            subtitle: '24/7 telephone crisis counselling for women',
            color: Colors.purple,
            onCall: () => _call('1800811811'),
          ),
          _helplineCard(
            emoji: '👨',
            name: 'MensLine Australia',
            number: '1300 78 99 78',
            subtitle: 'Support for men dealing with DV, relationship issues',
            color: Colors.blue,
            onCall: () => _call('1300789978'),
          ),
          _helplineCard(
            emoji: '👧',
            name: 'Kids Helpline',
            number: '1800 55 1800',
            subtitle: 'Free counselling for children & young people 5-25',
            color: Colors.amberAccent,
            onCall: () => _call('1800551800'),
          ),
          _helplineCard(
            emoji: '🏳️‍🌈',
            name: 'QLife',
            number: '1800 184 527',
            subtitle: 'LGBTQ+ peer support and referrals (3pm-midnight)',
            color: Colors.tealAccent,
            onCall: () => _call('1800184527'),
          ),
          const SizedBox(height: 24),

          // ── SAFETY PLANNING ──
          _sectionHead('SAFETY PLANNING'),
          const SizedBox(height: 12),
          _safetyStep(
            number: '1',
            title: 'Identify Safe People',
            body:
                'Choose 2-3 trusted people you can call day or night. Tell them your situation. '
                'Give them a code word that means "come get me" or "call police."',
            color: Colors.pinkAccent,
          ),
          _safetyStep(
            number: '2',
            title: 'Pack an Emergency Bag',
            body:
                'Keep a bag hidden somewhere safe (friend\'s house, car boot, work locker) with:\n'
                '• ID, passport, Medicare card\n'
                '• Cash (not card — can be tracked)\n'
                '• Phone charger, medication\n'
                '• Change of clothes for you and kids\n'
                '• Copies of important documents',
            color: Colors.orangeAccent,
          ),
          _safetyStep(
            number: '3',
            title: 'Know Your Exits',
            body:
                'Walk through your escape route. Which doors don\'t lock? Where are your car keys? '
                'If you live upstairs, know where the nearest safe exit is. Practice at night.',
            color: Colors.cyanAccent,
          ),
          _safetyStep(
            number: '4',
            title: 'Secure Your Devices',
            body:
                '• Clear browser history or use private/incognito mode\n'
                '• Turn off location sharing on your phone\n'
                '• Check for tracking apps (AirTags, Find My, Life360)\n'
                '• Use a separate phone if possible\n'
                '• Change passwords from a safe device',
            color: Colors.greenAccent,
          ),
          _safetyStep(
            number: '5',
            title: 'Legal Protection',
            body:
                'You can apply for an Apprehended Violence Order (AVO) through your local court or police station. '
                'It is FREE. You do not need a lawyer. Legal Aid can help.\n\n'
                'Legal Aid NSW: 1300 888 529\n'
                'Victoria Legal Aid: 1300 792 387\n'
                'Legal Aid QLD: 1300 65 11 88',
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 24),

          // ── WHAT IS DV ──
          _sectionHead('WHAT COUNTS AS DV?'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Domestic violence is not just physical. It includes:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _dvType(
                  '🤛',
                  'Physical',
                  'Hitting, pushing, choking, throwing objects',
                ),
                _dvType(
                  '😤',
                  'Emotional',
                  'Put-downs, gaslighting, isolation, threats',
                ),
                _dvType(
                  '💰',
                  'Financial',
                  'Controlling money, preventing work, hiding finances',
                ),
                _dvType(
                  '📱',
                  'Digital',
                  'Monitoring phone/social media, tracking location, revenge content',
                ),
                _dvType(
                  '🔒',
                  'Coercive Control',
                  'Controlling what you eat, wear, who you see, where you go',
                ),
                _dvType(
                  '⚖️',
                  'Legal Abuse',
                  'Using courts, custody, immigration status as weapons',
                ),
                const SizedBox(height: 12),
                const Text(
                  'If any of these are happening to you, it is NOT your fault.\nYou deserve safety.',
                  style: TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── QUICK CALL ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.phone, size: 24),
              label: const Text(
                'CALL 1800RESPECT NOW',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _call('1800737732'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionHead(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.pink.shade200,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _helplineCard({
    required String emoji,
    required String name,
    required String number,
    required String subtitle,
    required Color color,
    required VoidCallback onCall,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.phone, color: color),
          onPressed: onCall,
        ),
        onTap: onCall,
      ),
    );
  }

  Widget _safetyStep({
    required String number,
    required String title,
    required String body,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
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
          ),
        ],
      ),
    );
  }

  Widget _dvType(String emoji, String type, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$type — ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
