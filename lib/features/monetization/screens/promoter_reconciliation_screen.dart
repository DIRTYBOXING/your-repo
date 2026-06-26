import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/promoter_settlement_snapshot_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PROMOTER RECONCILIATION DASHBOARD
///
/// Read-only dashboard that proves the math to promoters.
/// Shows live buys, current split, reserve, transaction ledger,
/// split projection slider, payout history, and CSV export.
///
/// Spec: promoter sees Gross → Stripe Fees → Net → DFC% → DFC Cut →
///        Promoter Cut → Reserve → Payable Promoter → Payout Date
/// ═══════════════════════════════════════════════════════════════════════════
class PromoterReconciliationScreen extends StatefulWidget {
  final String? eventId;

  const PromoterReconciliationScreen({super.key, this.eventId});

  @override
  State<PromoterReconciliationScreen> createState() =>
      _PromoterReconciliationScreenState();
}

class _PromoterReconciliationScreenState
    extends State<PromoterReconciliationScreen> {
  final PromoterSettlementSnapshotService _settlementService =
      PromoterSettlementSnapshotService();

  String _eventName = 'DFC Fight Night 12';
  String _venue = 'Melbourne Convention Centre';
  String _ppvPrice = r'$20.00';
  DateTime _eventDate = DateTime(2026, 4, 12);
  String _promoterName = 'Ironside Promotions';
  double _ppvPriceValue = 20;
  bool _isLoading = false;
  bool _usingLiveData = false;
  PromoterSettlementSnapshot? _snapshot;
  int _refundedPurchases = 0;
  double _revenueShareDelta = 0;
  String _payoutStatusLabel = 'Awaiting Sync';
  DateTime? _lastPurchaseAt;
  DateTime? _lastPayoutAt;

  int _totalBuys = 3247;
  double _projectionSlider = 0;

  // Simulated transactions for the ledger
  late List<_LedgerRow> _ledger;

  @override
  void initState() {
    super.initState();
    _ledger = _generateDemoLedger();
    _loadLiveData();
  }

  // ── PPV split formula (mirrors ppv.js) ───────────────────────────────
  double _dfcPct(int buys) {
    if (buys <= 0) return 0.30;
    if (buys >= 10000) return 0.50;
    return 0.30 + (min(buys, 10000) / 10000) * 0.20;
  }

  double _stripeFees(int buys, double price) => buys * (price * 0.029 + 0.30);

  Future<void> _loadLiveData() async {
    final eventId = widget.eventId;
    if (eventId == null || eventId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _settlementService.getSnapshot(eventId: eventId);
      final liveLedger = snapshot.ledger
          .map(
            (row) => _LedgerRow(
              txNum: row.txNum,
              time: DateFormat('HH:mm').format(row.time),
              net: row.net,
              dfcPct: row.dfcPct,
              promoterCut: row.promoterCut,
              isRefund: row.isRefund,
            ),
          )
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _eventName = snapshot.eventName;
        _venue = snapshot.venue;
        _promoterName = snapshot.promoterName;
        _eventDate = snapshot.eventDate;
        _ppvPriceValue = snapshot.ppvPriceValue > 0
            ? snapshot.ppvPriceValue
            : 20.0;
        _ppvPrice = _fmt(_ppvPriceValue);
        _totalBuys = snapshot.totalPurchases;
        _refundedPurchases = snapshot.refundedPurchases;
        _revenueShareDelta = snapshot.revenueShareDelta;
        _payoutStatusLabel = snapshot.payoutStatusLabel;
        _lastPurchaseAt = snapshot.lastPurchaseAt;
        _lastPayoutAt = snapshot.lastPayoutAt;
        _ledger = liveLedger.isNotEmpty ? liveLedger : _ledger;
        _usingLiveData = snapshot.usingLiveData;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ── Computed getters ─────────────────────────────────────────────────
  double get _gross => _snapshot?.grossSales ?? (_totalBuys * _ppvPriceValue);
  double get _stripeTotal =>
      _snapshot?.stripeFees ?? _stripeFees(_totalBuys, _ppvPriceValue);
  double get _net => _snapshot?.netRevenue ?? max(0, _gross - _stripeTotal);
  double get _currentDfcPct => _snapshot?.dfcPct ?? _dfcPct(_totalBuys);
  double get _dfcCut => _snapshot?.dfcCut ?? (_net * _currentDfcPct);
  double get _promoterCut => _snapshot?.promoterCut ?? (_net - _dfcCut);
  double get _reserve => _snapshot?.reserveAmount ?? (_net * 0.02);
  double get _payablePromoter =>
      _snapshot?.payableNow ?? max(0, _promoterCut - _reserve);

  // Projection
  int get _projectedBuys => _totalBuys + _projectionSlider.toInt();
  double get _projectedGross => _projectedBuys * _ppvPriceValue;
  double get _projectedStripe => _stripeFees(_projectedBuys, _ppvPriceValue);
  double get _projectedNet => max(0, _projectedGross - _projectedStripe);
  double get _projectedDfcPct => _dfcPct(_projectedBuys);
  double get _projectedPromoterCut => _projectedNet * (1 - _projectedDfcPct);

  String _fmt(double v) => NumberFormat.currency(symbol: r'$').format(v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildEventHeader()),
            SliverToBoxAdapter(child: _buildSettlementIntegrity()),
            SliverToBoxAdapter(child: _buildLiveSummary()),
            SliverToBoxAdapter(child: _buildThresholdProgress()),
            SliverToBoxAdapter(child: _buildProjectionSlider()),
            SliverToBoxAdapter(child: _buildSectionTitle('Transaction Ledger')),
            SliverToBoxAdapter(child: _buildLedgerTable()),
            SliverToBoxAdapter(child: _buildSectionTitle('Payout Schedule')),
            SliverToBoxAdapter(child: _buildPayoutSchedule()),
            SliverToBoxAdapter(child: _buildExportButtons()),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: DesignTokens.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: const Text(
        'Reconciliation',
        style: TextStyle(
          color: DesignTokens.neonCyan,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white54),
          onPressed: _loadLiveData,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EVENT HEADER
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildEventHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.neonCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'RECONCILIATION',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isLoading ? 'SYNCING' : (_usingLiveData ? 'LIVE' : 'DEMO'),
                  style: TextStyle(
                    color: _isLoading
                        ? DesignTokens.neonAmber
                        : (_usingLiveData ? Colors.green : Colors.white70),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _eventName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_venue  •  ${DateFormat('d MMM yyyy').format(_eventDate)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Promoter: $_promoterName  •  PPV Price: $_ppvPrice',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementIntegrity() {
    final snapshot = _snapshot;
    final refundedAmount = snapshot?.refundedAmount ?? 0;
    final activeDisputeCount = snapshot?.activeDisputeCount ?? 0;
    final activeDisputeAmount = snapshot?.activeDisputeAmount ?? 0;
    final cards = [
      _IntegrityMetric(
        'Confidence',
        snapshot?.confidenceLabel ?? (_usingLiveData ? 'LIVE' : 'DEMO'),
        snapshot?.needsReview == true
            ? DesignTokens.neonAmber
            : DesignTokens.neonCyan,
        snapshot?.confidenceDetail ?? 'Settlement proof is loading.',
      ),
      _IntegrityMetric(
        'Verified Buys',
        NumberFormat('#,###').format(_totalBuys),
        Colors.white,
        _refundedPurchases > 0
            ? '$_refundedPurchases refund${_refundedPurchases == 1 ? '' : 's'} tracked in ledger'
            : 'No refunds currently detected',
      ),
      _IntegrityMetric(
        'Share Sync',
        snapshot?.hasRevenueShare == true ? 'SYNCED' : 'PENDING',
        snapshot?.hasRevenueShare == true
            ? Colors.green
            : DesignTokens.neonAmber,
        snapshot?.hasRevenueShare == true
            ? 'Ledger delta ${_fmt(_revenueShareDelta.abs())}'
            : 'Revenue share record not found yet',
      ),
      _IntegrityMetric(
        'Settlement Source',
        snapshot?.hasBackendSettlement == true ? 'ATLAS' : 'MISSING',
        snapshot?.hasBackendSettlement == true
            ? DesignTokens.neonGold
            : DesignTokens.neonAmber,
        snapshot?.hasBackendSettlement == true
            ? 'Backend delta ${_fmt(snapshot!.backendDelta.abs())}'
            : 'Authoritative settlement snapshot not generated yet',
      ),
      _IntegrityMetric(
        'Customer Risk',
        activeDisputeCount > 0
            ? '$activeDisputeCount REVIEW'
            : (refundedAmount > 0 ? _fmt(refundedAmount) : 'CLEAR'),
        activeDisputeCount > 0
            ? DesignTokens.neonAmber
            : (refundedAmount > 0 ? Colors.redAccent : Colors.green),
        activeDisputeCount > 0
            ? '${_fmt(activeDisputeAmount)} is currently disputed or awaiting Stripe resolution'
            : (refundedAmount > 0
                  ? 'Refund activity totals ${_fmt(refundedAmount)} across the live ledger'
                  : 'No refund or dispute pressure is currently recorded'),
      ),
      _IntegrityMetric(
        'Payout Lane',
        snapshot?.hasPayoutFailure == true
            ? 'FAILED'
            : _payoutStatusLabel.toUpperCase(),
        snapshot?.hasPayoutFailure == true
            ? Colors.redAccent
            : (snapshot?.hasRevenueShare == true
                  ? Colors.green
                  : DesignTokens.neonAmber),
        snapshot?.hasPayoutFailure == true
            ? 'The latest payout state needs operator intervention before release'
            : (_lastPayoutAt == null
                  ? 'Reserve hold and payout status are being tracked for this event'
                  : 'Last payout touch ${DateFormat('d MMM').format(_lastPayoutAt!)}'),
      ),
      _IntegrityMetric(
        'Last Money Movement',
        _lastPurchaseAt == null
            ? 'NONE'
            : DateFormat('d MMM HH:mm').format(_lastPurchaseAt!),
        DesignTokens.neonGold,
        _lastPayoutAt == null
            ? 'Payout status: $_payoutStatusLabel'
            : 'Last payout touch ${DateFormat('d MMM').format(_lastPayoutAt!)}',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                (snapshot?.needsReview == true
                        ? DesignTokens.neonAmber
                        : DesignTokens.neonCyan)
                    .withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: DesignTokens.neonCyan,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Settlement Proof',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  _payoutStatusLabel,
                  style: TextStyle(
                    color: snapshot?.needsReview == true
                        ? DesignTokens.neonAmber
                        : Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              snapshot?.confidenceDetail ??
                  'This board locks purchases, revenue share sync, and payout status into one view.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.58),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cards.map((card) {
                final cardWidth = (MediaQuery.of(context).size.width - 40) / 2;
                return Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: card.color.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.label,
                        style: TextStyle(
                          color: card.color.withValues(alpha: 0.72),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.value,
                        style: TextStyle(
                          color: card.color,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.caption,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.44),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LIVE SUMMARY — top row of key metrics
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLiveSummary() {
    final metrics = [
      _Metric(
        _snapshot?.hasBackendSettlement == true
            ? 'Gross Sales (Atlas)'
            : 'Gross Sales',
        _fmt(_gross),
        DesignTokens.neonCyan,
      ),
      _Metric(
        _snapshot?.hasBackendSettlement == true
            ? 'Stripe Fees (Atlas)'
            : 'Stripe Fees',
        _fmt(_stripeTotal),
        Colors.red,
      ),
      _Metric('Net Revenue', _fmt(_net), DesignTokens.neonGold),
      _Metric(
        'DFC ${(_currentDfcPct * 100).toStringAsFixed(1)}%',
        _fmt(_dfcCut),
        DesignTokens.neonMagenta,
      ),
      _Metric('Promoter Cut', _fmt(_promoterCut), Colors.green),
      _Metric('Reserve (2%)', _fmt(_reserve), DesignTokens.neonAmber),
      _Metric('Payable Now', _fmt(_payablePromoter), Colors.white),
      _Metric(
        'Payout Date',
        DateFormat('d MMM').format(_eventDate.add(const Duration(days: 14))),
        Colors.white70,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metrics.map((m) {
          final cardWidth = (MediaQuery.of(context).size.width - 40) / 2;
          return Container(
            width: cardWidth,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: m.color.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.label,
                  style: TextStyle(
                    color: m.color.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  m.value,
                  style: TextStyle(
                    color: m.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // THRESHOLD PROGRESS — visual 0→10k with markers at 1k, 5k, 10k
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildThresholdProgress() {
    final progress = min(_totalBuys / 10000, 1.0);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'DFC% Progression',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${NumberFormat('#,###').format(_totalBuys)} buys → ${(_currentDfcPct * 100).toStringAsFixed(1)}% DFC',
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Background
                  Container(color: Colors.white.withValues(alpha: 0.06)),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            DesignTokens.neonCyan,
                            DesignTokens.neonMagenta,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Threshold markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _thresholdLabel('0', '30%'),
              _thresholdLabel('1K', '32%'),
              _thresholdLabel('5K', '40%'),
              _thresholdLabel('10K', '50%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thresholdLabel(String buys, String pct) {
    return Column(
      children: [
        Text(
          buys,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          pct,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROJECTION SLIDER — "what if we sell N more?"
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildProjectionSlider() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignTokens.neonGold.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: DesignTokens.neonGold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Split Projection',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '+${NumberFormat('#,###').format(_projectionSlider.toInt())} buys',
                style: const TextStyle(
                  color: DesignTokens.neonGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: DesignTokens.neonGold,
              inactiveTrackColor: DesignTokens.neonGold.withValues(alpha: 0.15),
              thumbColor: DesignTokens.neonGold,
              overlayColor: DesignTokens.neonGold.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _projectionSlider,
              max: 10000,
              divisions: 100,
              onChanged: (v) => setState(() => _projectionSlider = v),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _projectionStat(
                'Projected Buys',
                NumberFormat('#,###').format(_projectedBuys),
              ),
              _projectionStat(
                'DFC%',
                '${(_projectedDfcPct * 100).toStringAsFixed(1)}%',
              ),
              _projectionStat('Promoter Gets', _fmt(_projectedPromoterCut)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _projectionStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TRANSACTION LEDGER (paginated-style table)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLedgerTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                _colHeader('TX'),
                _colHeader('Time', flex: 2),
                _colHeader('Net', flex: 2),
                _colHeader('DFC%'),
                _colHeader('Promo', flex: 2),
              ],
            ),
          ),
          // Rows
          ..._ledger
              .take(15)
              .map(
                (row) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _colCell(
                        '#${row.txNum}',
                        color: row.isRefund ? Colors.red : null,
                      ),
                      _colCell(row.time, flex: 2),
                      _colCell(
                        row.isRefund ? '-${_fmt(row.net)}' : _fmt(row.net),
                        flex: 2,
                        color: row.isRefund ? Colors.red : null,
                      ),
                      _colCell(
                        '${(row.dfcPct * 100).toStringAsFixed(1)}%',
                      ),
                      _colCell(
                        _fmt(row.promoterCut),
                        flex: 2,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Showing 15 of ${_ledger.length} transactions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colHeader(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _colCell(String text, {int flex = 1, Color? color}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? Colors.white.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAYOUT SCHEDULE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildPayoutSchedule() {
    final payoutDate = (_snapshot?.eventStartTime ?? _eventDate).add(
      const Duration(days: 14),
    );
    final reserveRelease =
        _snapshot?.reserveReleaseAt ?? _eventDate.add(const Duration(days: 28));
    final df = DateFormat('d MMM yyyy');
    final mainPayoutColor = _snapshot?.hasPayoutFailure == true
        ? Colors.redAccent
        : (_payoutStatusLabel == 'Processing'
              ? DesignTokens.neonGold
              : (_payoutStatusLabel == 'Requested'
                    ? DesignTokens.neonCyan
                    : Colors.green));

    final payouts = [
      (
        label: 'Main Payout',
        amount: _fmt(_payablePromoter),
        date: df.format(payoutDate),
        status: _payoutStatusLabel,
        color: mainPayoutColor,
      ),
      (
        label: 'Reserve Release',
        amount: _fmt(_reserve),
        date: df.format(reserveRelease),
        status: _snapshot?.reserveReleaseState == 'released'
            ? 'Released'
            : _snapshot?.reserveReleaseState == 'blocked'
            ? 'Blocked until payout lane is corrected'
            : _snapshot?.hasPayoutFailure == true
            ? 'Blocked until payout lane is corrected'
            : (_usingLiveData ? 'Pending (14d hold)' : 'Projected hold window'),
        color: DesignTokens.neonAmber,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: payouts.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DesignTokens.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.color.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet, color: p.color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${p.date} • ${p.status}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  p.amount,
                  style: TextStyle(
                    color: p.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXPORT BUTTONS — CSV + Audit Bundle
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildExportButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          _exportButton(
            icon: Icons.download,
            label: 'Export Reconciliation CSV',
            sublabel:
                'tx_id, ts, price, stripe_fee, net, dfc_pct, dfc_cut, promoter_cut, reserve',
            color: DesignTokens.neonCyan,
            onTap: _copyReconciliationCsv,
          ),
          const SizedBox(height: 8),
          _exportButton(
            icon: Icons.description,
            label: 'Copy Payout Summary',
            sublabel: 'Copy full reconciliation summary to clipboard',
            color: DesignTokens.neonGold,
            onTap: _copyPayoutSummary,
          ),
        ],
      ),
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy, color: color.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    );
  }

  // ── Clipboard actions ────────────────────────────────────────────────
  void _copyReconciliationCsv() {
    final buf = StringBuffer();
    buf.writeln(
      'tx_id,ts,price,stripe_fee,net,cumulative_buys,dfc_pct,dfc_cut,promoter_cut,reserve',
    );
    for (final row in _ledger) {
      final reserve = row.net * 0.02;
      buf.writeln(
        '${row.txNum},${row.time},${_ppvPriceValue.toStringAsFixed(2)},${(_ppvPriceValue * 0.029 + 0.30).toStringAsFixed(2)},${row.net.toStringAsFixed(2)},${row.txNum},${(row.dfcPct * 100).toStringAsFixed(2)}%,${(row.net * row.dfcPct).toStringAsFixed(2)},${row.promoterCut.toStringAsFixed(2)},${reserve.toStringAsFixed(2)}',
      );
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    _showSnack('Reconciliation CSV copied to clipboard');
  }

  void _copyPayoutSummary() {
    final summary =
        '''
RECONCILIATION SUMMARY
══════════════════════════════════════
Event: $_eventName
Venue: $_venue
Date: ${DateFormat('d MMMM yyyy').format(_eventDate)}
Promoter: $_promoterName
PPV Price: $_ppvPrice

FINANCIALS
──────────────────────────────────────
Total Buys: ${NumberFormat('#,###').format(_totalBuys)}
Gross Sales: ${_fmt(_gross)}
Stripe Fees: ${_fmt(_stripeTotal)}
Net Revenue: ${_fmt(_net)}
Refunded / Reversed: ${_fmt(_snapshot?.refundedAmount ?? 0)}
Disputes Requiring Review: ${_snapshot?.activeDisputeCount ?? 0}

SPLIT (DFC ${(_currentDfcPct * 100).toStringAsFixed(1)}%)
──────────────────────────────────────
DFC Cut: ${_fmt(_dfcCut)}
Promoter Cut: ${_fmt(_promoterCut)}
Reserve (2%): ${_fmt(_reserve)}
Payable Promoter: ${_fmt(_payablePromoter)}

PAYOUT SCHEDULE
──────────────────────────────────────
Main Payout: ${_fmt(_payablePromoter)} on ${DateFormat('d MMM yyyy').format(_eventDate.add(const Duration(days: 14)))}
Reserve Release: ${_fmt(_reserve)} on ${DateFormat('d MMM yyyy').format(_eventDate.add(const Duration(days: 28)))} (if no chargebacks)

Formula: DFC_pct = 30% + (min(buys,10000)/10000) × 20%
All splits applied to Net after Stripe fees (2.9% + \$0.30/tx).
''';
    Clipboard.setData(ClipboardData(text: summary));
    _showSnack('Payout summary copied to clipboard');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.9),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Demo ledger generator ───────────────────────────────────────────
  List<_LedgerRow> _generateDemoLedger() {
    final rng = Random(42);
    final rows = <_LedgerRow>[];
    for (int i = 1; i <= _totalBuys; i++) {
      final isRefund = rng.nextDouble() < 0.015; // ~1.5% refund rate
      final stripeFee = 20 * 0.029 + 0.30;
      final net = isRefund ? 0.0 : max(0.0, 20.0 - stripeFee);
      final dfcP = _dfcPct(i);
      final hour = 18 + (i ~/ 500);
      final minute = rng.nextInt(60);
      rows.add(
        _LedgerRow(
          txNum: i,
          time:
              '${hour.clamp(18, 23).toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
          net: net,
          dfcPct: dfcP,
          promoterCut: net * (1.0 - dfcP),
          isRefund: isRefund,
        ),
      );
    }
    return rows;
  }
}

class _Metric {
  final String label;
  final String value;
  final Color color;
  const _Metric(this.label, this.value, this.color);
}

class _IntegrityMetric {
  final String label;
  final String value;
  final Color color;
  final String caption;
  const _IntegrityMetric(this.label, this.value, this.color, this.caption);
}

class _LedgerRow {
  final int txNum;
  final String time;
  final double net;
  final double dfcPct;
  final double promoterCut;
  final bool isRefund;
  const _LedgerRow({
    required this.txNum,
    required this.time,
    required this.net,
    required this.dfcPct,
    required this.promoterCut,
    required this.isRefund,
  });
}
