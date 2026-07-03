import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// User roles in the platform
enum UserRole {
  superadmin, // ⭐ Head Pilot — Platform Owner (full authority)
  admin,
  fighter,
  coach,
  gym,
  promoter,
  sponsor,
  fan;

  String get displayName {
    switch (this) {
      case UserRole.superadmin:
        return '⭐ Head Pilot';
      case UserRole.admin:
        return 'Admin';
      case UserRole.coach:
        return 'Coach';
      case UserRole.gym:
        return 'Gym';
      case UserRole.promoter:
        return 'Promoter';
      case UserRole.sponsor:
        return 'Sponsor';
      case UserRole.fan:
        return 'Fan';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.superadmin:
        return 'Head Pilot & Platform Owner — full authority over all DFC systems';
      case UserRole.admin:
        return 'Platform administration';
      case UserRole.fighter:
        return 'Compete and track your career';
      case UserRole.coach:
        return 'Train fighters and manage teams';
      case UserRole.gym:
        return 'Manage your facility and members';
      case UserRole.promoter:
        return 'Organize events and discover talent';
      case UserRole.sponsor:
        return 'Connect with athletes and events';
      case UserRole.fan:
        return 'Follow fighters and engage with the community';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name == value.toLowerCase(),
      orElse: () => UserRole.fan,
    );
  }
}

/// Core User model
class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? username;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final String? pageAvatarUrl;
  final String? pageCoverUrl;
  final String? bio;
  final UserRole role;
  final bool emailVerified;
  final bool isActive;
  final bool isVerified; // Platform verification (blue checkmark)
  final bool onboardingCompleted;
  final DateTime? dateOfBirth; // Age verification (13+/16+ compliance)
  final bool businessVerified; // ID verification for promoters/gyms/sponsors
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
    this.photoUrl,
    this.coverPhotoUrl,
    this.pageAvatarUrl,
    this.pageCoverUrl,
    this.bio,
    required this.role,
    this.emailVerified = false,
    this.isActive = true,
    this.isVerified = false,
    this.onboardingCompleted = false,
    this.dateOfBirth,
    this.businessVerified = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.metadata,
  });

  String? get resolvedAvatarUrl => pageAvatarUrl ?? photoUrl;

  String? get resolvedCoverUrl => pageCoverUrl ?? coverPhotoUrl;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      username: data['username'],
      photoUrl: data['photoUrl'] ?? data['photoURL'],
      coverPhotoUrl: data['coverPhotoUrl'] ?? data['bannerUrl'],
      pageAvatarUrl:
          data['pageAvatarUrl'] ?? data['brandLogoUrl'] ?? data['photoUrl'],
      pageCoverUrl:
          data['pageCoverUrl'] ?? data['pageBannerUrl'] ?? data['bannerUrl'],
      bio: data['bio'],
      role: UserRole.fromString(data['role'] ?? 'fan'),
      emailVerified: data['emailVerified'] ?? false,
      isActive: data['isActive'] ?? true,
      isVerified: data['isVerified'] ?? false,
      onboardingCompleted: data['onboardingCompleted'] ?? false,
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate(),
      businessVerified: data['businessVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
      'photoURL': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'pageAvatarUrl': pageAvatarUrl ?? photoUrl,
      'pageCoverUrl': pageCoverUrl ?? coverPhotoUrl,
      'bio': bio,
      'role': role.name,
      'emailVerified': emailVerified,
      'isActive': isActive,
      'isVerified': isVerified,
      'onboardingCompleted': onboardingCompleted,
      'dateOfBirth': dateOfBirth != null
          ? Timestamp.fromDate(dateOfBirth!)
          : null,
      'businessVerified': businessVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? photoUrl,
    String? coverPhotoUrl,
    String? pageAvatarUrl,
    String? pageCoverUrl,
    String? bio,
    UserRole? role,
    bool? emailVerified,
    bool? isActive,
    bool? isVerified,
    bool? onboardingCompleted,
    DateTime? dateOfBirth,
    bool? businessVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      pageAvatarUrl: pageAvatarUrl ?? this.pageAvatarUrl,
      pageCoverUrl: pageCoverUrl ?? this.pageCoverUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      emailVerified: emailVerified ?? this.emailVerified,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      businessVerified: businessVerified ?? this.businessVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    displayName,
    username,
    photoUrl,
    coverPhotoUrl,
    pageAvatarUrl,
    pageCoverUrl,
    bio,
    role,
    emailVerified,
    isActive,
    isVerified,
    onboardingCompleted,
    dateOfBirth,
    businessVerified,
    createdAt,
    updatedAt,
    lastLoginAt,
  ];
}
