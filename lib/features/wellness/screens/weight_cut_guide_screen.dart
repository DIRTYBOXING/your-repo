import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WEIGHT CUT GUIDE SCREEN
/// Safe weight cutting for combat athletes — science-backed protocol
/// Calculator · 3-Phase Plan · 4 R's · Safety Checklist · FAQs
/// ═══════════════════════════════════════════════════════════════════════════

// ── Palette ──────────────────────────────────────────────────────────────────
const _bg = Color(0xFF060A0F);
const _card = Color(0xFF0D1520);
const _cardB = Color(0xFF111D2E);
const _cyan = Color(0xFF00E5FF);
const _green = Color(0xFF00E676);
const _amber = Color(0xFFFFD600);
const _red = Color(0xFFFF1744);
const _orange = Color(0xFFFF6D00);
const _purple = Color(0xFF9C6FFF);
const _textPri = Color(0xFFF0F6FF);
const _textSec = Color(0xFF8BADB8);

class WeightCutGuideScreen extends StatefulWidget {
  const WeightCutGuideScreen({super.key});

  @override
  State<WeightCutGuideScreen> createState() => _WeightCutGuideScreenState();
}

class _WeightCutGuideScreenState extends State<WeightCutGuideScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _slideCtrl;

  // ── Calculator state ──────────────────────────────────────────────────────
  final _currWtCtrl = TextEditingController();
  final _goalWtCtrl = TextEditingController();
  int _daysToFight = 14;
  String _activityLevel = 'Moderate';
  _CalcResult? _calcResult;

  // ── Expand state ─────────────────────────────────────────────────────────
  final Set<int> _expandedRisks = {};
  final Set<int> _expandedFaq = {};

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _currWtCtrl.dispose();
    _goalWtCtrl.dispose();
    super.dispose();
  }

  // ── Calculator logic ──────────────────────────────────────────────────────
  void _calculate() {
    final curr = double.tryParse(_currWtCtrl.text);
    final goal = double.tryParse(_goalWtCtrl.text);
    if (curr == null || goal == null || curr <= 0 || goal <= 0) return;
    if (goal >= curr) {
      setState(() => _calcResult = _CalcResult.nocut());
      return;
    }
    final totalKg = curr - goal;
    final pct = (totalKg / curr) * 100;
    final safeDaily = curr * 0.01; // 1 % / day guideline
    final minDays = (totalKg / safeDaily).ceil();
    String phase = 'FOUNDATION';
    Color phaseColor = _green;
    String advice = '';
    if (pct <= 3) {
      phase = 'SAFE';
      phaseColor = _green;
      advice =
          'This is a manageable cut. Focus on low-sodium meals and '
          'controlled fluid reduction in fight week.';
    } else if (pct <= 7) {
      phase = 'MODERATE RISK';
      phaseColor = _amber;
      advice =
          'Manageable with proper planning. Start foundation phase '
          '6–8 weeks out. Avoid last-minute dehydration.';
    } else if (pct <= 10) {
      phase = 'HIGH RISK';
      phaseColor = _orange;
      advice =
          'Aggressive cut. Prioritise fat loss now, not fight week. '
          'Consult a sports nutritionist immediately.';
    } else {
      phase = 'EXTREME — AVOID';
      phaseColor = _red;
      advice =
          'Cuts > 10 % body mass carry serious medical risk including '
          'kidney failure and cardiac arrest. Reconsider weight class.';
    }
    final dailyWater = _activityLevel == 'Light'
        ? 30.0
        : _activityLevel == 'Moderate'
        ? 35.0
        : 40.0;
    setState(() {
      _calcResult = _CalcResult(
        totalKg: totalKg,
        pct: pct,
        safeMinDays: minDays,
        riskPhase: phase,
        riskColor: phaseColor,
        advice: advice,
        dailyWaterMl: (curr * dailyWater).round(),
        calorieDeficit: pct <= 5 ? '300–500 kcal/day' : '500–700 kcal/day',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _medicalDisclaimer(),
                const SizedBox(height: 20),
                _sectionHeader('⚖️ WEIGHT CUT CALCULATOR'),
                const SizedBox(height: 12),
                _buildCalculator(),
                if (_calcResult != null) ...[
                  const SizedBox(height: 16),
                  _buildCalcResult(_calcResult!),
                ],
                const SizedBox(height: 28),
                _sectionHeader('⚠️ REAL RISKS — KNOW BEFORE YOU CUT'),
                const SizedBox(height: 12),
                ..._risks.asMap().entries.map((e) => _riskCard(e.key, e.value)),
                const SizedBox(height: 28),
                _sectionHeader('📋 3-PHASE PROTOCOL'),
                const SizedBox(height: 12),
                _phaseCard(
                  phase: '1',
                  title: 'FOUNDATION PHASE',
                  timing: '6–8 Weeks Out',
                  color: _green,
                  points: [
                    '300–500 kcal daily deficit — trim body fat, not muscle',
                    'Monthly DEXA scans — quantify fat vs lean mass',
                    'Maintain strength & conditioning — body recomposition',
                    'Establish baseline hydration: 35–40 mL/kg per day',
                  ],
                ),
                const SizedBox(height: 12),
                _phaseCard(
                  phase: '2',
                  title: 'FIGHT-WEEK BLUEPRINT',
                  timing: '10–2 Days Out',
                  color: _amber,
                  points: [
                    'Days 10–7: Normal carbs (4–5g/kg), normal sodium & fiber',
                    'Days 6–4: Reduce carbs to 3g/kg, sodium/fiber ↓30–50%',
                    'Day 3: Carbs 2g/kg, fluids 25 mL/kg, light sweat session',
                    'Day 2: Carbs 1g/kg, fluids 20 mL/kg, rest or very light',
                  ],
                ),
                const SizedBox(height: 12),
                _phaseCard(
                  phase: '3',
                  title: 'LAST-24H ACUTE CUT',
                  timing: 'Day of Weigh-In',
                  color: _orange,
                  points: [
                    'Hot-bath cycles: 10 min in / 10 min out — SUPERVISED ONLY',
                    'Sweat suits require extreme caution — ACSM discourages solo use',
                    'No laxatives or prescription diuretics without medical supervision',
                    'STOP if dizziness, cramping, or confusion — seek medical help',
                  ],
                ),
                const SizedBox(height: 28),
                _sectionHeader('🍊 FIGHT-WEEK BLUEPRINT TABLE'),
                const SizedBox(height: 12),
                _fightWeekTable(),
                const SizedBox(height: 28),
                _sectionHeader('💧 THE 4 R\'s — REHYDRATION PROTOCOL'),
                const SizedBox(height: 12),
                ..._fourRs.map(_rProtocolCard),
                const SizedBox(height: 28),
                _sectionHeader('✅ SAFETY CHECKLIST'),
                const SizedBox(height: 12),
                _safetyChecklist(),
                const SizedBox(height: 28),
                _sectionHeader('❓ FAQs'),
                const SizedBox(height: 12),
                ..._faqs.asMap().entries.map((e) => _faqTile(e.key, e.value)),
                const SizedBox(height: 28),
                _dfcConnectBanner(context),
                const SizedBox(height: 16),
                _sourceNote(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _bg,
      leading: const BackButton(color: _cyan),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Animated background grid
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) =>
                  CustomPaint(painter: _WeightCutBgPainter(_pulseCtrl.value)),
            ),
            // Overlay gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), _bg],
                ),
              ),
            ),
            // Title content
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _cyan.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _cyan.withAlpha(100),
                          ),
                        ),
                        child: const Text(
                          'COMBAT SPORTS SCIENCE',
                          style: TextStyle(
                            color: _cyan,
                            fontSize: 10,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'WEIGHT CUTTING',
                    style: TextStyle(
                      color: _textPri,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Text(
                    'Safe Guide for Combat Athletes',
                    style: TextStyle(
                      color: _textSec,
                      fontSize: 14,
                      letterSpacing: 0.5,
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

  // ── Medical Disclaimer ────────────────────────────────────────────────────
  Widget _medicalDisclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _red.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _red.withAlpha(100)),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_information_outlined, color: _red, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Medical Disclaimer: For educational purposes only. Not a substitute '
              'for professional medical advice. Consult a qualified healthcare provider '
              'before significant diet or exercise changes.',
              style: TextStyle(color: _red, fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calculator ────────────────────────────────────────────────────────────
  Widget _buildCalculator() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _calcField(
                  ctrl: _currWtCtrl,
                  label: 'Current Weight (kg)',
                  icon: Icons.scale_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _calcField(
                  ctrl: _goalWtCtrl,
                  label: 'Fight Weight (kg)',
                  icon: Icons.flag_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Days Until Weigh-In',
            style: TextStyle(color: _textSec, fontSize: 12, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _daysToFight.toDouble(),
                  min: 1,
                  max: 84,
                  divisions: 83,
                  activeColor: _cyan,
                  inactiveColor: _cyan.withAlpha(40),
                  onChanged: (v) => setState(() => _daysToFight = v.round()),
                ),
              ),
              Container(
                width: 50,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _cyan.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$_daysToFight',
                  style: const TextStyle(
                    color: _cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'days',
                style: TextStyle(color: _textSec, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Activity Level',
            style: TextStyle(color: _textSec, fontSize: 12, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Light', 'Moderate', 'Intense'].map((level) {
              final sel = _activityLevel == level;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activityLevel = level),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _cyan.withAlpha(40) : _cardB,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? _cyan : _cyan.withAlpha(30),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      level,
                      style: TextStyle(
                        color: sel ? _cyan : _textSec,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _cyan,
                foregroundColor: _bg,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'CALCULATE MY CUT PLAN',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSec,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: _textPri, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: _cyan, size: 18),
            hintText: '0.0',
            hintStyle: const TextStyle(color: Color(0xFF3A5060), fontSize: 15),
            filled: true,
            fillColor: _cardB,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _cyan.withAlpha(50)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _cyan.withAlpha(40)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _cyan, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // ── Calculator Result ─────────────────────────────────────────────────────
  Widget _buildCalcResult(_CalcResult r) {
    if (r.nocut) {
      return _infoBox(
        _green,
        Icons.check_circle_outline,
        'Already at Fight Weight',
        'Your current weight equals or is below fight weight. '
            'Focus on nutrition and peak performance instead.',
      );
    }
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: r.riskColor.withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.riskColor.withAlpha(120), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: r.riskColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  r.riskPhase,
                  style: TextStyle(
                    color: r.riskColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _resultMetric(
                'Total Cut',
                '${r.totalKg.toStringAsFixed(1)} kg',
                r.riskColor,
              ),
              const SizedBox(width: 12),
              _resultMetric(
                'Body Mass',
                '${r.pct.toStringAsFixed(1)}%',
                r.riskColor,
              ),
              const SizedBox(width: 12),
              _resultMetric('Min Days', '${r.safeMinDays}d', _cyan),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _resultMetric('Daily Water', '${r.dailyWaterMl} mL', _cyan),
              const SizedBox(width: 12),
              _resultMetric('Calorie Deficit', r.calorieDeficit, _green),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            r.advice,
            style: const TextStyle(color: _textSec, fontSize: 13, height: 1.5),
          ),
          if (r.pct > 3) ...[
            const SizedBox(height: 12),
            _infoBox(
              _cyan,
              Icons.tips_and_updates_outlined,
              '1% Daily Limit Rule',
              'Sports science recommends ≤ 1% body mass loss per day to '
                  'preserve performance and minimise medical risk. '
                  'You need at least ${r.safeMinDays} days for this cut.',
            ),
          ],
          if (_daysToFight < r.safeMinDays) ...[
            const SizedBox(height: 10),
            _infoBox(
              _red,
              Icons.warning_amber_rounded,
              'NOT ENOUGH TIME',
              'At $_daysToFight days you cannot safely lose '
                  '${r.totalKg.toStringAsFixed(1)} kg. '
                  'Consult your coach and nutritionist immediately.',
            ),
          ] else ...[
            const SizedBox(height: 10),
            _infoBox(
              _green,
              Icons.check_circle_outline,
              'Timeline OK',
              '$_daysToFight days is sufficient for this cut at the 1% daily guideline.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultMetric(String label, String val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: col.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                color: col,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: _textSec, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Risk Cards ────────────────────────────────────────────────────────────
  Widget _riskCard(int idx, _RiskItem r) {
    final exp = _expandedRisks.contains(idx);
    return GestureDetector(
      onTap: () => setState(
        () => exp ? _expandedRisks.remove(idx) : _expandedRisks.add(idx),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: r.color.withAlpha(exp ? 120 : 50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(r.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    r.title,
                    style: const TextStyle(
                      color: _textPri,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  exp ? Icons.expand_less : Icons.expand_more,
                  color: _textSec,
                  size: 20,
                ),
              ],
            ),
            if (exp) ...[
              const SizedBox(height: 10),
              Text(
                r.detail,
                style: const TextStyle(
                  color: _textSec,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              if (r.stat != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: r.color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: r.color.withAlpha(80)),
                  ),
                  child: Text(
                    r.stat!,
                    style: TextStyle(
                      color: r.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ── Phase Cards ───────────────────────────────────────────────────────────
  Widget _phaseCard({
    required String phase,
    required String title,
    required String timing,
    required Color color,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  phase,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      timing,
                      style: const TextStyle(color: _textSec, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        color: _textSec,
                        fontSize: 13,
                        height: 1.5,
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

  // ── Fight Week Table ──────────────────────────────────────────────────────
  Widget _fightWeekTable() {
    const headers = ['Days Out', 'Carb g/kg', 'Sodium', 'Fluids', 'Training'];
    const rows = [
      ['10–7', '4–5', 'Normal', '35 mL/kg', 'Full volume'],
      ['6–4', '3', '↓30%', '30 mL/kg', 'Taper'],
      ['3', '2', '↓50%', '25 mL/kg', 'Light sweat'],
      ['2', '1', '↓70%', '20 mL/kg', 'Rest/light'],
    ];
    final rowColors = [_green, _amber, _orange, _red];

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withAlpha(50)),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _cyan.withAlpha(25),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: headers
                  .map(
                    (h) => Expanded(
                      child: Text(
                        h,
                        style: const TextStyle(
                          color: _cyan,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          // Data rows
          ...rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final color = rowColors[i];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: i.isOdd ? _cardB : _card,
                borderRadius: i == rows.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(14))
                    : null,
                border: Border(
                  top: BorderSide(color: _cyan.withAlpha(20), width: 0.5),
                ),
              ),
              child: Row(
                children: row.asMap().entries.map((e) {
                  final isFirst = e.key == 0;
                  return Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isFirst ? color : _textSec,
                        fontSize: 11,
                        fontWeight: isFirst
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 4 R Protocol Cards ────────────────────────────────────────────────────
  Widget _rProtocolCard(_RProtocol r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: r.color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: r.color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              r.letter,
              style: TextStyle(
                color: r.color,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: TextStyle(
                    color: r.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  r.detail,
                  style: const TextStyle(
                    color: _textSec,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Safety Checklist ──────────────────────────────────────────────────────
  Widget _safetyChecklist() {
    const items = [
      'Doctor clearance and baseline bloodwork (8 weeks out)',
      'Written plan reviewed by a credentialed sports nutritionist',
      'Minimum 6 hours sleep nightly during cut',
      'Urine color: aim for pale straw except final 12 h',
      'No solo sauna sessions — bring a teammate',
      'Emergency contacts and oral rehydration solution on site',
      'Stop if: dizziness, cramping, confusion, chest pain',
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withAlpha(80)),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: _green, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: _textSec,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── FAQ Tiles ─────────────────────────────────────────────────────────────
  Widget _faqTile(int idx, _FAQ faq) {
    final exp = _expandedFaq.contains(idx);
    return GestureDetector(
      onTap: () => setState(
        () => exp ? _expandedFaq.remove(idx) : _expandedFaq.add(idx),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cyan.withAlpha(exp ? 100 : 40)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq.q,
                    style: TextStyle(
                      color: exp ? _cyan : _textPri,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  exp ? Icons.expand_less : Icons.expand_more,
                  color: _textSec,
                  size: 18,
                ),
              ],
            ),
            if (exp) ...[
              const SizedBox(height: 10),
              Text(
                faq.a,
                style: const TextStyle(
                  color: _textSec,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Source Note ───────────────────────────────────────────────────────────
  Widget _sourceNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cyan.withAlpha(30)),
      ),
      child: const Text(
        'Sources: Science for Sport · ISSN · Gatorade SSE · ACSM · PubMed · '
        'MMAFighting · Human Brain Mapping · Frontiers in Nutrition · '
        'ONE Championship Medical Guidelines',
        style: TextStyle(color: _textSec, fontSize: 11, height: 1.6),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  // ── DFC Smart Devices Connect Banner ─────────────────────────────────────
  Widget _dfcConnectBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001830), Color(0xFF060A0F)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cyan.withAlpha(100), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('📡', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 10),
          const Text(
            'CONNECT YOUR DEVICES TO DFC',
            style: TextStyle(
              color: _cyan,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your weight cut in real time with Garmin Fenix 8, WHOOP, Oura, '
            'Apple Health, Google Fit, smart scales, CGM blood glucose monitors, '
            'and more. All your biometrics in one fighter dashboard.',
            style: TextStyle(color: _textSec, fontSize: 12, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _devicePill('⌚ Garmin Fenix 8'),
              _devicePill('💪 WHOOP 5.0'),
              _devicePill('💍 Oura Ring 4'),
              _devicePill('🍎 Apple Health'),
              _devicePill('🟢 Google Fit'),
              _devicePill('⚖️ Smart Scale'),
              _devicePill('💉 CGM Glucose'),
              _devicePill('🧬 Astroskin'),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => context.push('/smart-devices'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_cyan, Color(0xFF4FC3F7)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'OPEN SMART DEVICES HUB',
                    style: TextStyle(
                      color: Color(0xFF060A0F),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.sensors, color: Color(0xFF060A0F), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _devicePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cyan.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withAlpha(60)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _cyan,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _cyan,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _infoBox(Color col, IconData icon, String title, String body) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: col, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: col,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: _textSec,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _CalcResult {
  final double totalKg;
  final double pct;
  final int safeMinDays;
  final String riskPhase;
  final Color riskColor;
  final String advice;
  final int dailyWaterMl;
  final String calorieDeficit;
  final bool nocut;

  _CalcResult({
    required this.totalKg,
    required this.pct,
    required this.safeMinDays,
    required this.riskPhase,
    required this.riskColor,
    required this.advice,
    required this.dailyWaterMl,
    required this.calorieDeficit,
    this.nocut = false,
  });

  factory _CalcResult.nocut() => _CalcResult(
    totalKg: 0,
    pct: 0,
    safeMinDays: 0,
    riskPhase: '',
    riskColor: Colors.transparent,
    advice: '',
    dailyWaterMl: 0,
    calorieDeficit: '',
    nocut: true,
  );
}

class _RiskItem {
  final String emoji;
  final String title;
  final String detail;
  final String? stat;
  final Color color;
  const _RiskItem({
    required this.emoji,
    required this.title,
    required this.detail,
    this.stat,
    required this.color,
  });
}

class _RProtocol {
  final String letter;
  final String title;
  final String detail;
  final Color color;
  const _RProtocol({
    required this.letter,
    required this.title,
    required this.detail,
    required this.color,
  });
}

class _FAQ {
  final String q;
  final String a;
  const _FAQ(this.q, this.a);
}

const _risks = [
  _RiskItem(
    emoji: '🔥',
    title: 'Acute Dehydration',
    detail:
        'Dehydration increases the likelihood of heat illness, kidney injury, '
        'and electrolyte imbalance. Cardiac arrest has occurred in combat sports '
        'fighters attempting extreme water cuts without supervision.',
    stat:
        'Cutting > 5–8% body mass in < 7 days consistently impairs performance and '
        'elevates cardiovascular risk (Science for Sport, PubMed)',
    color: _red,
  ),
  _RiskItem(
    emoji: '🧠',
    title: 'Increased Brain Injury Risk',
    detail:
        'Reduced cerebrospinal fluid volume from dehydration may amplify brain-injury '
        'risk during head impacts. This is particularly dangerous in boxing and MMA '
        'where concussive forces are regular.',
    stat:
        'Dehydrated fighters show measurable reduction in CSF cushioning — '
        'Human Brain Mapping research confirms elevated head trauma vulnerability',
    color: _orange,
  ),
  _RiskItem(
    emoji: '💪',
    title: 'Power & Endurance Loss',
    detail:
        'Severe glycogen depletion from extreme carb restriction blunts striking '
        'power and repeated high-intensity output. Fight night performance suffers '
        'even after partial rehydration.',
    stat:
        'Glycogen-depleted fighters show 10–15% reduction in high-intensity work '
        'capacity — Frontiers in Nutrition',
    color: _amber,
  ),
  _RiskItem(
    emoji: '⚖️',
    title: 'Sanction & Rule Violations',
    detail:
        'ONE Championship bans dehydration-based cutting entirely. The California SAC '
        'cancels bouts if a fighter is > 15% above contract weight on fight day. '
        'Violations can lead to fines, suspensions, and license revocation.',
    stat:
        'Multiple promotions worldwide are adopting hydration testing protocols '
        'and same-day weigh-ins to eliminate extreme cuts',
    color: _purple,
  ),
  _RiskItem(
    emoji: '🔄',
    title: 'Chronic Yo-Yo Cutting',
    detail:
        'Repeated severe cuts correlate with disordered eating, hormonal disruption, '
        'and long-term metabolic damage. Female fighters face higher risk of '
        'menstrual irregularities and bone density loss.',
    stat:
        'Conservative ceiling for female athletes: ≤ 5% body mass in 7 days '
        'to minimise hormonal disruption — Science for Sport',
    color: _red,
  ),
  _RiskItem(
    emoji: '🫀',
    title: 'Blood Pressure Spike',
    detail:
        'Acute dehydration during weight cuts causes blood volume drop, forcing the '
        'heart to work harder. This directly elevates blood pressure and can trigger '
        'hypertensive episodes — especially dangerous during same-day weigh-ins. '
        'Apple Watch Series 9+ now offers TGA-approved 30-day hypertension monitoring '
        'to catch elevated BP patterns before they become a crisis.',
    stat:
        'Apple Watch hypertension screening: 41% sensitivity / 95% specificity — '
        'TGA approved Australia Feb 2026. Monitor BP before every weight cut.',
    color: _red,
  ),
];

final _fourRs = [
  const _RProtocol(
    letter: 'R',
    title: 'REPLACE Fluids',
    detail:
        'Drink 150% of weight lost within 6 hours. '
        'Lose 2 kg? Drink 3 litres. Prioritise quick-absorbing electrolyte drinks '
        'over plain water to avoid dilutional hyponatremia.',
    color: _cyan,
  ),
  const _RProtocol(
    letter: 'R',
    title: 'RESTORE Electrolytes',
    detail:
        'Target 1,500–2,000 mg sodium plus potassium, calcium, and magnesium. '
        'Sports drink + snack (pretzels / banana) covers most needs. Avoid pure '
        'water only as it can dangerously dilute blood sodium.',
    color: _green,
  ),
  const _RProtocol(
    letter: 'R',
    title: 'REFILL Glycogen',
    detail:
        'Consume 8–10 g carbohydrate/kg over 24 hours post weigh-in. '
        'White rice, pasta, bananas, sports gels, and fruit juice are ideal. '
        'Start within 30 minutes of stepping off the scale.',
    color: _amber,
  ),
  const _RProtocol(
    letter: 'R',
    title: 'REPAIR Muscles',
    detail:
        'Target ~0.4 g protein/kg every 3–4 hours. '
        'Lean chicken, Greek yoghurt, protein shakes. Combine with carbs '
        'for optimal glycogen resynthesis and muscle recovery before competition.',
    color: _orange,
  ),
];

const _faqs = [
  _FAQ(
    'How long does it take to safely cut 5 pounds?',
    'With controlled water manipulation, most athletes can shed 5 lb (2.3 kg) in '
        '24–48 h, but faster efforts spike dehydration risk. At the 1% daily guideline '
        'for a 77 kg fighter, that\'s about 3–5 days minimum.',
  ),
  _FAQ(
    'What\'s the safest way to drop water weight fast?',
    'Combine low-sodium meals, controlled fluid restriction, and light exercise '
        'under professional supervision. Hot-bath cycles (10 min in / 10 min out) '
        'can accelerate loss but must be supervised. Never use diuretics unless '
        'medically prescribed.',
  ),
  _FAQ(
    'Can women follow the same protocols?',
    'Yes — but with key modifications. Female athletes should target ≤ 5% body mass '
        'cut over 7 days to account for menstrual-cycle water shifts and minimise '
        'hormonal disruption. Always factor in cycle phase when planning fight week.',
  ),
  _FAQ(
    'Do I need supplements for rehydration?',
    'Key components: electrolyte mix (sodium, potassium, magnesium) and easily absorbed '
        'carbs (maltodextrin, glucose). Optional: creatine helps replenish intracellular '
        'water post weigh-in. Avoid excessive caffeine — it\'s a mild diuretic.',
  ),
  _FAQ(
    'What weight class should I actually be fighting at?',
    'Your "walking weight" (off-season weight) should ideally be within 5–7% of your '
        'fight weight. If you\'re regularly cutting more than 8–10%, strongly consider '
        'moving up a class. Long-term health always outweighs short-term advantage.',
  ),
  _FAQ(
    'When should I stop the cut and seek help?',
    'STOP immediately and seek medical attention if you experience: severe dizziness, '
        'muscle cramps that won\'t resolve, confusion or disorientation, dark brown urine, '
        'heart palpitations, or you cannot keep fluids down.',
  ),
];

// ── Background Painter ────────────────────────────────────────────────────────
class _WeightCutBgPainter extends CustomPainter {
  final double t;
  _WeightCutBgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;

    // Draw animated grid lines
    for (int i = 0; i < 6; i++) {
      final progress = (t + i * 0.15) % 1.0;
      paint.color = const Color(
        0xFF00E5FF,
      ).withAlpha((20 + 30 * math.sin(progress * math.pi)).round());
      paint.strokeWidth = 0.5;
      final y = size.height * progress;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw scale circles
    for (int i = 0; i < 3; i++) {
      final r = 40.0 + i * 30 + 20 * math.sin(t * math.pi * 2 + i);
      paint.color = const Color(0xFF00E5FF).withAlpha(15 - i * 4);
      paint.strokeWidth = 1;
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.35),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WeightCutBgPainter old) => old.t != t;
}
