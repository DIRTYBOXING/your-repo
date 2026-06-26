import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PROMO CODE ENGINE — Create, Manage, Track, Redeem Promo Codes
// Affiliate links · Conversion analytics · Bulk generation · Tier gating
// ═══════════════════════════════════════════════════════════════════════════════

const _cyan = Color(0xFF00F5FF);
const _magenta = Color(0xFFFF00FF);
const _green = Color(0xFF00FF88);
const _amber = Color(0xFFFFB800);
const _red = Color(0xFFFF3366);
const _gold = Color(0xFFFFD700);
const _bg = Color(0xFF050A14);
const _panel = Color(0xFF0D1B2A);
const _surface = Color(0xFF142236);
const _border = Color(0xFF1A2744);

class PromoCodeEngineScreen extends StatefulWidget {
  const PromoCodeEngineScreen({super.key});
  @override
  State<PromoCodeEngineScreen> createState() => _PromoCodeEngineScreenState();
}

class _PromoCodeEngineScreenState extends State<PromoCodeEngineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // ── Create form state ──
  String _codePrefix = 'DFC';
  String _discountType = 'percent'; // percent | flat | freeEvent
  double _discountValue = 20;
  int _maxUses = 100;
  int _bulkCount = 1;
  bool _singleUsePerUser = true;
  String _tier = 'all'; // all | partner | vip
  final DateTime _expiresAt = DateTime(2026, 6, 30);

  // ── Demo codes ──
  final _codes = <_PromoCode>[
    _PromoCode(
      'DFC-LAUNCH20',
      'percent',
      20,
      500,
      312,
      true,
      'active',
      DateTime(2026, 6, 30),
      'All',
      4680.00,
    ),
    _PromoCode(
      'DFC-BKFC10',
      'flat',
      10,
      200,
      87,
      true,
      'active',
      DateTime(2026, 5, 15),
      'Partner',
      870.00,
    ),
    _PromoCode(
      'DFC-FREE1',
      'freeEvent',
      1,
      50,
      50,
      true,
      'exhausted',
      DateTime(2026, 4),
      'VIP',
      2500.00,
    ),
    _PromoCode(
      'DFC-SUMMER30',
      'percent',
      30,
      1000,
      0,
      true,
      'scheduled',
      DateTime(2026, 9),
      'All',
      0,
    ),
    _PromoCode(
      'DFC-FIGHTER5',
      'flat',
      5,
      300,
      145,
      false,
      'active',
      DateTime(2026, 7, 15),
      'All',
      725.00,
    ),
    _PromoCode(
      'DFC-VIP50',
      'percent',
      50,
      25,
      18,
      true,
      'active',
      DateTime(2026, 4, 15),
      'VIP',
      1800.00,
    ),
    _PromoCode(
      'DFC-EARLY15',
      'percent',
      15,
      400,
      400,
      true,
      'exhausted',
      DateTime(2026, 3),
      'All',
      3000.00,
    ),
  ];

  // ── Demo affiliates ──
  final _affiliates = <_Affiliate>[
    _Affiliate(
      'AFF-001',
      'CombatNews AU',
      'dfc.app/r/combatnews',
      1240,
      186,
      15.0,
      2790.00,
    ),
    _Affiliate(
      'AFF-002',
      'FightFans YT',
      'dfc.app/r/fightfans',
      3420,
      410,
      12.0,
      6150.00,
    ),
    _Affiliate(
      'AFF-003',
      'BKFC Insider',
      'dfc.app/r/bkfcinsider',
      890,
      98,
      11.0,
      1470.00,
    ),
    _Affiliate(
      'AFF-004',
      'MMA Weekly Pod',
      'dfc.app/r/mmaweekly',
      2100,
      273,
      13.0,
      4095.00,
    ),
    _Affiliate(
      'AFF-005',
      'Underground Boxing',
      'dfc.app/r/ugboxing',
      560,
      45,
      8.0,
      675.00,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  int get _totalRedemptions => _codes.fold(0, (s, c) => s + c.used);
  double get _totalRevenue => _codes.fold(0.0, (s, c) => s + c.revenueImpact);
  int get _activeCodes => _codes.where((c) => c.status == 'active').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSummaryBar(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildCodesTab(),
                _buildCreateTab(),
                _buildAffiliatesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _panel,
      foregroundColor: _magenta,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.confirmation_number, color: _magenta, size: 22),
          const SizedBox(width: 8),
          const Text(
            'PROMO CODE ENGINE',
            style: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: _magenta,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _green.withValues(alpha: 0.4)),
            ),
            child: Text(
              '$_activeCodes ACTIVE',
              style: const TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        indicatorColor: _magenta,
        labelColor: _magenta,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(
          fontFamily: 'Segoe UI',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(text: 'ALL CODES'),
          Tab(text: 'CREATE'),
          Tab(text: 'AFFILIATES'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUMMARY BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _summaryChip('TOTAL CODES', '${_codes.length}', _magenta),
            const SizedBox(width: 12),
            _summaryChip('ACTIVE', '$_activeCodes', _green),
            const SizedBox(width: 12),
            _summaryChip('REDEMPTIONS', '$_totalRedemptions', _cyan),
            const SizedBox(width: 12),
            _summaryChip(
              'REVENUE IMPACT',
              '\$${_totalRevenue.toStringAsFixed(0)}',
              _gold,
            ),
            const SizedBox(width: 12),
            _summaryChip('AFFILIATES', '${_affiliates.length}', _amber),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Segoe UI',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1 — All Codes
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCodesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'CODE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'TYPE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'USED/MAX',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'REVENUE',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _codes.length,
              itemBuilder: (ctx, i) => _codeRow(_codes[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeRow(_PromoCode c) {
    final statusColor = switch (c.status) {
      'active' => _green,
      'exhausted' => _red,
      'scheduled' => _amber,
      _ => Colors.white38,
    };
    final typeLabel = switch (c.discountType) {
      'percent' => '${c.discountValue.toInt()}% OFF',
      'flat' => '\$${c.discountValue.toInt()} OFF',
      'freeEvent' => 'FREE EVENT',
      _ => c.discountType,
    };
    final usageRatio = c.maxUses > 0 ? c.used / c.maxUses : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.code,
                      style: const TextStyle(
                        color: _cyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: c.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied ${c.code}'),
                            backgroundColor: _green,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.copy,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Tier: ${c.tier} · Expires: ${c.expiresAt.day}/${c.expiresAt.month}/${c.expiresAt.year}${c.singleUse ? ' · 1x/user' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              typeLabel,
              style: const TextStyle(
                color: _gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${c.used}/${c.maxUses}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: usageRatio,
                    backgroundColor: _surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usageRatio > 0.9 ? _red : _cyan,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '\$${c.revenueImpact.toStringAsFixed(0)}',
              style: const TextStyle(
                color: _gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                c.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2 — Create Code
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCreateTab() {
    final isWide = MediaQuery.of(context).size.width > 900;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _createForm()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _codePreview()),
              ],
            )
          : Column(
              children: [
                _createForm(),
                const SizedBox(height: 16),
                _codePreview(),
              ],
            ),
    );
  }

  Widget _createForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('CREATE PROMO CODE', _magenta),
          const SizedBox(height: 16),
          // Code prefix
          _formField(
            'Code Prefix',
            _codePrefix,
            (v) => setState(() => _codePrefix = v),
          ),
          const SizedBox(height: 12),
          // Discount type
          _sectionHeader('DISCOUNT TYPE', _cyan),
          const SizedBox(height: 8),
          Row(
            children: [
              _typeChip('Percent Off', 'percent', _green),
              const SizedBox(width: 8),
              _typeChip('Flat Amount', 'flat', _amber),
              const SizedBox(width: 8),
              _typeChip('Free Event', 'freeEvent', _magenta),
            ],
          ),
          const SizedBox(height: 12),
          // Discount value
          if (_discountType != 'freeEvent')
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _discountType == 'percent'
                            ? 'Discount (%)'
                            : 'Discount (\$)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: _gold,
                          thumbColor: _gold,
                          inactiveTrackColor: _gold.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          value: _discountValue,
                          min: 1,
                          max: _discountType == 'percent' ? 100 : 500,
                          divisions: _discountType == 'percent' ? 99 : 499,
                          onChanged: (v) => setState(() => _discountValue = v),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    _discountType == 'percent'
                        ? '${_discountValue.toInt()}%'
                        : '\$${_discountValue.toInt()}',
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          // Max uses + bulk count
          Row(
            children: [
              Expanded(
                child: _numField(
                  'Max Uses',
                  _maxUses,
                  (v) => setState(() => _maxUses = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numField(
                  'Bulk Generate',
                  _bulkCount,
                  (v) => setState(() => _bulkCount = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tier gating
          _sectionHeader('TIER GATE', _amber),
          const SizedBox(height: 8),
          Row(
            children: [
              _tierChip('All Users', 'all'),
              const SizedBox(width: 8),
              _tierChip('Partner Only', 'partner'),
              const SizedBox(width: 8),
              _tierChip('VIP Only', 'vip'),
            ],
          ),
          const SizedBox(height: 12),
          // Single use toggle
          Row(
            children: [
              Switch(
                value: _singleUsePerUser,
                onChanged: (v) => setState(() => _singleUsePerUser = v),
                activeTrackColor: _cyan,
              ),
              Text(
                _singleUsePerUser
                    ? 'Single use per user'
                    : 'Unlimited per user',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Generated $_bulkCount code${_bulkCount > 1 ? 's' : ''} with prefix $_codePrefix',
                    ),
                    backgroundColor: _green,
                  ),
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(
                _bulkCount > 1 ? 'GENERATE $_bulkCount CODES' : 'CREATE CODE',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _magenta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _codePreview() {
    final previewCode =
        '$_codePrefix-${_discountType == 'percent'
            ? '${_discountValue.toInt()}PCT'
            : _discountType == 'flat'
            ? '${_discountValue.toInt()}OFF'
            : 'FREE'}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('LIVE PREVIEW', _gold),
          const SizedBox(height: 16),
          // Code display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _magenta.withValues(alpha: 0.15),
                  _cyan.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _magenta.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  previewCode,
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _discountType == 'percent'
                      ? '${_discountValue.toInt()}% off'
                      : _discountType == 'flat'
                      ? '\$${_discountValue.toInt()} off'
                      : '1 Free Event',
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Max $_maxUses uses · Tier: ${_tier.toUpperCase()} · ${_singleUsePerUser ? '1x/user' : 'Unlimited'}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Expires: ${_expiresAt.day}/${_expiresAt.month}/${_expiresAt.year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Share links
          _sectionHeader('SHARE LINKS', _cyan),
          const SizedBox(height: 8),
          _shareLinkRow('Direct', 'dfc.app/promo/$previewCode'),
          _shareLinkRow(
            'UTM',
            'dfc.app/promo/$previewCode?utm_source=partner&utm_medium=promo',
          ),
          _shareLinkRow('QR', 'dfc.app/qr/$previewCode'),
          const SizedBox(height: 16),
          // Bulk preview
          if (_bulkCount > 1) ...[
            _sectionHeader('BULK CODES (${_bulkCount}x)', _amber),
            const SizedBox(height: 8),
            for (int i = 0; i < math.min(_bulkCount, 5); i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '$previewCode-${(1000 + i).toString().substring(1)}',
                  style: TextStyle(
                    color: _cyan.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            if (_bulkCount > 5)
              Text(
                '... and ${_bulkCount - 5} more',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _shareLinkRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              url,
              style: TextStyle(
                color: _cyan.withValues(alpha: 0.7),
                fontSize: 11,
                fontFamily: 'Courier',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Link copied'),
                  backgroundColor: _green,
                ),
              );
            },
            child: Icon(
              Icons.copy,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3 — Affiliates
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAffiliatesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader('AFFILIATE PARTNERS', _amber),
              const Spacer(),
              _pillButton('+ NEW AFFILIATE', _amber, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Email partners@datafightcentral.com to join the affiliate program',
                    ),
                    backgroundColor: _amber,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          // KPI row
          Row(
            children: [
              _kpiCard(
                'Total Clicks',
                '${_affiliates.fold<int>(0, (s, a) => s + a.clicks)}',
                _cyan,
                Icons.touch_app,
              ),
              const SizedBox(width: 8),
              _kpiCard(
                'Conversions',
                '${_affiliates.fold<int>(0, (s, a) => s + a.conversions)}',
                _green,
                Icons.check_circle,
              ),
              const SizedBox(width: 8),
              _kpiCard(
                'Revenue',
                '\$${_affiliates.fold<double>(0, (s, a) => s + a.revenue).toStringAsFixed(0)}',
                _gold,
                Icons.attach_money,
              ),
              const SizedBox(width: 8),
              _kpiCard(
                'Avg CVR',
                '${(_affiliates.fold<double>(0, (s, a) => s + a.cvr) / _affiliates.length).toStringAsFixed(1)}%',
                _magenta,
                Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _affiliates.length,
              itemBuilder: (ctx, i) => _affiliateCard(_affiliates[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _affiliateCard(_Affiliate a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                a.name.substring(0, 2).toUpperCase(),
                style: const TextStyle(
                  color: _amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      a.link,
                      style: TextStyle(
                        color: _cyan.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: 'https://${a.link}'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Affiliate link copied'),
                            backgroundColor: _green,
                          ),
                        );
                      },
                      child: Icon(
                        Icons.copy,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${a.clicks} clicks → ${a.conversions} conv',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${a.cvr}% CVR · \$${a.revenue.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared helpers
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _sectionHeader(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }

  Widget _typeChip(String label, String type, Color color) {
    final selected = _discountType == type;
    return GestureDetector(
      onTap: () => setState(() => _discountType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _tierChip(String label, String value) {
    final selected = _tier == value;
    final color = _amber;
    return GestureDetector(
      onTap: () => setState(() => _tier = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _formField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          style: const TextStyle(
            color: _cyan,
            fontFamily: 'Courier',
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: _surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _cyan),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _numField(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: _red,
                size: 20,
              ),
              onPressed: () {
                if (value > 1) onChanged(value - 1);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: Text(
                '$value',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: _green,
                size: 20,
              ),
              onPressed: () => onChanged(value + 1),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Data models
// ═══════════════════════════════════════════════════════════════════════════════
class _PromoCode {
  final String code, discountType, status, tier;
  final double discountValue, revenueImpact;
  final int maxUses, used;
  final bool singleUse;
  final DateTime expiresAt;
  _PromoCode(
    this.code,
    this.discountType,
    this.discountValue,
    this.maxUses,
    this.used,
    this.singleUse,
    this.status,
    this.expiresAt,
    this.tier,
    this.revenueImpact,
  );
}

class _Affiliate {
  final String id, name, link;
  final int clicks, conversions;
  final double cvr, revenue;
  _Affiliate(
    this.id,
    this.name,
    this.link,
    this.clicks,
    this.conversions,
    this.cvr,
    this.revenue,
  );
}
