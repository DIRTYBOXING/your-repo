import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMMUNITY GUIDELINES — Rules for a safe and respectful platform
/// Route: /community-guidelines
/// ═══════════════════════════════════════════════════════════════════════════
class CommunityGuidelinesScreen extends StatelessWidget {
  const CommunityGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Row(
          children: [
            Icon(Icons.groups_outlined, color: Colors.cyanAccent, size: 20),
            SizedBox(width: 8),
            Text(
              'Community Guidelines',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade900.withOpacity(0.6),
                  const Color(0xFF0A0A20),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DATAFIGHT CENTRAL',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Community Guidelines',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Last Updated: July 3, 2026',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _section(
            '1. Be Respectful',
            'Treat everyone with respect. Harassment, bullying, hate speech, and personal attacks are not tolerated. We are a community of fighters, fans, and professionals; conduct yourself accordingly.',
          ),

          _section(
            '2. No Illegal Content or Activity',
            'Do not post content that is illegal, promotes illegal acts, or infringes on the rights of others. This includes, but is not limited to, copyright infringement, defamation, and threats of violence.',
          ),

          _section(
            '3. Keep it Relevant',
            'While discussions can be broad, please keep content relevant to combat sports, training, health, and the topics covered by Data Fight Central. Off-topic spam or excessive self-promotion may be removed.',
          ),

           _section(
            '4. Protect Your Privacy (and Others\')',
            'Do not share private information about yourself or others without consent. This includes phone numbers, addresses, and other personal identifying information.',
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.7)),
        ],
      ),
    );
  }
}
