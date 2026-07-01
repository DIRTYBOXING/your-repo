import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER TRAVEL PACKAGE SERVICE
///
/// DFC-organized travel packages that transform the fight experience:
///
///  OLD WAY: Fly in → bad hotel near venue → fight → fly out same night
///  DFC WAY: Fly in early → quality hotel → explore the city → fight →
///           enjoy win/lose/draw → fly home when ready
///
/// Funded by a small % of the fighter purse + sponsor/promoter contributions.
/// The fighter sacrifices a little of the purse but gets a proper experience.
/// ═══════════════════════════════════════════════════════════════════════════

enum PackageTier {
  bronze, // Basic: flights + venue hotel + 1 extra night
  silver, // Standard: flights + quality hotel + 2 extra nights + city guide
  gold, // Premium: flights + premium hotel + 3 nights + food/tours + concierge
  platinum, // VIP: all-inclusive + 5 nights + partner travel + private transfers
}

enum PackageStatus {
  available,
  requested,
  confirmed,
  active,
  completed,
  cancelled,
}

class TravelPackage {
  final String id;
  final String eventName;
  final String eventCity;
  final String eventCountry;
  final String venueName;
  final DateTime eventDate;
  final PackageTier tier;
  final PackageStatus status;

  // Flights
  final String departureCity;
  final String departureCountry;
  final DateTime flyInDate;
  final DateTime flyOutDate;
  final int extraNights;

  // Accommodation
  final String hotelName;
  final String hotelArea;
  final int hotelStars;
  final String hotelNote; // "City centre, 20min from venue"

  // Experiences included
  final List<String> includedExperiences;

  // Financials
  final double totalCost;
  final double sponsorContribution;
  final double promoterContribution;
  final double fighterContribution; // from purse
  final double pursePercentage; // e.g. 5% of purse

  // Sponsor / promoter
  final String sponsorName;
  final String promoterName;

  const TravelPackage({
    required this.id,
    required this.eventName,
    required this.eventCity,
    required this.eventCountry,
    required this.venueName,
    required this.eventDate,
    required this.tier,
    required this.status,
    required this.departureCity,
    required this.departureCountry,
    required this.flyInDate,
    required this.flyOutDate,
    required this.extraNights,
    required this.hotelName,
    required this.hotelArea,
    required this.hotelStars,
    required this.hotelNote,
    required this.includedExperiences,
    required this.totalCost,
    required this.sponsorContribution,
    required this.promoterContribution,
    required this.fighterContribution,
    required this.pursePercentage,
    required this.sponsorName,
    required this.promoterName,
  });
}

class DestinationHighlight {
  final String city;
  final String country;
  final String flagEmoji;
  final String description;
  final List<String> topAttractions;
  final List<String> localFood;
  final String nightlife;
  final String bestArea;
  final String currency;
  final String language;
  final String timezone;

  const DestinationHighlight({
    required this.city,
    required this.country,
    required this.flagEmoji,
    required this.description,
    required this.topAttractions,
    required this.localFood,
    required this.nightlife,
    required this.bestArea,
    required this.currency,
    required this.language,
    required this.timezone,
  });
}

class FighterTravelPackageService extends ChangeNotifier {
  List<TravelPackage> _packages = [];
  List<DestinationHighlight> _destinations = [];

  List<TravelPackage> get packages => _packages;
  List<DestinationHighlight> get destinations => _destinations;

  FighterTravelPackageService() {
    _loadDemoPackages();
    _loadDestinations();
  }

  // ── TIER INFO ──────────────────────────────────────────────────────────

  static const Map<PackageTier, Map<String, dynamic>> tierDetails = {
    PackageTier.bronze: {
      'name': 'BRONZE',
      'tagline': 'Better Than a Curse',
      'pursePercent': 3.0,
      'extraNights': 1,
      'hotelStars': 3,
      'includes': [
        'Return flights',
        'Venue-area hotel (3★)',
        '+1 extra night after fight',
        'Airport transfers',
      ],
    },
    PackageTier.silver: {
      'name': 'SILVER',
      'tagline': 'See the City',
      'pursePercent': 5.0,
      'extraNights': 2,
      'hotelStars': 4,
      'includes': [
        'Return flights',
        'City-centre hotel (4★)',
        '+2 extra nights',
        'Airport transfers',
        'Local city guide PDF',
        'Restaurant recommendations',
      ],
    },
    PackageTier.gold: {
      'name': 'GOLD',
      'tagline': 'Fight & Explore',
      'pursePercent': 8.0,
      'extraNights': 3,
      'hotelStars': 4,
      'includes': [
        'Return flights (premium economy)',
        'Premium hotel (4★+)',
        '+3 extra nights',
        'Private airport transfers',
        'City walking tour',
        'Food tour (local cuisine)',
        'DFC concierge contact',
        'Local SIM card',
      ],
    },
    PackageTier.platinum: {
      'name': 'PLATINUM',
      'tagline': 'The Full Experience',
      'pursePercent': 12.0,
      'extraNights': 5,
      'hotelStars': 5,
      'includes': [
        'Return flights (business class)',
        'Luxury hotel (5★)',
        '+5 extra nights',
        'Private transfers everywhere',
        'Partner/companion travel included',
        'VIP city experiences',
        'Fine dining reservations',
        'Private tour guide',
        'Spa/recovery session',
        '24/7 DFC concierge',
        'Local SIM + data',
        'Emergency medical contact',
      ],
    },
  };

  // ── DEMO PACKAGES ──────────────────────────────────────────────────────

  void _loadDemoPackages() {
    _packages = [
      TravelPackage(
        id: 'PKG-001',
        eventName: 'GLORY 92 Amsterdam',
        eventCity: 'Amsterdam',
        eventCountry: 'Netherlands',
        venueName: 'AFAS Live',
        eventDate: DateTime(2026, 4, 12),
        tier: PackageTier.gold,
        status: PackageStatus.available,
        departureCity: 'Bangkok',
        departureCountry: 'Thailand',
        flyInDate: DateTime(2026, 4, 9),
        flyOutDate: DateTime(2026, 4, 15),
        extraNights: 3,
        hotelName: 'Hotel V Nesplein',
        hotelArea: 'City Centre, Dam Square',
        hotelStars: 4,
        hotelNote:
            'Heart of Amsterdam, 20min tram to AFAS Live. Walking distance to canals, museums, nightlife.',
        includedExperiences: [
          'Canal boat tour',
          'Jordaan food walk',
          'Rijksmuseum visit',
          'Dutch pancake breakfast',
          'Red Light District walking tour',
          'Heineken Experience',
        ],
        totalCost: 3200,
        sponsorContribution: 1200,
        promoterContribution: 800,
        fighterContribution: 1200,
        pursePercentage: 8.0,
        sponsorName: 'Venum',
        promoterName: 'GLORY Kickboxing',
      ),
      TravelPackage(
        id: 'PKG-002',
        eventName: 'UFC Fight Night Sydney',
        eventCity: 'Sydney',
        eventCountry: 'Australia',
        venueName: 'Qudos Bank Arena',
        eventDate: DateTime(2026, 5, 3),
        tier: PackageTier.silver,
        status: PackageStatus.available,
        departureCity: 'Manila',
        departureCountry: 'Philippines',
        flyInDate: DateTime(2026, 4, 30),
        flyOutDate: DateTime(2026, 5, 5),
        extraNights: 2,
        hotelName: 'Ovolo Woolloomooloo',
        hotelArea: 'Woolloomooloo, Harbour side',
        hotelStars: 4,
        hotelNote:
            'Harbour views, 10min from CBD. Near Kings Cross nightlife, Bondi bus routes.',
        includedExperiences: [
          'Sydney Harbour Bridge walk',
          'Bondi to Coogee coastal walk',
          'Darling Harbour dinner',
          'Local surf lesson',
        ],
        totalCost: 2100,
        sponsorContribution: 800,
        promoterContribution: 600,
        fighterContribution: 700,
        pursePercentage: 5.0,
        sponsorName: 'Engage MMA',
        promoterName: 'UFC',
      ),
      TravelPackage(
        id: 'PKG-003',
        eventName: 'Eternal MMA 80',
        eventCity: 'Melbourne',
        eventCountry: 'Australia',
        venueName: 'Melbourne Pavilion',
        eventDate: DateTime(2026, 6, 14),
        tier: PackageTier.platinum,
        status: PackageStatus.confirmed,
        departureCity: 'São Paulo',
        departureCountry: 'Brazil',
        flyInDate: DateTime(2026, 6, 9),
        flyOutDate: DateTime(2026, 6, 19),
        extraNights: 5,
        hotelName: 'Crown Towers Melbourne',
        hotelArea: 'Southbank, River precinct',
        hotelStars: 5,
        hotelNote:
            'Luxury river views, casino, fine dining. Walking distance to laneways, MCG, Rod Laver Arena.',
        includedExperiences: [
          'Great Ocean Road day trip',
          'Melbourne laneway food tour',
          'Yarra Valley wine region',
          'MCG stadium tour',
          'Graffiti laneway walking tour',
          'St Kilda beach & Luna Park',
          'Spa/recovery at Crown Spa',
          'Partner included (companion flight)',
          'Private airport limousine',
        ],
        totalCost: 8500,
        sponsorContribution: 3000,
        promoterContribution: 2000,
        fighterContribution: 3500,
        pursePercentage: 12.0,
        sponsorName: 'Hayabusa',
        promoterName: 'Eternal MMA',
      ),
      TravelPackage(
        id: 'PKG-004',
        eventName: 'ONE Championship 170',
        eventCity: 'Bangkok',
        eventCountry: 'Thailand',
        venueName: 'Impact Arena',
        eventDate: DateTime(2026, 3, 28),
        tier: PackageTier.bronze,
        status: PackageStatus.completed,
        departureCity: 'Perth',
        departureCountry: 'Australia',
        flyInDate: DateTime(2026, 3, 26),
        flyOutDate: DateTime(2026, 3, 30),
        extraNights: 1,
        hotelName: 'Ibis Styles Bangkok',
        hotelArea: 'Sukhumvit, Nana area',
        hotelStars: 3,
        hotelNote:
            'Central Sukhumvit, BTS Skytrain access. Street food heaven, Chatuchak market nearby.',
        includedExperiences: [
          'Airport transfers',
          'Extra night to recover & explore',
          'Local food guide PDF',
        ],
        totalCost: 900,
        sponsorContribution: 300,
        promoterContribution: 300,
        fighterContribution: 300,
        pursePercentage: 3.0,
        sponsorName: 'Fairtex',
        promoterName: 'ONE Championship',
      ),
      TravelPackage(
        id: 'PKG-005',
        eventName: 'BKFC 68 London',
        eventCity: 'London',
        eventCountry: 'United Kingdom',
        venueName: 'Indigo at The O2',
        eventDate: DateTime(2026, 7, 19),
        tier: PackageTier.gold,
        status: PackageStatus.available,
        departureCity: 'Las Vegas',
        departureCountry: 'United States',
        flyInDate: DateTime(2026, 7, 16),
        flyOutDate: DateTime(2026, 7, 22),
        extraNights: 3,
        hotelName: 'The Hoxton Shoreditch',
        hotelArea: 'Shoreditch, East London',
        hotelStars: 4,
        hotelNote:
            'Trendy East London. Brick Lane food, rooftop bars, street art. Tube to O2 in 25min.',
        includedExperiences: [
          'Thames river cruise',
          'Borough Market food tour',
          'Camden Town exploration',
          'Brick Lane curry experience',
          'London Eye',
          'Pub crawl with local guide',
        ],
        totalCost: 4200,
        sponsorContribution: 1500,
        promoterContribution: 1200,
        fighterContribution: 1500,
        pursePercentage: 8.0,
        sponsorName: 'Bad Boy MMA',
        promoterName: 'BKFC',
      ),
    ];
    notifyListeners();
  }

  // ── DESTINATION HIGHLIGHTS ─────────────────────────────────────────────

  void _loadDestinations() {
    _destinations = const [
      DestinationHighlight(
        city: 'Amsterdam',
        country: 'Netherlands',
        flagEmoji: '🇳🇱',
        description:
            'Canals, culture, and world-class kickboxing. The home of GLORY.',
        topAttractions: [
          'Canal Ring',
          'Rijksmuseum',
          'Vondelpark',
          'Anne Frank House',
          'Jordaan Quarter',
        ],
        localFood: [
          'Stroopwafels',
          'Bitterballen',
          'Herring',
          'Dutch pancakes',
          'Frites',
        ],
        nightlife:
            'Leidseplein & Rembrandtplein — bars, clubs, live music until late',
        bestArea:
            'De Pijp or Jordaan — walkable, local vibes, great restaurants',
        currency: 'EUR (€)',
        language: 'Dutch (English widely spoken)',
        timezone: 'CET (UTC+1)',
      ),
      DestinationHighlight(
        city: 'Sydney',
        country: 'Australia',
        flagEmoji: '🇦🇺',
        description:
            'Harbour city with beaches, culture, and a massive fight scene.',
        topAttractions: [
          'Sydney Opera House',
          'Harbour Bridge',
          'Bondi Beach',
          'The Rocks',
          'Taronga Zoo',
        ],
        localFood: [
          'Meat pies',
          'Barramundi',
          'Tim Tams',
          'Flat white coffee',
          'Pavlova',
        ],
        nightlife:
            'Kings Cross & Darlinghurst — cocktail bars, live music, late-night eats',
        bestArea:
            'Surry Hills or Newtown — café culture, diverse food, walking distance to CBD',
        currency: 'AUD (A\$)',
        language: 'English',
        timezone: 'AEST (UTC+10)',
      ),
      DestinationHighlight(
        city: 'Melbourne',
        country: 'Australia',
        flagEmoji: '🇦🇺',
        description:
            'Laneways, coffee, sport, and one of the best food cities on Earth.',
        topAttractions: [
          'Federation Square',
          'Great Ocean Road',
          'MCG',
          'Laneways',
          'Queen Victoria Market',
        ],
        localFood: [
          'Coffee (best in the world)',
          'Dim sum',
          'Souvlaki',
          'Meat pies',
          'Lamingtons',
        ],
        nightlife:
            'Fitzroy & Collingwood — rooftop bars, live music, warehouse parties',
        bestArea:
            'Southbank or Fitzroy — river views or inner-city hipster culture',
        currency: 'AUD (A\$)',
        language: 'English',
        timezone: 'AEST (UTC+10)',
      ),
      DestinationHighlight(
        city: 'Bangkok',
        country: 'Thailand',
        flagEmoji: '🇹🇭',
        description:
            'The birthplace of Muay Thai. Temples, street food, and incredible nightlife.',
        topAttractions: [
          'Grand Palace',
          'Wat Pho',
          'Chatuchak Market',
          'Khao San Road',
          'Lumpini Park',
        ],
        localFood: [
          'Pad Thai',
          'Som Tum',
          'Mango Sticky Rice',
          'Tom Yum',
          'Green Curry',
        ],
        nightlife:
            'Sukhumvit & Khao San — night markets, rooftop bars, clubs until sunrise',
        bestArea:
            'Sukhumvit (Nana/Asoke) — BTS access, food everywhere, easy transport',
        currency: 'THB (฿)',
        language: 'Thai (English in tourist areas)',
        timezone: 'ICT (UTC+7)',
      ),
      DestinationHighlight(
        city: 'London',
        country: 'United Kingdom',
        flagEmoji: '🇬🇧',
        description:
            'Historic city, world-class food scene, and growing combat sports culture.',
        topAttractions: [
          'Big Ben',
          'Tower of London',
          'Camden Market',
          'Brick Lane',
          'Hyde Park',
        ],
        localFood: [
          'Fish & Chips',
          'Sunday Roast',
          'Pie & Mash',
          'Full English',
          'Curry (Brick Lane)',
        ],
        nightlife:
            'Shoreditch & Soho — cocktail bars, clubs, comedy clubs, pub culture',
        bestArea:
            'Shoreditch or Kings Cross — central, trendy, great transport links',
        currency: 'GBP (£)',
        language: 'English',
        timezone: 'GMT (UTC+0)',
      ),
      DestinationHighlight(
        city: 'Las Vegas',
        country: 'United States',
        flagEmoji: '🇺🇸',
        description:
            'The fight capital of the world. Every major UFC PPV happens here.',
        topAttractions: [
          'The Strip',
          'Fremont Street',
          'Red Rock Canyon',
          'Grand Canyon day trip',
          'Shows',
        ],
        localFood: [
          'Buffets',
          'Steakhouses',
          'Tacos',
          'In-N-Out Burger',
          'Celebrity chef restaurants',
        ],
        nightlife:
            'The Strip — mega clubs, pool parties, 24/7 casinos, world-class shows',
        bestArea:
            'The Strip or Downtown Fremont — everything walkable, never boring',
        currency: 'USD (\$)',
        language: 'English',
        timezone: 'PST (UTC-8)',
      ),
      DestinationHighlight(
        city: 'Abu Dhabi',
        country: 'UAE',
        flagEmoji: '🇦🇪',
        description:
            'UFC Fight Island. Luxury, desert, and massive international events.',
        topAttractions: [
          'Yas Island',
          'Sheikh Zayed Mosque',
          'Ferrari World',
          'Louvre Abu Dhabi',
          'Desert Safari',
        ],
        localFood: [
          'Shawarma',
          'Hummus',
          'Machboos',
          'Luqaimat',
          'Arabic coffee',
        ],
        nightlife:
            'Yas Island & Corniche — beach clubs, rooftop lounges, hotel bars',
        bestArea:
            'Yas Island or Corniche — modern, sea views, close to Etihad Arena',
        currency: 'AED (د.إ)',
        language: 'Arabic (English widely spoken)',
        timezone: 'GST (UTC+4)',
      ),
      DestinationHighlight(
        city: 'Tokyo',
        country: 'Japan',
        flagEmoji: '🇯🇵',
        description:
            'RIZIN, martial arts heritage, and one of the most incredible cities to explore.',
        topAttractions: [
          'Shibuya Crossing',
          'Senso-ji Temple',
          'Akihabara',
          'Tsukiji Market',
          'Mt Fuji day trip',
        ],
        localFood: [
          'Ramen',
          'Sushi (real deal)',
          'Wagyu',
          'Takoyaki',
          'Matcha everything',
        ],
        nightlife:
            'Shinjuku & Roppongi — izakayas, karaoke, Golden Gai, clubs until 5am',
        bestArea:
            'Shinjuku or Shibuya — incredible transport, food everywhere, safe 24/7',
        currency: 'JPY (¥)',
        language: 'Japanese (English limited outside tourist areas)',
        timezone: 'JST (UTC+9)',
      ),
    ];
  }

  // ── PACKAGE OPERATIONS ─────────────────────────────────────────────────

  TravelPackage? getPackageById(String id) {
    try {
      return _packages.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TravelPackage> getPackagesByStatus(PackageStatus status) {
    return _packages.where((p) => p.status == status).toList();
  }

  List<TravelPackage> getPackagesForCity(String city) {
    return _packages
        .where((p) => p.eventCity.toLowerCase() == city.toLowerCase())
        .toList();
  }

  DestinationHighlight? getDestination(String city) {
    try {
      return _destinations.firstWhere(
        (d) => d.city.toLowerCase() == city.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Calculate what the fighter pays based on purse amount and tier
  static double calculateFighterCost(double purseAmount, PackageTier tier) {
    final percent = (tierDetails[tier]!['pursePercent'] as double) / 100.0;
    return purseAmount * percent;
  }

  /// Returns a description of the tier's value proposition
  static String tierValuePitch(PackageTier tier) {
    return switch (tier) {
      PackageTier.bronze =>
        'Just 3% of your purse. You get an extra night to recover, '
            'proper transfers, and you don\'t fly out the same night you fought. '
            'Better than a curse.',
      PackageTier.silver =>
        '5% of your purse buys you 2 extra nights in a quality hotel. '
            'See the city, eat the food, enjoy the win (or shake off the loss). '
            'You came all this way — actually see the place.',
      PackageTier.gold =>
        '8% of your purse gets you the full experience. Premium hotel, '
            'food tours, city exploration, concierge support. You\u2019re not just '
            'a fighter passing through — you\u2019re experiencing the destination.',
      PackageTier.platinum =>
        '12% of your purse for the VIP treatment. Business class flights, '
            '5-star hotel, partner travel included, private everything. '
            'Win, lose, or draw — you feel like a champion.',
    };
  }
}
