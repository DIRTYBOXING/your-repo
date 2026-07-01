import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/services/settings_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// RECOVERY ACCESS HUB v2.0 — Fighter Support Network
///
/// Compact, animated, sliding-panel design. No more giant boring cards.
/// Every section is tight, tappable, alive with micro-animations.
///
/// Sections:
///  1. Hero banner — pulsing gradient, stats strip
///  2. Quick Actions — horizontal sliding chips
///  3. Pathway Cards — compact icon+text, expandable on tap
///  4. Emergency strip — always visible, one-tap
///  5. Disclaimer — minimal footer
/// ═══════════════════════════════════════════════════════════════════════════

class RecoveryHubScreen extends StatefulWidget {
  const RecoveryHubScreen({super.key});

  @override
  State<RecoveryHubScreen> createState() => _RecoveryHubScreenState();
}

class _RecoveryHubScreenState extends State<RecoveryHubScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int? _expandedIdx;

  static const _pathways = [
    _Pathway(
      'Medical Cannabis Clinics',
      'Regulated access pathways only — education first.',
      Icons.local_pharmacy,
      Color(0xFF00FF9D),
      [
        'Licensed clinics and doctors only',
        'Education-first, no strain or dosage advice',
        'Always consult a medical professional',
      ],
      isMature: true,
    ),
    _Pathway(
      'Alternative Therapies',
      'Adjunct support for recovery and wellbeing.',
      Icons.spa,
      Color(0xFF00FFF0),
      [
        'Breathwork & nervous system regulation',
        'Physio, myotherapy, massage, mobility',
        'Sleep clinics, nutrition, recovery labs',
      ],
    ),
    _Pathway(
      'Traditional Medical',
      'Bulk-billing and community health access.',
      Icons.local_hospital,
      Color(0xFFFF0080),
      [
        'Bulk-billing GPs and sports physicians',
        'Community mental health services',
        'University clinics & NGO programs',
      ],
    ),
    _Pathway(
      'Youth & Community',
      'Programs and care for emerging athletes.',
      Icons.groups,
      Color(0xFF00D9FF),
      [
        'Youth mentorship & safe training spaces',
        'Community sport grants & transport',
        'School-based counselling & outreach',
      ],
    ),
    _Pathway(
      '24/7 Support Network',
      'Always available — your corner, your team.',
      Icons.support_agent,
      Color(0xFFB100FF),
      [
        '24/7 coach & team communication',
        'Peer-led recovery check-ins',
        'Escalation to sports medicine pros',
      ],
    ),
    _Pathway(
      'Free Counselling',
      'No-cost access for athletes and families.',
      Icons.psychology,
      Color(0xFFFF9800),
      [
        'Public health & NGO counselling',
        'Telehealth for remote regions',
        'Recovery-focused group sessions',
      ],
    ),
  ];

  static const _quickActions = [
    _QAction('Find Counsellor', Icons.psychology, Color(0xFF00FFF0)),
    _QAction('Request Mentor', Icons.school, Color(0xFF00FF9D)),
    _QAction('Safety Check', Icons.health_and_safety, Color(0xFFFF2D55)),
    _QAction('Youth Support', Icons.child_care, Color(0xFFFF9800)),
    _QAction('Crisis Line', Icons.phone_in_talk, Color(0xFFFF0080)),
    _QAction('Peer Circle', Icons.group_work, Color(0xFFB100FF)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Ambient bg
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _AmbientPainter(phase: _ctrl.value),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildHeroBanner(),
                        const SizedBox(height: 18),
                        _buildQuickActions(),
                        const SizedBox(height: 20),
                        _sectionLabel('SUPPORT PATHWAYS', AppColors.neonCyan),
                        const SizedBox(height: 4),
                        Text(
                          'Tap any pathway to expand details',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...(() {
                          final settings = context.watch<SettingsService>();
                          final filtered = _pathways
                              .where((p) => !p.isMature || settings.isAdultMode)
                              .toList();
                          return filtered.asMap().entries.map(
                            (e) => _buildPathwayCard(e.key, e.value),
                          );
                        })(),
                        const SizedBox(height: 18),
                        _buildEmergencyStrip(),
                        const SizedBox(height: 16),
                        _buildDisclaimer(),
                        const SizedBox(height: 30),
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

  // ── HEADER ──
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.neonGreen, AppColors.neonCyan],
                  ).createShader(b),
                  child: const Text(
                    'RECOVERY ACCESS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                Text(
                  'Fighter support & wellbeing hub',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    AppColors.neonGreen.withValues(
                      alpha: 0.15 + _ctrl.value * 0.1,
                    ),
                    AppColors.neonCyan.withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: const Icon(
                Icons.healing,
                color: AppColors.neonGreen,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HERO BANNER ──
  Widget _buildHeroBanner() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.neonGreen.withValues(alpha: 0.06 + _ctrl.value * 0.02),
              AppColors.neonCyan.withValues(alpha: 0.03),
              AppColors.neonPurple.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.neonGreen.withValues(alpha: 0.2),
                        AppColors.neonGreen.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: AppColors.neonGreen.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FIGHTER WELLBEING',
                        style: TextStyle(
                          color: AppColors.neonGreen.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verified support pathways grounded in safety & consent',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                          height: 1.3,
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
                _statChip('6', 'Pathways', AppColors.neonCyan),
                const SizedBox(width: 8),
                _statChip('24/7', 'Support', AppColors.neonGreen),
                const SizedBox(width: 8),
                _statChip('FREE', 'Access', AppColors.neonOrange),
                const SizedBox(width: 8),
                _statChip('ALL', 'Ages', AppColors.neonMagenta),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String val, String label, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: c.withValues(alpha: 0.06),
          border: Border.all(color: c.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: c,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: c.withValues(alpha: 0.4),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── QUICK ACTIONS — Horizontal sliding chips ──
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('QUICK ACTIONS', AppColors.neonMagenta),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _quickActions.length,
            itemBuilder: (_, i) {
              final a = _quickActions[i];
              return GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${a.label} — contact support@datafightcentral.com for assistance'),
                      backgroundColor: a.color.withValues(alpha: 0.8),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: a.color.withValues(alpha: 0.05),
                    border: Border.all(color: a.color.withValues(alpha: 0.12)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        a.icon,
                        color: a.color.withValues(alpha: 0.6),
                        size: 22,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: a.color.withValues(alpha: 0.6),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── PATHWAY CARD — Compact, expandable on tap ──
  Widget _buildPathwayCard(int idx, _Pathway p) {
    final isExpanded = _expandedIdx == idx;

    return GestureDetector(
      onTap: () => setState(() => _expandedIdx = isExpanded ? null : idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(isExpanded ? 16 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isExpanded
              ? p.color.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: isExpanded
                ? p.color.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row — always visible
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: p.color.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    p.icon,
                    color: p.color.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: TextStyle(
                          color: isExpanded
                              ? p.color
                              : Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isExpanded)
                        Text(
                          p.subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: isExpanded
                        ? p.color.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.15),
                    size: 22,
                  ),
                ),
              ],
            ),

            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...p.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.color.withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.check,
                                color: p.color.withValues(alpha: 0.6),
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: p.color.withValues(alpha: 0.08),
                        border: Border.all(
                          color: p.color.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.open_in_new,
                            color: p.color.withValues(alpha: 0.5),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LEARN MORE',
                            style: TextStyle(
                              color: p.color.withValues(alpha: 0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }

  // ── EMERGENCY STRIP ──
  Widget _buildEmergencyStrip() {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              AppColors.neonRed.withValues(
                alpha: 0.08 + math.sin(_ctrl.value * math.pi * 2) * 0.03,
              ),
              AppColors.neonMagenta.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: AppColors.neonRed.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonRed.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.emergency,
                color: AppColors.neonRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EMERGENCY? CALL NOW',
                    style: TextStyle(
                      color: AppColors.neonRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Lifeline 13 11 14 · Emergency 000',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.neonRed.withValues(alpha: 0.15),
              ),
              child: const Text(
                'CALL',
                style: TextStyle(
                  color: AppColors.neonRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DISCLAIMER ──
  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white.withValues(alpha: 0.15),
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'DFC provides education and access pathways only. '
              'We do not provide medical advice, prescriptions, or treatment. '
              'Always consult a licensed healthcare professional.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color c) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: c.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════
class _Pathway {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final List<String> bullets;
  final bool isMature;
  const _Pathway(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.bullets, {
    this.isMature = false,
  });
}

class _QAction {
  final String label;
  final IconData icon;
  final Color color;
  const _QAction(this.label, this.icon, this.color);
}

// ═══════════════════════════════════════════════════════════════════════════
// AMBIENT BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _AmbientPainter extends CustomPainter {
  final double phase;
  _AmbientPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    final colors = [
      AppColors.neonGreen,
      AppColors.neonCyan,
      AppColors.neonPurple,
    ];
    for (int i = 0; i < 3; i++) {
      final x =
          size.width * (0.2 + i * 0.3) + math.sin(phase * math.pi * 2 + i) * 40;
      final y =
          size.height * (0.15 + i * 0.25) +
          math.cos(phase * math.pi * 2 + i * 0.7) * 30;
      paint.color = colors[i].withValues(alpha: 0.01);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 250, height: 160),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) => old.phase != phase;
}
