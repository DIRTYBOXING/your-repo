import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC+ STREAMING SUBSCRIPTION — "Best Deal in Combat Sports"
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Inspired by BKFC+ / Kayo / DAZN landing pages but distinctly DFC:
/// • Animated earth/globe hero section with neon glow
/// • Monthly & Annual pricing (like BKFC+ $7.99/$49.99 but better value)
/// • Rich "Included in your subscription" feature list
/// • Promotion partner grid (UFC, BKFC, ONE, Bellator, etc.)
/// • Live event calendar preview
/// • Device availability strip
/// • FAQ accordion
///
/// Route: /streaming/dfc-plus
/// ═══════════════════════════════════════════════════════════════════════════
class DfcPlusScreen extends StatefulWidget {
  const DfcPlusScreen({super.key});

  @override
  State<DfcPlusScreen> createState() => _DfcPlusScreenState();
}

class _DfcPlusScreenState extends State<DfcPlusScreen>
    with TickerProviderStateMixin {
  bool _isAnnual = true;
  late AnimationController _pulseCtrl;
  late AnimationController _globeCtrl;
  late Animation<double> _pulse;
  late Animation<double> _globeRotate;
  int _expandedFaq = -1;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _globeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _globeRotate = Tween(begin: 0.0, end: 2 * pi).animate(_globeCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _globeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _sliverAppBar(),
          _heroSection(),
          _pricingCards(),
          _includedFeatures(),
          _promotionGrid(),
          _liveCalendar(),
          _deviceStrip(),
          _faqSection(),
          _ctaFooter(),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  SliverAppBar _sliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary.withValues(alpha: 0.95),
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'DFC+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text(
            'LOG IN',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Hero Section with Globe ─────────────────────────────────────────────
  SliverToBoxAdapter _heroSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          children: [
            // Globe visualization
            AnimatedBuilder(
              animation: _globeRotate,
              builder: (context, _) {
                return SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow rings
                      ...List.generate(3, (i) {
                        final size = 140.0 + i * 30;
                        return AnimatedBuilder(
                          animation: _pulse,
                          builder: (ctx, _) => Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: _pulse.value * (0.15 - i * 0.04),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Globe body
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              DesignTokens.neonCyan.withValues(alpha: 0.15),
                              DesignTokens.bgSecondary,
                              DesignTokens.bgPrimary,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Grid lines suggesting earth
                            CustomPaint(
                              size: const Size(130, 130),
                              painter: _GlobeGridPainter(
                                rotation: _globeRotate.value,
                                color: DesignTokens.neonCyan.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            // DFC logo center
                            const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.public,
                                  color: DesignTokens.neonCyan,
                                  size: 32,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'DFC',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Orbiting dots (live event indicators)
                      ...List.generate(5, (i) {
                        final angle = _globeRotate.value + (i * 2 * pi / 5);
                        final radius = 85.0;
                        return Positioned(
                          left: 100 + radius * cos(angle) - 4,
                          top: 100 + radius * sin(angle) * 0.5 - 4,
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (ctx, _) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: [
                                  DesignTokens.neonCyan,
                                  DesignTokens.neonMagenta,
                                  DesignTokens.neonGreen,
                                  DesignTokens.neonAmber,
                                  DesignTokens.neonRed,
                                ][i].withValues(alpha: _pulse.value),
                                boxShadow: [
                                  BoxShadow(
                                    color: [
                                      DesignTokens.neonCyan,
                                      DesignTokens.neonMagenta,
                                      DesignTokens.neonGreen,
                                      DesignTokens.neonAmber,
                                      DesignTokens.neonRed,
                                    ][i].withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Headline
            const Text(
              'BEST DEAL IN\nCOMBAT SPORTS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
              ).createShader(bounds),
              child: const Text(
                'DFC+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Subscribe button
            AnimatedBuilder(
              animation: _pulse,
              builder: (ctx, _) => Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonCyan.withValues(
                        alpha: _pulse.value * 0.3,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: HapticFeedback.mediumImpact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonCyan,
                    foregroundColor: DesignTokens.bgPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SUBSCRIBE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pricing Cards (Monthly / Annual toggle) ─────────────────────────────
  SliverToBoxAdapter _pricingCards() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: DesignTokens.bgCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _billingToggle('Monthly', !_isAnnual),
                  _billingToggle('Annual', _isAnnual),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isAnnual)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Save 48% with annual billing',
                  style: TextStyle(
                    color: DesignTokens.neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            // Price display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _priceCard(
                  _isAnnual ? '\$49.99' : '\$7.99',
                  _isAnnual ? '/Annually' : '/Monthly',
                  _isAnnual,
                ),
              ],
            ),
            if (_isAnnual) ...[
              const SizedBox(height: 8),
              Text(
                'That\'s just \$4.17/month',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _billingToggle(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _isAnnual = label == 'Annual');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? DesignTokens.neonCyan.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? DesignTokens.neonCyan : Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceCard(String price, String period, bool highlight) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (ctx, _) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.bgCard,
              DesignTokens.bgSecondary.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: _pulse.value * 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonCyan.withValues(
                alpha: _pulse.value * 0.1,
              ),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              period,
              style: TextStyle(
                color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Included Features ───────────────────────────────────────────────────
  SliverToBoxAdapter _includedFeatures() {
    const features = [
      {'icon': Icons.live_tv, 'text': 'MONTHLY LIVE EVENTS'},
      {'icon': Icons.video_library, 'text': 'ACCESS TO FULL DFC LIBRARY'},
      {'icon': Icons.movie_filter, 'text': 'BEHIND THE SCENES CONTENT'},
      {'icon': Icons.language, 'text': 'FIGHTS FROM AROUND THE WORLD'},
      {'icon': Icons.confirmation_number, 'text': 'FAST PASS AT DFC EVENTS'},
      {'icon': Icons.local_offer, 'text': 'MERCHANDISE DISCOUNTS'},
      {'icon': Icons.hd, 'text': 'STREAM IN UP TO 4K'},
      {'icon': Icons.devices, 'text': 'WATCH ON ANY DEVICE'},
      {'icon': Icons.videocam, 'text': 'MULTI-CAMERA ANGLES'},
      {'icon': Icons.analytics, 'text': 'LIVE FIGHTER STATS & SCORING'},
      {'icon': Icons.question_answer, 'text': 'EXCLUSIVE FIGHTER Q&A'},
      {'icon': Icons.star, 'text': 'AND MORE'},
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'INCLUDED IN YOUR SUBSCRIPTION:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        f['icon'] as IconData,
                        color: DesignTokens.neonCyan,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      f['text'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Promotion Partner Grid ──────────────────────────────────────────────
  SliverToBoxAdapter _promotionGrid() {
    const promotions = [
      {'name': 'UFC', 'icon': Icons.sports_mma, 'color': 0xFFD4AF37},
      {'name': 'BKFC', 'icon': Icons.front_hand, 'color': 0xFFFF3366},
      {'name': 'ONE FC', 'icon': Icons.looks_one, 'color': 0xFFFF6B35},
      {'name': 'Bellator', 'icon': Icons.military_tech, 'color': 0xFF4FC3F7},
      {'name': 'RIZIN', 'icon': Icons.auto_awesome, 'color': 0xFFCE93D8},
      {'name': 'KSW', 'icon': Icons.flash_on, 'color': 0xFFFFEB3B},
      {'name': 'Boxing', 'icon': Icons.sports_kabaddi, 'color': 0xFF66BB6A},
      {'name': 'Muay Thai', 'icon': Icons.sports, 'color': 0xFFEF5350},
      {
        'name': 'Kickboxing',
        'icon': Icons.sports_martial_arts,
        'color': 0xFF42A5F5,
      },
      {'name': 'BJJ', 'icon': Icons.self_improvement, 'color': 0xFF7E57C2},
      {'name': 'Wrestling', 'icon': Icons.fitness_center, 'color': 0xFFFFA726},
      {'name': 'K-1', 'icon': Icons.bolt, 'color': 0xFF26C6DA},
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            const Text(
              'STREAM EVERY PROMOTION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'All your favourite combat sports in one place',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: promotions.length,
              itemBuilder: (context, index) {
                final p = promotions[index];
                final color = Color(p['color'] as int);
                return Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(p['icon'] as IconData, color: color, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        p['name'] as String,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Live Event Calendar Preview ─────────────────────────────────────────
  SliverToBoxAdapter _liveCalendar() {
    final events = [
      const _UpcomingEvent(
        'Hepi vs Wisniewski',
        'BKFC · Apr 18',
        'LIVE',
        DesignTokens.neonRed,
      ),
      const _UpcomingEvent(
        'Logan Fight Night',
        'DFC Local · Apr 22',
        'UPCOMING',
        DesignTokens.neonAmber,
      ),
      const _UpcomingEvent(
        'ONE Championship 185',
        'ONE FC · Apr 26',
        'UPCOMING',
        DesignTokens.neonCyan,
      ),
      const _UpcomingEvent(
        'UFC Fight Night',
        'UFC · May 3',
        'UPCOMING',
        DesignTokens.neonGold,
      ),
      const _UpcomingEvent(
        'BK Bau vs Hardman',
        'BKFC · May 10',
        'PPV',
        DesignTokens.neonMagenta,
      ),
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: DesignTokens.neonCyan,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Text(
                  'UPCOMING EVENTS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonRed.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '1 LIVE NOW',
                    style: TextStyle(
                      color: DesignTokens.neonRed,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...events.map(_eventRow),
          ],
        ),
      ),
    );
  }

  Widget _eventRow(_UpcomingEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: e.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: e.color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: e.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: e.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              e.badge,
              style: TextStyle(
                color: e.color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Device Availability Strip ───────────────────────────────────────────
  SliverToBoxAdapter _deviceStrip() {
    const devices = [
      {'icon': Icons.phone_iphone, 'label': 'iOS'},
      {'icon': Icons.phone_android, 'label': 'Android'},
      {'icon': Icons.laptop_mac, 'label': 'Web'},
      {'icon': Icons.tv, 'label': 'Smart TV'},
      {'icon': Icons.tablet_mac, 'label': 'Tablet'},
      {'icon': Icons.cast, 'label': 'Chromecast'},
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            const Text(
              'WATCH ANYWHERE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: devices
                  .map(
                    (d) => Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: DesignTokens.neonCyan.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.1,
                              ),
                            ),
                          ),
                          child: Icon(
                            d['icon'] as IconData,
                            color: DesignTokens.neonCyan,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['label'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAQ Accordion ───────────────────────────────────────────────────────
  SliverToBoxAdapter _faqSection() {
    final faqs = [
      const _FaqItem(
        'What is DFC+?',
        'DFC+ is the ultimate combat sports streaming platform. Get access to live events, replays, fighter profiles, multi-cam angles, exclusive interviews, and 500+ hours of content from promotions worldwide.',
      ),
      const _FaqItem(
        'Can I cancel anytime?',
        'Yes. No lock-in contract. Cancel anytime from your account settings. Your access continues until the end of your billing period.',
      ),
      const _FaqItem(
        'Are PPV events included?',
        'DFC+ includes most live events. Select premium PPV cards may have an additional one-time fee at a DFC+ member discount.',
      ),
      const _FaqItem(
        'What devices are supported?',
        'Watch on iOS, Android, web browsers, Smart TVs (Samsung, LG, Apple TV), tablets, and cast to Chromecast or AirPlay devices.',
      ),
      const _FaqItem(
        'Is there a free trial?',
        'New members get their first month for just \$1. After that, you\'ll be charged the standard rate for your chosen plan.',
      ),
      const _FaqItem(
        'How is this different from BKFC+ or UFC Fight Pass?',
        'DFC+ brings ALL combat sports into one platform — UFC, BKFC, ONE FC, Bellator, boxing, kickboxing, and more. Plus exclusive features like multi-cam, live stats, fighter Q&A, and a global community.',
      ),
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FREQUENTLY ASKED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(faqs.length, (i) {
              final faq = faqs[i];
              final expanded = _expandedFaq == i;
              return GestureDetector(
                onTap: () => setState(() => _expandedFaq = expanded ? -1 : i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: expanded
                        ? DesignTokens.neonCyan.withValues(alpha: 0.04)
                        : Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: expanded
                          ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              faq.question,
                              style: TextStyle(
                                color: expanded
                                    ? DesignTokens.neonCyan
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: expanded
                                ? DesignTokens.neonCyan
                                : Colors.white38,
                            size: 20,
                          ),
                        ],
                      ),
                      if (expanded) ...[
                        const SizedBox(height: 10),
                        Text(
                          faq.answer,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── CTA Footer ──────────────────────────────────────────────────────────
  SliverToBoxAdapter _ctaFooter() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.neonCyan.withValues(alpha: 0.08),
              DesignTokens.neonMagenta.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Ready to stream?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get your first month for just \$1',
              style: TextStyle(
                color: DesignTokens.neonGreen.withValues(alpha: 0.9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: HapticFeedback.mediumImpact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonCyan,
                  foregroundColor: DesignTokens.bgPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'START YOUR DFC+ SUBSCRIPTION',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No lock-in contract · Cancel anytime',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Globe Grid Painter ────────────────────────────────────────────────────
class _GlobeGridPainter extends CustomPainter {
  final double rotation;
  final Color color;

  _GlobeGridPainter({required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Latitude lines
    for (int i = 1; i < 5; i++) {
      final y = center.dy + (radius * (i - 2.5) / 2.5) * 0.8;
      final halfWidth = sqrt(
        max(0, radius * radius - (y - center.dy) * (y - center.dy)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, y),
          width: halfWidth * 2,
          height: halfWidth * 0.3,
        ),
        paint,
      );
    }

    // Longitude lines (rotate with animation)
    for (int i = 0; i < 6; i++) {
      final angle = rotation + (i * pi / 6);
      final ellipseWidth = radius * cos(angle).abs() * 0.6;
      if (ellipseWidth > 2) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: ellipseWidth * 2,
            height: radius * 2,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlobeGridPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

// ── Data Classes ──────────────────────────────────────────────────────────
class _UpcomingEvent {
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  const _UpcomingEvent(this.title, this.subtitle, this.badge, this.color);
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}
