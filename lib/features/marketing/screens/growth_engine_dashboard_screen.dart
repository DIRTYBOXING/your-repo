import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_cosmetic_widgets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// GROWTH ENGINE DASHBOARD — Experiments, retargeting, KPIs, viral hooks
/// ═══════════════════════════════════════════════════════════════════════════

class GrowthEngineDashboardScreen extends StatefulWidget {
  const GrowthEngineDashboardScreen({super.key});

  @override
  State<GrowthEngineDashboardScreen> createState() =>
      _GrowthEngineDashboardScreenState();
}

class _GrowthEngineDashboardScreenState
    extends State<GrowthEngineDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseAnim;
  int _activeTab = 0;

  // ── KPI fields ──
  double _adSpend = 1000;
  double _ticketRevenue = 12000;
  double _ppvRevenue = 4500;
  int _impressions = 85000;
  int _clicks = 3200;
  int _conversions = 142;

  // ── Experiment matrix: 3 creatives × 2 audiences × 2 placements ──
  final List<_Experiment> _experiments = [
    const _Experiment(
      'Video 15s',
      'Fight fans 18-34',
      'FB Feed',
      ctr: 3.2,
      cvr: 2.1,
      spend: 150,
    ),
    const _Experiment(
      'Video 15s',
      'Fight fans 18-34',
      'IG Reels',
      ctr: 4.1,
      cvr: 2.8,
      spend: 150,
    ),
    const _Experiment(
      'Video 15s',
      'Local 25km',
      'FB Feed',
      ctr: 2.5,
      cvr: 1.6,
      spend: 100,
    ),
    const _Experiment(
      'Video 15s',
      'Local 25km',
      'IG Reels',
      ctr: 3.8,
      cvr: 2.3,
      spend: 100,
    ),
    const _Experiment(
      'Static Poster',
      'Fight fans 18-34',
      'FB Feed',
      ctr: 1.8,
      cvr: 1.2,
      spend: 80,
    ),
    const _Experiment(
      'Static Poster',
      'Fight fans 18-34',
      'IG Reels',
      ctr: 2.1,
      cvr: 1.5,
      spend: 80,
    ),
    const _Experiment(
      'Static Poster',
      'Local 25km',
      'FB Feed',
      ctr: 1.4,
      cvr: 0.9,
      spend: 60,
    ),
    const _Experiment(
      'Static Poster',
      'Local 25km',
      'IG Reels',
      ctr: 1.9,
      cvr: 1.1,
      spend: 60,
    ),
    const _Experiment(
      'Carousel UGC',
      'Fight fans 18-34',
      'FB Feed',
      ctr: 2.6,
      cvr: 1.8,
      spend: 70,
    ),
    const _Experiment(
      'Carousel UGC',
      'Fight fans 18-34',
      'IG Reels',
      ctr: 3.5,
      cvr: 2.4,
      spend: 70,
    ),
    const _Experiment(
      'Carousel UGC',
      'Local 25km',
      'FB Feed',
      ctr: 2.0,
      cvr: 1.3,
      spend: 50,
    ),
    const _Experiment(
      'Carousel UGC',
      'Local 25km',
      'IG Reels',
      ctr: 2.9,
      cvr: 1.9,
      spend: 50,
    ),
  ];

  // ── Retargeting funnel ──
  final List<_RetargetStage> _funnel = [
    const _RetargetStage(
      '0–3 days',
      'Video viewers 3s/10s/25%',
      'Lookalike + interest',
      DesignTokens.neonCyan,
      85000,
    ),
    const _RetargetStage(
      '3–7 days',
      'Site visitors + add-to-cart',
      'Dynamic product ads',
      DesignTokens.neonGold,
      12000,
    ),
    const _RetargetStage(
      '7–30 days',
      'Checkout abandoners',
      'Urgency creative + discount',
      DesignTokens.neonMagenta,
      3400,
    ),
    const _RetargetStage(
      'Last 72h',
      'All warm + SMS + email',
      'Final push: last chance',
      DesignTokens.neonRed,
      1800,
    ),
  ];

  // ── Viral hooks library ──
  final List<_ViralHook> _hooks = [
    const _ViralHook(
      'Tag a mate who owes you a night out — 2 free PPV codes',
      'UGC / engagement',
      Icons.people,
    ),
    const _ViralHook(
      'Share this post + follow for a chance at ringside seats',
      'Giveaway',
      Icons.card_giftcard,
    ),
    const _ViralHook(
      '"This knockout was INSANE" — watch the full card live',
      'Curiosity gap',
      Icons.whatshot,
    ),
    const _ViralHook(
      'Only 50 VIP tickets left — who are you bringing?',
      'Scarcity',
      Icons.timer,
    ),
    const _ViralHook(
      'POV: You just bought ringside tickets to Townsville',
      'TikTok trend',
      Icons.music_note,
    ),
    const _ViralHook(
      'Comment your prediction — winner gets free merch',
      'Prediction',
      Icons.emoji_events,
    ),
    const _ViralHook(
      'Show this to someone who thinks they can fight',
      'Challenge',
      Icons.sports_mma,
    ),
    const _ViralHook(
      '24 hours until fight night — are you ready?',
      'Countdown urgency',
      Icons.access_alarm,
    ),
  ];

  // ── Micro-influencers ──
  final List<_Influencer> _influencers = [
    const _Influencer(
      'Local Gym Partner 1',
      '@gym_partner_1',
      'Promo code: DFC10',
      sales: 0,
      reached: 0,
    ),
    const _Influencer(
      'Local Gym Partner 2',
      '@gym_partner_2',
      'Promo code: DFC15',
      sales: 0,
      reached: 0,
    ),
    const _Influencer(
      'Fight Blogger',
      '@fight_blogger',
      'Promo code: DFCBLOG',
      sales: 0,
      reached: 0,
    ),
    const _Influencer(
      'Local Radio Host',
      '@radio_host',
      'Promo code: DFCRADIO',
      sales: 0,
      reached: 0,
    ),
    const _Influencer(
      'Fighter Fan Account',
      '@fan_account',
      'Promo code: DFCFAN',
      sales: 0,
      reached: 0,
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
    super.dispose();
  }

  double get _roas =>
      _adSpend > 0 ? (_ticketRevenue + _ppvRevenue) / _adSpend : 0;
  double get _ctr => _impressions > 0 ? (_clicks / _impressions) * 100 : 0;
  double get _cvr => _clicks > 0 ? (_conversions / _clicks) * 100 : 0;
  double get _cpp => _conversions > 0 ? _adSpend / _conversions : 0;

  void _copyDailySnapshot() {
    final text =
        '''DFC GROWTH ENGINE — DAILY SNAPSHOT
${'=' * 50}

AD SPEND:       \$${_adSpend.toStringAsFixed(0)}
TICKET REVENUE: \$${_ticketRevenue.toStringAsFixed(0)}
PPV REVENUE:    \$${_ppvRevenue.toStringAsFixed(0)}
TOTAL REVENUE:  \$${(_ticketRevenue + _ppvRevenue).toStringAsFixed(0)}

IMPRESSIONS:    $_impressions
CLICKS:         $_clicks
CONVERSIONS:    $_conversions

CTR:            ${_ctr.toStringAsFixed(2)}%
CVR:            ${_cvr.toStringAsFixed(2)}%
CPP:            \$${_cpp.toStringAsFixed(2)}
ROAS:           ${_roas.toStringAsFixed(1)}x

EXPERIMENT WINNERS (top 3 by CVR):
${_topExperiments()}

RETARGETING FUNNEL:
${_funnelSummary()}
''';
    Clipboard.setData(ClipboardData(text: text));
    _snack('Daily snapshot copied');
  }

  String _topExperiments() {
    final sorted = List<_Experiment>.from(_experiments)
      ..sort((a, b) => b.cvr.compareTo(a.cvr));
    final buf = StringBuffer();
    for (var i = 0; i < 3 && i < sorted.length; i++) {
      final e = sorted[i];
      buf.writeln(
        '  ${i + 1}. ${e.creative} / ${e.audience} / ${e.placement} — CTR ${e.ctr}% CVR ${e.cvr}%',
      );
    }
    return buf.toString();
  }

  String _funnelSummary() {
    final buf = StringBuffer();
    for (final s in _funnel) {
      buf.writeln('  ${s.window}: ${s.audience} → ${s.reach} reach');
    }
    return buf.toString();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF00FF88)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: Stack(
        children: [
          const DFCCosmicBackground(
            particleCount: 40,
            primaryColor: DesignTokens.neonGold,
            secondaryColor: DesignTokens.neonRed,
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                _tabBar(),
                Expanded(child: _tabBody()),
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
              Icons.rocket_launch,
              color: Color.lerp(
                DesignTokens.neonGold,
                DesignTokens.neonRed,
                _pulseAnim.value,
              ),
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GROWTH ENGINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Experiments · Retargeting · KPIs · Viral · Influencers',
                  style: TextStyle(
                    color: DesignTokens.textMuted.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: DesignTokens.neonGold),
            tooltip: 'Copy daily snapshot',
            onPressed: _copyDailySnapshot,
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    const tabs = ['KPIs', 'Experiments', 'Retargeting', 'Viral', 'Influencers'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final sel = i == _activeTab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = i),
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
                        : DesignTokens.neonGold.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: sel ? DesignTokens.neonGold : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tabBody() {
    switch (_activeTab) {
      case 0:
        return _kpiTab();
      case 1:
        return _experimentsTab();
      case 2:
        return _retargetingTab();
      case 3:
        return _viralTab();
      case 4:
        return _influencersTab();
      default:
        return _kpiTab();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 0: KPIs
  // ═══════════════════════════════════════════════════════════════════════

  Widget _kpiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('REAL‑TIME METRICS'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'ROAS',
                '${_roas.toStringAsFixed(1)}x',
                DesignTokens.neonGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                'CTR',
                '${_ctr.toStringAsFixed(2)}%',
                DesignTokens.neonCyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'CVR',
                '${_cvr.toStringAsFixed(2)}%',
                DesignTokens.neonGold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                'CPP',
                '\$${_cpp.toStringAsFixed(2)}',
                DesignTokens.neonMagenta,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                'Ad Spend',
                '\$${_adSpend.toStringAsFixed(0)}',
                DesignTokens.neonAmber,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiCard(
                'Total Rev',
                '\$${(_ticketRevenue + _ppvRevenue).toStringAsFixed(0)}',
                DesignTokens.neonGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel('ADJUST INPUTS'),
        const SizedBox(height: 10),
        _sliderRow('Ad Spend (AUD)', _adSpend, 0, 10000, (v) {
          setState(() => _adSpend = v);
        }),
        _sliderRow('Ticket Revenue', _ticketRevenue, 0, 100000, (v) {
          setState(() => _ticketRevenue = v);
        }),
        _sliderRow('PPV Revenue', _ppvRevenue, 0, 50000, (v) {
          setState(() => _ppvRevenue = v);
        }),
        _numRow('Impressions', _impressions, (v) {
          setState(() => _impressions = v);
        }),
        _numRow('Clicks', _clicks, (v) {
          setState(() => _clicks = v);
        }),
        _numRow('Conversions', _conversions, (v) {
          setState(() => _conversions = v);
        }),
        const SizedBox(height: 16),
        _sectionLabel('PAID STRATEGY MATRIX'),
        const SizedBox(height: 8),
        _strategyRow(
          'Phase 1 (Days 1–3)',
          'AUD 300 — 3 creatives × 2 audiences × 2 placements',
          DesignTokens.neonCyan,
        ),
        _strategyRow(
          'Phase 2 (Days 4–7)',
          'AUD 400 — kill losers, scale winners 2×',
          DesignTokens.neonGold,
        ),
        _strategyRow(
          'Phase 3 (Last 72h)',
          'AUD 300 — retargeting + SMS + email blitz',
          DesignTokens.neonRed,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 1: EXPERIMENTS (3×2×2 matrix)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _experimentsTab() {
    final sorted = List<_Experiment>.from(_experiments)
      ..sort((a, b) => b.cvr.compareTo(a.cvr));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel(
          '3×2×2 EXPERIMENT MATRIX (${_experiments.length} variants)',
        ),
        const SizedBox(height: 4),
        const Text(
          '3 creatives × 2 audiences × 2 placements — sorted by CVR',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 12),
        ...sorted.map((e) {
          final isWinner = sorted.indexOf(e) < 3;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isWinner
                    ? DesignTokens.neonGreen.withValues(alpha: 0.06)
                    : DesignTokens.bgCard,
                border: Border.all(
                  color: isWinner
                      ? DesignTokens.neonGreen.withValues(alpha: 0.5)
                      : DesignTokens.neonGold.withValues(alpha: 0.15),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (isWinner)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.emoji_events,
                        color: DesignTokens.neonGold,
                        size: 16,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.creative} → ${e.audience}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${e.placement} · \$${e.spend.toStringAsFixed(0)} spend',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _metricPill('CTR', '${e.ctr}%', DesignTokens.neonCyan),
                  const SizedBox(width: 6),
                  _metricPill('CVR', '${e.cvr}%', DesignTokens.neonGold),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 2: RETARGETING FUNNEL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _retargetingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('RETARGETING FUNNEL'),
        const SizedBox(height: 12),
        ...List.generate(_funnel.length, (i) {
          final s = _funnel[i];
          final maxReach = _funnel
              .map((e) => e.reach)
              .reduce((a, b) => a > b ? a : b);
          final pct = maxReach > 0 ? s.reach / maxReach : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.window,
                        style: TextStyle(
                          color: s.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${s.reach} reach',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: DesignTokens.bgCard,
                    valueColor: AlwaysStoppedAnimation(s.color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.audience,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.strategy,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                if (i < _funnel.length - 1) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Icon(
                      Icons.arrow_downward,
                      color: s.color.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
        _sectionLabel('PIXEL EVENTS (paste into dev ticket)'),
        const SizedBox(height: 8),
        _pixelRow('view_content', 'Landing page load'),
        _pixelRow('add_to_cart', 'Ticket or PPV added'),
        _pixelRow('initiate_checkout', 'Checkout started'),
        _pixelRow('purchase', 'Payment confirmed'),
        _pixelRow('ppv_stream_start', 'PPV playback begins'),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('COPY PIXEL EVENTS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.neonGold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              const text =
                  'view_content — Landing page load\nadd_to_cart — Ticket/PPV added\ninitiate_checkout — Checkout started\npurchase — Payment confirmed\nppv_stream_start — PPV playback begins';
              Clipboard.setData(const ClipboardData(text: text));
              _snack('Pixel events copied');
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 3: VIRAL HOOKS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _viralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('VIRAL HOOK LIBRARY (${_hooks.length} hooks)'),
        const SizedBox(height: 8),
        const Text(
          'Tap any hook to copy. Use for captions, ads, stories, and reels.',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 12),
        ...List.generate(_hooks.length, (i) {
          final h = _hooks[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: h.text));
                _snack('Hook ${i + 1} copied');
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: GlassDecoration.card(
                  accent: DesignTokens.neonMagenta,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(h.icon, color: DesignTokens.neonMagenta, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            h.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            h.category,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.copy, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _sectionLabel('HASHTAG STRATEGY'),
        const SizedBox(height: 8),
        _hashtagGroup(
          'Primary (always use)',
          '#DataFightCentral #DFC #TownsvilleFightShow #FightNight #PPV',
        ),
        _hashtagGroup(
          'Fighters',
          '#AzeHepi #[OPPONENT] #MMA #Boxing #BareKnuckle #BKFC',
        ),
        _hashtagGroup(
          'Local',
          '#Townsville #NorthQueensland #QLD #AussieBoxing',
        ),
        _hashtagGroup(
          'Trending',
          '#FightFans #RingsideTickets #LiveStream #KnockOut',
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAB 4: MICRO-INFLUENCERS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _influencersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel('MICRO-INFLUENCER PROGRAM'),
        const SizedBox(height: 4),
        const Text(
          '5 local partners, unique promo codes, pay per sale',
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
        const SizedBox(height: 12),
        ...List.generate(_influencers.length, (i) {
          final inf = _influencers[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: GlassDecoration.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: DesignTokens.neonCyan,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          inf.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: inf.promoCode));
                          _snack('Promo code copied');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGold.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inf.promoCode,
                            style: const TextStyle(
                              color: DesignTokens.neonGold,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        inf.handle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${inf.sales} sales · ${inf.reached} reached',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _sectionLabel('INFLUENCER AGREEMENT TERMS'),
        const SizedBox(height: 8),
        _termItem('Commission: 10% of net ticket sales via promo code'),
        _termItem('Duration: campaign period only (event date + 7 days)'),
        _termItem('Deliverables: 2 posts, 3 stories, 1 reel minimum'),
        _termItem('Reporting: daily CSV with code usage + revenue'),
        _termItem('Exclusivity: no competing event promo during campaign'),
        _termItem('Payment: within 14 days post-event, via bank transfer'),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════════

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: DesignTokens.neonGold.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _kpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '\$${value.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: DesignTokens.neonGold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: DesignTokens.neonGold,
              thumbColor: DesignTokens.neonGold,
              inactiveTrackColor: DesignTokens.neonGold.withValues(alpha: 0.15),
              overlayColor: DesignTokens.neonGold.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 100).round().clamp(10, 1000),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _numRow(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.white38,
              size: 18,
            ),
            onPressed: () => onChanged((value - 100).clamp(0, 9999999)),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: DesignTokens.neonGold,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.white38,
              size: 18,
            ),
            onPressed: () => onChanged(value + 100),
          ),
        ],
      ),
    );
  }

  Widget _strategyRow(String phase, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$phase: ',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: detail,
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

  Widget _metricPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _pixelRow(String event, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.code, color: DesignTokens.neonGold, size: 14),
          const SizedBox(width: 8),
          Text(
            event,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '— $desc',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hashtagGroup(String label, String tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: tags));
          _snack('$label hashtags copied');
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.neonMagenta.withValues(alpha: 0.06),
            border: Border.all(
              color: DesignTokens.neonMagenta.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: DesignTokens.neonMagenta,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.copy, color: Colors.white24, size: 14),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                tags,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _termItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: DesignTokens.neonGreen,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _Experiment {
  final String creative;
  final String audience;
  final String placement;
  final double ctr;
  final double cvr;
  final double spend;
  const _Experiment(
    this.creative,
    this.audience,
    this.placement, {
    required this.ctr,
    required this.cvr,
    required this.spend,
  });
}

class _RetargetStage {
  final String window;
  final String audience;
  final String strategy;
  final Color color;
  final int reach;
  const _RetargetStage(
    this.window,
    this.audience,
    this.strategy,
    this.color,
    this.reach,
  );
}

class _ViralHook {
  final String text;
  final String category;
  final IconData icon;
  const _ViralHook(this.text, this.category, this.icon);
}

class _Influencer {
  final String name;
  final String handle;
  final String promoCode;
  final int sales;
  final int reached;
  const _Influencer(
    this.name,
    this.handle,
    this.promoCode, {
    required this.sales,
    required this.reached,
  });
}
