import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/helpline_directory.dart';
import '../../../shared/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER PROTECTION PROTOCOL — THE CONSCIENCE OF DATA FIGHT CENTRAL
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Nobody talks about what fighters actually go through.
///
/// The world sees the highlight reel. They don't see the 4am runs on an
/// empty stomach. The brain scans showing damage that can't be undone.
/// The ruined marriages. The kids who grow up without a parent because
/// camp is 12 weeks away from home. The poverty — because promoters take
/// 80% and leave you with nothing. The loneliness of losing a fight and
/// having your entire identity shattered while strangers mock you online.
///
/// Win, lose, or draw — nobody asks: "Are you okay?"
///
/// This screen does. Every section here exists because a fighter somewhere
/// needed it and nobody provided it. This is not a feature. This is a
/// responsibility.
///
///  SECTIONS:
///   1. SHIELD STATUS — Overall protection index
///   2. BRAIN HEALTH — CTE awareness, impact history, cognitive tracking
///   3. BODY DAMAGE — Chronic injuries, pain management, medical clearance
///   4. MIND & SOUL — Depression, isolation, PTSD, anxiety, identity crisis
///   5. FINANCIAL PROTECTION — Poverty prevention, exploitation alerts
///   6. FAMILY & RELATIONSHIPS — Isolation tracker, connection health
///   7. SOCIAL ARMOR — Cyberbullying shield, hate speech blockers
///   8. WEIGHT CUT SAFETY — Dehydration, organ stress
///   9. CORNER STOP AI — When to throw the towel
///  10. CRISIS LIFELINE — Real help, not just a phone number
///  11. LIFE AFTER FIGHTING — Career transition, identity beyond the cage
///  12. THE OATH — Our promise written in stone
///
/// ═══════════════════════════════════════════════════════════════════════════

class FighterSafetyScreen extends StatefulWidget {
  const FighterSafetyScreen({super.key});

  @override
  State<FighterSafetyScreen> createState() => _FighterSafetyScreenState();
}

class _FighterSafetyScreenState extends State<FighterSafetyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _shieldCtrl;
  late final AnimationController _heartCtrl;

  // Overall protection score
  final _shieldScore = 0.82; // 82%

  // Brain health
  final _daysSinceImpact = 47;
  final _concussionCount = 1;
  final _totalImpacts = 234;
  final _cteRiskLevel = 'LOW';
  final _cognitiveScore = 94; // out of 100
  final _lastBrainScan = 'Dec 8, 2025';

  // Body damage
  final _clearanceStatus = 'CLEARED';
  final _lastMedical = 'Jan 14, 2026';
  final _chronicInjuries = 2;
  final _activeRecovery = 1;
  final _painLevel = 3; // 1-10

  // Mental health
  final _mentalStatus = 'STABLE';
  final _depressionRisk = 'LOW';
  final _isolationDays = 4; // days without meaningful social contact
  final _sleepQuality = 6.2; // out of 10
  final _identityScore =
      7.5; // how much identity = fighting (lower = healthier separate identity)

  // Financial
  final _financialRisk = 'MODERATE';
  final _savingsMonths = 3.2; // months of expenses saved
  final _unpaidFights = 0;
  final _contractFairness = 68; // out of 100

  // Family
  final _daysFromFamily = 18;
  final _missedEvents = 2; // birthdays, anniversaries etc in last 6 months
  final _relationshipHealth = 'STRAINED';

  // Social armor
  final _hateMessagesBlocked = 47;
  final _trollAccountsFlagged = 12;
  final _positiveRatio = 0.73; // 73% positive interactions

  // Weight cut
  final _weightCutRisk = 'LOW';
  final _dehydrationLevel = 2.1; // percent

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shieldCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  Color get _statusColor => _clearanceStatus == 'CLEARED'
      ? AppColors.neonGreen
      : _clearanceStatus == 'SUSPENDED'
      ? AppColors.neonRed
      : AppColors.neonOrange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060A14),
      body: Stack(
        children: [
          // Background with shield energy
          AnimatedBuilder(
            animation: _shieldCtrl,
            builder: (_, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ShieldBgPainter(phase: _shieldCtrl.value),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildManifesto()),
                  SliverToBoxAdapter(child: _buildShieldStatus()),
                  SliverToBoxAdapter(child: _buildBrainHealth()),
                  SliverToBoxAdapter(child: _buildBodyDamage()),
                  SliverToBoxAdapter(child: _buildMindAndSoul()),
                  SliverToBoxAdapter(child: _buildFinancialProtection()),
                  SliverToBoxAdapter(child: _buildFamilyConnection()),
                  SliverToBoxAdapter(child: _buildSocialArmor()),
                  SliverToBoxAdapter(child: _buildWeightCutSafety()),
                  SliverToBoxAdapter(child: _buildCornerStopAI()),
                  SliverToBoxAdapter(child: _buildCrisisLifeline()),
                  SliverToBoxAdapter(child: _buildLifeAfterFighting()),
                  SliverToBoxAdapter(child: _buildTheOath()),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18,
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
                    colors: [
                      AppColors.neonRed,
                      AppColors.neonOrange,
                      AppColors.neonAmber,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'FIGHTER PROTECTION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                Text(
                  'THE HUMAN BEHIND THE FIGHTER MATTERS MORE THAN THE FIGHT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Pulsing shield
          AnimatedBuilder(
            animation: _heartCtrl,
            builder: (_, _) {
              final scale =
                  1.0 + math.sin(_heartCtrl.value * math.pi * 2) * 0.08;
              return Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: _statusColor.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _statusColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(Icons.shield, color: _statusColor, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MANIFESTO — The truth nobody says
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildManifesto() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonRed.withValues(alpha: 0.04),
              AppColors.neonOrange.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: AppColors.neonRed.withValues(alpha: 0.4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'WHY THIS EXISTS',
                  style: TextStyle(
                    color: AppColors.neonRed.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Nobody asks a fighter how they\'re really doing.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The world sees the highlights. They don\'t see the brain scans that keep you up at night. '
              'The poverty because promoters took everything. The kids growing up without you because '
              'camp is 12 weeks away. The relationship falling apart. The fans who mock you whether '
              'you win or lose. The injuries that never fully heal.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This page protects you — not just your body, but your brain, your family, '
              'your finances, your mental health, and your dignity. Because you\'re a human first '
              'and a fighter second.',
              style: TextStyle(
                color: AppColors.neonOrange.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHIELD STATUS — Overall protection index
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShieldStatus() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('PROTECTION INDEX', AppColors.neonCyan),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: _ShieldRadarPainter(
                  brainHealth: _cteRiskLevel == 'LOW' ? 0.9 : 0.5,
                  bodyHealth: _clearanceStatus == 'CLEARED' ? 0.85 : 0.3,
                  mentalHealth: _mentalStatus == 'STABLE' ? 0.8 : 0.4,
                  financial: _savingsMonths / 12.0,
                  family: _daysFromFamily > 30 ? 0.3 : 0.7,
                  social: _positiveRatio,
                  phase: _pulseCtrl.value,
                  overallScore: _shieldScore,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Score summary row
          Row(
            children: [
              _shieldStat('BRAIN', '$_cognitiveScore%', AppColors.neonRed),
              const SizedBox(width: 6),
              _shieldStat('BODY', _clearanceStatus, _statusColor),
              const SizedBox(width: 6),
              _shieldStat(
                'MIND',
                _mentalStatus,
                _mentalStatus == 'STABLE'
                    ? AppColors.neonGreen
                    : AppColors.neonOrange,
              ),
              const SizedBox(width: 6),
              _shieldStat(
                'MONEY',
                '${_savingsMonths.toStringAsFixed(1)}mo',
                _savingsMonths >= 6
                    ? AppColors.neonGreen
                    : AppColors.neonOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shieldStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.04),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.4),
                fontSize: 7,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BRAIN HEALTH — CTE, impacts, cognitive tracking
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBrainHealth() {
    final cteColor = _cteRiskLevel == 'LOW'
        ? AppColors.neonGreen
        : _cteRiskLevel == 'MODERATE'
        ? AppColors.neonOrange
        : AppColors.neonRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BRAIN HEALTH', AppColors.neonRed),
          const SizedBox(height: 6),
          Text(
            'Your brain doesn\'t get a second chance. Every impact matters.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonRed,
            Column(
              children: [
                // CTE Risk banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: cteColor.withValues(alpha: 0.06),
                    border: Border.all(color: cteColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.psychology, color: cteColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CTE RISK ASSESSMENT',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              _cteRiskLevel,
                              style: TextStyle(
                                color: cteColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Cognitive Score',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$_cognitiveScore/100',
                            style: const TextStyle(
                              color: AppColors.neonCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Impact timeline
                SizedBox(
                  height: 70,
                  child: CustomPaint(
                    size: const Size(double.infinity, 70),
                    painter: _ImpactTimelinePainter(
                      phase: _pulseCtrl.value,
                      daysSince: _daysSinceImpact,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat(
                      '$_daysSinceImpact',
                      'Days Since\nImpact',
                      AppColors.neonGreen,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_concussionCount',
                      'Concussion\nHistory',
                      AppColors.neonOrange,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_totalImpacts',
                      'Total Impacts\nLogged',
                      AppColors.neonCyan,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      _lastBrainScan,
                      'Last Brain\nScan',
                      AppColors.neonPurple,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _truthBox(
                  Icons.warning_amber,
                  AppColors.neonRed,
                  'CTE is real. It destroys memory, personality, and relationships. '
                  'DFC tracks every hit and will STOP you from fighting if the data says your '
                  'brain needs rest. No promoter, no payday is worth your mind.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY DAMAGE — Chronic injuries, pain, medical clearance
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBodyDamage() {
    final p = math.sin(_pulseCtrl.value * math.pi * 2) * 0.5 + 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('BODY INTEGRITY', AppColors.neonGreen),
          const SizedBox(height: 12),
          // Medical clearance banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: _statusColor.withValues(alpha: 0.04),
              border: Border.all(
                color: _statusColor.withValues(alpha: 0.1 + p * 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withValues(alpha: 0.04 + p * 0.03),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor.withValues(alpha: 0.08),
                    border: Border.all(
                      color: _statusColor.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: _statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MEDICAL CLEARANCE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        _clearanceStatus,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                        ),
                      ),
                      Text(
                        'Last medical: $_lastMedical',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonGreen,
            Column(
              children: [
                Row(
                  children: [
                    _miniStat(
                      '$_chronicInjuries',
                      'Chronic\nInjuries',
                      AppColors.neonOrange,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_activeRecovery',
                      'Active\nRecovery',
                      AppColors.neonCyan,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_painLevel/10',
                      'Pain\nLevel',
                      _painLevel > 5 ? AppColors.neonRed : AppColors.neonGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Vital Redlines
                SizedBox(
                  height: 80,
                  child: CustomPaint(
                    size: const Size(double.infinity, 80),
                    painter: _RedlinePainter(phase: _pulseCtrl.value),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _zoneBadge('SAFE', '<160', AppColors.neonGreen),
                    const SizedBox(width: 6),
                    _zoneBadge('CAUTION', '160-185', AppColors.neonOrange),
                    const SizedBox(width: 6),
                    _zoneBadge('DANGER', '>185', AppColors.neonRed),
                  ],
                ),
                const SizedBox(height: 10),
                _truthBox(
                  Icons.healing,
                  AppColors.neonGreen,
                  'Fighters carry injuries that never fully heal — torn ligaments, '
                  'cracked orbital bones, compressed spines. Your body is not invincible. '
                  'Pain is not weakness. Seeking treatment is not quitting.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIND & SOUL — Depression, isolation, PTSD, identity crisis
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMindAndSoul() {
    final mentalColor = _mentalStatus == 'STABLE'
        ? AppColors.neonGreen
        : _mentalStatus == 'MONITOR'
        ? AppColors.neonOrange
        : AppColors.neonRed;
    final depColor = _depressionRisk == 'LOW'
        ? AppColors.neonGreen
        : _depressionRisk == 'MODERATE'
        ? AppColors.neonOrange
        : AppColors.neonRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('MIND & SOUL', AppColors.neonPurple),
          const SizedBox(height: 6),
          Text(
            'The hardest fights happen inside your own head.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonPurple,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status row
                Row(
                  children: [
                    Expanded(
                      child: _statusPill(
                        'MENTAL STATUS',
                        _mentalStatus,
                        mentalColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statusPill(
                        'DEPRESSION RISK',
                        _depressionRisk,
                        depColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Key metrics
                Row(
                  children: [
                    _miniStat(
                      _sleepQuality.toStringAsFixed(1),
                      'Sleep\nQuality',
                      AppColors.neonCyan,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_isolationDays',
                      'Isolation\nDays',
                      _isolationDays > 7
                          ? AppColors.neonRed
                          : AppColors.neonGreen,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      _identityScore.toStringAsFixed(1),
                      'Identity\nIndex',
                      AppColors.neonAmber,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // What we monitor
                _monitorItem(
                  Icons.nights_stay,
                  'Sleep disruption & nightmare patterns',
                  AppColors.neonCyan,
                ),
                _monitorItem(
                  Icons.people_outline,
                  'Social withdrawal signals',
                  AppColors.neonPurple,
                ),
                _monitorItem(
                  Icons.trending_down,
                  'Training avoidance',
                  AppColors.neonOrange,
                ),
                _monitorItem(
                  Icons.mood_bad,
                  'Post-loss emotional spiral',
                  AppColors.neonRed,
                ),
                _monitorItem(
                  Icons.person_off,
                  'Identity crisis after retirement',
                  AppColors.neonAmber,
                ),
                _monitorItem(
                  Icons.home,
                  'Homesickness & loneliness during camp',
                  AppColors.neonGreen,
                ),

                const SizedBox(height: 14),
                _truthBox(
                  Icons.favorite,
                  AppColors.neonPurple,
                  'Losing a fight doesn\'t make you a loser. Struggling with depression '
                  'doesn\'t make you weak. Missing your family doesn\'t make you soft. '
                  'You stepped into a cage while the world watched — every single person '
                  'who mocks you from their couch will never understand what that takes. '
                  'Your mental health IS your strength.',
                ),

                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.push('/wellness'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.neonPurple.withValues(alpha: 0.08),
                      border: Border.all(
                        color: AppColors.neonPurple.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'OPEN WELLNESS SANCTUARY →',
                        style: TextStyle(
                          color: AppColors.neonPurple.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
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
  // FINANCIAL PROTECTION — Poverty prevention, exploitation
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFinancialProtection() {
    final finColor = _financialRisk == 'LOW'
        ? AppColors.neonGreen
        : _financialRisk == 'MODERATE'
        ? AppColors.neonOrange
        : AppColors.neonRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('FINANCIAL PROTECTION', AppColors.neonAmber),
          const SizedBox(height: 6),
          Text(
            'Most fighters retire broke. Not on our watch.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonAmber,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusPill('FINANCIAL RISK', _financialRisk, finColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Emergency Fund',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${_savingsMonths.toStringAsFixed(1)} months',
                            style: TextStyle(
                              color: _savingsMonths >= 6
                                  ? AppColors.neonGreen
                                  : AppColors.neonOrange,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniStat(
                      '$_unpaidFights',
                      'Unpaid\nFights',
                      _unpaidFights > 0
                          ? AppColors.neonRed
                          : AppColors.neonGreen,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_contractFairness%',
                      'Contract\nFairness',
                      _contractFairness >= 70
                          ? AppColors.neonGreen
                          : AppColors.neonRed,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _exploitAlert(
                  Icons.gavel,
                  'CONTRACT REVIEW — AI scans fight contracts for unfair clauses, '
                  'predatory revenue splits, and hidden obligations.',
                  AppColors.neonAmber,
                ),
                const SizedBox(height: 6),
                _exploitAlert(
                  Icons.savings,
                  'SAVINGS TRACKER — Target 6 months\' expenses before accepting camp. '
                  'Fighting broke destroys performance and safety.',
                  AppColors.neonGreen,
                ),
                const SizedBox(height: 6),
                _exploitAlert(
                  Icons.account_balance,
                  'RETIREMENT PLANNING — Age-adjusted savings targets. Most fighters retire '
                  'by 35 with no pension, no skills, and no safety net.',
                  AppColors.neonCyan,
                ),
                const SizedBox(height: 12),
                _truthBox(
                  Icons.attach_money,
                  AppColors.neonAmber,
                  'The fight game is built on exploiting athletes. Promoters take 80%, '
                  'managers take 20% of what\'s left, and fighters pay for their own camps. '
                  'A fighter earning \$50,000 might take home \$5,000 after expenses. '
                  'This system exists because nobody tracks it. We do.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAMILY & RELATIONSHIPS — Isolation tracker
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFamilyConnection() {
    final relColor = _relationshipHealth == 'STRONG'
        ? AppColors.neonGreen
        : _relationshipHealth == 'STRAINED'
        ? AppColors.neonOrange
        : AppColors.neonRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('FAMILY & CONNECTIONS', AppColors.neonMagenta),
          const SizedBox(height: 6),
          Text(
            'The people who love you didn\'t sign up for this life. Don\'t lose them.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonMagenta,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _statusPill('RELATIONSHIP', _relationshipHealth, relColor),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _miniStat(
                      '$_daysFromFamily',
                      'Days From\nFamily',
                      _daysFromFamily > 21
                          ? AppColors.neonRed
                          : AppColors.neonGreen,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_missedEvents',
                      'Missed Life\nEvents',
                      _missedEvents > 3
                          ? AppColors.neonRed
                          : AppColors.neonOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _monitorItem(
                  Icons.phone,
                  'Daily check-in call reminders',
                  AppColors.neonGreen,
                ),
                _monitorItem(
                  Icons.cake,
                  'Birthday & anniversary alerts',
                  AppColors.neonMagenta,
                ),
                _monitorItem(
                  Icons.child_care,
                  'Kids\' milestone notifications',
                  AppColors.neonCyan,
                ),
                _monitorItem(
                  Icons.favorite,
                  'Relationship health pulse checks',
                  AppColors.neonPurple,
                ),
                _monitorItem(
                  Icons.video_call,
                  'Family video call scheduling',
                  AppColors.neonAmber,
                ),
                const SizedBox(height: 12),
                _truthBox(
                  Icons.home,
                  AppColors.neonMagenta,
                  'Fight camps take you away for months. Your partner raises the kids alone. '
                  'Your parents worry every day. Your friends move on without you. '
                  'The cage takes 15 minutes — the sacrifice takes years. '
                  'We track your connection health because the people waiting at home '
                  'are the ones who pick you up when the world tears you down.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOCIAL ARMOR — Cyberbullying protection
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSocialArmor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('SOCIAL ARMOR', AppColors.neonBlue),
          const SizedBox(height: 6),
          Text(
            'Keyboard warriors will never understand what it takes to step into that cage.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonBlue,
            Column(
              children: [
                Row(
                  children: [
                    _miniStat(
                      '$_hateMessagesBlocked',
                      'Hate Messages\nBlocked',
                      AppColors.neonRed,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '$_trollAccountsFlagged',
                      'Troll Accounts\nFlagged',
                      AppColors.neonOrange,
                    ),
                    const SizedBox(width: 8),
                    _miniStat(
                      '${(_positiveRatio * 100).toInt()}%',
                      'Positive\nInteractions',
                      AppColors.neonGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _monitorItem(
                  Icons.shield,
                  'AI-powered hate speech filter on all DFC content',
                  AppColors.neonBlue,
                ),
                _monitorItem(
                  Icons.block,
                  'Auto-block repeat offenders & troll accounts',
                  AppColors.neonRed,
                ),
                _monitorItem(
                  Icons.visibility_off,
                  'Post-loss comment shield (48h auto-activate)',
                  AppColors.neonOrange,
                ),
                _monitorItem(
                  Icons.sentiment_very_satisfied,
                  'Positive message amplification',
                  AppColors.neonGreen,
                ),
                const SizedBox(height: 12),
                _truthBox(
                  Icons.shield,
                  AppColors.neonBlue,
                  'You lost a fight on Saturday night. By Sunday morning, thousands of people '
                  'who\'ve never been punched in their life are calling you a bum. '
                  'Win, lose, or draw — you showed up. They didn\'t. '
                  'DFC automatically shields you from hate after fights so you can process, '
                  'recover, and come back on YOUR terms. Not theirs.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEIGHT CUT SAFETY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWeightCutSafety() {
    final riskColor = _weightCutRisk == 'LOW'
        ? AppColors.neonGreen
        : _weightCutRisk == 'MODERATE'
        ? AppColors.neonOrange
        : AppColors.neonRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('WEIGHT CUT SAFETY', riskColor),
          const SizedBox(height: 12),
          _glass(
            riskColor,
            Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_weight, color: riskColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'DEHYDRATION RISK:',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: riskColor.withValues(alpha: 0.12),
                      ),
                      child: Text(
                        _weightCutRisk,
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_dehydrationLevel.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: riskColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _safetyRule(
                  Icons.water_drop,
                  'Maximum 8% body weight loss per cut',
                  AppColors.neonCyan,
                ),
                _safetyRule(
                  Icons.thermostat,
                  'No sauna >30 min if dehydrated',
                  AppColors.neonOrange,
                ),
                _safetyRule(
                  Icons.science,
                  'Kidney function monitored via AI',
                  AppColors.neonPurple,
                ),
                _safetyRule(
                  Icons.local_hospital,
                  'Emergency rehydration if >10% loss',
                  AppColors.neonRed,
                ),
                const SizedBox(height: 8),
                _truthBox(
                  Icons.warning_amber,
                  riskColor,
                  'Fighters have died making weight. Kidney failure, seizures, cardiac arrest. '
                  'No fight is worth your life. DFC will flag dangerous cuts and notify '
                  'your team automatically.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORNER STOP AI
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCornerStopAI() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CORNER STOP INTELLIGENCE', AppColors.neonMagenta),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonMagenta,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'When should the towel come in?',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Coach ATLAS calculates a real-time Corner Stop Score during competition — '
                  'giving cornermen data the human eye can\'t see.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                _cornerFactor(
                  'Accumulated head impacts per round',
                  '> 15 significant',
                ),
                _cornerFactor(
                  'Heart rate recovery between rounds',
                  '< 10 bpm drop',
                ),
                _cornerFactor(
                  'Balance & coordination degradation',
                  'Gyroscope drift',
                ),
                _cornerFactor(
                  'Fighter\'s own pre-set quit threshold',
                  'Customizable',
                ),
                const SizedBox(height: 10),
                _truthBox(
                  Icons.pan_tool,
                  AppColors.neonMagenta,
                  'A good corner saves lives. Too many fighters are sent out for "one more round" '
                  'when the data screams stop. This doesn\'t replace a cornerman\'s judgment — '
                  'it gives them the confidence to throw that towel when it matters.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRISIS LIFELINE — Location-aware real help
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCrisisLifeline() {
    // Resolve user country from auth
    final authService = context.read<AuthService>();
    final userCountry = authService.userModel?.metadata?['country'] as String?;
    final helplines = HelplineDirectory.resolve(userCountry);
    final colors = [
      AppColors.neonRed,
      AppColors.neonGreen,
      AppColors.neonCyan,
      AppColors.neonPurple,
      AppColors.neonOrange,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CRISIS LIFELINE', AppColors.neonRed),
          const SizedBox(height: 6),
          Text(
            'You are never alone. Even when it feels like it.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          // Country header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Text(helplines.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${helplines.countryName} — Emergency: ${helplines.emergency}',
                    style: TextStyle(
                      color: AppColors.neonCyan.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _emergencyCard(
            'Emergency Services',
            helplines.emergency,
            Icons.local_hospital,
            AppColors.neonRed,
          ),
          // Render location-aware helplines
          ...helplines.helplines.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _emergencyCard(
                e.value.name,
                e.value.number,
                e.key == 0
                    ? Icons.phone
                    : e.key == 1
                    ? Icons.phone_in_talk
                    : Icons.message,
                colors[e.key % colors.length],
              ),
            ),
          ),
          const SizedBox(height: 6),
          _emergencyCard(
            'DFC Safety Team (24/7)',
            'safety@datafightcentral.com',
            Icons.shield,
            AppColors.neonAmber,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.neonRed.withValues(alpha: 0.04),
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: AppColors.neonRed.withValues(alpha: 0.5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'If you\'re reading this and you\'re struggling: it\'s not your fault, you\'re not alone, '
                    'and reaching out is the bravest thing you\'ll ever do. Braver than any fight.',
                    style: TextStyle(
                      color: AppColors.neonRed.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
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
  // LIFE AFTER FIGHTING — Career transition
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLifeAfterFighting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('LIFE AFTER FIGHTING', AppColors.neonCyan),
          const SizedBox(height: 6),
          Text(
            'Your identity is bigger than the cage.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _glass(
            AppColors.neonCyan,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRANSITION READINESS',
                  style: TextStyle(
                    color: AppColors.neonCyan.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                _transitionItem(
                  Icons.school,
                  'Education & Certification Tracker',
                  'Build credentials while you compete',
                  AppColors.neonCyan,
                ),
                _transitionItem(
                  Icons.work,
                  'Career Skills Portfolio',
                  'Your discipline, leadership, work ethic — documented',
                  AppColors.neonGreen,
                ),
                _transitionItem(
                  Icons.record_voice_over,
                  'Coaching Certification Path',
                  'Give back what you\'ve learned',
                  AppColors.neonOrange,
                ),
                _transitionItem(
                  Icons.campaign,
                  'Personal Brand Builder',
                  'You are more than your record',
                  AppColors.neonMagenta,
                ),
                _transitionItem(
                  Icons.account_balance_wallet,
                  'Post-Career Financial Plan',
                  'What does life look like at 40?',
                  AppColors.neonAmber,
                ),
                _transitionItem(
                  Icons.diversity_3,
                  'Fighter Alumni Network',
                  'Connect with fighters who\'ve been where you are',
                  AppColors.neonPurple,
                ),
                const SizedBox(height: 12),
                _truthBox(
                  Icons.emoji_people,
                  AppColors.neonCyan,
                  'The average fighting career lasts 7 years. Then what? Too many fighters '
                  'retire with brain damage, no savings, no skills, and no identity outside '
                  'the sport. We help you build a life WHILE you fight — so when the gloves '
                  'come off, you don\'t lose yourself.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // THE OATH — Our unbreakable promise
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTheOath() {
    final p = math.sin(_pulseCtrl.value * math.pi * 2) * 0.5 + 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.02),
              Colors.white.withValues(alpha: 0.01),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.04 + p * 0.02),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonCyan.withValues(alpha: 0.02 + p * 0.02),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _heartCtrl,
              builder: (_, _) {
                final scale =
                    1.0 + math.sin(_heartCtrl.value * math.pi * 2) * 0.1;
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.shield,
                    color: AppColors.neonCyan.withValues(alpha: 0.25),
                    size: 36,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.neonCyan, AppColors.neonPurple],
              ).createShader(bounds),
              child: const Text(
                'THE DFC OATH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We will never prioritize entertainment over a fighter\'s wellbeing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We will protect your brain when promoters won\'t.\n'
              'We will track your money when the industry looks away.\n'
              'We will guard your relationships when the sport pulls you apart.\n'
              'We will shield you from hate when the crowd turns.\n'
              'We will plan your future when the fight game forgets you.\n'
              'We will be here when nobody else is.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
                height: 1.8,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Because you are a human first and a fighter second.\n'
              'And no result — win, lose, or draw — changes your worth.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neonCyan.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _glass(Color accent, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: accent.withValues(alpha: 0.03),
            border: Border.all(color: accent.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withValues(alpha: 0.04),
          border: Border.all(color: color.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color.withValues(alpha: 0.5),
                fontSize: 7,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneBadge(String label, String range, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.05),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            Text(
              range,
              style: TextStyle(
                color: color.withValues(alpha: 0.4),
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monitorItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyRule(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.5), size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _truthBox(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.4), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _exploitAlert(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
          ),
          child: Icon(icon, color: color.withValues(alpha: 0.5), size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _cornerFactor(String factor, String threshold) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonMagenta.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              factor,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
              ),
            ),
          ),
          Text(
            threshold,
            style: TextStyle(
              color: AppColors.neonMagenta.withValues(alpha: 0.4),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transitionItem(
    IconData icon,
    String title,
    String desc,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: color.withValues(alpha: 0.06),
            ),
            child: Icon(icon, color: color.withValues(alpha: 0.5), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emergencyCard(
    String name,
    String contact,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color.withValues(alpha: 0.03),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            contact,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIELD BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _ShieldBgPainter extends CustomPainter {
  final double phase;
  _ShieldBgPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    // Protective aura — warm, deep tones
    final positions = [
      [0.2, 0.1, AppColors.neonRed],
      [0.8, 0.3, AppColors.neonOrange],
      [0.3, 0.6, AppColors.neonPurple],
      [0.7, 0.9, AppColors.neonCyan],
    ];
    for (int i = 0; i < positions.length; i++) {
      final x =
          size.width * (positions[i][0] as double) +
          math.sin(phase * math.pi * 2 + i * 1.5) * 40;
      final y =
          size.height * (positions[i][1] as double) +
          math.cos(phase * math.pi * 2 + i) * 30;
      paint.color = (positions[i][2] as Color).withValues(alpha: 0.008);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 350, height: 250),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShieldBgPainter old) => old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIELD RADAR PAINTER — 6-axis protection score
// ═══════════════════════════════════════════════════════════════════════════
class _ShieldRadarPainter extends CustomPainter {
  final double brainHealth, bodyHealth, mentalHealth, financial, family, social;
  final double phase, overallScore;

  _ShieldRadarPainter({
    required this.brainHealth,
    required this.bodyHealth,
    required this.mentalHealth,
    required this.financial,
    required this.family,
    required this.social,
    required this.phase,
    required this.overallScore,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    final labels = ['BRAIN', 'BODY', 'MIND', 'MONEY', 'FAMILY', 'SOCIAL'];
    final values = [
      brainHealth,
      bodyHealth,
      mentalHealth,
      financial,
      family,
      social,
    ];
    final colors = [
      AppColors.neonRed,
      AppColors.neonGreen,
      AppColors.neonPurple,
      AppColors.neonAmber,
      AppColors.neonMagenta,
      AppColors.neonBlue,
    ];

    // Grid rings
    for (int ring = 1; ring <= 3; ring++) {
      final rr = r * ring / 3;
      final path = Path();
      for (int i = 0; i <= 6; i++) {
        final angle = math.pi * 2 * i / 6 - math.pi / 2;
        final x = cx + rr * math.cos(angle);
        final y = cy + rr * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Axis lines
    for (int i = 0; i < 6; i++) {
      final angle = math.pi * 2 * i / 6 - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 0.5,
      );
    }

    // Data polygon
    final dataPath = Path();
    for (int i = 0; i <= 6; i++) {
      final idx = i % 6;
      final angle = math.pi * 2 * idx / 6 - math.pi / 2;
      final v = values[idx] * r;
      final x = cx + v * math.cos(angle);
      final y = cy + v * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }

    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Vertex dots + labels
    for (int i = 0; i < 6; i++) {
      final angle = math.pi * 2 * i / 6 - math.pi / 2;
      final v = values[i] * r;
      final x = cx + v * math.cos(angle);
      final y = cy + v * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = colors[i].withValues(alpha: 0.7),
      );

      // Label
      final lx = cx + (r + 16) * math.cos(angle);
      final ly = cy + (r + 16) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i].withValues(alpha: 0.5),
            fontSize: 7,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }

    // Center score
    final p = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
    canvas.drawCircle(
      Offset(cx, cy),
      24,
      Paint()..color = AppColors.neonCyan.withValues(alpha: 0.04 + p * 0.02),
    );
    final scoreTp = TextPainter(
      text: TextSpan(
        text: '${(overallScore * 100).toInt()}',
        style: TextStyle(
          color: AppColors.neonCyan.withValues(alpha: 0.7),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(
      canvas,
      Offset(cx - scoreTp.width / 2, cy - scoreTp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ShieldRadarPainter old) => old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// IMPACT TIMELINE PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _ImpactTimelinePainter extends CustomPainter {
  final double phase;
  final int daysSince;

  _ImpactTimelinePainter({required this.phase, required this.daysSince});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    canvas.drawLine(
      Offset(0, mid),
      Offset(w, mid),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..strokeWidth = 1,
    );

    // Risk zones
    final zones = [
      [0.0, 0.2, AppColors.neonRed],
      [0.2, 0.5, AppColors.neonOrange],
      [0.5, 0.8, AppColors.neonGreen],
      [0.8, 1.0, AppColors.neonCyan],
    ];
    for (final z in zones) {
      canvas.drawRect(
        Rect.fromLTRB(
          w * (z[0] as double),
          mid - 3,
          w * (z[1] as double),
          mid + 3,
        ),
        Paint()..color = (z[2] as Color).withValues(alpha: 0.12),
      );
    }

    final pos = (daysSince / 60.0).clamp(0.0, 1.0);
    final cx = w * pos;
    final p = math.sin(phase * math.pi * 2) * 0.5 + 0.5;

    canvas.drawCircle(
      Offset(cx, mid),
      8 + p * 3,
      Paint()
        ..color = AppColors.neonGreen.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      Offset(cx, mid),
      5,
      Paint()..color = AppColors.neonGreen.withValues(alpha: 0.7),
    );

    for (int d = 0; d <= 60; d += 15) {
      final x = w * d / 60;
      final tp = TextPainter(
        text: TextSpan(
          text: '${d}d',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 7,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, mid + 10));
    }
  }

  @override
  bool shouldRepaint(covariant _ImpactTimelinePainter old) =>
      old.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// REDLINE PAINTER — Heart rate danger zone
// ═══════════════════════════════════════════════════════════════════════════
class _RedlinePainter extends CustomPainter {
  final double phase;
  _RedlinePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = math.Random(42);

    final safeH = h * 0.45;
    final cautionH = h * 0.25;

    canvas.drawRect(
      Rect.fromLTRB(0, h - safeH, w, h),
      Paint()..color = AppColors.neonGreen.withValues(alpha: 0.03),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, h - safeH - cautionH, w, h - safeH),
      Paint()..color = AppColors.neonOrange.withValues(alpha: 0.03),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, h - safeH - cautionH),
      Paint()..color = AppColors.neonRed.withValues(alpha: 0.03),
    );

    final path = Path();
    path.moveTo(0, h * 0.7);
    for (double x = 0; x <= w; x += 2) {
      final t = x / w;
      double hr;
      if (t < 0.2) {
        hr = 0.7 - t * 1.5;
      } else if (t < 0.6) {
        hr = 0.4 - math.sin((t - 0.2) * 5) * 0.15 + r.nextDouble() * 0.05;
      } else if (t < 0.75) {
        hr = 0.15 + r.nextDouble() * 0.05;
      } else {
        hr = 0.15 + (t - 0.75) * 2.0;
      }
      path.lineTo(x, h * hr.clamp(0.05, 0.95));
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.neonOrange.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.neonOrange.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final redY = h * 0.3;
    final p = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
    canvas.drawLine(
      Offset(0, redY),
      Offset(w, redY),
      Paint()
        ..color = AppColors.neonRed.withValues(alpha: 0.15 + p * 0.1)
        ..strokeWidth = 1,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '185 BPM REDLINE',
        style: TextStyle(
          color: AppColors.neonRed.withValues(alpha: 0.5),
          fontSize: 7,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w - tp.width - 4, redY - 10));
  }

  @override
  bool shouldRepaint(covariant _RedlinePainter old) => old.phase != phase;
}
