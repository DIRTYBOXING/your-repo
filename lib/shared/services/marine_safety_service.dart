/// ═══════════════════════════════════════════════════════════════════════
/// DFC Marine Safety & Conservation Service
///
/// Track whale boat conflicts, shark attack warnings from tagged sharks,
/// daily marine life kill statistics from commercial nets, and conservation
/// organization data. Fighting for ocean life — because all fights matter.
/// ═══════════════════════════════════════════════════════════════════════
library;

class MarineSafetyService {
  // ── Shark Attack Warnings ─────────────────────────────────────────

  /// Get active shark warnings based on tagged shark movements.
  Future<List<SharkWarning>> getSharkWarnings({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    // Query Firestore `shark_warnings` collection
    // Filter by geohash/proximity to lat/lng
    // Integrate with OCEARCH Global Shark Tracker API
    return [];
  }

  /// Get shark warnings for specific beach/location.
  List<SharkWarning> getActiveSharkWarnings({String? location}) {
    // Demo data - in production, fetch from OCEARCH API + Firestore
    return [
      SharkWarning(
        id: 'sw_001',
        sharkName: 'Mary Lee',
        species: 'Great White Shark',
        tagId: 'GW-001',
        lastPing: DateTime.now().subtract(const Duration(hours: 2)),
        latitude: -33.8688,
        longitude: 151.2093, // Sydney area
        distanceFromShoreKm: 3.2,
        warningLevel: SharkWarningLevel.high,
        beachesAffected: ['Bondi Beach', 'Coogee Beach', 'Manly Beach'],
        description:
            '4.5m Great White detected 3.2km offshore. Shark historically active in this area.',
      ),
      SharkWarning(
        id: 'sw_002',
        sharkName: 'Tiger 7',
        species: 'Tiger Shark',
        tagId: 'TS-007',
        lastPing: DateTime.now().subtract(const Duration(hours: 6)),
        latitude: -27.9396,
        longitude: 153.3957, // Gold Coast
        distanceFromShoreKm: 1.8,
        warningLevel: SharkWarningLevel.extreme,
        beachesAffected: ['Surfers Paradise', 'Burleigh Heads', 'Coolangatta'],
        description:
            '3.8m Tiger Shark detected 1.8km from shore. High activity zone. Beaches advised to close.',
      ),
    ];
  }

  // ── Whale Boat Conflicts ──────────────────────────────────────────

  /// Get active whale watching boats and potential conflict zones.
  Future<List<WhaleBoatConflict>> getWhaleBoatConflicts({
    required double latitude,
    required double longitude,
    double radiusKm = 100.0,
  }) async {
    // Query Firestore `whale_boat_conflicts`
    // Integrate with marine traffic APIs
    // Cross-reference with whale migration data
    return [];
  }

  /// Get whale boat conflict data for map display.
  List<WhaleBoatConflict> getActiveWhaleConflicts() {
    return [
      WhaleBoatConflict(
        id: 'wbc_001',
        conflictType: 'Illegal Proximity',
        boatId: 'VESSEL-8821',
        boatName: 'Unknown Commercial',
        whaleSpecies: 'Humpback Whale',
        latitude: -34.0522,
        longitude: 151.1852,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        distanceToWhaleMeters: 85,
        legalMinimumMeters: 100,
        severity: ConflictSeverity.medium,
        description:
            'Commercial vessel within 85m of Humpback pod. Legal minimum is 100m.',
        reportedBy: 'Sea Shepherd Observer',
      ),
      WhaleBoatConflict(
        id: 'wbc_002',
        conflictType: 'High Speed in Whale Zone',
        boatId: 'VESSEL-5512',
        boatName: 'Commercial Fishing Vessel',
        whaleSpecies: 'Southern Right Whale',
        latitude: -38.3159,
        longitude: 142.4995,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        distanceToWhaleMeters: 250,
        legalMinimumMeters: 100,
        severity: ConflictSeverity.high,
        description:
            'Vessel traveling 28 knots in protected whale breeding area. Speed limit 6 knots.',
        reportedBy: 'DFC Marine Scanner',
      ),
    ];
  }

  // ── Marine Life Kill Statistics ───────────────────────────────────

  /// Get daily statistics of marine life killed in commercial nets.
  Future<MarineKillStats> getTodayKillStats() async {
    // Query aggregated Firestore data
    // Integrate with conservation org APIs (Sea Shepherd, Oceana, etc.)
    return MarineKillStats(
      date: DateTime.now(),
      dolphinsByNet: 347,
      turtlesByNet: 521,
      sharksByNet: 1205,
      whalesByNet: 12,
      sealsByNet: 89,
      otherMarineLifeByNet: 4521,
      totalDeaths: 6695,
      previousDayTotal: 6412,
      trend: MarineKillTrend.increasing,
    );
  }

  /// Get marine kill statistics for date range.
  Future<List<MarineKillStats>> getKillStatsRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Query Firestore for historical data
    return [];
  }

  // ── Conservation Organizations ────────────────────────────────────

  /// Get list of marine conservation organizations.
  List<ConservationOrg> getConservationOrgs() {
    return const [
      ConservationOrg(
        name: 'Sea Shepherd Conservation Society',
        description:
            'Direct-action marine conservation. Protecting whales, dolphins, sharks, and sea life worldwide.',
        website: 'https://seashepherd.org',
        donateUrl: 'https://seashepherd.org/donate',
        volunteerUrl: 'https://seashepherd.org/volunteer',
        phone: '+61 3 9645 9422',
        email: 'info@seashepherd.org.au',
        regions: ['Global'],
        focus: ['Whaling', 'Shark Finning', 'Illegal Fishing', 'Ocean Cleanup'],
      ),
      ConservationOrg(
        name: 'Oceana',
        description:
            'Largest international ocean advocacy organization. Protecting and restoring the world\'s oceans.',
        website: 'https://oceana.org',
        donateUrl: 'https://oceana.org/donate',
        volunteerUrl: 'https://oceana.org/get-involved',
        phone: '+1 202-833-3900',
        email: 'info@oceana.org',
        regions: ['Global'],
        focus: ['Overfishing', 'Habitat Protection', 'Pollution', 'Climate'],
      ),
      ConservationOrg(
        name: 'Australian Marine Conservation Society',
        description:
            'Australia\'s voice for the ocean. Fighting for healthy seas and marine life.',
        website: 'https://www.marineconservation.org.au',
        donateUrl: 'https://www.marineconservation.org.au/donate',
        volunteerUrl: 'https://www.marineconservation.org.au/get-involved',
        phone: '+61 7 3846 6777',
        email: 'amcs@amcs.org.au',
        regions: ['Australia'],
        focus: [
          'Great Barrier Reef',
          'Shark Protection',
          'Sustainable Fishing',
        ],
      ),
      ConservationOrg(
        name: 'Surfrider Foundation',
        description:
            'Protecting the world\'s oceans, waves, and beaches for all people.',
        website: 'https://www.surfrider.org',
        donateUrl: 'https://www.surfrider.org/donate',
        volunteerUrl: 'https://www.surfrider.org/chapters',
        phone: '+1 949-492-8170',
        email: 'info@surfrider.org',
        regions: ['Global'],
        focus: ['Beach Access', 'Ocean Pollution', 'Coastal Preservation'],
      ),
      ConservationOrg(
        name: 'Whale and Dolphin Conservation',
        description:
            'Dedicated solely to the protection of whales and dolphins worldwide.',
        website: 'https://whales.org',
        donateUrl: 'https://whales.org/donate',
        volunteerUrl: 'https://whales.org/get-involved',
        phone: '+44 1249 449500',
        email: 'info@whales.org',
        regions: ['Global'],
        focus: ['Whale Protection', 'Captivity Issues', 'Sonar Threats'],
      ),
      ConservationOrg(
        name: 'Project AWARE',
        description:
            'Global movement for ocean protection. Focused on sharks, rays, and marine debris.',
        website: 'https://www.projectaware.org',
        donateUrl: 'https://www.projectaware.org/donate',
        volunteerUrl: 'https://www.projectaware.org/takeaction',
        phone: '+1 949-858-7657',
        email: 'info@projectaware.org',
        regions: ['Global'],
        focus: ['Shark Conservation', 'Marine Debris', 'Dive Against Debris'],
      ),
    ];
  }

  // ── Report Incidents ──────────────────────────────────────────────

  /// Report a whale/boat conflict incident.
  Future<void> reportWhaleBoatIncident({
    required String userId,
    required double latitude,
    required double longitude,
    required String conflictType,
    required String description,
    String? boatId,
    String? whaleSpecies,
    List<String>? photoUrls,
  }) async {
    // Write to Firestore `whale_boat_incidents`
    // Notify conservation orgs (Sea Shepherd, etc.)
    // Alert marine authorities
  }

  /// Report marine life death/injury.
  Future<void> reportMarineLifeIncident({
    required String userId,
    required double latitude,
    required double longitude,
    required String species,
    required String
    causeOfDeath, // 'net', 'boat_strike', 'pollution', 'unknown'
    required String description,
    List<String>? photoUrls,
  }) async {
    // Write to Firestore `marine_life_incidents`
    // Contribute to kill stats aggregation
  }
}

// ── Supporting Models ────────────────────────────────────────────────

enum SharkWarningLevel {
  low,
  medium,
  high,
  extreme;

  String get displayName {
    switch (this) {
      case SharkWarningLevel.low:
        return 'LOW RISK';
      case SharkWarningLevel.medium:
        return 'MEDIUM RISK';
      case SharkWarningLevel.high:
        return 'HIGH RISK';
      case SharkWarningLevel.extreme:
        return 'EXTREME RISK';
    }
  }

  String get emoji {
    switch (this) {
      case SharkWarningLevel.low:
        return '🟢';
      case SharkWarningLevel.medium:
        return '🟡';
      case SharkWarningLevel.high:
        return '🟠';
      case SharkWarningLevel.extreme:
        return '🔴';
    }
  }
}

class SharkWarning {
  final String id;
  final String sharkName;
  final String species;
  final String tagId;
  final DateTime lastPing;
  final double latitude;
  final double longitude;
  final double distanceFromShoreKm;
  final SharkWarningLevel warningLevel;
  final List<String> beachesAffected;
  final String description;

  const SharkWarning({
    required this.id,
    required this.sharkName,
    required this.species,
    required this.tagId,
    required this.lastPing,
    required this.latitude,
    required this.longitude,
    required this.distanceFromShoreKm,
    required this.warningLevel,
    required this.beachesAffected,
    required this.description,
  });

  String get timeSinceLastPing {
    final duration = DateTime.now().difference(lastPing);
    if (duration.inHours < 1) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }

  String get beachesList => beachesAffected.join(', ');
}

enum ConflictSeverity { low, medium, high, critical }

class WhaleBoatConflict {
  final String id;
  final String conflictType;
  final String boatId;
  final String boatName;
  final String whaleSpecies;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double distanceToWhaleMeters;
  final double legalMinimumMeters;
  final ConflictSeverity severity;
  final String description;
  final String reportedBy;

  const WhaleBoatConflict({
    required this.id,
    required this.conflictType,
    required this.boatId,
    required this.boatName,
    required this.whaleSpecies,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.distanceToWhaleMeters,
    required this.legalMinimumMeters,
    required this.severity,
    required this.description,
    required this.reportedBy,
  });

  bool get isViolation => distanceToWhaleMeters < legalMinimumMeters;

  String get timeAgo {
    final duration = DateTime.now().difference(timestamp);
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}

enum MarineKillTrend { decreasing, stable, increasing }

class MarineKillStats {
  final DateTime date;
  final int dolphinsByNet;
  final int turtlesByNet;
  final int sharksByNet;
  final int whalesByNet;
  final int sealsByNet;
  final int otherMarineLifeByNet;
  final int totalDeaths;
  final int previousDayTotal;
  final MarineKillTrend trend;

  const MarineKillStats({
    required this.date,
    required this.dolphinsByNet,
    required this.turtlesByNet,
    required this.sharksByNet,
    required this.whalesByNet,
    required this.sealsByNet,
    required this.otherMarineLifeByNet,
    required this.totalDeaths,
    required this.previousDayTotal,
    required this.trend,
  });

  int get changeFromYesterday => totalDeaths - previousDayTotal;

  double get percentChange =>
      ((totalDeaths - previousDayTotal) / previousDayTotal) * 100;

  String get trendDisplay {
    switch (trend) {
      case MarineKillTrend.decreasing:
        return '📉 Decreasing';
      case MarineKillTrend.stable:
        return '➡️ Stable';
      case MarineKillTrend.increasing:
        return '📈 Increasing';
    }
  }
}

class ConservationOrg {
  final String name;
  final String description;
  final String website;
  final String donateUrl;
  final String volunteerUrl;
  final String phone;
  final String email;
  final List<String> regions;
  final List<String> focus;

  const ConservationOrg({
    required this.name,
    required this.description,
    required this.website,
    required this.donateUrl,
    required this.volunteerUrl,
    required this.phone,
    required this.email,
    required this.regions,
    required this.focus,
  });

  String get focusAreas => focus.join(', ');
  String get regionsCovered => regions.join(', ');
}
