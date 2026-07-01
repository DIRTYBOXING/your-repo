import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SLIDING CONTRACT CALCULATOR — 85/15 four-tier revenue split modelling
/// ═══════════════════════════════════════════════════════════════════════════

class SlidingContractCalculatorScreen extends StatefulWidget {
  const SlidingContractCalculatorScreen({super.key});

  @override
  State<SlidingContractCalculatorScreen> createState() =>
      _SlidingContractCalculatorScreenState();
}

class _SlidingContractCalculatorScreenState
    extends State<SlidingContractCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;

  // ── Inputs ──
  final _t1Ctrl = TextEditingController(text: '25000');
  final _t2Ctrl = TextEditingController(text: '75000');
  final _t3Ctrl = TextEditingController(text: '200000');
  final _guaranteeCtrl = TextEditingController(text: '10000');
  final _escrowCtrl = TextEditingController(text: '10000');

  double _split1Fighter = 85; // tier 1 fighter %
  double _split2Fighter = 75; // tier 2 fighter %
  double _split3Fighter = 65; // tier 3 fighter %
  double _split4Fighter = 50; // tier 4 fighter %

  // ── Revenue slider ──
  double _revenueSlider = 150000;

  // ── Computed ──
  bool _calculated = false;
  double _fighterShare = 0;
  double _promoterShare = 0;
  double _effectiveRate = 0;
  double _totalFighter = 0;

  // Split per tier for breakdown
  double _tier1Payout = 0;
  double _tier2Payout = 0;
  double _tier3Payout = 0;
  double _tier4Payout = 0;

  // ── Split model presets ──
  static const _presets = [
    _ContractPreset('85/15 Standard', 85, 75, 65, 50, 25000, 75000, 200000),
    _ContractPreset('80/20 Moderate', 80, 70, 60, 50, 20000, 60000, 150000),
    _ContractPreset('85/15 PPV Heavy', 85, 75, 65, 50, 15000, 50000, 120000),
    _ContractPreset('90/10 Fighter Max', 90, 80, 70, 55, 30000, 80000, 250000),
    _ContractPreset('75/25 Promo Scale', 75, 65, 55, 50, 10000, 40000, 100000),
  ];
  int _selectedPreset = 0; // default 85/15 Standard

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _calculate();
  }

  @override
  void dispose() {
    _pulseAnim.dispose();
    _t1Ctrl.dispose();
    _t2Ctrl.dispose();
    _t3Ctrl.dispose();
    _guaranteeCtrl.dispose();
    _escrowCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(int idx) {
    final p = _presets[idx];
    setState(() {
      _selectedPreset = idx;
      _split1Fighter = p.f1;
      _split2Fighter = p.f2;
      _split3Fighter = p.f3;
      _split4Fighter = p.f4;
      _t1Ctrl.text = p.t1.toStringAsFixed(0);
      _t2Ctrl.text = p.t2.toStringAsFixed(0);
      _t3Ctrl.text = p.t3.toStringAsFixed(0);
    });
    _calculate();
  }

  void _calculate() {
    final t1 = double.tryParse(_t1Ctrl.text) ?? 0;
    final t2 = double.tryParse(_t2Ctrl.text) ?? 0;
    final t3 = double.tryParse(_t3Ctrl.text) ?? 0;
    final guarantee = double.tryParse(_guaranteeCtrl.text) ?? 0;
    final r = _revenueSlider;

    // Piecewise 4-tier fighter share: F(R)
    double fighter = 0;
    double p1 = 0, p2 = 0, p3 = 0, p4 = 0;

    if (r <= t1) {
      p1 = r * (_split1Fighter / 100);
      fighter = p1;
    } else if (r <= t2) {
      p1 = t1 * (_split1Fighter / 100);
      p2 = (r - t1) * (_split2Fighter / 100);
      fighter = p1 + p2;
    } else if (r <= t3) {
      p1 = t1 * (_split1Fighter / 100);
      p2 = (t2 - t1) * (_split2Fighter / 100);
      p3 = (r - t2) * (_split3Fighter / 100);
      fighter = p1 + p2 + p3;
    } else {
      p1 = t1 * (_split1Fighter / 100);
      p2 = (t2 - t1) * (_split2Fighter / 100);
      p3 = (t3 - t2) * (_split3Fighter / 100);
      p4 = (r - t3) * (_split4Fighter / 100);
      fighter = p1 + p2 + p3 + p4;
    }

    final effective = r > 0 ? (fighter / r) * 100 : 0.0;
    // If guarantee > fighter share, fighter gets guarantee
    final actualFighter = fighter < guarantee ? guarantee : fighter;

    setState(() {
      _calculated = true;
      _fighterShare = fighter;
      _promoterShare = r - fighter;
      _effectiveRate = effective;
      _totalFighter = actualFighter;
      _tier1Payout = p1;
      _tier2Payout = p2;
      _tier3Payout = p3;
      _tier4Payout = p4;
    });
  }

  void _copyTermSheet() {
    final t1 = _t1Ctrl.text;
    final t2 = _t2Ctrl.text;
    final t3 = _t3Ctrl.text;
    final guarantee = _guaranteeCtrl.text;
    final escrow = _escrowCtrl.text;
    final p1 = (100 - _split1Fighter).toStringAsFixed(0);
    final f1 = _split1Fighter.toStringAsFixed(0);
    final p2 = (100 - _split2Fighter).toStringAsFixed(0);
    final f2 = _split2Fighter.toStringAsFixed(0);
    final p3 = (100 - _split3Fighter).toStringAsFixed(0);
    final f3 = _split3Fighter.toStringAsFixed(0);
    final p4 = (100 - _split4Fighter).toStringAsFixed(0);
    final f4 = _split4Fighter.toStringAsFixed(0);

    final text =
        '''SLIDING CONTRACT — ONE-PAGE TERM SHEET
${'=' * 55}
Event: Townsville Fight Show — 25 Oct 2026
Parties: Promoter (DFC Founder / DirtyBoxer / DFC HQ)
         DFC (Logan) representing Aze Hepi
Ticket URL: https://www.datafightcentral.com

DEAL SUMMARY
${'─' * 45}
Sliding Revenue Split (Net Event Revenue):
  Tier 1 (AUD 0–$t1):       Promoter $p1% / Fighter $f1%
  Tier 2 (AUD $t1–$t2):     Promoter $p2% / Fighter $f2%
  Tier 3 (AUD $t2–$t3):     Promoter $p3% / Fighter $f3%
  Tier 4 (Above AUD $t3):   Promoter $p4% / Fighter $f4%

Guarantee: AUD $guarantee deposited into escrow within 72 hours
Escrow Amount: AUD $escrow
Marketing Spend: Pilot AUD 1,000; regional scale AUD 3,000
PPV: Net PPV revenue follows sliding tiers after platform fees
Reporting: Daily sales CSV; read-only ticketing + Meta pixel access
Payment: Within 7 days of event; reconciliation within 14 days
Termination: 48-hour notice prior to paid ad launch

NET REVENUE DEFINITION
${'─' * 45}
"Net Event Revenue" means gross receipts from ticket sales, PPV,
and merchandise attributable to the Event less: (a) ticketing
platform fees; (b) payment processing fees; (c) refunds and
chargebacks; (d) direct event costs pre-approved in writing.

GUARANTEE & ESCROW
${'─' * 45}
Promoter deposits AUD $escrow into escrow within 72 hours of
signing. Escrow funds applied to fighter guarantee and final
reconciliation. Paid activation paused until escrow funded.

CAP ON DEDUCTIONS
${'─' * 45}
Only ticketing platform fees, payment processing fees, documented
refunds/chargebacks, and pre-approved direct event costs may be
deducted. Any other deduction requires prior written approval
and supporting invoices.

REPORTING & AUDIT
${'─' * 45}
Daily sales CSVs (tickets + PPV); read-only ticketing dashboard;
Meta pixel access; PPV transaction exports within 24 hours.
Fighter may audit within 30 days with 5 business days notice.

PAYMENT TERMS
${'─' * 45}
Promoter pays within 7 days of event. Final reconciliation
within 14 days. Interest at 1.5%/month on overdue amounts.

PPV SECURITY
${'─' * 45}
Single-use tokens tied to buyer email/phone; 2-device limit;
token expiry at event end; DRM or tokenized access.

MODELLED SCENARIO
${'─' * 45}
Net Revenue: AUD ${_revenueSlider.toStringAsFixed(0)}
  Tier 1 fighter: AUD ${_tier1Payout.toStringAsFixed(2)}
  Tier 2 fighter: AUD ${_tier2Payout.toStringAsFixed(2)}
  Tier 3 fighter: AUD ${_tier3Payout.toStringAsFixed(2)}
  Tier 4 fighter: AUD ${_tier4Payout.toStringAsFixed(2)}
  TOTAL Fighter: AUD ${_totalFighter.toStringAsFixed(2)}
  Promoter Share: AUD ${_promoterShare.toStringAsFixed(2)}
  Effective Rate: ${_effectiveRate.toStringAsFixed(1)}%

SIGNATURES
${'─' * 45}
Promoter: ___________________  Date: ____
DFC (Logan): ________________  Date: ____
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full term sheet copied to clipboard'),
        backgroundColor: Color(0xFF00FF88),
      ),
    );
  }

  void _copyFullContract() {
    final t1 = _t1Ctrl.text;
    final t2 = _t2Ctrl.text;
    final t3 = _t3Ctrl.text;
    final escrow = _escrowCtrl.text;
    final p1 = (100 - _split1Fighter).toStringAsFixed(0);
    final f1 = _split1Fighter.toStringAsFixed(0);
    final p2 = (100 - _split2Fighter).toStringAsFixed(0);
    final f2 = _split2Fighter.toStringAsFixed(0);
    final p3 = (100 - _split3Fighter).toStringAsFixed(0);
    final f3 = _split3Fighter.toStringAsFixed(0);
    final p4 = (100 - _split4Fighter).toStringAsFixed(0);
    final f4 = _split4Fighter.toStringAsFixed(0);

    final text =
        '''FULL CONTRACT CLAUSES — PASTE-READY LEGAL LANGUAGE
${'=' * 60}

1. DEFINITIONS AND NET EVENT REVENUE
"Net Event Revenue" means gross receipts from ticket sales, PPV, and
merchandise attributable to the Event less: (a) ticketing platform
fees; (b) payment processing fees; (c) refunds and chargebacks; and
(d) direct event costs pre-approved in writing by both parties.

2. SLIDING REVENUE SPLIT
Net Event Revenue will be distributed on a tiered basis:
(i)   0–AUD $t1: Promoter $p1% / Fighter $f1%
(ii)  AUD $t1–AUD $t2: Promoter $p2% / Fighter $f2%
(iii) AUD $t2–AUD $t3: Promoter $p3% / Fighter $f3%
(iv)  Above AUD $t3: Promoter $p4% / Fighter $f4%
Net Event Revenue shall be calculated daily and reconciled post-event.

3. GUARANTEE AND ESCROW
Promoter will deposit AUD $escrow into escrow account
[ESCROW_ACCOUNT_DETAILS] within 72 hours of signing. Escrow funds
will be applied to the Fighter guarantee and final reconciliation.
If escrow is not funded by the deadline, DFC will pause paid activation.

4. PPV INTEGRATION AND SECURITY
PPV platform fees will be deducted before net split. PPV must use
single-use tokens tied to buyer email/phone, device limits (2 devices
default), token expiry at event end, and DRM or tokenized access to
limit sharing. Promoter must provide API or CSV access to PPV sales
within 24 hours of event end.

5. REPORTING AND AUDIT RIGHTS
Promoter will provide daily sales CSVs (tickets and PPV), read-only
access to the ticketing dashboard, and API or dashboard access to PPV
transaction exports. Fighter may audit sales records within 30 days of
final reconciliation with 5 business days notice. Promoter must provide
supporting invoices for any deductions claimed.

6. CAP ON DEDUCTIONS
Only the following may be deducted from Gross Receipts to calculate
Net Event Revenue: ticketing platform fees, payment processing fees,
documented refunds/chargebacks, and pre-approved direct event costs.
Any other deduction requires prior written approval and supporting
invoices.

7. PAYMENT TERMS AND REMEDIES
Promoter pays Fighter within 7 days of event; final reconciliation
within 14 days. Interest accrues at 1.5% per month on overdue amounts.
If Promoter fails to pay within 14 days, Fighter may withhold
promotional assets and pursue recovery.

8. INDEMNITY AND TAKEDOWN
Each party indemnifies the other for claims arising from their own
acts or omissions. Promoter will indemnify Fighter for third-party
claims arising from unauthorized clip use. Takedown requests must be
handled within 24 hours.

9. DISPUTE RESOLUTION
Any dispute will be resolved by arbitration in [City], Australia,
under [governing law]. Costs allocated to the losing party unless
otherwise ordered.
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full contract clauses copied to clipboard'),
        backgroundColor: Color(0xFF00FF88),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final wide = w > 900;

    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 40,
            primaryColor: DesignTokens.neonGold,
            secondaryColor: DesignTokens.neonCyan,
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(child: wide ? _wideLayout() : _narrowLayout()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, a) => Icon(
              Icons.gavel,
              color: Color.lerp(
                DesignTokens.neonGold,
                DesignTokens.neonCyan,
                _pulseAnim.value,
              ),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SLIDING CONTRACT — 85/15',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '4-tier revenue split · escrow · full term sheet export',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.description_outlined,
              color: DesignTokens.neonAmber,
            ),
            tooltip: 'Copy Full Contract Clauses',
            onPressed: _copyFullContract,
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: DesignTokens.neonGold),
            tooltip: 'Copy Term Sheet',
            onPressed: _copyTermSheet,
          ),
        ],
      ),
    );
  }

  Widget _wideLayout() {
    return Row(
      children: [
        Expanded(flex: 5, child: _inputPanel()),
        Expanded(flex: 5, child: _resultsPanel()),
      ],
    );
  }

  Widget _narrowLayout() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [_inputPanel(), const SizedBox(height: 16), _resultsPanel()],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INPUT PANEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _inputPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Presets ──
          _sectionLabel('CONTRACT MODEL PRESET'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_presets.length, (i) {
              final p = _presets[i];
              final sel = i == _selectedPreset;
              return GestureDetector(
                onTap: () => _applyPreset(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? DesignTokens.neonGold.withValues(alpha: 0.15)
                        : DesignTokens.bgCard,
                    border: Border.all(
                      color: sel
                          ? DesignTokens.neonGold
                          : DesignTokens.neonCyan.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      color: sel ? DesignTokens.neonGold : Colors.white70,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // ── Thresholds ──
          _sectionLabel('REVENUE THRESHOLDS (AUD)'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(_t1Ctrl, 'T1', DesignTokens.neonCyan)),
              const SizedBox(width: 12),
              Expanded(child: _field(_t2Ctrl, 'T2', DesignTokens.neonGold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(_t3Ctrl, 'T3', DesignTokens.neonMagenta)),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _guaranteeCtrl,
                  'Guarantee',
                  DesignTokens.neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(_escrowCtrl, 'Escrow Deposit', DesignTokens.neonAmber),

          const SizedBox(height: 20),

          // ── Split sliders ──
          _sectionLabel('FIGHTER SPLIT PER TIER'),
          const SizedBox(height: 8),
          _splitSlider(
            'Tier 1 (0 → T1)',
            _split1Fighter,
            DesignTokens.neonCyan,
            (v) {
              setState(() => _split1Fighter = v);
              _calculate();
            },
          ),
          _splitSlider(
            'Tier 2 (T1 → T2)',
            _split2Fighter,
            DesignTokens.neonGold,
            (v) {
              setState(() => _split2Fighter = v);
              _calculate();
            },
          ),
          _splitSlider(
            'Tier 3 (T2 → T3)',
            _split3Fighter,
            DesignTokens.neonMagenta,
            (v) {
              setState(() => _split3Fighter = v);
              _calculate();
            },
          ),
          _splitSlider(
            'Tier 4 (Above T3)',
            _split4Fighter,
            DesignTokens.neonGreen,
            (v) {
              setState(() => _split4Fighter = v);
              _calculate();
            },
          ),

          const SizedBox(height: 20),

          // ── Revenue slider ──
          _sectionLabel(
            'SIMULATE NET REVENUE: AUD ${_revenueSlider.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: DesignTokens.neonGold,
              inactiveTrackColor: DesignTokens.bgCard,
              thumbColor: DesignTokens.neonGold,
              overlayColor: DesignTokens.neonGold.withValues(alpha: 0.2),
            ),
            child: Slider(
              max: 500000,
              divisions: 500,
              value: _revenueSlider,
              onChanged: (v) {
                setState(() => _revenueSlider = v);
                _calculate();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _splitSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: DesignTokens.bgCard,
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.2),
              ),
              child: Slider(
                min: 10,
                max: 95,
                divisions: 85,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // RESULTS PANEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _resultsPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_calculated) ...[
            _resultCard(),
            const SizedBox(height: 16),
            _tierBreakdownTable(),
            const SizedBox(height: 16),
            _contractClausesCard(),
            const SizedBox(height: 16),
            _negotiationTips(),
          ],
        ],
      ),
    );
  }

  Widget _resultCard() {
    final guarantee = double.tryParse(_guaranteeCtrl.text) ?? 0;
    final isGuaranteeApplied = _totalFighter <= guarantee && guarantee > 0;
    final profitable = _totalFighter > 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
                Icons.gavel,
                color: profitable
                    ? DesignTokens.neonGreen
                    : DesignTokens.neonRed,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'DEAL SUMMARY',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _resultRow(
            'Net Revenue',
            'AUD ${_revenueSlider.toStringAsFixed(0)}',
            Colors.white,
          ),
          _resultRow(
            'Fighter Share (split)',
            'AUD ${_fighterShare.toStringAsFixed(2)}',
            DesignTokens.neonCyan,
          ),
          _resultRow(
            'Promoter Share',
            'AUD ${_promoterShare.toStringAsFixed(2)}',
            DesignTokens.neonGold,
          ),
          if (_tier1Payout > 0)
            _resultRow(
              '  Tier 1 fighter',
              'AUD ${_tier1Payout.toStringAsFixed(2)}',
              Colors.white54,
            ),
          if (_tier2Payout > 0)
            _resultRow(
              '  Tier 2 fighter',
              'AUD ${_tier2Payout.toStringAsFixed(2)}',
              Colors.white54,
            ),
          if (_tier3Payout > 0)
            _resultRow(
              '  Tier 3 fighter',
              'AUD ${_tier3Payout.toStringAsFixed(2)}',
              Colors.white54,
            ),
          if (_tier4Payout > 0)
            _resultRow(
              '  Tier 4 fighter',
              'AUD ${_tier4Payout.toStringAsFixed(2)}',
              Colors.white54,
            ),
          const Divider(color: Colors.white24, height: 24),
          _resultRow(
            isGuaranteeApplied ? 'TOTAL FIGHTER (guarantee)' : 'TOTAL FIGHTER',
            'AUD ${_totalFighter.toStringAsFixed(2)}',
            DesignTokens.neonGold,
            bold: true,
          ),
          _resultRow(
            'Effective Rate',
            '${_effectiveRate.toStringAsFixed(1)}%',
            DesignTokens.neonMagenta,
          ),
          if (isGuaranteeApplied)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Guarantee applied — fighter receives AUD ${guarantee.toStringAsFixed(0)} minimum',
                style: const TextStyle(
                  color: DesignTokens.neonAmber,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierBreakdownTable() {
    final t1 = double.tryParse(_t1Ctrl.text) ?? 0;
    final t2 = double.tryParse(_t2Ctrl.text) ?? 0;
    final t3 = double.tryParse(_t3Ctrl.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIER BREAKDOWN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _tierRow(
            'Tier 1',
            '0 → ${t1.toStringAsFixed(0)}',
            '${(100 - _split1Fighter).toStringAsFixed(0)} / ${_split1Fighter.toStringAsFixed(0)}',
            DesignTokens.neonCyan,
          ),
          _tierRow(
            'Tier 2',
            '${t1.toStringAsFixed(0)} → ${t2.toStringAsFixed(0)}',
            '${(100 - _split2Fighter).toStringAsFixed(0)} / ${_split2Fighter.toStringAsFixed(0)}',
            DesignTokens.neonGold,
          ),
          _tierRow(
            'Tier 3',
            '${t2.toStringAsFixed(0)} → ${t3.toStringAsFixed(0)}',
            '${(100 - _split3Fighter).toStringAsFixed(0)} / ${_split3Fighter.toStringAsFixed(0)}',
            DesignTokens.neonMagenta,
          ),
          _tierRow(
            'Tier 4',
            'Above ${t3.toStringAsFixed(0)}',
            '${(100 - _split4Fighter).toStringAsFixed(0)} / ${_split4Fighter.toStringAsFixed(0)}',
            DesignTokens.neonGreen,
          ),
          const SizedBox(height: 8),
          const Text(
            'Promoter % / Fighter %',
            style: TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _tierRow(String tier, String range, String split, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              tier,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'AUD $range',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              split,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contractClausesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonGold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTRACT CLAUSES (9 SECTIONS)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _clauseItem(
            Icons.attach_money,
            'Net Revenue',
            'Gross tickets + PPV + merch − platform fees − processing − refunds − pre-approved costs',
          ),
          _clauseItem(
            Icons.trending_up,
            'Sliding Split',
            '4-tier piecewise split starting at 85/15 fighter-first',
          ),
          _clauseItem(
            Icons.account_balance,
            'Escrow',
            'AUD ${_escrowCtrl.text} deposited within 72h of signing; pause if unfunded',
          ),
          _clauseItem(
            Icons.timer,
            'Guarantee',
            'AUD ${_guaranteeCtrl.text} applied to escrow and final reconciliation',
          ),
          _clauseItem(
            Icons.shield_outlined,
            'PPV Security',
            'Single-use tokens, 2-device limit, DRM, token expiry at event end',
          ),
          _clauseItem(
            Icons.receipt_long,
            'Reconciliation',
            'Detailed sales CSV within 14 days; interest at 1.5%/mo on late payments',
          ),
          _clauseItem(
            Icons.visibility,
            'Audit Rights',
            'Fighter may audit within 30 days with 5 business days notice',
          ),
          _clauseItem(
            Icons.block,
            'Cap on Deductions',
            'Only platform fees, processing fees, refunds, pre-approved costs; all others need written approval',
          ),
          _clauseItem(
            Icons.security,
            'Reporting',
            'Daily sales CSVs, read-only ticketing + PPV dashboards, Meta pixel access',
          ),
        ],
      ),
    );
  }

  Widget _clauseItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DesignTokens.neonGold, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: desc,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _negotiationTips() {
    const tips = [
      'Open: "We start 85/15 to cover fighter risk. As the event outperforms, the split slides so you capture upside — fair and measurable."',
      'Pilot: "7-day pilot, small spend. You fund ad spend or split 50/50. If pilot hits KPIs we sign the sliding split and scale."',
      'Non-negotiable: "Daily CSVs, read-only pixel/ticketing access, guarantee in escrow before paid activation."',
      'If they push back on 85/15: "We can add a small promoter advance or reduce T1, but the 85/15 floor stays — it covers fighter risk."',
      'Escalation: "No pixel access, no paid activation. No signed terms and escrow by [date], I pause all promotion."',
      'Cap deductions to an explicit short list with invoices — any other deduction needs written approval',
      'Include anti-dilution clause for bulk/partner ticket allocations',
      'Demand escrow funded within 72 hours — if unfunded, pause all paid activation',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: GlassDecoration.card(accent: DesignTokens.neonAmber),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEGOTIATION TACTICS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...tips.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: DesignTokens.neonGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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

  // ═══════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, Color accent) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      onChanged: (_) => _calculate(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: accent.withValues(alpha: 0.7),
          fontSize: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: DesignTokens.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _ContractPreset {
  final String name;
  final double f1, f2, f3, f4, t1, t2, t3;
  const _ContractPreset(
    this.name,
    this.f1,
    this.f2,
    this.f3,
    this.f4,
    this.t1,
    this.t2,
    this.t3,
  );
}
