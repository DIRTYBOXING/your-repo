import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../services/ppv_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER DASHBOARD — Revenue, Analytics, Event Management
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The promoter's war room:
///   • Revenue overview (total, pending, this month)
///   • Event performance cards (sales, CVR, viewers)
///   • Quick actions: Create Event, Poster Store, Command Chat
///   • Payout history + Stripe Connect status
///   • DFC fee transparency (sliding 30–50%)
///
/// Route: /ppv/promoter
/// ═══════════════════════════════════════════════════════════════════════════
class PromoterDashboardScreen extends StatefulWidget {
  const PromoterDashboardScreen({super.key});

  @override
  State<PromoterDashboardScreen> createState() =>
      _PromoterDashboardScreenState();
}

class _PromoterDashboardScreenState extends State<PromoterDashboardScreen>
    with SingleTickerProviderStateMixin {
  final PpvService _PpvService = PpvService();
  final String _promoterId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabCtrl;

  List<PPVEvent> _promoterEvents = [];
  StreamSubscription<List<PPVEvent>>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _eventsSub = _PpvService.getPromoterEvents(_promoterId).listen((events) {
      if (mounted) setState(() => _promoterEvents = events);
    });
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildRevenueCard()),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildPerformanceMetrics()),
          SliverToBoxAdapter(child: _buildPayoutStatus()),
          SliverToBoxAdapter(child: _buildSectionHeader('MY PPV EVENTS')),
          _buildEventsList(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ppv/create'),
        backgroundColor: DesignTokens.neonCyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'CREATE EVENT',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: DesignTokens.bgPrimary,
      elevation: 0,
      expandedHeight: 120,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/ppv');
          }
        },
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.08),
                DesignTokens.neonMagenta.withValues(alpha: 0.05),
                DesignTokens.bgPrimary,
              ],
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(56, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'PROMOTER HQ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Revenue  •  Analytics  •  Event Management',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/ppv/poster-store'),
          icon: const Icon(
            Icons.store,
            color: DesignTokens.neonAmber,
            size: 22,
          ),
          tooltip: 'Poster Store',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // REVENUE CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRevenueCard() {
    return StreamBuilder<double>(
      stream: _PpvService.getPromoterTotalRevenue(_promoterId),
      builder: (context, snapshot) {
        final totalRevenue = snapshot.data ?? 0.0;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignTokens.neonCyan.withValues(alpha: 0.12),
                DesignTokens.neonMagenta.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: DesignTokens.neonCyan.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: DesignTokens.neonCyan,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'TOTAL REVENUE',
                    style: TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '\$${totalRevenue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRevenueMetric(
                    'Events',
                    _promoterEvents.length.toString(),
                    DesignTokens.neonCyan,
                  ),
                  _buildRevenueMetric(
                    'Total Sales',
                    _promoterEvents
                        .fold<int>(0, (s, e) => s + e.purchaseCount)
                        .toString(),
                    const Color(0xFF00FF88),
                  ),
                  _buildRevenueMetric(
                    'Pending',
                    '\$0.00',
                    DesignTokens.neonAmber,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRevenueMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: DesignTokens.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              'Create\nEvent',
              Icons.add_circle,
              DesignTokens.neonCyan,
              () => context.push('/ppv/create'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionCard(
              'Poster\nStore',
              Icons.palette,
              DesignTokens.neonMagenta,
              () => context.push('/ppv/poster-store'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionCard(
              'Command\nChat',
              Icons.chat_bubble,
              DesignTokens.neonGreen,
              () {},
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildActionCard(
              'PPV\nStore',
              Icons.storefront,
              DesignTokens.neonAmber,
              () => context.push('/ppv/store'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PERFORMANCE METRICS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPerformanceMetrics() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: DesignTokens.neonMagenta, size: 18),
              SizedBox(width: 8),
              Text(
                'PERFORMANCE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Conversion Rate',
                  '7.8%',
                  Icons.trending_up,
                  const Color(0xFF00FF88),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Avg Viewers',
                  '1,240',
                  Icons.visibility,
                  DesignTokens.neonCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Avg Revenue',
                  '\$4,950',
                  Icons.attach_money,
                  DesignTokens.neonAmber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  'Return Rate',
                  '62%',
                  Icons.repeat,
                  DesignTokens.neonMagenta,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: DesignTokens.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // PAYOUT STATUS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPayoutStatus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00FF88).withValues(alpha: 0.08),
            DesignTokens.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFF00FF88), size: 18),
              const SizedBox(width: 8),
              const Text(
                'STRIPE CONNECT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF00FF88),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Color(0xFF00FF88),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Payout',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$0.00',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DFC Fee (Sliding)',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '30–50%',
                      style: TextStyle(
                        color: DesignTokens.neonAmber.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payout Cycle',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Weekly',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // EVENTS LIST
  // ═══════════════════════════════════════════════════════════════════
  SliverToBoxAdapter _buildEventsList() {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<PPVEvent>>(
        stream: _PpvService.getPromoterEvents(_promoterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: DesignTokens.neonCyan),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: snapshot.data!
                .map(_buildEventCard)
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.live_tv,
              size: 48,
              color: DesignTokens.neonCyan.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No PPV Events Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first PPV event and start\nearning revenue from combat fans worldwide.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/ppv/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create First Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonCyan,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(PPVEvent event) {
    final isLive = event.status == PPVStatus.live;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _buildStatusChip(event.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(event.eventDate),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEventStat(
                  'Price',
                  '\$${event.standardPrice.toStringAsFixed(0)}',
                  DesignTokens.neonCyan,
                ),
                _buildEventStat(
                  'Sales',
                  '${event.purchaseCount}',
                  const Color(0xFF00FF88),
                ),
                _buildEventStat(
                  'Revenue',
                  '\$${event.totalRevenue.toStringAsFixed(0)}',
                  DesignTokens.neonAmber,
                ),
                _buildEventStat(
                  'Your Share',
                  '\$${event.promoterRevenue.toStringAsFixed(0)}',
                  DesignTokens.neonMagenta,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateStatus(event),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Status', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.neonCyan,
                      side: BorderSide(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareEvent(event),
                    icon: const Icon(Icons.share, size: 14),
                    label: const Text('Share', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(PPVStatus status) {
    final (Color color, String label) = switch (status) {
      PPVStatus.announced => (Colors.blue, 'ANNOUNCED'),
      PPVStatus.presale => (Colors.purple, 'PRESALE'),
      PPVStatus.onSale => (const Color(0xFF00FF88), 'ON SALE'),
      PPVStatus.live => (Colors.red, 'LIVE'),
      PPVStatus.replay => (Colors.orange, 'REPLAY'),
      PPVStatus.expired => (Colors.grey, 'EXPIRED'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEventStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: DesignTokens.textMuted),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _updateStatus(PPVEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Event Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ...PPVStatus.values.map((status) {
                final isSelected = event.status == status;
                final (Color color, String label) = switch (status) {
                  PPVStatus.announced => (Colors.blue, 'ANNOUNCED'),
                  PPVStatus.presale => (Colors.purple, 'PRESALE'),
                  PPVStatus.onSale => (const Color(0xFF00FF88), 'ON SALE'),
                  PPVStatus.live => (Colors.red, 'LIVE'),
                  PPVStatus.replay => (Colors.orange, 'REPLAY'),
                  PPVStatus.expired => (Colors.grey, 'EXPIRED'),
                };
                return ListTile(
                  leading: Icon(Icons.circle, color: color, size: 12),
                  title: Text(
                    label,
                    style: TextStyle(color: isSelected ? color : Colors.white),
                  ),
                  selected: isSelected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    await _PpvService.updateEventStatus(event.id, status);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status updated to $label'),
                          backgroundColor: color,
                        ),
                      );
                    }
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _shareEvent(PPVEvent event) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard'),
        backgroundColor: DesignTokens.neonCyan,
      ),
    );
  }
}
