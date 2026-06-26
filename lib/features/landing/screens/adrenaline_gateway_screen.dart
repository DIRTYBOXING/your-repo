import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_logos.dart';
import '../../../shared/widgets/dfc_card.dart';
import '../../../shared/services/auth_service.dart';
import '../../genie/services/genie_video_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ADRENALINE GATEWAY v4.0 — Cage Entry Protocol
///
/// The first thing people see. Compact. Punchy. Zero wasted space.
///
/// STRUCTURE:
///  1. Ember storm particle canvas (60 sparks, rising)
///  2. Glitch-flicker DFC hero title + tagline
///  3. Stat ticker ribbon (horizontal scroll, glass chips)
///  4. Compact command grid — 6 nodes, tight 3x2
///  5. Pulsing "ENTER THE CAGE" CTA
///  6. Role selector strip (Fighter/Promoter/Fan/Gym/Mentor)
///  7. Fight card previews (upcoming bouts)
///  8. Quote + guest CTA
///
/// Every element custom-painted. Zero third-party packages.
/// ═══════════════════════════════════════════════════════════════════════════

class AdrenalineGatewayScreen extends StatefulWidget {
  const AdrenalineGatewayScreen({super.key});

  @override
  State<AdrenalineGatewayScreen> createState() =>
      _AdrenalineGatewayScreenState();
}

class _AdrenalineGatewayScreenState extends State<AdrenalineGatewayScreen>
    with TickerProviderStateMixin {
  late AnimationController _stormCtrl;
  late AnimationController _glitchCtrl;
  late AnimationController _wireCtrl;
  late AnimationController _entranceCtrl;
  late Animation<double> _heroFade;
  late Animation<double> _gridSlide;
  late Animation<double> _ctaScale;

  final _random = math.Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _particles = List.generate(60, (_) => _Particle.random(_random));

    _stormCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _glitchCtrl = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _wireCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _entranceCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..forward();

    _heroFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _gridSlide = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
    );
    _ctaScale = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.55, 0.85, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _stormCtrl.dispose();
    _glitchCtrl.dispose();
    _wireCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020508),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _stormCtrl,
          _glitchCtrl,
          _wireCtrl,
          _entranceCtrl,
        ]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // Layer 0: Particle storm
              CustomPaint(
                painter: _StormPainter(
                  phase: _stormCtrl.value,
                  particles: _particles,
                ),
              ),

              // Layer 1: Radial vignette
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.3),
                    radius: 1.3,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF020508).withValues(alpha: 0.4),
                      const Color(0xFF020508).withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Layer 2: Wire grid background
              CustomPaint(
                painter: _WireGridPainter(
                  phase: _wireCtrl.value,
                  revealProgress: _gridSlide.value,
                ),
              ),

              // Layer 3: Content
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 14),
                      // Hero brand logo — horizontal DFC badge + text
                      Center(
                        child: Image.asset(
                          AppLogos.full,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildHeroTitle(),
                      const SizedBox(height: 6),
                      _buildSubtitle(),
                      const SizedBox(height: 10),
                      _buildAuthorityBanner(),
                      const SizedBox(height: 20),
                      _buildQuickAccess(),
                      const SizedBox(height: 28),
                      _buildStatTicker(),
                      const SizedBox(height: 24),
                      _buildCommandGrid(),
                      const SizedBox(height: 24),
                      _buildShidoBanner(),
                      const SizedBox(height: 28),
                      _buildEnterButton(),
                      const SizedBox(height: 12),
                      _buildStartOptions(),
                      const SizedBox(height: 24),
                      _buildIbcHero(),
                      const SizedBox(height: 20),
                      _buildRoleStrip(),
                      const SizedBox(height: 20),
                      _buildFightCards(),
                      const SizedBox(height: 24),
                      _buildQuoteSection(),
                      const SizedBox(height: 20),
                      _buildBottomCta(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO TITLE — Glitch-flicker reveal
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroTitle() {
    final glitch = _glitchCtrl.value;
    final isGlitching = glitch > 0.92 && glitch < 0.96;
    final dx = isGlitching ? (_random.nextDouble() - 0.5) * 6 : 0.0;

    return FadeTransition(
      opacity: _heroFade,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Column(
          children: [
            Text(
              '— WELCOME TO THE CAGE —',
              style: TextStyle(
                color: AppColors.neonRed.withValues(alpha: 0.6 + glitch * 0.3),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.neonCyan,
                  AppColors.neonBlue,
                  isGlitching ? AppColors.neonRed : AppColors.neonCyan,
                ],
              ).createShader(bounds),
              child: const Text(
                'DATA FIGHT\nCENTRAL',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return FadeTransition(
      opacity: _heroFade,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'Where fighters become legends.\nData-powered. Community-driven.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorityBanner() {
    return FadeTransition(
      opacity: _heroFade,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.neonRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.neonRed.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonRed.withValues(alpha: 0.22),
              blurRadius: 22,
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'DFC STANDARD',
              style: TextStyle(
                color: AppColors.neonRed,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'DISCIPLINE OVER NOISE.\nNO SHORTCUTS. NO EXCUSES.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK ACCESS — Free features, no login required
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuickAccess() {
    return FadeTransition(
      opacity: _gridSlide,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonCyan.withValues(alpha: 0.05),
              AppColors.neonPurple.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: AppColors.neonCyan.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Sign Up Free — Full Access',
              style: TextStyle(
                color: AppColors.neonCyan,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Browse fights. Find your gym. Connect with fighters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickAccessButton(
                  icon: Icons.explore,
                  label: 'Find\nFriends',
                  color: AppColors.neonCyan,
                  onTap: () => context.push('/register'),
                ),
                _QuickAccessButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  color: AppColors.neonGreen,
                  onTap: () => context.push('/register'),
                ),
                _QuickAccessButton(
                  icon: Icons.people_outline,
                  label: 'Connect',
                  color: AppColors.neonPurple,
                  onTap: () => context.push('/register'),
                ),
                _QuickAccessButton(
                  icon: Icons.feed,
                  label: 'Feed',
                  color: AppColors.neonOrange,
                  onTap: () => context.push('/register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE STAT TICKER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatTicker() {
    final stats = [
      const _TickerStat('LIVE EVENTS', '847', AppColors.neonRed),
      const _TickerStat('FIGHTERS', '24.3K', AppColors.neonCyan),
      const _TickerStat('KO RATE', '61%', AppColors.neonOrange),
      const _TickerStat('PROMOTERS', '1.2K', AppColors.neonGreen),
      const _TickerStat('GYMS', '3.8K', AppColors.neonPurple),
      const _TickerStat('FIGHT CARDS', '156', AppColors.neonMagenta),
    ];

    return FadeTransition(
      opacity: _heroFade,
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stats.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final s = stats[i];
            return _GlassStatChip(stat: s, phase: _wireCtrl.value);
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMAND GRID — Compact 3x2 with inline wires
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCommandGrid() {
    final nodes = [
      const _DashNode(
        'AI Brain',
        Icons.smart_toy,
        AppColors.neonMagenta,
        'Neural Combat Intelligence',
        'Live Engine Connected',
        '/ai-brain',
      ),
      const _DashNode(
        'FightLab',
        Icons.science,
        AppColors.neonGreen,
        'Biometric Performance',
        'Sensors Active',
        '/fightlab',
      ),
      const _DashNode(
        'Analytics',
        Icons.analytics,
        AppColors.neonCyan,
        'Combat Statistics',
        '21 Metrics Tracked',
        '/combat-analytics',
      ),
      const _DashNode(
        'Fight Camp',
        Icons.fitness_center,
        AppColors.neonOrange,
        'Elite Training Protocol',
        'Phase Active',
        '/fight-camp-tools',
      ),
      const _DashNode(
        'Recovery',
        Icons.healing,
        AppColors.neonBlue,
        'Wellness & Recovery',
        'Monitoring 24/7',
        '/recovery',
      ),
      const _DashNode(
        'FightWire',
        Icons.bolt,
        AppColors.neonRed,
        'Real-Time Feed',
        'Live Updates',
        '/fightwire',
      ),
    ];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_gridSlide),
      child: FadeTransition(
        opacity: _gridSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Section header
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonCyan.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SYSTEMS ONLINE',
                    style: TextStyle(
                      color: AppColors.neonCyan.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.neonGreen.withValues(
                        alpha:
                            0.5 + math.sin(_wireCtrl.value * math.pi * 2) * 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonGreen.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'CONNECTED',
                    style: TextStyle(
                      color: AppColors.neonGreen.withValues(alpha: 0.5),
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Compact 3x2 grid — 2026 style, desktop-optimized
              // Uses maxCrossAxisExtent to prevent cards from getting too wide
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200, // Max width per card
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.15, // Slightly wider than tall
                ),
                itemCount: nodes.length,
                itemBuilder: (context, i) {
                  final node = nodes[i];
                  return DFCCard(
                    style: DFCCardStyle.action,
                    accent: node.color,
                    onTap: () => context.push(node.route),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(node.icon, color: node.color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          node.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (node.subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            node.subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                            ),
                          ),
                        ],
                        if (node.statusLabel.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: node.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              node.statusLabel,
                              style: TextStyle(color: node.color, fontSize: 9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTER THE CAGE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildEnterButton() {
    final pulse = math.sin(_wireCtrl.value * math.pi * 2) * 0.5 + 0.5;

    return ScaleTransition(
      scale: _ctaScale,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonRed.withValues(alpha: 0.14 + pulse * 0.14),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: () => context.push('/register'),
          icon: const Icon(Icons.shield_rounded, size: 18),
          label: const Text(
            'ENTER THE CAGE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.8,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.neonRed.withValues(alpha: 0.85),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: AppColors.neonOrange.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartOptions() {
    return FadeTransition(
      opacity: _ctaScale,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go(
                      AppConstants.authEnabled ? '/login' : '/home',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neonCyan,
                      side: BorderSide(
                        color: AppColors.neonCyan.withValues(alpha: 0.45),
                      ),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppConstants.authEnabled ? 'Sign In' : 'Explore App',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                      minimumSize: const Size.fromHeight(42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Create Free Account',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Guest explore ──
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  try {
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    auth.enableEmergencyLocalSession(
                      emailHint: 'guest@datafightcentral.app',
                    );
                  } catch (_) {}
                  context.go('/home');
                },
                icon: Icon(
                  Icons.explore,
                  size: 16,
                  color: AppColors.neonCyan.withValues(alpha: 0.7),
                ),
                label: Text(
                  'Explore as Guest',
                  style: TextStyle(
                    color: AppColors.neonCyan.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'By continuing you agree to DFC Terms and Privacy Policy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IBC III HERO — Live event promo on gateway
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIbcHero() {
    final pulse = math.sin(_wireCtrl.value * math.pi * 2) * 0.5 + 0.5;
    final eventDate = DateTime(2026, 3, 7, 19);
    final now = DateTime.now();
    final diff = eventDate.difference(now);
    final isLive = diff.isNegative && diff.inHours.abs() < 6;
    final isToday = diff.inHours < 24 && !diff.isNegative;
    final isPastEvent = diff.isNegative && diff.inHours.abs() >= 6;

    String badge = 'MARCH 7';
    Color badgeColor = const Color(0xFFFF0040);
    String mainText = 'CUTLER vs MODINI';
    String subtitle = 'LIGHT HEAVYWEIGHT TITLE • 5 ROUNDS • GOLD COAST';
    List<String> chips = ['11 BOUTS', 'PPV \$29.99', '7PM AEST'];

    if (isPastEvent) {
      badge = '✅ RESULTS';
      badgeColor = const Color(0xFF00FF41);
      mainText = 'CUTLER WINS BY KO';
      subtitle = 'NEW LIGHT HEAVYWEIGHT CHAMPION • R2 2:47 • 8,400 FANS';
      chips = ['GATE \$1.2M', '+340% SOCIAL', 'SOLD OUT'];
    } else if (isLive) {
      badge = '🔴 LIVE NOW';
      badgeColor = const Color(0xFFFF0040);
    } else if (isToday) {
      badge = 'TONIGHT';
      badgeColor = const Color(0xFFFF6600);
    } else if (diff.inHours < 48) {
      badge = 'TOMORROW';
      badgeColor = const Color(0xFFFFD700);
    }

    return FadeTransition(
      opacity: _ctaScale,
      child: GestureDetector(
        onTap: () => context.push('/ibc/live'),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isPastEvent
                        ? const Color(0xFF00FF41)
                        : const Color(0xFFFF0040))
                    .withValues(alpha: 0.15 + pulse * 0.08),
                const Color(0xFFFF6600).withValues(alpha: 0.08),
                const Color(0xFF0D0D1A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  (isPastEvent
                          ? const Color(0xFF00FF41)
                          : const Color(0xFFFF0040))
                      .withValues(alpha: 0.3 + pulse * 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (isPastEvent
                            ? const Color(0xFF00FF41)
                            : const Color(0xFFFF0040))
                        .withValues(alpha: 0.1 + pulse * 0.05),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'IBC III',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 12,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                mainText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      (isPastEvent
                              ? const Color(0xFF00FF41)
                              : const Color(0xFFFF0040))
                          .withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ibcInfoChip(chips[0]),
                  const SizedBox(width: 8),
                  _ibcInfoChip(chips[1]),
                  const SizedBox(width: 8),
                  _ibcInfoChip(chips[2]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ibcInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROLE STRIP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRoleStrip() {
    final roles = [
      const _Role('FIGHTER', Icons.sports_mma, AppColors.neonRed, 'fighter'),
      const _Role('PROMOTER', Icons.campaign, AppColors.neonOrange, 'promoter'),
      const _Role('FAN', Icons.people, AppColors.neonCyan, 'fan'),
      const _Role('GYM', Icons.fitness_center, AppColors.neonGreen, 'gym_owner'),
      const _Role('MENTOR', Icons.psychology, AppColors.neonPurple, 'mentor'),
    ];

    return FadeTransition(
      opacity: _ctaScale,
      child: Column(
        children: [
          Text(
            'YOUR FIGHT IDENTITY',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 68,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: roles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final role = roles[i];
                return _RoleChip(
                  role: role,
                  onTap: () => context.push('/register?role=${role.roleKey}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT CARDS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFightCards() {
    final cards = [
      const _FightCardData(
        'TITLE FIGHT',
        'JONES vs MIOCIC',
        'UFC 312 • Las Vegas',
        'SAT 8PM ET',
        AppColors.neonRed,
      ),
      const _FightCardData(
        'MAIN EVENT',
        'Byrne vs NAKAMURA',
        'UFC Fight Night • London',
        'SUN 6PM GMT',
        AppColors.neonOrange,
      ),
      const _FightCardData(
        'RISING STAR',
        'LOCAL PROSPECT — Opponent TBA',
        'DFC Prospect Series',
        'OPEN CHALLENGE',
        AppColors.neonCyan,
      ),
    ];

    return FadeTransition(
      opacity: _ctaScale,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppColors.neonRed.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'UPCOMING WARS',
                  style: TextStyle(
                    color: AppColors.neonRed.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...cards.map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FightCard(data: card, wirePhase: _wireCtrl.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUOTE SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuoteSection() {
    final phase = _wireCtrl.value;
    final quoteIndex = (phase * 3).floor() % 3;
    const quoteTexts = [
      '"Everyone has a plan until they get punched in the face."',
      '"I fear not the man who practised 10,000 kicks once.\nI fear the man who practised one kick 10,000 times."',
      '"A champion is someone who gets up,\neven when they can\'t."',
    ];
    const attributions = ['MIKE TYSON', 'BRUCE LEE', 'JACK DEMPSEY'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.neonRed.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonRed.withValues(alpha: 0.12),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: AppColors.neonRed.withValues(alpha: 0.75),
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  quoteTexts[quoteIndex],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: 32,
                  height: 2,
                  decoration: BoxDecoration(
                    color: AppColors.neonRed.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '— ${attributions[quoteIndex]}',
                  style: TextStyle(
                    color: AppColors.neonRed.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIDO BANNER — Samurai Shido Feature CTA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShidoBanner() {
    return FadeTransition(
      opacity: _ctaScale,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: GenieBannerCTA(compact: true),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM CTA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomCta() {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push('/how-we-work'),
          icon: const Icon(Icons.rule_folder_rounded, size: 16),
          label: const Text(
            'How We Work',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.neonCyan.withValues(alpha: 0.85),
            side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.45)),
            minimumSize: const Size(170, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.go('/register'),
          icon: Icon(
            Icons.explore_outlined,
            size: 16,
            color: AppColors.neonCyan.withValues(alpha: 0.72),
          ),
          label: Text(
            'Create Free Account',
            style: TextStyle(
              color: AppColors.neonCyan.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '\u00A9 2026 DATAFIGHTCENTRAL.COM',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.12),
            fontSize: 8,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUICK ACCESS BUTTON
// ═════════════════════════════════════════════════════════════════════════════
class _QuickAccessButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withValues(alpha: 0.3),
            highlightColor: color.withValues(alpha: 0.1),
            child: Container(
              width: 56,
              height: 56,
              color: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════

class _Particle {
  double x, y, speed, size, angle;
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.angle,
    required this.color,
  });

  factory _Particle.random(math.Random r) {
    const colors = [
      AppColors.neonRed,
      AppColors.neonOrange,
      AppColors.neonCyan,
      Color(0xFFFF6B35),
    ];
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      speed: 0.2 + r.nextDouble() * 0.8,
      size: 0.5 + r.nextDouble() * 2.5,
      angle: r.nextDouble() * math.pi * 2,
      color: colors[r.nextInt(colors.length)],
    );
  }
}

class _TickerStat {
  final String label, value;
  final Color color;
  const _TickerStat(this.label, this.value, this.color);
}

class _DashNode {
  final String label;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String statusLabel;
  final String route;
  const _DashNode(
    this.label,
    this.icon,
    this.color,
    this.subtitle,
    this.statusLabel,
    this.route,
  );
}

class _Role {
  final String label;
  final IconData icon;
  final Color color;
  final String roleKey;
  const _Role(this.label, this.icon, this.color, this.roleKey);
}

class _FightCardData {
  final String tag, title, location, time;
  final Color accent;
  const _FightCardData(
    this.tag,
    this.title,
    this.location,
    this.time,
    this.accent,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// STORM PAINTER — Ember/spark particle field
// ═════════════════════════════════════════════════════════════════════════════
class _StormPainter extends CustomPainter {
  final double phase;
  final List<_Particle> particles;

  _StormPainter({required this.phase, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (phase * p.speed + p.angle) % 1.0;
      final px = (p.x + t * 0.3) % 1.0 * size.width;
      final py = (p.y - t * 0.5 + 1.0) % 1.0 * size.height;

      final alpha = (0.15 + math.sin(t * math.pi) * 0.35).clamp(0.0, 1.0);

      canvas.drawCircle(
        Offset(px, py),
        p.size + 3,
        Paint()
          ..color = p.color.withValues(alpha: alpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        Offset(px, py),
        p.size * 0.5,
        Paint()..color = p.color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StormPainter old) => old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// WIRE GRID PAINTER — Background circuit-board wires
// ═════════════════════════════════════════════════════════════════════════════
class _WireGridPainter extends CustomPainter {
  final double phase;
  final double revealProgress;

  _WireGridPainter({required this.phase, required this.revealProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (revealProgress <= 0) return;

    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 12; i++) {
      final y = size.height * (i / 12.0);
      final alpha = (0.02 + math.sin(phase * math.pi * 2 + i) * 0.02).clamp(
        0.0,
        1.0,
      );
      paint.color = AppColors.neonCyan.withValues(
        alpha: alpha * revealProgress,
      );
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 8.0);
      final alpha = (0.015 + math.sin(phase * math.pi * 2 + i * 0.5) * 0.015)
          .clamp(0.0, 1.0);
      paint.color = AppColors.neonCyan.withValues(
        alpha: alpha * revealProgress,
      );
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final dotPaint = Paint();
    for (int i = 0; i < 5; i++) {
      final ix = (phase * 3 + i * 1.7) % 1.0;
      final iy = (phase * 2 + i * 2.3) % 1.0;
      final dx = ix * size.width;
      final dy = iy * size.height;
      dotPaint.color = AppColors.neonCyan.withValues(
        alpha: 0.08 * revealProgress,
      );
      dotPaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dx, dy), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WireGridPainter old) =>
      old.phase != phase || old.revealProgress != revealProgress;
}

// ═════════════════════════════════════════════════════════════════════════════
// GLASS STAT CHIP
// ═════════════════════════════════════════════════════════════════════════════
class _GlassStatChip extends StatelessWidget {
  final _TickerStat stat;
  final double phase;

  const _GlassStatChip({required this.stat, required this.phase});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: stat.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: stat.color.withValues(alpha: 0.18 + phase * 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stat.label,
                style: TextStyle(
                  color: stat.color.withValues(alpha: 0.5),
                  fontSize: 6,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.value,
                style: TextStyle(
                  color: stat.color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LEGACY COMMAND NODE — Replaced by DfcSystemCard from ui_system
// ═════════════════════════════════════════════════════════════════════════════
/*
class _CommandNode extends StatefulWidget {
  final _DashNode node;
  final double wirePhase;
  final int index;

  const _CommandNode({
    required this.node,
    required this.wirePhase,
    required this.index,
  });

  @override
  State<_CommandNode> createState() => _CommandNodeState();
}

class _CommandNodeState extends State<_CommandNode> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final glow =
        math.sin(widget.wirePhase * math.pi * 2 + widget.index * 0.8) * 0.5 +
        0.5;

    return GestureDetector(
      onTap: () => context.push(widget.node.route),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: node.color.withValues(alpha: 0.04),
                border: Border.all(
                  color: node.color.withValues(alpha: 0.12 + glow * 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: node.color.withValues(alpha: 0.05 + glow * 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(node.icon, color: node.color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    node.label,
                    style: TextStyle(
                      color: node.color,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    node.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.22),
                      fontSize: 6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
*/

// ═════════════════════════════════════════════════════════════════════════════
// ROLE CHIP
// ═════════════════════════════════════════════════════════════════════════════
class _RoleChip extends StatefulWidget {
  final _Role role;
  final VoidCallback onTap;

  const _RoleChip({required this.role, required this.onTap});

  @override
  State<_RoleChip> createState() => _RoleChipState();
}

class _RoleChipState extends State<_RoleChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: role.color.withValues(alpha: _hovered ? 0.12 : 0.05),
            border: Border.all(
              color: role.color.withValues(alpha: _hovered ? 0.3 : 0.12),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: role.color.withValues(alpha: 0.25),
              highlightColor: role.color.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(role.icon, color: role.color, size: 20),
                    const SizedBox(height: 5),
                    Text(
                      role.label,
                      style: TextStyle(
                        color: role.color.withValues(alpha: 0.85),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FIGHT CARD
// ═════════════════════════════════════════════════════════════════════════════
class _FightCard extends StatelessWidget {
  final _FightCardData data;
  final double wirePhase;

  const _FightCard({required this.data, required this.wirePhase});

  @override
  Widget build(BuildContext context) {
    final pulse = math.sin(wirePhase * math.pi * 2) * 0.5 + 0.5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: data.accent.withValues(alpha: 0.04),
            border: Border.all(
              color: data.accent.withValues(alpha: 0.1 + pulse * 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 44,
                decoration: BoxDecoration(
                  color: data.accent,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: data.accent.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: data.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        data.tag,
                        style: TextStyle(
                          color: data.accent,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.location,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  data.time,
                  style: TextStyle(
                    color: data.accent.withValues(alpha: 0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
