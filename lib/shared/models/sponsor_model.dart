import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Sponsor model for business sponsors
class SponsorModel extends Equatable {
  final String id;
  final String userId;
  final String companyName;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? websiteUrl;
  final String? industry;
  final String? contactEmail;
  final String? contactPhone;
  final Map<String, dynamic>? address;
  final List<String> sponsoredFighterIds;
  final List<String> sponsoredEventIds;
  final List<String> sponsoredGymIds;
  final double? totalSponsorshipValue;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic>? socialLinks;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SponsorModel({
    required this.id,
    required this.userId,
    required this.companyName,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.websiteUrl,
    this.industry,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.sponsoredFighterIds = const [],
    this.sponsoredEventIds = const [],
    this.sponsoredGymIds = const [],
    this.totalSponsorshipValue,
    this.isVerified = false,
    this.isActive = true,
    this.socialLinks,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Total sponsorships count
  int get totalSponsorships =>
      sponsoredFighterIds.length +
      sponsoredEventIds.length +
      sponsoredGymIds.length;

  factory SponsorModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SponsorModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      companyName: data['companyName'] ?? '',
      description: data['description'],
      logoUrl: data['logoUrl'],
      bannerUrl: data['bannerUrl'],
      websiteUrl: data['websiteUrl'],
      industry: data['industry'],
      contactEmail: data['contactEmail'],
      contactPhone: data['contactPhone'],
      address: data['address'],
      sponsoredFighterIds: List<String>.from(data['sponsoredFighterIds'] ?? []),
      sponsoredEventIds: List<String>.from(data['sponsoredEventIds'] ?? []),
      sponsoredGymIds: List<String>.from(data['sponsoredGymIds'] ?? []),
      totalSponsorshipValue: (data['totalSponsorshipValue'] as num?)
          ?.toDouble(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      socialLinks: data['socialLinks'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'companyName': companyName,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'websiteUrl': websiteUrl,
      'industry': industry,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'sponsoredFighterIds': sponsoredFighterIds,
      'sponsoredEventIds': sponsoredEventIds,
      'sponsoredGymIds': sponsoredGymIds,
      'totalSponsorshipValue': totalSponsorshipValue,
      'isVerified': isVerified,
      'isActive': isActive,
      'socialLinks': socialLinks,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SponsorModel copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    String? websiteUrl,
    String? industry,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? address,
    List<String>? sponsoredFighterIds,
    List<String>? sponsoredEventIds,
    List<String>? sponsoredGymIds,
    double? totalSponsorshipValue,
    bool? isVerified,
    bool? isActive,
    Map<String, dynamic>? socialLinks,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SponsorModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      industry: industry ?? this.industry,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      sponsoredFighterIds: sponsoredFighterIds ?? this.sponsoredFighterIds,
      sponsoredEventIds: sponsoredEventIds ?? this.sponsoredEventIds,
      sponsoredGymIds: sponsoredGymIds ?? this.sponsoredGymIds,
      totalSponsorshipValue:
          totalSponsorshipValue ?? this.totalSponsorshipValue,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      socialLinks: socialLinks ?? this.socialLinks,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, companyName, isActive];
}

/// Coach model for trainers
class CoachModel extends Equatable {
  final String id;
  final String userId;
  final String? gymId;
  final String? bio;
  final List<String> specialties; // e.g., boxing, wrestling, BJJ
  final List<String> certifications;
  final int? yearsExperience;
  final List<String> fighterIds;
  final List<String> achievements;
  final String? profileImageUrl;
  final Map<String, dynamic>? availability;
  final double? hourlyRate;
  final String? currency;
  final bool isAvailableForHire;
  final bool isVerified;
  final double? rating;
  final int reviewsCount;
  final Map<String, dynamic>? socialLinks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CoachModel({
    required this.id,
    required this.userId,
    this.gymId,
    this.bio,
    this.specialties = const [],
    this.certifications = const [],
    this.yearsExperience,
    this.fighterIds = const [],
    this.achievements = const [],
    this.profileImageUrl,
    this.availability,
    this.hourlyRate,
    this.currency,
    this.isAvailableForHire = false,
    this.isVerified = false,
    this.rating,
    this.reviewsCount = 0,
    this.socialLinks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Number of current fighters
  int get fightersCount => fighterIds.length;

  factory CoachModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CoachModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      gymId: data['gymId'],
      bio: data['bio'],
      specialties: List<String>.from(data['specialties'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      yearsExperience: data['yearsExperience'],
      fighterIds: List<String>.from(data['fighterIds'] ?? []),
      achievements: List<String>.from(data['achievements'] ?? []),
      profileImageUrl: data['profileImageUrl'],
      availability: data['availability'],
      hourlyRate: (data['hourlyRate'] as num?)?.toDouble(),
      currency: data['currency'],
      isAvailableForHire: data['isAvailableForHire'] ?? false,
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewsCount: data['reviewsCount'] ?? 0,
      socialLinks: data['socialLinks'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'gymId': gymId,
      'bio': bio,
      'specialties': specialties,
      'certifications': certifications,
      'yearsExperience': yearsExperience,
      'fighterIds': fighterIds,
      'achievements': achievements,
      'profileImageUrl': profileImageUrl,
      'availability': availability,
      'hourlyRate': hourlyRate,
      'currency': currency,
      'isAvailableForHire': isAvailableForHire,
      'isVerified': isVerified,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'socialLinks': socialLinks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CoachModel copyWith({
    String? id,
    String? userId,
    String? gymId,
    String? bio,
    List<String>? specialties,
    List<String>? certifications,
    int? yearsExperience,
    List<String>? fighterIds,
    List<String>? achievements,
    String? profileImageUrl,
    Map<String, dynamic>? availability,
    double? hourlyRate,
    String? currency,
    bool? isAvailableForHire,
    bool? isVerified,
    double? rating,
    int? reviewsCount,
    Map<String, dynamic>? socialLinks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CoachModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      gymId: gymId ?? this.gymId,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      certifications: certifications ?? this.certifications,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      fighterIds: fighterIds ?? this.fighterIds,
      achievements: achievements ?? this.achievements,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      availability: availability ?? this.availability,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      currency: currency ?? this.currency,
      isAvailableForHire: isAvailableForHire ?? this.isAvailableForHire,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, gymId, isVerified];
}

/// Promoter model for event promoters
class PromoterModel extends Equatable {
  final String id;
  final String userId;
  final String companyName;
  final String? description;
  final String? logoUrl;
  final String? websiteUrl;
  final String? contactEmail;
  final String? contactPhone;
  final Map<String, dynamic>? address;
  final List<String> eventIds;
  final List<String> sanctioningBodies;
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final bool isVerified;
  final bool isActive;
  final int totalEventsHosted;
  final Map<String, dynamic>? socialLinks;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PromoterModel({
    required this.id,
    required this.userId,
    required this.companyName,
    this.description,
    this.logoUrl,
    this.websiteUrl,
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.eventIds = const [],
    this.sanctioningBodies = const [],
    this.licenseNumber,
    this.licenseExpiry,
    this.isVerified = false,
    this.isActive = true,
    this.totalEventsHosted = 0,
    this.socialLinks,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Is license valid
  bool get hasValidLicense {
    if (licenseExpiry == null) return false;
    return DateTime.now().isBefore(licenseExpiry!);
  }

  factory PromoterModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoterModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      companyName: data['companyName'] ?? '',
      description: data['description'],
      logoUrl: data['logoUrl'],
      websiteUrl: data['websiteUrl'],
      contactEmail: data['contactEmail'],
      contactPhone: data['contactPhone'],
      address: data['address'],
      eventIds: List<String>.from(data['eventIds'] ?? []),
      sanctioningBodies: List<String>.from(data['sanctioningBodies'] ?? []),
      licenseNumber: data['licenseNumber'],
      licenseExpiry: (data['licenseExpiry'] as Timestamp?)?.toDate(),
      isVerified: data['isVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      totalEventsHosted: data['totalEventsHosted'] ?? 0,
      socialLinks: data['socialLinks'],
      metadata: data['metadata'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'companyName': companyName,
      'description': description,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'address': address,
      'eventIds': eventIds,
      'sanctioningBodies': sanctioningBodies,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry != null
          ? Timestamp.fromDate(licenseExpiry!)
          : null,
      'isVerified': isVerified,
      'isActive': isActive,
      'totalEventsHosted': totalEventsHosted,
      'socialLinks': socialLinks,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PromoterModel copyWith({
    String? id,
    String? userId,
    String? companyName,
    String? description,
    String? logoUrl,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? address,
    List<String>? eventIds,
    List<String>? sanctioningBodies,
    String? licenseNumber,
    DateTime? licenseExpiry,
    bool? isVerified,
    bool? isActive,
    int? totalEventsHosted,
    Map<String, dynamic>? socialLinks,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromoterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName ?? this.companyName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      eventIds: eventIds ?? this.eventIds,
      sanctioningBodies: sanctioningBodies ?? this.sanctioningBodies,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      totalEventsHosted: totalEventsHosted ?? this.totalEventsHosted,
      socialLinks: socialLinks ?? this.socialLinks,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, companyName, isVerified];
}
