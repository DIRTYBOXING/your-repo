import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Pre-fight training readiness data for a fighter.
/// Stored in Firestore `camp_ready/{fighterId}` and updated by
/// coaching staff or wearable integrations.
///
/// Surfaces on the Fighter Profile and as a Premium PPV tier feature
/// ("Camp Intel") for paying subscribers.
class CampReady extends Equatable {
  final String fighterId;
  final String fighterName;

  /// Training load (0.0–10.0 scale, 10 = peak overload)
  final double trainingLoad;

  /// Resting heart rate in BPM
  final int restingHeartRate;

  /// Weight cut progress: current weight vs target (kg)
  final double currentWeightKg;
  final double targetWeightKg;

  /// Fight outcome triangle: striking / grappling / cardio scores (0–100)
  final int strikingScore;
  final int grapplingScore;
  final int cardioScore;

  /// Camp status
  final CampStatus status;

  /// Injury flag (vague — never expose specifics to protect fighter)
  final bool minorFlag;

  /// Days until fight
  final int daysOut;

  final DateTime? lastUpdated;

  const CampReady({
    required this.fighterId,
    this.fighterName = '',
    this.trainingLoad = 0.0,
    this.restingHeartRate = 0,
    this.currentWeightKg = 0.0,
    this.targetWeightKg = 0.0,
    this.strikingScore = 0,
    this.grapplingScore = 0,
    this.cardioScore = 0,
    this.status = CampStatus.inCamp,
    this.minorFlag = false,
    this.daysOut = 0,
    this.lastUpdated,
  });

  factory CampReady.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CampReady(
      fighterId: data['fighterId'] as String? ?? doc.id,
      fighterName: data['fighterName'] as String? ?? '',
      trainingLoad: (data['trainingLoad'] as num?)?.toDouble() ?? 0.0,
      restingHeartRate: data['restingHeartRate'] as int? ?? 0,
      currentWeightKg: (data['currentWeightKg'] as num?)?.toDouble() ?? 0.0,
      targetWeightKg: (data['targetWeightKg'] as num?)?.toDouble() ?? 0.0,
      strikingScore: data['strikingScore'] as int? ?? 0,
      grapplingScore: data['grapplingScore'] as int? ?? 0,
      cardioScore: data['cardioScore'] as int? ?? 0,
      status: CampStatus.fromString(data['status'] as String? ?? 'in_camp'),
      minorFlag: data['minorFlag'] as bool? ?? false,
      daysOut: data['daysOut'] as int? ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fighterId': fighterId,
    'fighterName': fighterName,
    'trainingLoad': trainingLoad,
    'restingHeartRate': restingHeartRate,
    'currentWeightKg': currentWeightKg,
    'targetWeightKg': targetWeightKg,
    'strikingScore': strikingScore,
    'grapplingScore': grapplingScore,
    'cardioScore': cardioScore,
    'status': status.value,
    'minorFlag': minorFlag,
    'daysOut': daysOut,
    'lastUpdated': FieldValue.serverTimestamp(),
  };

  /// Weight-cut progress percentage (0–100)
  double get weightCutProgress {
    if (targetWeightKg <= 0 || currentWeightKg <= 0) return 0;
    if (currentWeightKg <= targetWeightKg) return 100;
    final totalToCut = currentWeightKg - targetWeightKg;
    if (totalToCut <= 0) return 100;
    return ((1.0 - (currentWeightKg - targetWeightKg) / totalToCut) * 100)
        .clamp(0, 100);
  }

  /// Overall readiness score (0–100)
  int get readinessScore {
    final base = ((strikingScore + grapplingScore + cardioScore) / 3).round();
    // Penalize high training load (overtraining) and injury flags
    final overtrainPenalty = trainingLoad > 8.0 ? 10 : 0;
    final injuryPenalty = minorFlag ? 15 : 0;
    return (base - overtrainPenalty - injuryPenalty).clamp(0, 100);
  }

  @override
  List<Object?> get props => [
    fighterId,
    fighterName,
    trainingLoad,
    restingHeartRate,
    currentWeightKg,
    targetWeightKg,
    strikingScore,
    grapplingScore,
    cardioScore,
    status,
    minorFlag,
    daysOut,
    lastUpdated,
  ];
}

enum CampStatus {
  preCamp('pre_camp', 'Pre-Camp'),
  inCamp('in_camp', 'In Camp'),
  peakWeek('peak_week', 'Peak Week'),
  weightCut('weight_cut', 'Weight Cut'),
  fightReady('fight_ready', 'Fight Ready'),
  postFight('post_fight', 'Post-Fight');

  final String value;
  final String label;
  const CampStatus(this.value, this.label);

  static CampStatus fromString(String s) => CampStatus.values.firstWhere(
    (e) => e.value == s,
    orElse: () => CampStatus.inCamp,
  );
}
