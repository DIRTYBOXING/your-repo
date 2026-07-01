import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// IBC 3 — WORLD PROMO SCREEN
/// "SAMURAI SPAWN INVASION — THE WORLD TUNES IN"
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Route: /ibc/world
///
/// Danny Mac presents IBC 3 — International Brawling Championships
/// March 7, 2026 — 7 PM AEST — Gold Coast Sports & Leisure Centre
///
/// PUTTING THE WORD "BRAWL" BACK IN BRAWLING
/// Every continent. Every country. The whole world invades TONIGHT.
/// ═══════════════════════════════════════════════════════════════════════════
class Ibc3WorldPromoScreen extends StatefulWidget {
  const Ibc3WorldPromoScreen({super.key});

  @override
  State<Ibc3WorldPromoScreen> createState() => _Ibc3WorldPromoScreenState();
}

class _Ibc3WorldPromoScreenState extends State<Ibc3WorldPromoScreen>
    with TickerProviderStateMixin {
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════════════════════
  static final DateTime _eventDate = DateTime(2026, 3, 7, 19); // 7 PM AEST
  Timer? _timer;
  Duration _remaining = Duration.zero;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _glowCtrl;
  late Animation<double> _glow;
  late AnimationController _invasionCtrl;
  late Animation<double> _invasion;

  // REAL IBC 3 Fight Card
  final List<Map<String, String>> _mainCard = [
    {
      'fighter1': 'Jay Cutler',
      'fighter2': 'Luke Modini',
      'title': 'LHW TITLE — 5 ROUNDS',
      'type': 'MAIN EVENT',
    },
    {
      'fighter1': 'Isaac Hardman',
      'fighter2': 'Jonathan Tuhu',
      'title': 'IBC CHAMPIONSHIP — 5 ROUNDS',
      'type': 'CO-MAIN EVENT',
    },
    {
      'fighter1': 'Boaz Kapua',
      'fighter2': 'A. Rosinhaskev',
      'title': 'PRO BOUT — 3 ROUNDS',
      'type': 'MAIN CARD',
    },
    {
      'fighter1': 'Andrew Loulanting',
      'fighter2': 'Bruce Irvine',
      'title': 'PRO BOUT — 3 ROUNDS',
      'type': 'MAIN CARD',
    },
    {
      'fighter1': 'Noah Stevens',
      'fighter2': 'Ronny Hull',
      'title': 'PRO BOUT — 3 ROUNDS',
      'type': 'MAIN CARD',
    },
    {
      'fighter1': 'Mikey Vaotusa',
      'fighter2': 'Jarrod Kaye',
      'title': 'PRO BOUT — 3 ROUNDS',
      'type': 'MAIN CARD',
    },
  ];

  // Global broadcast zones
  final List<Map<String, dynamic>> _worldZones = [
    {
      'flag': '🇦🇺',
      'zone': 'AUSTRALIA',
      'time': '7:00 PM AEST',
      'accent': DesignTokens.neonGold,
    },
    {
      'flag': '🇳🇿',
      'zone': 'NEW ZEALAND',
      'time': '9:00 PM NZDT',
      'accent': DesignTokens.neonGreen,
    },
    {
      'flag': '🇹🇭',
      'zone': 'THAILAND',
      'time': '4:00 PM ICT',
      'accent': DesignTokens.neonAmber,
    },
    {
      'flag': '🇯🇵',
      'zone': 'JAPAN',
      'time': '6:00 PM JST',
      'accent': DesignTokens.neonRed,
    },
    {
      'flag': '🇰🇷',
      'zone': 'SOUTH KOREA',
      'time': '6:00 PM KST',
      'accent': DesignTokens.neonCyan,
    },
    {
      'flag': '🇨🇳',
      'zone': 'CHINA',
      'time': '5:00 PM CST',
      'accent': DesignTokens.neonMagenta,
    },
    {
      'flag': '🇷🇺',
      'zone': 'RUSSIA',
      'time': '12:00 PM MSK',
      'accent': DesignTokens.neonBlue,
    },
    {
      'flag': '🇬🇧',
      'zone': 'UNITED KINGDOM',
      'time': '9:00 AM GMT',
      'accent': DesignTokens.neonCyan,
    },
    {
      'flag': '🇪🇺',
      'zone': 'EUROPE',
      'time': '10:00 AM CET',
      'accent': DesignTokens.neonGold,
    },
    {
      'flag': '🇺🇸',
      'zone': 'USA (EAST)',
      'time': '4:00 AM EST',
      'accent': DesignTokens.neonRed,
    },
    {
      'flag': '🇺🇸',
      'zone': 'USA (WEST)',
      'time': '1:00 AM PST',
      'accent': DesignTokens.neonAmber,
    },
    {
      'flag': '🇧🇷',
      'zone': 'BRAZIL',
      'time': '6:00 AM BRT',
      'accent': DesignTokens.neonGreen,
    },
    {
      'flag': '🇿🇦',
      'zone': 'SOUTH AFRICA',
      'time': '11:00 AM SAST',
      'accent': DesignTokens.neonGold,
    },
    {
      'flag': '🇮🇳',
      'zone': 'INDIA',
      'time': '2:30 PM IST',
      'accent': DesignTokens.neonAmber,
    },
    {
      'flag': '🇵🇭',
      'zone': 'PHILIPPINES',
      'time': '5:00 PM PHT',
      'accent': DesignTokens.neonCyan,
    },
    {
      'flag': '🇦🇪',
      'zone': 'UAE / MIDDLE EAST',
      'time': '1:00 PM GST',
      'accent': DesignTokens.neonGold,
    },
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glow = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _invasionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _invasion = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _invasionCtrl, curve: Curves.easeInOut));

    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _remaining = _eventDate.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _invasionCtrl.dispose();
    super.dispose();
  }

  bool get _isLive => _remaining == Duration.zero;

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          // Cosmic background — red when live, gold for hype
          DFCCosmicBackground(
            particleCount: 30,
            primaryColor: _isLive
                ? DesignTokens.neonRed
                : DesignTokens.neonGold,
            secondaryColor: DesignTokens.neonMagenta,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    children: [
                      _buildHeroBanner(),
                      const SizedBox(height: 16),
                      _buildCountdown(),
                      const SizedBox(height: 20),
                      _buildDannyMacSection(),
                      const SizedBox(height: 20),
                      _buildSamuraiInvasionBanner(),
                      const SizedBox(height: 20),
                      const DFCSectionHeader(
                        title: 'FIGHT CARD',
                        icon: Icons.sports_mma,
                      ),
                      const SizedBox(height: 8),
                      ..._mainCard.map(_buildFightRow),
                      const SizedBox(height: 20),
                      const DFCSectionHeader(
                        title: 'GLOBAL BROADCAST TIMES',
                        icon: Icons.public,
                      ),
                      const SizedBox(height: 8),
                      _buildWorldTimesGrid(),
                      const SizedBox(height: 20),
                      _buildHowToWatch(),
                      const SizedBox(height: 20),
                      _buildShareSection(),
                      const SizedBox(height: 20),
                      _buildContactDannyMac(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Opacity(
                  opacity: _pulse.value,
                  child: Icon(
                    _isLive ? Icons.fiber_manual_record : Icons.sports_mma,
                    color: _isLive
                        ? DesignTokens.neonRed
                        : DesignTokens.neonGold,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFF6B00),
                      Color(0xFFFF3366),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'IBC 3 — WORLD PROMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              if (_isLive)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.neonRed.withValues(
                        alpha: _pulse.value * 0.3,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: DesignTokens.neonRed.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          color: DesignTokens.neonRed,
                          size: 8,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LIVE NOW',
                          style: TextStyle(
                            color: DesignTokens.neonRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const DFCNeonDivider(color: DesignTokens.neonGold),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO BANNER — THE HEADLINE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroBanner() {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A0A00).withValues(alpha: 0.95),
              const Color(0xFF0A0000).withValues(alpha: 0.95),
              DesignTokens.neonRed.withValues(alpha: _glow.value * 0.15),
            ],
          ),
          border: Border.all(
            color: DesignTokens.neonGold.withValues(alpha: _glow.value * 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonGold.withValues(alpha: _glow.value * 0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // IBC LOGO
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ).createShader(bounds),
              child: const Text(
                'IBC',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 16,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF3366)],
              ).createShader(bounds),
              child: const Text(
                'INTERNATIONAL BRAWLING\nCHAMPIONSHIPS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // BRAWL III
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: DesignTokens.neonGold.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'III',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // TAGLINE
            Text(
              'DANNY MAC × DFC\nWORLD BRAWLING TAKEOVER',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'DFC IS THE PROMOTION ENGINE • IBC IS FRONT STAGE',
                style: TextStyle(
                  color: Color(0xFF00D4FF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Event details
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: DesignTokens.neonGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DesignTokens.neonGold.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'TONIGHT — MARCH 7, 2026',
                    style: TextStyle(
                      color: DesignTokens.neonGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '7:00 PM AEST — GOLD COAST SPORTS & LEISURE CENTRE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // PPV CTA
            GestureDetector(
              onTap: () => context.push('/ppv'),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.neonRed,
                        DesignTokens.neonRed.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: DesignTokens.neonRed.withValues(
                          alpha: _pulse.value * 0.5,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'ORDER PPV NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COUNTDOWN
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCountdown() {
    if (_isLive) {
      return DFCCard.glass(
        accent: const Color(0xFF00FF41),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Color(0xFF00FF41), size: 20),
                SizedBox(width: 8),
                Text(
                  'EVENT COMPLETE',
                  style: TextStyle(
                    color: Color(0xFF00FF41),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'JAY CUTLER WINS BY KO',
              style: TextStyle(
                color: Color(0xFF00FF41),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NEW LIGHT HEAVYWEIGHT CHAMPION',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _resultStat('8,400', 'FANS'),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _resultStat('\$1.2M', 'GATE'),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      _resultStat('11', 'BOUTS'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'HARDMAN RETAINS • KAPUA SUBMITS ROSINHASKEV • RECORD NIGHT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }

    final h = _remaining.inHours;
    final m = _remaining.inMinutes % 60;
    final s = _remaining.inSeconds % 60;

    return DFCCard.glass(
      accent: DesignTokens.neonGold,
      child: Column(
        children: [
          const Text(
            'COUNTDOWN TO WAR',
            style: TextStyle(
              color: DesignTokens.neonGold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _countdownUnit(h.toString().padLeft(2, '0'), 'HRS'),
              _countdownSep(),
              _countdownUnit(m.toString().padLeft(2, '0'), 'MIN'),
              _countdownSep(),
              _countdownUnit(s.toString().padLeft(2, '0'), 'SEC'),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'EVERY CONTINENT — EVERY COUNTRY — DON\'T MISS OUT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00FF41),
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _countdownUnit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: DesignTokens.neonGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DesignTokens.neonGold.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _countdownSep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => Opacity(
          opacity: _pulse.value,
          child: const Text(
            ':',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DANNY MAC — ICONIC PROMOTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildDannyMacSection() {
    return DFCCard.glass(
      accent: DesignTokens.neonGold,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.neonGold.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'DM',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                      ).createShader(bounds),
                      child: const Text(
                        'DANNY MAC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ICONIC PROMOTER — IBC FOUNDER',
                      style: TextStyle(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'PROMOTION ENGINE',
                  style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF0000), Color(0xFF00D4FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'IBC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '×',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'DFC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PROMOTIONAL PARTNERS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Text(
                  '"DFC is excited to announce IBC III as a world-class brawling event.\n'
                  'We back promoters from the engine room while they own the spotlight.\n'
                  'Respect to every fighter who left it all in the cage."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '— Danny Mac',
                  style: TextStyle(
                    color: DesignTokens.neonGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _launchUrl(
              'https://www.facebook.com/InternationalBrawlingChampionship',
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1877F2),
                    const Color(0xFF1877F2).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1877F2).withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.facebook, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'CONTACT DANNY MAC ON FACEBOOK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // SAMURAI SPAWN INVASION BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSamuraiInvasionBanner() {
    return AnimatedBuilder(
      animation: _invasion,
      builder: (_, _) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.neonRed.withValues(alpha: 0.15),
              const Color(0xFF0A0000),
              DesignTokens.neonMagenta.withValues(
                alpha: _invasion.value * 0.12,
              ),
            ],
          ),
          border: Border.all(
            color: DesignTokens.neonRed.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neonRed.withValues(
                alpha: _invasion.value * 0.15,
              ),
              blurRadius: 25,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: const [
                      DesignTokens.neonRed,
                      DesignTokens.neonMagenta,
                      DesignTokens.neonRed,
                    ],
                    stops: [0.0, _invasion.value, 1.0],
                  ).createShader(bounds),
                  child: const Text(
                    'SAMURAI SPAWN\nINVASION',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('⚔️', style: TextStyle(fontSize: 24)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'THE DFC SWARM DEPLOYS WORLDWIDE',
              style: TextStyle(
                color: DesignTokens.neonRed.withValues(alpha: 0.9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const DFCNeonDivider(color: DesignTokens.neonRed),
            const SizedBox(height: 12),
            const Text(
              'Every continent. Every timezone.\n'
              'The Samurai Swarm is deployed across all socials.\n'
              'IBC 3 is TONIGHT — the world is watching.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DesignTokens.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            // INVASION STATS
            Row(
              children: [
                _invasionStat('🌏', 'CONTINENTS', '7'),
                _invasionStat('🏴', 'NATIONS', '50+'),
                _invasionStat('📡', 'PLATFORMS', 'ALL'),
                _invasionStat('⚔️', 'SWARM', 'LIVE'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _invasionStat(String emoji, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFightRow(Map<String, String> fight) {
    final isTitle =
        fight['type'] == 'MAIN EVENT' || fight['type'] == 'CO-MAIN EVENT';
    final accent = isTitle ? DesignTokens.neonGold : DesignTokens.neonCyan;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DFCCard.glass(
        accent: accent,
        hasTopGlow: isTitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Text(
                fight['type'] ?? '',
                style: TextStyle(
                  color: accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Fighters
            Row(
              children: [
                Expanded(
                  child: Text(
                    fight['fighter1'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTitle ? 16 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Color(0xFFFF3366),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    fight['fighter2'] ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTitle ? 16 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                fight['title'] ?? '',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WORLD TIMES GRID — Every continent, every timezone
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWorldTimesGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _worldZones.map((zone) {
        final accent = zone['accent'] as Color;
        return Container(
          width: (MediaQuery.of(context).size.width - 48) / 2,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Text(
                zone['flag'] as String,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zone['zone'] as String,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      zone['time'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOW TO WATCH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHowToWatch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DFCSectionHeader(title: 'HOW TO WATCH', icon: Icons.tv),
        const SizedBox(height: 8),
        _watchOption(
          icon: Icons.sports_mma,
          title: 'DFC — DATA FIGHT CENTRAL',
          subtitle: 'Stream live on datafightcentral.com',
          accent: DesignTokens.neonCyan,
          url: 'https://datafightcentral.com',
        ),
        const SizedBox(height: 8),
        _watchOption(
          icon: Icons.play_circle_outline,
          title: 'TRILLER TV+',
          subtitle: 'PPV available worldwide',
          accent: DesignTokens.neonMagenta,
          url: 'https://www.trillertvplus.com',
        ),
        const SizedBox(height: 8),
        _watchOption(
          icon: Icons.live_tv,
          title: 'KAYO SPORTS',
          subtitle: 'Stream in Australia & New Zealand',
          accent: DesignTokens.neonGreen,
          url: 'https://kayosports.com.au',
        ),
        const SizedBox(height: 8),
        _watchOption(
          icon: Icons.facebook,
          title: 'IBC ON FACEBOOK',
          subtitle: 'Updates, results & behind the scenes',
          accent: const Color(0xFF1877F2),
          url: 'https://www.facebook.com/InternationalBrawlingChampionship',
        ),
      ],
    );
  }

  Widget _watchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: DFCCard.glass(
        accent: accent,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: accent.withValues(alpha: 0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARE SECTION — Spread the invasion
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShareSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DFCSectionHeader(title: 'SPREAD THE INVASION', icon: Icons.share),
        const SizedBox(height: 8),
        DFCCard.glass(
          accent: DesignTokens.neonMagenta,
          child: Column(
            children: [
              const Text(
                'COPY & BLAST THIS EVERYWHERE',
                style: TextStyle(
                  color: DesignTokens.neonMagenta,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Text(
                  '🥊 IBC 3 — TONIGHT 🥊\n\n'
                  'International Brawling Championships III\n'
                  'Danny Mac puts the word BRAWL back in BRAWLING\n\n'
                  '🏟️ Gold Coast Sports & Leisure Centre\n'
                  '⏰ 7:00 PM AEST — March 7, 2026\n\n'
                  '🔴 MAIN EVENT: Jay Cutler vs Luke Modini — LHW Title\n'
                  '⚔️ CO-MAIN: Isaac Hardman vs Jonathan Tuhu — IBC Title\n\n'
                  '📺 Watch on DFC, TrillerTV+, Kayo\n'
                  '📲 Contact Danny Mac on Facebook: IBC\n\n'
                  '#IBC3 #InternationalBrawlingChampionships\n'
                  '#DannyMac #BrawlIsBack #DataFightCentral\n'
                  '#GoldCoast #PPV #CombatSports',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          const ClipboardData(
                            text:
                                '🥊 IBC 3 — TONIGHT 🥊\n\n'
                                'International Brawling Championships III\n'
                                'Danny Mac puts the word BRAWL back in BRAWLING\n\n'
                                '🏟️ Gold Coast Sports & Leisure Centre\n'
                                '⏰ 7:00 PM AEST — March 7, 2026\n\n'
                                '🔴 MAIN EVENT: Jay Cutler vs Luke Modini — LHW Title\n'
                                '⚔️ CO-MAIN: Isaac Hardman vs Jonathan Tuhu — IBC Title\n\n'
                                '📺 Watch on DFC, TrillerTV+, Kayo\n'
                                '📲 Contact Danny Mac on Facebook: IBC\n\n'
                                '#IBC3 #InternationalBrawlingChampionships\n'
                                '#DannyMac #BrawlIsBack #DataFightCentral\n'
                                '#GoldCoast #PPV #CombatSports',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '⚔️ IBC 3 Promo copied — DEPLOY IT EVERYWHERE',
                            ),
                            backgroundColor: DesignTokens.neonGold.withValues(
                              alpha: 0.85,
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DesignTokens.neonGold,
                              DesignTokens.neonGold.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.copy, color: Colors.black, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'COPY PROMO',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _launchUrl(
                        'https://twitter.com/intent/tweet?text='
                        '🥊 IBC 3 TONIGHT! Danny Mac puts the word BRAWL back in BRAWLING. '
                        'Jay Cutler vs Luke Modini — LHW Title. '
                        '7PM AEST Gold Coast. PPV on DFC, TrillerTV+, Kayo '
                        '%23IBC3 %23DannyMac %23BrawlIsBack %23DataFightCentral',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'TWEET IT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTACT DANNY MAC
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContactDannyMac() {
    return DFCCard.glass(
      accent: const Color(0xFF1877F2),
      child: Column(
        children: [
          const Text(
            '📲 CONTACT DANNY MAC FOR INFO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sponsorships · Media Passes · Fight Tickets\n'
            'Partnerships · Broadcast Rights · VIP Access',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _launchUrl(
              'https://www.facebook.com/InternationalBrawlingChampionship',
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1877F2),
                    const Color(0xFF1877F2).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1877F2).withValues(alpha: 0.3),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.facebook, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'IBC ON FACEBOOK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'SEARCH: International Brawling Championship',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
