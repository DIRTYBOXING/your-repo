import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/image_assets.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FAN CAGEVIEW — The spectator's arena. Energetic, passionate, inspiring.
///
/// Fans want:
///  • Highlight reels, skill analysis, athlete rankings
///  • The thrill of competition, the spectacle, the stories
///  • Fantasy matchups, skill-based predictions
///
/// DFC reminds them:
///  • That athlete who just competed is someone's child
///  • Every highlight reel is earned through dedication and sacrifice
///  • The best fans care about their athletes' wellbeing
///
/// This screen is the bridge between entertainment and respect.
/// ═══════════════════════════════════════════════════════════════════════════

class FanCageViewScreen extends StatefulWidget {
  const FanCageViewScreen({super.key});

  @override
  State<FanCageViewScreen> createState() => _FanCageViewScreenState();
}

class _FanCageViewScreenState extends State<FanCageViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _factIndex = 0;
  Timer? _factTimer;

  static const _facts = [
    (
      stat: '6–8 WEEKS',
      label: 'mandatory recovery after every knockout.',
      icon: Icons.healing,
    ),
    (
      stat: '35–65 STRIKES',
      label: 'absorbed per fight. DFC tracks every one.',
      icon: Icons.analytics_outlined,
    ),
    (
      stat: 'CTE STARTS',
      label:
          'before the highlight KO — with sub-concussive hits. Every fight counts.',
      icon: Icons.psychology_outlined,
    ),
    (
      stat: '65% OF FIGHTERS',
      label: 'face financial hardship within 2 years of their last fight.',
      icon: Icons.volunteer_activism_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _factTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _factIndex = (_factIndex + 1) % _facts.length);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _factTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _CageWirePainter(phase: _ctrl.value)),
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(child: _buildLiveNow()),
                    SliverToBoxAdapter(child: _buildTrendingTopics()),
                    SliverToBoxAdapter(child: _buildRecentResults()),
                    SliverToBoxAdapter(child: _buildKOHighlights()),
                    SliverToBoxAdapter(child: _buildFightPredictions()),
                    SliverToBoxAdapter(child: _buildWarriorRankings()),
                    SliverToBoxAdapter(child: _buildFanPulse()),
                    SliverToBoxAdapter(child: _buildCompassionReminder()),
                    SliverToBoxAdapter(child: _buildFantasyMatchup()),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.canPop() ? context.pop() : context.go('/home'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FIGHTVIEW',
                  style: TextStyle(
                    color: AppColors.neonRed,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                  ),
                ),
                Text(
                  'MMA • Boxing • Muay Thai • BKFC • Kickboxing',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.neonRed.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulseDot(color: AppColors.neonRed, phase: _ctrl.value),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: AppColors.neonRed,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LIVE NOW — Current event
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLiveNow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.neonRed.withValues(alpha: 0.06),
                  AppColors.neonOrange.withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: AppColors.neonRed.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.neonRed.withValues(alpha: 0.2),
                      ),
                      child: const Text(
                        'MAIN EVENT',
                        style: TextStyle(
                          color: AppColors.neonRed,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'ROUND 3',
                      style: TextStyle(
                        color: AppColors.neonOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const _FighterAvatar(
                      name: 'DELLA MADDALENA',
                      record: '17-2',
                      color: AppColors.neonRed,
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'WELTERWEIGHT',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.1),
                            fontSize: 7,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const _FighterAvatar(
                      name: 'RAKHMONOV',
                      record: '18-0',
                      color: AppColors.neonCyan,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 40,
                  child: CustomPaint(
                    size: const Size(double.infinity, 40),
                    painter: _LivePulsePainter(phase: _ctrl.value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRENDING TOPICS — What the fight world is buzzing about
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTrendingTopics() {
    final topics = [
      {'tag': '#UFCSydney', 'posts': '187K', 'color': AppColors.neonRed},
      {'tag': '#TopuriaEra', 'posts': '89K', 'color': AppColors.neonGreen},
      {'tag': '#ShurikenFS', 'posts': '24K', 'color': AppColors.neonCyan},
      {'tag': '#InoueMONSTER', 'posts': '201K', 'color': AppColors.neonOrange},
      {
        'tag': '#ONEChampionship',
        'posts': '45K',
        'color': AppColors.neonMagenta,
      },
      {'tag': '#HexFightSeries', 'posts': '18K', 'color': AppColors.neonRed},
      {'tag': '#AotearoaFights', 'posts': '12K', 'color': AppColors.neonCyan},
      {'tag': '#AusBoxing', 'posts': '31K', 'color': AppColors.neonOrange},
      {'tag': '#MelbourneMMA', 'posts': '22K', 'color': AppColors.neonGreen},
      {'tag': '#NZFights', 'posts': '15K', 'color': AppColors.neonMagenta},
      {'tag': '#UFCPerth', 'posts': '142K', 'color': AppColors.neonRed},
      {'tag': '#EternalMMA', 'posts': '16K', 'color': AppColors.neonOrange},
      {'tag': '#PerthMMA', 'posts': '9K', 'color': AppColors.neonCyan},
      {'tag': '#WestCoastFights', 'posts': '7K', 'color': AppColors.neonGreen},
      {
        'tag': '#EmpireFightSeries',
        'posts': '11K',
        'color': AppColors.neonMagenta,
      },
      {'tag': '#IBCBrawling', 'posts': '38K', 'color': AppColors.neonRed},
      {
        'tag': '#UltimateLegends',
        'posts': '19K',
        'color': AppColors.neonOrange,
      },
      {'tag': '#WBCSilverAU', 'posts': '27K', 'color': AppColors.neonCyan},
      {
        'tag': '#MelbournePavilion',
        'posts': '11K',
        'color': AppColors.neonGreen,
      },
      {'tag': '#JoeDemicoli', 'posts': '6K', 'color': AppColors.neonMagenta},
      {
        'tag': '#EliteFightSeries',
        'posts': '8K',
        'color': AppColors.neonOrange,
      },
      {'tag': '#BruceBuffer', 'posts': '95K', 'color': AppColors.neonCyan},
      {'tag': '#FightComAu', 'posts': '14K', 'color': AppColors.neonGreen},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('TRENDING NOW', AppColors.neonCyan),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = topics[i];
                return GestureDetector(
                  onTap: () => context.push('/explore'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: (t['color'] as Color).withValues(alpha: 0.06),
                      border: Border.all(
                        color: (t['color'] as Color).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t['tag'] as String,
                          style: TextStyle(
                            color: (t['color'] as Color).withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t['posts'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT RESULTS — Latest fight outcomes
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentResults() {
    final results = [
      {
        'winner': 'Makhachev',
        'loser': 'Tsarukyan',
        'method': 'Decision (Unanimous)',
        'event': 'UFC 311',
        'round': 'R5',
        'color': AppColors.neonRed,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Topuria',
        'loser': 'Volkanovski',
        'method': 'KO (Right Hook)',
        'event': 'UFC 298',
        'round': 'R2',
        'color': AppColors.neonGreen,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Pereira',
        'loser': 'Prochazka',
        'method': 'TKO (Head Kick)',
        'event': 'UFC 303',
        'round': 'R2',
        'color': AppColors.neonOrange,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Inoue',
        'loser': 'Doheny',
        'method': 'TKO (Body Shot)',
        'event': 'Super Series',
        'round': 'R7',
        'color': AppColors.neonCyan,
        'sport': '🥊 Boxing',
      },
      {
        'winner': 'Du Plessis',
        'loser': 'Strickland',
        'method': 'Split Decision',
        'event': 'UFC 297',
        'round': 'R5',
        'color': AppColors.neonMagenta,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Tawanchai',
        'loser': 'Nattawut',
        'method': 'Decision',
        'event': 'ONE 169',
        'round': 'R5',
        'color': AppColors.neonCyan,
        'sport': '🦵 Muay Thai',
      },
      {
        'winner': 'Superbon',
        'loser': 'Aliakbari',
        'method': 'KO (Spinning Heel Kick)',
        'event': 'ONE 168',
        'round': 'R1',
        'color': AppColors.neonOrange,
        'sport': '🦵 Kickboxing',
      },
      {
        'winner': 'Crawford',
        'loser': 'Madrimov',
        'method': 'Decision',
        'event': 'BLK Prime',
        'round': 'R12',
        'color': AppColors.neonGreen,
        'sport': '🥊 Boxing',
      },
      {
        'winner': 'Della Maddalena',
        'loser': 'Rodriguez',
        'method': 'KO (Left Hook)',
        'event': 'UFC Perth',
        'round': 'R1',
        'color': AppColors.neonRed,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Lougheed',
        'loser': 'Chan',
        'method': 'TKO (Elbows)',
        'event': 'Empire FS 4',
        'round': 'R2',
        'color': AppColors.neonOrange,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Crute',
        'loser': 'Pedro',
        'method': 'Submission (RNC)',
        'event': 'Hex FS 27',
        'round': 'R3',
        'color': AppColors.neonCyan,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Wilkinson',
        'loser': 'Torres',
        'method': 'TKO (Body Kicks)',
        'event': 'Eternal MMA 79',
        'round': 'R2',
        'color': AppColors.neonGreen,
        'sport': '🥋 MMA',
      },
      {
        'winner': 'Hardman',
        'loser': 'Towns',
        'method': 'TKO (Punches)',
        'event': 'IBC 02',
        'round': 'R3',
        'color': AppColors.neonRed,
        'sport': '👊 Brawling',
      },
      {
        'winner': 'Roesler',
        'loser': 'TBA',
        'method': 'WBC Silver Title Fight',
        'event': 'Ultimate Legends',
        'round': 'Apr 24',
        'color': AppColors.neonOrange,
        'sport': '🥊 Boxing',
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('RECENT RESULTS', AppColors.neonGreen),
          const SizedBox(height: 4),
          Text(
            'Latest outcomes across all promotions',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          ...results.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => context.push('/combat-analytics'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: (r['color'] as Color).withValues(alpha: 0.02),
                    border: Border.all(
                      color: (r['color'] as Color).withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 32,
                        decoration: BoxDecoration(
                          color: (r['color'] as Color).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
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
                                  r['winner'] as String,
                                  style: TextStyle(
                                    color: (r['color'] as Color),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  ' def. ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    fontSize: 10,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    r['loser'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: (r['color'] as Color).withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                  child: Text(
                                    r['sport'] as String,
                                    style: TextStyle(
                                      color: (r['color'] as Color).withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  r['method'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    fontSize: 9,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  r['round'] as String,
                                  style: TextStyle(
                                    color: (r['color'] as Color).withValues(
                                      alpha: 0.3,
                                    ),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                        child: Text(
                          r['event'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KO HIGHLIGHTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildKOHighlights() {
    final highlights = [
      const _Highlight(
        'FLYING KNEE KO',
        'Della Maddalena vs Magny',
        'R1 2:34',
        AppColors.neonRed,
        '2.1M views',
      ),
      const _Highlight(
        'SPINNING BACK FIST',
        'Rakhmonov vs Neal',
        'R2 4:51',
        AppColors.neonOrange,
        '1.8M views',
      ),
      const _Highlight(
        'HAIL MARY UPPERCUT',
        'Davis vs Reyes',
        'R3 0:12',
        AppColors.neonMagenta,
        '3.4M views',
      ),
      const _Highlight(
        'WALK-OFF HEAD KICK',
        'Pereira vs Adesanya',
        'R2 0:23',
        AppColors.neonCyan,
        '8.7M views',
      ),
      const _Highlight(
        'OVERHAND BOMB',
        'Ngannou vs Miocic',
        'R2 0:52',
        AppColors.neonGreen,
        '12.3M views',
      ),
      const _Highlight(
        'SIDEKICK TO THE BODY',
        'McGregor vs Cerrone',
        'R1 0:40',
        AppColors.neonOrange,
        '15.1M views',
      ),
      const _Highlight(
        'LIVER SHOT FINISH',
        'Holloway vs Kattar',
        'R5 4:59',
        AppColors.neonRed,
        '6.8M views',
      ),
      const _Highlight(
        'TRIANGLE CHOKE KO',
        'Oliveira vs Chandler',
        'R2 4:18',
        AppColors.neonCyan,
        '4.2M views',
      ),
      const _Highlight(
        'SUPERMAN PUNCH',
        'Thompson vs Holland',
        'R1 3:22',
        AppColors.neonMagenta,
        '3.9M views',
      ),
      const _Highlight(
        'GUILLOTINE SLAM KO',
        'Topuria vs Volkanovski',
        'R2 3:32',
        AppColors.neonGreen,
        '9.5M views',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('KO HIGHLIGHTS', AppColors.neonRed),
          const SizedBox(height: 4),
          Text(
            'The moments that shake the arena',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          ...highlights.map(_buildHighlightCard),
        ],
      ),
    );
  }

  String _highlightImageUrl(String title) {
    if (title.contains('KNEE')) {
      return ImageAssets.bgHero;
    }
    if (title.contains('FIST') || title.contains('SPINNING')) {
      return ImageAssets.bgAction;
    }
    if (title.contains('UPPERCUT')) {
      return ImageAssets.bgPromo;
    }
    return ImageAssets.bgEvent;
  }

  Widget _buildHighlightCard(_Highlight h) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.push('/combat-reels'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: h.color.withValues(alpha: 0.03),
            border: Border.all(color: h.color.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        _highlightImageUrl(h.title),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: h.color.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.play_arrow,
                            color: h.color.withValues(alpha: 0.5),
                            size: 22,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.title,
                      style: TextStyle(
                        color: h.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      h.fighters,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          h.timing,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 9,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          h.views,
                          style: TextStyle(
                            color: h.color.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: h.color.withValues(alpha: 0.2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT PREDICTIONS — AI-powered picks
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFightPredictions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('AI FIGHT PREDICTIONS', AppColors.neonCyan),
          const SizedBox(height: 10),
          _predictionCard(
            'Della Maddalena vs Rakhmonov',
            'Rakhmonov by Submission R3',
            0.58,
            AppColors.neonRed,
            'Grappling chain + relentless pressure',
          ),
          _predictionCard(
            'Dvalishvili vs Hooker',
            'Dvalishvili by Decision',
            0.64,
            AppColors.neonCyan,
            'Volume wrestling + cardio advantage',
          ),
          _predictionCard(
            'Whittaker vs O\'Malley',
            'Whittaker by TKO R3',
            0.62,
            AppColors.neonGreen,
            'Counter striking + power at range',
          ),
          _predictionCard(
            'Makhachev vs Palmer',
            'Makhachev by Decision',
            0.61,
            AppColors.neonOrange,
            'Sambo wrestling chain + octagon control',
          ),
          _predictionCard(
            'Pereira vs Ankalaev',
            'Pereira by KO R2',
            0.65,
            AppColors.neonRed,
            'Left hook counter + fight-ending power',
          ),
          _predictionCard(
            'Topuria vs Holloway',
            'Topuria by TKO R4',
            0.58,
            AppColors.neonMagenta,
            'Precision boxing + body shot accumulation',
          ),
          _predictionCard(
            'Inoue vs Nery',
            'Inoue by KO R6',
            0.81,
            AppColors.neonCyan,
            'Monster power at any weight + perfect timing',
          ),
          _predictionCard(
            'Crawford vs Madrimov',
            'Crawford by TKO R8',
            0.74,
            AppColors.neonGreen,
            'Switch-hitting mastery + ring generalship',
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/ai-fight-predictions'),
              icon: const Icon(Icons.psychology, size: 16),
              label: const Text('DEEP DIVE — AI FIGHT PREDICTIONS'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.neonCyan,
                side: BorderSide(
                  color: AppColors.neonCyan.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionCard(
    String bout,
    String pick,
    double confidence,
    Color color,
    String reason,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.push('/ai-fight-predictions'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.02),
            border: Border.all(color: color.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bout,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${(confidence * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pick,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                reason,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: color.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(
                    color.withValues(alpha: 0.3),
                  ),
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WARRIOR RANKINGS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWarriorRankings() {
    final fighters = [
      const _Ranked(
        1,
        'MAKHACHEV',
        '26-1',
        'Lightweight',
        'P4P #1 — 14 fight win streak',
        AppColors.neonRed,
        '—',
      ),
      const _Ranked(
        2,
        'PEREIRA',
        '11-2',
        'Light Heavyweight',
        'Double champ KO artist',
        AppColors.neonOrange,
        '+1',
      ),
      const _Ranked(
        3,
        'TOPURIA',
        '15-0',
        'Featherweight',
        'Undefeated — KO machine',
        AppColors.neonGreen,
        '+2',
      ),
      const _Ranked(
        4,
        'INOUE',
        '28-0',
        'Super Bantamweight',
        'Monster — 4 div champion',
        AppColors.neonCyan,
        '—',
      ),
      const _Ranked(
        5,
        'PANTOJA',
        '28-5',
        'Flyweight',
        'Dominant champion reign',
        AppColors.neonMagenta,
        '-2',
      ),
      const _Ranked(
        6,
        'DU PLESSIS',
        '22-2',
        'Middleweight',
        'South African powerhouse',
        AppColors.neonRed,
        '+3',
      ),
      const _Ranked(
        7,
        'CRAWFORD',
        '41-0',
        'Welterweight',
        'Undisputed pound-for-pound',
        AppColors.neonCyan,
        '—',
      ),
      const _Ranked(
        8,
        'HOLLOWAY',
        '26-7',
        'Featherweight',
        'BMF — volume king',
        AppColors.neonOrange,
        '-1',
      ),
      const _Ranked(
        9,
        'DVALISHVILI',
        '18-4',
        'Bantamweight',
        'Relentless wrestling machine',
        AppColors.neonGreen,
        '+4',
      ),
      const _Ranked(
        10,
        'DELLA MADDALENA',
        '17-2',
        'Welterweight',
        'Australian KO machine — 5 finishes in a row',
        AppColors.neonRed,
        '+2',
      ),
      const _Ranked(
        11,
        'WHITTAKER',
        '26-7',
        'Middleweight',
        'Former champ — perennial contender',
        AppColors.neonMagenta,
        '—',
      ),
      const _Ranked(
        12,
        'SUPERBON',
        '115-32',
        'Featherweight',
        'ONE kickboxing king',
        AppColors.neonOrange,
        '+1',
      ),
      const _Ranked(
        13,
        'TAWANCHAI',
        '133-31',
        'Featherweight',
        'Muay Thai phenom',
        AppColors.neonCyan,
        '+3',
      ),
      const _Ranked(
        14,
        'RAKHMONOV',
        '18-0',
        'Welterweight',
        'Undefeated finisher — 100% finish rate',
        AppColors.neonGreen,
        '+3',
      ),
      const _Ranked(
        15,
        'O\'MALLEY',
        '17-2',
        'Bantamweight',
        'Sugar Show — precision KO artist',
        AppColors.neonMagenta,
        '-1',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('POUND-FOR-POUND', AppColors.neonOrange),
          const SizedBox(height: 10),
          ...fighters.map(_rankCard),
        ],
      ),
    );
  }

  Widget _rankCard(_Ranked f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => context.push('/fighter-databank'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: f.color.withValues(alpha: 0.02),
            border: Border.all(color: f.color.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: f.color.withValues(alpha: f.rank == 1 ? 0.15 : 0.06),
                  border: Border.all(
                    color: f.color.withValues(alpha: f.rank == 1 ? 0.3 : 0.1),
                    width: f.rank == 1 ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '#${f.rank}',
                    style: TextStyle(
                      color: f.color,
                      fontSize: 10,
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
                    Row(
                      children: [
                        Text(
                          f.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          f.move,
                          style: TextStyle(
                            color: f.move.startsWith('+')
                                ? AppColors.neonGreen.withValues(alpha: 0.5)
                                : f.move.startsWith('-')
                                ? AppColors.neonRed.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.2),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          f.record,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '·',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          f.division,
                          style: TextStyle(
                            color: f.color.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                f.tag,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.15),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FAN PULSE — Live crowd sentiment
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFanPulse() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('FAN PULSE', AppColors.neonMagenta),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.neonMagenta.withValues(alpha: 0.02),
                  border: Border.all(
                    color: AppColors.neonMagenta.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 80,
                      child: CustomPaint(
                        size: const Size(double.infinity, 80),
                        painter: _CrowdPulsePainter(phase: _ctrl.value),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _pulseMetric('HYPE', '94%', AppColors.neonRed),
                        _pulseMetric(
                          'ENGAGEMENT',
                          '12.4K',
                          AppColors.neonMagenta,
                        ),
                        _pulseMetric(
                          'SENTIMENT',
                          '↑ FIRE',
                          AppColors.neonOrange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Live fan reactions
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _reactionChip('🔥 KO INCOMING', AppColors.neonRed),
                        _reactionChip('👊 WAR', AppColors.neonOrange),
                        _reactionChip('🏆 GOAT TALK', AppColors.neonGreen),
                        _reactionChip('😱 WHAT A ROUND', AppColors.neonCyan),
                        _reactionChip('💪 WARRIOR', AppColors.neonMagenta),
                        _reactionChip('🥊 STAND & BANG', AppColors.neonRed),
                        _reactionChip('⚡ HIGHLIGHT REEL', AppColors.neonOrange),
                        _reactionChip(
                          '🦁 LET\'S GO CHAMP',
                          AppColors.neonGreen,
                        ),
                        _reactionChip('💀 IT\'S OVER', AppColors.neonCyan),
                        _reactionChip('🎯 SNIPER', AppColors.neonMagenta),
                        _reactionChip('🐐 UNDISPUTED', AppColors.neonRed),
                        _reactionChip('🌊 LEVELS', AppColors.neonCyan),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pulseMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.3),
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _reactionChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPASSION REMINDER — The conscience within the chaos
  // Now: rotating fighter welfare stats. Hook → Heart.
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCompassionReminder() {
    final fact = _facts[_factIndex];
    final accent = AppColors.neonPink;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.07),
              AppColors.neonPurple.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.favorite, color: accent, size: 14),
                const SizedBox(width: 8),
                Text(
                  'THE REAL SCORE',
                  style: TextStyle(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                // Dot indicators
                Row(
                  children: List.generate(
                    _facts.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(left: 4),
                      width: i == _factIndex ? 14 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == _factIndex
                            ? accent
                            : accent.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Stat
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(_factIndex),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(fact.icon, color: accent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fact.stat,
                          style: TextStyle(
                            color: accent,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fact.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Tagline
            Text(
              'Love the sport. Respect the sacrifice.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 10,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            // CTA
            GestureDetector(
              onTap: () => context.push('/fighter-safety'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: accent.withValues(alpha: 0.1),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_outlined, color: accent, size: 13),
                    const SizedBox(width: 8),
                    Text(
                      'FIGHTER SAFETY PROTOCOL',
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FANTASY MATCHUP — Dream fights
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFantasyMatchup() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('FANTASY MATCHUPS', AppColors.neonPurple),
          const SizedBox(height: 4),
          Text(
            'Vote on the fights you want to see',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          _matchupCard(
            'MAKHACHEV',
            'PEREIRA',
            'P4P super fight — grappler vs KO artist',
            142,
            AppColors.neonRed,
            AppColors.neonOrange,
          ),
          _matchupCard(
            'TOPURIA',
            'HOLLOWAY',
            'Undefeated KO power vs infinite cardio',
            118,
            AppColors.neonGreen,
            AppColors.neonCyan,
          ),
          _matchupCard(
            'CRAWFORD',
            'INOUE',
            'Boxing dream fight — P4P legends collide',
            97,
            AppColors.neonCyan,
            AppColors.neonMagenta,
          ),
          _matchupCard(
            'DELLA MADDALENA',
            'WHITTAKER',
            'AU dream fight — Perth vs Sydney, who\'s the best?',
            73,
            AppColors.neonRed,
            AppColors.neonGreen,
          ),
          _matchupCard(
            'PEREIRA',
            'DU PLESSIS',
            'KO power vs African pressure — who breaks?',
            89,
            AppColors.neonOrange,
            AppColors.neonRed,
          ),
          _matchupCard(
            'TAWANCHAI',
            'SUPERBON',
            'ONE FC Muay Thai throne — ultimate striker showdown',
            64,
            AppColors.neonCyan,
            AppColors.neonMagenta,
          ),
        ],
      ),
    );
  }

  Widget _matchupCard(
    String a,
    String b,
    String tagline,
    int votes,
    Color colorA,
    Color colorB,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.push('/ai-fight-predictions'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorA,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.1),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      b,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorB,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tagline,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.how_to_vote,
                    color: Colors.white.withValues(alpha: 0.15),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${votes}K fans want this',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 10,
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

  Widget _label(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATA CLASSES
// ═════════════════════════════════════════════════════════════════════════════
class _Highlight {
  final String title, fighters, timing, views;
  final Color color;
  const _Highlight(
    this.title,
    this.fighters,
    this.timing,
    this.color,
    this.views,
  );
}

class _Ranked {
  final int rank;
  final String name, record, division, tag, move;
  final Color color;
  const _Ranked(
    this.rank,
    this.name,
    this.record,
    this.division,
    this.tag,
    this.color,
    this.move,
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// PULSE DOT — Animated live indicator
// ═════════════════════════════════════════════════════════════════════════════
class _PulseDot extends StatelessWidget {
  final Color color;
  final double phase;

  const _PulseDot({required this.color, required this.phase});

  @override
  Widget build(BuildContext context) {
    final p = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.5 + p * 0.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3 + p * 0.3),
            blurRadius: 6 + p * 4,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FIGHTER AVATAR — Simple name/record display
// ═════════════════════════════════════════════════════════════════════════════
class _FighterAvatar extends StatelessWidget {
  final String name, record;
  final Color color;

  const _FighterAvatar({
    required this.name,
    required this.record,
    required this.color,
  });

  String get _fighterImageUrl {
    const images = {
      'DELLA MADDALENA': ImageAssets.bgHero,
      'RAKHMONOV': ImageAssets.bgAction,
      'DVALISHVILI': ImageAssets.bgPromo,
      'WHITTAKER': ImageAssets.bgEvent,
      'O\'MALLEY': ImageAssets.bgCentral,
      'HOOKER': ImageAssets.bgSquare,
    };
    return images[name] ?? ImageAssets.bgLogoSmall;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipOval(
          child: SizedBox(
            width: 56,
            height: 56,
            child: Image.asset(
              _fighterImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.08),
                  border: Border.all(
                    color: color.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: color.withValues(alpha: 0.4),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        Text(
          record,
          style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 10),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CAGE WIRE — Background cage overlay
// ═════════════════════════════════════════════════════════════════════════════
class _CageWirePainter extends CustomPainter {
  final double phase;

  _CageWirePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonRed.withValues(alpha: 0.015)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Diagonal cage wire pattern
    const spacing = 40.0;
    for (double d = -size.height; d < size.width + size.height; d += spacing) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(d + size.height, 0),
        Offset(d, size.height),
        paint,
      );
    }

    // Corner spotlights
    final spotPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final p = math.sin(phase * math.pi * 2) * 0.5 + 0.5;
    spotPaint.color = AppColors.neonRed.withValues(alpha: 0.02 + p * 0.01);
    canvas.drawCircle(const Offset(0, 0), 120, spotPaint);

    spotPaint.color = AppColors.neonCyan.withValues(alpha: 0.01 + p * 0.005);
    canvas.drawCircle(Offset(size.width, 0), 100, spotPaint);
  }

  @override
  bool shouldRepaint(covariant _CageWirePainter old) => old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// LIVE PULSE — Heartbeat of the event
// ═════════════════════════════════════════════════════════════════════════════
class _LivePulsePainter extends CustomPainter {
  final double phase;

  _LivePulsePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (double x = 0; x <= size.width; x += 2) {
      final t = x / size.width;
      double y = size.height / 2;

      // Irregular heartbeat pattern
      final pos = (t + phase) % 1.0;
      if (pos > 0.3 && pos < 0.35) {
        y -= 15 * math.sin((pos - 0.3) / 0.05 * math.pi);
      } else if (pos > 0.36 && pos < 0.44) {
        y += 25 * math.sin((pos - 0.36) / 0.08 * math.pi);
      } else if (pos > 0.45 && pos < 0.5) {
        y -= 10 * math.sin((pos - 0.45) / 0.05 * math.pi);
      }

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.neonRed.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.neonRed.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant _LivePulsePainter old) => old.phase != phase;
}

// ═════════════════════════════════════════════════════════════════════════════
// CROWD PULSE — Aggregate fan energy visualization
// ═════════════════════════════════════════════════════════════════════════════
class _CrowdPulsePainter extends CustomPainter {
  final double phase;

  _CrowdPulsePainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 40;
    final barWidth = size.width / barCount - 2;
    final rng = math.Random(99);

    for (int i = 0; i < barCount; i++) {
      final baseH = rng.nextDouble() * 0.6 + 0.2;
      final p = math.sin(phase * math.pi * 4 + i * 0.3) * 0.2 + 0.8;
      final h = baseH * p * size.height;
      final x = i * (barWidth + 2);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, barWidth, h),
          const Radius.circular(2),
        ),
        Paint()
          ..color = AppColors.neonMagenta.withValues(alpha: 0.1 + baseH * 0.2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CrowdPulsePainter old) => old.phase != phase;
}
