import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AI PREDICTIVE BETTING ENGINE — ML-Powered Fight Predictions
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

enum PredictionType { winner, method, round, totalRounds, parlayCombo }

enum FightMethod { koTko, submission, decision, draw }

class FightPrediction {
  final String id;
  final String fightId;
  final String fighter1Id;
  final String fighter2Id;
  final double fighter1WinProb;
  final double fighter2WinProb;
  final Map<String, double> methodProbs;
  final Map<int, double> roundProbs;
  final String aiReasoning;
  final double confidence;
  final DateTime generatedAt;

  const FightPrediction({
    required this.id,
    required this.fightId,
    required this.fighter1Id,
    required this.fighter2Id,
    required this.fighter1WinProb,
    required this.fighter2WinProb,
    this.methodProbs = const {},
    this.roundProbs = const {},
    required this.aiReasoning,
    required this.confidence,
    required this.generatedAt,
  });

  factory FightPrediction.fromMap(Map<String, dynamic> map) => FightPrediction(
    id: map['id'] ?? '',
    fightId: map['fightId'] ?? '',
    fighter1Id: map['fighter1Id'] ?? '',
    fighter2Id: map['fighter2Id'] ?? '',
    fighter1WinProb: (map['fighter1WinProb'] ?? 0.5).toDouble(),
    fighter2WinProb: (map['fighter2WinProb'] ?? 0.5).toDouble(),
    methodProbs: Map<String, double>.from(map['methodProbs'] ?? {}),
    roundProbs:
        (map['roundProbs'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
        ) ??
        {},
    aiReasoning: map['aiReasoning'] ?? '',
    confidence: (map['confidence'] ?? 0.7).toDouble(),
    generatedAt: (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class UserPick {
  final String id;
  final String userId;
  final String fightId;
  final String pickFighterId;
  final FightMethod? pickMethod;
  final int? pickRound;
  final double confidence;
  final bool isCorrect;
  final int pointsEarned;
  final DateTime createdAt;

  const UserPick({
    required this.id,
    required this.userId,
    required this.fightId,
    required this.pickFighterId,
    this.pickMethod,
    this.pickRound,
    this.confidence = 0.5,
    this.isCorrect = false,
    this.pointsEarned = 0,
    required this.createdAt,
  });
}

class AIPredictiveBettingEngine with ChangeNotifier {
  static final AIPredictiveBettingEngine _instance =
      AIPredictiveBettingEngine._internal();
  factory AIPredictiveBettingEngine() => _instance;
  AIPredictiveBettingEngine._internal();

  bool _initialized = false;
  final Map<String, FightPrediction> _predictions = {};
  // ignore: unused_field
  final List<UserPick> _userPicks = [];

  bool get initialized => _initialized;
  Map<String, FightPrediction> get predictions =>
      Map.unmodifiable(_predictions);

  Future<void> initialize() async {
    if (_initialized) return;
    debugPrint('🎰 AIPredictiveBettingEngine: Initializing...');
    _initialized = true;
    notifyListeners();
  }

  Future<FightPrediction?> generatePrediction({
    required String fightId,
    required String fighter1Id,
    required String fighter1Name,
    required String fighter2Id,
    required String fighter2Name,
    String? weightClass,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateFightPrediction');
      final result = await callable.call<Map<String, dynamic>>({
        'fightId': fightId,
        'fighter1Id': fighter1Id,
        'fighter1Name': fighter1Name,
        'fighter2Id': fighter2Id,
        'fighter2Name': fighter2Name,
        'weightClass': weightClass,
      });

      if (result.data['prediction'] != null) {
        final pred = FightPrediction.fromMap({
          ...result.data['prediction'] as Map<String, dynamic>,
          'id': 'pred_${DateTime.now().millisecondsSinceEpoch}',
          'fightId': fightId,
          'fighter1Id': fighter1Id,
          'fighter2Id': fighter2Id,
        });
        _predictions[fightId] = pred;
        notifyListeners();
        return pred;
      }
    } catch (e) {
      debugPrint('AIPredictiveBettingEngine: Prediction failed: $e');
    }
    return null;
  }

  Future<void> submitPick({
    required String userId,
    required String fightId,
    required String pickFighterId,
    FightMethod? pickMethod,
    int? pickRound,
    double confidence = 0.5,
  }) async {
    try {
      await _firestore.collection('user_picks').add({
        'userId': userId,
        'fightId': fightId,
        'pickFighterId': pickFighterId,
        'pickMethod': pickMethod?.name,
        'pickRound': pickRound,
        'confidence': confidence,
        'isCorrect': false,
        'pointsEarned': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('🎰 AIPredictiveBettingEngine: Pick submitted');
    } catch (e) {
      debugPrint('AIPredictiveBettingEngine: Submit pick failed: $e');
    }
  }

  Future<Map<String, dynamic>> getLeaderboard({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('prediction_leaderboard')
          .orderBy('totalPoints', descending: true)
          .limit(limit)
          .get();

      return {
        'leaders': snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList(),
        'totalPlayers': snapshot.docs.length,
      };
    } catch (e) {
      return {'leaders': [], 'totalPlayers': 0};
    }
  }

  FightPrediction? getPrediction(String fightId) => _predictions[fightId];
}
