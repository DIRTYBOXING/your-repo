import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MARKETING COST ESTIMATOR — ROI calculator for ad spend, ticket price,
/// conversion rates, and budget allocation with preset bundles
/// ═══════════════════════════════════════════════════════════════════════════

class MarketingCostEstimatorScreen extends StatefulWidget {
  const MarketingCostEstimatorScreen({super.key});

  @override
  State<MarketingCostEstimatorScreen> createState() =>
      _MarketingCostEstimatorScreenState();
}

class _MarketingCostEstimatorScreenState
    extends State<MarketingCostEstimatorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;

  // ── Inputs ────────────────────────────────────────────────────────────
  final _ticketPriceCtrl = TextEditingController(text: '50');
  final _expectedSalesCtrl = TextEditingController(text: '500');
  final _convRateCtrl = TextEditingController(text: '2');
  final _avgCpcCtrl = TextEditingController(text: '0.80');
  final _ppvPriceCtrl = TextEditingController(text: '29.99');
  final _ppvSalesCtrl = TextEditingController(text: '200');
  final _vipPriceCtrl = TextEditingController(text: '150');
  final _vipSalesCtrl = TextEditingController(text: '50');

  // ── Results ───────────────────────────────────────────────────────────
  bool _calculated = false;
  double _ticketRevenue = 0;
  double _ppvRevenue = 0;
  double _vipRevenue = 0;
  double _totalRevenue = 0;
  int _clicksNeeded = 0;
  double _adSpend = 0;
  double _breakevenCpc = 0;
  double _roas = 0;
  double _profit = 0;
  double _cpp = 0; // cost per purchase

  int _selectedBundle = -1;

  static const _bundles = [
    _BudgetBundle(
      'Fast Launch',
      '7 days',
      900,
      2200,
      'Creative pack + WP page + CTA + basic ad setup',
      DesignTokens.neonCyan,
    ),
    _BudgetBundle(
      'Growth Pack',
      '14 days',
      1800,
      5000,
      'Above + ad creatives + email flows + 2 wks ad management',
      DesignTokens.neonGold,
    ),
    _BudgetBundle(
      'Full Factory',
      '30 days',
      4500,
      12000,
      'End-to-end: creative, page, ads, automation, 4 wks mgmt',
      DesignTokens.neonMagenta,
    ),
  ];

  static const _adBudgets = [
    _AdBudget(
      'Local Launch',
      500,
      '7–10 days, prospecting + retargeting',
      DesignTokens.neonGreen,
    ),
    _AdBudget(
      'Regional Push',
      3500,
      '14 days, scale retargeting last 7d',
      DesignTokens.neonGold,
    ),
    _AdBudget(
      'Aggressive Scale',
      7500,
      'National reach, heavy retargeting 48–72h',
      DesignTokens.neonRed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _ticketPriceCtrl.dispose();
    _expectedSalesCtrl.dispose();
    _convRateCtrl.dispose();
    _avgCpcCtrl.dispose();
    _ppvPriceCtrl.dispose();
    _ppvSalesCtrl.dispose();
    _vipPriceCtrl.dispose();
    _vipSalesCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final ticketPrice = double.tryParse(_ticketPriceCtrl.text) ?? 0;
    final expectedSales = int.tryParse(_expectedSalesCtrl.text) ?? 0;
    final convRate = (double.tryParse(_convRateCtrl.text) ?? 0) / 100;
    final cpc = double.tryParse(_avgCpcCtrl.text) ?? 0;
    final ppvPrice = double.tryParse(_ppvPriceCtrl.text) ?? 0;
    final ppvSales = int.tryParse(_ppvSalesCtrl.text) ?? 0;
    final vipPrice = double.tryParse(_vipPriceCtrl.text) ?? 0;
    final vipSales = int.tryParse(_vipSalesCtrl.text) ?? 0;

    final ticketRev = ticketPrice * expectedSales;
    final ppvRev = ppvPrice * ppvSales;
    final vipRev = vipPrice * vipSales;
    final total = ticketRev + ppvRev + vipRev;

    final safeConv = convRate > 0 ? convRate : 0.0001;
    final totalSales = expectedSales + ppvSales + vipSales;
    final clicks = (totalSales / safeConv).ceil();
    final spend = clicks * cpc;
    final beCpc = clicks > 0 ? total / clicks : 0.0;
    final roas = spend > 0 ? total / spend : 0.0;
    final costPerPurchase = totalSales > 0 ? spend / totalSales : 0.0;

    setState(() {
      _calculated = true;
      _ticketRevenue = ticketRev;
      _ppvRevenue = ppvRev;
      _vipRevenue = vipRev;
      _totalRevenue = total;
      _clicksNeeded = clicks;
      _adSpend = spend;
      _breakevenCpc = beCpc;
      _roas = roas;
      _profit = total - spend;
      _cpp = costPerPurchase;
    });
  }

  void _copyResults() {
    final text =
        '''Marketing Cost Estimate
Ticket Revenue: AUD ${_ticketRevenue.toStringAsFixed(2)}
PPV Revenue: AUD ${_ppvRevenue.toStringAsFixed(2)}
VIP Revenue: AUD ${_vipRevenue.toStringAsFixed(2)}
Total Revenue: AUD ${_totalRevenue.toStringAsFixed(2)}
Clicks Needed: $_clicksNeeded
Ad Spend: AUD ${_adSpend.toStringAsFixed(2)}
Break-even CPC: AUD ${_breakevenCpc.toStringAsFixed(2)}
Cost per Purchase: AUD ${_cpp.toStringAsFixed(2)}
ROAS: ${_roas.toStringAsFixed(2)}x
Net Profit: AUD ${_profit.toStringAsFixed(2)}''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Results copied to clipboard'),
        backgroundColor: DesignTokens.neonGreen.withValues(alpha: 0.9),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 16,
            primaryColor: DesignTokens.neonGold,
            secondaryColor: DesignTokens.neonGreen,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: wide ? _wideLayout() : _narrowLayout()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, a) => Icon(
              Icons.calculate_outlined,
              color: DesignTokens.neonGold.withValues(
                alpha: 0.6 + _pulseAnim.value * 0.4,
              ),
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [DesignTokens.neonGold, DesignTokens.neonGreen],
              ).createShader(bounds),
              child: const Text(
                'COST ESTIMATOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          if (_calculated)
            IconButton(
              onPressed: _copyResults,
              icon: const Icon(Icons.copy_all, color: DesignTokens.neonGold),
              tooltip: 'Copy results',
            ),
        ],
      ),
    );
  }

  // ── Layouts ────────────────────────────────────────────────────────────

  Widget _wideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 10, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputForm(),
                const SizedBox(height: 16),
                if (_calculated) _resultsCard(),
                const SizedBox(height: 16),
                _funnelMetrics(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(10, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _budgetBundles(),
                const SizedBox(height: 16),
                _adBudgetTiers(),
                const SizedBox(height: 16),
                _tacticTable(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrowLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inputForm(),
          const SizedBox(height: 16),
          if (_calculated) _resultsCard(),
          const SizedBox(height: 16),
          _funnelMetrics(),
          const SizedBox(height: 16),
          _budgetBundles(),
          const SizedBox(height: 16),
          _adBudgetTiers(),
          const SizedBox(height: 16),
          _tacticTable(),
        ],
      ),
    );
  }

  // ── Input form ────────────────────────────────────────────────────────

  Widget _inputForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('REVENUE INPUTS', DesignTokens.neonGold),
          const SizedBox(height: 12),
          // Ticket row
          Row(
            children: [
              Expanded(
                child: _inputField(
                  _ticketPriceCtrl,
                  'Ticket Price (AUD)',
                  Icons.confirmation_num_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputField(
                  _expectedSalesCtrl,
                  'Expected Tickets',
                  Icons.people_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // PPV row
          Row(
            children: [
              Expanded(
                child: _inputField(
                  _ppvPriceCtrl,
                  'PPV Price (AUD)',
                  Icons.live_tv_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputField(_ppvSalesCtrl, 'PPV Sales', Icons.tv),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // VIP row
          Row(
            children: [
              Expanded(
                child: _inputField(
                  _vipPriceCtrl,
                  'VIP Price (AUD)',
                  Icons.star_outline,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputField(
                  _vipSalesCtrl,
                  'VIP Sales',
                  Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionLabel('AD SPEND INPUTS', DesignTokens.neonCyan),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  _convRateCtrl,
                  'Conv Rate (%)',
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputField(
                  _avgCpcCtrl,
                  'Avg CPC (AUD)',
                  Icons.ads_click,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate, size: 18),
              label: const Text('CALCULATE ROI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.neonGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Results card ──────────────────────────────────────────────────────

  Widget _resultsCard() {
    final profitable = _profit >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(
        accent: profitable ? DesignTokens.neonGreen : DesignTokens.neonRed,
        hasGlow: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                profitable ? Icons.trending_up : Icons.trending_down,
                color: profitable
                    ? DesignTokens.neonGreen
                    : DesignTokens.neonRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                profitable ? 'PROFITABLE' : 'LOSS',
                style: TextStyle(
                  color: profitable
                      ? DesignTokens.neonGreen
                      : DesignTokens.neonRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _copyResults,
                icon: const Icon(Icons.copy, size: 16, color: Colors.white38),
                tooltip: 'Copy',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Revenue breakdown
          _resultRow(
            'Ticket Revenue',
            'AUD ${_ticketRevenue.toStringAsFixed(0)}',
            DesignTokens.neonCyan,
          ),
          _resultRow(
            'PPV Revenue',
            'AUD ${_ppvRevenue.toStringAsFixed(0)}',
            DesignTokens.neonMagenta,
          ),
          _resultRow(
            'VIP Revenue',
            'AUD ${_vipRevenue.toStringAsFixed(0)}',
            DesignTokens.neonGold,
          ),
          const Divider(color: Colors.white12, height: 20),
          _resultRow(
            'Total Revenue',
            'AUD ${_totalRevenue.toStringAsFixed(0)}',
            Colors.white,
          ),
          const SizedBox(height: 8),
          // Spend metrics
          _resultRow(
            'Clicks Needed',
            _clicksNeeded.toString(),
            DesignTokens.neonAmber,
          ),
          _resultRow(
            'Est. Ad Spend',
            'AUD ${_adSpend.toStringAsFixed(2)}',
            DesignTokens.neonRed,
          ),
          _resultRow(
            'Break-even CPC',
            'AUD ${_breakevenCpc.toStringAsFixed(2)}',
            DesignTokens.neonAmber,
          ),
          _resultRow(
            'Cost per Purchase',
            'AUD ${_cpp.toStringAsFixed(2)}',
            DesignTokens.neonAmber,
          ),
          const Divider(color: Colors.white12, height: 20),
          _resultRow(
            'ROAS',
            '${_roas.toStringAsFixed(2)}x',
            _roas >= 3
                ? DesignTokens.neonGreen
                : (_roas >= 1 ? DesignTokens.neonAmber : DesignTokens.neonRed),
          ),
          _resultRow(
            'Net Profit',
            'AUD ${_profit.toStringAsFixed(0)}',
            profitable ? DesignTokens.neonGreen : DesignTokens.neonRed,
          ),
        ],
      ),
    );
  }

  // ── Funnel metrics ────────────────────────────────────────────────────

  Widget _funnelMetrics() {
    const kpis = [
      (
        'Landing CVR',
        '≥ 2–5%',
        'Top performers > 5%',
        Icons.language,
        DesignTokens.neonCyan,
      ),
      (
        'Cost per Purchase',
        'Track daily',
        'Lower = better',
        Icons.attach_money,
        DesignTokens.neonGold,
      ),
      (
        'ROAS',
        '≥ 3x',
        'Break-even at 1x',
        Icons.show_chart,
        DesignTokens.neonGreen,
      ),
      (
        'Video 25% → Purchase',
        'Retargeting lift',
        'Heavy retarget 24–72h',
        Icons.play_circle_outline,
        DesignTokens.neonMagenta,
      ),
      (
        'Email Open → Purchase',
        'Track CVR',
        'SMS for last-minute',
        Icons.email_outlined,
        DesignTokens.neonAmber,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('KPIs TO WATCH DAILY', DesignTokens.neonCyan),
          const SizedBox(height: 12),
          ...kpis.map(
            (k) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(k.$4, size: 16, color: k.$5.withValues(alpha: 0.6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.$1,
                          style: TextStyle(
                            color: k.$5,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${k.$2} · ${k.$3}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Budget bundles ────────────────────────────────────────────────────

  Widget _budgetBundles() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonMagenta),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('MARKETING BUNDLES', DesignTokens.neonMagenta),
          const SizedBox(height: 12),
          ...List.generate(_bundles.length, (i) {
            final b = _bundles[i];
            final selected = i == _selectedBundle;
            return GestureDetector(
              onTap: () => setState(() => _selectedBundle = selected ? -1 : i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? b.color.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? b.color.withValues(alpha: 0.5)
                        : Colors.white10,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          b.name.toUpperCase(),
                          style: TextStyle(
                            color: b.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          b.timeline,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AUD ${b.low.toStringAsFixed(0)} – ${b.high.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Ad budget tiers ───────────────────────────────────────────────────

  Widget _adBudgetTiers() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('AD SPEND TIERS (AUD)', DesignTokens.neonAmber),
          const SizedBox(height: 12),
          ..._adBudgets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: b.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              b.name,
                              style: TextStyle(
                                color: b.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'AUD ${b.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          b.note,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tactic investment table ───────────────────────────────────────────

  Widget _tacticTable() {
    const tactics = [
      ('Retargeting', '+30–80%', 'Low–Med', DesignTokens.neonGreen),
      ('Prospecting Ads', '+10–30%', 'Medium', DesignTokens.neonCyan),
      ('Email + SMS', '2–10%+ CVR', 'Low', DesignTokens.neonGold),
      ('Organic / Community', 'Variable', 'Low', DesignTokens.neonMagenta),
      (
        'Grassroots / Venues',
        'High per-contact',
        'Low',
        DesignTokens.neonAmber,
      ),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGreen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('CONVERSION TACTICS', DesignTokens.neonGreen),
          const SizedBox(height: 12),
          ...tactics.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      t.$1,
                      style: TextStyle(
                        color: t.$4,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      t.$2,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      t.$3,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.4),
          fontSize: 11,
        ),
        prefixIcon: Icon(icon, size: 16, color: Colors.white24),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DesignTokens.neonGold),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data Models ────────────────────────────────────────────────────────────

class _BudgetBundle {
  final String name;
  final String timeline;
  final double low;
  final double high;
  final String description;
  final Color color;
  const _BudgetBundle(
    this.name,
    this.timeline,
    this.low,
    this.high,
    this.description,
    this.color,
  );
}

class _AdBudget {
  final String name;
  final double amount;
  final String note;
  final Color color;
  const _AdBudget(this.name, this.amount, this.note, this.color);
}
