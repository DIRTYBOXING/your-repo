import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Badge progression tracking and management
class CreatorBadgeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Badge tiers and their unlock requirements
  static const Map<String, int> badgeRequirements = {
    'bronze': 10, // 10 clips
    'silver': 100, // 100 clips
    'gold': 500, // 500 clips
    'platinum': 1000, // 1000 clips
    'diamond': 5000, // 5000 clips
  };

  /// Get unlocked badges for a creator
  Future<List<String>> getUnlockedBadges(String creatorId) async {
    try {
      final doc = await _firestore
          .collection('creator_dashboards')
          .doc(creatorId)
          .collection('badges')
          .doc('unlocked')
          .get();

      if (!doc.exists) return [];

      return List<String>.from(doc.data()?['badges'] ?? []);
    } catch (e) {
      debugPrint('❌ Error getting unlocked badges: $e');
      return [];
    }
  }

  /// Get badge progress for a creator
  Future<Map<String, dynamic>> getBadgeProgress(
    String creatorId,
    int totalClipsCreated,
  ) async {
    try {
      final unlockedBadges = await getUnlockedBadges(creatorId);

      final progress = <String, dynamic>{};

      badgeRequirements.forEach((badge, requirement) {
        final isUnlocked = unlockedBadges.contains(badge);
        final progressPercent = isUnlocked
            ? 100.0
            : (totalClipsCreated / requirement) * 100.0;

        progress[badge] = {
          'isUnlocked': isUnlocked,
          'required': requirement,
          'current': totalClipsCreated,
          'progressPercent': progressPercent.clamp(0.0, 100.0),
          'remaining': (requirement - totalClipsCreated).clamp(0, requirement),
          'displayName': _getBadgeDisplayName(badge),
          'emoji': _getBadgeEmoji(badge),
        };
      });

      return progress;
    } catch (e) {
      debugPrint('❌ Error getting badge progress: $e');
      return {};
    }
  }

  /// Check and update badges based on clips count
  Future<List<String>> checkAndUpdateBadges(
    String creatorId,
    int totalClipsCreated,
  ) async {
    try {
      final unlockedBadges = await getUnlockedBadges(creatorId);
      final newlyUnlocked = <String>[];

      badgeRequirements.forEach((badge, requirement) {
        if (!unlockedBadges.contains(badge) &&
            totalClipsCreated >= requirement) {
          newlyUnlocked.add(badge);
        }
      });

      if (newlyUnlocked.isNotEmpty) {
        // Save newly unlocked badges
        final updated = [...unlockedBadges, ...newlyUnlocked];
        await _firestore
            .collection('creator_dashboards')
            .doc(creatorId)
            .collection('badges')
            .doc('unlocked')
            .set({
              'badges': updated,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        debugPrint('🏆 New badges unlocked for $creatorId: $newlyUnlocked');
      }

      return newlyUnlocked;
    } catch (e) {
      debugPrint('❌ Error checking/updating badges: $e');
      return [];
    }
  }

  /// Get next badge to unlock
  Future<Map<String, dynamic>?> getNextBadge(
    String creatorId,
    int totalClipsCreated,
  ) async {
    try {
      final unlockedBadges = await getUnlockedBadges(creatorId);

      String? nextBadge;
      int? nextRequirement;

      for (final entry in badgeRequirements.entries) {
        if (!unlockedBadges.contains(entry.key)) {
          nextBadge = entry.key;
          nextRequirement = entry.value;
          break;
        }
      }

      if (nextBadge == null) {
        return null; // All badges unlocked
      }

      final remaining = (nextRequirement! - totalClipsCreated).clamp(
        0,
        nextRequirement,
      );

      return {
        'badge': nextBadge,
        'displayName': _getBadgeDisplayName(nextBadge),
        'emoji': _getBadgeEmoji(nextBadge),
        'required': nextRequirement,
        'current': totalClipsCreated,
        'remaining': remaining,
        'progressPercent': (totalClipsCreated / nextRequirement) * 100.0,
      };
    } catch (e) {
      debugPrint('❌ Error getting next badge: $e');
      return null;
    }
  }

  /// Get badge display name
  String _getBadgeDisplayName(String badge) {
    return switch (badge) {
      'bronze' => 'Bronze Creator',
      'silver' => 'Silver Creator',
      'gold' => 'Gold Creator',
      'platinum' => 'Platinum Creator',
      'diamond' => 'Diamond Creator',
      _ => badge,
    };
  }

  /// Get badge emoji
  String _getBadgeEmoji(String badge) {
    return switch (badge) {
      'bronze' => '🥉',
      'silver' => '🥈',
      'gold' => '🥇',
      'platinum' => '💎',
      'diamond' => '💠',
      _ => '⭐',
    };
  }

  /// Get total badge count achievement (special badge for collecting badges)
  Future<int> getTotalBadgeCount(String creatorId) async {
    try {
      final badges = await getUnlockedBadges(creatorId);
      return badges.length;
    } catch (e) {
      return 0;
    }
  }
}
