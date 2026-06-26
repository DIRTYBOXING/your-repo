import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC × IBC — OFFICIAL PARTNERSHIP HUB
// "The Handshake" — Facebook-style brand collaboration page
// DataFightCentral × International Brawling Championship
// ═══════════════════════════════════════════════════════════════════════════════

class IbcPartnershipHub extends StatefulWidget {
  const IbcPartnershipHub({super.key});

  @override
  State<IbcPartnershipHub> createState() => _IbcPartnershipHubState();
}

class _IbcPartnershipHubState extends State<IbcPartnershipHub>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _shakeCtrl;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _shake = Tween<double>(
      begin: -0.02,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final eventDate = DateTime(2026, 3, 7, 19);
    final diff = eventDate.difference(now);
    final isLive = diff.isNegative && diff.inHours > -6;
    final isPast = diff.inHours < -6;
    final hours = diff.inHours.clamp(0, 9999);
    final mins = (diff.inMinutes % 60).clamp(0, 59);

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: CustomScrollView(
        slivers: [
          // ── HERO HEADER — THE HANDSHAKE ──
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white70),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A0030),
                      Color(0xFF000A20),
                      Color(0xFF0A0A14),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // ── THE HANDSHAKE ICON ──
                      AnimatedBuilder(
                        animation: _shake,
                        builder: (_, _) => Transform.rotate(
                          angle: _shake.value,
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (_, _) => Transform.scale(
                              scale: _pulse.value,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.deepPurple.withValues(alpha: 0.4),
                                      Colors.cyanAccent.withValues(alpha: 0.1),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.handshake,
                                  size: 56,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── BRAND LOGOS ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _brandBadge('DFC', Colors.cyanAccent),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: ShaderMask(
                              shaderCallback: (rect) => const LinearGradient(
                                colors: [Colors.cyanAccent, Colors.amberAccent],
                              ).createShader(rect),
                              child: const Text(
                                '×',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          _brandBadge('IBC', Colors.amberAccent),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── TITLE ──
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Colors.cyanAccent, Colors.amberAccent],
                        ).createShader(rect),
                        child: const Text(
                          'OFFICIAL PARTNERSHIP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'DataFightCentral × International Brawling Championship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── LIVE / COUNTDOWN ──
                      if (isLive)
                        _liveBadge()
                      else if (!isPast)
                        _countdownRow(hours, mins)
                      else
                        _completedBadge(),
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
                // ── IBC III EVENT CARD ──
                _eventHeroCard(isLive, isPast),
                const SizedBox(height: 20),

                // ── PARTNERSHIP STATUS ──
                _sectionLabel('PARTNERSHIP STATUS', Icons.verified),
                const SizedBox(height: 8),
                _partnershipStatusCard(),
                const SizedBox(height: 20),

                // ── WHAT IS IBC ──
                _sectionLabel('ABOUT IBC', Icons.sports_mma),
                const SizedBox(height: 8),
                _aboutIbcCard(),
                const SizedBox(height: 20),

                // ── WHAT DFC BRINGS ──
                _sectionLabel('WHAT DFC BRINGS', Icons.rocket_launch),
                const SizedBox(height: 8),
                _dfcBringsCard(),
                const SizedBox(height: 20),

                // ── IBC III FIGHT CARD ──
                _sectionLabel(
                  'IBC III — FIGHT CARD',
                  Icons.format_list_numbered,
                ),
                const SizedBox(height: 8),
                _fightCardPreview(),
                const SizedBox(height: 20),

                // ── CO-BRANDED CONTENT ──
                _sectionLabel('CO-BRANDED CONTENT', Icons.campaign),
                const SizedBox(height: 8),
                _coBrandedContent(),
                const SizedBox(height: 20),

                // ── SHARED STATS ──
                _sectionLabel('SHARED REACH', Icons.trending_up),
                const SizedBox(height: 8),
                _sharedReachStats(),
                const SizedBox(height: 20),

                // ── QUICK ACTIONS ──
                _sectionLabel('ACTIONS', Icons.flash_on),
                const SizedBox(height: 8),
                _actionButtons(),
                const SizedBox(height: 20),

                // ── FUTURE EVENTS ──
                _sectionLabel('ROADMAP', Icons.map),
                const SizedBox(height: 8),
                _roadmapCard(),
                const SizedBox(height: 16),

                // ── FOOTER ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Text('🤝', style: TextStyle(fontSize: 28)),
                      SizedBox(height: 8),
                      Text(
                        'DFC × IBC — Rolling Together\n'
                        'Official digital platform partner of the International Brawling Championship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
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

  Widget _brandBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _liveBadge() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, _) => Opacity(
        opacity: _pulse.value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Colors.white, size: 10),
              SizedBox(width: 8),
              Text(
                'LIVE NOW',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countdownRow(int hours, int mins) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _countdownUnit('$hours', 'HOURS'),
        const SizedBox(width: 16),
        const Text(
          ':',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        _countdownUnit('$mins', 'MINS'),
      ],
    );
  }

  Widget _countdownUnit(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Colors.cyanAccent,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _completedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'EVENT COMPLETE',
        style: TextStyle(
          color: Colors.greenAccent,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _eventHeroCard(bool isLive, bool isPast) {
    return GestureDetector(
      onTap: () => context.push('/ibc/live'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isLive
                  ? Colors.red.shade900
                  : Colors.deepPurple.shade900.withValues(alpha: 0.8),
              const Color(0xFF0A0A20),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.cyanAccent.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isLive
                        ? Colors.red
                        : isPast
                        ? Colors.green.shade800
                        : Colors.amber.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isLive
                        ? '🔴 LIVE NOW'
                        : isPast
                        ? 'COMPLETED'
                        : '🔥 TOMORROW — MARCH 7',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handshake, color: Colors.cyanAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'DFC × IBC',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'IBC III',
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'INTERNATIONAL BRAWLING CHAMPIONSHIP',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'CUTLER vs MODINI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Light Heavyweight Title — 5 Rounds',
              style: TextStyle(color: Colors.amberAccent, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Gold Coast Sports & Leisure Centre, QLD',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '7:00 PM AEST',
                  style: TextStyle(
                    color: Colors.cyanAccent.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _streamChip('DFC', Colors.cyanAccent),
                const SizedBox(width: 6),
                _streamChip('TrillerTV+', Colors.amberAccent),
                const SizedBox(width: 6),
                _streamChip('Kayo', Colors.greenAccent),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 4),
                const Text(
                  'VIEW FIGHT CARD',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _streamChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _partnershipStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade900.withValues(alpha: 0.4),
            Colors.cyan.shade900.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.verified, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'ACTIVE PARTNERSHIP',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _statusRow(
            'Status',
            'Official Digital Platform Partner',
            Colors.greenAccent,
          ),
          _statusRow('Since', 'January 2026', Colors.white70),
          _statusRow(
            'Events Covered',
            'IBC 01, IBC 02, IBC 03',
            Colors.white70,
          ),
          _statusRow(
            'Next Event',
            'IBC III — March 7, 2026',
            Colors.amberAccent,
          ),
          _statusRow(
            'Type',
            'Co-branded collaboration (Facebook-style)',
            Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutIbcCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'International Brawling Championship',
            style: TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Founded by Danny Mac on the Gold Coast, the IBC is Australia\'s fastest-growing '
            'combat sport. Closed-fist hybrid format — no grappling, no hugging, just FISTS. '
            'Pure striking action that fans love and fighters respect.\n\n'
            'From sold-out events on the Gold Coast to Las Vegas on the horizon, '
            'the IBC is rewriting the rules of what a fight show can be.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TagChip(label: 'Closed-Fist', color: Colors.amberAccent),
              _TagChip(label: 'No Grappling', color: Colors.redAccent),
              _TagChip(label: 'Gold Coast', color: Colors.cyanAccent),
              _TagChip(label: 'TrillerTV+', color: Colors.green),
              _TagChip(label: 'Danny Mac', color: Colors.purpleAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dfcBringsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What DFC Delivers to IBC',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          _deliveryItem(Icons.live_tv, 'PPV streaming & live chat integration'),
          _deliveryItem(
            Icons.phone_android,
            'Mobile-first fight card & live scoring',
          ),
          _deliveryItem(
            Icons.campaign,
            'AI-powered social content via Samurai Swarm',
          ),
          _deliveryItem(
            Icons.trending_up,
            'Fighter stats, predictions & analytics',
          ),
          _deliveryItem(
            Icons.people,
            'Fan engagement — polls, predictions, reactions',
          ),
          _deliveryItem(
            Icons.newspaper,
            'FightWire news coverage & promo distribution',
          ),
          _deliveryItem(
            Icons.payment,
            'Stripe-powered PPV checkout & subscriptions',
          ),
          _deliveryItem(Icons.map, 'Map Warfare — event pins & gym locator'),
        ],
      ),
    );
  }

  Widget _deliveryItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fightCardPreview() {
    const fights = [
      _FightData(
        'MAIN EVENT',
        'Jay Cutler',
        'Luke Modini',
        'LHW Title — 5 Rds',
        Colors.amberAccent,
        true,
      ),
      _FightData(
        'CO-MAIN',
        'Isaac Hardman',
        'Jonathan Tuhu',
        'IBC Championship — 5 Rds',
        Colors.redAccent,
        true,
      ),
      _FightData(
        'MAIN CARD',
        'Boaz Kapua',
        'A. Rosinhaskev',
        'Pro Bout — 3 Rds',
        Colors.cyanAccent,
        false,
      ),
      _FightData(
        'MAIN CARD',
        'Andrew Loulanting',
        'Bruce Irvine',
        'Pro Bout — 3 Rds',
        Colors.cyanAccent,
        false,
      ),
      _FightData(
        'MAIN CARD',
        'Noah Stevens',
        'Ronny Hull',
        'Pro Bout — 3 Rds',
        Colors.greenAccent,
        false,
      ),
      _FightData(
        'MAIN CARD',
        'Mikey Vaotusa',
        'Jarrod Kaye',
        'Pro Bout — 3 Rds',
        Colors.orangeAccent,
        false,
      ),
      _FightData(
        'MAIN CARD',
        'Corban Mita',
        'Josh Eccles',
        'Pro Bout — 3 Rds',
        Colors.pinkAccent,
        false,
      ),
      _FightData(
        'UNDERCARD',
        'Selwyn Alexander',
        'Petaia Mason',
        'Pro Bout — 3 Rds',
        Colors.greenAccent,
        false,
      ),
      _FightData(
        'UNDERCARD',
        'Gaz Phillips',
        'Damien Johnson',
        'Pro Bout — 3 Rds',
        Colors.cyanAccent,
        false,
      ),
      _FightData(
        'UNDERCARD',
        'Brayden Ion',
        'Spencer Hepi',
        'Pro Bout — 3 Rds',
        Colors.purpleAccent,
        false,
      ),
      _FightData(
        'OPENER',
        'Jay Hepi',
        'Tui Halcrow',
        'Pro Bout — 3 Rds',
        Colors.orangeAccent,
        false,
      ),
    ];

    return Column(
      children: [
        ...fights.map(
          (f) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  f.color.withValues(alpha: f.isMain ? 0.15 : 0.06),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: f.color.withValues(alpha: f.isMain ? 0.4 : 0.15),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    f.label,
                    style: TextStyle(
                      color: f.color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${f.fighter1}  vs  ${f.fighter2}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: f.isMain
                              ? FontWeight.w900
                              : FontWeight.w600,
                          fontSize: f.isMain ? 15 : 13,
                        ),
                      ),
                      Text(
                        f.info,
                        style: TextStyle(
                          color: f.color.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.sports_mma,
                  color: f.color.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.format_list_numbered, size: 16),
            label: const Text('VIEW FULL FIGHT CARD & PREDICTIONS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.all(14),
            ),
            onPressed: () => context.push('/ibc/fight-card'),
          ),
        ),
      ],
    );
  }

  Widget _coBrandedContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade900.withValues(alpha: 0.4),
            Colors.amber.shade900.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Co-Branded Posts & Promotions',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Like Facebook collaborations — every IBC post on DFC shows the 🤝 handshake badge, '
            'cross-promotes on both brands, and shares engagement metrics.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _coBrandPost(
            'IBC III TOMORROW — THE WOOD GETS CHOPPED 🪓',
            'Gold Coast Sports & Leisure Centre, 7 PM AEST. '
                'Cutler vs Modini LHW title. Hardman vs Tuhu IBC Championship. Live on Main Event, Kayo & TrillerTV+.',
            '42.8K',
            '12.6K',
          ),
          const SizedBox(height: 8),
          _coBrandPost(
            'Not long until the wood gets chopped! 🔥',
            'IBC III fight week — weigh-ins done, all fighters on weight. '
                'Who\'s watching tomorrow night? #IBC #GoldCoast',
            '28.1K',
            '8.4K',
          ),
          const SizedBox(height: 8),
          _coBrandPost(
            'IBC is the future of combat sports 🥊',
            'No hugging, no stalling, just FISTS. Danny Mac\'s International '
                'Brawling Championship is changing the game. #IBCBrawling',
            '38K',
            '15.2K',
          ),
        ],
      ),
    );
  }

  Widget _coBrandPost(
    String title,
    String body,
    String views,
    String engagements,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                'DFC × IBC',
                style: TextStyle(
                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$views views',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            '$engagements engagements',
            style: const TextStyle(color: Colors.amberAccent, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _sharedReachStats() {
    return Row(
      children: [
        _reachStat('🤝', '1', 'Partner'),
        const SizedBox(width: 8),
        _reachStat('📺', '3.2K', 'PPV Orders'),
        const SizedBox(width: 8),
        _reachStat('📰', '108K', 'Impressions'),
        const SizedBox(width: 8),
        _reachStat('🔥', '38K', 'Engagement'),
      ],
    );
  }

  Widget _reachStat(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon: Icons.play_circle_fill,
                label: 'WATCH LIVE',
                color: Colors.redAccent,
                onTap: () => context.push('/ppv/ppv-ibc-03/watch'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon: Icons.sports_mma,
                label: 'EVENT DAY',
                color: Colors.cyanAccent,
                onTap: () => context.push('/ibc/live'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon: Icons.shopping_cart,
                label: 'BUY PPV \$29.99',
                color: Colors.amberAccent,
                onTap: () => context.push('/ppv/ppv-ibc-03/watch'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon: Icons.format_list_numbered,
                label: 'FIGHT CARD',
                color: Colors.cyanAccent,
                onTap: () => context.push('/ibc/fight-card'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon: Icons.scoreboard,
                label: 'LIVE SCORING',
                color: const Color(0xFFFF6600),
                onTap: () => context.push('/scoring'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon: Icons.leaderboard,
                label: 'RANKINGS',
                color: const Color(0xFF00FF88),
                onTap: () => context.push('/rankings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                icon: Icons.newspaper,
                label: 'PRESS CENTER',
                color: Colors.cyanAccent,
                onTap: () => context.push('/press'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                icon: Icons.live_tv,
                label: 'TRILLERTV+',
                color: Colors.greenAccent,
                onTap: () => _openUrl('https://www.trillertv.com'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roadmapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roadmapItem(
            'IBC 01',
            'Gold Coast — COMPLETED',
            Colors.greenAccent,
            true,
          ),
          _roadmapItem(
            'IBC 02',
            'Gold Coast — COMPLETED',
            Colors.greenAccent,
            true,
          ),
          _roadmapItem(
            'IBC III',
            'Gold Coast — MARCH 7 🔥',
            Colors.amberAccent,
            false,
          ),
          _roadmapItem(
            'IBC 04',
            'Las Vegas — ANNOUNCED',
            Colors.cyanAccent,
            false,
          ),
          _roadmapItem(
            'IBC 05+',
            'Global expansion — TBA',
            Colors.white38,
            false,
          ),
        ],
      ),
    );
  }

  Widget _roadmapItem(String event, String detail, Color color, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            event,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
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

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
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
}

class _FightData {
  final String label;
  final String fighter1;
  final String fighter2;
  final String info;
  final Color color;
  final bool isMain;
  const _FightData(
    this.label,
    this.fighter1,
    this.fighter2,
    this.info,
    this.color,
    this.isMain,
  );
}
