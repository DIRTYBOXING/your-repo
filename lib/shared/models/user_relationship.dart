import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// USER RELATIONSHIP MODEL — Social Graph System
/// Tracks all relationships between users for feed ranking
/// ═══════════════════════════════════════════════════════════════════════════

class UserRelationship extends Equatable {
  final String id;
  final String userId;
  final String targetUserId;
  final RelationshipType type;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Mutual connection
  final bool isMutual;

  // Gym connection
  final String? sharedGymId;
  final bool isTrainingPartner;

  // Interaction metrics
  final int interactionCount;
  final DateTime? lastInteraction;

  // Trust & verification
  final bool isVerified;
  final double connectionStrength; // 0.0 - 1.0

  const UserRelationship({
    required this.id,
    required this.userId,
    required this.targetUserId,
    required this.type,
    required this.createdAt,
    this.updatedAt,
    this.isMutual = false,
    this.sharedGymId,
    this.isTrainingPartner = false,
    this.interactionCount = 0,
    this.lastInteraction,
    this.isVerified = false,
    this.connectionStrength = 0.5,
  });

  @override
  List<Object?> get props => [id, userId, targetUserId, type, createdAt];

  factory UserRelationship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRelationship(
      id: doc.id,
      userId: data['userId'] ?? '',
      targetUserId: data['targetUserId'] ?? '',
      type: RelationshipType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => RelationshipType.following,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isMutual: data['isMutual'] ?? false,
      sharedGymId: data['sharedGymId'],
      isTrainingPartner: data['isTrainingPartner'] ?? false,
      interactionCount: data['interactionCount'] ?? 0,
      lastInteraction: data['lastInteraction'] != null
          ? (data['lastInteraction'] as Timestamp).toDate()
          : null,
      isVerified: data['isVerified'] ?? false,
      connectionStrength: data['connectionStrength']?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'targetUserId': targetUserId,
      'type': type.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isMutual': isMutual,
      'sharedGymId': sharedGymId,
      'isTrainingPartner': isTrainingPartner,
      'interactionCount': interactionCount,
      'lastInteraction': lastInteraction != null
          ? Timestamp.fromDate(lastInteraction!)
          : null,
      'isVerified': isVerified,
      'connectionStrength': connectionStrength,
    };
  }

  UserRelationship copyWith({
    bool? isMutual,
    int? interactionCount,
    DateTime? lastInteraction,
    double? connectionStrength,
  }) {
    return UserRelationship(
      id: id,
      userId: userId,
      targetUserId: targetUserId,
      type: type,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isMutual: isMutual ?? this.isMutual,
      sharedGymId: sharedGymId,
      isTrainingPartner: isTrainingPartner,
      interactionCount: interactionCount ?? this.interactionCount,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      isVerified: isVerified,
      connectionStrength: connectionStrength ?? this.connectionStrength,
    );
  }
}

enum RelationshipType {
  friend, // Mutual friendship
  coach, // Coach-fighter relationship
  trainingPartner, // Regular training together
  gymMember, // Same gym membership
  fan, // Fan following fighter
  promoter, // Promoter representing fighter
  sponsor, // Sponsorship relationship
  following, // One-way follow
}

/// Relationship strength weights for feed ranking
extension RelationshipWeight on RelationshipType {
  double get weight {
    switch (this) {
      case RelationshipType.friend:
        return 0.40;
      case RelationshipType.trainingPartner:
        return 0.35;
      case RelationshipType.gymMember:
        return 0.30;
      case RelationshipType.coach:
        return 0.35;
      case RelationshipType.following:
        return 0.15;
      case RelationshipType.fan:
        return 0.10;
      case RelationshipType.promoter:
        return 0.20;
      case RelationshipType.sponsor:
        return 0.25;
    }
  }
}
