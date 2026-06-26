import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Status of an open bout slot on a promoter's fight card.
enum BoutSlotStatus { open, negotiating, filled, cancelled }

/// Position on the card.
enum BoutSlotType { mainEvent, coMain, prelim, amateur }

extension BoutSlotTypeX on BoutSlotType {
  String get label {
    switch (this) {
      case BoutSlotType.mainEvent:
        return 'MAIN EVENT';
      case BoutSlotType.coMain:
        return 'CO-MAIN';
      case BoutSlotType.prelim:
        return 'PRELIM';
      case BoutSlotType.amateur:
        return 'AMATEUR';
    }
  }
}

class BoutSlotModel extends Equatable {
  final String id;
  final String promoterId;
  final String promoterName;
  final String eventId;
  final String eventName;
  final DateTime eventDate;
  final String venue;
  final String city;
  final String country;
  final String weightClass;
  final String sportType;
  final BoutSlotStatus status;
  final BoutSlotType slotType;
  final double purse;
  final String? notes;
  final int applicationCount;
  final List<String> preferredStyles;
  final List<String> targetCountries;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BoutSlotModel({
    required this.id,
    required this.promoterId,
    required this.promoterName,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.venue,
    required this.city,
    required this.country,
    required this.weightClass,
    required this.sportType,
    this.status = BoutSlotStatus.open,
    this.slotType = BoutSlotType.prelim,
    required this.purse,
    this.notes,
    this.applicationCount = 0,
    this.preferredStyles = const [],
    this.targetCountries = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory BoutSlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoutSlotModel(
      id: doc.id,
      promoterId: data['promoterId'] ?? '',
      promoterName: data['promoterName'] ?? 'Unknown Promoter',
      eventId: data['eventId'] ?? '',
      eventName: data['eventName'] ?? 'Unnamed Event',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      venue: data['venue'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      weightClass: data['weightClass'] ?? '',
      sportType: data['sportType'] ?? 'MMA',
      status: BoutSlotStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => BoutSlotStatus.open,
      ),
      slotType: BoutSlotType.values.firstWhere(
        (s) => s.name == data['slotType'],
        orElse: () => BoutSlotType.prelim,
      ),
      purse: (data['purse'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'],
      applicationCount: data['applicationCount'] ?? 0,
      preferredStyles: List<String>.from(data['preferredStyles'] ?? []),
      targetCountries: List<String>.from(data['targetCountries'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'promoterId': promoterId,
    'promoterName': promoterName,
    'eventId': eventId,
    'eventName': eventName,
    'eventDate': Timestamp.fromDate(eventDate),
    'venue': venue,
    'city': city,
    'country': country,
    'weightClass': weightClass,
    'sportType': sportType,
    'status': status.name,
    'slotType': slotType.name,
    'purse': purse,
    'notes': notes,
    'applicationCount': applicationCount,
    'preferredStyles': preferredStyles,
    'targetCountries': targetCountries,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  };

  BoutSlotModel copyWith({
    String? id,
    String? promoterId,
    String? promoterName,
    String? eventId,
    String? eventName,
    DateTime? eventDate,
    String? venue,
    String? city,
    String? country,
    String? weightClass,
    String? sportType,
    BoutSlotStatus? status,
    BoutSlotType? slotType,
    double? purse,
    String? notes,
    int? applicationCount,
    List<String>? preferredStyles,
    List<String>? targetCountries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoutSlotModel(
      id: id ?? this.id,
      promoterId: promoterId ?? this.promoterId,
      promoterName: promoterName ?? this.promoterName,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      country: country ?? this.country,
      weightClass: weightClass ?? this.weightClass,
      sportType: sportType ?? this.sportType,
      status: status ?? this.status,
      slotType: slotType ?? this.slotType,
      purse: purse ?? this.purse,
      notes: notes ?? this.notes,
      applicationCount: applicationCount ?? this.applicationCount,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      targetCountries: targetCountries ?? this.targetCountries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    promoterId,
    eventId,
    status,
    weightClass,
    purse,
    applicationCount,
  ];
}
