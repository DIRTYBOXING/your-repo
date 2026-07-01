import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/judge_score_models.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// JUDGE SCORE SERVICE — "You're The Judge" Backend
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles all round scoring, XP calculation, badge unlocks, and leaderboards.
/// Integrates with PPV live streams for real-time judging competition.
///
/// Key Methods:
///   • submitRoundScore() — Submit user's round prediction
///   • gradeScore() — Compare to official judges, award XP
///   • updateProfile() — Refresh user's judge stats
///   • getLeaderboard() — Fetch global/event rankings
///   • streamUserProfile() — Real-time profile updates
///
/// XP Awards:
///   Base: 10 XP per correct round
///   Perfect: +25 XP for exact judge match
///   Speed: +5 XP if first to score (within 30s)
///   Streak: +2 XP per round in current streak
///   Event Perfect: +100 XP bonus for perfect card
/// ═══════════════════════════════════════════════════════════════════════════
class JudgeScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit user's round score prediction
  Future<RoundScore> submitRoundScore({
    required String eventId,
    required String fightId,
    required int roundNumber,
    required int redCornerScore,
    required int blueCornerScore,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User must be authenticated to submit scores');
    }

    // Validate scores (10-7 range for MMA/boxing)
    if (redCornerScore < 7 || redCornerScore > 10) {
      throw Exception('Red corner score must be between 7-10');
    }
    if (blueCornerScore < 7 || blueCornerScore > 10) {
      throw Exception('Blue corner score must be between 7-10');
    }

    final now = DateTime.now();

    // Check if user already scored this round
    final existingDoc = await _firestore
        .collection('user_judge_scores')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('fights')
        .doc(fightId)
        .collection('rounds')
        .doc(roundNumber.toString())
        .get();

    if (existingDoc.exists) {
      throw Exception('You already scored this round');
    }

    // Check if we're the first to score (within 30s of round end)
    final allScoresQuery = await _firestore
        .collectionGroup('rounds')
        .where('eventId', isEqualTo: eventId)
        .where('fightId', isEqualTo: fightId)
        .where('roundNumber', isEqualTo: roundNumber)
        .get();

    final firstToScore = allScoresQuery.docs.isEmpty;

    final roundScore = RoundScore(
      userId: userId,
      eventId: eventId,
      fightId: fightId,
      roundNumber: roundNumber,
      redCornerScore: redCornerScore,
      blueCornerScore: blueCornerScore,
      submittedAt: now,
      firstToScore: firstToScore,
    );

    // Save to Firestore
    await _firestore
        .collection('user_judge_scores')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('fights')
        .doc(fightId)
        .collection('rounds')
        .doc(roundNumber.toString())
        .set(roundScore.toFirestore());

    return roundScore;
  }

  /// Grade a user's score against official judges and award XP
  Future<RoundScore> gradeScore({
    required String userId,
    required String eventId,
    required String fightId,
    required int roundNumber,
    required int officialRedScore,
    required int officialBlueScore,
  }) async {
    final docRef = _firestore
        .collection('user_judge_scores')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('fights')
        .doc(fightId)
        .collection('rounds')
        .doc(roundNumber.toString());

    final doc = await docRef.get();
    if (!doc.exists) {
      throw Exception('No score found for this round');
    }

    final score = RoundScore.fromFirestore(doc.data()!);

    // Determine accuracy
    final accuracy = _calculateAccuracy(
      score.redCornerScore,
      score.blueCornerScore,
      officialRedScore,
      officialBlueScore,
    );

    // Calculate XP
    int xpEarned = 0;
    switch (accuracy) {
      case JudgeAccuracyLevel.perfect:
        xpEarned = 25;
        break;
      case JudgeAccuracyLevel.correct:
        xpEarned = 10;
        break;
      case JudgeAccuracyLevel.close:
        xpEarned = 5;
        break;
      case JudgeAccuracyLevel.wrong:
        xpEarned = 0;
        break;
    }

    // Speed bonus
    if (score.firstToScore) {
      xpEarned += 5;
    }

    // Update score with official results
    await docRef.update({
      'officialRedScore': officialRedScore,
      'officialBlueScore': officialBlueScore,
      'accuracy': accuracy.name,
      'xpEarned': xpEarned,
    });

    // Update user's judge profile
    await _updateJudgeProfile(
      userId: userId,
      eventId: eventId,
      xpEarned: xpEarned,
      wasCorrect:
          accuracy == JudgeAccuracyLevel.perfect ||
          accuracy == JudgeAccuracyLevel.correct,
      wasPerfect: accuracy == JudgeAccuracyLevel.perfect,
    );

    return RoundScore(
      userId: score.userId,
      eventId: score.eventId,
      fightId: score.fightId,
      roundNumber: score.roundNumber,
      redCornerScore: score.redCornerScore,
      blueCornerScore: score.blueCornerScore,
      submittedAt: score.submittedAt,
      officialRedScore: officialRedScore,
      officialBlueScore: officialBlueScore,
      accuracy: accuracy,
      xpEarned: xpEarned,
      firstToScore: score.firstToScore,
    );
  }

  JudgeAccuracyLevel _calculateAccuracy(
    int userRed,
    int userBlue,
    int officialRed,
    int officialBlue,
  ) {
    // Perfect match
    if (userRed == officialRed && userBlue == officialBlue) {
      return JudgeAccuracyLevel.perfect;
    }

    // Same winner
    final userWinner = userRed > userBlue
        ? 'red'
        : userBlue > userRed
        ? 'blue'
        : 'draw';
    final officialWinner = officialRed > officialBlue
        ? 'red'
        : officialBlue > officialRed
        ? 'blue'
        : 'draw';

    if (userWinner != officialWinner) {
      return JudgeAccuracyLevel.wrong;
    }

    // Same winner, check score proximity
    final redDiff = (userRed - officialRed).abs();
    final blueDiff = (userBlue - officialBlue).abs();

    if (redDiff <= 1 && blueDiff <= 1) {
      return JudgeAccuracyLevel.correct;
    }

    return JudgeAccuracyLevel.close;
  }

  Future<void> _updateJudgeProfile({
    required String userId,
    required String eventId,
    required int xpEarned,
    required bool wasCorrect,
    required bool wasPerfect,
  }) async {
    final profileRef = _firestore.collection('judge_profiles').doc(userId);

    await _firestore.runTransaction((transaction) async {
      final profileDoc = await transaction.get(profileRef);

      JudgeProfile profile;
      if (profileDoc.exists) {
        profile = JudgeProfile.fromFirestore(profileDoc.data()!);
      } else {
        profile = JudgeProfile(userId: userId);
      }

      // Update stats
      final newTotalXP = profile.totalXP + xpEarned;
      final newTotalRounds = profile.totalRounds + 1;
      final newCorrectRounds = profile.correctRounds + (wasCorrect ? 1 : 0);
      final newPerfectMatches = profile.perfectMatches + (wasPerfect ? 1 : 0);
      final newCurrentStreak = wasCorrect ? profile.currentStreak + 1 : 0;
      final newLongestStreak = newCurrentStreak > profile.longestStreak
          ? newCurrentStreak
          : profile.longestStreak;

      // Update event-specific XP
      final newEventScores = Map<String, int>.from(profile.eventScores);
      newEventScores[eventId] = (newEventScores[eventId] ?? 0) + xpEarned;

      final updatedProfile = profile.copyWith(
        totalXP: newTotalXP,
        totalRounds: newTotalRounds,
        correctRounds: newCorrectRounds,
        perfectMatches: newPerfectMatches,
        currentStreak: newCurrentStreak,
        longestStreak: newLongestStreak,
        rank: profile.copyWith(totalXP: newTotalXP).calculateRank(),
        badges: profile
            .copyWith(
              correctRounds: newCorrectRounds,
              perfectMatches: newPerfectMatches,
              currentStreak: newCurrentStreak,
            )
            .calculateEarnedBadges(),
        lastScoreAt: DateTime.now(),
        eventScores: newEventScores,
      );

      transaction.set(profileRef, updatedProfile.toFirestore());
    });
  }

  /// Get user's judge profile
  Future<JudgeProfile> getUserProfile(String userId) async {
    final doc = await _firestore.collection('judge_profiles').doc(userId).get();

    if (!doc.exists) {
      return JudgeProfile(userId: userId);
    }

    return JudgeProfile.fromFirestore(doc.data()!);
  }

  /// Stream user's judge profile for real-time updates
  Stream<JudgeProfile> streamUserProfile(String userId) {
    return _firestore.collection('judge_profiles').doc(userId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return JudgeProfile(userId: userId);
      }
      return JudgeProfile.fromFirestore(doc.data()!);
    });
  }

  /// Get global leaderboard
  Future<List<JudgeLeaderboardEntry>> getGlobalLeaderboard({
    int limit = 50,
  }) async {
    final querySnapshot = await _firestore
        .collection('judge_profiles')
        .orderBy('totalXP', descending: true)
        .limit(limit)
        .get();

    final entries = <JudgeLeaderboardEntry>[];
    int position = 1;

    for (final doc in querySnapshot.docs) {
      final profile = JudgeProfile.fromFirestore(doc.data());

      // Fetch user display name
      final userDoc = await _firestore
          .collection('users')
          .doc(profile.userId)
          .get();
      final displayName = userDoc.data()?['displayName'] ?? 'Anonymous';
      final photoUrl = userDoc.data()?['photoUrl'];

      entries.add(
        JudgeLeaderboardEntry(
          userId: profile.userId,
          displayName: displayName,
          photoUrl: photoUrl,
          totalXP: profile.totalXP,
          accuracy: profile.accuracy,
          correctRounds: profile.correctRounds,
          rank: profile.rank,
          topBadges: profile.badges.take(3).toList(),
          position: position++,
        ),
      );
    }

    return entries;
  }

  /// Get event-specific leaderboard
  Future<List<JudgeLeaderboardEntry>> getEventLeaderboard({
    required String eventId,
    int limit = 50,
  }) async {
    final querySnapshot = await _firestore
        .collection('judge_profiles')
        .where('eventScores.$eventId', isGreaterThan: 0)
        .orderBy('eventScores.$eventId', descending: true)
        .limit(limit)
        .get();

    final entries = <JudgeLeaderboardEntry>[];
    int position = 1;

    for (final doc in querySnapshot.docs) {
      final profile = JudgeProfile.fromFirestore(doc.data());
      final eventXP = profile.eventScores[eventId] ?? 0;

      // Fetch user display name
      final userDoc = await _firestore
          .collection('users')
          .doc(profile.userId)
          .get();
      final displayName = userDoc.data()?['displayName'] ?? 'Anonymous';
      final photoUrl = userDoc.data()?['photoUrl'];

      entries.add(
        JudgeLeaderboardEntry(
          userId: profile.userId,
          displayName: displayName,
          photoUrl: photoUrl,
          totalXP: eventXP,
          accuracy: profile.accuracy,
          correctRounds: profile.correctRounds,
          rank: profile.rank,
          topBadges: profile.badges.take(3).toList(),
          position: position++,
        ),
      );
    }

    return entries;
  }

  /// Get user's scores for a specific fight
  Future<List<RoundScore>> getFightScores({
    required String userId,
    required String eventId,
    required String fightId,
  }) async {
    final querySnapshot = await _firestore
        .collection('user_judge_scores')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('fights')
        .doc(fightId)
        .collection('rounds')
        .orderBy('roundNumber')
        .get();

    return querySnapshot.docs
        .map((doc) => RoundScore.fromFirestore(doc.data()))
        .toList();
  }

  /// Check if user has already scored a round
  Future<bool> hasUserScoredRound({
    required String eventId,
    required String fightId,
    required int roundNumber,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final doc = await _firestore
        .collection('user_judge_scores')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('fights')
        .doc(fightId)
        .collection('rounds')
        .doc(roundNumber.toString())
        .get();

    return doc.exists;
  }
}
