import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// IBC III — FULL FIGHT CARD & PREDICTIONS
// Bout-by-bout breakdown with fighter profiles, AI predictions, fan voting
// ═══════════════════════════════════════════════════════════════════════════════

class IbcFightCardScreen extends StatefulWidget {
  const IbcFightCardScreen({super.key});

  @override
  State<IbcFightCardScreen> createState() => _IbcFightCardScreenState();
}

class _IbcFightCardScreenState extends State<IbcFightCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // Fan voting state
  final Map<String, String> _fanPicks = {};

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // REAL IBC 3 FIGHT CARD — Tapology verified
  // Gold Coast Sports & Leisure Centre · March 7, 2026
  // ═══════════════════════════════════════════════════════════════
  static const _fights = [
    // ── IBC CHAMPIONSHIP BOUTS ──
    _BoutData(
      id: 'ibc-main',
      label: 'MAIN EVENT',
      fighter1: 'Jay Cutler',
      fighter2: 'Luke Modini',
      f1Id: 'jay-cutler',
      f2Id: 'luke-modini',
      weight: 'Light Heavyweight Title',
      rounds: 5,
      isTitle: true,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Power Striker / Pressure Fighter',
      f2Style: 'Counter Puncher / Ring IQ',
      f1Streak: 'IBC Title Shot',
      f2Streak: 'Wynnum, QLD',
      aiPick: 'Cutler',
      aiMethod: 'TKO R4',
      aiConfidence: 58,
      color: Colors.amberAccent,
    ),
    _BoutData(
      id: 'ibc-co-main',
      label: 'CO-MAIN',
      fighter1: 'Isaac Hardman',
      fighter2: 'Jonathan Tuhu',
      f1Id: 'isaac-hardman',
      f2Id: 'jonathan-tuhu',
      weight: 'IBC Championship',
      rounds: 5,
      isTitle: true,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Power / The Headsplitter',
      f2Style: 'Brawler / Pressure',
      f1Streak: 'KO R1 (IBC 02)',
      f2Streak: 'Mardi, NSW',
      aiPick: 'Hardman',
      aiMethod: 'KO R2',
      aiConfidence: 72,
      color: Colors.redAccent,
    ),
    // ── MAIN CARD ──
    _BoutData(
      id: 'ibc-3',
      label: 'MAIN CARD',
      fighter1: 'Boaz Kapua',
      fighter2: 'A. Rosinhaskev',
      f1Id: 'boaz-kapua',
      f2Id: 'a-rosinhaskev',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Power Striker',
      f2Style: 'Technical / Precision',
      f1Streak: 'IBC Veteran',
      f2Streak: 'Sydney, NSW',
      aiPick: 'Kapua',
      aiMethod: 'Decision',
      aiConfidence: 55,
      color: Colors.cyanAccent,
    ),
    _BoutData(
      id: 'ibc-4',
      label: 'MAIN CARD',
      fighter1: 'Andrew Loulanting',
      fighter2: 'Bruce Irvine',
      f1Id: 'andrew-loulanting',
      f2Id: 'bruce-irvine',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Volume Striker / Pace',
      f2Style: 'Brawler / Heavy Hands',
      f1Streak: 'IBC Debut',
      f2Streak: 'IBC Debut',
      aiPick: 'Loulanting',
      aiMethod: 'Decision',
      aiConfidence: 52,
      color: Colors.cyanAccent,
    ),
    _BoutData(
      id: 'ibc-5',
      label: 'MAIN CARD',
      fighter1: 'Noah Stevens',
      fighter2: 'Ronny Hull',
      f1Id: 'noah-stevens',
      f2Id: 'ronny-hull',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Aggressive / Forward Pressure',
      f2Style: 'Counter Puncher / Movement',
      f1Streak: 'IBC Debut',
      f2Streak: 'Newcastle, NSW',
      aiPick: 'Stevens',
      aiMethod: 'TKO R2',
      aiConfidence: 54,
      color: Colors.greenAccent,
    ),
    _BoutData(
      id: 'ibc-6',
      label: 'MAIN CARD',
      fighter1: 'Mikey Vaotusa',
      fighter2: 'Jarrod Kaye',
      f1Id: 'mikey-vaotusa',
      f2Id: 'jarrod-kaye',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Power / KO Artist',
      f2Style: 'Technical Boxer / Range',
      f1Streak: 'The Entrance, NSW',
      f2Streak: 'IBC Debut',
      aiPick: 'Vaotusa',
      aiMethod: 'KO R1',
      aiConfidence: 60,
      color: Colors.orangeAccent,
    ),
    _BoutData(
      id: 'ibc-7',
      label: 'MAIN CARD',
      fighter1: 'Corban Mita',
      fighter2: 'Josh Eccles',
      f1Id: 'corban-mita',
      f2Id: 'josh-eccles',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Brawler / Pressure Fighter',
      f2Style: 'Slick Counter Fighter',
      f1Streak: 'Gold Coast, QLD',
      f2Streak: 'IBC Debut',
      aiPick: 'Mita',
      aiMethod: 'Decision',
      aiConfidence: 56,
      color: Colors.pinkAccent,
    ),
    _BoutData(
      id: 'ibc-8',
      label: 'UNDERCARD',
      fighter1: 'Selwyn Alexander',
      fighter2: 'Petaia Mason',
      f1Id: 'selwyn-alexander',
      f2Id: 'petaia-mason',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Volume Striker / Pace',
      f2Style: 'Power / Heavy Hands',
      f1Streak: 'Gold Coast, QLD',
      f2Streak: 'IBC Debut',
      aiPick: 'Alexander',
      aiMethod: 'Decision',
      aiConfidence: 53,
      color: Colors.greenAccent,
    ),
    _BoutData(
      id: 'ibc-9',
      label: 'UNDERCARD',
      fighter1: 'Gaz Phillips',
      fighter2: 'Damien Johnson',
      f1Id: 'gaz-phillips',
      f2Id: 'damien-johnson',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Aggressive / Forward Pressure',
      f2Style: 'Technical / Ring Craft',
      f1Streak: 'IBC Debut',
      f2Streak: 'IBC Debut',
      aiPick: 'Phillips',
      aiMethod: 'TKO R3',
      aiConfidence: 51,
      color: Colors.cyanAccent,
    ),
    _BoutData(
      id: 'ibc-10',
      label: 'UNDERCARD',
      fighter1: 'Brayden Ion',
      fighter2: 'Spencer Hepi',
      f1Id: 'brayden-ion',
      f2Id: 'spencer-hepi',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Brawler / Durability',
      f2Style: 'Speed / Combination Puncher',
      f1Streak: 'Hobart, TAS',
      f2Streak: 'IBC Debut',
      aiPick: 'Ion',
      aiMethod: 'Decision',
      aiConfidence: 50,
      color: Colors.purpleAccent,
    ),
    _BoutData(
      id: 'ibc-11',
      label: 'OPENER',
      fighter1: 'Jay Hepi',
      fighter2: 'Tui Halcrow',
      f1Id: 'jay-hepi',
      f2Id: 'tui-halcrow',
      weight: 'Pro Bout',
      rounds: 3,
      isTitle: false,
      f1Record: 'Pro',
      f2Record: 'Pro',
      f1Style: 'Power Striker',
      f2Style: 'Counter Puncher / Movement',
      f1Streak: 'IBC Debut',
      f2Streak: 'IBC Debut',
      aiPick: 'Hepi',
      aiMethod: 'KO R2',
      aiConfidence: 55,
      color: Colors.orangeAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A1A),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A0A00), Color(0xFF050510)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.cyanAccent.withValues(alpha: 0.4),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.handshake,
                                  color: Colors.cyanAccent,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'DFC × IBC',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'IBC III — FIGHT CARD',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Gold Coast Sports & Leisure Centre · March 7, 2026 · 7 PM AEST',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'CLOSED-FIST HYBRID · NO GRAPPLING · ALL ACTION',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── PPV Banner ──
                _ppvBanner(),
                const SizedBox(height: 10),
                _eventDayBanner(),
                const SizedBox(height: 20),

                // ── Each Bout ──
                ..._fights.expand(
                  (bout) => [_boutCard(bout), const SizedBox(height: 16)],
                ),

                // ── Fan Picks Summary ──
                if (_fanPicks.isNotEmpty) ...[
                  _fanPicksSummary(),
                  const SizedBox(height: 16),
                ],

                // ── Rules Box ──
                _rulesCard(),
                const SizedBox(height: 16),

                // ── Broadcast Info ──
                _broadcastCard(),
                const SizedBox(height: 16),

                // ── Back to Partnership Hub ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.handshake, size: 16),
                    label: const Text('BACK TO DFC × IBC HUB'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyanAccent,
                      side: const BorderSide(color: Colors.cyanAccent),
                      padding: const EdgeInsets.all(14),
                    ),
                    onPressed: () => context.push('/ibc'),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _ppvBanner() {
    return GestureDetector(
      onTap: () => context.push('/ppv/ppv-ibc-03/watch'),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => Transform.scale(
          scale: _pulse.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade900, Colors.deepOrange.shade900],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.live_tv, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WATCH PPV — \$29.99 AUD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Watch LIVE on DFC · TrillerTV+ · Kayo',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventDayBanner() {
    return GestureDetector(
      onTap: () => context.push('/ibc/live'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900,
              Colors.cyanAccent.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.sports_mma, color: Colors.cyanAccent, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IBC EVENT DAY HUB',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Countdown, how to watch, venue info & more',
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _boutCard(_BoutData bout) {
    final pick = _fanPicks[bout.id];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bout.color.withValues(alpha: bout.isTitle ? 0.15 : 0.06),
            const Color(0xFF0A0A14),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bout.color.withValues(alpha: bout.isTitle ? 0.5 : 0.2),
          width: bout.isTitle ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: bout.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bout.label,
                  style: TextStyle(
                    color: bout.color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (bout.isTitle) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.emoji_events,
                  color: Colors.amberAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                const Text(
                  'TITLE FIGHT',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '${bout.weight} · ${bout.rounds} Rds',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // VS Row
          Row(
            children: [
              Expanded(
                child: _fighterCol(
                  bout.fighter1,
                  bout.f1Record,
                  bout.f1Style,
                  bout.f1Streak,
                  bout.color,
                  true,
                  bout.f1Id,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        color: bout.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.sports_mma,
                      color: bout.color.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _fighterCol(
                  bout.fighter2,
                  bout.f2Record,
                  bout.f2Style,
                  bout.f2Streak,
                  bout.color,
                  false,
                  bout.f2Id,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI Prediction
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.purpleAccent,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'AI PICK: ',
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${bout.aiPick} via ${bout.aiMethod}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '${bout.aiConfidence}%',
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Fan Vote
          Row(
            children: [
              const Text(
                'YOUR PICK: ',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _voteBtn(
                bout.id,
                bout.fighter1,
                bout.color,
                pick == bout.fighter1,
              ),
              const SizedBox(width: 8),
              _voteBtn(
                bout.id,
                bout.fighter2,
                bout.color,
                pick == bout.fighter2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fighterCol(
    String name,
    String record,
    String style,
    String streak,
    Color color,
    bool isLeft,
    String fighterId,
  ) {
    return GestureDetector(
      onTap: () => context.push('/fighter/$fighterId'),
      child: Column(
        crossAxisAlignment: isLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Text(
            name.toUpperCase(),
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            record,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            style,
            textAlign: isLeft ? TextAlign.left : TextAlign.right,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            'Streak: $streak',
            style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            'TAP FOR PROFILE →',
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _voteBtn(String boutId, String fighter, Color color, bool selected) {
    final lastName = fighter.split(' ').last;
    return GestureDetector(
      onTap: () => setState(() => _fanPicks[boutId] = fighter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Colors.white24),
        ),
        child: Text(
          lastName.toUpperCase(),
          style: TextStyle(
            color: selected ? color : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _fanPicksSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.how_to_vote, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 8),
              Text(
                'YOUR PICKS',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._fanPicks.entries.map((e) {
            final bout = _fights.firstWhere((b) => b.id == e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${bout.label}: ${e.value}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _rulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.gavel, color: Colors.redAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'IBC RULES',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ruleItem('Closed-fist strikes only — no open hand'),
          _ruleItem('No grappling, clinching, or takedowns'),
          _ruleItem('No elbows or knees'),
          _ruleItem('Standing 8-count applies'),
          _ruleItem('Three knockdown rule in effect'),
          _ruleItem('Referee can stop fight at any time for safety'),
          _ruleItem('Title fights: 5 × 2-minute rounds'),
          _ruleItem('Non-title: 3 × 2-minute rounds'),
        ],
      ),
    );
  }

  Widget _ruleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _broadcastCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade900.withValues(alpha: 0.4),
            Colors.blue.shade900.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.live_tv, color: Colors.cyanAccent, size: 18),
              SizedBox(width: 8),
              Text(
                'WHERE TO WATCH',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _BroadcastRow(
            icon: Icons.sports_mma,
            label: 'DFC Platform',
            detail: 'datafightcentral.com',
            color: Colors.cyanAccent,
          ),
          _BroadcastRow(
            icon: Icons.tv,
            label: 'TrillerTV+',
            detail: 'PPV — trillertv.com',
            color: Colors.amberAccent,
          ),
          _BroadcastRow(
            icon: Icons.sports,
            label: 'Kayo Sports',
            detail: 'PPV — kayosports.com.au',
            color: Colors.greenAccent,
          ),
          _BroadcastRow(
            icon: Icons.confirmation_number,
            label: 'In-Person',
            detail: 'Eventbrite — Gold Coast Sports & Leisure Centre',
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}

class _BroadcastRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  const _BroadcastRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detail,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoutData {
  final String id, label, fighter1, fighter2, weight;
  final String f1Id, f2Id;
  final int rounds;
  final bool isTitle;
  final String f1Record, f2Record, f1Style, f2Style, f1Streak, f2Streak;
  final String aiPick, aiMethod;
  final int aiConfidence;
  final Color color;

  const _BoutData({
    required this.id,
    required this.label,
    required this.fighter1,
    required this.fighter2,
    required this.weight,
    required this.rounds,
    required this.isTitle,
    required this.f1Id,
    required this.f2Id,
    required this.f1Record,
    required this.f2Record,
    required this.f1Style,
    required this.f2Style,
    required this.f1Streak,
    required this.f2Streak,
    required this.aiPick,
    required this.aiMethod,
    required this.aiConfidence,
    required this.color,
  });
}
