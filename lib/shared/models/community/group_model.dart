import 'package:cloud_firestore/cloud_firestore.dart';

/// Privacy levels for groups
enum GroupPrivacy { public, private, secret }

/// Data model for DFC groups (gyms, teams, fan clubs, etc.)
class GroupModel {
  final String id;
  final String name;
  final String description;
  final GroupPrivacy privacy;
  final String? coverImageUrl;
  final String? iconUrl;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final List<String> moderatorIds;
  final List<String> pinnedPostIds;
  final List<String> bannedUserIds;
  final String category; // 'gym', 'team', 'fan_club', 'promotion', 'general'
  final Map<String, dynamic> rules; // {index: ruleText}
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.privacy,
    this.coverImageUrl,
    this.iconUrl,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    this.moderatorIds = const [],
    this.pinnedPostIds = const [],
    this.bannedUserIds = const [],
    this.category = 'general',
    this.rules = const {},
    this.memberCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromMap(Map<String, dynamic> data, String documentId) {
    return GroupModel(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      privacy: _privacyFromString(data['privacy'] ?? 'public'),
      coverImageUrl: data['coverImageUrl'],
      iconUrl: data['iconUrl'],
      creatorId: data['creatorId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      adminIds: List<String>.from(data['adminIds'] ?? []),
      moderatorIds: List<String>.from(data['moderatorIds'] ?? []),
      pinnedPostIds: List<String>.from(data['pinnedPostIds'] ?? []),
      bannedUserIds: List<String>.from(data['bannedUserIds'] ?? []),
      category: data['category'] ?? 'general',
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      memberCount: data['memberCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'privacy': privacy.name,
      'coverImageUrl': coverImageUrl,
      'iconUrl': iconUrl,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'moderatorIds': moderatorIds,
      'pinnedPostIds': pinnedPostIds,
      'bannedUserIds': bannedUserIds,
      'category': category,
      'rules': rules,
      'memberCount': memberCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool isMember(String userId) => memberIds.contains(userId);
  bool isAdmin(String userId) => adminIds.contains(userId);
  bool isModerator(String userId) => moderatorIds.contains(userId);
  bool isBanned(String userId) => bannedUserIds.contains(userId);
  bool hasAuthority(String userId) =>
      isAdmin(userId) || isModerator(userId) || creatorId == userId;

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    GroupPrivacy? privacy,
    String? coverImageUrl,
    String? iconUrl,
    String? creatorId,
    List<String>? memberIds,
    List<String>? adminIds,
    List<String>? moderatorIds,
    List<String>? pinnedPostIds,
    List<String>? bannedUserIds,
    String? category,
    Map<String, dynamic>? rules,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      privacy: privacy ?? this.privacy,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      moderatorIds: moderatorIds ?? this.moderatorIds,
      pinnedPostIds: pinnedPostIds ?? this.pinnedPostIds,
      bannedUserIds: bannedUserIds ?? this.bannedUserIds,
      category: category ?? this.category,
      rules: rules ?? this.rules,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static GroupPrivacy _privacyFromString(String privacy) {
    switch (privacy) {
      case 'private':
        return GroupPrivacy.private;
      case 'secret':
        return GroupPrivacy.secret;
      case 'public':
      default:
        return GroupPrivacy.public;
    }
  }
}
