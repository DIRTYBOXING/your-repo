import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WORLD CULTURES & RELIGIONS — Global Awareness for Combat Sports
/// ═══════════════════════════════════════════════════════════════════════════
///
/// DFC is a worldwide platform. We respect and celebrate every culture,
/// religion, and tradition. This model powers:
///   - Religious/cultural calendar awareness (fasting periods, holy days)
///   - Event scheduling sensitivity (avoid clashing with major holy days)
///   - Fighter profile cultural tags
///   - Community celebration posts & greetings
///   - Dietary/training accommodation awareness

// ── World Religions ──────────────────────────────────────────────────────────

enum WorldReligion {
  christianity,
  islam,
  hinduism,
  buddhism,
  sikhism,
  judaism,
  shinto,
  taoism,
  jainism,
  bahai,
  zoroastrianism,
  indigenous, // Aboriginal, Māori, Native American, etc.
  spiritual, // Non-denominational / spiritual
  none, // Secular / no religion
  other,
}

extension WorldReligionExt on WorldReligion {
  String get displayName {
    switch (this) {
      case WorldReligion.christianity:
        return 'Christianity';
      case WorldReligion.islam:
        return 'Islam';
      case WorldReligion.hinduism:
        return 'Hinduism';
      case WorldReligion.buddhism:
        return 'Buddhism';
      case WorldReligion.sikhism:
        return 'Sikhism';
      case WorldReligion.judaism:
        return 'Judaism';
      case WorldReligion.shinto:
        return 'Shinto';
      case WorldReligion.taoism:
        return 'Taoism';
      case WorldReligion.jainism:
        return 'Jainism';
      case WorldReligion.bahai:
        return "Bahá'í";
      case WorldReligion.zoroastrianism:
        return 'Zoroastrianism';
      case WorldReligion.indigenous:
        return 'Indigenous Spirituality';
      case WorldReligion.spiritual:
        return 'Spiritual';
      case WorldReligion.none:
        return 'Secular';
      case WorldReligion.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case WorldReligion.christianity:
        return '✝️';
      case WorldReligion.islam:
        return '☪️';
      case WorldReligion.hinduism:
        return '🕉️';
      case WorldReligion.buddhism:
        return '☸️';
      case WorldReligion.sikhism:
        return '🪯';
      case WorldReligion.judaism:
        return '✡️';
      case WorldReligion.shinto:
        return '⛩️';
      case WorldReligion.taoism:
        return '☯️';
      case WorldReligion.jainism:
        return '🙏';
      case WorldReligion.bahai:
        return '✨';
      case WorldReligion.zoroastrianism:
        return '🔥';
      case WorldReligion.indigenous:
        return '🌿';
      case WorldReligion.spiritual:
        return '🧘';
      case WorldReligion.none:
        return '🌍';
      case WorldReligion.other:
        return '🕊️';
    }
  }
}

// ── World Regions ────────────────────────────────────────────────────────────

enum WorldRegion {
  northAmerica,
  centralAmerica,
  southAmerica,
  caribbean,
  westernEurope,
  easternEurope,
  northernEurope,
  southernEurope,
  middleEast,
  centralAsia,
  southAsia,
  southeastAsia,
  eastAsia,
  northAfrica,
  westAfrica,
  eastAfrica,
  southernAfrica,
  centralAfrica,
  oceania,
  pacific,
}

extension WorldRegionExt on WorldRegion {
  String get displayName {
    switch (this) {
      case WorldRegion.northAmerica:
        return 'North America';
      case WorldRegion.centralAmerica:
        return 'Central America';
      case WorldRegion.southAmerica:
        return 'South America';
      case WorldRegion.caribbean:
        return 'Caribbean';
      case WorldRegion.westernEurope:
        return 'Western Europe';
      case WorldRegion.easternEurope:
        return 'Eastern Europe';
      case WorldRegion.northernEurope:
        return 'Northern Europe';
      case WorldRegion.southernEurope:
        return 'Southern Europe';
      case WorldRegion.middleEast:
        return 'Middle East';
      case WorldRegion.centralAsia:
        return 'Central Asia';
      case WorldRegion.southAsia:
        return 'South Asia';
      case WorldRegion.southeastAsia:
        return 'Southeast Asia';
      case WorldRegion.eastAsia:
        return 'East Asia';
      case WorldRegion.northAfrica:
        return 'North Africa';
      case WorldRegion.westAfrica:
        return 'West Africa';
      case WorldRegion.eastAfrica:
        return 'East Africa';
      case WorldRegion.southernAfrica:
        return 'Southern Africa';
      case WorldRegion.centralAfrica:
        return 'Central Africa';
      case WorldRegion.oceania:
        return 'Oceania';
      case WorldRegion.pacific:
        return 'Pacific Islands';
    }
  }
}

// ── Cultural Event / Holy Day ────────────────────────────────────────────────

enum CulturalEventType {
  religiousHoliday,
  nationalDay,
  culturalFestival,
  commemorationDay,
  fastingPeriod,
  sportingTradition,
  seasonalCelebration,
}

class CulturalEvent extends Equatable {
  final String id;
  final String name;
  final String description;
  final CulturalEventType type;
  final List<WorldReligion> religions;
  final List<WorldRegion> regions;
  final List<String> countries; // ISO codes
  final int month; // 1-12 (approximate for lunar calendars)
  final int? day; // null for variable dates (lunar/solar calendar based)
  final bool isLunarCalendar; // Date shifts yearly
  final int? durationDays;
  final String? greeting; // "Eid Mubarak", "Merry Christmas", etc.
  final bool fasting; // Affects training schedules
  final bool eventSchedulingSensitive; // Avoid scheduling fights

  const CulturalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.religions = const [],
    this.regions = const [],
    this.countries = const [],
    required this.month,
    this.day,
    this.isLunarCalendar = false,
    this.durationDays,
    this.greeting,
    this.fasting = false,
    this.eventSchedulingSensitive = false,
  });

  factory CulturalEvent.fromMap(Map<String, dynamic> map, String docId) {
    return CulturalEvent(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: CulturalEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CulturalEventType.culturalFestival,
      ),
      religions:
          (map['religions'] as List<dynamic>?)
              ?.map(
                (r) => WorldReligion.values.firstWhere(
                  (e) => e.name == r,
                  orElse: () => WorldReligion.other,
                ),
              )
              .toList() ??
          [],
      regions:
          (map['regions'] as List<dynamic>?)
              ?.map(
                (r) => WorldRegion.values.firstWhere(
                  (e) => e.name == r,
                  orElse: () => WorldRegion.oceania,
                ),
              )
              .toList() ??
          [],
      countries: List<String>.from(map['countries'] ?? []),
      month: map['month'] ?? 1,
      day: map['day'],
      isLunarCalendar: map['isLunarCalendar'] ?? false,
      durationDays: map['durationDays'],
      greeting: map['greeting'],
      fasting: map['fasting'] ?? false,
      eventSchedulingSensitive: map['eventSchedulingSensitive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'religions': religions.map((r) => r.name).toList(),
      'regions': regions.map((r) => r.name).toList(),
      'countries': countries,
      'month': month,
      'day': day,
      'isLunarCalendar': isLunarCalendar,
      'durationDays': durationDays,
      'greeting': greeting,
      'fasting': fasting,
      'eventSchedulingSensitive': eventSchedulingSensitive,
    };
  }

  @override
  List<Object?> get props => [id, name, month, day];
}

// ── Martial Arts Tradition ───────────────────────────────────────────────────

class MartialArtsTradition extends Equatable {
  final String id;
  final String name;
  final String originCountry;
  final WorldRegion region;
  final String description;
  final List<String> relatedStyles;
  final String? culturalSignificance;
  final bool isOlympicSport;

  const MartialArtsTradition({
    required this.id,
    required this.name,
    required this.originCountry,
    required this.region,
    required this.description,
    this.relatedStyles = const [],
    this.culturalSignificance,
    this.isOlympicSport = false,
  });

  factory MartialArtsTradition.fromMap(Map<String, dynamic> map, String docId) {
    return MartialArtsTradition(
      id: docId,
      name: map['name'] ?? '',
      originCountry: map['originCountry'] ?? '',
      region: WorldRegion.values.firstWhere(
        (e) => e.name == map['region'],
        orElse: () => WorldRegion.eastAsia,
      ),
      description: map['description'] ?? '',
      relatedStyles: List<String>.from(map['relatedStyles'] ?? []),
      culturalSignificance: map['culturalSignificance'],
      isOlympicSport: map['isOlympicSport'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'originCountry': originCountry,
      'region': region.name,
      'description': description,
      'relatedStyles': relatedStyles,
      'culturalSignificance': culturalSignificance,
      'isOlympicSport': isOlympicSport,
    };
  }

  @override
  List<Object?> get props => [id, name, originCountry];
}

// ── User Cultural Preferences ────────────────────────────────────────────────

class UserCulturalPreferences extends Equatable {
  final String userId;
  final String? preferredLanguage;
  final WorldRegion? homeRegion;
  final String? country; // ISO code
  final WorldReligion? religion;
  final bool showCulturalGreetings;
  final bool respectFastingSchedule;
  final bool showLocalEvents;
  final List<String> celebratedHolidays; // CulturalEvent IDs
  final String? timezone;

  const UserCulturalPreferences({
    required this.userId,
    this.preferredLanguage,
    this.homeRegion,
    this.country,
    this.religion,
    this.showCulturalGreetings = true,
    this.respectFastingSchedule = false,
    this.showLocalEvents = true,
    this.celebratedHolidays = const [],
    this.timezone,
  });

  factory UserCulturalPreferences.fromMap(
    Map<String, dynamic> map,
    String uid,
  ) {
    return UserCulturalPreferences(
      userId: uid,
      preferredLanguage: map['preferredLanguage'],
      homeRegion: map['homeRegion'] != null
          ? WorldRegion.values.firstWhere(
              (e) => e.name == map['homeRegion'],
              orElse: () => WorldRegion.oceania,
            )
          : null,
      country: map['country'],
      religion: map['religion'] != null
          ? WorldReligion.values.firstWhere(
              (e) => e.name == map['religion'],
              orElse: () => WorldReligion.none,
            )
          : null,
      showCulturalGreetings: map['showCulturalGreetings'] ?? true,
      respectFastingSchedule: map['respectFastingSchedule'] ?? false,
      showLocalEvents: map['showLocalEvents'] ?? true,
      celebratedHolidays: List<String>.from(map['celebratedHolidays'] ?? []),
      timezone: map['timezone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredLanguage': preferredLanguage,
      'homeRegion': homeRegion?.name,
      'country': country,
      'religion': religion?.name,
      'showCulturalGreetings': showCulturalGreetings,
      'respectFastingSchedule': respectFastingSchedule,
      'showLocalEvents': showLocalEvents,
      'celebratedHolidays': celebratedHolidays,
      'timezone': timezone,
    };
  }

  UserCulturalPreferences copyWith({
    String? preferredLanguage,
    WorldRegion? homeRegion,
    String? country,
    WorldReligion? religion,
    bool? showCulturalGreetings,
    bool? respectFastingSchedule,
    bool? showLocalEvents,
    List<String>? celebratedHolidays,
    String? timezone,
  }) {
    return UserCulturalPreferences(
      userId: userId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      homeRegion: homeRegion ?? this.homeRegion,
      country: country ?? this.country,
      religion: religion ?? this.religion,
      showCulturalGreetings:
          showCulturalGreetings ?? this.showCulturalGreetings,
      respectFastingSchedule:
          respectFastingSchedule ?? this.respectFastingSchedule,
      showLocalEvents: showLocalEvents ?? this.showLocalEvents,
      celebratedHolidays: celebratedHolidays ?? this.celebratedHolidays,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  List<Object?> get props => [userId, preferredLanguage, religion, country];
}
