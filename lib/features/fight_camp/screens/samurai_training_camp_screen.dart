import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SamuraiTrainingCampScreen extends StatefulWidget {
  const SamuraiTrainingCampScreen({super.key});

  @override
  State<SamuraiTrainingCampScreen> createState() =>
      _SamuraiTrainingCampScreenState();
}

class _SamuraiTrainingCampScreenState extends State<SamuraiTrainingCampScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;

  int _activeDayIdx = 3;
  String _priorityMetric = 'Sleep';
  static const List<String> _metrics = [
    'Sleep',
    'Mood',
    'Diet',
    'Training Load',
  ];

  // 7-day tracking — realistic fight camp progression (Mon→Sun)
  final List<double> _sleepHours = const [6.2, 7.1, 7.8, 6.9, 8.0, 7.4, 7.7];
  final List<double> _moodScore = const [6.5, 7.0, 7.6, 6.9, 7.8, 7.2, 7.5];
  final List<double> _dietScore = const [6.0, 6.8, 7.4, 7.0, 7.6, 7.1, 7.3];
  final List<double> _trainingLoad = const [
    0.55,
    0.64,
    0.72,
    0.78,
    0.74,
    0.66,
    0.60,
  ];

  // Camp metadata — dynamically computed from April 24 Ultimate Legends event
  int get _daysOut {
    final fightDate = DateTime(2026, 4, 24);
    final diff = fightDate.difference(DateTime.now()).inDays;
    return diff.clamp(0, 999);
  }
  int get _week {
    // 8-week camp started March 1
    final campStart = DateTime(2026, 3);
    final diff = DateTime.now().difference(campStart).inDays;
    return (diff ~/ 7 + 1).clamp(1, 12);
  }

  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _purple = Color(0xFFD500F9);
  static const _orange = Color(0xFFFF6D00);
  static const _blue = Color(0xFF2979FF);
  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF080F1E);
  static const _card2 = Color(0xFF071426);

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, _) {
          final bgShift = math.sin(_bgCtrl.value * 2 * math.pi);
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(bgShift * 0.45, -0.25),
                      radius: 1.75,
                      colors: const [
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
                    opacity: 0.22,
                    child: CustomPaint(
                      painter: _CampMapPainter(
                        grid: Colors.white.withValues(alpha: 0.06),
                        glow: _cyan.withValues(
                          alpha: 0.06 + 0.04 * (0.5 + 0.5 * bgShift),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _appBar()),
                    // Priority Metric Dropdown
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Row(
                          children: [
                            const Text(
                              'Priority Metric:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _priorityMetric,
                                dropdownColor: _card,
                                iconEnabledColor: _cyan,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withValues(
                                    alpha: 0.04,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: _cyan.withValues(alpha: 0.25),
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                items: _metrics
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(m),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _priorityMetric = val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: _hero()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _focusCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _teamRow()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _daySelector()),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    SliverToBoxAdapter(child: _graphs()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _routineCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _boundariesCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(child: _packingCard()),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverToBoxAdapter(child: _actions()),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _appBar() => Padding(
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
              'SAMURAI TRAINING CAMP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Coach • mentor • bots • family • graphs',
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
          child: Text(
            'D-$_daysOut',
            style: const TextStyle(
              color: _cyan,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_card2, _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _miniStat(
              'WEEK',
              '$_week/8',
              _orange,
              'Intensity + specificity',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _miniStat(
              'TODAY',
              _dayLabel(_activeDayIdx).toUpperCase(),
              _blue,
              'Execute. Recover. Repeat.',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _focusCard() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_card2, _card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  boxShadow: [
                    BoxShadow(
                      color: _green.withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'CALM + CONFIDENCE (ANTI-ANXIETY PROTOCOL)',
                  style: TextStyle(
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
          Row(
            children: [
              Expanded(
                child: _microRule(
                  icon: Icons.air,
                  title: 'Breathe 60s',
                  body: '4 in • 6 out. Drop shoulders.',
                  col: _cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _microRule(
                  icon: Icons.center_focus_strong,
                  title: '3 Anchors',
                  body: 'Feet • hands • eyes on task.',
                  col: _purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _microRule(
            icon: Icons.shield,
            title: 'Camp Rule',
            body:
                'No chaos. No substances. No toxic contact. Protect your sleep.',
            col: _amber,
          ),
          const SizedBox(height: 8),
          Text(
            'If you feel unsafe or in danger, contact local emergency services or a trusted person immediately.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _microRule({
    required IconData icon,
    required String title,
    required String body,
    required Color col,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  col.withValues(alpha: 0.95),
                  col.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: col.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: col.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.black),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color col, String hint) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [col.withValues(alpha: 0.14), _card],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                height: 1.2,
              ),
            ),
          ],
        ),
      );

  Widget _teamRow() => Padding(
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
            'YOUR CAMP CIRCLE (ONE PAGE)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _roleTile(
                emoji: '🥊',
                title: 'Head Coach',
                subtitle: 'Game plan + rounds',
                col: _cyan,
                seed:
                    'Act as my Head Coach. Build today\'s Muay Thai plan for camp Week $_week with a main technical focus, sparring intensity, and one key adjustment.',
              ),
              _roleTile(
                emoji: '🏋️',
                title: 'S&C Coach',
                subtitle: 'Power + engine',
                col: _blue,
                seed:
                    'Act as my Strength & Conditioning coach. Create a 45–60 min session for camp Week $_week (fight-specific power + conditioning) and include warm-up and cooldown.',
              ),
              _roleTile(
                emoji: '🥗',
                title: 'Nutrition Bot',
                subtitle: 'Diet + cut plan',
                col: _green,
                seed:
                    'Act as my nutrition coach for fight camp. Based on training load, give me today\'s meal plan and hydration plan. Keep it realistic and camp-friendly.',
              ),
              _roleTile(
                emoji: '😴',
                title: 'Recovery Bot',
                subtitle: 'Sleep + soreness',
                col: _purple,
                seed:
                    'Act as my recovery coach. Review my sleep and mood trend and tell me what to change tonight (sleep routine, mobility, recovery work).',
              ),
              _roleTile(
                emoji: '🧠',
                title: 'Mentor',
                subtitle: 'Mindset + focus',
                col: _amber,
                seed:
                    'Act as my mentor. I\'m in fight camp and anxiety is high. I\'m choosing stability over chaos (no substances, no toxic contact). Give me a short mindset briefing for today + one rule to follow + one sentence to repeat before training.',
              ),
              _roleTile(
                emoji: '🤝',
                title: 'Friend',
                subtitle: 'Support, no pressure',
                col: _orange,
                seed:
                    'Act as my best friend. Send a short supportive message that doesn\'t require a reply. Keep me confident and calm in camp (no pressure).',
              ),
              _roleTile(
                emoji: '💍',
                title: 'Wife',
                subtitle: 'Boundaries + love',
                col: Colors.white70,
                seed:
                    'Help me write a respectful camp message to my wife: boundaries, what\'s changing, how she can support me, and how I\'ll stay present even while focused.',
              ),
              _roleTile(
                emoji: '👨‍👩‍👧‍👦',
                title: 'Kids',
                subtitle: 'Simple + honest',
                col: Colors.white54,
                seed:
                    'Help me explain fight camp to my kids in a simple, positive way, and give me 3 small ways to stay connected each day.',
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _roleTile({
    required String emoji,
    required String title,
    required String subtitle,
    required Color col,
    required String seed,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 10) / 2,
      child: InkWell(
        onTap: () =>
            context.push('/atlas-chat?seed=${Uri.encodeComponent(seed)}'),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [col.withValues(alpha: 0.12), _card],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: col.withValues(alpha: 0.26)),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 10,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: col.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _daySelector() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: List.generate(
        7,
        (i) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeDayIdx = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: i == _activeDayIdx
                    ? _cyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: i == _activeDayIdx
                      ? _cyan.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: Text(
                  _dayLabel(i),
                  style: TextStyle(
                    color: i == _activeDayIdx
                        ? _cyan
                        : Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                    fontWeight: i == _activeDayIdx
                        ? FontWeight.w900
                        : FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _graphs() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        _graphCard(
          emoji: '😴',
          title: 'Sleep',
          value: '${_sleepHours[_activeDayIdx].toStringAsFixed(1)} h',
          data: _sleepHours,
          col: _cyan,
          maxVal: 10.0,
          hint: 'Target 7.5–9h in camp. Protect bedtime.',
          highlight: _priorityMetric == 'Sleep',
        ),
        const SizedBox(height: 10),
        _graphCard(
          emoji: '🙂',
          title: 'Mood',
          value: '${_moodScore[_activeDayIdx].toStringAsFixed(1)}/10',
          data: _moodScore,
          col: _purple,
          maxVal: 10.0,
          hint:
              'Mood tracks readiness. Low mood = reduce damage and add recovery.',
          highlight: _priorityMetric == 'Mood',
        ),
        const SizedBox(height: 10),
        _graphCard(
          emoji: '🥗',
          title: 'Diet',
          value: '${_dietScore[_activeDayIdx].toStringAsFixed(1)}/10',
          data: _dietScore,
          col: _green,
          maxVal: 10.0,
          hint: 'High protein, consistent carbs around sessions, electrolytes.',
          highlight: _priorityMetric == 'Diet',
        ),
        const SizedBox(height: 10),
        _graphCard(
          emoji: '🔥',
          title: 'Training Load',
          value: '${(_trainingLoad[_activeDayIdx] * 100).toInt()}%',
          data: _trainingLoad,
          col: _orange,
          maxVal: 1.0,
          hint: 'Push hard, but avoid piling damage near fight week.',
          isPercent: true,
          highlight: _priorityMetric == 'Training Load',
        ),
      ],
    ),
  );

  Widget _graphCard({
    required String emoji,
    required String title,
    required String value,
    required List<double> data,
    required Color col,
    required double maxVal,
    required String hint,
    bool isPercent = false,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? _card.withValues(alpha: 0.97) : _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? _cyan.withValues(alpha: 0.45) : Colors.white10,
          width: highlight ? 2 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : [],
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
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: col,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final v = data[i];
                final t = (v / maxVal).clamp(0.0, 1.0);
                final active = i == _activeDayIdx;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: t),
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, _) => Container(
                        height: 64 * val,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              col.withValues(alpha: active ? 0.45 : 0.25),
                              col.withValues(alpha: active ? 0.95 : 0.55),
                            ],
                          ),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: col.withValues(alpha: 0.22),
                                    blurRadius: 14,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hint,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              height: 1.25,
            ),
          ),
          if (isPercent) const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _routineCard() => Padding(
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
            'STANDARD DAILY ROUTINE (CAMP)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _timeRow('06:00', 'Roadwork / intervals', _cyan),
          _timeRow('10:00', 'Technical: drills + pads + bag', _orange),
          _timeRow('18:00', 'Sport-specific: spar / clinch / S&C', _blue),
          _timeRow('20:00', 'Recovery: mobility, cold/heat, journal', _purple),
          const SizedBox(height: 8),
          Text(
            'Rule: nothing late-night. Sleep is training.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _timeRow(String time, String text, Color col) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: col.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.withValues(alpha: 0.28)),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: col,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _boundariesCard() => Padding(
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
            'README FOR FAMILY & FRIENDS (BOUNDARIES)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _bullet(
            'I\'m in camp. Replies may be slow: training, sleep, recovery.',
            _cyan,
          ),
          _bullet(
            'No late nights, parties, or off-plan meals. This is the job.',
            _orange,
          ),
          _bullet(
            'Closer to fight week I may be quieter or irritable. It\'s the cut and the load.',
            _amber,
          ),
          _bullet(
            'Best support: short positive messages that don\'t require a reply.',
            _green,
          ),
          _bullet(
            'If you want to help: errands, meal prep on-plan, rides, quiet support.',
            _blue,
          ),
          const SizedBox(height: 8),
          Text(
            'Say: “You look ready. The work is done.” (Not: “Are you ready?”)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _packingCard() => Padding(
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
            'CAMP PACKING LIST (ESSENTIALS)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          _bullet(
            '2+ wraps • 16oz spar gloves • bag gloves • shin guards',
            _cyan,
          ),
          _bullet(
            '2 mouthguards • cup • tape • ankle supports (if used)',
            _orange,
          ),
          _bullet(
            'Recovery: first aid, foam roller, epsom salts, lacrosse ball',
            _purple,
          ),
          _bullet(
            'Nutrition: electrolytes, protein, food scale, pre-measured supps',
            _green,
          ),
          _bullet('Mind: journal, breathing routine, opponent notes', _amber),
        ],
      ),
    ),
  );

  Widget _actions() => Padding(
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
              'Phases',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => context.push('/fight-camp/guide'),
            style: FilledButton.styleFrom(
              backgroundColor: _green.withValues(alpha: 0.9),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.menu_book_outlined, size: 18),
            label: const Text(
              'Guide',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    ),
  );

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
              BoxShadow(color: col.withValues(alpha: 0.22), blurRadius: 10),
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

  String _dayLabel(int i) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i];
}

class _CampMapPainter extends CustomPainter {
  final Color grid;
  final Color glow;
  const _CampMapPainter({required this.grid, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    const step = 30.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // “Camp constellations”
    final star = Paint()..color = Colors.white.withValues(alpha: 0.07);
    for (int i = 0; i < 26; i++) {
      final dx = (math.Random(i).nextDouble() * size.width);
      final dy = (math.Random(i * 7 + 3).nextDouble() * size.height);
      canvas.drawCircle(Offset(dx, dy), 1.2, star);
    }

    // Subtle glow node near top-right
    final glowPaint = Paint()
      ..color = glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      58,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CampMapPainter oldDelegate) {
    return oldDelegate.grid != grid || oldDelegate.glow != glow;
  }
}
