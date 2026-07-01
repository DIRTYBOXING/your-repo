import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/fighter_model.dart';
import '../../../shared/models/stats/live_fight_stats.dart';
import '../../../shared/widgets/shareable_fighter_card.dart';

class FighterProfileScreen extends StatefulWidget {
  final FighterModel fighter;

  const FighterProfileScreen({super.key, required this.fighter});

  @override
  State<FighterProfileScreen> createState() => _FighterProfileScreenState();
}

class _FighterProfileScreenState extends State<FighterProfileScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  final GlobalKey _shareCardKey = GlobalKey();

  bool _available = true;
  bool _sharingCard = false;

  static const _skillLabels = [
    'STRIKING',
    'WRESTLING',
    'SUBMISSIONS',
    'CARDIO',
    'CHIN',
    'SPEED',
  ];

  static const _skillValues = [8.6, 7.4, 6.9, 8.8, 7.8, 8.2];

  static const _history = [
    _FightHistory(
      result: 'W',
      opponent: 'Leon Hart',
      method: 'TKO R2',
      event: 'DFC Fight Night 14',
      dateText: '11 Feb 2026',
    ),
    _FightHistory(
      result: 'L',
      opponent: 'M. De Silva',
      method: 'DEC',
      event: 'DFC Numbered 27',
      dateText: '09 Dec 2025',
    ),
    _FightHistory(
      result: 'W',
      opponent: 'Ari Tevita',
      method: 'SUB R1',
      event: 'Pacific Rumble 4',
      dateText: '02 Oct 2025',
    ),
    _FightHistory(
      result: 'W',
      opponent: 'S. Ocampo',
      method: 'DEC',
      event: 'DFC Fight Night 11',
      dateText: '16 Jul 2025',
    ),
    _FightHistory(
      result: 'NC',
      opponent: 'R. Kovac',
      method: 'No Contest',
      event: 'DFC Numbered 23',
      dateText: '29 Mar 2025',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _available =
        widget.fighter.matchupAvailability == MatchupAvailability.available;
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fighter = widget.fighter;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: const Text(
          'Fighter Profile',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _entryCtrl,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _buildHeader(fighter),
            const SizedBox(height: 12),
            _buildShareCardSection(fighter),
            const SizedBox(height: 12),
            _buildAvailabilityCard(),
            const SizedBox(height: 12),
            _buildLiveStatsCard(),
            const SizedBox(height: 12),
            _buildRadarCard(),
            const SizedBox(height: 12),
            _buildFightHistoryCard(),
          ],
        ),
      ),
    );
  }

  FighterCardData _fighterCardData(FighterModel fighter) {
    return FighterCardData(
      id: fighter.id,
      name: fighter.fullName,
      nickname: fighter.nickname,
      photoUrl: fighter.photoUrl,
      wins: fighter.wins,
      losses: fighter.losses,
      draws: fighter.draws,
      knockouts: fighter.knockouts,
      submissions: fighter.submissions,
      weightClass: fighter.weightClass,
      gym: fighter.currentGymId,
      country: fighter.country ?? fighter.nationality,
      isVerified: fighter.status == FighterStatus.active,
    );
  }

  Future<void> _shareFighterCard() async {
    if (_sharingCard) return;

    setState(() => _sharingCard = true);
    final messenger = ScaffoldMessenger.of(context);
    final shared = await FighterCardService().shareCard(
      _shareCardKey,
      _fighterCardData(widget.fighter),
    );

    if (!mounted) return;
    setState(() => _sharingCard = false);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          shared
              ? 'Fighter card ready to share.'
              : 'Unable to generate fighter card image.',
        ),
      ),
    );
  }

  Widget _buildHeader(FighterModel fighter) {
    final totalFights = fighter.totalFights == 0 ? 1 : fighter.totalFights;
    final koPct = (fighter.knockouts / totalFights) * 100;
    final subPct = (fighter.submissions / totalFights) * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.18),
            AppTheme.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fighter.fullName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${fighter.weightClass ?? 'Open Weight'} · ${fighter.sportType ?? 'MMA'} · ${fighter.country ?? 'Unknown'}',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            fighter.record,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Professional Record',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniStat(
                'Win%',
                '${fighter.winPercentage.toStringAsFixed(1)}%',
                const Color(0xFF69FF47),
              ),
              _miniStat(
                'KO%',
                '${koPct.toStringAsFixed(1)}%',
                const Color(0xFFFF6B35),
              ),
              _miniStat(
                'Sub%',
                '${subPct.toStringAsFixed(1)}%',
                const Color(0xFFFFD740),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareCardSection(FighterModel fighter) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shareable Fighter Card',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Generate a real PNG from this profile preview.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _sharingCard ? null : _shareFighterCard,
                icon: _sharingCard
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share, size: 14),
                label: Text(_sharingCard ? 'EXPORTING' : 'SHARE PNG'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00E5FF),
                  side: BorderSide(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ShareableFighterCard(
              repaintKey: _shareCardKey,
              fighter: _fighterCardData(fighter),
              width: 340,
              height: 430,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (_available ? AppTheme.neonGreen : Colors.orangeAccent)
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) => Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: (_available ? AppTheme.neonGreen : Colors.orangeAccent)
                    .withValues(alpha: 0.55 + (0.45 * _pulseCtrl.value)),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_available ? AppTheme.neonGreen : Colors.orangeAccent)
                            .withValues(alpha: 0.35),
                    blurRadius: 7,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _available ? 'Available for matchup' : 'Not available right now',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Switch(
            value: _available,
            activeThumbColor: AppTheme.neonGreen,
            activeTrackColor: AppTheme.neonGreen.withValues(alpha: 0.35),
            onChanged: (v) => setState(() => _available = v),
          ),
        ],
      ),
    );
  }

  /// Real-time live fight stats card — streams from Firestore
  /// `live_stats/{eventId}` written by syncGeniusStats Cloud Function.
  /// Only visible when a live event is linked to this fighter.
  Widget _buildLiveStatsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_stats')
          .where('matchStatus', isEqualTo: 'live')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Find a live_stats doc where this fighter is red or blue corner
        LiveFightStats? stats;
        for (final doc in snapshot.data!.docs) {
          final candidate = LiveFightStats.fromFirestore(doc);
          final nameLC = widget.fighter.fullName.toLowerCase();
          if (candidate.redCorner.name.toLowerCase() == nameLC ||
              candidate.blueCorner.name.toLowerCase() == nameLC) {
            stats = candidate;
            break;
          }
        }

        if (stats == null) return const SizedBox.shrink();

        final isRed =
            stats.redCorner.name.toLowerCase() ==
            widget.fighter.fullName.toLowerCase();
        final mine = isRed ? stats.redCorner : stats.blueCorner;
        final opp = isRed ? stats.blueCorner : stats.redCorner;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.redAccent.withValues(alpha: 0.12),
                AppTheme.cardDark,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.45)),
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
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE — Round ${stats.round}  ${stats.clockDisplay}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _liveStatCol(
                    mine.name,
                    mine.strikes,
                    mine.takedowns,
                    mine.liveOdds,
                    const Color(0xFF00E5FF),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  _liveStatCol(
                    opp.name,
                    opp.strikes,
                    opp.takedowns,
                    opp.liveOdds,
                    Colors.orangeAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _liveStatCol(
    String name,
    int strikes,
    int takedowns,
    double? odds,
    Color accent,
  ) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$strikes STR',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$takedowns TD',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        if (odds != null) ...[
          const SizedBox(height: 4),
          Text(
            odds > 0 ? '+${odds.toStringAsFixed(0)}' : odds.toStringAsFixed(0),
            style: const TextStyle(
              color: AppTheme.neonGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRadarCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Combat Profile Radar',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 5,
                ticksTextStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
                tickBorderData: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                gridBorderData: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
                titleTextStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
                getTitle: (index, _) =>
                    RadarChartTitle(text: _skillLabels[index]),
                dataSets: [
                  RadarDataSet(
                    dataEntries: _skillValues
                        .map((v) => RadarEntry(value: v))
                        .toList(),
                    fillColor: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                    borderColor: const Color(0xFF00E5FF),
                    borderWidth: 2,
                    entryRadius: 2.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFightHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Fight History',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _sharingCard ? null : _shareFighterCard,
                icon: const Icon(Icons.share, size: 14),
                label: const Text('SHARE CARD'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00E5FF),
                  side: BorderSide(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._history.map(_timelineRow),
        ],
      ),
    );
  }

  Widget _timelineRow(_FightHistory item) {
    final color = switch (item.result) {
      'W' => AppTheme.neonGreen,
      'L' => Colors.redAccent,
      _ => const Color(0xFFFFD740),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            alignment: Alignment.center,
            child: Text(
              item.result,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${item.opponent}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${item.method} · ${item.event}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            item.dateText,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FightHistory {
  final String result;
  final String opponent;
  final String method;
  final String event;
  final String dateText;

  const _FightHistory({
    required this.result,
    required this.opponent,
    required this.method,
    required this.event,
    required this.dateText,
  });
}
