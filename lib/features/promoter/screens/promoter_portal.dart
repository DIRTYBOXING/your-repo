import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/config/router_config.dart' as rc;
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/bout_slot_model.dart';
import '../services/promoter_readiness_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 🥊 PROMOTER PORTAL — Fight card management hub
// ─────────────────────────────────────────────────────────────────────────────

class PromoterPortal extends StatefulWidget {
  final String promoterId;
  final String promoterName;

  const PromoterPortal({
    super.key,
    required this.promoterId,
    required this.promoterName,
  });

  @override
  State<PromoterPortal> createState() => _PromoterPortalState();
}

class _PromoterPortalState extends State<PromoterPortal>
    with TickerProviderStateMixin {
  late final AnimationController _headerCtrl;
  late final AnimationController _statsCtrl;
  late final TabController _tabCtrl;
  final _readinessService = PromoterReadinessService();

  int _selectedEventIdx = 0;

  // ── Demo Revenue Data ─────────────────────────────────────────────────────
  static const _revenueMonths = [
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Jan',
    'Feb',
    'Mar',
  ];
  static const _revenueValues = [
    12000.0,
    18500.0,
    15200.0,
    31000.0,
    22400.0,
    28900.0,
    41200.0,
  ];

  static final _demoEvents = [
    _PromoterEvent(
      name: 'DFC Road to Australia III',
      date: DateTime(2026, 6, 15),
      venue: 'Melbourne Arena',
      city: 'Melbourne',
      country: 'Australia',
      totalSlots: 10,
      filledSlots: 7,
      pendingApplications: 14,
      color: const Color(0xFF00E5FF),
    ),
    _PromoterEvent(
      name: 'Pacific Rumble V',
      date: DateTime(2026, 7, 3),
      venue: 'Port Moresby Stadium',
      city: 'Port Moresby',
      country: 'Papua New Guinea',
      totalSlots: 8,
      filledSlots: 5,
      pendingApplications: 9,
      color: const Color(0xFF69FF47),
    ),
    _PromoterEvent(
      name: 'NZ Fight Series — Auckland',
      date: DateTime(2026, 5, 28),
      venue: 'Spark Arena',
      city: 'Auckland',
      country: 'New Zealand',
      totalSlots: 6,
      filledSlots: 6,
      pendingApplications: 0,
      color: const Color(0xFFFFD740),
    ),
  ];

  static final _demoApplications = [
    _Application(
      fighterName: 'Marcus "The Bull" Taufa',
      country: 'Australia',
      record: '12-2-0',
      weightClass: 'Lightweight',
      slotType: BoutSlotType.mainEvent,
      message: 'Looking for a main event fight. Ranked #3 in Oceania.',
      received: DateTime(2026, 3, 8),
    ),
    _Application(
      fighterName: 'Ezekiel "The Lion" Banda',
      country: 'Zambia',
      record: '9-1-0',
      weightClass: 'Welterweight',
      slotType: BoutSlotType.coMain,
      message: 'Willing to travel. African champion 2025.',
      received: DateTime(2026, 3, 9),
    ),
    _Application(
      fighterName: 'Yuki Tanaka',
      country: 'Japan',
      record: '21-5-0',
      weightClass: 'Bantamweight',
      slotType: BoutSlotType.prelim,
      message: 'Available June–August. 7 KO wins in last 10.',
      received: DateTime(2026, 3, 10),
    ),
    _Application(
      fighterName: 'Tama "Samoa Storm" Faleolo',
      country: 'Samoa',
      record: '15-3-2',
      weightClass: 'Middleweight',
      slotType: BoutSlotType.coMain,
      message: 'Pacific fan base of 80k. Brings exposure.',
      received: DateTime(2026, 3, 10),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _statsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _statsCtrl.dispose();
    _tabCtrl.dispose();
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
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.20),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF6B9D).withValues(alpha: 0.50),
                ),
              ),
              child: const Icon(
                Icons.business_center,
                color: Color(0xFFFF6B9D),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Promoter Portal',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppTheme.accentTeal,
            ),
            tooltip: 'Post New Slot',
            onPressed: () => context.push(
              '/open-slots',
              extra: {'userId': widget.promoterId, 'userRole': 'promoter'},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildReadinessBanner(),
          _buildStatsStrip(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildEventsTab(),
                _buildApplicationsTab(),
                _buildRevenueTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/open-slots',
          extra: {'userId': widget.promoterId, 'userRole': 'promoter'},
        ),
        backgroundColor: const Color(0xFFFF6B9D),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'POST SLOT',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (_, child) => Opacity(
        opacity: _headerCtrl.value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - _headerCtrl.value)),
          child: child,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        color: AppTheme.cardDark,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROMOTER CONTROL ROOM',
                    style: TextStyle(
                      color: Color(0xFFFF6B9D),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.promoterName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_demoEvents.length} active events · ${_demoApplications.length} pending applications',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Mini ring graphic
            CustomPaint(size: const Size(70, 70), painter: _RingPainter()),
          ],
        ),
      ),
    );
  }

  Widget _buildReadinessBanner() {
    return FutureBuilder<PromoterReadinessSnapshot>(
      future: _readinessService.getPromoterReadiness(
        promoterId: widget.promoterId,
      ),
      builder: (context, snapshot) {
        final readiness = snapshot.data;
        final ready = readiness?.onboardingReady == true;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ready
                  ? const Color(0xFF69FF47).withValues(alpha: 0.35)
                  : const Color(0xFFFFD740).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ready ? Icons.verified : Icons.pending_actions,
                    color: ready
                        ? const Color(0xFF69FF47)
                        : const Color(0xFFFFD740),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ready ? 'Commercial Ready' : 'Commercial Setup Required',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                readiness == null
                    ? 'Checking onboarding, Stripe, and rights status...'
                    : 'Stripe: ${readiness.stripeReady ? 'ready' : 'pending'} • Assets: ${readiness.profile.assetsCompleted}/4 • Rights intake: ${readiness.hasLicenseDraft ? 'started' : 'not started'}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              if (readiness != null && readiness.blockers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  readiness.blockers.first,
                  style: const TextStyle(
                    color: Color(0xFFFFD740),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => context.push(
                      '${rc.RouterConfig.promoterControlRoomPath}?promoterId=${Uri.encodeComponent(widget.promoterId)}&promoterName=${Uri.encodeComponent(widget.promoterName)}',
                    ),
                    child: const Text('Control Room'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(rc.RouterConfig.promoterOnboardingPath),
                    child: const Text('Onboarding'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        context.push(rc.RouterConfig.promoterRightsIntakePath),
                    child: const Text('Rights Intake'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(
                      rc.RouterConfig.promoterReconciliationPath,
                    ),
                    child: const Text('Settlement'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Stats Strip ───────────────────────────────────────────────────────────
  Widget _buildStatsStrip() {
    final stats = [
      _StatTile(
        'Events',
        _demoEvents.length.toString(),
        Icons.event,
        const Color(0xFF00E5FF),
      ),
      const _StatTile(
        'Open Slots',
        '7',
        Icons.event_available,
        Color(0xFF69FF47),
      ),
      _StatTile(
        'Applications',
        _demoApplications.length.toString(),
        Icons.inbox,
        const Color(0xFFFFD740),
      ),
      const _StatTile(
        'Revenue',
        '\$41.2k',
        Icons.attach_money,
        Color(0xFFFF6B9D),
      ),
    ];

    return Container(
      color: AppTheme.cardDark,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: stats.map((s) => Expanded(child: _buildStatTile(s))).toList(),
      ),
    );
  }

  Widget _buildStatTile(_StatTile s) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(opacity: v, child: child),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: s.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: s.color.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Icon(s.icon, color: s.color, size: 16),
            const SizedBox(height: 3),
            Text(
              s.value,
              style: TextStyle(
                color: s.color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              s.label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: AppTheme.cardDark,
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: const Color(0xFFFF6B9D),
        labelColor: const Color(0xFFFF6B9D),
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.event, size: 14), text: 'EVENTS'),
          Tab(icon: Icon(Icons.inbox, size: 14), text: 'APPLICATIONS'),
          Tab(icon: Icon(Icons.attach_money, size: 14), text: 'REVENUE'),
        ],
      ),
    );
  }

  // ── Events Tab ────────────────────────────────────────────────────────────
  Widget _buildEventsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _demoEvents.length,
      itemBuilder: (_, i) => _buildEventCard(_demoEvents[i], i),
    );
  }

  Widget _buildEventCard(_PromoterEvent event, int index) {
    final filledFraction = event.filledSlots / event.totalSlots;
    final daysToEvent = event.date.difference(DateTime.now()).inDays;
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

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - v)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _selectedEventIdx = index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (_selectedEventIdx == index)
                  ? event.color
                  : event.color.withValues(alpha: 0.25),
              width: _selectedEventIdx == index ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: 0.10),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: event.color, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (daysToEvent < 30
                                    ? Colors.redAccent
                                    : AppTheme.accentTeal)
                                .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$daysToEvent days',
                        style: TextStyle(
                          color: daysToEvent < 30
                              ? Colors.redAccent
                              : AppTheme.accentTeal,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.date.day} ${months[event.date.month - 1]} ${event.date.year}',
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
                            '${event.venue} · ${event.city}, ${event.country}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Card filled: ',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${event.filledSlots}/${event.totalSlots}',
                          style: TextStyle(
                            color: event.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: filledFraction),
                      duration: Duration(milliseconds: 900 + index * 100),
                      curve: Curves.easeOut,
                      builder: (_, v, child) => Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: event.color.withValues(alpha: 0.70),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: event.color.withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (event.pendingApplications > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFFD740,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(
                                  0xFFFFD740,
                                ).withValues(alpha: 0.40),
                              ),
                            ),
                            child: Text(
                              '${event.pendingApplications} applications waiting',
                              style: const TextStyle(
                                color: Color(0xFFFFD740),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Applications Tab ──────────────────────────────────────────────────────
  Widget _buildApplicationsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _demoApplications.length,
      itemBuilder: (_, i) => _buildApplicationCard(_demoApplications[i], i),
    );
  }

  Widget _buildApplicationCard(_Application app, int index) {
    final typeColor = _slotTypeColor(app.slotType);
    final initials = app.fighterName
        .split(' ')
        .take(2)
        .map(
          (w) =>
              w.replaceAll('"', '').isNotEmpty ? w.replaceAll('"', '')[0] : '',
        )
        .join();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 450 + index * 80),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: typeColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: typeColor.withValues(alpha: 0.40)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: typeColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          app.fighterName,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          app.slotType.label,
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        app.record,
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${app.weightClass} · ${app.country}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    app.message,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _actionBtn('APPROVE', AppTheme.neonGreen, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${app.fighterName} approved!'),
                            backgroundColor: AppTheme.cardDark,
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      _actionBtn('DECLINE', Colors.redAccent, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${app.fighterName} declined.'),
                            backgroundColor: AppTheme.cardDark,
                          ),
                        );
                      }),
                      const Spacer(),
                      Text(
                        _timeAgo(app.received),
                        style: TextStyle(
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                          fontSize: 10,
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

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.40)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Revenue Tab ───────────────────────────────────────────────────────────
  Widget _buildRevenueTab() {
    final maxRevenue = _revenueValues.reduce(math.max);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFF6B9D).withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.trending_up, color: Color(0xFFFF6B9D), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Revenue Dashboard',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Last 7 months',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOut,
                  builder: (_, v, child) => Text(
                    '\$${(_revenueValues.last * v / 1000).toStringAsFixed(1)}k this month',
                    style: const TextStyle(
                      color: Color(0xFFFF6B9D),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '+42% month on month',
                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Bar chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Revenue (AUD)',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      backgroundColor: Colors.transparent,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: Colors.white.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          
                        ),
                        rightTitles: const AxisTitles(
                          
                        ),
                        topTitles: const AxisTitles(
                          
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= _revenueMonths.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                _revenueMonths[idx],
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        _revenueValues.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: _revenueValues[i],
                              width: 18,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  const Color(
                                    0xFFFF6B9D,
                                  ).withValues(alpha: 0.4),
                                  const Color(0xFFFF6B9D),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      maxY: maxRevenue * 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Revenue by source
          _buildRevenueSourceCard('Gate Tickets', 42, const Color(0xFF00E5FF)),
          const SizedBox(height: 8),
          _buildRevenueSourceCard('PPV Sales', 35, const Color(0xFF69FF47)),
          const SizedBox(height: 8),
          _buildRevenueSourceCard(
            'Merch + Sponsorship',
            15,
            const Color(0xFFFFD740),
          ),
          const SizedBox(height: 8),
          _buildRevenueSourceCard('Replay / VOD', 8, const Color(0xFFAB47BC)),
        ],
      ),
    );
  }

  Widget _buildRevenueSourceCard(String label, int pct, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: pct / 100.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOut,
            builder: (_, v, child) => SizedBox(
              width: 120,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}

// ── Ring Painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const pink = Color(0xFFFF6B9D);

    // Outer ring
    canvas.drawCircle(
      center,
      size.width / 2 - 2,
      Paint()
        ..color = pink.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner ropes
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        (size.width / 2 - 2) * i / 3,
        Paint()
          ..color = pink.withValues(alpha: 0.08 * i)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    // Corner posts
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final r = size.width / 2 - 2;
      canvas.drawCircle(
        Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ),
        4,
        Paint()..color = pink.withValues(alpha: 0.60),
      );
    }

    // Centre icon
    canvas.drawCircle(
      center,
      10,
      Paint()..color = pink.withValues(alpha: 0.15),
    );
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = pink.withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

// ── Data Classes ──────────────────────────────────────────────────────────────
class _PromoterEvent {
  final String name;
  final DateTime date;
  final String venue;
  final String city;
  final String country;
  final int totalSlots;
  final int filledSlots;
  final int pendingApplications;
  final Color color;

  const _PromoterEvent({
    required this.name,
    required this.date,
    required this.venue,
    required this.city,
    required this.country,
    required this.totalSlots,
    required this.filledSlots,
    required this.pendingApplications,
    required this.color,
  });
}

class _Application {
  final String fighterName;
  final String country;
  final String record;
  final String weightClass;
  final BoutSlotType slotType;
  final String message;
  final DateTime received;

  const _Application({
    required this.fighterName,
    required this.country,
    required this.record,
    required this.weightClass,
    required this.slotType,
    required this.message,
    required this.received,
  });
}

class _StatTile {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile(this.label, this.value, this.icon, this.color);
}
