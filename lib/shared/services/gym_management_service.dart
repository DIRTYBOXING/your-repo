import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC GYM MANAGEMENT SYSTEM — #107
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Professional-grade tools for gyms and coaches.
///
/// Features:
///   • Gym profiles with branding
///   • Coach profiles & certifications
///   • Fighter rosters per gym
///   • Training schedules & curriculum
///   • Membership & attendance tracking
///   • Progress tracking per fighter
///   • Coach notes & video review
///   • AI training load balancing
///   • AI coach recommendations
///
/// Firestore Collections:
///   gym_management/{gymId}                   — Extended gym profiles
///   gym_management/{gymId}/coaches           — Coach roster
///   gym_management/{gymId}/schedule          — Training schedule
///   gym_management/{gymId}/attendance        — Attendance logs
///   gym_management/{gymId}/progress          — Fighter progress records
///
/// ═══════════════════════════════════════════════════════════════════════════

enum TrainingType {
  striking,
  grappling,
  wrestling,
  conditioning,
  sparring,
  technique,
  padWork,
  bagWork,
  recovery,
}

class CoachProfile {
  final String id;
  final String gymId;
  final String name;
  final String? photoUrl;
  final List<String> specialties; // e.g. 'Boxing', 'BJJ', 'MMA Striking'
  final List<String> certifications;
  final int yearsExperience;
  final double rating; // 0.0 – 5.0

  const CoachProfile({
    required this.id,
    required this.gymId,
    required this.name,
    this.photoUrl,
    this.specialties = const [],
    this.certifications = const [],
    this.yearsExperience = 0,
    this.rating = 0,
  });
}

class TrainingSession {
  final String id;
  final String gymId;
  final String coachId;
  final TrainingType type;
  final DateTime startTime;
  final Duration duration;
  final int maxCapacity;
  final List<String> attendeeIds;

  const TrainingSession({
    required this.id,
    required this.gymId,
    required this.coachId,
    required this.type,
    required this.startTime,
    required this.duration,
    this.maxCapacity = 30,
    this.attendeeIds = const [],
  });

  bool get isFull => attendeeIds.length >= maxCapacity;
}

class FighterProgress {
  final String fighterId;
  final String gymId;
  final Map<TrainingType, double> skillLevels; // 0.0 – 10.0
  final int sessionsAttended;
  final int sessionsTotal;
  final double attendanceRate;
  final String? coachNotes;
  final DateTime lastUpdated;

  const FighterProgress({
    required this.fighterId,
    required this.gymId,
    required this.skillLevels,
    required this.sessionsAttended,
    required this.sessionsTotal,
    required this.attendanceRate,
    this.coachNotes,
    required this.lastUpdated,
  });
}

class GymManagementService extends ChangeNotifier {
  static final GymManagementService _instance =
      GymManagementService._internal();
  factory GymManagementService() => _instance;
  GymManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _initialized = false;

  final Map<String, List<CoachProfile>> _coaches = {};
  final Map<String, List<TrainingSession>> _schedules = {};
  final Map<String, List<FighterProgress>> _progress = {};

  // ── Getters ──
  bool get initialized => _initialized;

  List<CoachProfile> coachesForGym(String gymId) =>
      List.unmodifiable(_coaches[gymId] ?? []);

  List<TrainingSession> scheduleForGym(String gymId) =>
      List.unmodifiable(_schedules[gymId] ?? []);

  List<FighterProgress> progressForGym(String gymId) =>
      List.unmodifiable(_progress[gymId] ?? []);

  // ── Lifecycle ──

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[GymMgmt] Online — professional gym tools active');
    notifyListeners();
  }

  // ── Coach Management ──

  Future<void> addCoach(CoachProfile coach) async {
    await _firestore
        .collection('gym_management')
        .doc(coach.gymId)
        .collection('coaches')
        .doc(coach.id)
        .set({
          'name': coach.name,
          'photoUrl': coach.photoUrl,
          'specialties': coach.specialties,
          'certifications': coach.certifications,
          'yearsExperience': coach.yearsExperience,
          'rating': coach.rating,
        });
    _coaches.putIfAbsent(coach.gymId, () => []).add(coach);
    notifyListeners();
  }

  // ── Schedule Management ──

  Future<void> addTrainingSession(TrainingSession session) async {
    await _firestore
        .collection('gym_management')
        .doc(session.gymId)
        .collection('schedule')
        .doc(session.id)
        .set({
          'coachId': session.coachId,
          'type': session.type.name,
          'startTime': Timestamp.fromDate(session.startTime),
          'durationMinutes': session.duration.inMinutes,
          'maxCapacity': session.maxCapacity,
          'attendeeIds': session.attendeeIds,
        });
    _schedules.putIfAbsent(session.gymId, () => []).add(session);
    notifyListeners();
  }

  // ── Attendance ──

  Future<void> recordAttendance(
    String gymId,
    String sessionId,
    String fighterId,
  ) async {
    await _firestore
        .collection('gym_management')
        .doc(gymId)
        .collection('attendance')
        .add({
          'sessionId': sessionId,
          'fighterId': fighterId,
          'timestamp': FieldValue.serverTimestamp(),
        });
    debugPrint('[GymMgmt] Attendance recorded: $fighterId in $sessionId');
    notifyListeners();
  }

  // ── Progress Tracking ──

  Future<void> updateProgress(FighterProgress progress) async {
    await _firestore
        .collection('gym_management')
        .doc(progress.gymId)
        .collection('progress')
        .doc(progress.fighterId)
        .set({
          'skillLevels': progress.skillLevels.map(
            (k, v) => MapEntry(k.name, v),
          ),
          'sessionsAttended': progress.sessionsAttended,
          'sessionsTotal': progress.sessionsTotal,
          'attendanceRate': progress.attendanceRate,
          'coachNotes': progress.coachNotes,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
    notifyListeners();
  }

  // ── AI: Training Load Balancing ──

  /// Recommend optimal training distribution for a fighter based on
  /// current skill levels and upcoming fight requirements.
  Map<TrainingType, double> recommendTrainingLoad(
    FighterProgress progress, {
    String? opponentStyle,
  }) {
    final loads = <TrainingType, double>{};
    final skills = progress.skillLevels;

    for (final type in TrainingType.values) {
      final currentLevel = skills[type] ?? 5.0;
      // Inversely proportional: weaknesses get more time.
      loads[type] = (10.0 - currentLevel) / 10.0;
    }

    // Normalize to 100%.
    final total = loads.values.reduce((a, b) => a + b);
    if (total > 0) {
      for (final type in loads.keys.toList()) {
        loads[type] = (loads[type]! / total * 100);
      }
    }

    debugPrint('[GymMgmt] AI training load: $loads');
    return loads;
  }

  /// AI: Recommend a coach based on fighter needs.
  CoachProfile? recommendCoach(String gymId, List<String> needSpecialties) {
    final coaches = _coaches[gymId] ?? [];
    if (coaches.isEmpty) return null;

    CoachProfile? best;
    int bestMatch = 0;
    for (final coach in coaches) {
      final match = coach.specialties
          .where((s) => needSpecialties.contains(s))
          .length;
      if (match > bestMatch) {
        bestMatch = match;
        best = coach;
      }
    }
    return best;
  }
}
