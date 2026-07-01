import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER CARD v2.0 — The Definitive Combat Identity
///
/// Every warrior has a story written in sweat, sacrifice, and bloodlines.
/// This is theirs — AI-verified, fight-tested, and built to outlast the cage.
///
/// Sections:
///  1. IDENTITY — Name, alias, division, record, physical measurables
///  2. COMBAT DNA — Six-axis radar: striking, grappling, cardio, chin, IQ, power
///  3. CAREER ARC — Win/loss timeline with method breakdowns
///  4. AI SCOUTING REPORT — CombatIntelligenceEngine analysis
///  5. DFC SAFETY SCORE — Public compassion layer
///  6. LEGACY STATS — Finishes, fight time, titles, fan rating
///  7. SHARE — Exportable verified identity
/// ═══════════════════════════════════════════════════════════════════════════

class FighterCardScreen extends StatefulWidget {
  const FighterCardScreen({super.key});

  @override
  State<FighterCardScreen> createState() => _FighterCardScreenState();
}

class _FighterCardScreenState extends State<FighterCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Demo fighter data
  final _name = 'MARCUS SANTOS';
  final _alias = '"The Storm"';
  final _record = '18 – 4 – 0';
  final _division = 'WELTERWEIGHT';
  final _age = 28;
  final _reach = '74"';
  final _stance = 'Orthodox';

  // Combat DNA (0-1)
  final _striking = 0.88;
  final _grappling = 0.65;
  final _cardio = 0.78;
  final _chin = 0.82;
  final _fightIQ = 0.75;
  final _power = 0.92;

  // FightLink: video URL (editable for demo, should be user-owned in prod)
  final TextEditingController _videoUrlCtrl = TextEditingController();
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    // Optionally prefill for demo
    //_videoUrlCtrl.text = 'https://www.youtube.com/watch?v=xxxxxxx';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _videoUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CardBgPainter(phase: _ctrl.value)),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildIdentity()),
                    SliverToBoxAdapter(child: _buildCombatDNA()),
                    SliverToBoxAdapter(child: _buildCareerArc()),
                    SliverToBoxAdapter(child: _buildScoutingReport()),
                    SliverToBoxAdapter(child: _buildSafetyScore()),
                    SliverToBoxAdapter(child: _buildLegacyStats()),
                    SliverToBoxAdapter(child: _buildFightLink()),
                    SliverToBoxAdapter(child: _buildShareCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHTLINK — Add and show hosted fight video link
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFightLink() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: AppColors.neonCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'FIGHTLINK',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _videoUrlCtrl,
            decoration: InputDecoration(
              hintText: 'Paste YouTube or video link',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: AppColors.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check, color: AppColors.neonCyan),
                onPressed: () {
                  setState(() {
                    _videoUrl = _videoUrlCtrl.text.trim().isNotEmpty
                        ? _videoUrlCtrl.text.trim()
                        : null;
                  });
                },
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) {
              setState(() {
                _videoUrl = _videoUrlCtrl.text.trim().isNotEmpty
                    ? _videoUrlCtrl.text.trim()
                    : null;
              });
            },
          ),
          if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final url = Uri.parse(_videoUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: AppColors.neonCyan,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _videoUrl!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
                Icons.arrow_back,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIGHTER CARD',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI-verified combat identity',
                  style: TextStyle(
                    color: AppColors.neonCyan.withValues(alpha: 0.4),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonCyan.withValues(alpha: 0.04),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.share,
              color: AppColors.neonCyan.withValues(alpha: 0.4),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IDENTITY — The warrior's signature
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIdentity() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.neonRed.withValues(alpha: 0.06),
                  AppColors.neonCyan.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonRed.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppColors.neonRed.withValues(alpha: 0.35),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonRed.withValues(alpha: 0.2),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    color: AppColors.neonRed.withValues(alpha: 0.5),
                    size: 46,
                  ),
                ),
                const SizedBox(height: 14),
                // Name
                Text(
                  _name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                // Alias
                Text(
                  _alias,
                  style: TextStyle(
                    color: AppColors.neonRed.withValues(alpha: 0.55),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                // Record
                Text(
                  _record,
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _division,
                  style: TextStyle(
                    color: AppColors.neonCyan.withValues(alpha: 0.45),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statChip('AGE', '$_age', AppColors.neonOrange),
                    const SizedBox(width: 24),
                    _statChip('REACH', _reach, AppColors.neonGreen),
                    const SizedBox(width: 24),
                    _statChip('STANCE', _stance, AppColors.neonMagenta),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMBAT DNA — Six-axis fighter genome
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCombatDNA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('COMBAT DNA', AppColors.neonCyan),
          const SizedBox(height: 4),
          Text(
            'Six-axis analysis of fighting capability',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.neonCyan.withValues(alpha: 0.02),
              border: Border.all(
                color: AppColors.neonCyan.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 280,
                  child: CustomPaint(
                    size: const Size(double.infinity, 280),
                    painter: _CombatDNARadarPainter(
                      phase: _ctrl.value,
                      values: [
                        _striking,
                        _grappling,
                        _cardio,
                        _chin,
                        _fightIQ,
                        _power,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _dnaLegend('Striking', _striking, AppColors.neonRed),
                    _dnaLegend('Grappling', _grappling, AppColors.neonGreen),
                    _dnaLegend('Cardio', _cardio, AppColors.neonCyan),
                    _dnaLegend('Chin', _chin, AppColors.neonOrange),
                    _dnaLegend('Fight IQ', _fightIQ, AppColors.neonMagenta),
                    _dnaLegend('Power', _power, AppColors.neonPurple),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dnaLegend(String name, double val, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          name,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(val * 100).toInt()}',
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAREER ARC — The path to greatness
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCareerArc() {
    final fights = [
      const _Fight('W', 'TKO R2', 'vs Magny', AppColors.neonGreen),
      const _Fight('W', 'KO R1', 'vs Prates', AppColors.neonGreen),
      const _Fight('L', 'Decision', 'vs Whittaker', AppColors.neonRed),
      const _Fight('W', 'SUB R3', 'vs Brady', AppColors.neonGreen),
      const _Fight('W', 'KO R1', 'vs Rodriguez', AppColors.neonGreen),
      const _Fight('W', 'TKO R2', 'vs Luque', AppColors.neonGreen),
      const _Fight('L', 'KO R3', 'vs Rakhmonov', AppColors.neonRed),
      const _Fight('W', 'Decision', 'vs Hooker', AppColors.neonGreen),
      const _Fight('W', 'KO R1', 'vs Buckley', AppColors.neonGreen),
      const _Fight('W', 'TKO R2', 'vs Neal', AppColors.neonGreen),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('CAREER ARC', AppColors.neonOrange),
          const SizedBox(height: 4),
          Text(
            '22 professional bouts — 18 victories',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                // Fight bars
                SizedBox(
                  height: 70,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: fights.asMap().entries.map((e) {
                      final f = e.value;
                      final isWin = f.result == 'W';
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          height: isWin ? 45 + (e.key % 3) * 8.0 : 22,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                            color: f.color.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Recent fights list
                ...fights.reversed
                    .take(5)
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 20,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: f.color.withValues(alpha: 0.15),
                              ),
                              child: Center(
                                child: Text(
                                  f.result,
                                  style: TextStyle(
                                    color: f.color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              f.opponent,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              f.method,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 13,
                              ),
                            ),
                          ],
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
  // AI SCOUTING REPORT — CombatIntelligenceEngine breakdown
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildScoutingReport() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('AI SCOUTING REPORT', AppColors.neonMagenta),
          const SizedBox(height: 4),
          Text(
            'Generated by CombatIntelligenceEngine',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.neonMagenta.withValues(alpha: 0.02),
              border: Border.all(
                color: AppColors.neonMagenta.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: AppColors.neonMagenta.withValues(alpha: 0.5),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'COMBAT INTELLIGENCE ENGINE',
                      style: TextStyle(
                        color: AppColors.neonMagenta.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _scoutItem('STRENGTHS', [
                  'Elite knockout power — 78% finish rate across 22 bouts',
                  'Detonates in the first round — most dangerous 5 minutes in the division',
                  'Iron chin — only stopped once in his entire career',
                  'Takedown defense improved +18% this camp under new coaching staff',
                ], AppColors.neonGreen),
                const SizedBox(height: 14),
                _scoutItem('VULNERABILITIES', [
                  'Cardio fades hard after round two — output drops 40%',
                  'Southpaw body kicks consistently land clean',
                  'Overcommits on power shots when fatigue sets in',
                  'Ground game exposed against elite grappling credentials',
                ], AppColors.neonRed),
                const SizedBox(height: 14),
                _scoutItem('TACTICAL BLUEPRINT', [
                  'Finish early — every round past the second carries escalating risk',
                  'Deploy leg kicks to slow lateral movement before loading power',
                  'Maintain distance from the clinch where grappling gap is exposed',
                ], AppColors.neonCyan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoutItem(String title, List<String> points, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        ...points.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAFETY SCORE — DFC compassion layer
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSafetyScore() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonCyan.withValues(alpha: 0.04),
              AppColors.neonGreen.withValues(alpha: 0.02),
            ],
          ),
          border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield,
                  color: AppColors.neonCyan.withValues(alpha: 0.5),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DFC SAFETY SCORE',
                    style: TextStyle(
                      color: AppColors.neonCyan.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonGreen.withValues(alpha: 0.08),
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _safetyRow('Medical clearance', 'CURRENT', AppColors.neonGreen),
            _safetyRow(
              'Concussion protocol',
              'CLEAR — 47 days since last impact',
              AppColors.neonGreen,
            ),
            _safetyRow(
              'Weight cut safety',
              'OPTIMAL — no extreme cuts',
              AppColors.neonGreen,
            ),
            _safetyRow('Mental health check', 'PASSED', AppColors.neonGreen),
            _safetyRow(
              'Career absorption',
              '312 significant strikes absorbed',
              AppColors.neonOrange,
            ),
            const SizedBox(height: 12),
            Text(
              'This fighter meets all DFC safety standards. Medical clearance '
              'verified within 30 days. No red flags detected by monitoring systems.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _safetyRow(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              status,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color.withValues(alpha: 0.65),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY STATS — Numbers that outlive the cage
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLegacyStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('LEGACY', AppColors.neonPurple),
          const SizedBox(height: 4),
          Text(
            'The numbers that define a career',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _legacyStat('KO / TKO', '14', AppColors.neonRed)),
              const SizedBox(width: 8),
              Expanded(child: _legacyStat('SUB', '2', AppColors.neonGreen)),
              const SizedBox(width: 8),
              Expanded(child: _legacyStat('DEC', '2', AppColors.neonCyan)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _legacyStat(
                  'FIGHT TIME',
                  '2:47:12',
                  AppColors.neonOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _legacyStat('TITLE SHOTS', '3', AppColors.neonMagenta),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _legacyStat('FAN RATING', '9.2', AppColors.neonPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legacyStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.04),
        border: Border.all(color: color.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARE CARD — Export verified identity
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildShareCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: GestureDetector(
        onTap: () {
          SharePlus.instance.share(
            ShareParams(
              text: '$_name $_alias\n'
                  'Record: $_record  |  $_division\n\n'
                  'View their full Fighter Card on Data Fight Central\n'
                  'https://datafightcentral.web.app',
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.neonCyan.withValues(alpha: 0.04),
                AppColors.neonPurple.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.share,
                color: AppColors.neonCyan.withValues(alpha: 0.4),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SHARE THIS FIGHTER CARD',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI-verified stats · Safety certified · DFC authentic',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.neonCyan.withValues(alpha: 0.3),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.75),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════
class _Fight {
  final String result, method, opponent;
  final Color color;
  const _Fight(this.result, this.method, this.opponent, this.color);
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD BG — Subtle holographic shimmer
// ═════════════════════════════════════════════════════════════════════════════
class _CardBgPainter extends CustomPainter {
  final double phase;

  _CardBgPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);

    // Holographic shimmer bands
    for (int i = 0; i < 3; i++) {
      final y =
          size.height * (0.2 + i * 0.3) +
          math.sin(phase * math.pi * 2 + i) * 30;
      final colors = [
        AppColors.neonRed,
        AppColors.neonCyan,
        AppColors.neonPurple,
      ];
      paint.color = colors[i].withValues(alpha: 0.015);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, y),
          width: size.width * 0.9,
          height: 70,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CardBgPainter old) => old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// COMBAT DNA RADAR — Six-axis radar chart (enlarged)
// ═════════════════════════════════════════════════════════════════════════════
class _CombatDNARadarPainter extends CustomPainter {
  final double phase;
  final List<double> values;

  _CombatDNARadarPainter({required this.phase, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = math.min(cx, cy) - 36;
    final labels = [
      'STRIKING',
      'GRAPPLING',
      'CARDIO',
      'CHIN',
      'FIGHT IQ',
      'POWER',
    ];
    final colors = [
      AppColors.neonRed,
      AppColors.neonGreen,
      AppColors.neonCyan,
      AppColors.neonOrange,
      AppColors.neonMagenta,
      AppColors.neonPurple,
    ];

    // Grid rings
    for (int ring = 1; ring <= 4; ring++) {
      final r = maxR * ring / 4;
      final path = Path();
      for (int i = 0; i < 6; i++) {
        final angle = math.pi / 3 * i - math.pi / 2;
        final x = cx + r * math.cos(angle);
        final y = cy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Spokes
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + maxR * math.cos(angle), cy + maxR * math.sin(angle)),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.04)
          ..strokeWidth = 0.5,
      );
    }

    // Value polygon
    final pulse = math.sin(phase * math.pi * 2) * 0.02;
    final valuePath = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final v = values[i] + pulse;
      final x = cx + maxR * v * math.cos(angle);
      final y = cy + maxR * v * math.sin(angle);
      if (i == 0) {
        valuePath.moveTo(x, y);
      } else {
        valuePath.lineTo(x, y);
      }
    }
    valuePath.close();

    canvas.drawPath(
      valuePath,
      Paint()..color = AppColors.neonCyan.withValues(alpha: 0.08),
    );
    canvas.drawPath(
      valuePath,
      Paint()
        ..color = AppColors.neonCyan.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Vertices + labels
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final v = values[i] + pulse;
      final vx = cx + maxR * v * math.cos(angle);
      final vy = cy + maxR * v * math.sin(angle);

      canvas.drawCircle(
        Offset(vx, vy),
        5,
        Paint()..color = colors[i].withValues(alpha: 0.7),
      );
      canvas.drawCircle(
        Offset(vx, vy),
        10,
        Paint()
          ..color = colors[i].withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      // Label
      final lx = cx + (maxR + 24) * math.cos(angle);
      final ly = cy + (maxR + 24) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i].withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CombatDNARadarPainter old) =>
      old.phase != phase;
}
