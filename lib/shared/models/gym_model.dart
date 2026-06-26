import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Gym status
enum GymStatus { active, inactive, pending, suspended }

/// Gym model for training facilities
class GymModel extends Equatable {
  final String id;
  final String userId; // Owner's user ID
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? website;
  final List<String> sportTypes; // MMA, Boxing, BJJ, etc.
  final List<String> amenities;
  final String? logoUrl;
  final String? coverPhotoUrl;
  final List<String> photoGallery;
  final Map<String, String>? operatingHours;
  final List<String> coachIds;
  final List<String> fighterIds;
  final GymStatus status;
  final bool isVerified;
  final double? rating;
  final int reviewCount;
  final Map<String, dynamic>? socialLinks;
  final String? regionId;
  final String? pinkShieldStatus;
  final String? bannerUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GymModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.sportTypes = const [],
    this.amenities = const [],
    this.logoUrl,
    this.coverPhotoUrl,
    this.photoGallery = const [],
    this.operatingHours,
    this.coachIds = const [],
    this.fighterIds = const [],
    this.status = GymStatus.active,
    this.isVerified = false,
    this.rating,
    this.reviewCount = 0,
    this.socialLinks,
    this.regionId,
    this.pinkShieldStatus,
    this.bannerUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Full address string
  String get fullAddress {
    final parts = [
      address,
      city,
      state,
      postalCode,
      country,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }

  /// Number of active members (coaches + fighters)
  int get memberCount => coachIds.length + fighterIds.length;

  factory GymModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GymModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      address: data['address'],
      city: data['city'],
      state: data['state'],
      country: data['country'],
      postalCode: data['postalCode'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      phone: data['phone'],
      email: data['email'],
      website: data['website'],
      sportTypes: List<String>.from(data['sportTypes'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      logoUrl: data['logoUrl'],
      coverPhotoUrl: data['coverPhotoUrl'],
      photoGallery: List<String>.from(data['photoGallery'] ?? []),
      operatingHours: data['operatingHours'] != null
          ? Map<String, String>.from(data['operatingHours'])
          : null,
      coachIds: List<String>.from(data['coachIds'] ?? []),
      fighterIds: List<String>.from(data['fighterIds'] ?? []),
      status: GymStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GymStatus.active,
      ),
      isVerified: data['isVerified'] ?? false,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      socialLinks: data['socialLinks'],
      regionId: data['regionId'],
      pinkShieldStatus: data['pinkShieldStatus'],
      bannerUrl: data['bannerUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'email': email,
      'website': website,
      'sportTypes': sportTypes,
      'amenities': amenities,
      'logoUrl': logoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'photoGallery': photoGallery,
      'operatingHours': operatingHours,
      'coachIds': coachIds,
      'fighterIds': fighterIds,
      'status': status.name,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'socialLinks': socialLinks,
      'regionId': regionId,
      'pinkShieldStatus': pinkShieldStatus,
      'bannerUrl': bannerUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  GymModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    String? website,
    List<String>? sportTypes,
    List<String>? amenities,
    String? logoUrl,
    String? coverPhotoUrl,
    List<String>? photoGallery,
    Map<String, String>? operatingHours,
    List<String>? coachIds,
    List<String>? fighterIds,
    GymStatus? status,
    bool? isVerified,
    double? rating,
    int? reviewCount,
    Map<String, dynamic>? socialLinks,
    String? regionId,
    String? pinkShieldStatus,
    String? bannerUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GymModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      sportTypes: sportTypes ?? this.sportTypes,
      amenities: amenities ?? this.amenities,
      logoUrl: logoUrl ?? this.logoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      photoGallery: photoGallery ?? this.photoGallery,
      operatingHours: operatingHours ?? this.operatingHours,
      coachIds: coachIds ?? this.coachIds,
      fighterIds: fighterIds ?? this.fighterIds,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      socialLinks: socialLinks ?? this.socialLinks,
      regionId: regionId ?? this.regionId,
      pinkShieldStatus: pinkShieldStatus ?? this.pinkShieldStatus,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, status, isVerified, regionId];
}
