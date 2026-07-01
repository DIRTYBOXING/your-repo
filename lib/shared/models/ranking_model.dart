import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Ranking model for fighter rankings by weight class and organization
class RankingModel extends Equatable {
  final String id;
  final String fighterId;
  final String weightClass;
  final String sportType;
  final String? organization; // e.g., UFC, Bellator, ONE, PFL
  final int position;
  final int previousPosition;
  final int? points;
  final bool isChampion;
  final bool isInterimChampion;
  final DateTime effectiveDate;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RankingModel({
    required this.id,
    required this.fighterId,
    required this.weightClass,
    required this.sportType,
    this.organization,
    required this.position,
    this.previousPosition = 0,
    this.points,
    this.isChampion = false,
    this.isInterimChampion = false,
    required this.effectiveDate,
    this.expiryDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Position change from previous ranking
  int get positionChange => previousPosition - position;

  /// Is ranking moving up
  bool get isMovingUp => positionChange > 0;

  /// Is ranking moving down
  bool get isMovingDown => positionChange < 0;

  /// Is ranking unchanged
  bool get isUnchanged => positionChange == 0;

  /// Is ranking active (not expired)
  bool get isActive {
    if (expiryDate == null) return true;
    return DateTime.now().isBefore(expiryDate!);
  }

  factory RankingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RankingModel(
      id: doc.id,
      fighterId: data['fighterId'] ?? '',
      weightClass: data['weightClass'] ?? '',
      sportType: data['sportType'] ?? '',
      organization: data['organization'],
      position: data['position'] ?? 0,
      previousPosition: data['previousPosition'] ?? 0,
      points: data['points'],
      isChampion: data['isChampion'] ?? false,
      isInterimChampion: data['isInterimChampion'] ?? false,
      effectiveDate:
          (data['effectiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fighterId': fighterId,
      'weightClass': weightClass,
      'sportType': sportType,
      'organization': organization,
      'position': position,
      'previousPosition': previousPosition,
      'points': points,
      'isChampion': isChampion,
      'isInterimChampion': isInterimChampion,
      'effectiveDate': Timestamp.fromDate(effectiveDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  RankingModel copyWith({
    String? id,
    String? fighterId,
    String? weightClass,
    String? sportType,
    String? organization,
    int? position,
    int? previousPosition,
    int? points,
    bool? isChampion,
    bool? isInterimChampion,
    DateTime? effectiveDate,
    DateTime? expiryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RankingModel(
      id: id ?? this.id,
      fighterId: fighterId ?? this.fighterId,
      weightClass: weightClass ?? this.weightClass,
      sportType: sportType ?? this.sportType,
      organization: organization ?? this.organization,
      position: position ?? this.position,
      previousPosition: previousPosition ?? this.previousPosition,
      points: points ?? this.points,
      isChampion: isChampion ?? this.isChampion,
      isInterimChampion: isInterimChampion ?? this.isInterimChampion,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fighterId,
    weightClass,
    sportType,
    organization,
    position,
  ];
}
