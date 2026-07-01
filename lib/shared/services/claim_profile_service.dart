// ═══════════════════════════════════════════════════════════════════════════
// DFC CLAIM YOUR PROFILE SYSTEM
// ═══════════════════════════════════════════════════════════════════════════
// Pre-seeded fighter profiles + verification claim flow
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Claim status
enum ClaimStatus { pending, underReview, approved, rejected, expired }

/// Verification method
enum VerificationMethod {
  socialMedia, // Link to verified social accounts
  photoId, // Government ID upload
  coachReferral, // Coach/gym vouches
  fightRecord, // Link to official fight record
  videoMessage, // Video verification
}

/// Fighter profile (pre-seeded)
class UnclaimedProfile {
  final String id;
  final String name;
  final String? nickname;
  final String? photoUrl;
  final int wins;
  final int losses;
  final int draws;
  final String? weightClass;
  final String? country;
  final String? team;
  final String? recordSource; // 'sherdog', 'tapology', 'manual'
  final DateTime? lastFightDate;
  final bool isClaimed;
  final String? claimedBy;

  const UnclaimedProfile({
    required this.id,
    required this.name,
    this.nickname,
    this.photoUrl,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.weightClass,
    this.country,
    this.team,
    this.recordSource,
    this.lastFightDate,
    this.isClaimed = false,
    this.claimedBy,
  });

  String get record => '$wins-$losses${draws > 0 ? '-$draws' : ''}';

  factory UnclaimedProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnclaimedProfile(
      id: doc.id,
      name: data['name'] as String? ?? '',
      nickname: data['nickname'] as String?,
      photoUrl: data['photoUrl'] as String?,
      wins: data['wins'] as int? ?? 0,
      losses: data['losses'] as int? ?? 0,
      draws: data['draws'] as int? ?? 0,
      weightClass: data['weightClass'] as String?,
      country: data['country'] as String?,
      team: data['team'] as String?,
      recordSource: data['recordSource'] as String?,
      lastFightDate: (data['lastFightDate'] as Timestamp?)?.toDate(),
      isClaimed: data['isClaimed'] as bool? ?? false,
      claimedBy: data['claimedBy'] as String?,
    );
  }
}

/// Profile claim request
class ProfileClaim {
  final String id;
  final String profileId;
  final String userId;
  final String userName;
  final ClaimStatus status;
  final List<VerificationMethod> verificationMethods;
  final Map<String, String>? verificationData;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const ProfileClaim({
    required this.id,
    required this.profileId,
    required this.userId,
    required this.userName,
    required this.status,
    required this.verificationMethods,
    this.verificationData,
    this.rejectionReason,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  factory ProfileClaim.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileClaim(
      id: doc.id,
      profileId: data['profileId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String? ?? '',
      status: ClaimStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ClaimStatus.pending,
      ),
      verificationMethods:
          (data['verificationMethods'] as List<dynamic>?)
              ?.map(
                (m) => VerificationMethod.values.firstWhere(
                  (v) => v.name == m,
                  orElse: () => VerificationMethod.socialMedia,
                ),
              )
              .toList() ??
          [],
      verificationData: (data['verificationData'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// CLAIM PROFILE SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
class ClaimProfileService {
  static final ClaimProfileService _instance = ClaimProfileService._internal();
  factory ClaimProfileService() => _instance;
  ClaimProfileService._internal();

  final _db = FirebaseFirestore.instance;

  /// Search for unclaimed profiles
  Future<List<UnclaimedProfile>> searchProfiles({
    required String query,
    String? weightClass,
    String? country,
    int limit = 20,
  }) async {
    try {
      final Query q = _db
          .collection('fighter_profiles')
          .where('isClaimed', isEqualTo: false)
          .limit(limit);

      // Note: For production, use Algolia or similar for full-text search
      // This is a basic implementation

      final results = await q.get();

      return results.docs
          .map(UnclaimedProfile.fromFirestore)
          .where(
            (p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                (p.nickname?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    } catch (e) {
      debugPrint('[ClaimProfile] Search error: $e');
      return [];
    }
  }

  /// Get profile by ID
  Future<UnclaimedProfile?> getProfile(String profileId) async {
    try {
      final doc = await _db.collection('fighter_profiles').doc(profileId).get();
      if (!doc.exists) return null;
      return UnclaimedProfile.fromFirestore(doc);
    } catch (e) {
      debugPrint('[ClaimProfile] Get profile error: $e');
      return null;
    }
  }

  /// Check if user has pending claim
  Future<ProfileClaim?> getPendingClaim(String userId) async {
    try {
      final query = await _db
          .collection('profile_claims')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: ClaimStatus.pending.name)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return ProfileClaim.fromFirestore(query.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Submit profile claim
  Future<String?> submitClaim({
    required String profileId,
    required String userId,
    required String userName,
    required List<VerificationMethod> methods,
    required Map<String, String> verificationData,
  }) async {
    try {
      // Check if profile is already claimed
      final profile = await getProfile(profileId);
      if (profile == null || profile.isClaimed) {
        return null;
      }

      // Check for existing pending claim
      final existingClaim = await getPendingClaim(userId);
      if (existingClaim != null) {
        return null;
      }

      // Create claim
      final claimRef = await _db.collection('profile_claims').add({
        'profileId': profileId,
        'userId': userId,
        'userName': userName,
        'status': ClaimStatus.pending.name,
        'verificationMethods': methods.map((m) => m.name).toList(),
        'verificationData': verificationData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Mark profile as having pending claim
      await _db.collection('fighter_profiles').doc(profileId).update({
        'pendingClaimId': claimRef.id,
        'pendingClaimBy': userId,
      });

      // Create notification for admins
      await _db.collection('admin_notifications').add({
        'type': 'profile_claim',
        'claimId': claimRef.id,
        'profileId': profileId,
        'userId': userId,
        'profileName': profile.name,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return claimRef.id;
    } catch (e) {
      debugPrint('[ClaimProfile] Submit error: $e');
      return null;
    }
  }

  /// Approve claim (admin only)
  Future<bool> approveClaim({
    required String claimId,
    required String adminId,
  }) async {
    try {
      final claimDoc = await _db
          .collection('profile_claims')
          .doc(claimId)
          .get();
      if (!claimDoc.exists) return false;

      final claim = ProfileClaim.fromFirestore(claimDoc);

      // Update claim
      await _db.collection('profile_claims').doc(claimId).update({
        'status': ClaimStatus.approved.name,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
      });

      // Update fighter profile
      await _db.collection('fighter_profiles').doc(claim.profileId).update({
        'isClaimed': true,
        'claimedBy': claim.userId,
        'claimedAt': FieldValue.serverTimestamp(),
        'pendingClaimId': FieldValue.delete(),
        'pendingClaimBy': FieldValue.delete(),
      });

      // Update user
      await _db.collection('users').doc(claim.userId).update({
        'isVerifiedFighter': true,
        'fighterProfileId': claim.profileId,
        'verifiedAt': FieldValue.serverTimestamp(),
        'badges': FieldValue.arrayUnion(['verified_fighter']),
      });

      // Send notification to user
      await _db.collection('notifications').add({
        'userId': claim.userId,
        'type': 'claim_approved',
        'title': '✅ Profile Verified!',
        'body':
            'Your fighter profile has been verified. You now have the verified badge!',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('[ClaimProfile] Approve error: $e');
      return false;
    }
  }

  /// Reject claim (admin only)
  Future<bool> rejectClaim({
    required String claimId,
    required String adminId,
    required String reason,
  }) async {
    try {
      final claimDoc = await _db
          .collection('profile_claims')
          .doc(claimId)
          .get();
      if (!claimDoc.exists) return false;

      final claim = ProfileClaim.fromFirestore(claimDoc);

      // Update claim
      await _db.collection('profile_claims').doc(claimId).update({
        'status': ClaimStatus.rejected.name,
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': adminId,
      });

      // Remove pending claim from profile
      await _db.collection('fighter_profiles').doc(claim.profileId).update({
        'pendingClaimId': FieldValue.delete(),
        'pendingClaimBy': FieldValue.delete(),
      });

      // Send notification to user
      await _db.collection('notifications').add({
        'userId': claim.userId,
        'type': 'claim_rejected',
        'title': '❌ Verification Not Approved',
        'body': 'Your profile claim was not approved. Reason: $reason',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('[ClaimProfile] Reject error: $e');
      return false;
    }
  }

  /// Get claim status
  Future<ProfileClaim?> getClaimStatus(String claimId) async {
    try {
      final doc = await _db.collection('profile_claims').doc(claimId).get();
      if (!doc.exists) return null;
      return ProfileClaim.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  /// Get user's claims history
  Future<List<ProfileClaim>> getUserClaims(String userId) async {
    final query = await _db
        .collection('profile_claims')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return query.docs.map(ProfileClaim.fromFirestore).toList();
  }

  /// Get pending claims (admin)
  Future<List<ProfileClaim>> getPendingClaims({int limit = 50}) async {
    final query = await _db
        .collection('profile_claims')
        .where('status', isEqualTo: ClaimStatus.pending.name)
        .orderBy('createdAt')
        .limit(limit)
        .get();

    return query.docs.map(ProfileClaim.fromFirestore).toList();
  }

  /// Check if user is verified fighter
  Future<bool> isVerifiedFighter(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data()?['isVerifiedFighter'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get verification methods description
  static String getMethodDescription(VerificationMethod method) {
    switch (method) {
      case VerificationMethod.socialMedia:
        return 'Link your verified social media accounts (Instagram, Twitter, etc.)';
      case VerificationMethod.photoId:
        return 'Upload a government-issued photo ID';
      case VerificationMethod.coachReferral:
        return 'Have your coach or gym verify your identity';
      case VerificationMethod.fightRecord:
        return 'Link to your official fight record (Sherdog, Tapology, BoxRec)';
      case VerificationMethod.videoMessage:
        return 'Record a short video message confirming your identity';
    }
  }

  /// Get verification method icon
  static String getMethodIcon(VerificationMethod method) {
    switch (method) {
      case VerificationMethod.socialMedia:
        return '📱';
      case VerificationMethod.photoId:
        return '🪪';
      case VerificationMethod.coachReferral:
        return '🥋';
      case VerificationMethod.fightRecord:
        return '📊';
      case VerificationMethod.videoMessage:
        return '🎥';
    }
  }
}
