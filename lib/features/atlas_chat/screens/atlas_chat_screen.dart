import 'dart:math' as math;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AtlasChatScreen extends StatefulWidget {
  const AtlasChatScreen({super.key});
  @override
  State<AtlasChatScreen> createState() => _AtlasChatScreenState();
}

class _AtlasChatScreenState extends State<AtlasChatScreen>
    with TickerProviderStateMixin {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );
  late AnimationController _bgCtrl;
  late AnimationController _typingCtrl;
  late AnimationController _pulseCtrl;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _atlasTyping = false;
  final List<_Msg> _msgs = [];
  bool _didApplySeed = false;

  static const _cyan = Color(0xFF00E5FF);
  static const _green = Color(0xFF00E676);
  static const _blue = Color(0xFF2979FF);
  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF080F1E);

  static const List<(String, String)> _chips = [
    ('⚡', 'Analyse my record'),
    ('🏕️', 'Build a fight camp'),
    ('🥊', 'Find my ideal opponent'),
    ('📊', 'What is my health score?'),
    ('🏆', 'DFC rankings explained'),
    ('🎯', 'Training tips for tonight'),
    ('💰', 'How to get sponsored?'),
    ('📱', 'Grow my social following'),
  ];

  static String _pickResponse(String q) {
    final l = q.toLowerCase();
    if (l.contains('record') ||
        l.contains('win') ||
        l.contains('loss') ||
        l.contains('analyse')) {
      return 'Your fight record shapes everything — your ranking, your value to promoters, and the opportunities the system generates for you. A 5-2 record at welterweight puts you in the top 30% of DFC fighters in your region. Want me to run a gap analysis against your target opponents?';
    }
    if (l.contains('camp') ||
        l.contains('training plan') ||
        l.contains('build')) {
      return 'A quality 12-week camp breaks into 4 phases: Base (weeks 1-3, aerobic base + skill drilling), Strength (weeks 4-6, gym work + technical sparring), Sharpening (weeks 7-10, hard sparring + fight-specific conditioning), and Peak Week (weeks 11-12, taper, weight management, mental prep). Which phase are you in right now?';
    }
    if (l.contains('opponent') || l.contains('fight') || l.contains('match')) {
      return 'Finding your ideal opponent means matching style, level, and momentum. You want someone who challenges your weak points while letting your strengths shine. Give me your record and weight class and I will generate a shortlist from the DFC fighter database.';
    }
    if (l.contains('health') || l.contains('score') || l.contains('recovery')) {
      return 'Your DFC Health Score is calculated from: training consistency, recovery tracking, weight management, injury log, and sleep data. Connect a wearable or manually log your data in the Performance tab. A score above 75 is fight-ready. Below 60 means your camp needs review.';
    }
    if (l.contains('rank') || l.contains('dfc')) {
      return 'DFC rankings update weekly. Points are awarded for wins (weighted by opponent quality), title fights, and professional status. Activity bonus applies if you fight at least once every 90 days. Your current rank within your weight class is visible on your fighter card.';
    }
    if (l.contains('training') ||
        l.contains('tonight') ||
        l.contains('workout')) {
      return 'Tonight: 20 min shadow boxing to warm up the patterns, 4x3min pad work with focus on your fastest combination, 3x3min light sparring at 60% to build timing, 15 min BJJ positional drilling, then 10 min stretch and ice. Simple, focused, effective.';
    }
    if (l.contains('sponsor') || l.contains('brand') || l.contains('money')) {
      return 'Sponsorships in combat sports work on three tiers: Gear deals (kit, supplements, equipment), Cash deals (require 1k+ engaged social followers), and Equity deals (for high-profile fighters). DFC\'s sponsorship marketplace lists active deals. Post consistently for 90 days and your value triples.';
    }
    if (l.contains('social') ||
        l.contains('follow') ||
        l.contains('tiktok') ||
        l.contains('instagram')) {
      return 'The DFC social growth formula: post 1 training clip daily (15-30 sec, vertical), 1 personal story per week, 1 fight analysis per fortnight. Use fight week as your peak content moment. Your best platform depends on your age — under 25 dominate on TikTok, over 25 on Instagram.';
    }
    return 'Good question. I have data on thousands of fighters across the DFC network, every major promotion\'s fight history, and real-time health and training metrics. Ask me anything about fight strategy, camp planning, matchmaking, sponsorships, health scores, or how DFC works. I\'m Atlas.';
  }

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _typingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _msgs.add(
      const _Msg(
        sender: 'atlas',
        text:
            'I\'m Atlas — DFC\'s AI fight intelligence engine.\n\nI know your training data, your fight record, the rankings, every promotion in the database, and what it takes to build a career in combat sports.\n\nWhat do you need?',
        time: '',
        showChips: true,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didApplySeed) return;
      final seed = GoRouterState.of(context).uri.queryParameters['seed'];
      if (seed == null || seed.trim().isEmpty) return;
      _didApplySeed = true;
      _send(seed.trim());
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _typingCtrl.dispose();
    _pulseCtrl.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _timeNow() {
    final n = DateTime.now();
    return '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _msgs.add(_Msg(sender: 'user', text: text.trim(), time: _timeNow()));
      _atlasTyping = true;
    });
    _input.clear();
    _scrollDown();

    // Try Gemini CF first, fall back to local keyword matching
    String response;
    try {
      final callable = _functions.httpsCallable('generateSocialPost');
      final result = await callable.call<Map<String, dynamic>>({
        'topic': text.trim(),
        'tone': 'expert_coach',
        'platform': 'atlas_chat',
      });
      final post = (result.data['post'] as String?) ?? '';
      response = post.isNotEmpty ? post : _pickResponse(text);
    } catch (_) {
      await Future.delayed(
        Duration(milliseconds: 900 + math.Random().nextInt(600)),
      );
      response = _pickResponse(text);
    }

    if (!mounted) return;
    setState(() {
      _atlasTyping = false;
      _msgs.add(_Msg(sender: 'atlas', text: response, time: _timeNow()));
    });
    _scrollDown();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: _bgCtrl,
        builder: (_, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_bgCtrl.value * 2 * math.pi) * 0.5,
                -0.3,
              ),
              radius: 1.8,
              colors: const [
                Color(0xFF001812),
                Color(0xFF030810),
                Color(0xFF001525),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _appBar(),
                _banner(),
                Expanded(child: _msgList()),
                if (_atlasTyping) _typing(),
                _inputBar(),
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
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF004D66)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: _cyan.withValues(alpha: 0.4)),
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ATLAS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _green.withValues(
                          alpha: 0.6 + 0.4 * _pulseCtrl.value,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      'DFC Fight Intelligence • Online',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _banner() => Container(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: _cyan.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _cyan.withValues(alpha: 0.18)),
    ),
    child: Row(
      children: [
        Icon(Icons.auto_awesome, color: _cyan.withValues(alpha: 0.5), size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Atlas uses DFC fight data and AI reasoning — not live web search.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _msgList() => ListView.builder(
    controller: _scroll,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    itemCount: _msgs.length,
    itemBuilder: (_, i) => _buildMsg(_msgs[i]),
  );

  Widget _buildMsg(_Msg m) {
    final isAtlas = m.sender == 'atlas';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isAtlas
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: isAtlas
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAtlas) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF004D66)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    gradient: isAtlas
                        ? LinearGradient(
                            colors: [_cyan.withValues(alpha: 0.08), _card],
                          )
                        : LinearGradient(
                            colors: [
                              _green.withValues(alpha: 0.18),
                              _green.withValues(alpha: 0.08),
                            ],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isAtlas ? 2 : 14),
                      bottomRight: Radius.circular(isAtlas ? 14 : 2),
                    ),
                    border: Border.all(
                      color: isAtlas
                          ? _cyan.withValues(alpha: 0.15)
                          : _green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: Colors.white.withValues(
                        alpha: isAtlas ? 0.72 : 0.92,
                      ),
                      fontSize: 12,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (m.time.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4, left: isAtlas ? 36 : 0),
              child: Text(
                m.time,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 8,
                ),
              ),
            ),
          if (m.showChips)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 36),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _chips
                    .map(
                      (c) => GestureDetector(
                        onTap: () => _send(c.$2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _cyan.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _cyan.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c.$1, style: const TextStyle(fontSize: 11)),
                              const SizedBox(width: 5),
                              Text(
                                c.$2,
                                style: TextStyle(
                                  color: _cyan.withValues(alpha: 0.8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typing() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF004D66)],
            ),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.07),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(14),
            ),
            border: Border.all(color: _cyan.withValues(alpha: 0.15)),
          ),
          child: AnimatedBuilder(
            animation: _typingCtrl,
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _cyan.withValues(
                      alpha: i == 0
                          ? (0.3 + 0.55 * _typingCtrl.value)
                          : i == 1
                          ? (0.3 + 0.55 * (1 - _typingCtrl.value))
                          : (0.45 + 0.4 * _typingCtrl.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _inputBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _input,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textInputAction: TextInputAction.send,
              onSubmitted: _send,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ask Atlas anything...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _send(_input.text),
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, _) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cyan.withValues(alpha: 0.38 + 0.1 * _pulseCtrl.value),
                    _blue.withValues(alpha: 0.28),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _cyan.withValues(alpha: 0.5 + 0.2 * _pulseCtrl.value),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _cyan.withValues(alpha: 0.07 * _pulseCtrl.value),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Msg {
  final String sender, text, time;
  final bool showChips;
  const _Msg({
    required this.sender,
    required this.text,
    required this.time,
    this.showChips = false,
  });
}
