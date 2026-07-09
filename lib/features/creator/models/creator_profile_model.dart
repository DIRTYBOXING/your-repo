import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Creator profile — identity, rank, influence metrics
class CreatorProfile extends Equatable {
  final String creatorId;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final int followerCount;
  final int rank; // 1-10000 globally
  final double trendingScore; // 0-10
  final DateTime joinedDate;
  final bool isVerified;
  final String? website;
  final String? socialHandle;

  const CreatorProfile({
    required this.creatorId,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    required this.followerCount,
    required this.rank,
    required this.trendingScore,
    required this.joinedDate,
    this.isVerified = false,
    this.website,
    this.socialHandle,
  });

  /// Serialize to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'followerCount': followerCount,
      'rank': rank,
      'trendingScore': trendingScore,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'isVerified': isVerified,
      'website': website,
      'socialHandle': socialHandle,
    };
  }

  /// Deserialize from Firestore
  factory CreatorProfile.fromFirestore(Map<String, dynamic> doc) {
    return CreatorProfile(
      creatorId: doc['creatorId'] ?? '',
      displayName: doc['displayName'] ?? 'Unknown Creator',
      bio: doc['bio'],
      avatarUrl: doc['avatarUrl'],
      followerCount: doc['followerCount'] ?? 0,
      rank: doc['rank'] ?? 9999,
      trendingScore: (doc['trendingScore'] ?? 0.0).toDouble(),
      joinedDate: doc['joinedDate'] is Timestamp
          ? (doc['joinedDate'] as Timestamp).toDate()
          : DateTime.now(),
      isVerified: doc['isVerified'] ?? false,
      website: doc['website'],
      socialHandle: doc['socialHandle'],
    );
  }

  /// Copy with modifications
  CreatorProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
    int? followerCount,
    int? rank,
    double? trendingScore,
    bool? isVerified,
  }) {
    return CreatorProfile(
      creatorId: creatorId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      followerCount: followerCount ?? this.followerCount,
      rank: rank ?? this.rank,
      trendingScore: trendingScore ?? this.trendingScore,
      joinedDate: joinedDate,
      isVerified: isVerified ?? this.isVerified,
      website: website,
      socialHandle: socialHandle,
    );
  }

  @override
  List<Object?> get props => [
    creatorId,
    displayName,
    bio,
    avatarUrl,
    followerCount,
    rank,
    trendingScore,
    joinedDate,
    isVerified,
  ];
}
