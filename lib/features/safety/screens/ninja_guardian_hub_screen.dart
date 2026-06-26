import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NINJA GUARDIAN HUB — DataFightCentral
// 🌸 Sakura (桜) — Women's Safety & DV Protection
// 🪙 Gold Coin — Child Poverty & Free Training
// 💙 Men's Health — Physical & Mental Wellness
// 🌍 Global Emergency Support by Country
// ═══════════════════════════════════════════════════════════════════════════════

class NinjaGuardianHubScreen extends StatefulWidget {
  const NinjaGuardianHubScreen({super.key});

  @override
  State<NinjaGuardianHubScreen> createState() => _NinjaGuardianHubScreenState();
}

class _NinjaGuardianHubScreenState extends State<NinjaGuardianHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _glowCtrl;
  String _selectedCountry = 'AU';

  // Colors
  static const _sakuraPink = Color(0xFFFF69B4);
  static const _goldCoin = Color(0xFFFFD700);
  static const _mensMind = Color(0xFF4169E1);
  static const _bg = Color(0xFF0A0A12);
  static const _card = Color(0xFF12121A);
  static const _cyan = Color(0xFF00E5FF);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:${number.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildSakuraTab(),
                  _buildGoldCoinTab(),
                  _buildMensHealthTab(),
                  _buildEmergencyTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🥷', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 6),
                    Text(
                      'NINJA GUARDIAN HUB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Protection • Support • Community',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // SOS Button
          GestureDetector(
            onTap: _showSOSDialog,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.redAccent.withValues(
                        alpha: 0.3 + _pulseCtrl.value * 0.4,
                      ),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(
                          alpha: _pulseCtrl.value * 0.3,
                        ),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              _sakuraPink.withValues(alpha: 0.3),
              _cyan.withValues(alpha: 0.2),
            ],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(
            icon: Text('🌸', style: TextStyle(fontSize: 18)),
            text: 'Sakura',
          ),
          Tab(
            icon: Text('🪙', style: TextStyle(fontSize: 18)),
            text: 'Gold Coin',
          ),
          Tab(
            icon: Text('💙', style: TextStyle(fontSize: 18)),
            text: "Men's Health",
          ),
          Tab(
            icon: Text('🆘', style: TextStyle(fontSize: 18)),
            text: 'Emergency',
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🌸 SAKURA TAB — Women's Safety
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildSakuraTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _sakuraPink.withValues(alpha: 0.25),
                Colors.purple.withValues(alpha: 0.15),
                _bg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _sakuraPink.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text('🌸', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'SAKURA 桜',
                style: TextStyle(
                  color: _sakuraPink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'The Female Ninja Guardian',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"Every woman deserves to feel safe. Sakura connects survivors with '
                  'female trainers, women-only classes, and trauma-informed coaches. '
                  'Rebuild confidence. Reclaim strength. You are not alone."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Pink Shield Button
        _buildActionCard(
          emoji: '🛡️',
          title: 'Pink Shield Certified Gyms',
          subtitle:
              'Find safe spaces with female trainers & women-only classes',
          color: _sakuraPink,
          onTap: () => context.push('/pink-shield'),
        ),

        // What Sakura Offers
        const SizedBox(height: 16),
        _buildSectionTitle('What Sakura Offers'),
        const SizedBox(height: 8),

        _buildFeatureCard(
          emoji: '👩‍🏫',
          title: 'Female Trainers',
          desc:
              'Request a female coach — no questions asked. Your comfort is paramount.',
          color: _sakuraPink,
        ),
        _buildFeatureCard(
          emoji: '🚺',
          title: 'Women-Only Classes',
          desc:
              'Private sessions for survivors who need space and privacy to heal.',
          color: Colors.purple,
        ),
        _buildFeatureCard(
          emoji: '💜',
          title: 'Trauma-Informed Coaching',
          desc:
              'Certified coaches trained in DV awareness, PTSD response, and survivor support.',
          color: Colors.deepPurple,
        ),
        _buildFeatureCard(
          emoji: '🤝',
          title: 'Safe Check-In',
          desc:
              'Message "Pink Shield" to any certified gym — they know what it means.',
          color: Colors.pink,
        ),
        _buildFeatureCard(
          emoji: '🔇',
          title: 'Silent Alert',
          desc:
              'Triple-tap Sakura to send a silent SOS to your trusted contacts.',
          color: Colors.redAccent,
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('For Survivors'),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _sakuraPink.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Whether you\'ve experienced domestic violence, sexual assault, or any form of abuse — '
                'martial arts can help you rebuild confidence, regain control, and find community.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag('DV Survivors', _sakuraPink),
                  _buildTag('Sexual Assault', Colors.purple),
                  _buildTag('Domestic Abuse', Colors.deepPurple),
                  _buildTag('Bullying', Colors.pink),
                  _buildTag('Anxiety & PTSD', Colors.indigo),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        // DV Hotlines
        _buildSectionTitle('24/7 DV Hotlines'),
        const SizedBox(height: 8),
        _buildHotline(
          '1800RESPECT',
          '1800 737 732',
          'AU — Confidential DV support',
          _sakuraPink,
        ),
        _buildHotline(
          'National DV Hotline',
          '1-800-799-7233',
          'US — 24/7 support',
          Colors.purple,
        ),
        _buildHotline(
          'UK Refuge',
          '0808 2000 247',
          'UK — Free, confidential',
          Colors.deepPurple,
        ),
        _buildHotline(
          'Safe Ireland',
          '1800 341 900',
          'IE — 24/7 crisis support',
          Colors.pink,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🪙 GOLD COIN TAB — Child Poverty & Free Training
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildGoldCoinTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _goldCoin.withValues(alpha: 0.25),
                Colors.orange.withValues(alpha: 0.15),
                _bg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _goldCoin.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Text('🪙', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'GOLD COIN DRIVE',
                style: TextStyle(
                  color: _goldCoin,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$1 Can Change A Child\'s Future',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"Every child deserves a chance. Gold Coin connects underprivileged kids '
                  '— affected by poverty, homelessness, or abuse — with free gym access, '
                  'mentor-funded training, and community support. Building stronger futures."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard('1 in 6', 'Kids in poverty', _goldCoin),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '44,000+',
                'Homeless youth (AU)',
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Free', 'Weekly training', Colors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Global', 'Gym partners', _cyan)),
          ],
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Who Gold Coin Helps'),
        const SizedBox(height: 8),

        _buildFeatureCard(
          emoji: '🏚️',
          title: 'Homeless Youth',
          desc:
              'Kids without stable housing deserve a safe place to train and grow.',
          color: _goldCoin,
        ),
        _buildFeatureCard(
          emoji: '💔',
          title: 'Abuse Survivors',
          desc:
              'Children escaping domestic violence need mentorship and community.',
          color: Colors.orange,
        ),
        _buildFeatureCard(
          emoji: '📚',
          title: 'Poverty-Affected Kids',
          desc: 'When parents can\'t afford gym fees — Gold Coin covers it.',
          color: Colors.amber,
        ),
        _buildFeatureCard(
          emoji: '🌏',
          title: 'Refugees & Immigrants',
          desc: 'New arrivals finding their feet deserve equal opportunities.',
          color: Colors.teal,
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('How Gyms Can Help'),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _goldCoin.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text('🏋️', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text(
                    'Gym Partnership Options',
                    style: TextStyle(
                      color: _goldCoin,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                '1 Free Week',
                'Trial week for underprivileged youth',
              ),
              _buildOptionTile(
                '1 Free Month',
                'Monthly scholarship for at-risk kids',
              ),
              _buildOptionTile(
                'Mentor Package',
                'Pair youth with experienced fighters',
              ),
              _buildOptionTile(
                'Equipment Fund',
                'Gloves, wraps, gear for those in need',
              ),
              _buildOptionTile(
                'Custom Program',
                'Design your own community initiative',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.handshake, size: 18),
                  label: const Text('Register Your Gym'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldCoin,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/gym-registration'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Child Support Hotlines'),
        const SizedBox(height: 8),
        _buildHotline(
          'Kids Helpline',
          '1800 55 1800',
          'AU — Free counselling 5-25',
          _goldCoin,
        ),
        _buildHotline(
          'Childhelp USA',
          '1-800-422-4453',
          'US — 24/7 abuse hotline',
          Colors.orange,
        ),
        _buildHotline(
          'NSPCC',
          '0808 800 5000',
          'UK — Child protection',
          Colors.amber,
        ),
        _buildHotline(
          'Barnardos',
          '1800 222 300',
          'IE — Children\'s charity',
          Colors.teal,
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 💙 MEN'S HEALTH TAB — Physical & Mental Wellness
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildMensHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _mensMind.withValues(alpha: 0.25),
                Colors.blue.shade900.withValues(alpha: 0.15),
                _bg,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _mensMind.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              // Blue ribbon shield icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_mensMind, Colors.blue.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _mensMind.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('💙', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "MEN'S HEALTH",
                style: TextStyle(
                  color: _mensMind,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Breaking the Silence on Men\'s Health',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"In Australia alone, over 2,500 men take their own lives each year. '
                  'That\'s 7 men every single day. Combat sports saved many of us — '
                  'let\'s make sure no one fights their darkest battle alone."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stark Stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Text(
                '⚠️ THE REALITY',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '2,500+',
                      'Men lost yearly (AU)',
                      Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard('7', 'Men every day', Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      '75%',
                      'Of suicides are men',
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      '#1',
                      'Cause of death 15-44',
                      Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('How Combat Sports Help'),
        const SizedBox(height: 8),

        _buildFeatureCard(
          emoji: '🧠',
          title: 'Discipline & Focus',
          desc:
              'Training gives purpose, structure, and something to work towards.',
          color: _mensMind,
        ),
        _buildFeatureCard(
          emoji: '🤝',
          title: 'Brotherhood',
          desc: 'The gym becomes family. You\'re never alone on the mats.',
          color: Colors.blue.shade700,
        ),
        _buildFeatureCard(
          emoji: '💪',
          title: 'Physical Outlet',
          desc:
              'Channel anger, frustration, and pain into something constructive.',
          color: Colors.indigo,
        ),
        _buildFeatureCard(
          emoji: '🎯',
          title: 'Achievement',
          desc: 'Every session is a win. Every belt, every fight — progress.',
          color: Colors.blue.shade900,
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Crisis Support'),
        const SizedBox(height: 8),

        _buildHotline(
          'Lifeline',
          '13 11 14',
          'AU — 24/7 crisis support',
          _mensMind,
        ),
        _buildHotline(
          'Beyond Blue',
          '1300 22 4636',
          'AU — Anxiety & depression',
          Colors.blue.shade700,
        ),
        _buildHotline(
          'MensLine',
          '1300 78 99 78',
          'AU — Men\'s support line',
          Colors.indigo,
        ),
        _buildHotline(
          'Suicide Prevention',
          '988',
          'US — National lifeline',
          Colors.blue.shade900,
        ),
        _buildHotline(
          'Samaritans',
          '116 123',
          'UK — Free 24/7 support',
          Colors.teal,
        ),
        _buildHotline(
          'Crisis Text Line',
          'Text HOME to 741741',
          'US — Text-based support',
          Colors.cyan,
        ),

        const SizedBox(height: 20),

        // You Are Not Alone banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _mensMind.withValues(alpha: 0.3),
                _cyan.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _mensMind.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Text('🫂', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              const Text(
                'YOU ARE NOT ALONE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reaching out is strength, not weakness.\n'
                'Your gym family is here. The DFC community is here.\n'
                'One conversation can save a life.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // 🆘 EMERGENCY TAB — Global Numbers by Country
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildEmergencyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Country Selector
        _buildSectionTitle('Select Your Country'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cyan.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              dropdownColor: _card,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              items: _countries
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['code'],
                      child: Row(
                        children: [
                          Text(
                            c['flag']!,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            c['name']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCountry = v!),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Emergency number for selected country
        ..._getEmergencyNumbers(_selectedCountry),

        const SizedBox(height: 40),
      ],
    );
  }

  List<Widget> _getEmergencyNumbers(String countryCode) {
    final numbers = _emergencyNumbers[countryCode] ?? [];
    final country = _countries.firstWhere((c) => c['code'] == countryCode);

    return [
      // Police/Emergency
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade900.withValues(alpha: 0.3),
              Colors.red.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(
              '${country['flag']} EMERGENCY',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...numbers
                .where((n) => n['type'] == 'emergency')
                .map(
                  (n) => _buildEmergencyButton(
                    n['name']!,
                    n['number']!,
                    Colors.redAccent,
                  ),
                ),
          ],
        ),
      ),

      const SizedBox(height: 16),
      _buildSectionTitle('Crisis & Mental Health'),
      const SizedBox(height: 8),
      ...numbers
          .where((n) => n['type'] == 'crisis')
          .map(
            (n) =>
                _buildHotline(n['name']!, n['number']!, n['desc']!, _mensMind),
          ),

      const SizedBox(height: 16),
      _buildSectionTitle('Domestic Violence'),
      const SizedBox(height: 8),
      ...numbers
          .where((n) => n['type'] == 'dv')
          .map(
            (n) => _buildHotline(
              n['name']!,
              n['number']!,
              n['desc']!,
              _sakuraPink,
            ),
          ),

      const SizedBox(height: 16),
      _buildSectionTitle('Child Protection'),
      const SizedBox(height: 8),
      ...numbers
          .where((n) => n['type'] == 'child')
          .map(
            (n) =>
                _buildHotline(n['name']!, n['number']!, n['desc']!, _goldCoin),
          ),
    ];
  }

  Widget _buildEmergencyButton(String name, String number, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.phone, size: 20),
          label: Text(
            '$name: $number',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _call(number),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SOS DIALOG
  // ══════════════════════════════════════════════════════════════════════════════
  void _showSOSDialog() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.sos, color: Colors.redAccent, size: 28),
            SizedBox(width: 8),
            Text(
              'EMERGENCY SOS',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will alert your trusted contacts with your location.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text(
                  'CALL EMERGENCY (000)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () => _call('000'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.send, color: Colors.orange),
                label: const Text(
                  'Silent Alert to Guardians',
                  style: TextStyle(color: Colors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🛡️ Silent alert sent to your guardians'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildActionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String emoji,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotline(
    String name,
    String number,
    String subtitle,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _call(number),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.phone, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.call, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _goldCoin,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
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
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GLOBAL DATA
// ══════════════════════════════════════════════════════════════════════════════
const _countries = [
  {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
  {'code': 'NZ', 'name': 'New Zealand', 'flag': '🇳🇿'},
  {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
  {'code': 'UK', 'name': 'United Kingdom', 'flag': '🇬🇧'},
  {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
  {'code': 'IE', 'name': 'Ireland', 'flag': '🇮🇪'},
  {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
  {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
  {'code': 'TH', 'name': 'Thailand', 'flag': '🇹🇭'},
  {'code': 'PH', 'name': 'Philippines', 'flag': '🇵🇭'},
  {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷'},
  {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
  {'code': 'SG', 'name': 'Singapore', 'flag': '🇸🇬'},
  {'code': 'AE', 'name': 'UAE', 'flag': '🇦🇪'},
  {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦'},
];

const _emergencyNumbers = {
  'AU': [
    {
      'type': 'emergency',
      'name': 'Police/Fire/Ambulance',
      'number': '000',
      'desc': '',
    },
    {
      'type': 'crisis',
      'name': 'Lifeline',
      'number': '13 11 14',
      'desc': '24/7 crisis support',
    },
    {
      'type': 'crisis',
      'name': 'Beyond Blue',
      'number': '1300 22 4636',
      'desc': 'Anxiety & depression',
    },
    {
      'type': 'crisis',
      'name': 'MensLine',
      'number': '1300 78 99 78',
      'desc': 'Men\'s support',
    },
    {
      'type': 'crisis',
      'name': 'Suicide Callback',
      'number': '1300 659 467',
      'desc': '24/7 support',
    },
    {
      'type': 'dv',
      'name': '1800RESPECT',
      'number': '1800 737 732',
      'desc': '24/7 DV support',
    },
    {
      'type': 'dv',
      'name': 'Women\'s Crisis Line',
      'number': '1800 811 811',
      'desc': 'Victoria',
    },
    {
      'type': 'dv',
      'name': 'DV Connect',
      'number': '1800 811 811',
      'desc': 'Queensland',
    },
    {
      'type': 'child',
      'name': 'Kids Helpline',
      'number': '1800 55 1800',
      'desc': 'Free 5-25yo',
    },
    {
      'type': 'child',
      'name': 'Child Protection',
      'number': '132 111',
      'desc': 'Report abuse',
    },
  ],
  'NZ': [
    {
      'type': 'emergency',
      'name': 'Police/Fire/Ambulance',
      'number': '111',
      'desc': '',
    },
    {
      'type': 'crisis',
      'name': 'Lifeline NZ',
      'number': '0800 543 354',
      'desc': '24/7 support',
    },
    {
      'type': 'crisis',
      'name': 'Depression Helpline',
      'number': '0800 111 757',
      'desc': '24/7',
    },
    {
      'type': 'crisis',
      'name': 'Suicide Crisis',
      'number': '0508 828 865',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'Women\'s Refuge',
      'number': '0800 733 843',
      'desc': '24/7 DV support',
    },
    {
      'type': 'dv',
      'name': 'Shine Helpline',
      'number': '0508 744 633',
      'desc': 'Family violence',
    },
    {
      'type': 'child',
      'name': 'Youthline',
      'number': '0800 376 633',
      'desc': 'Youth support',
    },
    {
      'type': 'child',
      'name': 'Oranga Tamariki',
      'number': '0508 326 459',
      'desc': 'Child protection',
    },
  ],
  'US': [
    {
      'type': 'emergency',
      'name': 'Police/Fire/EMS',
      'number': '911',
      'desc': '',
    },
    {
      'type': 'crisis',
      'name': 'Suicide & Crisis Lifeline',
      'number': '988',
      'desc': '24/7',
    },
    {
      'type': 'crisis',
      'name': 'Crisis Text Line',
      'number': 'Text HOME to 741741',
      'desc': 'Text support',
    },
    {
      'type': 'crisis',
      'name': 'Veterans Crisis',
      'number': '1-800-273-8255',
      'desc': 'Press 1',
    },
    {
      'type': 'dv',
      'name': 'National DV Hotline',
      'number': '1-800-799-7233',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'RAINN',
      'number': '1-800-656-4673',
      'desc': 'Sexual assault',
    },
    {
      'type': 'child',
      'name': 'Childhelp',
      'number': '1-800-422-4453',
      'desc': '24/7 abuse hotline',
    },
    {
      'type': 'child',
      'name': 'National Runaway',
      'number': '1-800-786-2929',
      'desc': 'Youth crisis',
    },
  ],
  'UK': [
    {
      'type': 'emergency',
      'name': 'Police/Fire/Ambulance',
      'number': '999',
      'desc': '',
    },
    {'type': 'emergency', 'name': 'EU Emergency', 'number': '112', 'desc': ''},
    {
      'type': 'crisis',
      'name': 'Samaritans',
      'number': '116 123',
      'desc': 'Free 24/7',
    },
    {
      'type': 'crisis',
      'name': 'CALM',
      'number': '0800 58 58 58',
      'desc': 'Men\'s mental health',
    },
    {
      'type': 'crisis',
      'name': 'Mind',
      'number': '0300 123 3393',
      'desc': 'Mental health',
    },
    {
      'type': 'dv',
      'name': 'National DV Helpline',
      'number': '0808 2000 247',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'Men\'s Advice Line',
      'number': '0808 801 0327',
      'desc': 'Male victims',
    },
    {
      'type': 'child',
      'name': 'NSPCC',
      'number': '0808 800 5000',
      'desc': 'Child protection',
    },
    {
      'type': 'child',
      'name': 'Childline',
      'number': '0800 1111',
      'desc': 'Under 19s',
    },
  ],
  'CA': [
    {
      'type': 'emergency',
      'name': 'Police/Fire/EMS',
      'number': '911',
      'desc': '',
    },
    {
      'type': 'crisis',
      'name': 'Crisis Services Canada',
      'number': '1-833-456-4566',
      'desc': '24/7',
    },
    {
      'type': 'crisis',
      'name': 'Crisis Text Line',
      'number': 'Text HOME to 686868',
      'desc': 'Text',
    },
    {
      'type': 'dv',
      'name': 'Assaulted Women\'s',
      'number': '1-866-863-0511',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'ShelterSafe',
      'number': '1-800-799-7233',
      'desc': 'Find shelter',
    },
    {
      'type': 'child',
      'name': 'Kids Help Phone',
      'number': '1-800-668-6868',
      'desc': 'Youth 24/7',
    },
  ],
  'IE': [
    {
      'type': 'emergency',
      'name': 'Police/Fire/Ambulance',
      'number': '999',
      'desc': '',
    },
    {'type': 'emergency', 'name': 'EU Emergency', 'number': '112', 'desc': ''},
    {
      'type': 'crisis',
      'name': 'Samaritans Ireland',
      'number': '116 123',
      'desc': 'Free 24/7',
    },
    {
      'type': 'crisis',
      'name': 'Pieta House',
      'number': '1800 247 247',
      'desc': 'Suicide & self-harm',
    },
    {
      'type': 'dv',
      'name': 'Women\'s Aid Ireland',
      'number': '1800 341 900',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'Men\'s Aid Ireland',
      'number': '01 554 3811',
      'desc': 'Male victims',
    },
    {
      'type': 'child',
      'name': 'Childline',
      'number': '1800 66 66 66',
      'desc': 'Under 18s',
    },
    {
      'type': 'child',
      'name': 'Barnardos',
      'number': '1800 222 300',
      'desc': 'Children\'s charity',
    },
  ],
  'DE': [
    {'type': 'emergency', 'name': 'Police', 'number': '110', 'desc': ''},
    {'type': 'emergency', 'name': 'Fire/Medical', 'number': '112', 'desc': ''},
    {
      'type': 'crisis',
      'name': 'Telefonseelsorge',
      'number': '0800 111 0 111',
      'desc': '24/7 free',
    },
    {
      'type': 'dv',
      'name': 'Hilfetelefon',
      'number': '08000 116 016',
      'desc': 'Violence against women',
    },
    {
      'type': 'child',
      'name': 'Nummer gegen Kummer',
      'number': '116 111',
      'desc': 'Youth helpline',
    },
  ],
  'FR': [
    {'type': 'emergency', 'name': 'Police', 'number': '17', 'desc': ''},
    {
      'type': 'emergency',
      'name': 'Fire/Medical',
      'number': '15/18',
      'desc': '',
    },
    {'type': 'emergency', 'name': 'EU Emergency', 'number': '112', 'desc': ''},
    {
      'type': 'crisis',
      'name': 'SOS Amitié',
      'number': '09 72 39 40 50',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'Violence Femmes Info',
      'number': '3919',
      'desc': 'DV support',
    },
    {
      'type': 'child',
      'name': 'Enfance en Danger',
      'number': '119',
      'desc': 'Child protection',
    },
  ],
  'TH': [
    {'type': 'emergency', 'name': 'Police', 'number': '191', 'desc': ''},
    {'type': 'emergency', 'name': 'Medical', 'number': '1669', 'desc': ''},
    {
      'type': 'emergency',
      'name': 'Tourist Police',
      'number': '1155',
      'desc': 'English speaking',
    },
    {
      'type': 'crisis',
      'name': 'Mental Health Hotline',
      'number': '1323',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'OSCC Hotline',
      'number': '1300',
      'desc': 'Violence against women',
    },
    {
      'type': 'child',
      'name': 'Child Protection',
      'number': '1387',
      'desc': 'Report abuse',
    },
  ],
  'PH': [
    {'type': 'emergency', 'name': 'Police', 'number': '911', 'desc': ''},
    {'type': 'emergency', 'name': 'Red Cross', 'number': '143', 'desc': ''},
    {
      'type': 'crisis',
      'name': 'NCMH Crisis',
      'number': '0917 899 8727',
      'desc': 'Mental health',
    },
    {
      'type': 'crisis',
      'name': 'Hopeline',
      'number': '2919',
      'desc': 'Suicide prevention',
    },
    {
      'type': 'dv',
      'name': 'VAW Hotline',
      'number': '1343',
      'desc': 'Violence against women',
    },
    {
      'type': 'child',
      'name': 'Bantay Bata',
      'number': '163',
      'desc': 'Child protection',
    },
  ],
  'BR': [
    {'type': 'emergency', 'name': 'Police', 'number': '190', 'desc': ''},
    {
      'type': 'emergency',
      'name': 'Fire/Medical',
      'number': '192/193',
      'desc': '',
    },
    {
      'type': 'crisis',
      'name': 'CVV',
      'number': '188',
      'desc': '24/7 emotional support',
    },
    {
      'type': 'dv',
      'name': 'Ligue 180',
      'number': '180',
      'desc': 'Women\'s hotline',
    },
    {
      'type': 'child',
      'name': 'Disque 100',
      'number': '100',
      'desc': 'Child rights',
    },
  ],
  'JP': [
    {'type': 'emergency', 'name': 'Police', 'number': '110', 'desc': ''},
    {
      'type': 'emergency',
      'name': 'Fire/Ambulance',
      'number': '119',
      'desc': '',
    },
    {
      'type': 'crisis',
      'name': 'TELL Lifeline',
      'number': '03-5774-0992',
      'desc': 'English support',
    },
    {
      'type': 'crisis',
      'name': 'Yorisoi Hotline',
      'number': '0120-279-338',
      'desc': '24/7 Japanese',
    },
    {'type': 'dv', 'name': 'DV Hotline', 'number': '0570-0-55210', 'desc': ''},
    {
      'type': 'child',
      'name': 'Child Guidance',
      'number': '189',
      'desc': 'Child welfare',
    },
  ],
  'SG': [
    {'type': 'emergency', 'name': 'Police', 'number': '999', 'desc': ''},
    {
      'type': 'emergency',
      'name': 'Ambulance/Fire',
      'number': '995',
      'desc': '',
    },
    {
      'type': 'crisis',
      'name': 'SOS Singapore',
      'number': '1800 221 4444',
      'desc': '24/7',
    },
    {
      'type': 'crisis',
      'name': 'IMH Mental Health',
      'number': '6389 2222',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'AWARE',
      'number': '1800 777 5555',
      'desc': 'Women\'s helpline',
    },
    {
      'type': 'child',
      'name': 'Tinkle Friend',
      'number': '1800 274 4788',
      'desc': 'Children',
    },
  ],
  'AE': [
    {'type': 'emergency', 'name': 'Police', 'number': '999', 'desc': ''},
    {'type': 'emergency', 'name': 'Ambulance', 'number': '998', 'desc': ''},
    {
      'type': 'crisis',
      'name': 'Mental Support',
      'number': '800-HOPE (4673)',
      'desc': '',
    },
    {
      'type': 'dv',
      'name': 'Dubai Foundation',
      'number': '800 111',
      'desc': 'Women & children',
    },
    {
      'type': 'child',
      'name': 'Child Protection',
      'number': '800 988',
      'desc': 'Abu Dhabi',
    },
  ],
  'ZA': [
    {'type': 'emergency', 'name': 'Police', 'number': '10111', 'desc': ''},
    {'type': 'emergency', 'name': 'Ambulance', 'number': '10177', 'desc': ''},
    {
      'type': 'crisis',
      'name': 'SADAG',
      'number': '0800 567 567',
      'desc': 'Depression & anxiety',
    },
    {
      'type': 'crisis',
      'name': 'Lifeline SA',
      'number': '0861 322 322',
      'desc': '24/7',
    },
    {
      'type': 'dv',
      'name': 'Stop GBV',
      'number': '0800 150 150',
      'desc': 'Gender-based violence',
    },
    {
      'type': 'child',
      'name': 'Childline SA',
      'number': '0800 055 555',
      'desc': '24/7',
    },
  ],
};
