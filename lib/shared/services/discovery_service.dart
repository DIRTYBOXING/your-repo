import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/app_logger.dart';

class DiscoveryResult {
  final String id;
  final String type; // 'fighter' | 'gym' | 'promoter' | 'user' | 'event'
  final String name;
  final String? subtitle;
  final String? photoUrl;
  final String? description;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String? role;
  final bool? isVerified;
  final int? unreadCount;
  final Map<String, dynamic>? meta; // Extra data (stats, availability, etc.)

  const DiscoveryResult({
    required this.id,
    required this.type,
    required this.name,
    this.subtitle,
    this.photoUrl,
    this.description,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.role,
    this.isVerified,
    this.unreadCount,
    this.meta,
  });

  // Backward-compatible aliases used by existing UI code.
  double? get distance => distanceKm;
  Map<String, dynamic> get metadata => meta ?? const <String, dynamic>{};
}

/// ═══════════════════════════════════════════════════════════════════════════
/// DISCOVERY SERVICE - Multi-Role User & Resource Matching System
/// ═══════════════════════════════════════════════════════════════════════════
/// Enables fighters, gyms, promoters, fans, coaches to find each other
/// by location, role, and availability
/// ═══════════════════════════════════════════════════════════════════════════
class DiscoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Geopoints for demo (SF Bay Area) - in production, use user's location
  static const double _defaultLat = 37.7749;
  static const double _defaultLng = -122.4194;

  // ═══════════════════════════════════════════════════════════════════════════
  // DEMO / FALLBACK DATA
  // ═══════════════════════════════════════════════════════════════════════════

  static List<DiscoveryResult> _getDemoFighters() => const [
    // ── AUSTRALIA ──
    DiscoveryResult(
      id: 'demo_fighter_1',
      type: 'fighter',
      name: 'Jai Opetaia',
      subtitle: 'IBF Cruiserweight Champion',
      description: 'Cruiserweight • Boxing',
      latitude: -33.8688,
      longitude: 151.2093,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 26,
        'losses': 0,
        'availability': 'unavailable',
        'stance': 'orthodox',
        'city': 'Sydney',
        'country': 'Australia',
        'flag': '🇦🇺',
      },
    ),
    DiscoveryResult(
      id: 'demo_fighter_2',
      type: 'fighter',
      name: 'Justis Huni',
      subtitle: 'Australian Heavyweight Hope',
      description: 'Heavyweight • Boxing',
      latitude: -27.4698,
      longitude: 153.0251,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 9,
        'losses': 1,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Brisbane',
        'country': 'Australia',
        'flag': '🇦🇺',
      },
    ),
    DiscoveryResult(
      id: 'demo_fighter_3',
      type: 'fighter',
      name: 'Jake "The Snake" Morrison',
      subtitle: 'Southpaw Striker',
      description: 'Welterweight • MMA',
      latitude: -37.8136,
      longitude: 144.9631,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 12,
        'losses': 2,
        'availability': 'available',
        'stance': 'southpaw',
        'city': 'Melbourne',
        'country': 'Australia',
        'flag': '🇦🇺',
      },
    ),
    DiscoveryResult(
      id: 'demo_fighter_4',
      type: 'fighter',
      name: 'Nawid Yosufi',
      subtitle: 'Afghan Hammer',
      description: 'Lightweight • MMA',
      latitude: -42.8821,
      longitude: 147.3272,
      role: 'fighter',
      isVerified: false,
      meta: {
        'wins': 7,
        'losses': 2,
        'availability': 'looking_for_bout',
        'city': 'Hobart',
        'country': 'Australia',
        'flag': '🇦🇺',
      },
    ),
    // ── USA ──
    DiscoveryResult(
      id: 'demo_fighter_5',
      type: 'fighter',
      name: 'Christine Ferea',
      subtitle: 'The Cyborg Queen',
      description: 'Featherweight • BKFC',
      latitude: 36.1699,
      longitude: -115.1398,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 9,
        'losses': 1,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Las Vegas',
        'country': 'USA',
        'flag': '🇺🇸',
      },
    ),
    DiscoveryResult(
      id: 'demo_fighter_6',
      type: 'fighter',
      name: 'Marcus "Iron Chin" Torres',
      subtitle: 'Pressure Fighter',
      description: 'Super Welterweight • Boxing',
      latitude: 34.0522,
      longitude: -118.2437,
      role: 'fighter',
      isVerified: false,
      meta: {
        'wins': 10,
        'losses': 3,
        'availability': 'looking_for_bout',
        'city': 'Los Angeles',
        'country': 'USA',
        'flag': '🇺🇸',
      },
    ),
    DiscoveryResult(
      id: 'demo_fighter_7',
      type: 'fighter',
      name: 'Bunty "Brick Fists" Boxer',
      subtitle: 'Bare Knuckle Brawler',
      description: 'Heavyweight • Bare Knuckle',
      latitude: 25.7617,
      longitude: -80.1918,
      role: 'fighter',
      isVerified: false,
      meta: {
        'wins': 5,
        'losses': 1,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Miami',
        'country': 'USA',
        'flag': '🇺🇸',
      },
    ),
    // ── BRAZIL ──
    DiscoveryResult(
      id: 'demo_fighter_8',
      type: 'fighter',
      name: 'Alex "Poatan" Pereira',
      subtitle: 'The Brazilian Knockout Artist',
      description: 'Light Heavyweight • MMA',
      latitude: -22.9068,
      longitude: -43.1729,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 18,
        'losses': 3,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Rio de Janeiro',
        'country': 'Brazil',
        'flag': '🇧🇷',
      },
    ),
    DiscoveryResult(
      id: 'demo_fighter_9',
      type: 'fighter',
      name: 'Alex "The Submission Machine" Silva',
      subtitle: 'Ground Specialist',
      description: 'Lightweight • BJJ / MMA',
      latitude: -23.5505,
      longitude: -46.6333,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 15,
        'losses': 4,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'S\u00e3o Paulo',
        'country': 'Brazil',
        'flag': '🇧🇷',
      },
    ),
    // ── THAILAND ──
    DiscoveryResult(
      id: 'demo_fighter_10',
      type: 'fighter',
      name: 'Stamp Fairtex',
      subtitle: 'Atomweight Queen',
      description: 'Atomweight • Muay Thai',
      latitude: 13.7563,
      longitude: 100.5018,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 65,
        'losses': 15,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Bangkok',
        'country': 'Thailand',
        'flag': '🇹🇭',
      },
    ),
    // ── UK ──
    DiscoveryResult(
      id: 'demo_fighter_11',
      type: 'fighter',
      name: 'Tommy "TNT" Fury',
      subtitle: 'Light Heavyweight Showman',
      description: 'Light Heavyweight • Boxing',
      latitude: 53.4808,
      longitude: -2.2426,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 10,
        'losses': 1,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Manchester',
        'country': 'UK',
        'flag': '🇬🇧',
      },
    ),
    // ── NEW ZEALAND ──
    DiscoveryResult(
      id: 'demo_fighter_12',
      type: 'fighter',
      name: 'Israel Adesanya',
      subtitle: 'The Last Stylebender',
      description: 'Middleweight • MMA',
      latitude: -36.8485,
      longitude: 174.7633,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 24,
        'losses': 3,
        'availability': 'unavailable',
        'stance': 'orthodox',
        'city': 'Auckland',
        'country': 'New Zealand',
        'flag': '🇳🇿',
      },
    ),
    // ── JAPAN ──
    DiscoveryResult(
      id: 'demo_fighter_13',
      type: 'fighter',
      name: 'Takeru Segawa',
      subtitle: 'The Natural Born Crusher',
      description: 'Featherweight • Kickboxing',
      latitude: 35.6762,
      longitude: 139.6503,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 44,
        'losses': 2,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Tokyo',
        'country': 'Japan',
        'flag': '🇯🇵',
      },
    ),
    // ── PHILIPPINES ──
    DiscoveryResult(
      id: 'demo_fighter_14',
      type: 'fighter',
      name: 'Mark "Magnifico" Magsayo',
      subtitle: 'Filipino Thunder',
      description: 'Featherweight • Boxing',
      latitude: 10.3157,
      longitude: 123.8854,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 25,
        'losses': 2,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Cebu',
        'country': 'Philippines',
        'flag': '🇵🇭',
      },
    ),
    // ── NIGERIA ──
    DiscoveryResult(
      id: 'demo_fighter_15',
      type: 'fighter',
      name: 'Kamaru Usman',
      subtitle: 'The Nigerian Nightmare',
      description: 'Welterweight • MMA',
      latitude: 9.0579,
      longitude: 7.4951,
      role: 'fighter',
      isVerified: true,
      meta: {
        'wins': 20,
        'losses': 4,
        'availability': 'available',
        'stance': 'orthodox',
        'city': 'Abuja',
        'country': 'Nigeria',
        'flag': '🇳🇬',
      },
    ),
  ];

  static List<DiscoveryResult> _getDemoGyms() => const [
    // ── AUSTRALIA ──
    DiscoveryResult(
      id: 'demo_gym_1',
      type: 'gym',
      name: 'Absolute MMA Melbourne',
      subtitle: 'Melbourne, Australia',
      description: '123 Swanston St, Melbourne VIC 3000',
      latitude: -37.8136,
      longitude: 144.9631,
      isVerified: true,
      meta: {
        'memberCount': 320,
        'sports': ['MMA', 'BJJ', 'Wrestling', 'Boxing'],
        'pricePerMonth': 180,
        'city': 'Melbourne',
        'country': 'Australia',
        'flag': '🇦🇺',
      },
    ),
    DiscoveryResult(
      id: 'demo_gym_2',
      type: 'gym',
      name: 'Eternal Training Centre',
      subtitle: 'Gold Coast, Australia',
      description: '12 Marine Pde, Southport QLD 4215',
      latitude: -27.9659,
      longitude: 153.3983,
      isVerified: true,
      meta: {
        'memberCount': 240,
        'sports': ['MMA', 'Boxing', 'Wrestling', 'Kickboxing'],
        'pricePerMonth': 160,
        'city': 'Gold Coast',
        'country': 'Australia',
        'flag': '🇦🇺',
      },
    ),
    DiscoveryResult(
      id: 'demo_gym_3',
      type: 'gym',
      name: 'Brace MMA Training HQ',
      subtitle: 'Adelaide, Australia',
      description: '77 Rundle St, Adelaide SA 5000',
      latitude: -34.9285,
      longitude: 138.6007,
      isVerified: true,
      meta: {
        'memberCount': 190,
        'sports': ['MMA', 'BJJ', 'Wrestling', 'Brawling'],
        'pricePerMonth': 140,
        'city': 'Adelaide',
        'country': 'Australia',
        'flag': '🇦🇺',
      },
    ),
    // ── USA ──
    DiscoveryResult(
      id: 'demo_gym_4',
      type: 'gym',
      name: 'American Top Team',
      subtitle: 'Miami, USA',
      description: '5750 NW 20th Terrace, Coconut Creek FL',
      latitude: 26.2746,
      longitude: -80.2544,
      isVerified: true,
      meta: {
        'memberCount': 600,
        'sports': ['MMA', 'BJJ', 'Wrestling', 'Boxing'],
        'pricePerMonth': 250,
        'city': 'Miami',
        'country': 'USA',
        'flag': '🇺🇸',
      },
    ),
    DiscoveryResult(
      id: 'demo_gym_5',
      type: 'gym',
      name: 'Wild Card Boxing Club',
      subtitle: 'Los Angeles, USA',
      description: '1123 Vine St, Hollywood CA 90038',
      latitude: 34.0928,
      longitude: -118.3264,
      isVerified: true,
      meta: {
        'memberCount': 400,
        'sports': ['Boxing'],
        'pricePerMonth': 200,
        'city': 'Los Angeles',
        'country': 'USA',
        'flag': '🇺🇸',
      },
    ),
    // ── THAILAND ──
    DiscoveryResult(
      id: 'demo_gym_6',
      type: 'gym',
      name: 'Tiger Muay Thai',
      subtitle: 'Phuket, Thailand',
      description: '7/6 Moo 5, Soi Ta-iad, Chalong, Phuket',
      latitude: 7.8464,
      longitude: 98.3361,
      isVerified: true,
      meta: {
        'memberCount': 500,
        'sports': ['Muay Thai', 'MMA', 'BJJ', 'Boxing'],
        'pricePerMonth': 120,
        'city': 'Phuket',
        'country': 'Thailand',
        'flag': '🇹🇭',
      },
    ),
    // ── UK ──
    DiscoveryResult(
      id: 'demo_gym_7',
      type: 'gym',
      name: 'London Shootfighters',
      subtitle: 'London, UK',
      description: '313 Latimer Rd, London W10 6RA',
      latitude: 51.5142,
      longitude: -0.2171,
      isVerified: true,
      meta: {
        'memberCount': 350,
        'sports': ['MMA', 'BJJ', 'Muay Thai', 'Wrestling'],
        'pricePerMonth': 180,
        'city': 'London',
        'country': 'UK',
        'flag': '🇬🇧',
      },
    ),
    // ── NEW ZEALAND ──
    DiscoveryResult(
      id: 'demo_gym_8',
      type: 'gym',
      name: 'City Kickboxing',
      subtitle: 'Auckland, New Zealand',
      description: '5 Cross St, Auckland CBD 1010',
      latitude: -36.8485,
      longitude: 174.7633,
      isVerified: true,
      meta: {
        'memberCount': 280,
        'sports': ['MMA', 'Kickboxing', 'Wrestling', 'BJJ'],
        'pricePerMonth': 150,
        'city': 'Auckland',
        'country': 'New Zealand',
        'flag': '🇳🇿',
      },
    ),
    // ── BRAZIL ──
    DiscoveryResult(
      id: 'demo_gym_9',
      type: 'gym',
      name: 'Nova Uni\u00e3o',
      subtitle: 'Rio de Janeiro, Brazil',
      description: 'R. Visc. de Piraj\u00e1, Ipanema, Rio',
      latitude: -22.9838,
      longitude: -43.2096,
      isVerified: true,
      meta: {
        'memberCount': 450,
        'sports': ['BJJ', 'MMA', 'Boxing'],
        'pricePerMonth': 100,
        'city': 'Rio de Janeiro',
        'country': 'Brazil',
        'flag': '🇧🇷',
      },
    ),
  ];

  static List<DiscoveryResult> _getDemoEvents() {
    final now = DateTime.now();
    return [
      // ── AUSTRALIA ──
      DiscoveryResult(
        id: 'demo_event_1',
        type: 'event',
        name: 'IBC IV: Gold Coast Showdown',
        subtitle: 'in 5 days',
        description: 'Gold Coast, Australia',
        latitude: -27.9659,
        longitude: 153.3983,
        isVerified: true,
        meta: {
          'promoterId': 'ibc_promotions',
          'fightCount': 10,
          'eventDate': now.add(const Duration(days: 5)).toIso8601String(),
          'city': 'Gold Coast',
          'country': 'Australia',
          'flag': '🇦🇺',
        },
      ),
      DiscoveryResult(
        id: 'demo_event_2',
        type: 'event',
        name: 'BKFC: Townsville Throwdown',
        subtitle: 'in 12 days',
        description: 'Townsville, Australia',
        latitude: -19.2590,
        longitude: 146.8169,
        isVerified: true,
        meta: {
          'promoterId': 'bkfc_australia',
          'fightCount': 8,
          'eventDate': now.add(const Duration(days: 12)).toIso8601String(),
          'city': 'Townsville',
          'country': 'Australia',
          'flag': '🇦🇺',
        },
      ),
      DiscoveryResult(
        id: 'demo_event_3',
        type: 'event',
        name: 'Eternal MMA 81: Melbourne',
        subtitle: 'in 18 days',
        description: 'Melbourne, Australia',
        latitude: -37.8136,
        longitude: 144.9631,
        isVerified: true,
        meta: {
          'promoterId': 'eternal_mma',
          'fightCount': 12,
          'eventDate': now.add(const Duration(days: 18)).toIso8601String(),
          'city': 'Melbourne',
          'country': 'Australia',
          'flag': '🇦🇺',
        },
      ),
      // ── USA ──
      DiscoveryResult(
        id: 'demo_event_5',
        type: 'event',
        name: 'UFC 310: Las Vegas',
        subtitle: 'in 25 days',
        description: 'Las Vegas, USA',
        latitude: 36.1699,
        longitude: -115.1398,
        isVerified: true,
        meta: {
          'promoterId': 'ufc',
          'fightCount': 14,
          'eventDate': now.add(const Duration(days: 25)).toIso8601String(),
          'city': 'Las Vegas',
          'country': 'USA',
          'flag': '🇺🇸',
        },
      ),
      DiscoveryResult(
        id: 'demo_event_6',
        type: 'event',
        name: 'BKFC 68: Knucklemania IV',
        subtitle: 'in 30 days',
        description: 'Philadelphia, USA',
        latitude: 39.9526,
        longitude: -75.1652,
        isVerified: true,
        meta: {
          'promoterId': 'bkfc',
          'fightCount': 11,
          'eventDate': now.add(const Duration(days: 30)).toIso8601String(),
          'city': 'Philadelphia',
          'country': 'USA',
          'flag': '🇺🇸',
        },
      ),
      // ── UK ──
      DiscoveryResult(
        id: 'demo_event_7',
        type: 'event',
        name: 'Cage Warriors 180: London',
        subtitle: 'in 20 days',
        description: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
        isVerified: true,
        meta: {
          'promoterId': 'cage_warriors',
          'fightCount': 12,
          'eventDate': now.add(const Duration(days: 20)).toIso8601String(),
          'city': 'London',
          'country': 'UK',
          'flag': '🇬🇧',
        },
      ),
      // ── THAILAND ──
      DiscoveryResult(
        id: 'demo_event_8',
        type: 'event',
        name: 'ONE Championship: Bangkok',
        subtitle: 'in 15 days',
        description: 'Bangkok, Thailand',
        latitude: 13.7563,
        longitude: 100.5018,
        isVerified: true,
        meta: {
          'promoterId': 'one_championship',
          'fightCount': 10,
          'eventDate': now.add(const Duration(days: 15)).toIso8601String(),
          'city': 'Bangkok',
          'country': 'Thailand',
          'flag': '🇹🇭',
        },
      ),
      // ── JAPAN ──
      DiscoveryResult(
        id: 'demo_event_9',
        type: 'event',
        name: 'RIZIN 50: Tokyo Dome',
        subtitle: 'in 40 days',
        description: 'Tokyo, Japan',
        latitude: 35.6762,
        longitude: 139.6503,
        isVerified: true,
        meta: {
          'promoterId': 'rizin',
          'fightCount': 15,
          'eventDate': now.add(const Duration(days: 40)).toIso8601String(),
          'city': 'Tokyo',
          'country': 'Japan',
          'flag': '🇯🇵',
        },
      ),
      // ── SOUTH AFRICA ──
      DiscoveryResult(
        id: 'demo_event_10',
        type: 'event',
        name: 'EFC Africa 120: Johannesburg',
        subtitle: 'in 22 days',
        description: 'Johannesburg, South Africa',
        latitude: -26.2041,
        longitude: 28.0473,
        isVerified: true,
        meta: {
          'promoterId': 'efc_africa',
          'fightCount': 10,
          'eventDate': now.add(const Duration(days: 22)).toIso8601String(),
          'city': 'Johannesburg',
          'country': 'South Africa',
          'flag': '🇿🇦',
        },
      ),
    ];
  }

  /// Public accessor for demo feed — used by UI as safety-net fallback.
  static Map<String, List<DiscoveryResult>> getDemoFeed() => {
    'fighters': _getDemoFighters(),
    'gyms': _getDemoGyms(),
    'events': _getDemoEvents(),
  };

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * (math.pi / 180);

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHTER DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find nearby fighters for sparring/collaboration/recruitment
  Future<List<DiscoveryResult>> getNearbyFighters({
    double? latitude,
    double? longitude,
    int radiusKm = 50,
    String? sport, // 'mma', 'boxing', 'bjj', 'muay_thai', etc.
    String? weightClass,
    int? maxAge,
    int? minAge,
  }) async {
    try {
      final lat = latitude ?? _defaultLat;
      final lng = longitude ?? _defaultLng;
      final currentUser = _auth.currentUser;

      // Query all fighters with coordinates
      final query = _firestore
          .collection('fighters')
          .where('status', isEqualTo: 'active');

      final snapshot = await query.get();
      final results = <DiscoveryResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fighterLat = data['latitude'] as double?;
        final fighterLng = data['longitude'] as double?;

        // Skip if no location
        if (fighterLat == null || fighterLng == null) continue;

        // Skip if it's the current user
        if (doc.id == currentUser?.uid) continue;

        // Calculate distance
        final distance = _calculateDistance(lat, lng, fighterLat, fighterLng);
        if (distance > radiusKm) continue;

        // Apply filters
        if (sport != null && data['sportType'] != sport) continue;
        if (weightClass != null && data['weightClass'] != weightClass) continue;

        final dob = (data['dateOfBirth'] as Timestamp?)?.toDate();
        if (dob != null) {
          final age = DateTime.now().year - dob.year;
          if (minAge != null && age < minAge) continue;
          if (maxAge != null && age > maxAge) continue;
        }

        // Build result
        results.add(
          DiscoveryResult(
            id: doc.id,
            type: 'fighter',
            name: data['fullName'] ?? 'Unnamed Fighter',
            subtitle: data['nickname'],
            photoUrl: data['photoUrl'],
            description:
                '${data['weightClass'] ?? 'Unknown'} • ${data['sportType'] ?? 'Combat Sports'}',
            latitude: fighterLat,
            longitude: fighterLng,
            distanceKm: distance,
            role: 'fighter',
            isVerified: data['isVerified'] ?? false,
            meta: {
              'wins': data['wins'] ?? 0,
              'losses': data['losses'] ?? 0,
              'availability': data['matchupAvailability'] ?? 'unavailable',
              'stance': data['stance'],
              'gym': data['currentGymId'],
            },
          ),
        );
      }

      // Sort by distance
      results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
      if (results.isEmpty) return _getDemoFighters();
      return results;
    } catch (e) {
      AppLogger.error(
        'Error finding nearby fighters – falling back to demo data',
        error: e,
        tag: 'DiscoveryService',
      );
      return _getDemoFighters();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GYM DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find nearby gyms/training facilities
  Future<List<DiscoveryResult>> getNearbyGyms({
    double? latitude,
    double? longitude,
    int radiusKm = 50,
    String? sport,
  }) async {
    try {
      final lat = latitude ?? _defaultLat;
      final lng = longitude ?? _defaultLng;
      final snapshot = await _firestore.collection('gyms').get();
      final results = <DiscoveryResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final gymLat = data['latitude'] as double?;
        final gymLng = data['longitude'] as double?;

        if (gymLat == null || gymLng == null) continue;

        final distance = _calculateDistance(lat, lng, gymLat, gymLng);
        if (distance > radiusKm) continue;

        if (sport != null) {
          final sports = (data['sports'] as List?)?.cast<String>() ?? [];
          if (!sports.contains(sport)) continue;
        }

        results.add(
          DiscoveryResult(
            id: doc.id,
            type: 'gym',
            name: data['name'] ?? 'Unnamed Gym',
            subtitle: data['city'],
            photoUrl: data['photoUrl'],
            description: data['address'],
            latitude: gymLat,
            longitude: gymLng,
            distanceKm: distance,
            isVerified: data['isVerified'] ?? false,
            meta: {
              'memberCount': data['memberCount'] ?? 0,
              'sports': data['sports'] ?? [],
              'pricePerMonth': data['pricePerMonth'],
            },
          ),
        );
      }

      results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
      if (results.isEmpty) return _getDemoGyms();
      return results;
    } catch (e) {
      AppLogger.error(
        'Error finding nearby gyms – falling back to demo data',
        error: e,
        tag: 'DiscoveryService',
      );
      return _getDemoGyms();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMOTER/EVENT DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find upcoming events nearby
  Future<List<DiscoveryResult>> getNearbyEvents({
    double? latitude,
    double? longitude,
    int radiusKm = 100,
  }) async {
    try {
      final lat = latitude ?? _defaultLat;
      final lng = longitude ?? _defaultLng;

      final snapshot = await _firestore
          .collection('events')
          .where('eventDate', isGreaterThan: Timestamp.now())
          .orderBy('eventDate')
          .limit(50)
          .get();

      final results = <DiscoveryResult>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final eventLat = data['latitude'] as double?;
        final eventLng = data['longitude'] as double?;

        if (eventLat == null || eventLng == null) continue;

        final distance = _calculateDistance(lat, lng, eventLat, eventLng);
        if (distance > radiusKm) continue;

        final eventDate = (data['eventDate'] as Timestamp?)?.toDate();
        final daysAway = eventDate?.difference(DateTime.now()).inDays;

        results.add(
          DiscoveryResult(
            id: doc.id,
            type: 'event',
            name: data['name'] ?? 'Unnamed Event',
            subtitle: eventDate != null ? 'in $daysAway days' : null,
            photoUrl: data['posterUrl'],
            description: '${data['city']}, ${data['state']}',
            latitude: eventLat,
            longitude: eventLng,
            distanceKm: distance,
            meta: {
              'promoterId': data['promoterId'],
              'fightCount': data['fightCount'] ?? 0,
              'eventDate': eventDate?.toIso8601String(),
            },
          ),
        );
      }

      results.sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
      if (results.isEmpty) return _getDemoEvents();
      return results;
    } catch (e) {
      AppLogger.error(
        'Error finding nearby events – falling back to demo data',
        error: e,
        tag: 'DiscoveryService',
      );
      return _getDemoEvents();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MULTI-ROLE DISCOVERY (Combined)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get mixed results: everything nearby (fighters, gyms, events)
  Future<Map<String, List<DiscoveryResult>>> getDiscoveryFeed({
    double? latitude,
    double? longitude,
    int radiusKm = 50,
  }) async {
    try {
      final results = await Future.wait([
        getNearbyFighters(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        ),
        getNearbyGyms(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        ),
        getNearbyEvents(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        ),
      ]);

      return {'fighters': results[0], 'gyms': results[1], 'events': results[2]};
    } catch (e) {
      AppLogger.error(
        'Error building discovery feed – falling back to demo data',
        error: e,
        tag: 'DiscoveryService',
      );
      return {
        'fighters': _getDemoFighters(),
        'gyms': _getDemoGyms(),
        'events': _getDemoEvents(),
      };
    }
  }

  /// Search across all types by name/location
  Future<List<DiscoveryResult>> searchAll(
    String query, {
    double? latitude,
    double? longitude,
    int radiusKm = 50,
  }) async {
    try {
      if (query.isEmpty) {
        return getDiscoveryFeed(
          latitude: latitude,
          longitude: longitude,
          radiusKm: radiusKm,
        ).then(
          (feed) => [
            ...?feed['fighters'],
            ...?feed['gyms'],
            ...?feed['events'],
          ],
        );
      }

      final results = <DiscoveryResult>[];

      // Firestore prefix queries are case-sensitive, so try both
      // original casing and capitalized first letter.
      final queryLower = query.toLowerCase();
      final queryCapitalized = query.isEmpty
          ? query
          : '${query[0].toUpperCase()}${query.substring(1).toLowerCase()}';
      final prefixes = {query, queryLower, queryCapitalized};
      final seenIds = <String>{};

      for (final prefix in prefixes) {
        // Search fighters by name
        final fightersSnap = await _firestore
            .collection('fighters')
            .where('fullName', isGreaterThanOrEqualTo: prefix)
            .where('fullName', isLessThan: '${prefix}z')
            .get();
        for (final doc in fightersSnap.docs) {
          if (seenIds.add(doc.id)) results.add(_fighterDocToResult(doc));
        }

        // Search gyms by name
        final gymsSnap = await _firestore
            .collection('gyms')
            .where('name', isGreaterThanOrEqualTo: prefix)
            .where('name', isLessThan: '${prefix}z')
            .get();
        for (final doc in gymsSnap.docs) {
          if (seenIds.add(doc.id)) results.add(_gymDocToResult(doc));
        }

        // Search events by name
        final eventsSnap = await _firestore
            .collection('events')
            .where('name', isGreaterThanOrEqualTo: prefix)
            .where('name', isLessThan: '${prefix}z')
            .get();
        for (final doc in eventsSnap.docs) {
          if (seenIds.add(doc.id)) results.add(_eventDocToResult(doc));
        }
      }

      // Fall back to filtered demo data when Firestore returns nothing
      if (results.isEmpty) {
        final q = queryLower;
        return [
          ..._getDemoFighters().where(
            (r) =>
                r.name.toLowerCase().contains(q) ||
                (r.description?.toLowerCase().contains(q) ?? false),
          ),
          ..._getDemoGyms().where(
            (r) =>
                r.name.toLowerCase().contains(q) ||
                (r.description?.toLowerCase().contains(q) ?? false),
          ),
          ..._getDemoEvents().where(
            (r) =>
                r.name.toLowerCase().contains(q) ||
                (r.description?.toLowerCase().contains(q) ?? false),
          ),
        ];
      }

      return results;
    } catch (e) {
      AppLogger.error(
        'Error searching discovery – falling back to demo data',
        error: e,
        tag: 'DiscoveryService',
      );
      // Return demo data filtered by query
      final q = query.toLowerCase();
      return [
        ..._getDemoFighters().where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              (r.description?.toLowerCase().contains(q) ?? false),
        ),
        ..._getDemoGyms().where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              (r.description?.toLowerCase().contains(q) ?? false),
        ),
        ..._getDemoEvents().where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              (r.description?.toLowerCase().contains(q) ?? false),
        ),
      ];
    }
  }

  DiscoveryResult _fighterDocToResult(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DiscoveryResult(
      id: doc.id,
      type: 'fighter',
      name: data['fullName'] ?? 'Unnamed',
      photoUrl: data['photoUrl'],
      description: data['weightClass'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      isVerified: data['isVerified'],
      meta: {'wins': data['wins'] ?? 0, 'losses': data['losses'] ?? 0},
    );
  }

  DiscoveryResult _gymDocToResult(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DiscoveryResult(
      id: doc.id,
      type: 'gym',
      name: data['name'] ?? 'Unnamed',
      photoUrl: data['photoUrl'],
      description: data['address'],
      latitude: data['latitude'],
      longitude: data['longitude'],
    );
  }

  DiscoveryResult _eventDocToResult(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DiscoveryResult(
      id: doc.id,
      type: 'event',
      name: data['name'] ?? 'Unnamed',
      photoUrl: data['posterUrl'],
      latitude: data['latitude'],
      longitude: data['longitude'],
    );
  }
}
