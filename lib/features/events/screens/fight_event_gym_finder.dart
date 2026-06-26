import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT EVENT & GYM FINDER — Self-Contained with Real Demo Data
/// Map buttons navigate to DFC Gym Map. Badge tagging for DFC-certified gyms.
/// For educational & informational purposes only.
/// ═══════════════════════════════════════════════════════════════════════════
class FightEventGymFinder extends StatelessWidget {
  final List<FightEvent>? events;
  final List<GymLocation>? gyms;

  const FightEventGymFinder({this.events, this.gyms, super.key});

  static const _bg = Color(0xFF030810);
  static const _card = Color(0xFF0A1628);
  static const _cyan = Color(0xFF00E5FF);
  static const _red = Color(0xFFFF1744);
  static const _amber = Color(0xFFFFD600);
  static const _green = Color(0xFF00E676);
  static const _purple = Color(0xFF9C6FFF);

  List<FightEvent> get _events => events ?? defaultEvents;
  List<GymLocation> get _gyms => gyms ?? defaultGyms;

  void _goBackSafely(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg.withValues(alpha: 0.95),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _goBackSafely(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FIGHT EVENTS & GYMS',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'NEARBY · THIS WEEKEND · DFC TAGGED',
              style: TextStyle(
                fontSize: 7,
                color: Color(0xFF607090),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map, color: _cyan, size: 22),
            onPressed: () => context.push('/map'),
            tooltip: 'Open Full Map',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disclaimer
            _disclaimer(),
            const SizedBox(height: 16),
            _sectionTitle('🥊 FIGHT EVENTS THIS WEEKEND', _red),
            ..._events.map((e) => _buildEventCard(context, e)),
            const SizedBox(height: 24),
            _sectionTitle('🏟 DFC-TAGGED GYMS NEAR YOU', _purple),
            ..._gyms.map((g) => _buildGymCard(context, g)),
            const SizedBox(height: 24),
            // CTA — World Map
            GestureDetector(
              onTap: () => context.push('/fight-world-map'),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _cyan.withValues(alpha: 0.3)),
                ),
                child: const Center(
                  child: Text(
                    '🌍  VIEW EVENTS ON WORLD MAP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _cyan,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amber.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: _amber, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'For educational & informational purposes only. Event data is illustrative.',
              style: TextStyle(
                fontSize: 9,
                color: _amber.withValues(alpha: 0.7),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, FightEvent e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: e.isLive
              ? _red.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          // Date block
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.sports_mma, color: _red, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      e.sport,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: _cyan,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (e.isLive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '● LIVE',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: _red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  e.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.venue} · ${e.city}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                Text(
                  e.date,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.public, color: _cyan, size: 20),
            onPressed: () => context.push('/fight-world-map', extra: e),
            tooltip: 'View on World Map',
          ),
        ],
      ),
    );
  }

  Widget _buildGymCard(BuildContext context, GymLocation g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _purple.withValues(alpha: 0.3),
                  _cyan.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                g.name
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .take(2)
                    .map((w) => w[0])
                    .join()
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
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
                  g.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${g.city} · ${g.address}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          if (g.badge != GymBadge.none) ...[
            _badgeChip(g.badge),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.map, color: _cyan, size: 20),
            onPressed: () => context.push('/map'),
            tooltip: 'View on Map',
          ),
        ],
      ),
    );
  }

  Widget _badgeChip(GymBadge badge) {
    final (label, color, icon) = switch (badge) {
      GymBadge.gold => ('GOLD', _amber, Icons.star),
      GymBadge.diamond => ('DIAMOND', const Color(0xFF00E5FF), Icons.diamond),
      GymBadge.platinum => ('PLATINUM', _purple, Icons.workspace_premium),
      GymBadge.mentor => ('MENTOR', const Color(0xFFFF4081), Icons.favorite),
      _ => ('DFC', _green, Icons.verified),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DEFAULT DEMO DATA — Real events & gyms
  // ═════════════════════════════════════════════════════════════════════════
  static final defaultEvents = [
    const FightEvent(
      name: 'Hex Fight Series 25',
      city: 'Brisbane, QLD',
      venue: 'Brisbane Convention Centre',
      date: 'Sat Mar 8, 2026',
      latitude: -27.4710,
      longitude: 153.0234,
      isLive: true,
    ),
    const FightEvent(
      name: 'Eternal MMA 85',
      city: 'Gold Coast, QLD',
      venue: 'Gold Coast Convention Centre',
      date: 'Sat Mar 15, 2026',
      latitude: -28.0167,
      longitude: 153.4000,
    ),
    const FightEvent(
      name: 'UFC Fight Night — Apex',
      sport: 'UFC',
      city: 'Las Vegas, NV',
      venue: 'UFC Apex',
      date: 'Sat Mar 8, 2026',
      latitude: 36.1699,
      longitude: -115.1398,
      isLive: true,
    ),
    const FightEvent(
      name: 'ONE Friday Fights 144',
      sport: 'Muay Thai',
      city: 'Bangkok, Thailand',
      venue: 'Lumpinee Stadium',
      date: 'Fri Mar 7, 2026',
      latitude: 13.7563,
      longitude: 100.5018,
      isLive: true,
    ),
    const FightEvent(
      name: 'GLORY 95 Kickboxing',
      sport: 'Kickboxing',
      city: 'Amsterdam, NL',
      venue: 'Johan Cruyff Arena',
      date: 'Sat Apr 5, 2026',
      latitude: 52.3676,
      longitude: 4.9041,
    ),
    const FightEvent(
      name: 'Brace MMA 85',
      city: 'Melbourne, VIC',
      venue: 'Hisense Arena',
      date: 'Sat Mar 22, 2026',
      latitude: -37.8136,
      longitude: 144.9631,
    ),
    const FightEvent(
      name: 'DFC Community Fight Night',
      city: 'Logan, QLD',
      venue: 'Logan Community Hub',
      date: 'Sat Apr 5, 2026',
      latitude: -27.6274,
      longitude: 153.0846,
    ),
  ];

  static final defaultGyms = [
    const GymLocation(
      name: 'Elite Combat Team',
      city: 'Coconut Creek, FL',
      address: '5750 NW 17th Ave',
      latitude: 26.2470,
      longitude: -80.1788,
      badge: GymBadge.diamond,
    ),
    const GymLocation(
      name: 'AKA — Pacific Kickboxing Academy',
      city: 'San Jose, CA',
      address: '289 Oldfield Way',
      latitude: 37.3710,
      longitude: -121.9326,
      badge: GymBadge.gold,
    ),
    const GymLocation(
      name: 'Jackson Wink MMA',
      city: 'Albuquerque, NM',
      address: '901 Gold Ave',
      latitude: 35.0844,
      longitude: -106.6504,
      badge: GymBadge.gold,
    ),
    const GymLocation(
      name: 'Summit Fight Academy',
      city: 'Auckland, NZ',
      address: '7 Faraday St, Parnell',
      latitude: -36.8509,
      longitude: 174.7740,
      badge: GymBadge.diamond,
    ),
    const GymLocation(
      name: 'Golden Dragon Muay Thai',
      city: 'Phuket, Thailand',
      address: '7/6 Moo 5, Soi Ta-iad',
      latitude: 7.8854,
      longitude: 98.3388,
      badge: GymBadge.gold,
    ),
    const GymLocation(
      name: 'DFC HQ Gym',
      city: 'Woodridge, QLD',
      address: 'DFC Headquarters',
      latitude: -27.6274,
      longitude: 153.0846,
      badge: GymBadge.platinum,
    ),
    const GymLocation(
      name: 'Absolute MMA Melbourne',
      city: 'Melbourne, VIC',
      address: '124 Lygon St, Brunswick East',
      latitude: -37.7700,
      longitude: 144.9620,
      badge: GymBadge.gold,
    ),
    const GymLocation(
      name: 'Celtic Combat Ireland',
      city: 'Dublin, Ireland',
      address: 'Naas Rd, Dublin 12',
      latitude: 53.3331,
      longitude: -6.3440,
      badge: GymBadge.diamond,
    ),
    const GymLocation(
      name: 'Evolve MMA',
      city: 'Singapore',
      address: '26 China St',
      latitude: 1.2834,
      longitude: 103.8480,
      badge: GymBadge.gold,
    ),
    const GymLocation(
      name: 'UFC Performance Institute',
      city: 'Las Vegas, NV',
      address: '6820 Losee Rd',
      latitude: 36.2500,
      longitude: -115.1500,
      badge: GymBadge.diamond,
    ),
  ];
}

class FightEvent {
  final String name;
  final String sport;
  final String city;
  final String venue;
  final String date;
  final double latitude;
  final double longitude;
  final bool isLive;

  const FightEvent({
    required this.name,
    this.sport = 'MMA',
    required this.city,
    required this.venue,
    required this.date,
    required this.latitude,
    required this.longitude,
    this.isLive = false,
  });
}

class GymLocation {
  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final GymBadge badge;

  const GymLocation({
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.badge = GymBadge.none,
  });
}

enum GymBadge { none, gold, diamond, platinum, mentor }
