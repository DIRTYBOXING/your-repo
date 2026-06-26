import 'dart:async';

// ══════════════════════════════════════════════════════════════════════════════
// BETTING ODDS AGGREGATOR SERVICE
// ══════════════════════════════════════════════════════════════════════════════
//
// DFC does NOT do gambling. Zero.
// But we position ourselves WHERE the sports bettor searches happen.
// We crawl every major sportsbook for combat sport odds, display them as
// pure data/stats, and funnel that traffic into DFC's ecosystem.
//
// The bettor comes for the odds comparison → stays for the PPV, stats,
// fighter profiles, and community. That's the play.
//
// Supported sources (public odds feeds):
//   - DraftKings, FanDuel, BetMGM, Bet365, PointsBet
//   - TAB (AU/NZ), Sportsbet (AU), Ladbrokes (AU/UK)
//   - William Hill, Betfair, Unibet, Pinnacle
//
// ══════════════════════════════════════════════════════════════════════════════

class BettingOddsAggregatorService {
  BettingOddsAggregatorService._();
  static final instance = BettingOddsAggregatorService._();

  // Supported sportsbooks we crawl
  static const List<String> supportedBooks = [
    'DraftKings',
    'FanDuel',
    'BetMGM',
    'Bet365',
    'PointsBet',
    'TAB',
    'Sportsbet',
    'Ladbrokes',
    'William Hill',
    'Betfair',
    'Unibet',
    'Pinnacle',
  ];

  // Combat sport categories we index for SEO
  static const List<String> combatCategories = [
    'UFC',
    'Bellator',
    'ONE Championship',
    'PFL',
    'BKFC',
    'Boxing',
    'Muay Thai',
    'Kickboxing',
    'Glory',
    'RIZIN',
    'Cage Warriors',
    'Hex Fight Series',
    'IBC',
  ];

  /// Fetch aggregated odds for an upcoming event.
  /// Returns a list of fight cards with odds from every sportsbook.
  Future<List<FightOddsCard>> getEventOdds(String eventName) async {
    // In production this hits a Cloud Function that crawls public odds APIs.
    // For now, return rich demo data that powers the UI and SEO.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _demoEventOdds(eventName);
  }

  /// Get trending fights by odds movement (biggest line shifts).
  /// This is the SEO magnet — "biggest odds movement UFC 323" etc.
  Future<List<OddsMovement>> getTrendingOddsMovements() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _demoOddsMovements;
  }

  /// Fetch all upcoming events with odds available.
  Future<List<EventOddsSummary>> getUpcomingEventsWithOdds() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _demoUpcomingEvents;
  }

  /// Convert American odds to implied probability for display.
  static double impliedProbability(int americanOdds) {
    if (americanOdds > 0) {
      return 100.0 / (americanOdds + 100);
    } else {
      return americanOdds.abs() / (americanOdds.abs() + 100);
    }
  }

  /// Format American odds with + sign for underdogs.
  static String formatOdds(int odds) {
    return odds > 0 ? '+$odds' : '$odds';
  }

  /// Get best available odds across all books for a fighter.
  static BookOdds? bestOdds(List<BookOdds> allOdds) {
    if (allOdds.isEmpty) return null;
    return allOdds.reduce((a, b) => a.americanOdds > b.americanOdds ? a : b);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class FightOddsCard {
  final String fighter1;
  final String fighter2;
  final String weightClass;
  final bool isMainEvent;
  final bool isTitleFight;
  final List<BookOdds> fighter1Odds;
  final List<BookOdds> fighter2Odds;

  const FightOddsCard({
    required this.fighter1,
    required this.fighter2,
    required this.weightClass,
    this.isMainEvent = false,
    this.isTitleFight = false,
    this.fighter1Odds = const [],
    this.fighter2Odds = const [],
  });

  /// Consensus favorite based on average odds
  String get favorite {
    if (fighter1Odds.isEmpty || fighter2Odds.isEmpty) return fighter1;
    final avg1 =
        fighter1Odds.map((o) => o.americanOdds).reduce((a, b) => a + b) /
        fighter1Odds.length;
    final avg2 =
        fighter2Odds.map((o) => o.americanOdds).reduce((a, b) => a + b) /
        fighter2Odds.length;
    return avg1 < avg2 ? fighter1 : fighter2;
  }
}

class BookOdds {
  final String sportsbook;
  final int americanOdds;
  final DateTime lastUpdated;

  const BookOdds({
    required this.sportsbook,
    required this.americanOdds,
    required this.lastUpdated,
  });

  String get formatted => BettingOddsAggregatorService.formatOdds(americanOdds);
}

class OddsMovement {
  final String fighter;
  final String opponent;
  final String event;
  final int openingOdds;
  final int currentOdds;
  final String direction; // 'steaming' or 'drifting'

  const OddsMovement({
    required this.fighter,
    required this.opponent,
    required this.event,
    required this.openingOdds,
    required this.currentOdds,
    required this.direction,
  });

  int get shift => currentOdds - openingOdds;
}

class EventOddsSummary {
  final String eventName;
  final String organization;
  final String date;
  final int fightCount;
  final int booksAvailable;
  final String mainEvent;
  final bool hasLiveOdds;

  const EventOddsSummary({
    required this.eventName,
    required this.organization,
    required this.date,
    required this.fightCount,
    required this.booksAvailable,
    required this.mainEvent,
    this.hasLiveOdds = false,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// DEMO DATA — Powers UI and SEO indexing
// ══════════════════════════════════════════════════════════════════════════════

List<FightOddsCard> _demoEventOdds(String eventName) {
  final now = DateTime.now();
  return [
    FightOddsCard(
      fighter1: 'Islam Makhachev',
      fighter2: 'Charles Oliveira',
      weightClass: 'Lightweight',
      isMainEvent: true,
      isTitleFight: true,
      fighter1Odds: [
        BookOdds(
          sportsbook: 'DraftKings',
          americanOdds: -250,
          lastUpdated: now,
        ),
        BookOdds(sportsbook: 'FanDuel', americanOdds: -240, lastUpdated: now),
        BookOdds(sportsbook: 'BetMGM', americanOdds: -260, lastUpdated: now),
        BookOdds(sportsbook: 'Bet365', americanOdds: -245, lastUpdated: now),
        BookOdds(sportsbook: 'TAB', americanOdds: -255, lastUpdated: now),
        BookOdds(sportsbook: 'Sportsbet', americanOdds: -248, lastUpdated: now),
      ],
      fighter2Odds: [
        BookOdds(sportsbook: 'DraftKings', americanOdds: 200, lastUpdated: now),
        BookOdds(sportsbook: 'FanDuel', americanOdds: 195, lastUpdated: now),
        BookOdds(sportsbook: 'BetMGM', americanOdds: 210, lastUpdated: now),
        BookOdds(sportsbook: 'Bet365', americanOdds: 200, lastUpdated: now),
        BookOdds(sportsbook: 'TAB', americanOdds: 205, lastUpdated: now),
        BookOdds(sportsbook: 'Sportsbet', americanOdds: 198, lastUpdated: now),
      ],
    ),
    FightOddsCard(
      fighter1: 'Alexander Volkanovski',
      fighter2: 'Ilia Topuria',
      weightClass: 'Featherweight',
      isTitleFight: true,
      fighter1Odds: [
        BookOdds(sportsbook: 'DraftKings', americanOdds: 140, lastUpdated: now),
        BookOdds(sportsbook: 'FanDuel', americanOdds: 145, lastUpdated: now),
        BookOdds(sportsbook: 'Bet365', americanOdds: 135, lastUpdated: now),
        BookOdds(sportsbook: 'Pinnacle', americanOdds: 150, lastUpdated: now),
      ],
      fighter2Odds: [
        BookOdds(
          sportsbook: 'DraftKings',
          americanOdds: -165,
          lastUpdated: now,
        ),
        BookOdds(sportsbook: 'FanDuel', americanOdds: -170, lastUpdated: now),
        BookOdds(sportsbook: 'Bet365', americanOdds: -160, lastUpdated: now),
        BookOdds(sportsbook: 'Pinnacle', americanOdds: -175, lastUpdated: now),
      ],
    ),
    FightOddsCard(
      fighter1: 'Sean O\'Malley',
      fighter2: 'Merab Dvalishvili',
      weightClass: 'Bantamweight',
      isTitleFight: true,
      fighter1Odds: [
        BookOdds(
          sportsbook: 'DraftKings',
          americanOdds: -130,
          lastUpdated: now,
        ),
        BookOdds(sportsbook: 'FanDuel', americanOdds: -125, lastUpdated: now),
        BookOdds(sportsbook: 'BetMGM', americanOdds: -135, lastUpdated: now),
      ],
      fighter2Odds: [
        BookOdds(sportsbook: 'DraftKings', americanOdds: 110, lastUpdated: now),
        BookOdds(sportsbook: 'FanDuel', americanOdds: 105, lastUpdated: now),
        BookOdds(sportsbook: 'BetMGM', americanOdds: 115, lastUpdated: now),
      ],
    ),
    FightOddsCard(
      fighter1: 'Robert Whittaker',
      fighter2: 'Dricus Du Plessis',
      weightClass: 'Middleweight',
      fighter1Odds: [
        BookOdds(sportsbook: 'TAB', americanOdds: 120, lastUpdated: now),
        BookOdds(sportsbook: 'Sportsbet', americanOdds: 115, lastUpdated: now),
        BookOdds(sportsbook: 'Ladbrokes', americanOdds: 125, lastUpdated: now),
      ],
      fighter2Odds: [
        BookOdds(sportsbook: 'TAB', americanOdds: -140, lastUpdated: now),
        BookOdds(sportsbook: 'Sportsbet', americanOdds: -135, lastUpdated: now),
        BookOdds(sportsbook: 'Ladbrokes', americanOdds: -150, lastUpdated: now),
      ],
    ),
    FightOddsCard(
      fighter1: 'Tai Tuivasa',
      fighter2: 'Ciryl Gane',
      weightClass: 'Heavyweight',
      fighter1Odds: [
        BookOdds(sportsbook: 'DraftKings', americanOdds: 280, lastUpdated: now),
        BookOdds(sportsbook: 'TAB', americanOdds: 275, lastUpdated: now),
      ],
      fighter2Odds: [
        BookOdds(
          sportsbook: 'DraftKings',
          americanOdds: -350,
          lastUpdated: now,
        ),
        BookOdds(sportsbook: 'TAB', americanOdds: -340, lastUpdated: now),
      ],
    ),
  ];
}

const _demoOddsMovements = <OddsMovement>[
  OddsMovement(
    fighter: 'Islam Makhachev',
    opponent: 'Charles Oliveira',
    event: 'UFC 323',
    openingOdds: -200,
    currentOdds: -250,
    direction: 'steaming',
  ),
  OddsMovement(
    fighter: 'Ilia Topuria',
    opponent: 'Alexander Volkanovski',
    event: 'UFC 323',
    openingOdds: -140,
    currentOdds: -170,
    direction: 'steaming',
  ),
  OddsMovement(
    fighter: 'Robert Whittaker',
    opponent: 'Dricus Du Plessis',
    event: 'UFC Sydney',
    openingOdds: -110,
    currentOdds: 120,
    direction: 'drifting',
  ),
  OddsMovement(
    fighter: 'Tai Tuivasa',
    opponent: 'Ciryl Gane',
    event: 'UFC Sydney',
    openingOdds: 220,
    currentOdds: 280,
    direction: 'drifting',
  ),
  OddsMovement(
    fighter: 'Sean O\'Malley',
    opponent: 'Merab Dvalishvili',
    event: 'UFC 324',
    openingOdds: -150,
    currentOdds: -130,
    direction: 'drifting',
  ),
];

const _demoUpcomingEvents = <EventOddsSummary>[
  EventOddsSummary(
    eventName: 'UFC 323',
    organization: 'UFC',
    date: 'Mar 15',
    fightCount: 14,
    booksAvailable: 12,
    mainEvent: 'Makhachev vs Oliveira 2',
    hasLiveOdds: true,
  ),
  EventOddsSummary(
    eventName: 'UFC Fight Night: Sydney',
    organization: 'UFC',
    date: 'Mar 22',
    fightCount: 12,
    booksAvailable: 10,
    mainEvent: 'Whittaker vs Du Plessis',
  ),
  EventOddsSummary(
    eventName: 'Bellator 310',
    organization: 'Bellator',
    date: 'Mar 22',
    fightCount: 11,
    booksAvailable: 8,
    mainEvent: 'Amosov vs Storley',
  ),
  EventOddsSummary(
    eventName: 'ONE Friday Fights 145',
    organization: 'ONE',
    date: 'Mar 28',
    fightCount: 10,
    booksAvailable: 6,
    mainEvent: 'Superlek vs Panpayak',
  ),
  EventOddsSummary(
    eventName: 'RIZIN 53',
    organization: 'RIZIN',
    date: 'Mar 29',
    fightCount: 12,
    booksAvailable: 5,
    mainEvent: 'Asakura vs Saito',
  ),
  EventOddsSummary(
    eventName: 'BKFC Australia 1',
    organization: 'BKFC',
    date: 'Apr 5',
    fightCount: 10,
    booksAvailable: 7,
    mainEvent: 'TBA — Main Event',
  ),
  EventOddsSummary(
    eventName: 'Glory 102',
    organization: 'Glory',
    date: 'Apr 12',
    fightCount: 8,
    booksAvailable: 6,
    mainEvent: 'Pereira vs Grigorian',
  ),
  EventOddsSummary(
    eventName: 'PFL World Championship',
    organization: 'PFL',
    date: 'Apr 19',
    fightCount: 6,
    booksAvailable: 9,
    mainEvent: 'Season Finals',
  ),
  EventOddsSummary(
    eventName: 'Hex Fight Series 28',
    organization: 'Hex',
    date: 'Apr 26',
    fightCount: 10,
    booksAvailable: 4,
    mainEvent: 'Australian MMA Showcase',
  ),
  EventOddsSummary(
    eventName: 'IBC IV',
    organization: 'IBC',
    date: 'May 3',
    fightCount: 8,
    booksAvailable: 3,
    mainEvent: 'Gold Coast Brawl',
  ),
];
