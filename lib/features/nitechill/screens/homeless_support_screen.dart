import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// POVERTY & HOMELESS SUPPORT — NightChill Program
// Shelters · Food banks · Clothing · Job help · Free training
// ═══════════════════════════════════════════════════════════════════════════════

class HomelessSupportScreen extends StatelessWidget {
  const HomelessSupportScreen({super.key});

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:${number.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF002D2D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.home, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text(
              'Support & Resources',
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
          // ── HERO ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF002D2D), Color(0xFF001A1A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.coffee, color: Colors.amberAccent, size: 40),
                const SizedBox(height: 12),
                const Text(
                  "You Don't Have To Do This Alone",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Free resources for shelter, food, clothing, jobs, and training.\n'
                  'No judgement. No cost. Just help.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── I NEED RIGHT NOW ──
          _sectionHead('I NEED HELP RIGHT NOW'),
          const SizedBox(height: 12),
          _needCard(
            emoji: '🏠',
            title: 'A Place to Sleep Tonight',
            resources: [
              const _Resource(
                'Link2Home NSW',
                '1800 152 152',
                '24/7 housing helpline',
              ),
              const _Resource(
                'Safe Steps VIC',
                '1800 015 188',
                '24/7 family violence response',
              ),
              const _Resource(
                'Homeless Hotline QLD',
                '1800 474 753',
                'Housing & support referrals',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _needCard(
            emoji: '🍞',
            title: 'Food & Meals',
            resources: [
              const _Resource(
                'Foodbank Australia',
                '',
                'Free groceries — foodbank.org.au',
              ),
              const _Resource('OzHarvest', '', 'Free meals — ozharvest.org'),
              const _Resource(
                'Salvation Army',
                '13 72 58',
                'Emergency meals & food vouchers',
              ),
              const _Resource(
                'St Vincent de Paul',
                '13 18 12',
                'Food, clothing, furniture',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _needCard(
            emoji: '👕',
            title: 'Clothing & Essentials',
            resources: [
              const _Resource('Vinnies Shops', '', 'Free or low-cost clothing'),
              const _Resource(
                'Salvation Army Stores',
                '',
                'Emergency clothing packs',
              ),
              const _Resource(
                'Thread Together',
                '',
                'New clothing — threadtogether.org.au',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _needCard(
            emoji: '💊',
            title: 'Health & Medical',
            resources: [
              const _Resource('Healthdirect', '1800 022 222', '24/7 nurse on call'),
              const _Resource(
                'Alcohol & Drug Hotline',
                '1800 250 015',
                '24/7 counselling & referral',
              ),
              const _Resource(
                'Needle & Syringe Programs',
                '',
                '1800 633 353 — harm reduction',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── GETTING BACK ON YOUR FEET ──
          _sectionHead('GETTING BACK ON YOUR FEET'),
          const SizedBox(height: 12),
          _stepCard(
            icon: Icons.work,
            title: 'Job Help',
            items: [
              'Centrelink: 13 28 50 — income support, JobSeeker payments',
              'jobactive.gov.au — free resume help & job matching',
              'Brotherhood of St Laurence — work readiness programs',
              'Many gyms offer free memberships for job seekers — ask NightChill',
            ],
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 12),
          _stepCard(
            icon: Icons.school,
            title: 'Education & Training',
            items: [
              'TAFE fee-free places — check with your state TAFE',
              'Free online courses: Open Universities, Coursera certificates',
              'Libraries offer free WiFi, computers, and study space',
              'DFC offers free training resources through the platform',
            ],
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 12),
          _stepCard(
            icon: Icons.fitness_center,
            title: 'Free Training & Gyms',
            items: [
              'NightChill partners with local gyms for free memberships',
              'Community boxing/martial arts programs — ask your local club',
              "Outdoor fitness groups — free, no membership needed",
              'DFC Fight Camp — free training plans in the app',
            ],
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _stepCard(
            icon: Icons.account_balance,
            title: 'Financial Help',
            items: [
              'Centrelink Crisis Payment: 13 28 50 (one-off emergency payment)',
              'No Interest Loan Scheme (NILS): nils.com.au',
              'Financial counselling: 1800 007 007 (free)',
              'Utility relief: ask your energy/water provider for hardship programs',
            ],
            color: Colors.amber,
          ),
          const SizedBox(height: 24),

          // ── FOR FAMILIES ──
          _sectionHead('FOR FAMILIES'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'For mums, dads, and families doing it tough',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Parentline: 1300 30 1300 — parenting support\n'
                  '• Smith Family: thesmithfamily.com.au — education support\n'
                  '• Anglicare Emergency Relief — food, bills, clothing\n'
                  '• Playgroup Australia — free playgroups for kids under 5\n'
                  '• School breakfast programs — ask your school',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── FOR YOUNG PEOPLE ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Under 25? These are for you',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Kids Helpline: 1800 55 1800\n'
                  '• Headspace: headspace.org.au — free mind health support\n'
                  '• ReachOut: reachout.com — online support & forums\n'
                  '• Mission Australia Youth Programs\n'
                  '• Youth Off The Streets: 1800 005 009',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── BOTTOM MESSAGE ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.withValues(alpha: 0.15),
                  Colors.teal.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Text(
                  '"Rock bottom became the solid foundation\non which I rebuilt my life."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '— J.K. Rowling',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                SizedBox(height: 12),
                Text(
                  'NightChill — a program of the DataFightCentral Foundation.\n'
                  'Every coffee bought helps someone rebuild.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
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
        color: Colors.teal.shade200,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _needCard({
    required String emoji,
    required String title,
    required List<_Resource> resources,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...resources.map(_resourceRow),
        ],
      ),
    );
  }

  Widget _resourceRow(_Resource r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(color: Colors.tealAccent, fontSize: 14),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        r.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (r.number.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _call(r.number),
                        child: Text(
                          r.number,
                          style: const TextStyle(
                            color: Colors.tealAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (r.desc.isNotEmpty)
                  Text(
                    r.desc,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard({
    required IconData icon,
    required String title,
    required List<String> items,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: color, fontSize: 13)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
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

class _Resource {
  final String name;
  final String number;
  final String desc;
  const _Resource(this.name, this.number, this.desc);
}
