import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// User Settings Model — Firestore-persisted preferences (like Facebook settings)
/// Collection: user_settings/{userId}
/// ═══════════════════════════════════════════════════════════════════════════

class NotificationPreferences extends Equatable {
  // Push
  final bool pushEnabled;
  final bool fightAlerts;
  final bool trainingReminders;
  final bool socialMentions;
  final bool campaignWins;
  final bool marketplace;
  final bool weightReminders;
  final bool coachMessages;

  // In-app
  final bool aiTips;
  final bool fightWire;
  final bool achievements;
  final bool promotions;
  final bool community;

  // Quiet hours
  final bool quietHoursEnabled;
  final int quietStartHour;
  final int quietStartMinute;
  final int quietEndHour;
  final int quietEndMinute;

  // Email digest
  final String emailDigest; // 'daily', 'weekly', 'none'
  final bool emailNotifications;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.fightAlerts = true,
    this.trainingReminders = true,
    this.socialMentions = true,
    this.campaignWins = true,
    this.marketplace = true,
    this.weightReminders = true,
    this.coachMessages = true,
    this.aiTips = true,
    this.fightWire = true,
    this.achievements = true,
    this.promotions = false,
    this.community = true,
    this.quietHoursEnabled = false,
    this.quietStartHour = 22,
    this.quietStartMinute = 0,
    this.quietEndHour = 7,
    this.quietEndMinute = 0,
    this.emailDigest = 'daily',
    this.emailNotifications = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> m) {
    return NotificationPreferences(
      pushEnabled: m['pushEnabled'] ?? true,
      fightAlerts: m['fightAlerts'] ?? true,
      trainingReminders: m['trainingReminders'] ?? true,
      socialMentions: m['socialMentions'] ?? true,
      campaignWins: m['campaignWins'] ?? true,
      marketplace: m['marketplace'] ?? true,
      weightReminders: m['weightReminders'] ?? true,
      coachMessages: m['coachMessages'] ?? true,
      aiTips: m['aiTips'] ?? true,
      fightWire: m['fightWire'] ?? true,
      achievements: m['achievements'] ?? true,
      promotions: m['promotions'] ?? false,
      community: m['community'] ?? true,
      quietHoursEnabled: m['quietHoursEnabled'] ?? false,
      quietStartHour: m['quietStartHour'] ?? 22,
      quietStartMinute: m['quietStartMinute'] ?? 0,
      quietEndHour: m['quietEndHour'] ?? 7,
      quietEndMinute: m['quietEndMinute'] ?? 0,
      emailDigest: m['emailDigest'] ?? 'daily',
      emailNotifications: m['emailNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'pushEnabled': pushEnabled,
    'fightAlerts': fightAlerts,
    'trainingReminders': trainingReminders,
    'socialMentions': socialMentions,
    'campaignWins': campaignWins,
    'marketplace': marketplace,
    'weightReminders': weightReminders,
    'coachMessages': coachMessages,
    'aiTips': aiTips,
    'fightWire': fightWire,
    'achievements': achievements,
    'promotions': promotions,
    'community': community,
    'quietHoursEnabled': quietHoursEnabled,
    'quietStartHour': quietStartHour,
    'quietStartMinute': quietStartMinute,
    'quietEndHour': quietEndHour,
    'quietEndMinute': quietEndMinute,
    'emailDigest': emailDigest,
    'emailNotifications': emailNotifications,
  };

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? fightAlerts,
    bool? trainingReminders,
    bool? socialMentions,
    bool? campaignWins,
    bool? marketplace,
    bool? weightReminders,
    bool? coachMessages,
    bool? aiTips,
    bool? fightWire,
    bool? achievements,
    bool? promotions,
    bool? community,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietStartMinute,
    int? quietEndHour,
    int? quietEndMinute,
    String? emailDigest,
    bool? emailNotifications,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      fightAlerts: fightAlerts ?? this.fightAlerts,
      trainingReminders: trainingReminders ?? this.trainingReminders,
      socialMentions: socialMentions ?? this.socialMentions,
      campaignWins: campaignWins ?? this.campaignWins,
      marketplace: marketplace ?? this.marketplace,
      weightReminders: weightReminders ?? this.weightReminders,
      coachMessages: coachMessages ?? this.coachMessages,
      aiTips: aiTips ?? this.aiTips,
      fightWire: fightWire ?? this.fightWire,
      achievements: achievements ?? this.achievements,
      promotions: promotions ?? this.promotions,
      community: community ?? this.community,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietStartMinute: quietStartMinute ?? this.quietStartMinute,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      quietEndMinute: quietEndMinute ?? this.quietEndMinute,
      emailDigest: emailDigest ?? this.emailDigest,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }

  @override
  List<Object?> get props => [
    pushEnabled, fightAlerts, trainingReminders, socialMentions,
    campaignWins, marketplace, weightReminders, coachMessages,
    aiTips, fightWire, achievements, promotions, community,
    quietHoursEnabled, quietStartHour, quietStartMinute,
    quietEndHour, quietEndMinute, emailDigest, emailNotifications,
  ];
}

class PrivacySettings extends Equatable {
  final String profileVisibility;    // 'public', 'friends', 'private'
  final String activityVisibility;   // 'public', 'friends', 'private'
  final bool showOnlineStatus;
  final bool allowFriendRequests;
  final bool allowMessagesFromStrangers;
  final bool showInSearchResults;
  final bool showFightRecord;
  final bool allowTagging;
  final bool showLocation;
  final bool shareTrainingData;

  const PrivacySettings({
    this.profileVisibility = 'public',
    this.activityVisibility = 'friends',
    this.showOnlineStatus = true,
    this.allowFriendRequests = true,
    this.allowMessagesFromStrangers = false,
    this.showInSearchResults = true,
    this.showFightRecord = true,
    this.allowTagging = true,
    this.showLocation = false,
    this.shareTrainingData = false,
  });

  factory PrivacySettings.fromMap(Map<String, dynamic> m) {
    return PrivacySettings(
      profileVisibility: m['profileVisibility'] ?? 'public',
      activityVisibility: m['activityVisibility'] ?? 'friends',
      showOnlineStatus: m['showOnlineStatus'] ?? true,
      allowFriendRequests: m['allowFriendRequests'] ?? true,
      allowMessagesFromStrangers: m['allowMessagesFromStrangers'] ?? false,
      showInSearchResults: m['showInSearchResults'] ?? true,
      showFightRecord: m['showFightRecord'] ?? true,
      allowTagging: m['allowTagging'] ?? true,
      showLocation: m['showLocation'] ?? false,
      shareTrainingData: m['shareTrainingData'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'profileVisibility': profileVisibility,
    'activityVisibility': activityVisibility,
    'showOnlineStatus': showOnlineStatus,
    'allowFriendRequests': allowFriendRequests,
    'allowMessagesFromStrangers': allowMessagesFromStrangers,
    'showInSearchResults': showInSearchResults,
    'showFightRecord': showFightRecord,
    'allowTagging': allowTagging,
    'showLocation': showLocation,
    'shareTrainingData': shareTrainingData,
  };

  PrivacySettings copyWith({
    String? profileVisibility,
    String? activityVisibility,
    bool? showOnlineStatus,
    bool? allowFriendRequests,
    bool? allowMessagesFromStrangers,
    bool? showInSearchResults,
    bool? showFightRecord,
    bool? allowTagging,
    bool? showLocation,
    bool? shareTrainingData,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      activityVisibility: activityVisibility ?? this.activityVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowMessagesFromStrangers: allowMessagesFromStrangers ?? this.allowMessagesFromStrangers,
      showInSearchResults: showInSearchResults ?? this.showInSearchResults,
      showFightRecord: showFightRecord ?? this.showFightRecord,
      allowTagging: allowTagging ?? this.allowTagging,
      showLocation: showLocation ?? this.showLocation,
      shareTrainingData: shareTrainingData ?? this.shareTrainingData,
    );
  }

  @override
  List<Object?> get props => [
    profileVisibility, activityVisibility, showOnlineStatus,
    allowFriendRequests, allowMessagesFromStrangers, showInSearchResults,
    showFightRecord, allowTagging, showLocation, shareTrainingData,
  ];
}

class SecuritySettings extends Equatable {
  final bool twoFactorEnabled;
  final String? twoFactorMethod;       // 'sms', 'email', 'authenticator'
  final bool loginAlertsEnabled;
  final List<String> trustedDevices;
  final String? recoveryEmail;
  final String? recoveryPhone;
  final bool requirePasswordForChanges;

  const SecuritySettings({
    this.twoFactorEnabled = false,
    this.twoFactorMethod,
    this.loginAlertsEnabled = true,
    this.trustedDevices = const [],
    this.recoveryEmail,
    this.recoveryPhone,
    this.requirePasswordForChanges = true,
  });

  factory SecuritySettings.fromMap(Map<String, dynamic> m) {
    return SecuritySettings(
      twoFactorEnabled: m['twoFactorEnabled'] ?? false,
      twoFactorMethod: m['twoFactorMethod'],
      loginAlertsEnabled: m['loginAlertsEnabled'] ?? true,
      trustedDevices: List<String>.from(m['trustedDevices'] ?? []),
      recoveryEmail: m['recoveryEmail'],
      recoveryPhone: m['recoveryPhone'],
      requirePasswordForChanges: m['requirePasswordForChanges'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'twoFactorEnabled': twoFactorEnabled,
    'twoFactorMethod': twoFactorMethod,
    'loginAlertsEnabled': loginAlertsEnabled,
    'trustedDevices': trustedDevices,
    'recoveryEmail': recoveryEmail,
    'recoveryPhone': recoveryPhone,
    'requirePasswordForChanges': requirePasswordForChanges,
  };

  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    String? twoFactorMethod,
    bool? loginAlertsEnabled,
    List<String>? trustedDevices,
    String? recoveryEmail,
    String? recoveryPhone,
    bool? requirePasswordForChanges,
  }) {
    return SecuritySettings(
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      twoFactorMethod: twoFactorMethod ?? this.twoFactorMethod,
      loginAlertsEnabled: loginAlertsEnabled ?? this.loginAlertsEnabled,
      trustedDevices: trustedDevices ?? this.trustedDevices,
      recoveryEmail: recoveryEmail ?? this.recoveryEmail,
      recoveryPhone: recoveryPhone ?? this.recoveryPhone,
      requirePasswordForChanges: requirePasswordForChanges ?? this.requirePasswordForChanges,
    );
  }

  @override
  List<Object?> get props => [
    twoFactorEnabled, twoFactorMethod, loginAlertsEnabled,
    trustedDevices, recoveryEmail, recoveryPhone, requirePasswordForChanges,
  ];
}

/// Full user settings document
class UserSettingsModel extends Equatable {
  final String userId;
  final NotificationPreferences notifications;
  final PrivacySettings privacy;
  final SecuritySettings security;
  final String contentMode;    // 'family' or '18plus'
  final String? language;
  final String? timezone;
  final DateTime updatedAt;

  const UserSettingsModel({
    required this.userId,
    this.notifications = const NotificationPreferences(),
    this.privacy = const PrivacySettings(),
    this.security = const SecuritySettings(),
    this.contentMode = 'family',
    this.language,
    this.timezone,
    required this.updatedAt,
  });

  factory UserSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserSettingsModel(
      userId: doc.id,
      notifications: NotificationPreferences.fromMap(
        Map<String, dynamic>.from(data['notifications'] ?? {}),
      ),
      privacy: PrivacySettings.fromMap(
        Map<String, dynamic>.from(data['privacy'] ?? {}),
      ),
      security: SecuritySettings.fromMap(
        Map<String, dynamic>.from(data['security'] ?? {}),
      ),
      contentMode: data['contentMode'] ?? 'family',
      language: data['language'],
      timezone: data['timezone'],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'notifications': notifications.toMap(),
    'privacy': privacy.toMap(),
    'security': security.toMap(),
    'contentMode': contentMode,
    'language': language,
    'timezone': timezone,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  UserSettingsModel copyWith({
    NotificationPreferences? notifications,
    PrivacySettings? privacy,
    SecuritySettings? security,
    String? contentMode,
    String? language,
    String? timezone,
  }) {
    return UserSettingsModel(
      userId: userId,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      security: security ?? this.security,
      contentMode: contentMode ?? this.contentMode,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    userId, notifications, privacy, security,
    contentMode, language, timezone, updatedAt,
  ];
}
