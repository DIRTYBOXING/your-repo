import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🥷 ADMIN SERVICE — Samurai Panel Backend Operations
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Master control system for DFC ecosystem.
///
/// Capabilities:
/// • User management (warn, mute, suspend, ban)
/// • Content moderation (approve, remove, hide)
/// • Campaign management (create, edit, approve)
/// • Analytics access (growth, engagement, health)
/// • System control (broadcasts, feature toggles)
/// • Security monitoring (spam, bots, abuse)
///
/// ═══════════════════════════════════════════════════════════════════════════
class AdminService {
  final FirebaseFirestore _firestore;

  AdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEM DASHBOARD METRICS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get real-time system status
  Future<SystemStatus> getSystemStatus() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Users online (active in last 15 minutes)
    final activeThreshold = now.subtract(const Duration(minutes: 15));
    final activeUsers = await _firestore
        .collection('users')
        .where('lastActive', isGreaterThan: activeThreshold)
        .count()
        .get();

    // Posts today
    final postsToday = await _firestore
        .collection('posts')
        .where('createdAt', isGreaterThan: todayStart)
        .count()
        .get();

    // Messages today
    final messagesToday = await _firestore
        .collection('messages')
        .where('createdAt', isGreaterThan: todayStart)
        .count()
        .get();

    // Campaign donations today
    final donationsToday = await _firestore
        .collection('campaign_donations')
        .where('createdAt', isGreaterThan: todayStart)
        .get();

    final totalDonations = donationsToday.docs.fold<double>(
      0.0,
      (runningTotal, doc) =>
          runningTotal + ((doc.data()['amount'] as num?)?.toDouble() ?? 0.0),
    );

    // Ninja alerts (pending reports)
    final pendingReports = await _firestore
        .collection('content_reports')
        .where('status', isEqualTo: 'pending')
        .count()
        .get();

    return SystemStatus(
      usersOnline: activeUsers.count ?? 0,
      postsToday: postsToday.count ?? 0,
      messagesToday: messagesToday.count ?? 0,
      donationsToday: totalDonations,
      pendingReports: pendingReports.count ?? 0,
    );
  }

  /// Get growth metrics
  Future<GrowthMetrics> getGrowthMetrics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));

    // New users today
    final newUsersToday = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThan: todayStart)
        .count()
        .get();

    // Total users
    final totalUsers = await _firestore.collection('users').count().get();

    // Invites sent (last 7 days)
    final recentInvites = await _firestore
        .collection('user_invites')
        .where('createdAt', isGreaterThan: weekAgo)
        .count()
        .get();

    // Active regions (users grouped by location)
    final usersSnapshot = await _firestore
        .collection('users')
        .where('lastActive', isGreaterThan: weekAgo)
        .limit(1000)
        .get();

    final regions = <String>{};
    for (final doc in usersSnapshot.docs) {
      final country = doc.data()['country'] as String?;
      if (country != null) regions.add(country);
    }

    return GrowthMetrics(
      newUsersToday: newUsersToday.count ?? 0,
      totalUsers: totalUsers.count ?? 0,
      invitesSent: recentInvites.count ?? 0,
      activeRegions: regions.length,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search users by name, email, or username
  Future<List<UserProfile>> searchUsers(String query) async {
    final lowerQuery = query.toLowerCase();

    final snapshot = await _firestore
        .collection('users')
        .orderBy('displayName')
        .limit(50)
        .get();

    final results = <UserProfile>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['displayName'] as String? ?? '').toLowerCase();
      final email = (data['email'] as String? ?? '').toLowerCase();
      final username = (data['username'] as String? ?? '').toLowerCase();

      if (name.contains(lowerQuery) ||
          email.contains(lowerQuery) ||
          username.contains(lowerQuery)) {
        results.add(UserProfile.fromFirestore(doc.id, data));
      }
    }

    return results;
  }

  /// Get user details with moderation history
  Future<UserDetails> getUserDetails(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw Exception('User not found');
    }

    // Get moderation history
    final moderationSnapshot = await _firestore
        .collection('moderation_actions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final moderationHistory = moderationSnapshot.docs
        .map((doc) => ModerationAction.fromFirestore(doc.data()))
        .toList();

    // Get reports against this user
    final reportsSnapshot = await _firestore
        .collection('content_reports')
        .where('reportedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final reports = reportsSnapshot.docs
        .map((doc) => ContentReport.fromFirestore(doc.id, doc.data()))
        .toList();

    return UserDetails(
      profile: UserProfile.fromFirestore(userId, userDoc.data()!),
      moderationHistory: moderationHistory,
      reports: reports,
    );
  }

  /// Warn user
  Future<void> warnUser({
    required String userId,
    required String adminId,
    required String reason,
  }) async {
    await _firestore.collection('moderation_actions').add({
      'userId': userId,
      'adminId': adminId,
      'action': 'warn',
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Send notification to user
    await _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .add({
          'type': 'system_warning',
          'title': '⚠️ Community Guidelines Warning',
          'body': 'The Ninja has issued a warning: $reason',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// Mute user (temporary)
  Future<void> muteUser({
    required String userId,
    required String adminId,
    required String reason,
    required Duration duration,
  }) async {
    final muteUntil = DateTime.now().add(duration);

    await _firestore.collection('users').doc(userId).update({
      'mutedUntil': muteUntil,
      'mutedReason': reason,
    });

    await _firestore.collection('moderation_actions').add({
      'userId': userId,
      'adminId': adminId,
      'action': 'mute',
      'reason': reason,
      'duration': duration.inHours,
      'muteUntil': muteUntil,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Suspend user account
  Future<void> suspendUser({
    required String userId,
    required String adminId,
    required String reason,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'suspended',
      'suspendedReason': reason,
      'suspendedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('moderation_actions').add({
      'userId': userId,
      'adminId': adminId,
      'action': 'suspend',
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Ban user permanently
  Future<void> banUser({
    required String userId,
    required String adminId,
    required String reason,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'banned',
      'bannedReason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('moderation_actions').add({
      'userId': userId,
      'adminId': adminId,
      'action': 'ban',
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Restore user account
  Future<void> restoreUser({
    required String userId,
    required String adminId,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'status': 'active',
      'mutedUntil': null,
      'suspendedReason': null,
      'bannedReason': null,
    });

    await _firestore.collection('moderation_actions').add({
      'userId': userId,
      'adminId': adminId,
      'action': 'restore',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTENT MODERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get pending content reports
  Stream<List<ContentReport>> streamPendingReports() {
    return _firestore
        .collection('content_reports')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ContentReport.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Approve content (dismiss report)
  Future<void> approveContent({
    required String reportId,
    required String adminId,
  }) async {
    await _firestore.collection('content_reports').doc(reportId).update({
      'status': 'approved',
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove content
  Future<void> removeContent({
    required String reportId,
    required String contentId,
    required String contentType,
    required String adminId,
    required String reason,
  }) async {
    // Mark report as actioned
    await _firestore.collection('content_reports').doc(reportId).update({
      'status': 'removed',
      'reviewedBy': adminId,
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    // Remove content based on type
    if (contentType == 'post') {
      await _firestore.collection('posts').doc(contentId).update({
        'status': 'removed',
        'removedReason': reason,
        'removedAt': FieldValue.serverTimestamp(),
      });
    } else if (contentType == 'comment') {
      await _firestore.collection('comments').doc(contentId).update({
        'status': 'removed',
        'removedReason': reason,
        'removedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMPAIGN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all campaigns
  Stream<List<CampaignSummary>> streamCampaigns() {
    return _firestore
        .collection('campaigns')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CampaignSummary.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Create campaign
  Future<String> createCampaign({
    required String name,
    required String description,
    required String type,
    required double goalAmount,
    required String adminId,
  }) async {
    final doc = await _firestore.collection('campaigns').add({
      'name': name,
      'description': description,
      'type': type,
      'goalAmount': goalAmount,
      'raisedAmount': 0.0,
      'supporters': [],
      'status': 'active',
      'createdBy': adminId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Feature campaign (pin to top of feed)
  Future<void> featureCampaign(String campaignId, bool featured) async {
    await _firestore.collection('campaigns').doc(campaignId).update({
      'featured': featured,
      'featuredAt': featured ? FieldValue.serverTimestamp() : null,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEM CONTROL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send broadcast notification to all users
  Future<void> sendBroadcast({
    required String title,
    required String message,
    required String adminId,
  }) async {
    // Log broadcast
    await _firestore.collection('system_broadcasts').add({
      'title': title,
      'message': message,
      'sentBy': adminId,
      'sentAt': FieldValue.serverTimestamp(),
    });

    // Cloud Function would handle actual sending to all users
    if (kDebugMode) {
      debugPrint('📢 Broadcast sent: $title');
    }
  }

  /// Set feature toggle
  Future<void> setFeatureToggle(String feature, bool enabled) async {
    await _firestore.collection('system_config').doc('features').set({
      feature: enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get system health
  Future<SystemHealth> getSystemHealth() async {
    // Check Firestore connectivity
    bool firestoreHealthy = true;
    try {
      await _firestore.collection('system_health').doc('ping').get();
    } catch (e) {
      firestoreHealthy = false;
    }

    // Get error rate (last hour)
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final errors = await _firestore
        .collection('system_errors')
        .where('createdAt', isGreaterThan: hourAgo)
        .count()
        .get();

    return SystemHealth(
      firestoreHealthy: firestoreHealthy,
      errorsLastHour: errors.count ?? 0,
      timestamp: DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class SystemStatus {
  final int usersOnline;
  final int postsToday;
  final int messagesToday;
  final double donationsToday;
  final int pendingReports;

  SystemStatus({
    required this.usersOnline,
    required this.postsToday,
    required this.messagesToday,
    required this.donationsToday,
    required this.pendingReports,
  });
}

class GrowthMetrics {
  final int newUsersToday;
  final int totalUsers;
  final int invitesSent;
  final int activeRegions;

  GrowthMetrics({
    required this.newUsersToday,
    required this.totalUsers,
    required this.invitesSent,
    required this.activeRegions,
  });
}

class UserProfile {
  final String id;
  final String displayName;
  final String? email;
  final String role;
  final String status;

  UserProfile({
    required this.id,
    required this.displayName,
    this.email,
    required this.role,
    required this.status,
  });

  factory UserProfile.fromFirestore(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['displayName'] ?? 'Unknown',
      email: data['email'],
      role: data['role'] ?? 'fan',
      status: data['status'] ?? 'active',
    );
  }
}

class UserDetails {
  final UserProfile profile;
  final List<ModerationAction> moderationHistory;
  final List<ContentReport> reports;

  UserDetails({
    required this.profile,
    required this.moderationHistory,
    required this.reports,
  });
}

class ModerationAction {
  final String action;
  final String reason;
  final DateTime createdAt;

  ModerationAction({
    required this.action,
    required this.reason,
    required this.createdAt,
  });

  factory ModerationAction.fromFirestore(Map<String, dynamic> data) {
    return ModerationAction(
      action: data['action'] ?? '',
      reason: data['reason'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

class ContentReport {
  final String id;
  final String contentId;
  final String contentType;
  final String reason;
  final String reportedBy;
  final String status;

  ContentReport({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.reason,
    required this.reportedBy,
    required this.status,
  });

  factory ContentReport.fromFirestore(String id, Map<String, dynamic> data) {
    return ContentReport(
      id: id,
      contentId: data['contentId'] ?? '',
      contentType: data['contentType'] ?? '',
      reason: data['reason'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      status: data['status'] ?? 'pending',
    );
  }
}

class CampaignSummary {
  final String id;
  final String name;
  final String type;
  final double goalAmount;
  final double raisedAmount;
  final String status;

  CampaignSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.goalAmount,
    required this.raisedAmount,
    required this.status,
  });

  factory CampaignSummary.fromFirestore(String id, Map<String, dynamic> data) {
    return CampaignSummary(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      goalAmount: (data['goalAmount'] as num?)?.toDouble() ?? 0.0,
      raisedAmount: (data['raisedAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'active',
    );
  }

  double get progressPercent =>
      goalAmount > 0 ? (raisedAmount / goalAmount * 100).clamp(0, 100) : 0;
}

class SystemHealth {
  final bool firestoreHealthy;
  final int errorsLastHour;
  final DateTime timestamp;

  SystemHealth({
    required this.firestoreHealthy,
    required this.errorsLastHour,
    required this.timestamp,
  });

  bool get isHealthy => firestoreHealthy && errorsLastHour < 100;
}
