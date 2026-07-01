import 'package:cloud_firestore/cloud_firestore.dart';

/// Platform-wide settings singleton.
/// Collection: settings/platform
class PlatformSettingsModel {
  final List<String> moderationRules;
  final List<String> bannedWords;
  final Map<String, dynamic> commentFilters;
  final Map<String, dynamic> qnaRules;
  final Map<String, dynamic> branding;
  final Map<String, dynamic> roles;

  const PlatformSettingsModel({
    this.moderationRules = const [],
    this.bannedWords = const [],
    this.commentFilters = const {},
    this.qnaRules = const {},
    this.branding = const {},
    this.roles = const {},
  });

  factory PlatformSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PlatformSettingsModel(
      moderationRules: List<String>.from(data['moderationRules'] ?? []),
      bannedWords: List<String>.from(data['bannedWords'] ?? []),
      commentFilters: Map<String, dynamic>.from(data['commentFilters'] ?? {}),
      qnaRules: Map<String, dynamic>.from(data['qnaRules'] ?? {}),
      branding: Map<String, dynamic>.from(data['branding'] ?? {}),
      roles: Map<String, dynamic>.from(data['roles'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'moderationRules': moderationRules,
      'bannedWords': bannedWords,
      'commentFilters': commentFilters,
      'qnaRules': qnaRules,
      'branding': branding,
      'roles': roles,
    };
  }
}
