import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Fighter stance types
enum FighterStance { orthodox, southpaw, switch_ }

/// Fighter status
enum FighterStatus { active, inactive, retired, suspended }

/// Matchup availability status
enum MatchupAvailability { available, unavailable, negotiating, booked }

/// Fighter model for combat sports athletes
/// Gender enum for fighters
enum FighterGender { male, female, nonbinary, undisclosed }

class FighterModel extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String? nickname;
  final String? nationality;
  final FighterGender gender;
  final DateTime? dateOfBirth;
  final String? weightClass;
  final String? sportType;
  final FighterStance? stance;
  final FighterStatus status;
  final double? heightCm;
  final double? reachCm;
  final int wins;
  final int losses;
  final int draws;
  final int noContests;
  final int knockouts;
  final int submissions;
  final String? currentGymId;
  final String? currentCoachId;
  final List<String> previousGymIds;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final Map<String, dynamic>? socialLinks;

  // FightWire 2.0 fields
  final String? regionId;
  final String? bio;
  final bool qnaEnabled;
  final bool commentsEnabled;
  final String? upcomingEventId;

  // Location fields for matchups
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final int? maxTravelDistanceKm;

  // Matchup availability fields
  final MatchupAvailability matchupAvailability;
  final List<String> preferredWeightClasses;
  final List<String> preferredOpponentStyles;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final String? matchupNotes;
  final bool willingToTravel;
  final double? minimumPurse;
  final List<String> blockedFighterIds;

  final DateTime createdAt;
  final DateTime updatedAt;

  const FighterModel({
    required this.id,
    required this.userId,
    required this.fullName,
    this.nickname,
    this.nationality,
    this.gender = FighterGender.undisclosed,
    this.dateOfBirth,
    this.weightClass,
    this.sportType,
    this.stance,
    this.status = FighterStatus.active,
    this.heightCm,
    this.reachCm,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.noContests = 0,
    this.knockouts = 0,
    this.submissions = 0,
    this.currentGymId,
    this.currentCoachId,
    this.previousGymIds = const [],
    this.photoUrl,
    this.coverPhotoUrl,
    this.socialLinks,
    // FightWire 2.0 fields
    this.regionId,
    this.bio,
    this.qnaEnabled = true,
    this.commentsEnabled = true,
    this.upcomingEventId,
    // Location fields
    this.city,
    this.state,
    this.country,
    this.latitude,
    this.longitude,
    this.maxTravelDistanceKm,
    // Matchup fields
    this.matchupAvailability = MatchupAvailability.available,
    this.preferredWeightClasses = const [],
    this.preferredOpponentStyles = const [],
    this.availableFrom,
    this.availableUntil,
    this.matchupNotes,
    this.willingToTravel = true,
    this.minimumPurse,
    this.blockedFighterIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Professional record as string (e.g., "15-3-0")
  String get record => '$wins-$losses-$draws';

  /// Total number of fights
  int get totalFights => wins + losses + draws + noContests;

  /// Win percentage
  double get winPercentage =>
      totalFights > 0 ? (wins / totalFights) * 100 : 0.0;

  /// Finish rate (KO + Sub / Wins)
  double get finishRate =>
      wins > 0 ? ((knockouts + submissions) / wins) * 100 : 0.0;

  factory FighterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FighterModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      nickname: data['nickname'],
      nationality: data['nationality'],
      gender: data['gender'] != null
          ? FighterGender.values.firstWhere(
              (g) => g.name == data['gender'],
              orElse: () => FighterGender.undisclosed,
            )
          : FighterGender.undisclosed,
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      weightClass: data['weightClass'],
      sportType: data['sportType'],
      stance: data['stance'] != null
          ? FighterStance.values.firstWhere(
              (s) => s.name == data['stance'],
              orElse: () => FighterStance.orthodox,
            )
          : null,
      status: FighterStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => FighterStatus.active,
      ),
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      reachCm: (data['reachCm'] as num?)?.toDouble(),
      wins: data['wins'] ?? 0,
      losses: data['losses'] ?? 0,
      draws: data['draws'] ?? 0,
      noContests: data['noContests'] ?? 0,
      knockouts: data['knockouts'] ?? 0,
      submissions: data['submissions'] ?? 0,
      currentGymId: data['currentGymId'],
      currentCoachId: data['currentCoachId'],
      previousGymIds: List<String>.from(data['previousGymIds'] ?? []),
      photoUrl: data['photoUrl'],
      coverPhotoUrl: data['coverPhotoUrl'],
      socialLinks: data['socialLinks'],
      // FightWire 2.0 fields
      regionId: data['regionId'],
      bio: data['bio'],
      qnaEnabled: data['qnaEnabled'] ?? true,
      commentsEnabled: data['commentsEnabled'] ?? true,
      upcomingEventId: data['upcomingEventId'],
      // Location fields
      city: data['city'],
      state: data['state'],
      country: data['country'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      maxTravelDistanceKm: data['maxTravelDistanceKm'],
      // Matchup fields
      matchupAvailability: MatchupAvailability.values.firstWhere(
        (m) => m.name == data['matchupAvailability'],
        orElse: () => MatchupAvailability.available,
      ),
      preferredWeightClasses: List<String>.from(
        data['preferredWeightClasses'] ?? [],
      ),
      preferredOpponentStyles: List<String>.from(
        data['preferredOpponentStyles'] ?? [],
      ),
      availableFrom: (data['availableFrom'] as Timestamp?)?.toDate(),
      availableUntil: (data['availableUntil'] as Timestamp?)?.toDate(),
      matchupNotes: data['matchupNotes'],
      willingToTravel: data['willingToTravel'] ?? true,
      minimumPurse: (data['minimumPurse'] as num?)?.toDouble(),
      blockedFighterIds: List<String>.from(data['blockedFighterIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'nickname': nickname,
      'nationality': nationality,
      'gender': gender.name,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'weightClass': weightClass,
      'sportType': sportType,
      'stance': stance?.name,
      'status': status.name,
      'heightCm': heightCm,
      'reachCm': reachCm,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'noContests': noContests,
      'knockouts': knockouts,
      'submissions': submissions,
      'currentGymId': currentGymId,
      'currentCoachId': currentCoachId,
      'previousGymIds': previousGymIds,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'socialLinks': socialLinks,
      // FightWire 2.0 fields
      'regionId': regionId,
      'bio': bio,
      'qnaEnabled': qnaEnabled,
      'commentsEnabled': commentsEnabled,
      'upcomingEventId': upcomingEventId,
      // Location fields
      'city': city,
      'state': state,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'maxTravelDistanceKm': maxTravelDistanceKm,
      // Matchup fields
      'matchupAvailability': matchupAvailability.name,
      'preferredWeightClasses': preferredWeightClasses,
      'preferredOpponentStyles': preferredOpponentStyles,
      'availableFrom': availableFrom != null
          ? Timestamp.fromDate(availableFrom!)
          : null,
      'availableUntil': availableUntil != null
          ? Timestamp.fromDate(availableUntil!)
          : null,
      'matchupNotes': matchupNotes,
      'willingToTravel': willingToTravel,
      'minimumPurse': minimumPurse,
      'blockedFighterIds': blockedFighterIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Location display string
  String get locationDisplay {
    final parts = [city, state, country].whereType<String>().toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Location not set';
  }

  /// Check if fighter is available for matchup
  bool get isAvailableForMatchup {
    if (matchupAvailability != MatchupAvailability.available) return false;
    if (status != FighterStatus.active) return false;
    final now = DateTime.now();
    if (availableFrom != null && now.isBefore(availableFrom!)) return false;
    if (availableUntil != null && now.isAfter(availableUntil!)) return false;
    return true;
  }

  FighterModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? nickname,
    String? nationality,
    FighterGender? gender,
    DateTime? dateOfBirth,
    String? weightClass,
    String? sportType,
    FighterStance? stance,
    FighterStatus? status,
    double? heightCm,
    double? reachCm,
    int? wins,
    int? losses,
    int? draws,
    int? noContests,
    int? knockouts,
    int? submissions,
    String? currentGymId,
    String? currentCoachId,
    List<String>? previousGymIds,
    String? photoUrl,
    String? coverPhotoUrl,
    Map<String, dynamic>? socialLinks,
    // FightWire 2.0
    String? regionId,
    String? bio,
    bool? qnaEnabled,
    bool? commentsEnabled,
    String? upcomingEventId,
    // Location
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    int? maxTravelDistanceKm,
    // Matchup
    MatchupAvailability? matchupAvailability,
    List<String>? preferredWeightClasses,
    List<String>? preferredOpponentStyles,
    DateTime? availableFrom,
    DateTime? availableUntil,
    String? matchupNotes,
    bool? willingToTravel,
    double? minimumPurse,
    List<String>? blockedFighterIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FighterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      nationality: nationality ?? this.nationality,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      weightClass: weightClass ?? this.weightClass,
      sportType: sportType ?? this.sportType,
      stance: stance ?? this.stance,
      status: status ?? this.status,
      heightCm: heightCm ?? this.heightCm,
      reachCm: reachCm ?? this.reachCm,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      noContests: noContests ?? this.noContests,
      knockouts: knockouts ?? this.knockouts,
      submissions: submissions ?? this.submissions,
      currentGymId: currentGymId ?? this.currentGymId,
      currentCoachId: currentCoachId ?? this.currentCoachId,
      previousGymIds: previousGymIds ?? this.previousGymIds,
      photoUrl: photoUrl ?? this.photoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      regionId: regionId ?? this.regionId,
      bio: bio ?? this.bio,
      qnaEnabled: qnaEnabled ?? this.qnaEnabled,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      upcomingEventId: upcomingEventId ?? this.upcomingEventId,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      maxTravelDistanceKm: maxTravelDistanceKm ?? this.maxTravelDistanceKm,
      matchupAvailability: matchupAvailability ?? this.matchupAvailability,
      preferredWeightClasses:
          preferredWeightClasses ?? this.preferredWeightClasses,
      preferredOpponentStyles:
          preferredOpponentStyles ?? this.preferredOpponentStyles,
      availableFrom: availableFrom ?? this.availableFrom,
      availableUntil: availableUntil ?? this.availableUntil,
      matchupNotes: matchupNotes ?? this.matchupNotes,
      willingToTravel: willingToTravel ?? this.willingToTravel,
      minimumPurse: minimumPurse ?? this.minimumPurse,
      blockedFighterIds: blockedFighterIds ?? this.blockedFighterIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    fullName,
    nickname,
    status,
    gender,
    wins,
    losses,
    draws,
    city,
    country,
    matchupAvailability,
    regionId,
    qnaEnabled,
    commentsEnabled,
  ];
}
