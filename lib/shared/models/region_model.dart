import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Region model — fight city identity (Logan, Bronx Islanders, Brisbane, etc.)
/// Collection: regions/{regionId}
/// Subcollections: regions/{regionId}/posts/{postId}
///                 regions/{regionId}/members/{userId}
class RegionModel extends Equatable {
  final String id;
  final String name;
  final String? bannerUrl;
  final String? description;
  final int followerCount;
  final DateTime createdAt;

  const RegionModel({
    required this.id,
    required this.name,
    this.bannerUrl,
    this.description,
    this.followerCount = 0,
    required this.createdAt,
  });

  factory RegionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegionModel(
      id: doc.id,
      name: data['name'] ?? '',
      bannerUrl: data['bannerUrl'],
      description: data['description'],
      followerCount: data['followerCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'bannerUrl': bannerUrl,
      'description': description,
      'followerCount': followerCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RegionModel copyWith({
    String? id,
    String? name,
    String? bannerUrl,
    String? description,
    int? followerCount,
    DateTime? createdAt,
  }) {
    return RegionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      description: description ?? this.description,
      followerCount: followerCount ?? this.followerCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, followerCount];
}

/// Region member — tracks users following a region.
/// Subcollection: regions/{regionId}/members/{userId}
class RegionMemberModel {
  final String userId;
  final DateTime joinedAt;

  const RegionMemberModel({required this.userId, required this.joinedAt});

  factory RegionMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RegionMemberModel(
      userId: doc.id,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'joinedAt': Timestamp.fromDate(joinedAt)};
  }
}
