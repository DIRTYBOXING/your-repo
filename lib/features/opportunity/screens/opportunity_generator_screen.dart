import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OPPORTUNITY GENERATOR — AI matchup builder, event engine, sponsorship finder
// ─────────────────────────────────────────────────────────────────────────────
class OpportunityGeneratorScreen extends StatefulWidget {
  const OpportunityGeneratorScreen({super.key});
  @override
  State<OpportunityGeneratorScreen> createState() =>
      _OpportunityGeneratorScreenState();
}

class _OpportunityGeneratorScreenState extends State<OpportunityGeneratorScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late TabController _tab;
  bool _generating = false;
  int _generatedCount = 0;

  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _amber = Color(0xFFFFAB00);
  static const _purple = Color(0xFFD500F9);
  static const _orange = Color(0xFFFF6D00);
  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF080F1E);

  // ── Opportunity types ─────────────────────────────────────────────────────
  String _myStyle = 'MMA';
  String _myWeight = 'Welterweight';
  String _myLevel = 'Amateur';
  String _lookingFor = 'Fight';
  bool _openToTravel = true;

  static const _styles = [
    'MMA',
    'Boxing',
    'Muay Thai',
    'BJJ',
    'Kickboxing',
    'Wrestling',
  ];
  static const _weights = [
    'Flyweight',
    'Bantamweight',
    'Featherweight',
    'Lightweight',
    'Welterweight',
    'Middleweight',
    'Light Heavyweight',
    'Heavyweight',
  ];
  static const _levels = [
    'Beginner',
    'Amateur',
    'Pro Amateur',
    'Semi-Pro',
    'Professional',
  ];
  static const _seeking = [
    'Fight',
    'Event Slot',
    'Sponsorship',
    'Gym Partnership',
    'Coaching Role',
    'Media Feature',
  ];

  // ── Generated opportunities ───────────────────────────────────────────────
  final List<_Opp> _opportunities = [
    const _Opp(
      '🥊',
      'FIGHT OFFER — Welterweight',
      'Hex Fight Series 27 • March 15',
      'ABA Welterweight belt on the line. Promoter needs a quality opponent for their headliner. Short-notice available. \$800 show / \$800 win.',
      Color(0xFFFF1744),
      'FIGHT',
      'HOT',
    ),
    const _Opp(
      '🏆',
      'AMATEUR TOURNAMENT — Open Division',
      'Brisbane Combat Sports Centre • April 5',
      '16-man single-elimination. All styles welcome. Trophies + DFC ranking points. Free entry for DFC members.',
      Color(0xFFFFAB00),
      'EVENT',
      'NEW',
    ),
    const _Opp(
      '💼',
      'SPONSORSHIP — Fight Gear Brand',
      'NightHawk Combat',
      'Looking for 5 fighters at amateur/semi-pro level. Full kit in exchange for Instagram posts + DFC profile branding. No cash.',
      Color(0xFF00E5FF),
      'SPONSOR',
      'OPEN',
    ),
    const _Opp(
      '🏋️',
      'GYM WANT AD — Sparring Partner',
      'Absolute MMA Melbourne',
      'Elite gym with 3 pro fighters seeking quality welterweight for weekly sparring camp. Travel covered. Coaching access included.',
      Color(0xFF00E676),
      'GYM',
      'OPEN',
    ),
    const _Opp(
      '📱',
      'MEDIA — Fighter Feature',
      'FightCast Podcast',
      '45-min interview slot. 12,000 listeners. Focus on your journey, training philosophy and upcoming fights. Reach: AU/NZ.',
      Color(0xFFD500F9),
      'MEDIA',
      'OPEN',
    ),
    const _Opp(
      '🥊',
      'FIGHT OFFER — Featherweight',
      'Perth Warriors FC • March 28',
      'Full card filler bout needed. Experienced opponent required. \$500 flat rate. Air travel arranged. 5 weeks notice.',
      Color(0xFFFF6D00),
      'FIGHT',
      'URGENT',
    ),
    const _Opp(
      '🎓',
      'COACHING ROLE — Youth Program',
      'Gold Coast City Council',
      'Part-time MMA fundamentals coach for youth at-risk program. 8hrs/week. \$35/hr. DFC-credentialed coaches preferred.',
      Color(0xFF2979FF),
      'COACHING',
      'NEW',
    ),
    const _Opp(
      '💰',
      'SPONSORSHIP — Supplement Brand',
      'PrimalFuel Nutrition',
      'Cash + product deal for fighters with 500+ social followers. \$150/month + free supps. Requires monthly Instagram content.',
      Color(0xFFFF4081),
      'SPONSOR',
      'HOT',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _pulseCtrl.dispose();
    _tab.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _generating = false;
        _generatedCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.cos(_bgCtrl.value * 2 * math.pi) * 0.4,
                -0.2,
              ),
              radius: 1.7,
              colors: const [
                Color(0xFF001A10),
                Color(0xFF030810),
                Color(0xFF0A0018),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _appBar(),
                _tabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [_discoverTab(), _generatorTab(), _myOppsTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Row(
      children: [
        GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white54,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'OPPORTUNITY ENGINE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'AI-matched fights • events • sponsors • gyms',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 9,
              ),
            ),
          ],
        ),
        const Spacer(),
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.1 + 0.05 * _pulseCtrl.value),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _green.withValues(alpha: 0.4 + 0.2 * _pulseCtrl.value),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_opportunities.length} LIVE',
                  style: const TextStyle(
                    color: _green,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _tabBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TabBar(
        controller: _tab,
        labelStyle: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 9),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E676), Color(0xFF00E5FF)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'DISCOVER'),
          Tab(text: 'AI MATCH'),
          Tab(text: 'MY OPPS'),
        ],
      ),
    ),
  );

  // ── TAB 1: DISCOVER ───────────────────────────────────────────────────────
  Widget _discoverTab() {
    final cats = [
      'ALL',
      'FIGHT',
      'EVENT',
      'SPONSOR',
      'GYM',
      'MEDIA',
      'COACHING',
    ];
    return Column(
      children: [
        // Category filter
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: cats
                .map(
                  (c) => GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Filter: $c — browse opportunities below')),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c == 'ALL'
                            ? _cyan.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: c == 'ALL'
                              ? _cyan.withValues(alpha: 0.5)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          color: c == 'ALL' ? _cyan : Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _opportunities.length,
            itemBuilder: (_, i) => _oppCard(_opportunities[i]),
          ),
        ),
      ],
    );
  }

  Widget _oppCard(_Opp o) {
    final hot = o.badge == 'HOT' || o.badge == 'URGENT';
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) => GestureDetector(
        onTap: () => _showOppDetail(o),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [o.color.withValues(alpha: 0.1), _card],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: o.color.withValues(
                alpha: hot ? 0.35 + 0.15 * _pulseCtrl.value : 0.22,
              ),
            ),
            boxShadow: hot
                ? [
                    BoxShadow(
                      color: o.color.withValues(alpha: 0.08 * _pulseCtrl.value),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Text(o.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.title,
                            style: TextStyle(
                              color: o.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: o.color.withValues(alpha: hot ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            o.badge,
                            style: TextStyle(
                              color: o.color,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      o.location,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 9,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: o.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: o.color.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    o.type,
                    style: TextStyle(
                      color: o.color,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOppDetail(_Opp o) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                o.color.withValues(alpha: 0.12),
                const Color(0xFF060D1A),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: o.color.withValues(alpha: 0.3)),
          ),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(22),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(o.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o.title,
                          style: TextStyle(
                            color: o.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          o.location,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                o.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text(
                          'SAVE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              o.color.withValues(alpha: 0.35),
                              o.color.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: o.color.withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Text(
                          'APPLY NOW →',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TAB 2: AI MATCH ───────────────────────────────────────────────────────
  Widget _generatorTab() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_green.withValues(alpha: 0.1), _card],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _green.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🤖', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  'AI OPPORTUNITY MATCH',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tell us your profile and the AI scans every open opportunity across the DFC network for your exact match.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _genDropdown(
        'My Style',
        _myStyle,
        _styles,
        _cyan,
        (v) => setState(() => _myStyle = v),
      ),
      _genDropdown(
        'My Weight Class',
        _myWeight,
        _weights,
        _amber,
        (v) => setState(() => _myWeight = v),
      ),
      _genDropdown(
        'My Level',
        _myLevel,
        _levels,
        _purple,
        (v) => setState(() => _myLevel = v),
      ),
      _genDropdown(
        "I'm Looking For",
        _lookingFor,
        _seeking,
        _orange,
        (v) => setState(() => _lookingFor = v),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.flight_takeoff,
              color: Color(0xFF00E5FF),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Open to Travel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Show interstate/international opportunities',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _openToTravel,
              activeThumbColor: _cyan,
              onChanged: (v) => setState(() => _openToTravel = v),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _generating ? null : _generate,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, _) => Container(
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _green.withValues(alpha: 0.35),
                  _cyan.withValues(alpha: 0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _green.withValues(alpha: 0.6 + 0.2 * _pulseCtrl.value),
              ),
              boxShadow: [
                BoxShadow(
                  color: _green.withValues(alpha: 0.15 * _pulseCtrl.value),
                  blurRadius: 16,
                ),
              ],
            ),
            child: _generating
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'SCANNING NETWORK...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _generatedCount > 0
                            ? 'SCAN AGAIN'
                            : 'FIND MY OPPORTUNITIES',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      if (_generatedCount > 0) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _green.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Text(
                '${3 + _generatedCount * 2} MATCHES FOUND',
                style: const TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Based on $_myStyle • $_myWeight • $_myLevel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _tab.animateTo(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _green.withValues(alpha: 0.4)),
                  ),
                  child: const Center(
                    child: Text(
                      'VIEW MATCHES →',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );

  Widget _genDropdown(
    String label,
    String val,
    List<String> items,
    Color col,
    ValueChanged<String> fn,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      initialValue: val,
      onChanged: (v) {
        if (v != null) fn(v);
      },
      dropdownColor: const Color(0xFF0A1428),
      style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: col.withValues(alpha: 0.55), fontSize: 11),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: col.withValues(alpha: 0.2)),
        ),
      ),
      items: items
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: TextStyle(color: col, fontSize: 12)),
            ),
          )
          .toList(),
    ),
  );

  // ── TAB 3: MY OPPS ───────────────────────────────────────────────────────
  Widget _myOppsTab() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _cyan.withValues(alpha: 0.3)),
            ),
            child: Icon(
              Icons.bolt,
              color: _cyan.withValues(alpha: 0.5),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NO SAVED OPPORTUNITIES',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the AI Match tab to find opportunities, then save them here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _tab.animateTo(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cyan.withValues(alpha: 0.35)),
              ),
              child: const Text(
                'FIND OPPORTUNITIES →',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Opp {
  final String emoji, title, location, description, badge, type;
  final Color color;
  const _Opp(
    this.emoji,
    this.title,
    this.location,
    this.description,
    this.color,
    this.type,
    this.badge,
  );
}
