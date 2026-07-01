import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bout_slot_model.dart';
import '../../../shared/services/matchmaking_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 🥊 PROMOTER PORTAL — DFC Fight Card Command Centre
// Promoters manage their event cards, post open slots, review applications.
// ─────────────────────────────────────────────────────────────────────────────

class PromoterPortalScreen extends StatefulWidget {
  final String promoterId;
  final String promoterName;

  const PromoterPortalScreen({
    super.key,
    required this.promoterId,
    required this.promoterName,
  });

  @override
  State<PromoterPortalScreen> createState() => _PromoterPortalScreenState();
}

class _PromoterPortalScreenState extends State<PromoterPortalScreen>
    with TickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _entryCtrl;

  final _service = MatchmakingService();

  // New slot form state
  final _formKey = GlobalKey<FormState>();
  final _eventNameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _purseCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedWeightClass = 'Lightweight';
  String _selectedSport = 'MMA';
  BoutSlotType _selectedSlotType = BoutSlotType.mainEvent;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 90));
  bool _savingSlot = false;

  // Demo fight card data
  static final List<_FightCardSlot> _mySlots = [
    _FightCardSlot(
      id: 'slot_1',
      slotType: BoutSlotType.mainEvent,
      weightClass: 'Lightweight',
      sport: 'MMA',
      applicationCount: 7,
      status: BoutSlotStatus.open,
      eventName: 'DFC Road to Australia III',
      eventDate: DateTime(2026, 6, 15),
      purse: 15000,
    ),
    _FightCardSlot(
      id: 'slot_2',
      slotType: BoutSlotType.coMain,
      weightClass: 'Welterweight',
      sport: 'MMA',
      applicationCount: 3,
      status: BoutSlotStatus.negotiating,
      eventName: 'DFC Road to Australia III',
      eventDate: DateTime(2026, 6, 15),
      purse: 8000,
    ),
    _FightCardSlot(
      id: 'slot_3',
      slotType: BoutSlotType.prelim,
      weightClass: 'Featherweight',
      sport: 'MMA',
      applicationCount: 11,
      status: BoutSlotStatus.filled,
      eventName: 'DFC Road to Australia III',
      eventDate: DateTime(2026, 6, 15),
      purse: 3000,
    ),
    _FightCardSlot(
      id: 'slot_4',
      slotType: BoutSlotType.prelim,
      weightClass: 'Middleweight',
      sport: 'MMA',
      applicationCount: 5,
      status: BoutSlotStatus.open,
      eventName: 'DFC Road to Australia III',
      eventDate: DateTime(2026, 6, 15),
      purse: 3000,
    ),
    _FightCardSlot(
      id: 'slot_5',
      slotType: BoutSlotType.amateur,
      weightClass: 'Bantamweight',
      sport: 'MMA',
      applicationCount: 2,
      status: BoutSlotStatus.open,
      eventName: 'DFC Road to Australia III',
      eventDate: DateTime(2026, 6, 15),
      purse: 500,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pulseCtrl.dispose();
    _entryCtrl.dispose();
    _eventNameCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _purseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.neonPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.neonPink.withValues(alpha: 0.50),
                ),
              ),
              child: const Icon(
                Icons.business_center,
                size: 16,
                color: AppTheme.neonPink,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Promoter Portal',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  widget.promoterName,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, child) =>
                Opacity(opacity: 0.5 + 0.5 * _pulseCtrl.value, child: child),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.neonGreen.withValues(alpha: 0.40),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.neonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPromoterHeader(),
          _buildStatBar(),
          Container(
            color: AppTheme.cardDark,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppTheme.neonPink,
              labelColor: AppTheme.neonPink,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.view_list, size: 15), text: 'MY CARD'),
                Tab(icon: Icon(Icons.add_circle, size: 15), text: 'POST SLOT'),
                Tab(icon: Icon(Icons.bar_chart, size: 15), text: 'ANALYTICS'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildMyCardTab(),
                _buildPostSlotTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildPromoterHeader() {
    return Container(
      color: AppTheme.cardDark,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DFC ROAD TO AUSTRALIA III',
                  style: TextStyle(
                    color: AppTheme.neonPink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Melbourne Arena · 15 Jun 2026',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniChip('5 Slots', const Color(0xFF00E5FF)),
                    const SizedBox(width: 6),
                    _miniChip('28 Applications', const Color(0xFF69FF47)),
                    const SizedBox(width: 6),
                    _miniChip('96 days out', const Color(0xFFFFD740)),
                  ],
                ),
              ],
            ),
          ),
          // Mini fight card visual
          _buildMiniCardViz(),
        ],
      ),
    );
  }

  Widget _buildMiniCardViz() {
    const slotColors = [
      Color(0xFFFFD740),
      Color(0xFF00E5FF),
      Color(0xFF69FF47),
      Color(0xFF69FF47),
      Color(0xFFAB47BC),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final s = _mySlots[i];
        return Container(
          width: 90,
          height: 16,
          margin: const EdgeInsets.only(bottom: 3),
          decoration: BoxDecoration(
            color: slotColors[i].withValues(
              alpha: s.status == BoutSlotStatus.filled ? 0.25 : 0.10,
            ),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: slotColors[i].withValues(
                alpha: s.status == BoutSlotStatus.filled ? 0.70 : 0.30,
              ),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              s.slotType.label,
              style: TextStyle(
                color: slotColors[i],
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatBar() {
    final openCount = _mySlots
        .where((s) => s.status == BoutSlotStatus.open)
        .length;
    final filledCount = _mySlots
        .where((s) => s.status == BoutSlotStatus.filled)
        .length;
    final totalApps = _mySlots.fold<int>(
      0,
      (sum, s) => sum + s.applicationCount,
    );

    return Container(
      color: AppTheme.cardDark,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _statTile('Open', openCount.toString(), AppTheme.neonGreen),
          _divider(),
          _statTile(
            'Negotiating',
            _mySlots
                .where((s) => s.status == BoutSlotStatus.negotiating)
                .length
                .toString(),
            const Color(0xFFFFD740),
          ),
          _divider(),
          _statTile('Filled', filledCount.toString(), const Color(0xFFAB47BC)),
          _divider(),
          _statTile('Applications', totalApps.toString(), AppTheme.accentTeal),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 28,
    color: Colors.white.withValues(alpha: 0.08),
  );

  // ── My Card Tab ───────────────────────────────────────────────────────────
  Widget _buildMyCardTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _sectionLabel('FIGHT CARD SLOTS'),
        const SizedBox(height: 8),
        ..._mySlots.asMap().entries.map(
          (e) => _buildSlotManageCard(e.value, e.key),
        ),
        const SizedBox(height: 16),
        _sectionLabel('PPV REVENUE PROJECTION'),
        const SizedBox(height: 8),
        _buildRevenueProjection(),
      ],
    );
  }

  Widget _buildSlotManageCard(_FightCardSlot slot, int index) {
    final typeColor = _slotTypeColor(slot.slotType);
    final statusColor = _statusColor(slot.status);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 350 + index * 70),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: typeColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            // Slot type badge
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withValues(alpha: 0.50)),
              ),
              child: Column(
                children: [
                  Icon(Icons.sports_mma, color: typeColor, size: 18),
                  const SizedBox(height: 3),
                  Text(
                    slot.slotType.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: typeColor,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        slot.weightClass,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _miniChip(slot.sport, AppTheme.accentTeal),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 11,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${slot.applicationCount} applications',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${_fmtMoney(slot.purse.toDouble())}',
                        style: const TextStyle(
                          color: Color(0xFFFFD740),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Application progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (slot.applicationCount / 15.0).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(
                        typeColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.45)),
              ),
              child: Column(
                children: [
                  Text(
                    _statusLabel(slot.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (slot.applicationCount > 0 &&
                      slot.status == BoutSlotStatus.open)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: GestureDetector(
                        onTap: () => _showApplicationsSnackBar(slot),
                        child: const Text(
                          'REVIEW',
                          style: TextStyle(
                            color: AppTheme.accentTeal,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueProjection() {
    const scenarios = [
      _RevenueScenario(
        label: 'Bear',
        viewers: 8000,
        priceAUD: 12.99,
        color: Color(0xFFFF6B35),
      ),
      _RevenueScenario(
        label: 'Base',
        viewers: 25000,
        priceAUD: 12.99,
        color: Color(0xFF00E5FF),
      ),
      _RevenueScenario(
        label: 'Bull',
        viewers: 60000,
        priceAUD: 12.99,
        color: Color(0xFF69FF47),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD740).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.attach_money,
                color: Color(0xFFFFD740),
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'PPV Revenue Scenarios',
                style: TextStyle(
                  color: Color(0xFFFFD740),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.06),
                    strokeWidth: 0.8,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < scenarios.length) {
                          return Text(
                            scenarios[idx].label,
                            style: TextStyle(
                              color: scenarios[idx].color,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        '\$${(v / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    
                  ),
                  topTitles: const AxisTitles(
                    
                  ),
                ),
                barGroups: scenarios.asMap().entries.map((e) {
                  final gross = e.value.viewers * e.value.priceAUD;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: gross,
                        color: e.value.color,
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        rodStackItems: [
                          BarChartRodStackItem(0, gross * 0.72, e.value.color),
                          BarChartRodStackItem(
                            gross * 0.72,
                            gross,
                            e.value.color.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...scenarios.map((s) {
            final gross = s.viewers * s.priceAUD;
            final promoterCut = gross * 0.72;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.label,
                    style: TextStyle(
                      color: s.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_fmtInt(s.viewers)} buys → \$${_fmtMoney(gross)} gross',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Your cut: \$${_fmtMoney(promoterCut)}',
                    style: TextStyle(
                      color: s.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          const Text(
            '72% promoter / 28% DFC platform split',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Post Slot Tab ─────────────────────────────────────────────────────────
  Widget _buildPostSlotTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('POST A NEW SLOT'),
            const SizedBox(height: 14),
            _buildSlotTypeSelector(),
            const SizedBox(height: 16),
            _buildTextField(
              _eventNameCtrl,
              'Event Name',
              Icons.event,
              'e.g. DFC Road to Australia III',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _venueCtrl,
                    'Venue',
                    Icons.stadium,
                    'Arena name',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _cityCtrl,
                    'City',
                    Icons.location_city,
                    'City',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _countryCtrl,
                    'Country',
                    Icons.flag,
                    'Country',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField(
                    _purseCtrl,
                    'Purse (USD)',
                    Icons.attach_money,
                    '5000',
                    isNumber: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildWeightClassSelector(),
            const SizedBox(height: 12),
            _buildSportSelector(),
            const SizedBox(height: 12),
            _buildDatePicker(),
            const SizedBox(height: 12),
            _buildTextField(
              _notesCtrl,
              'Notes / Requirements (optional)',
              Icons.notes,
              'Fighter requirements, travel info...',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _savingSlot ? null : _postSlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: _savingSlot
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send, size: 18),
                label: Text(
                  _savingSlot ? 'Posting...' : 'POST SLOT TO DFC NETWORK',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotTypeSelector() {
    final types = [
      BoutSlotType.mainEvent,
      BoutSlotType.coMain,
      BoutSlotType.prelim,
      BoutSlotType.amateur,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SLOT TYPE',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((t) {
            final isSelected = _selectedSlotType == t;
            final c = _slotTypeColor(t);
            return GestureDetector(
              onTap: () => setState(() => _selectedSlotType = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? c.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? c
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: isSelected ? c : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        hintStyle: TextStyle(
          color: AppTheme.textSecondary.withValues(alpha: 0.5),
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, size: 16, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.neonPink),
        ),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildWeightClassSelector() {
    return _buildDropdown(
      'WEIGHT CLASS',
      _selectedWeightClass,
      AppConstants.mmaWeightClasses,
      (val) => setState(() => _selectedWeightClass = val!),
    );
  }

  Widget _buildSportSelector() {
    return _buildDropdown(
      'SPORT',
      _selectedSport,
      AppConstants.sportTypes,
      (val) => setState(() => _selectedSport = val!),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppTheme.cardBackground,
            underline: const SizedBox.shrink(),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            items: items
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EVENT DATE',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  '${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Analytics Tab ─────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    final totalApps = _mySlots.fold<int>(
      0,
      (s, slot) => s + slot.applicationCount,
    );
    final fillRate =
        _mySlots.where((s) => s.status == BoutSlotStatus.filled).length /
        _mySlots.length;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _buildAnalyticCard(
          'Total Applications',
          totalApps.toString(),
          Icons.people,
          AppTheme.accentTeal,
          '+24% vs last event',
          true,
        ),
        _buildAnalyticCard(
          'Card Fill Rate',
          '${(fillRate * 100).toStringAsFixed(0)}%',
          Icons.check_circle_outline,
          AppTheme.neonGreen,
          '${(_mySlots.where((s) => s.status != BoutSlotStatus.open).length)} of ${_mySlots.length} slots confirmed',
          false,
        ),
        _buildAnalyticCard(
          'Avg Purse Per Slot',
          '\$${_fmtMoney(_mySlots.fold<double>(0, (s, x) => s + x.purse) / _mySlots.length)}',
          Icons.attach_money,
          const Color(0xFFFFD740),
          'Across all slot tiers',
          false,
        ),
        _buildAnalyticCard(
          'Countries Reached',
          '14',
          Icons.public,
          const Color(0xFFAB47BC),
          'Via DFC global network',
          true,
        ),
        const SizedBox(height: 8),
        _buildApplicationBreakdownChart(),
      ],
    );
  }

  Widget _buildAnalyticCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    bool trending,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (trending)
            const Icon(Icons.trending_up, color: AppTheme.neonGreen, size: 20),
        ],
      ),
    );
  }

  Widget _buildApplicationBreakdownChart() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APPLICATIONS BY SLOT',
            style: TextStyle(
              color: AppTheme.accentTeal,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          ..._mySlots.map((s) {
            final c = _slotTypeColor(s.slotType);
            final fraction = (s.applicationCount / 15.0).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      s.slotType.label,
                      style: TextStyle(
                        color: c,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: fraction),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOut,
                      builder: (_, v, child) => Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 14,
                              decoration: BoxDecoration(
                                color: c.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.applicationCount.toString(),
                    style: TextStyle(
                      color: c,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _postSlot() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _savingSlot = true);

    final slot = BoutSlotModel(
      id: '',
      promoterId: widget.promoterId,
      promoterName: widget.promoterName,
      eventId: '',
      eventName: _eventNameCtrl.text.trim(),
      eventDate: _selectedDate,
      venue: _venueCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim(),
      weightClass: _selectedWeightClass,
      sportType: _selectedSport,
      slotType: _selectedSlotType,
      purse: double.tryParse(_purseCtrl.text.trim()) ?? 0,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await _service.createSlot(slot);
      if (mounted) {
        setState(() => _savingSlot = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Slot posted to DFC Network!'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
        _tabCtrl.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingSlot = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showApplicationsSnackBar(_FightCardSlot slot) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${slot.applicationCount} applications for ${slot.slotType.label} (${slot.weightClass})',
        ),
        backgroundColor: AppTheme.cardDark,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppTheme.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _miniChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
    ),
  );

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

  Color _statusColor(BoutSlotStatus status) {
    switch (status) {
      case BoutSlotStatus.open:
        return AppTheme.neonGreen;
      case BoutSlotStatus.negotiating:
        return const Color(0xFFFFD740);
      case BoutSlotStatus.filled:
        return const Color(0xFF00E5FF);
      case BoutSlotStatus.cancelled:
        return Colors.redAccent;
    }
  }

  String _statusLabel(BoutSlotStatus status) {
    switch (status) {
      case BoutSlotStatus.open:
        return 'OPEN';
      case BoutSlotStatus.negotiating:
        return 'NEGO';
      case BoutSlotStatus.filled:
        return 'FILLED';
      case BoutSlotStatus.cancelled:
        return 'CANCEL';
    }
  }

  String _fmtMoney(double v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
    }
    return v.toStringAsFixed(0);
  }

  String _fmtInt(int v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toString();
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────
class _FightCardSlot {
  final String id;
  final BoutSlotType slotType;
  final String weightClass;
  final String sport;
  final int applicationCount;
  final BoutSlotStatus status;
  final String eventName;
  final DateTime eventDate;
  final double purse;

  const _FightCardSlot({
    required this.id,
    required this.slotType,
    required this.weightClass,
    required this.sport,
    required this.applicationCount,
    required this.status,
    required this.eventName,
    required this.eventDate,
    required this.purse,
  });
}

class _RevenueScenario {
  final String label;
  final int viewers;
  final double priceAUD;
  final Color color;
  const _RevenueScenario({
    required this.label,
    required this.viewers,
    required this.priceAUD,
    required this.color,
  });
}
