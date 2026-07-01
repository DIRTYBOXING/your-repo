import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// LIVE SCORING — JUDGE INTERFACE v1.0
///
/// The ringside weapon. 10-point-must scoring system.
/// Judges enter scores round-by-round. Aggregate scorecards displayed live.
///
/// Built from pain. Forged in battles. Hardened by resilience.
/// ═══════════════════════════════════════════════════════════════════════════

class LiveScoringScreen extends StatefulWidget {
  final String eventId;
  const LiveScoringScreen({super.key, this.eventId = 'ibc-03-gold-coast'});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _scanCtrl;

  int _selectedBoutIndex = 0;
  int _currentRound = 1;
  bool _isJudge = false;
  String _judgeName = '';

  // Score state per round: {round: {fighter: score}}
  final Map<int, Map<String, int>> _scores = {};

  // IBC III fight card
  final List<_BoutData> _bouts = [
    const _BoutData(
      'MAIN EVENT',
      'Jay Cutler',
      'Luke Modini',
      'jay-cutler',
      'luke-modini',
      'LHW TITLE',
      5,
      'IBC',
      'IBC',
      '🇦🇺',
      '🇦🇺',
    ),
    const _BoutData(
      'CO-MAIN',
      'Blake Watts',
      'Jordan Silva',
      'blake-watts',
      'jordan-silva',
      'WW',
      3,
      '8-1-0',
      '7-2-0',
      '🇦🇺',
      '🇧🇷',
    ),
    const _BoutData(
      'BOUT 3',
      'Nikita Davids',
      'Sarah King',
      'nikita-davids',
      'sarah-king',
      'SW',
      3,
      '6-0-0',
      '5-1-0',
      '🇿🇦',
      '🇦🇺',
    ),
    const _BoutData(
      'BOUT 2',
      'Danny Torres',
      'Koji Tanaka',
      'danny-torres',
      'koji-tanaka',
      'LW',
      3,
      '9-4-0',
      '7-3-0',
      '🇲🇽',
      '🇯🇵',
    ),
    const _BoutData(
      'OPENER',
      'Liam O\'Brien',
      'Ratu Vunipola',
      'liam-obrien',
      'ratu-vunipola',
      'HW',
      3,
      '4-1-0',
      '3-0-0',
      '🇮🇪',
      '🇫🇯',
    ),
  ];

  _BoutData get _currentBout => _bouts[_selectedBoutIndex];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => Icon(
                Icons.scoreboard,
                color: Color.lerp(
                  const Color(0xFF00E5FF),
                  const Color(0xFFFF0040),
                  _pulseCtrl.value,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE SCORING',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'IBC III — GOLD COAST BRAWL',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: Color(0xFF00E5FF),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _isJudge
              ? Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0040),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'JUDGE: $_judgeName',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _showJudgeLogin,
                  child: const Text(
                    'JUDGE LOGIN',
                    style: TextStyle(
                      color: Color(0xFFFF0040),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          _buildScanLine(),
          _buildBoutSelector(),
          _buildBoutHeader(),
          _buildRoundSelector(),
          Expanded(
            child: _isJudge ? _buildJudgeScoringUI() : _buildViewerScoreboard(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _scanCtrl,
      builder: (_, _) => Container(
        height: 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              const Color(0xFFFF0040).withValues(alpha: _scanCtrl.value),
              Colors.transparent,
            ],
            stops: [
              math.max(0, _scanCtrl.value - 0.2),
              _scanCtrl.value,
              math.min(1, _scanCtrl.value + 0.2),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOUT SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBoutSelector() {
    return Container(
      height: 50,
      color: const Color(0xFF0A0A14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _bouts.length,
        itemBuilder: (context, i) {
          final sel = i == _selectedBoutIndex;
          final bout = _bouts[i];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedBoutIndex = i;
              _currentRound = 1;
            }),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFFFF0040).withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: sel ? const Color(0xFFFF0040) : Colors.white12,
                  width: sel ? 1.5 : 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                bout.label,
                style: TextStyle(
                  color: sel ? const Color(0xFFFF0040) : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOUT HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBoutHeader() {
    final bout = _currentBout;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF0040).withValues(alpha: 0.1),
            Colors.transparent,
            const Color(0xFF00E5FF).withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          // Fighter 1
          Expanded(
            child: Column(
              children: [
                Text(bout.f1Flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  bout.fighter1.split(' ').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  bout.f1Record,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // VS
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0040).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bout.weightClass,
                  style: const TextStyle(
                    color: Color(0xFFFF0040),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'VS',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bout.totalRounds} RDS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          // Fighter 2
          Expanded(
            child: Column(
              children: [
                Text(bout.f2Flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  bout.fighter2.split(' ').last.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  bout.f2Record,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
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
  // ROUND SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRoundSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: const Color(0xFF0A0A14),
      child: Row(
        children: [
          Text(
            'ROUND',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(_currentBout.totalRounds, (i) {
            final round = i + 1;
            final sel = round == _currentRound;
            return GestureDetector(
              onTap: () => setState(() => _currentRound = round),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sel
                      ? const Color(0xFFFF0040)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel ? const Color(0xFFFF0040) : Colors.white12,
                    width: sel ? 2 : 0.5,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFFF0040,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'R$round',
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          _buildTotalScore(),
        ],
      ),
    );
  }

  Widget _buildTotalScore() {
    int f1Total = 0;
    int f2Total = 0;
    _scores.forEach((_, roundScores) {
      f1Total += roundScores[_currentBout.f1Id] ?? 0;
      f2Total += roundScores[_currentBout.f2Id] ?? 0;
    });

    if (f1Total == 0 && f2Total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$f1Total',
            style: TextStyle(
              color: f1Total > f2Total ? const Color(0xFF00FF88) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            ' — ',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
          Text(
            '$f2Total',
            style: TextStyle(
              color: f2Total > f1Total ? const Color(0xFF00FF88) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JUDGE SCORING UI — 10 POINT MUST SYSTEM
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildJudgeScoringUI() {
    final bout = _currentBout;
    final roundScores = _scores[_currentRound] ?? {};
    final f1Score = roundScores[bout.f1Id] ?? 10;
    final f2Score = roundScores[bout.f2Id] ?? 10;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scoring instruction
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF0040).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFF0040).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFFF0040),
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '10-POINT MUST SYSTEM: The round winner gets 10 points. Loser gets 9 (or less for knockdowns/dominance).',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Fighter 1 scoring
        _scoringCard(
          bout.fighter1,
          bout.f1Id,
          bout.f1Flag,
          f1Score,
          const Color(0xFFFF0040),
        ),
        const SizedBox(height: 12),

        // Fighter 2 scoring
        _scoringCard(
          bout.fighter2,
          bout.f2Id,
          bout.f2Flag,
          f2Score,
          const Color(0xFF00E5FF),
        ),
        const SizedBox(height: 24),

        // Deductions
        _deductionOptions(),
        const SizedBox(height: 24),

        // Submit round
        _submitRoundButton(),
        const SizedBox(height: 16),

        // Round history
        _roundHistory(),
      ],
    );
  }

  Widget _scoringCard(
    String name,
    String id,
    String flag,
    int score,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score',
                  style: TextStyle(
                    color: accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Score picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [10, 9, 8, 7].map((val) {
              final selected = score == val;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _scores.putIfAbsent(_currentRound, () => {});
                    _scores[_currentRound]![id] = val;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 56,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? accent
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? accent : Colors.white12,
                      width: selected ? 2 : 0.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$val',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white38,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _deductionOptions() {
    final deductions = [
      'KNOCKDOWN (-1)',
      'POINT DEDUCTION',
      '10-8 ROUND',
      'EVEN ROUND (10-10)',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ROUND NOTES',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: deductions
              .map(
                (d) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    d,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _submitRoundButton() {
    final hasScores =
        _scores[_currentRound] != null &&
        _scores[_currentRound]!.containsKey(_currentBout.f1Id) &&
        _scores[_currentRound]!.containsKey(_currentBout.f2Id);

    return GestureDetector(
      onTap: hasScores ? _submitRound : null,
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: hasScores
                ? LinearGradient(
                    colors: [
                      const Color(
                        0xFFFF0040,
                      ).withValues(alpha: 0.8 + _pulseCtrl.value * 0.2),
                      const Color(0xFFFF6600).withValues(alpha: 0.6),
                    ],
                  )
                : null,
            color: hasScores ? null : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasScores ? const Color(0xFFFF0040) : Colors.white12,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.gavel,
                color: hasScores ? Colors.white : Colors.white24,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'SUBMIT ROUND $_currentRound SCORE',
                style: TextStyle(
                  color: hasScores ? Colors.white : Colors.white24,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRound() async {
    final bout = _currentBout;
    final roundScores = _scores[_currentRound]!;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('scoring')
          .doc('${bout.f1Id}-vs-${bout.f2Id}')
          .collection('rounds')
          .doc('round-$_currentRound')
          .set({
            'round': _currentRound,
            'judge': _judgeName,
            'fighter1': bout.f1Id,
            'fighter1Score': roundScores[bout.f1Id],
            'fighter2': bout.f2Id,
            'fighter2Score': roundScores[bout.f2Id],
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ Score submit failed: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ R$_currentRound: ${bout.fighter1.split(' ').last} ${roundScores[bout.f1Id]} — ${roundScores[bout.f2Id]} ${bout.fighter2.split(' ').last}',
          ),
          backgroundColor: Colors.green.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Auto-advance to next round
      if (_currentRound < bout.totalRounds) {
        setState(() => _currentRound++);
      }
    }
  }

  Widget _roundHistory() {
    if (_scores.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCORECARD',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      _currentBout.fighter1.split(' ').last.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFF0040),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _currentBout.fighter2.split(' ').last.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 16),
              // Rounds
              ..._scores.entries
                  .where(
                    (e) =>
                        e.value.containsKey(_currentBout.f1Id) &&
                        e.value.containsKey(_currentBout.f2Id),
                  )
                  .map((entry) {
                    final f1 = entry.value[_currentBout.f1Id]!;
                    final f2 = entry.value[_currentBout.f2Id]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              'R${entry.key}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$f1',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: f1 > f2
                                    ? const Color(0xFF00FF88)
                                    : f1 < f2
                                    ? const Color(0xFFFF0040)
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '$f2',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: f2 > f1
                                    ? const Color(0xFF00FF88)
                                    : f2 < f1
                                    ? const Color(0xFFFF0040)
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VIEWER SCOREBOARD — Fan view (no judge access)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildViewerScoreboard() {
    final bout = _currentBout;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live scoring badge
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(
                    0xFFFF0040,
                  ).withValues(alpha: 0.1 + _pulseCtrl.value * 0.05),
                  const Color(0xFF00E5FF).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF0040).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFF0040,
                    ).withValues(alpha: _pulseCtrl.value),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'LIVE SCORING — Scores update in real-time as judges submit',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Fan scoring
        Text(
          'SCORE THIS FIGHT',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            children: [
              Text(
                'ROUND $_currentRound — Who won this round?',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _fanVoteButton(
                      bout.fighter1,
                      bout.f1Id,
                      bout.f1Flag,
                      const Color(0xFFFF0040),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _fanVoteButton(
                      bout.fighter2,
                      bout.f2Id,
                      bout.f2Flag,
                      const Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _scores.putIfAbsent(_currentRound, () => {});
                    _scores[_currentRound]![bout.f1Id] = 10;
                    _scores[_currentRound]![bout.f2Id] = 10;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'EVEN ROUND',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Aggregate scores from Firestore
        _buildFirestoreScoreboard(),
        const SizedBox(height: 20),

        // Your scorecard
        _roundHistory(),
        const SizedBox(height: 16),

        // Become a judge CTA
        GestureDetector(
          onTap: _showJudgeLogin,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6600).withValues(alpha: 0.1),
                  const Color(0xFFFF0040).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF6600).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.gavel, color: Color(0xFFFF6600), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RINGSIDE JUDGE ACCESS',
                        style: TextStyle(
                          color: Color(0xFFFF6600),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Official judges can log in for round-by-round scoring',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFFFF6600),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fanVoteButton(String name, String id, String flag, Color color) {
    final voted =
        _scores[_currentRound]?[id] == 10 &&
        _scores[_currentRound]?.values.where((v) => v == 10).length == 1;

    return GestureDetector(
      onTap: () {
        final otherId = id == _currentBout.f1Id
            ? _currentBout.f2Id
            : _currentBout.f1Id;
        setState(() {
          _scores.putIfAbsent(_currentRound, () => {});
          _scores[_currentRound]![id] = 10;
          _scores[_currentRound]![otherId] = 9;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: voted
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: voted ? color : Colors.white12,
            width: voted ? 2 : 0.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              name.split(' ').last.toUpperCase(),
              style: TextStyle(
                color: voted ? color : Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreScoreboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('scoring')
          .doc('${_currentBout.f1Id}-vs-${_currentBout.f2Id}')
          .collection('rounds')
          .orderBy('round')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.scoreboard,
                  color: Colors.white.withValues(alpha: 0.1),
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'OFFICIAL SCORECARDS\nWaiting for judge submissions...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        int f1Total = 0;
        int f2Total = 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00FF88).withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00FF88).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.gavel, color: Color(0xFF00FF88), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'OFFICIAL SCORECARDS',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Header
              Row(
                children: [
                  const SizedBox(width: 50),
                  Expanded(
                    child: Text(
                      _currentBout.fighter1.split(' ').last.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFF0040),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _currentBout.fighter2.split(' ').last.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white12),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final f1 = data['fighter1Score'] as int? ?? 0;
                final f2 = data['fighter2Score'] as int? ?? 0;
                f1Total += f1;
                f2Total += f2;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          'R${data['round']}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$f1',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: f1 > f2
                                ? const Color(0xFF00FF88)
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$f2',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: f2 > f1
                                ? const Color(0xFF00FF88)
                                : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(color: Colors.white12),
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      'TOTAL',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$f1Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: f1Total >= f2Total
                            ? const Color(0xFF00FF88)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$f2Total',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: f2Total >= f1Total
                            ? const Color(0xFF00FF88)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF0A0A14),
      child: Row(
        children: [
          Icon(
            Icons.scoreboard,
            color: Colors.white.withValues(alpha: 0.2),
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            'DFC LIVE SCORING • 10-POINT MUST SYSTEM',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(
                  0xFFFF0040,
                ).withValues(alpha: _pulseCtrl.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFFFF0040),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JUDGE LOGIN
  // ═══════════════════════════════════════════════════════════════════════════
  void _showJudgeLogin() {
    final controller = TextEditingController();
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Color(0xFFFF0040)),
            SizedBox(width: 10),
            Text(
              'JUDGE LOGIN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Judge Name',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF0040)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Access PIN',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF0040)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0040),
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _isJudge = true;
                  _judgeName = controller.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '⚖️ Judge ${controller.text.trim()} — scoring mode activated',
                    ),
                    backgroundColor: const Color(0xFFFF0040),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'LOGIN',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA
// ═══════════════════════════════════════════════════════════════════════════

class _BoutData {
  final String label;
  final String fighter1;
  final String fighter2;
  final String f1Id;
  final String f2Id;
  final String weightClass;
  final int totalRounds;
  final String f1Record;
  final String f2Record;
  final String f1Flag;
  final String f2Flag;

  const _BoutData(
    this.label,
    this.fighter1,
    this.fighter2,
    this.f1Id,
    this.f2Id,
    this.weightClass,
    this.totalRounds,
    this.f1Record,
    this.f2Record,
    this.f1Flag,
    this.f2Flag,
  );
}
