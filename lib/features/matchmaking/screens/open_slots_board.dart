import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bout_slot_model.dart';
import '../../../shared/models/fighter_model.dart';
import '../../../shared/services/matchmaking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 🥊 OPEN SLOTS BOARD — DFC Matchmaking Engine
// The live marketplace where promoters post open slots and fighters apply.
// ─────────────────────────────────────────────────────────────────────────────

class OpenSlotsBoard extends StatefulWidget {
  final String userId;
  final String userRole; // 'fighter' | 'promoter' | 'admin'

  const OpenSlotsBoard({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<OpenSlotsBoard> createState() => _OpenSlotsBoardState();
}

class _OpenSlotsBoardState extends State<OpenSlotsBoard>
    with TickerProviderStateMixin {
  late final AnimationController _sonarCtrl;
  late final AnimationController _entryCtrl;
  late final TabController _tabCtrl;

  final _service = MatchmakingService();

  String? _filterWeightClass;
  String? _filterSport;

  // ── Demo Data ────────────────────────────────────────────────────────────
  static final List<BoutSlotModel> _demoSlots = [
    BoutSlotModel(
      id: 'demo_s1',
      promoterId: 'demo_p1',
      promoterName: 'Fight Network Australia',
      eventId: 'demo_e1',
      eventName: 'DFC Road to Australia III',
      eventDate: DateTime(2026, 6, 15),
      venue: 'Melbourne Arena',
      city: 'Melbourne',
      country: 'Australia',
      weightClass: 'Lightweight',
      sportType: 'MMA',
      slotType: BoutSlotType.mainEvent,
      purse: 15000,
      applicationCount: 7,
      notes: 'Seeking intl fighter — Pacific, Asia, or NZ preferred.',
      targetCountries: const ['Papua New Guinea', 'Fiji', 'New Zealand'],
      createdAt: DateTime(2026, 3),
      updatedAt: DateTime(2026, 3, 11),
    ),
    BoutSlotModel(
      id: 'demo_s2',
      promoterId: 'demo_p2',
      promoterName: 'Pacific Combat Series',
      eventId: 'demo_e2',
      eventName: 'Pacific Rumble V',
      eventDate: DateTime(2026, 7, 3),
      venue: 'Port Moresby Stadium',
      city: 'Port Moresby',
      country: 'Papua New Guinea',
      weightClass: 'Welterweight',
      sportType: 'MMA',
      slotType: BoutSlotType.coMain,
      purse: 5000,
      applicationCount: 3,
      notes: 'Co-main slot open for a fighter with 5+ pro bouts.',
      targetCountries: const ['Australia', 'Fiji', 'Solomon Islands'],
      createdAt: DateTime(2026, 3, 5),
      updatedAt: DateTime(2026, 3, 11),
    ),
    BoutSlotModel(
      id: 'demo_s3',
      promoterId: 'demo_p3',
      promoterName: 'K1 India Open',
      eventId: 'demo_e3',
      eventName: 'K1 India Open 2026',
      eventDate: DateTime(2026, 8, 20),
      venue: 'NSCI Dome',
      city: 'Mumbai',
      country: 'India',
      weightClass: 'Featherweight',
      sportType: 'Kickboxing',
      slotType: BoutSlotType.mainEvent,
      purse: 8000,
      applicationCount: 14,
      notes: 'Main event slot. Must have verified kickboxing record.',
      targetCountries: const ['Japan', 'Thailand', 'Australia'],
      createdAt: DateTime(2026, 3, 3),
      updatedAt: DateTime(2026, 3, 11),
    ),
    BoutSlotModel(
      id: 'demo_s4',
      promoterId: 'demo_p4',
      promoterName: 'EFC Africa',
      eventId: 'demo_e4',
      eventName: 'EFC 120 — Cape Town',
      eventDate: DateTime(2026, 9, 5),
      venue: 'GrandWest Arena',
      city: 'Cape Town',
      country: 'South Africa',
      weightClass: 'Bantamweight',
      sportType: 'MMA',
      purse: 3000,
      applicationCount: 5,
      targetCountries: const ['Nigeria', 'Kenya', 'United Kingdom'],
      createdAt: DateTime(2026, 3, 8),
      updatedAt: DateTime(2026, 3, 11),
    ),
    BoutSlotModel(
      id: 'demo_s5',
      promoterId: 'demo_p5',
      promoterName: 'NZ Fight Series',
      eventId: 'demo_e5',
      eventName: 'NZ Fight Series — Auckland',
      eventDate: DateTime(2026, 5, 28),
      venue: 'Spark Arena',
      city: 'Auckland',
      country: 'New Zealand',
      weightClass: 'Middleweight',
      sportType: 'Boxing',
      slotType: BoutSlotType.coMain,
      purse: 9000,
      applicationCount: 11,
      notes: 'Pro boxing record required. 8+ bouts minimum.',
      targetCountries: const ['Australia', 'Samoa', 'Tonga'],
      createdAt: DateTime(2026, 3, 2),
      updatedAt: DateTime(2026, 3, 11),
    ),
  ];

  static final List<FighterModel> _demoFighters = [
    FighterModel(
      id: 'demo_f1',
      userId: 'demo_u1',
      fullName: 'Marcus Taufa',
      nickname: 'The Bull',
      nationality: 'Tongan-Australian',
      country: 'Australia',
      city: 'Sydney',
      weightClass: 'Lightweight',
      sportType: 'MMA',
      wins: 12,
      losses: 2,
      knockouts: 8,
      submissions: 2,
      createdAt: DateTime(2025),
      updatedAt: DateTime(2026, 3),
    ),
    FighterModel(
      id: 'demo_f2',
      userId: 'demo_u2',
      fullName: 'Jai Singh',
      nickname: 'The Maharaja',
      nationality: 'Indian',
      country: 'India',
      city: 'Mumbai',
      weightClass: 'Featherweight',
      sportType: 'Kickboxing',
      wins: 18,
      losses: 4,
      draws: 1,
      knockouts: 12,
      createdAt: DateTime(2024, 6),
      updatedAt: DateTime(2026, 2, 15),
    ),
    FighterModel(
      id: 'demo_f3',
      userId: 'demo_u3',
      fullName: 'Ezekiel Banda',
      nickname: 'The Lion',
      nationality: 'Zambian',
      country: 'Zambia',
      city: 'Lusaka',
      weightClass: 'Welterweight',
      sportType: 'MMA',
      wins: 9,
      losses: 1,
      knockouts: 5,
      submissions: 3,
      createdAt: DateTime(2024, 9),
      updatedAt: DateTime(2026, 3, 5),
    ),
    FighterModel(
      id: 'demo_f4',
      userId: 'demo_u4',
      fullName: 'Tama Faleolo',
      nickname: 'Samoa Storm',
      nationality: 'Samoan',
      country: 'Samoa',
      city: 'Apia',
      weightClass: 'Middleweight',
      sportType: 'Boxing',
      wins: 15,
      losses: 3,
      draws: 2,
      knockouts: 9,
      createdAt: DateTime(2023, 4),
      updatedAt: DateTime(2026, 1, 10),
    ),
    FighterModel(
      id: 'demo_f5',
      userId: 'demo_u5',
      fullName: 'Yuki Tanaka',
      nationality: 'Japanese',
      country: 'Japan',
      city: 'Tokyo',
      weightClass: 'Bantamweight',
      sportType: 'MMA',
      wins: 21,
      losses: 5,
      knockouts: 7,
      submissions: 11,
      createdAt: DateTime(2022, 7),
      updatedAt: DateTime(2026, 3, 8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _sonarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _sonarCtrl.dispose();
    _entryCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  List<BoutSlotModel> _applySlotFilters(List<BoutSlotModel> slots) {
    return slots.where((s) {
      if (_filterWeightClass != null && s.weightClass != _filterWeightClass) {
        return false;
      }
      if (_filterSport != null && s.sportType != _filterSport) return false;
      return true;
    }).toList();
  }

  List<FighterModel> _applyFighterFilters(List<FighterModel> fighters) {
    return fighters.where((f) {
      if (_filterWeightClass != null && f.weightClass != _filterWeightClass) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.radar, color: AppTheme.accentTeal, size: 20),
            SizedBox(width: 8),
            Text(
              'Matchmaking Engine',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSonarHeader(),
          _buildFilterStrip(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [_buildSlotsTab(), _buildFightersTab()],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sonar Header ──────────────────────────────────────────────────────────
  Widget _buildSonarHeader() {
    return Container(
      height: 165,
      color: AppTheme.cardDark,
      child: Row(
        children: [
          // Left panel - stats
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'MATCHMAKING ENGINE',
                    style: TextStyle(
                      color: AppTheme.accentTeal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'DFC Open Network',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Promoters post slots. Fighters apply. Fights happen.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const _PulsingDot(color: AppTheme.neonGreen),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 14),
                      _buildStatChip(
                        Icons.event_available,
                        _demoSlots.length.toString(),
                        'Slots',
                        AppTheme.accentTeal,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.sports_mma,
                        _demoFighters.length.toString(),
                        'Fighters',
                        AppTheme.neonGreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Right panel - sonar
          SizedBox(
            width: 165,
            height: 165,
            child: AnimatedBuilder(
              animation: _sonarCtrl,
              builder: (context, _) => CustomPaint(
                painter: _SonarPainter(_sonarCtrl.value * 2 * math.pi),
                size: const Size(165, 165),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Filter Strip ─────────────────────────────────────────────────────────
  Widget _buildFilterStrip() {
    final weightClasses = ['All', ...AppConstants.mmaWeightClasses];
    final sports = ['All', ...AppConstants.sportTypes];

    return Container(
      color: AppTheme.cardDark,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weightClasses.map((wc) {
                final selected = wc == 'All'
                    ? _filterWeightClass == null
                    : _filterWeightClass == wc;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(
                      () => _filterWeightClass = wc == 'All' ? null : wc,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accentTeal.withValues(alpha: 0.20)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.accentTeal
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        wc,
                        style: TextStyle(
                          color: selected
                              ? AppTheme.accentTeal
                              : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: sports.map((sp) {
                final selected = sp == 'All'
                    ? _filterSport == null
                    : _filterSport == sp;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _filterSport = sp == 'All' ? null : sp),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.neonGreen.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.neonGreen
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        sp,
                        style: TextStyle(
                          color: selected
                              ? AppTheme.neonGreen
                              : AppTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppTheme.cardDark,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppTheme.accentTeal,
        labelColor: AppTheme.accentTeal,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.event_available, size: 16), text: 'OPEN SLOTS'),
          Tab(icon: Icon(Icons.sports_mma, size: 16), text: 'FIGHTERS'),
        ],
      ),
    );
  }

  // ── Slots Tab ─────────────────────────────────────────────────────────────
  Widget _buildSlotsTab() {
    return StreamBuilder<List<BoutSlotModel>>(
      stream: _service.streamOpenSlots(),
      builder: (context, snap) {
        final live = snap.data ?? [];
        final slots = _applySlotFilters(live.isNotEmpty ? live : _demoSlots);

        if (slots.isEmpty) {
          return _buildEmptyState(
            'No Open Slots',
            'No slots match your filters right now.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: slots.length,
          itemBuilder: (_, i) => _buildSlotCard(slots[i], i),
        );
      },
    );
  }

  // ── Fighters Tab ──────────────────────────────────────────────────────────
  Widget _buildFightersTab() {
    return StreamBuilder<List<FighterModel>>(
      stream: _service.streamAvailableFighters(),
      builder: (context, snap) {
        final live = snap.data ?? [];
        final fighters = _applyFighterFilters(
          live.isNotEmpty ? live : _demoFighters,
        );

        if (fighters.isEmpty) {
          return _buildEmptyState(
            'No Fighters Available',
            'No fighters match your filters.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: fighters.length,
          itemBuilder: (_, i) => _buildFighterCard(fighters[i], i),
        );
      },
    );
  }

  // ── Slot Card ─────────────────────────────────────────────────────────────
  Widget _buildSlotCard(BoutSlotModel slot, int index) {
    final typeColor = _slotTypeColor(slot.slotType);
    final appFraction = (slot.applicationCount / 20.0).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 80),
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: typeColor.withValues(alpha: 0.40),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: typeColor.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot type banner
            Container(
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.60),
                      ),
                    ),
                    child: Text(
                      slot.slotType.label,
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    slot.promoterName,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  const _PulsingDot(color: AppTheme.neonGreen),
                  const SizedBox(width: 5),
                  const Text(
                    'OPEN',
                    style: TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event name + date
                  Text(
                    slot.eventName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(slot.eventDate),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.location_on,
                        size: 12,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${slot.venue} · ${slot.city}, ${slot.country}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tags + purse
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildBadge(slot.weightClass, AppTheme.accentTeal),
                      _buildBadge(slot.sportType, const Color(0xFF69FF47)),
                      if (slot.purse > 0)
                        _buildBadge(
                          '\$${_formatMoney(slot.purse)} purse',
                          const Color(0xFFFFD740),
                        ),
                    ],
                  ),
                  if (slot.targetCountries.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: slot.targetCountries
                          .map(
                            (c) =>
                                _buildBadge('🎯 $c', const Color(0xFFAB47BC)),
                          )
                          .toList(),
                    ),
                  ],
                  if (slot.notes != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      slot.notes!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Applications bar + button
                  Row(
                    children: [
                      const Icon(
                        Icons.group,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${slot.applicationCount} applications',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: appFraction),
                          duration: Duration(milliseconds: 800 + index * 100),
                          curve: Curves.easeOut,
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 4,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.accentTeal.withValues(alpha: 0.7),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/bout-offer',
                          extra: {'slot': slot, 'userId': widget.userId},
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send, size: 14),
                        label: const Text(
                          'APPLY',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
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

  // ── Fighter Card ──────────────────────────────────────────────────────────
  Widget _buildFighterCard(FighterModel fighter, int index) {
    final totalFights = fighter.totalFights;
    final winPct = fighter.winPercentage / 100;
    final koPct = fighter.wins > 0
        ? fighter.knockouts / fighter.wins.toDouble()
        : 0.0;
    final subPct = fighter.wins > 0
        ? fighter.submissions / fighter.wins.toDouble()
        : 0.0;
    final initials = fighter.fullName
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join();

    final gradientColor = _fighterGradientColor(index);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + index * 80),
      curve: Curves.easeOut,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: gradientColor.withValues(alpha: 0.30)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    gradientColor.withValues(alpha: 0.40),
                    gradientColor.withValues(alpha: 0.10),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: gradientColor.withValues(alpha: 0.50),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: gradientColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fighter.fullName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const _PulsingDot(color: AppTheme.neonGreen),
                      const SizedBox(width: 5),
                      const Text(
                        'AVAILABLE',
                        style: TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  if (fighter.nickname != null)
                    Text(
                      '"${fighter.nickname}"',
                      style: TextStyle(
                        color: gradientColor,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${fighter.weightClass ?? "—"} · ${fighter.sportType ?? "MMA"}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${fighter.city ?? ""}${fighter.country != null ? ", ${fighter.country}" : ""}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Pro record
                  Row(
                    children: [
                      _buildRecordBubble(
                        fighter.wins.toString(),
                        'W',
                        AppTheme.neonGreen,
                      ),
                      const SizedBox(width: 6),
                      _buildRecordBubble(
                        fighter.losses.toString(),
                        'L',
                        Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      _buildRecordBubble(
                        fighter.draws.toString(),
                        'D',
                        Colors.grey,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$totalFights pro fights',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stat bars
                  _buildAnimatedStatBar(
                    'WIN %',
                    winPct,
                    AppTheme.neonGreen,
                    '${fighter.winPercentage.toStringAsFixed(0)}%',
                    index,
                  ),
                  const SizedBox(height: 5),
                  _buildAnimatedStatBar(
                    'KO RATE',
                    koPct,
                    AppTheme.accentTeal,
                    '${(koPct * 100).toStringAsFixed(0)}%',
                    index,
                  ),
                  const SizedBox(height: 5),
                  _buildAnimatedStatBar(
                    'SUB RATE',
                    subPct,
                    const Color(0xFFAB47BC),
                    '${(subPct * 100).toStringAsFixed(0)}%',
                    index,
                  ),
                  const SizedBox(height: 10),
                  // Record pie mini chart + Offer button
                  Row(
                    children: [
                      if (totalFights > 0)
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: _buildRecordPieChart(fighter),
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Offer sent to ${fighter.fullName}',
                              ),
                              backgroundColor: AppTheme.cardDark,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gradientColor,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.send, size: 14),
                        label: const Text(
                          'SEND OFFER',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
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

  Widget _buildAnimatedStatBar(
    String label,
    double value,
    Color color,
    String valueStr,
    int index,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
            duration: Duration(milliseconds: 900 + index * 100),
            curve: Curves.easeOut,
            builder: (context, v, _) => Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 32,
          child: Text(
            valueStr,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordPieChart(FighterModel f) {
    final total = f.totalFights;
    if (total == 0) return const SizedBox.shrink();
    return PieChart(
      PieChartData(
        sectionsSpace: 1,
        centerSpaceRadius: 12,
        sections: [
          PieChartSectionData(
            value: f.wins.toDouble(),
            color: AppTheme.neonGreen,
            radius: 10,
            showTitle: false,
          ),
          PieChartSectionData(
            value: f.losses.toDouble(),
            color: Colors.redAccent,
            radius: 10,
            showTitle: false,
          ),
          if (f.draws > 0)
            PieChartSectionData(
              value: f.draws.toDouble(),
              color: Colors.grey,
              radius: 10,
              showTitle: false,
            ),
        ],
      ),
    );
  }

  Widget _buildRecordBubble(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _slotTypeColor(BoutSlotType type) {
    switch (type) {
      case BoutSlotType.mainEvent:
        return const Color(0xFFFFD740);
      case BoutSlotType.coMain:
        return const Color(0xFF00E5FF);
      case BoutSlotType.prelim:
        return const Color(0xFF69FF47);
      case BoutSlotType.amateur:
        return const Color(0xFFAB47BC);
    }
  }

  Color _fighterGradientColor(int index) {
    const colors = [
      Color(0xFF00E5FF),
      Color(0xFF69FF47),
      Color(0xFFFFD740),
      Color(0xFFAB47BC),
      Color(0xFFFF6B35),
    ];
    return colors[index % colors.length];
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}k';
    }
    return amount.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌐 Sonar Painter — rotating radar sweep
// ─────────────────────────────────────────────────────────────────────────────
class _SonarPainter extends CustomPainter {
  final double angle;
  _SonarPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const cyan = Color(0xFF00E5FF);

    // Background fill
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = cyan.withValues(alpha: 0.04),
    );

    // Concentric rings
    final ringPaint = Paint()
      ..color = cyan.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * i / 4, ringPaint);
    }

    // Crosshairs
    final xPaint = Paint()
      ..color = cyan.withValues(alpha: 0.10)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      xPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      xPaint,
    );
    canvas.drawLine(
      Offset(
        center.dx - radius * math.cos(math.pi / 4),
        center.dy - radius * math.sin(math.pi / 4),
      ),
      Offset(
        center.dx + radius * math.cos(math.pi / 4),
        center.dy + radius * math.sin(math.pi / 4),
      ),
      xPaint,
    );
    canvas.drawLine(
      Offset(
        center.dx - radius * math.cos(math.pi / 4),
        center.dy + radius * math.sin(math.pi / 4),
      ),
      Offset(
        center.dx + radius * math.cos(math.pi / 4),
        center.dy - radius * math.sin(math.pi / 4),
      ),
      xPaint,
    );

    // Outer border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = cyan.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Sweep arc (gradient fade)
    final sweepRect = Rect.fromCircle(center: center, radius: radius);
    const sweepSpan = 1.3;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - sweepSpan,
        endAngle: angle,
        colors: [Colors.transparent, cyan.withValues(alpha: 0.20)],
      ).createShader(sweepRect)
      ..style = PaintingStyle.fill;
    canvas.drawArc(sweepRect, angle - sweepSpan, sweepSpan, true, sweepPaint);

    // Leading edge line
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ),
      Paint()
        ..color = cyan.withValues(alpha: 0.85)
        ..strokeWidth = 1.5,
    );

    // Blip dots at random stable positions (seeded by angle bucket)
    _drawBlips(canvas, center, radius, cyan);

    // Center dot
    canvas.drawCircle(center, 3.5, Paint()..color = cyan);
    canvas.drawCircle(
      center,
      6,
      Paint()
        ..color = cyan.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _drawBlips(Canvas canvas, Offset center, double radius, Color cyan) {
    const blips = [
      (0.7, 0.45), // fraction of radius, angle fraction of 2pi
      (0.5, 0.72),
      (0.85, 0.18),
      (0.35, 0.90),
      (0.60, 0.60),
    ];
    for (final b in blips) {
      final r = b.$1 * radius;
      final a = b.$2 * 2 * math.pi;
      final blipPos = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );
      // Only show when sweep passes over
      final diff = (angle % (2 * math.pi)) - a;
      final visible = diff > 0 && diff < 0.6;
      if (visible) {
        final fade = 1.0 - diff / 0.6;
        canvas.drawCircle(
          blipPos,
          3,
          Paint()
            ..color = const Color(0xFF69FF47).withValues(alpha: 0.8 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SonarPainter old) => old.angle != angle;
}

// ─────────────────────────────────────────────────────────────────────────────
// 💚 Pulsing status dot
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.45 + 0.55 * _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.55 * _anim.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
