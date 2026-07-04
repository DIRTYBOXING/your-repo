import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// PREDICTOR LIVE INPUTS SERVICE
// Holds conditioning slider state, debounces changes, re-runs prediction,
// writes results + inputs to Firestore for audit + live UI sync.
// ═══════════════════════════════════════════════════════════════════════════════

class ConditioningInputs {
  // Fighter A
  final double campWeeksA; // 1–16
  final double fatigueA; // 0.0–1.0 (0 = fresh, 1 = gassed)
  final double weightCutA; // 0.0–1.0 (0 = easy cut, 1 = brutal cut)
  final bool shortNoticeA;

  // Fighter B
  final double campWeeksB;
  final double fatigueB;
  final double weightCutB;
  final bool shortNoticeB;

  // Context
  final double oddsA; // implied probability 0.0–1.0
  final double oddsB;
  final bool isTitleFight;
  final int scheduledRounds; // 3 or 5

  const ConditioningInputs({
    this.campWeeksA = 8,
    this.fatigueA = 0.2,
    this.weightCutA = 0.2,
    this.shortNoticeA = false,
    this.campWeeksB = 8,
    this.fatigueB = 0.2,
    this.weightCutB = 0.2,
    this.shortNoticeB = false,
    this.oddsA = 0.5,
    this.oddsB = 0.5,
    this.isTitleFight = false,
    this.scheduledRounds = 3,
  });

  ConditioningInputs copyWith({
    double? campWeeksA,
    double? fatigueA,
    double? weightCutA,
    bool? shortNoticeA,
    double? campWeeksB,
    double? fatigueB,
    double? weightCutB,
    bool? shortNoticeB,
    double? oddsA,
    double? oddsB,
    bool? isTitleFight,
    int? scheduledRounds,
  }) => ConditioningInputs(
    campWeeksA: campWeeksA ?? this.campWeeksA,
    fatigueA: fatigueA ?? this.fatigueA,
    weightCutA: weightCutA ?? this.weightCutA,
    shortNoticeA: shortNoticeA ?? this.shortNoticeA,
    campWeeksB: campWeeksB ?? this.campWeeksB,
    fatigueB: fatigueB ?? this.fatigueB,
    weightCutB: weightCutB ?? this.weightCutB,
    shortNoticeB: shortNoticeB ?? this.shortNoticeB,
    oddsA: oddsA ?? this.oddsA,
    oddsB: oddsB ?? this.oddsB,
    isTitleFight: isTitleFight ?? this.isTitleFight,
    scheduledRounds: scheduledRounds ?? this.scheduledRounds,
  );

  Map<String, dynamic> toMap() => {
    'campWeeksA': campWeeksA,
    'fatigueA': fatigueA,
    'weightCutA': weightCutA,
    'shortNoticeA': shortNoticeA,
    'campWeeksB': campWeeksB,
    'fatigueB': fatigueB,
    'weightCutB': weightCutB,
    'shortNoticeB': shortNoticeB,
    'oddsA': oddsA,
    'oddsB': oddsB,
    'isTitleFight': isTitleFight,
    'scheduledRounds': scheduledRounds,
  };
}

class LivePredictionResult {
  final double winProbA;
  final double winProbB;
  final String predictedMethod; // 'KO/TKO' | 'Submission' | 'Decision'
  final int predictedRound;
  final double confidence;
  final List<ShapFeature> shapFeatures;
  final DateTime computedAt;
  final bool fromCache;

  const LivePredictionResult({
    required this.winProbA,
    required this.winProbB,
    required this.predictedMethod,
    required this.predictedRound,
    required this.confidence,
    required this.shapFeatures,
    required this.computedAt,
    this.fromCache = false,
  });
}

class ShapFeature {
  final String feature;
  final String label;
  final double impact;
  final String direction; // 'favors_a' | 'favors_b' | 'neutral'

  const ShapFeature({
    required this.feature,
    required this.label,
    required this.impact,
    required this.direction,
  });

  factory ShapFeature.fromMap(Map<String, dynamic> m) => ShapFeature(
    feature: m['feature'] ?? '',
    label: m['label'] ?? m['feature'] ?? '',
    impact: (m['impact'] ?? 0.0).toDouble().abs(),
    direction: m['direction'] ?? 'neutral',
  );
}

class PredictorLiveInputsService extends ChangeNotifier {
  static final PredictorLiveInputsService _i = PredictorLiveInputsService._();
  factory PredictorLiveInputsService() => _i;
  PredictorLiveInputsService._();

  final _fs = FirebaseFirestore.instance;
  final _fns = FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  // ── State ──────────────────────────────────────────────────────────────
  ConditioningInputs _inputs = const ConditioningInputs();
  LivePredictionResult? _result;
  bool _computing = false;
  String? _error;
  Timer? _debounce;

  // ── Getters ────────────────────────────────────────────────────────────
  ConditioningInputs get inputs => _inputs;
  LivePredictionResult? get result => _result;
  bool get computing => _computing;
  String? get error => _error;

  // ── Public API ─────────────────────────────────────────────────────────

  void setFighterA(String id, String name) {
    _fighterAId = id;
    _fighterAName = name;
  }

  void setFighterB(String id, String name) {
    _fighterBId = id;
    _fighterBName = name;
  }

  void updateInputs(ConditioningInputs updated) {
    _inputs = updated;
    notifyListeners();
    _scheduleRecompute();
  }

  void forceRecompute() {
    _debounce?.cancel();
    _compute();
  }

  // ── Private ────────────────────────────────────────────────────────────
  String _fighterAId = 'fighter_a';
  String _fighterAName = 'Fighter A';
  String _fighterBId = 'fighter_b';
  String _fighterBName = 'Fighter B';

  void _scheduleRecompute() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _compute);
  }

  Future<void> _compute() async {
    _computing = true;
    _error = null;
    notifyListeners();

    try {
      final callable = _fns.httpsCallable('predictFight');
      final payload = {
        'fighter1Id': _fighterAId,
        'fighter1Name': _fighterAName,
        'fighter2Id': _fighterBId,
        'fighter2Name': _fighterBName,
        ..._inputs.toMap(),
      };

      final res = await callable
          .call<Map<String, dynamic>>(payload)
          .timeout(const Duration(seconds: 12));

      final data = res.data;
      final prediction = data['prediction'] as Map<String, dynamic>? ?? data;

      final shapRaw = (prediction['explanation'] as List<dynamic>?) ?? [];
      final shapFeatures =
          shapRaw
              .map(
                (e) => ShapFeature.fromMap(Map<String, dynamic>.from(e as Map)),
              )
              .toList()
            ..sort((a, b) => b.impact.compareTo(a.impact));

      _result = LivePredictionResult(
        winProbA:
            (prediction['fighter1WinProb'] ??
                    prediction['winProbabilityA'] ??
                    0.5)
                .toDouble(),
        winProbB:
            (prediction['fighter2WinProb'] ??
                    prediction['winProbabilityB'] ??
                    0.5)
                .toDouble(),
        predictedMethod: _topMethod(prediction['methodProbs'] as Map? ?? {}),
        predictedRound:
            (prediction['predictedRound'] ?? prediction['rounds'] ?? 3) as int,
        confidence: (prediction['confidence'] ?? 0.65).toDouble(),
        shapFeatures: shapFeatures.take(6).toList(),
        computedAt: DateTime.now(),
        fromCache: prediction['fromCache'] == true,
      );

      // Firestore audit log
      await _logToFirestore(payload);
    } catch (e) {
      // Graceful heuristic fallback — keeps UI alive if service is down
      _result = _heuristicFallback();
      _error = 'Live predictor unreachable — showing heuristic estimate';
      debugPrint('PredictorLiveInputsService: $e');
    }

    _computing = false;
    notifyListeners();
  }

  String _topMethod(Map methodProbs) {
    if (methodProbs.isEmpty) return 'Decision';
    final sorted = methodProbs.entries.toList()
      ..sort((a, b) => (b.value as num).compareTo(a.value as num));
    return sorted.first.key.toString();
  }

  LivePredictionResult _heuristicFallback() {
    final campEdgeA = (_inputs.campWeeksA - _inputs.campWeeksB) / 16.0;
    final fatigueEdge = (_inputs.fatigueB - _inputs.fatigueA);
    final weightEdge = (_inputs.weightCutB - _inputs.weightCutA) * 0.5;
    final raw =
        0.5 +
        (campEdgeA + fatigueEdge + weightEdge) * 0.25 +
        (_inputs.oddsA - 0.5) * 0.3;
    final probA = raw.clamp(0.15, 0.85);

    return LivePredictionResult(
      winProbA: probA,
      winProbB: 1.0 - probA,
      predictedMethod: 'Decision',
      predictedRound: _inputs.scheduledRounds,
      confidence: 0.55,
      shapFeatures: [
        ShapFeature(
          feature: 'camp_weeks',
          label: 'Camp Length',
          impact: 0.18,
          direction: campEdgeA > 0 ? 'favors_a' : 'favors_b',
        ),
        ShapFeature(
          feature: 'fatigue',
          label: 'Fatigue Level',
          impact: 0.14,
          direction: fatigueEdge > 0 ? 'favors_a' : 'favors_b',
        ),
        ShapFeature(
          feature: 'weight_cut',
          label: 'Weight Cut',
          impact: 0.12,
          direction: weightEdge > 0 ? 'favors_a' : 'favors_b',
        ),
        ShapFeature(
          feature: 'odds_edge',
          label: 'Market Odds',
          impact: 0.10,
          direction: _inputs.oddsA > 0.5 ? 'favors_a' : 'favors_b',
        ),
      ],
      computedAt: DateTime.now(),
      fromCache: false,
    );
  }

  Future<void> _logToFirestore(Map<String, dynamic> payload) async {
    try {
      await _fs.collection('live_input_logs').add({
        ...payload,
        'fighterAId': _fighterAId,
        'fighterBId': _fighterBId,
        'resultProbA': _result?.winProbA,
        'resultProbB': _result?.winProbB,
        'method': _result?.predictedMethod,
        'confidence': _result?.confidence,
        'source': 'live_slider_input',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      /* non-critical */
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
