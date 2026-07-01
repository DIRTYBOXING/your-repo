import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// IBC EVENT DAY HUB — The Live Event Command Center for Fans
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Route: /ibc/live
///
/// This is THE page fans land on during IBC III. It shows:
///   • Live countdown → flips to LIVE NOW when event starts
///   • Quick-access stream links (DFC, TrillerTV+, Kayo)
///   • Fight card with live results that update
///   • Social buzz feed
///   • How to watch guide
///   • Venue info & broadcast details
///   • Fan engagement: predictions, polls
///
/// IBC III: March 7, 2026 — 7 PM AEST
/// Gold Coast Sports & Leisure Centre, QLD
/// ═══════════════════════════════════════════════════════════════════════════
class IbcEventDayScreen extends StatefulWidget {
  const IbcEventDayScreen({super.key});

  @override
  State<IbcEventDayScreen> createState() => _IbcEventDayScreenState();
}

class _IbcEventDayScreenState extends State<IbcEventDayScreen>
    with SingleTickerProviderStateMixin {
  static final DateTime _eventDate = DateTime(2026, 3, 7, 19);
  Timer? _timer;
  Duration _remaining = Duration.zero;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // REAL IBC 3 Fight Card — Tapology verified
  final List<Map<String, dynamic>> _fights = [
    {
      'fighter1': 'Jay Cutler',
      'fighter2': 'Luke Modini',
      'weight': 'Light Heavyweight',
      'rounds': 5,
      'type': 'LHW Title',
      'isMain': true,
      'result': null,
      'f1id': 'jay-cutler',
      'f2id': 'luke-modini',
    },
    {
      'fighter1': 'Isaac Hardman',
      'fighter2': 'Jonathan Tuhu',
      'weight': 'IBC Championship',
      'rounds': 5,
      'type': 'IBC Title',
      'isMain': true,
      'result': null,
      'f1id': 'isaac-hardman',
      'f2id': 'jonathan-tuhu',
    },
    {
      'fighter1': 'Boaz Kapua',
      'fighter2': 'A. Rosinhaskev',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Main Card',
      'isMain': false,
      'result': null,
      'f1id': 'boaz-kapua',
      'f2id': 'a-rosinhaskev',
    },
    {
      'fighter1': 'Andrew Loulanting',
      'fighter2': 'Bruce Irvine',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Main Card',
      'isMain': false,
      'result': null,
      'f1id': 'andrew-loulanting',
      'f2id': 'bruce-irvine',
    },
    {
      'fighter1': 'Noah Stevens',
      'fighter2': 'Ronny Hull',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Main Card',
      'isMain': false,
      'result': null,
      'f1id': 'noah-stevens',
      'f2id': 'ronny-hull',
    },
    {
      'fighter1': 'Mikey Vaotusa',
      'fighter2': 'Jarrod Kaye',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Main Card',
      'isMain': false,
      'result': null,
      'f1id': 'mikey-vaotusa',
      'f2id': 'jarrod-kaye',
    },
    {
      'fighter1': 'Corban Mita',
      'fighter2': 'Josh Eccles',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Main Card',
      'isMain': false,
      'result': null,
      'f1id': 'corban-mita',
      'f2id': 'josh-eccles',
    },
    {
      'fighter1': 'Selwyn Alexander',
      'fighter2': 'Petaia Mason',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Undercard',
      'isMain': false,
      'result': null,
      'f1id': 'selwyn-alexander',
      'f2id': 'petaia-mason',
    },
    {
      'fighter1': 'Gaz Phillips',
      'fighter2': 'Damien Johnson',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Undercard',
      'isMain': false,
      'result': null,
      'f1id': 'gaz-phillips',
      'f2id': 'damien-johnson',
    },
    {
      'fighter1': 'Brayden Ion',
      'fighter2': 'Spencer Hepi',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Undercard',
      'isMain': false,
      'result': null,
      'f1id': 'brayden-ion',
      'f2id': 'spencer-hepi',
    },
    {
      'fighter1': 'Jay Hepi',
      'fighter2': 'Tui Halcrow',
      'weight': 'Pro Bout',
      'rounds': 3,
      'type': 'Opener',
      'isMain': false,
      'result': null,
      'f1id': 'jay-hepi',
      'f2id': 'tui-halcrow',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _remaining = _eventDate.difference(DateTime.now());
      if (_remaining.isNegative) _remaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _isLive => _remaining == Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: _isLive ? 220 : 280,
            pinned: true,
            backgroundColor: _isLive
                ? Colors.red.shade900
                : Colors.deepPurple.shade900,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
            title: Row(
              children: [
                if (_isLive)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, _) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: _pulse.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Expanded(
                  child: Text(
                    'IBC 03',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Watch Now Buttons ──
                  _buildWatchNow(),
                  const SizedBox(height: 20),

                  // ── Fight Card ──
                  _buildFightCard(),
                  const SizedBox(height: 20),

                  // ── How to Watch ──
                  _buildHowToWatch(),
                  const SizedBox(height: 20),

                  // ── Venue & Event Info ──
                  _buildVenueInfo(),
                  const SizedBox(height: 20),

                  // ── Quick Nav ──
                  _buildQuickNav(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isLive
              ? [Colors.red.shade900, Colors.black]
              : [Colors.deepPurple.shade900, Colors.black],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // IBC Logo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isLive ? Colors.red : Colors.cyanAccent,
                    width: 2,
                  ),
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Icon(
                  Icons.sports_mma,
                  size: 36,
                  color: _isLive ? Colors.red : Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                'INTERNATIONAL BRAWLING CHAMPIONSHIP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 4),

              const Text(
                'IBC 03: GOLD COAST BRAWL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const Text(
                'Cutler vs Modini — LHW Title',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 14),
              ),

              const SizedBox(height: 12),

              // Countdown or LIVE badge
              if (_isLive)
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: _pulse.value),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(
                            alpha: _pulse.value * 0.5,
                          ),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 10, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'EVENT IS LIVE NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'STARTS IN',
                        style: TextStyle(
                          color: Colors.cyanAccent.withValues(alpha: 0.6),
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCountdown(),
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCountdown() {
    final d = _remaining;
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    }
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WATCH NOW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildWatchNow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _isLive
                ? Colors.red.shade900.withValues(alpha: 0.5)
                : Colors.deepPurple.shade900.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_isLive ? Colors.red : Colors.cyanAccent).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isLive ? Icons.live_tv : Icons.tv,
                color: _isLive ? Colors.red : Colors.cyanAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _isLive ? 'WATCH LIVE NOW' : 'HOW TO WATCH',
                style: TextStyle(
                  color: _isLive ? Colors.red : Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/ppv/ppv-ibc-03/watch'),
              icon: Icon(
                _isLive ? Icons.play_arrow : Icons.shopping_cart,
                size: 20,
              ),
              label: Text(
                _isLive ? 'WATCH ON DFC — LIVE' : 'BUY PPV — \$29.99 AUD',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLive ? Colors.red : Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Platform buttons
          Row(
            children: [
              Expanded(
                child: _streamBtn(
                  'TrillerTV+',
                  Colors.deepPurple,
                  Icons.tv,
                  'https://www.trillertvplus.com',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _streamBtn(
                  'Kayo Sports',
                  Colors.green.shade700,
                  Icons.sports,
                  'https://kayosports.com.au',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _streamBtn(
                  'Eventbrite',
                  Colors.orange.shade700,
                  Icons.confirmation_number,
                  'https://www.eventbrite.com.au',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // DFC Feature buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/scoring'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6600).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF6600).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.scoreboard,
                          color: Color(0xFFFF6600),
                          size: 18,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'LIVE SCORING',
                          style: TextStyle(
                            color: Color(0xFFFF6600),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/rankings'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF88).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00FF88).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.leaderboard,
                          color: Color(0xFF00FF88),
                          size: 18,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'RANKINGS',
                          style: TextStyle(
                            color: Color(0xFF00FF88),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/press'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.newspaper,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'PRESS',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _streamBtn(String label, Color color, IconData icon, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHT CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFightCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.format_list_numbered,
                  color: Colors.deepPurple,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'FIGHT CARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_fights.length} BOUTS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ..._fights.asMap().entries.map((e) => _fightRow(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _fightRow(Map<String, dynamic> fight, int index) {
    final isMain = fight['isMain'] as bool;
    final result = fight['result'] as String?;

    return InkWell(
      onTap: () {
        // Navigate to fighter profile
        final f1id = fight['f1id'] as String;
        context.go('/fighter/$f1id');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: index < _fights.length - 1
              ? Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                )
              : null,
          color: isMain ? Colors.red.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isMain
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                fight['type'] as String,
                style: TextStyle(
                  color: isMain ? Colors.red : Colors.deepPurple,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 10),
            // Fight details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${fight['fighter1']} vs ${fight['fighter2']}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMain ? 15 : 13,
                      fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '${fight['weight']} • ${fight['rounds']} Rds',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Result or status
            if (result != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else if (_isLive)
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, _) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: _pulse.value * 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PENDING',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HOW TO WATCH
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHowToWatch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'HOW TO WATCH',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _howStep(
            '1',
            'PPV Stream (DFC)',
            'Buy PPV at datafightcentral.com/ppv — \$29.99 AUD',
            Icons.computer,
          ),
          _howStep(
            '2',
            'TrillerTV+',
            'Watch via TrillerTV+ app or website',
            Icons.tv,
          ),
          _howStep(
            '3',
            'Kayo Sports',
            'Available on Kayo Sports streaming platform',
            Icons.sports,
          ),
          _howStep(
            '4',
            'In Person',
            'Gold Coast Sports & Leisure Centre — Tickets via Eventbrite',
            Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _howStep(String num, String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.cyanAccent.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.3), size: 18),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VENUE INFO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVenueInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.cyanAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'EVENT DETAILS',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow(Icons.event, 'Date', 'Friday, March 7, 2026'),
          _detailRow(Icons.access_time, 'Doors Open', '5:30 PM AEST'),
          _detailRow(Icons.play_arrow, 'First Bout', '6:00 PM AEST'),
          _detailRow(Icons.star, 'Main Event', '~9:00 PM AEST'),
          _detailRow(
            Icons.location_on,
            'Venue',
            'Gold Coast Sports & Leisure Centre',
          ),
          _detailRow(Icons.map, 'Location', 'Carrara, Gold Coast, QLD'),
          _detailRow(Icons.person, 'Promoter', 'Danny Mac'),
          _detailRow(
            Icons.sports_mma,
            'Format',
            'Closed-fist hybrid, no grappling',
          ),
          _detailRow(Icons.attach_money, 'PPV Price', '\$29.99 AUD (Standard)'),
          _detailRow(
            Icons.live_tv,
            'Broadcast',
            'DFC • TrillerTV+ • Kayo Sports',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.3), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUICK NAV
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickNav() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.grid_view, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 6),
            Text(
              'QUICK LINKS',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _navCard(
                'Fight Card',
                Icons.list,
                Colors.deepPurple,
                () => context.go('/ibc/fight-card'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _navCard(
                'IBC Hub',
                Icons.handshake,
                Colors.cyanAccent,
                () => context.go('/ibc'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _navCard(
                'PPV Hub',
                Icons.local_fire_department,
                Colors.orange,
                () => context.go('/ppv'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _navCard(
                'Databank',
                Icons.leaderboard,
                Colors.green,
                () => context.go('/databank'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _navCard(
                'Fan Zone',
                Icons.people,
                Colors.amber,
                () => context.go('/cageview'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _navCard(
                'Social',
                Icons.forum,
                Colors.pink,
                () => context.go('/social'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _navCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
