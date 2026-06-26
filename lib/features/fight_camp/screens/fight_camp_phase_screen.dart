import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/services/fight_camp_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FIGHT CAMP PHASE — 6-phase camp timeline with training load, weight cut,
// phase goals, and a fight-ready indicator
// ─────────────────────────────────────────────────────────────────────────────
class FightCampPhaseScreen extends StatefulWidget {
  const FightCampPhaseScreen({super.key});
  @override
  State<FightCampPhaseScreen> createState() => _FightCampPhaseScreenState();
}

class _FightCampPhaseScreenState extends State<FightCampPhaseScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  final FightCampService _campService = FightCampService();
  Timer? _refreshTimer;
  int? _selectedPhase; // For manual expansion (null = auto)

  // Dynamic values from service
  int get _daysOut => _campService.daysUntilFight.clamp(0, 999);
  int get _activePhase => _selectedPhase ?? _currentPhase;
  int get _currentPhase => _calculateActivePhase(); // Actual camp phase
  int _currentWeight = 78;
  int _fightWeight = 70;
  double _trainingLoad = 0.72;

  /// Calculate active phase based on days remaining
  int _calculateActivePhase() {
    final days = _campService.daysUntilFight;
    if (days <= 0) return 5; // Fight week
    if (days <= 5) return 4; // Weight cut
    if (days <= 7) return 3; // Peak week
    if (days <= 28) return 2; // Sharpening
    if (days <= 42) return 1; // Strength & Power
    return 0; // Base building
  }

  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _red = Color(0xFFFF1744);
  static const _purple = Color(0xFFD500F9);
  static const _orange = Color(0xFFFF6D00);
  static const _blue = Color(0xFF2979FF);
  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF080F1E);

  static const _phases = [
    _Phase(
      emoji: '🏃',
      name: 'BASE BUILDING',
      weeks: 'Weeks 1–3',
      color: Color(0xFF00E5FF),
      goal:
          'Build aerobic engine, establish rhythms, drill fundamentals at low intensity.',
      drills: [
        'Roadwork (5km daily)',
        'Shadow boxing 6x3min',
        'Light pad work 4x3min',
        'BJJ positional rolling',
        'Mobility + flexibility',
      ],
      load: 0.45,
      done: true,
    ),
    _Phase(
      emoji: '⚡',
      name: 'STRENGTH & POWER',
      weeks: 'Weeks 4–6',
      color: Color(0xFF2979FF),
      goal:
          'Build fight-specific strength. Gym sessions 3x/week. Technical skill work continues.',
      drills: [
        'Heavy bag power combos 6x3min',
        'Strength: squat/deadlift/pull',
        'Wrestling live rounds 4x5min',
        'Pad work with power emphasis',
        'Sprint intervals 8x30sec',
      ],
      load: 0.62,
      done: true,
    ),
    _Phase(
      emoji: '🔥',
      name: 'SHARPENING',
      weeks: 'Weeks 7–10',
      color: Color(0xFFFF6D00),
      goal:
          'Hard sparring at 80-90%. Full rounds. Fight simulation. Finalise game plan.',
      drills: [
        'Sparring 5x5min (3x/week)',
        'Full pad rounds 6x4min',
        'Wrestling + clinch 30min',
        'Video analysis 2hrs',
        'Light skills drill cool-down',
      ],
      load: 0.87,
      done: false,
    ),
    _Phase(
      emoji: '🎯',
      name: 'PEAK WEEK',
      weeks: 'Week 11',
      color: Color(0xFFD500F9),
      goal:
          'Taper intensity. Last hard sesh Mon. Light movement only from Wed. Mental prep.',
      drills: [
        'Monday: full rounds — LAST hard day',
        'Tuesday: light technical only',
        'Wednesday: pads 30% power only',
        'Thursday: shadow + visualisation',
        'Friday: rest or walk',
      ],
      load: 0.55,
      done: false,
    ),
    _Phase(
      emoji: '⚖️',
      name: 'WEIGHT CUT',
      weeks: 'Days 5–1',
      color: Color(0xFFFFAB00),
      goal:
          'Hit weight safely. Prioritise muscle glycogen depletion before water. No crash cutting.',
      drills: [
        'Low-carb diet from D-5',
        'Sauna: max 1hr sessions',
        'Water restriction from D-2',
        'Rehydration protocol post-weigh-in',
        'Sleep 8hrs minimum',
      ],
      load: 0.3,
      done: false,
    ),
    _Phase(
      emoji: '🏆',
      name: 'FIGHT WEEK',
      weeks: 'Days 0–1',
      color: Color(0xFF00E676),
      goal:
          'Arrive sharp, recovered, confident. Trust the camp. Execute the plan.',
      drills: [
        'Rehydrate + carb load post-weigh-in',
        'Light movement day before',
        'Mental visualisation x2',
        'Sleep 8hrs fight night eve',
        'Warm-up protocol 45min pre-fight',
      ],
      load: 0.2,
      done: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // Initialize fight camp service and listen for updates
    _campService.initialize();
    _campService.addListener(_onCampUpdate);

    // Load real weight/training data from Firestore
    _loadCampData();

    // Refresh countdown every minute
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadCampData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final firestore = FirebaseFirestore.instance;

      // Load fighter profile for weight class / fight weight
      final fighterDoc = await firestore.collection('fighters').doc(uid).get();
      if (fighterDoc.exists) {
        final data = fighterDoc.data()!;
        final weightClass = data['weightClass'] as String? ?? '';
        // Map weight class to target fight weight (kg)
        _fightWeight = _weightClassToKg(weightClass);
      }

      // Load latest weight from fighter_stats
      final statsDoc = await firestore
          .collection('fighter_stats')
          .doc(uid)
          .get();
      if (statsDoc.exists) {
        final data = statsDoc.data()!;
        if (data['currentWeight'] != null) {
          _currentWeight = (data['currentWeight'] as num).toInt();
        }
      }

      // Load training log to calculate training load
      final logsQuery = await firestore
          .collection('training_logs')
          .where('userId', isEqualTo: uid)
          .orderBy('date', descending: true)
          .limit(14)
          .get();

      if (logsQuery.docs.isNotEmpty) {
        double totalIntensity = 0;
        for (final doc in logsQuery.docs) {
          final data = doc.data();
          totalIntensity += (data['intensity'] as num?)?.toDouble() ?? 0.5;
        }
        _trainingLoad = (totalIntensity / logsQuery.docs.length).clamp(
          0.0,
          1.0,
        );
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Fight camp data load: $e');
    }
  }

  static int _weightClassToKg(String wc) {
    switch (wc.toLowerCase()) {
      case 'strawweight':
        return 52;
      case 'flyweight':
        return 57;
      case 'bantamweight':
        return 61;
      case 'featherweight':
        return 66;
      case 'lightweight':
        return 70;
      case 'super lightweight':
        return 74;
      case 'welterweight':
        return 77;
      case 'super welterweight':
        return 79;
      case 'middleweight':
        return 84;
      case 'super middleweight':
        return 88;
      case 'light heavyweight':
        return 93;
      case 'cruiserweight':
        return 102;
      case 'heavyweight':
        return 120;
      default:
        return 70;
    }
  }

  void _onCampUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    _campService.removeListener(_onCampUpdate);
    super.dispose();
  }

  bool get _fightReady =>
      _trainingLoad > 0.65 && _currentWeight < _fightWeight + 10;
  int get _weightToLose => _currentWeight - _fightWeight;
  double get _campProgress => (_activePhase + 0.5) / _phases.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_bgCtrl.value * 2 * math.pi) * 0.4,
                -0.2,
              ),
              radius: 1.7,
              colors: const [
                Color(0xFF0D0500),
                Color(0xFF030810),
                Color(0xFF000D18),
              ],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _appBar()),
                SliverToBoxAdapter(child: _heroStats()),
                SliverToBoxAdapter(child: _progressBar()),
                SliverToBoxAdapter(child: _readinessCard()),
                SliverToBoxAdapter(child: _weightCard()),
                SliverToBoxAdapter(child: _phaseHeader()),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _phaseCard(i, _phases[i]),
                    childCount: _phases.length,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
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
              'FIGHT CAMP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Phase tracker • weight cut • readiness',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => context.push('/fight-camp/guide'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _cyan.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.menu_book_outlined, size: 14, color: _cyan),
                SizedBox(width: 6),
                Text(
                  'GUIDE',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => context.push('/fight-camp/samurai'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _purple.withValues(alpha: 0.35)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_moon_outlined, size: 14, color: _purple),
                SizedBox(width: 6),
                Text(
                  'SAMURAI',
                  style: TextStyle(
                    color: _purple,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (_fightReady ? _green : _amber).withValues(
                alpha: 0.1 + 0.05 * _pulseCtrl.value,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_fightReady ? _green : _amber).withValues(
                  alpha: 0.4 + 0.2 * _pulseCtrl.value,
                ),
              ),
            ),
            child: Text(
              _fightReady ? '✅ FIGHT READY' : '⚠️ IN CAMP',
              style: TextStyle(
                color: _fightReady ? _green : _amber,
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _heroStats() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Row(
      children: [
        _statBox('$_daysOut', 'DAYS OUT', _red),
        const SizedBox(width: 8),
        _statBox('${(_campProgress * 100).toInt()}%', 'CAMP DONE', _orange),
        const SizedBox(width: 8),
        _statBox('${(_trainingLoad * 100).toInt()}%', 'LOAD', _blue),
        const SizedBox(width: 8),
        _statBox('${_weightToLose}kg', 'TO CUT', _amber),
      ],
    ),
  );

  Widget _statBox(String val, String lbl, Color col) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [col.withValues(alpha: 0.15), _card]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: TextStyle(
              color: col,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lbl,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 7,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _progressBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CAMP PROGRESS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            Text(
              'Phase ${_activePhase + 1} of ${_phases.length}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              height: 6,
              width: (MediaQuery.of(context).size.width - 32) * _campProgress,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(color: _cyan.withValues(alpha: 0.3), blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _phases
              .asMap()
              .entries
              .map(
                (e) => Text(
                  e.value.emoji,
                  style: TextStyle(
                    fontSize: 11,
                    color: e.key <= _activePhase
                        ? Colors.white
                        : Colors.white24,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  Widget _readinessCard() {
    final r = (_trainingLoad * 100).toInt();
    final col = r >= 80
        ? _green
        : r >= 55
        ? _amber
        : _red;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [col.withValues(alpha: 0.1), _card]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'READINESS SCORE',
                style: TextStyle(
                  color: col,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '$r / 100',
                style: TextStyle(
                  color: col,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _trainingLoad,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(col),
            minHeight: 6,
          ),
          const SizedBox(height: 10),
          Text(
            r >= 80
                ? 'Excellent camp load. You are building towards peak performance. Keep the consistency.'
                : r >= 55
                ? 'Camp is progressing well. Push intensity in the next phase to build your peak.'
                : 'Training load below target. Review your weekly schedule with your coach.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ADJUST TRAINING LOAD',
            style: TextStyle(
              color: col.withValues(alpha: 0.5),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Slider(
            value: _trainingLoad,
            divisions: 20,
            activeColor: col,
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _trainingLoad = v),
          ),
        ],
      ),
    );
  }

  Widget _weightCard() => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [_amber.withValues(alpha: 0.09), _card]),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _amber.withValues(alpha: 0.25)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Text('⚖️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            const Text(
              'WEIGHT MANAGEMENT',
              style: TextStyle(
                color: Color(0xFFFFAB00),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '${_weightToLose}kg to cut',
              style: TextStyle(
                color: _amber.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentWeight}kg',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Slider(
                    value: _currentWeight.toDouble(),
                    min: 60,
                    max: 100,
                    divisions: 40,
                    activeColor: _amber,
                    inactiveColor: Colors.white12,
                    onChanged: (v) =>
                        setState(() => _currentWeight = v.round()),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: Colors.white12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FIGHT WEIGHT',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_fightWeight}kg',
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Welterweight Division',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_weightToLose > 12)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _red.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: _red.withValues(alpha: 0.7),
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_weightToLose}kg cut is aggressive. Review with your coach. Consider moving up a weight class.',
                    style: TextStyle(
                      color: _red.withValues(alpha: 0.7),
                      fontSize: 9,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _phaseHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: Text(
      'CAMP PHASES',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _phaseCard(int idx, _Phase p) {
    final isActive = idx == _activePhase;
    final isCurrentPhase = idx == _currentPhase;
    final isDone = idx < _currentPhase;
    return GestureDetector(
      onTap: () =>
          setState(() => _selectedPhase = _selectedPhase == idx ? null : idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.fromLTRB(16, 0, 16, isActive ? 12 : 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [p.color.withValues(alpha: 0.18), _card]
                : [Colors.transparent, Colors.transparent],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? p.color.withValues(alpha: 0.45) : Colors.white12,
          ),
        ),
        child: Column(
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? p.color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? p.color.withValues(alpha: 0.4)
                            : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        p.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: isActive
                                ? p.color
                                : isDone
                                ? Colors.white38
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          p.weeks,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        'DONE',
                        style: TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (isCurrentPhase && !isDone)
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, _) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.color.withValues(
                            alpha: 0.1 + 0.05 * _pulseCtrl.value,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: p.color.withValues(
                              alpha: 0.4 + 0.2 * _pulseCtrl.value,
                            ),
                          ),
                        ),
                        child: Text(
                          'NOW',
                          style: TextStyle(
                            color: p.color,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isActive
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white24,
                    size: 16,
                  ),
                ],
              ),
            ),
            // Expanded detail
            if (isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: p.color.withValues(alpha: 0.12),
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    Text(
                      'GOAL',
                      style: TextStyle(
                        color: p.color.withValues(alpha: 0.55),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.goal,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'KEY DRILLS',
                      style: TextStyle(
                        color: p.color.withValues(alpha: 0.55),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...p.drills.map(
                      (d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(right: 8, top: 1),
                              decoration: BoxDecoration(
                                color: p.color.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                d,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'PHASE LOAD',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: p.load,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation(p.color),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(p.load * 100).toInt()}%',
                          style: TextStyle(
                            color: p.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Phase {
  final String emoji, name, weeks, goal;
  final List<String> drills;
  final Color color;
  final double load;
  final bool done;
  const _Phase({
    required this.emoji,
    required this.name,
    required this.weeks,
    required this.color,
    required this.goal,
    required this.drills,
    required this.load,
    required this.done,
  });
}
