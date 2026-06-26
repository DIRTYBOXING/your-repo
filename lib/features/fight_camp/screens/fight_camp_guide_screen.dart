import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FightCampGuideScreen extends StatelessWidget {
  const FightCampGuideScreen({super.key});

  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFFD500F9);
  static const _blue = Color(0xFF2979FF);
  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF080F1E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.8,
                  colors: [
                    Color(0xFF0A0010),
                    Color(0xFF030810),
                    Color(0xFF001018),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: CustomPaint(
                  painter: _GridPainter(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _appBar(context)),
                SliverToBoxAdapter(child: _headerCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _sectionCard(
                    emoji: '🔥',
                    title: 'Training Intensification & Specificity',
                    color: _orangeForMuayThai,
                    bullets: const [
                      'Build a camp plan around the date: intensity rises, volume peaks, then tapers.',
                      'Game-plan for range, stance matchups, kick battles, and clinch control.',
                      'Two-a-days are common: AM conditioning/skills, PM pads/clinch/sparring.',
                      'Simulate rounds and rules: round length, pace, and rest intervals.',
                      'Muay Thai emphasis: clinch rounds, knees/elbows entries, balance/off-balancing.',
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _sectionCard(
                    emoji: '🥗',
                    title: 'Physical & Nutritional Readiness',
                    color: _green,
                    bullets: const [
                      'Start weight management early: steady fat loss > last-minute panic cuts.',
                      'Aerobic base first, then layer in harder intervals and sport-specific conditioning.',
                      'Protect recovery: sleep targets, mobility, and deload days are non-negotiable.',
                      'Track training load and soreness—small adjustments beat forced grind.',
                      'Hydration and electrolytes matter more as volume climbs and weight drops.',
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _sectionCard(
                    emoji: '🧾',
                    title: 'Logistics, Rules & Gear',
                    color: _blue,
                    bullets: const [
                      'Confirm sanctioning requirements early: medicals, bloodwork, paperwork, deadlines.',
                      'Know the rule set: elbows allowed? clinch limits? scoring emphasis? protective gear?',
                      'Build a gear checklist: gloves (bag/pads/spar), wraps, mouthguard (spare), cup, shin guards for training, ankle supports if used.',
                      'Corner team locked in: head coach + second + cut/med support if required.',
                      'Travel and weigh-in plan: timing, meals, rehydration, and warm-up logistics.',
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: _sectionCard(
                    emoji: '🧠',
                    title: 'Mental & Tactical Prep',
                    color: _purple,
                    bullets: const [
                      'Film study: patterns, tells, pacing, and clinch habits (breaks, turns, dumps).',
                      'Rehearse the full night: walkout, ring nerves, and round-by-round composure.',
                      'Prepare for the adrenaline dump: breathe early, win the first exchange calmly.',
                      'Muay Thai scoring mindset: clean kicks, knees, control, balance, and visible effect.',
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _templateCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(child: _safetyCard()),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(child: _footerActions(context)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _orangeForMuayThai = Color(0xFFFF6D00);

  Widget _appBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white54,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FIGHT CAMP GUIDE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Muay Thai • experienced amateur • checklist',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _cyan.withValues(alpha: 0.35)),
          ),
          child: const Text(
            '6–8 WEEKS',
            style: TextStyle(
              color: _cyan,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _headerCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Fight camp is a lifestyle shift aimed at peaking for a date—not just “training harder.”',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Use this as a fast checklist. Your coach and medical team override any generic advice.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sectionCard({
    required String emoji,
    required String title,
    required Color color,
    required List<String> bullets,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final b in bullets) _bullet(b, color),
          ],
        ),
      ),
    );
  }

  Widget _bullet(String text, Color col) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: col.withValues(alpha: 0.22),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _templateCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏱️ 6–8 Week Template (Experienced Amateur)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          _miniPhase('Weeks 8–6', 'Base + skill volume', _cyan, const [
            'Aerobic base, lots of technical reps, lower sparring intensity.',
            'Clinch fundamentals: posture, frames, pummeling, balance.',
          ]),
          const SizedBox(height: 10),
          _miniPhase(
            'Weeks 5–3',
            'Intensity + specificity',
            _orangeForMuayThai,
            const [
              'Harder pads, more live clinch, controlled sparring volume.',
              'Add opponent-style looks and scoring scenarios.',
            ],
          ),
          const SizedBox(height: 10),
          _miniPhase('Weeks 2–1', 'Sharpen + taper', _purple, const [
            'Shorter, faster sessions; keep timing sharp, reduce damage risk.',
            'Prioritise sleep, soft tissue work, and confidence reps.',
          ]),
          const SizedBox(height: 10),
          _miniPhase('Last 72h', 'Weigh-in & rehydration plan', _amber, const [
            'No last-minute surprises: confirm the exact weigh-in schedule.',
            'Cut safely with coaching/medical guidance; rehydrate deliberately.',
          ]),
        ],
      ),
    ),
  );

  Widget _miniPhase(
    String when,
    String title,
    Color col,
    List<String> bullets,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [col.withValues(alpha: 0.14), _card]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                when,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final b in bullets) _bullet(b, col),
        ],
      ),
    );
  }

  Widget _safetyCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🚨 Red Flags (Don’t Ignore)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _bullet(
            'Persistent joint pain, concussive symptoms, or sharp new injuries.',
            _red,
          ),
          _bullet(
            'Rapid weight loss that spikes fatigue, cramps, or sleep disruption.',
            _red,
          ),
          _bullet(
            'Mood crashes, chronic soreness, or performance drop-offs for 7+ days.',
            _red,
          ),
          _bullet('Too much hard sparring too close to fight week.', _red),
        ],
      ),
    ),
  );

  Widget _footerActions(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/fight-camp/phase'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _cyan,
              side: BorderSide(color: _cyan.withValues(alpha: 0.45)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.timeline, size: 18),
            label: const Text(
              'Open Camp Phases',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/atlas-chat'),
            style: FilledButton.styleFrom(
              backgroundColor: _green.withValues(alpha: 0.9),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.psychology, size: 18),
            label: const Text(
              'Ask Atlas',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );
}

class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;

    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }

    // A few faint “stars”
    final star = Paint()..color = Colors.white.withValues(alpha: 0.06);
    for (int i = 0; i < 22; i++) {
      final dx = (math.Random(i).nextDouble() * size.width);
      final dy = (math.Random(i * 7 + 3).nextDouble() * size.height);
      canvas.drawCircle(Offset(dx, dy), 1.2, star);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
