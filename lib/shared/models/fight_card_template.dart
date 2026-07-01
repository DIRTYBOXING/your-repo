import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CARD TEMPLATE MODEL
/// ═══════════════════════════════════════════════════════════════════════════
///
/// A reusable fight card template for coaches/promoters to build event cards
/// with structured bouts (Main Event, Semi-Main, Co-Main, Prelim, etc.).
/// Supports print, download (HTML), and send-to-member flows.
///
/// ═══════════════════════════════════════════════════════════════════════════

enum BoutPosition {
  mainEvent,
  semiMain,
  coMain,
  prelim,
  undercard,
  superfight,
  exhibition,
}

extension BoutPositionX on BoutPosition {
  String get label {
    switch (this) {
      case BoutPosition.mainEvent:
        return 'MAIN EVENT';
      case BoutPosition.semiMain:
        return 'SEMI-MAIN';
      case BoutPosition.coMain:
        return 'CO-MAIN';
      case BoutPosition.prelim:
        return 'PRELIM';
      case BoutPosition.undercard:
        return 'UNDERCARD';
      case BoutPosition.superfight:
        return 'SUPER FIGHT';
      case BoutPosition.exhibition:
        return 'EXHIBITION';
    }
  }

  int get sortOrder {
    switch (this) {
      case BoutPosition.mainEvent:
        return 0;
      case BoutPosition.semiMain:
        return 1;
      case BoutPosition.coMain:
        return 2;
      case BoutPosition.superfight:
        return 3;
      case BoutPosition.prelim:
        return 4;
      case BoutPosition.undercard:
        return 5;
      case BoutPosition.exhibition:
        return 6;
    }
  }
}

/// A single bout on the fight card
class FightCardBout extends Equatable {
  final String id;
  final BoutPosition position;
  final String redCornerName;
  final String blueCornerName;
  final String redCornerGym;
  final String blueCornerGym;
  final String redCornerRecord;
  final String blueCornerRecord;
  final String weightClass;
  final int rounds;
  final int roundMinutes;
  final String? titleFight; // e.g. "DFC Lightweight Title"
  final String sportType;
  final String rules; // Full Contact / Amateur / Pro / K-1 / etc.
  final int boutOrder; // manual ordering within position

  const FightCardBout({
    required this.id,
    this.position = BoutPosition.prelim,
    this.redCornerName = '',
    this.blueCornerName = '',
    this.redCornerGym = '',
    this.blueCornerGym = '',
    this.redCornerRecord = '',
    this.blueCornerRecord = '',
    this.weightClass = '',
    this.rounds = 3,
    this.roundMinutes = 3,
    this.titleFight,
    this.sportType = 'MMA',
    this.rules = 'Full Contact',
    this.boutOrder = 0,
  });

  FightCardBout copyWith({
    String? id,
    BoutPosition? position,
    String? redCornerName,
    String? blueCornerName,
    String? redCornerGym,
    String? blueCornerGym,
    String? redCornerRecord,
    String? blueCornerRecord,
    String? weightClass,
    int? rounds,
    int? roundMinutes,
    String? titleFight,
    String? sportType,
    String? rules,
    int? boutOrder,
  }) {
    return FightCardBout(
      id: id ?? this.id,
      position: position ?? this.position,
      redCornerName: redCornerName ?? this.redCornerName,
      blueCornerName: blueCornerName ?? this.blueCornerName,
      redCornerGym: redCornerGym ?? this.redCornerGym,
      blueCornerGym: blueCornerGym ?? this.blueCornerGym,
      redCornerRecord: redCornerRecord ?? this.redCornerRecord,
      blueCornerRecord: blueCornerRecord ?? this.blueCornerRecord,
      weightClass: weightClass ?? this.weightClass,
      rounds: rounds ?? this.rounds,
      roundMinutes: roundMinutes ?? this.roundMinutes,
      titleFight: titleFight ?? this.titleFight,
      sportType: sportType ?? this.sportType,
      rules: rules ?? this.rules,
      boutOrder: boutOrder ?? this.boutOrder,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'position': position.name,
    'redCornerName': redCornerName,
    'blueCornerName': blueCornerName,
    'redCornerGym': redCornerGym,
    'blueCornerGym': blueCornerGym,
    'redCornerRecord': redCornerRecord,
    'blueCornerRecord': blueCornerRecord,
    'weightClass': weightClass,
    'rounds': rounds,
    'roundMinutes': roundMinutes,
    'titleFight': titleFight,
    'sportType': sportType,
    'rules': rules,
    'boutOrder': boutOrder,
  };

  factory FightCardBout.fromMap(Map<String, dynamic> m) {
    return FightCardBout(
      id: (m['id'] ?? '').toString(),
      position: BoutPosition.values.firstWhere(
        (e) => e.name == m['position'],
        orElse: () => BoutPosition.prelim,
      ),
      redCornerName: (m['redCornerName'] ?? '').toString(),
      blueCornerName: (m['blueCornerName'] ?? '').toString(),
      redCornerGym: (m['redCornerGym'] ?? '').toString(),
      blueCornerGym: (m['blueCornerGym'] ?? '').toString(),
      redCornerRecord: (m['redCornerRecord'] ?? '').toString(),
      blueCornerRecord: (m['blueCornerRecord'] ?? '').toString(),
      weightClass: (m['weightClass'] ?? '').toString(),
      rounds: (m['rounds'] as num?)?.toInt() ?? 3,
      roundMinutes: (m['roundMinutes'] as num?)?.toInt() ?? 3,
      titleFight: m['titleFight']?.toString(),
      sportType: (m['sportType'] ?? 'MMA').toString(),
      rules: (m['rules'] ?? 'Full Contact').toString(),
      boutOrder: (m['boutOrder'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, position, redCornerName, blueCornerName];
}

/// The full fight card template
class FightCardTemplate extends Equatable {
  final String id;
  final String creatorId;
  final String creatorName;
  final String eventName;
  final String promotionName;
  final String venue;
  final String city;
  final String country;
  final DateTime eventDate;
  final String sportType;
  final String sanctioningBody; // e.g. "WKBF", "ISKA", "WBC Muaythai"
  final List<FightCardBout> bouts;
  final String? logoUrl;
  final String? notes;
  final bool isDraft;
  final List<String> sharedWith; // user IDs it's been sent to
  final DateTime createdAt;
  final DateTime updatedAt;

  const FightCardTemplate({
    required this.id,
    required this.creatorId,
    this.creatorName = '',
    this.eventName = '',
    this.promotionName = '',
    this.venue = '',
    this.city = '',
    this.country = 'Australia',
    required this.eventDate,
    this.sportType = 'MMA',
    this.sanctioningBody = '',
    this.bouts = const [],
    this.logoUrl,
    this.notes,
    this.isDraft = true,
    this.sharedWith = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Bouts sorted by position then boutOrder
  List<FightCardBout> get sortedBouts {
    final sorted = List<FightCardBout>.from(bouts);
    sorted.sort((a, b) {
      final posCmp = a.position.sortOrder.compareTo(b.position.sortOrder);
      if (posCmp != 0) return posCmp;
      return a.boutOrder.compareTo(b.boutOrder);
    });
    return sorted;
  }

  int get totalBouts => bouts.length;

  FightCardTemplate copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? eventName,
    String? promotionName,
    String? venue,
    String? city,
    String? country,
    DateTime? eventDate,
    String? sportType,
    String? sanctioningBody,
    List<FightCardBout>? bouts,
    String? logoUrl,
    String? notes,
    bool? isDraft,
    List<String>? sharedWith,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FightCardTemplate(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      eventName: eventName ?? this.eventName,
      promotionName: promotionName ?? this.promotionName,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      country: country ?? this.country,
      eventDate: eventDate ?? this.eventDate,
      sportType: sportType ?? this.sportType,
      sanctioningBody: sanctioningBody ?? this.sanctioningBody,
      bouts: bouts ?? this.bouts,
      logoUrl: logoUrl ?? this.logoUrl,
      notes: notes ?? this.notes,
      isDraft: isDraft ?? this.isDraft,
      sharedWith: sharedWith ?? this.sharedWith,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'creatorId': creatorId,
    'creatorName': creatorName,
    'eventName': eventName,
    'promotionName': promotionName,
    'venue': venue,
    'city': city,
    'country': country,
    'eventDate': Timestamp.fromDate(eventDate),
    'sportType': sportType,
    'sanctioningBody': sanctioningBody,
    'bouts': bouts.map((b) => b.toMap()).toList(),
    'logoUrl': logoUrl,
    'notes': notes,
    'isDraft': isDraft,
    'sharedWith': sharedWith,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };

  factory FightCardTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    DateTime ts(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return FightCardTemplate(
      id: doc.id,
      creatorId: (data['creatorId'] ?? '').toString(),
      creatorName: (data['creatorName'] ?? '').toString(),
      eventName: (data['eventName'] ?? '').toString(),
      promotionName: (data['promotionName'] ?? '').toString(),
      venue: (data['venue'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      country: (data['country'] ?? 'Australia').toString(),
      eventDate: ts(data['eventDate']),
      sportType: (data['sportType'] ?? 'MMA').toString(),
      sanctioningBody: (data['sanctioningBody'] ?? '').toString(),
      bouts:
          (data['bouts'] as List<dynamic>?)
              ?.map((b) => FightCardBout.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      logoUrl: data['logoUrl']?.toString(),
      notes: data['notes']?.toString(),
      isDraft: data['isDraft'] as bool? ?? true,
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      createdAt: ts(data['createdAt']),
      updatedAt: ts(data['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [id, creatorId, eventName, eventDate];
}
