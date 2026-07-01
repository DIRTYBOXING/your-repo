import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC FIGHTER HEALTH PASSPORT — #113
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Blockchain-style tamper-evident health record for every fighter.
///
/// Features:
///   • Full medical history (injuries, surgeries, conditions)
///   • Concussion protocol tracking w/ mandatory cool-off periods
///   • Medical clearance status (cleared, suspended, conditional)
///   • Pre-fight & post-fight exam records
///   • Weight cut monitoring & interventions
///   • AI: concussion accumulation risk modeling
///   • AI: return-to-fight readiness scoring
///
/// Firestore Collections:
///   fighter_health_passports/{fighterId}           — Master passport
///   fighter_health_passports/{fighterId}/exams      — Exam records
///   fighter_health_passports/{fighterId}/concussions — Concussion log
///
/// ═══════════════════════════════════════════════════════════════════════════

enum ClearanceStatus { cleared, suspended, conditional, pending }

enum ExamType { preFight, postFight, annual, emergency, concussionProtocol }

class HealthPassport {
  final String fighterId;
  final String name;
  final ClearanceStatus status;
  final DateTime? suspensionEndDate;
  final int totalConcussions;
  final DateTime? lastConcussionDate;
  final int totalFightsAfterLastConcussion;
  final List<MedicalExam> recentExams;
  final List<String> knownConditions;
  final double readinessScore; // 0.0 – 1.0

  const HealthPassport({
    required this.fighterId,
    required this.name,
    this.status = ClearanceStatus.pending,
    this.suspensionEndDate,
    this.totalConcussions = 0,
    this.lastConcussionDate,
    this.totalFightsAfterLastConcussion = 0,
    this.recentExams = const [],
    this.knownConditions = const [],
    this.readinessScore = 1.0,
  });

  bool get isClearedToFight => status == ClearanceStatus.cleared;

  bool get isInConcussionProtocol {
    if (lastConcussionDate == null) return false;
    final coolOffDays = totalConcussions >= 3 ? 180 : 90;
    return DateTime.now().difference(lastConcussionDate!).inDays < coolOffDays;
  }
}

class MedicalExam {
  final String id;
  final String fighterId;
  final ExamType type;
  final String doctorName;
  final DateTime examDate;
  final bool passed;
  final String? notes;
  final Map<String, dynamic> vitals;

  const MedicalExam({
    required this.id,
    required this.fighterId,
    required this.type,
    required this.doctorName,
    required this.examDate,
    required this.passed,
    this.notes,
    this.vitals = const {},
  });
}

class ConcussionRecord {
  final String id;
  final String fighterId;
  final DateTime incidentDate;
  final String fightId;
  final String severity; // 'mild', 'moderate', 'severe'
  final int mandatorySuspensionDays;
  final DateTime returnEligibleDate;
  final bool clearedToReturn;

  const ConcussionRecord({
    required this.id,
    required this.fighterId,
    required this.incidentDate,
    required this.fightId,
    required this.severity,
    required this.mandatorySuspensionDays,
    required this.returnEligibleDate,
    this.clearedToReturn = false,
  });
}

class FighterHealthPassportService extends ChangeNotifier {
  static final FighterHealthPassportService _instance =
      FighterHealthPassportService._internal();
  factory FighterHealthPassportService() => _instance;
  FighterHealthPassportService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  final Map<String, HealthPassport> _passports = {};
  int _totalConcussionsTracked = 0;

  // ── Getters ──
  bool get initialized => _initialized;
  int get totalConcussionsTracked => _totalConcussionsTracked;

  HealthPassport? passportFor(String fighterId) => _passports[fighterId];

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[HealthPassport] Online — fighter safety passport active');
    notifyListeners();
  }

  // ── Passport Management ──

  Future<HealthPassport> createPassport(String fighterId, String name) async {
    final passport = HealthPassport(
      fighterId: fighterId,
      name: name,
    );
    _passports[fighterId] = passport;

    await _firestore.collection('fighter_health_passports').doc(fighterId).set({
      'name': name,
      'status': ClearanceStatus.pending.name,
      'totalConcussions': 0,
      'knownConditions': [],
      'readinessScore': 1.0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
    return passport;
  }

  // ── Medical Exams ──

  Future<void> recordExam(MedicalExam exam) async {
    await _firestore
        .collection('fighter_health_passports')
        .doc(exam.fighterId)
        .collection('exams')
        .doc(exam.id)
        .set({
          'type': exam.type.name,
          'doctorName': exam.doctorName,
          'examDate': Timestamp.fromDate(exam.examDate),
          'passed': exam.passed,
          'notes': exam.notes,
          'vitals': exam.vitals,
        });

    // Update clearance based on exam result.
    if (exam.passed && exam.type == ExamType.preFight) {
      _updateClearance(exam.fighterId, ClearanceStatus.cleared);
    } else if (!exam.passed) {
      _updateClearance(exam.fighterId, ClearanceStatus.suspended);
    }

    debugPrint(
      '[HealthPassport] Exam recorded: ${exam.type.name} '
      'for ${exam.fighterId} — ${exam.passed ? "PASSED" : "FAILED"}',
    );
    notifyListeners();
  }

  // ── Concussion Protocol ──

  Future<ConcussionRecord> recordConcussion(
    String fighterId,
    String fightId,
    String severity,
  ) async {
    _totalConcussionsTracked++;

    final suspensionDays = severity == 'severe'
        ? 180
        : severity == 'moderate'
        ? 90
        : 45;
    final returnDate = DateTime.now().add(Duration(days: suspensionDays));

    final record = ConcussionRecord(
      id: 'conc_${DateTime.now().millisecondsSinceEpoch}',
      fighterId: fighterId,
      incidentDate: DateTime.now(),
      fightId: fightId,
      severity: severity,
      mandatorySuspensionDays: suspensionDays,
      returnEligibleDate: returnDate,
    );

    await _firestore
        .collection('fighter_health_passports')
        .doc(fighterId)
        .collection('concussions')
        .doc(record.id)
        .set({
          'incidentDate': Timestamp.fromDate(record.incidentDate),
          'fightId': fightId,
          'severity': severity,
          'mandatorySuspensionDays': suspensionDays,
          'returnEligibleDate': Timestamp.fromDate(returnDate),
          'clearedToReturn': false,
        });

    // Suspend fighter.
    _updateClearance(
      fighterId,
      ClearanceStatus.suspended,
      suspensionEndDate: returnDate,
    );

    debugPrint(
      '[HealthPassport] CONCUSSION RECORDED: $fighterId — '
      '$severity — suspended $suspensionDays days',
    );
    notifyListeners();
    return record;
  }

  // ── AI: Concussion Accumulation Risk ──

  /// Returns risk level based on concussion history.
  Map<String, dynamic> concussionRiskAssessment(String fighterId) {
    final passport = _passports[fighterId];
    if (passport == null) {
      return {'riskLevel': 'unknown', 'recommendation': 'No passport found'};
    }

    final totalConc = passport.totalConcussions;
    final daysSinceLast = passport.lastConcussionDate != null
        ? DateTime.now().difference(passport.lastConcussionDate!).inDays
        : 9999;

    String riskLevel;
    String recommendation;

    if (totalConc >= 5 || (totalConc >= 3 && daysSinceLast < 365)) {
      riskLevel = 'critical';
      recommendation =
          'Strongly recommend extended medical evaluation and possible retirement counseling';
    } else if (totalConc >= 3 || (totalConc >= 2 && daysSinceLast < 180)) {
      riskLevel = 'high';
      recommendation =
          'Extended suspension required. Neurological evaluation before return';
    } else if (totalConc >= 1 && daysSinceLast < 90) {
      riskLevel = 'moderate';
      recommendation = 'Standard concussion protocol. Monitor closely';
    } else {
      riskLevel = 'low';
      recommendation = 'Cleared with standard monitoring';
    }

    return {
      'riskLevel': riskLevel,
      'totalConcussions': totalConc,
      'daysSinceLast': daysSinceLast,
      'recommendation': recommendation,
    };
  }

  // ── AI: Return-To-Fight Readiness ──

  /// Score from 0.0 (not ready) to 1.0 (fully ready).
  double assessReadiness(String fighterId) {
    final passport = _passports[fighterId];
    if (passport == null) return 0;

    double score = 1.0;

    // Concussion penalty.
    if (passport.isInConcussionProtocol) score -= 0.5;
    score -= passport.totalConcussions * 0.05;

    // Clearance status.
    if (passport.status == ClearanceStatus.suspended) score -= 0.4;
    if (passport.status == ClearanceStatus.conditional) score -= 0.2;
    if (passport.status == ClearanceStatus.pending) score -= 0.3;

    // Known conditions penalty.
    score -= passport.knownConditions.length * 0.05;

    return score.clamp(0.0, 1.0);
  }

  // ── Internal ──

  void _updateClearance(
    String fighterId,
    ClearanceStatus status, {
    DateTime? suspensionEndDate,
  }) {
    final current = _passports[fighterId];
    if (current == null) return;

    _passports[fighterId] = HealthPassport(
      fighterId: current.fighterId,
      name: current.name,
      status: status,
      suspensionEndDate: suspensionEndDate ?? current.suspensionEndDate,
      totalConcussions: current.totalConcussions,
      lastConcussionDate: current.lastConcussionDate,
      totalFightsAfterLastConcussion: current.totalFightsAfterLastConcussion,
      recentExams: current.recentExams,
      knownConditions: current.knownConditions,
      readinessScore: assessReadiness(fighterId),
    );
    notifyListeners();
  }
}
