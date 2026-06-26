import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DAILY GRIND SERVICE — Fight Camp Scheduler & Planner
/// ═══════════════════════════════════════════════════════════════════════════
///
/// CRUD for daily/weekly training schedules.
/// Handles: create, read, update, delete, reschedule, replan.
/// Firestore-backed: users/{uid}/daily_grind/{docId}
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Activity types ────────────────────────────────────────────
enum GrindActivityType {
  striking,
  grappling,
  wrestling,
  conditioning,
  strength,
  sparring,
  padWork,
  bagWork,
  recovery,
  yoga,
  stretching,
  cardio,
  swimming,
  roadWork,
  weightCut,
  weighIn,
  mediaDay,
  rest,
  custom,
}

extension GrindActivityTypeX on GrindActivityType {
  String get label {
    switch (this) {
      case GrindActivityType.striking:
        return 'Striking';
      case GrindActivityType.grappling:
        return 'Grappling';
      case GrindActivityType.wrestling:
        return 'Wrestling';
      case GrindActivityType.conditioning:
        return 'Conditioning';
      case GrindActivityType.strength:
        return 'Strength & Weights';
      case GrindActivityType.sparring:
        return 'Sparring';
      case GrindActivityType.padWork:
        return 'Pad Work';
      case GrindActivityType.bagWork:
        return 'Bag Work';
      case GrindActivityType.recovery:
        return 'Recovery';
      case GrindActivityType.yoga:
        return 'Yoga';
      case GrindActivityType.stretching:
        return 'Stretching';
      case GrindActivityType.cardio:
        return 'Cardio';
      case GrindActivityType.swimming:
        return 'Swimming';
      case GrindActivityType.roadWork:
        return 'Road Work / Run';
      case GrindActivityType.weightCut:
        return 'Weight Cut Session';
      case GrindActivityType.weighIn:
        return 'Weigh-In';
      case GrindActivityType.mediaDay:
        return 'Media / Press';
      case GrindActivityType.rest:
        return 'Rest Day';
      case GrindActivityType.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case GrindActivityType.striking:
        return '🥊';
      case GrindActivityType.grappling:
        return '🤼';
      case GrindActivityType.wrestling:
        return '🤼‍♂️';
      case GrindActivityType.conditioning:
        return '🏃';
      case GrindActivityType.strength:
        return '🏋️';
      case GrindActivityType.sparring:
        return '⚡';
      case GrindActivityType.padWork:
        return '🎯';
      case GrindActivityType.bagWork:
        return '🥋';
      case GrindActivityType.recovery:
        return '🧊';
      case GrindActivityType.yoga:
        return '🧘';
      case GrindActivityType.stretching:
        return '🤸';
      case GrindActivityType.cardio:
        return '❤️‍🔥';
      case GrindActivityType.swimming:
        return '🏊';
      case GrindActivityType.roadWork:
        return '🛣️';
      case GrindActivityType.weightCut:
        return '⚖️';
      case GrindActivityType.weighIn:
        return '📊';
      case GrindActivityType.mediaDay:
        return '📸';
      case GrindActivityType.rest:
        return '😴';
      case GrindActivityType.custom:
        return '📝';
    }
  }
}

// ─── Priority levels ───────────────────────────────────────────
enum GrindPriority { critical, high, normal, low }

extension GrindPriorityX on GrindPriority {
  String get label {
    switch (this) {
      case GrindPriority.critical:
        return 'CRITICAL';
      case GrindPriority.high:
        return 'HIGH';
      case GrindPriority.normal:
        return 'NORMAL';
      case GrindPriority.low:
        return 'LOW';
    }
  }
}

// ─── Single scheduled activity ─────────────────────────────────
class GrindEntry {
  final String id;
  final String userId;
  final DateTime date;
  final String startTime; // "06:00"
  final String endTime; // "07:30"
  final GrindActivityType activityType;
  final String title;
  final String notes;
  final String location; // gym name
  final String coach;
  final GrindPriority priority;
  final bool isCompleted;
  final int durationMinutes;

  /// RPE logged after session (1-10)
  final double? rpeAfter;

  /// Recurring pattern
  final bool isRecurring;
  final List<int> recurringDays; // 1=Mon ... 7=Sun

  final DateTime createdAt;
  final DateTime updatedAt;

  const GrindEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.activityType,
    required this.title,
    this.notes = '',
    this.location = '',
    this.coach = '',
    this.priority = GrindPriority.normal,
    this.isCompleted = false,
    this.durationMinutes = 60,
    this.rpeAfter,
    this.isRecurring = false,
    this.recurringDays = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  GrindEntry copyWith({
    String? id,
    DateTime? date,
    String? startTime,
    String? endTime,
    GrindActivityType? activityType,
    String? title,
    String? notes,
    String? location,
    String? coach,
    GrindPriority? priority,
    bool? isCompleted,
    int? durationMinutes,
    double? rpeAfter,
    bool? isRecurring,
    List<int>? recurringDays,
  }) {
    return GrindEntry(
      id: id ?? this.id,
      userId: userId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      coach: coach ?? this.coach,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      rpeAfter: rpeAfter ?? this.rpeAfter,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringDays: recurringDays ?? this.recurringDays,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'startTime': startTime,
    'endTime': endTime,
    'activityType': activityType.name,
    'title': title,
    'notes': notes,
    'location': location,
    'coach': coach,
    'priority': priority.name,
    'isCompleted': isCompleted,
    'durationMinutes': durationMinutes,
    'rpeAfter': rpeAfter,
    'isRecurring': isRecurring,
    'recurringDays': recurringDays,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  factory GrindEntry.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GrindEntry(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: d['startTime'] as String? ?? '06:00',
      endTime: d['endTime'] as String? ?? '07:00',
      activityType: GrindActivityType.values.firstWhere(
        (e) => e.name == d['activityType'],
        orElse: () => GrindActivityType.custom,
      ),
      title: d['title'] as String? ?? '',
      notes: d['notes'] as String? ?? '',
      location: d['location'] as String? ?? '',
      coach: d['coach'] as String? ?? '',
      priority: GrindPriority.values.firstWhere(
        (e) => e.name == d['priority'],
        orElse: () => GrindPriority.normal,
      ),
      isCompleted: d['isCompleted'] as bool? ?? false,
      durationMinutes: d['durationMinutes'] as int? ?? 60,
      rpeAfter: (d['rpeAfter'] as num?)?.toDouble(),
      isRecurring: d['isRecurring'] as bool? ?? false,
      recurringDays: List<int>.from(d['recurringDays'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DAILY GRIND SERVICE
// ═══════════════════════════════════════════════════════════════════════════
class DailyGrindService extends ChangeNotifier {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  List<GrindEntry> _entries = [];
  List<GrindEntry> get entries => _entries;
  bool _loading = false;
  bool get loading => _loading;

  DateTime _focusDate = DateTime.now();
  DateTime get focusDate => _focusDate;

  CollectionReference _col(String uid) =>
      _fs.collection('users').doc(uid).collection('daily_grind');

  // ─── SET FOCUS DATE ──────────────────────────────────────────
  void setFocusDate(DateTime d) {
    _focusDate = DateTime(d.year, d.month, d.day);
    notifyListeners();
  }

  // ─── LOAD DAY ────────────────────────────────────────────────
  Future<void> loadDay(String uid, DateTime date) async {
    _loading = true;
    notifyListeners();

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      final snap = await _col(uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .orderBy('date')
          .get();

      _entries = snap.docs.map(GrindEntry.fromFirestore).toList();
      // Sort by start time
      _entries.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (_) {
      // Fallback to demo data
      _entries = _demoEntries(uid, date);
    }

    _focusDate = date;
    _loading = false;
    notifyListeners();
  }

  // ─── LOAD WEEK ───────────────────────────────────────────────
  Future<List<GrindEntry>> loadWeek(String uid, DateTime weekStart) async {
    final end = weekStart.add(const Duration(days: 7));
    try {
      final snap = await _col(uid)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .orderBy('date')
          .get();

      final list = snap.docs.map(GrindEntry.fromFirestore).toList();
      list.sort((a, b) {
        final cmp = a.date.compareTo(b.date);
        return cmp != 0 ? cmp : a.startTime.compareTo(b.startTime);
      });
      return list;
    } catch (_) {
      return _demoWeek(uid, weekStart);
    }
  }

  // ─── CREATE ──────────────────────────────────────────────────
  Future<void> addEntry(String uid, GrindEntry entry) async {
    try {
      await _col(uid).add(entry.toFirestore());
    } catch (e) {
      debugPrint('DailyGrindService.addEntry offline/error: $e');
    }
    await loadDay(uid, entry.date);
  }

  // ─── UPDATE ──────────────────────────────────────────────────
  Future<void> updateEntry(String uid, GrindEntry entry) async {
    try {
      await _col(uid).doc(entry.id).update(entry.toFirestore());
    } catch (e) {
      debugPrint('DailyGrindService.updateEntry error: $e');
    }
    await loadDay(uid, entry.date);
  }

  // ─── DELETE ──────────────────────────────────────────────────
  Future<void> deleteEntry(String uid, GrindEntry entry) async {
    try {
      await _col(uid).doc(entry.id).delete();
    } catch (e) {
      debugPrint('DailyGrindService.deleteEntry error: $e');
    }
    _entries.removeWhere((e) => e.id == entry.id);
    notifyListeners();
  }

  // ─── TOGGLE COMPLETE ────────────────────────────────────────
  Future<void> toggleComplete(String uid, GrindEntry entry) async {
    final updated = entry.copyWith(isCompleted: !entry.isCompleted);
    await updateEntry(uid, updated);
  }

  // ─── RESCHEDULE (move to new date/time) ──────────────────────
  Future<void> reschedule(
    String uid,
    GrindEntry entry,
    DateTime newDate, {
    String? newStart,
    String? newEnd,
  }) async {
    final updated = entry.copyWith(
      date: newDate,
      startTime: newStart,
      endTime: newEnd,
    );
    await updateEntry(uid, updated);
  }

  // ─── LOG RPE ────────────────────────────────────────────────
  Future<void> logRpe(String uid, GrindEntry entry, double rpe) async {
    final updated = entry.copyWith(rpeAfter: rpe, isCompleted: true);
    await updateEntry(uid, updated);
  }

  // ─── GENERATE DAILY SUMMARY TEXT ────────────────────────────
  String dailySummary(List<GrindEntry> entries) {
    if (entries.isEmpty) return 'Rest day — no sessions scheduled.';

    final totalMin = entries.fold<int>(
      0,
      (runningTotal, entry) => runningTotal + entry.durationMinutes,
    );
    final completed = entries.where((e) => e.isCompleted).length;
    final buf = StringBuffer();
    buf.writeln('📋 DAILY GRIND SUMMARY');
    buf.writeln('═══════════════════════');
    buf.writeln(
      '${entries.length} sessions • ${totalMin}min total • $completed completed',
    );
    buf.writeln();
    for (final e in entries) {
      buf.write(
        '${e.activityType.emoji} ${e.startTime}-${e.endTime}  ${e.title}',
      );
      if (e.isCompleted) buf.write(' ✅');
      buf.writeln();
    }
    return buf.toString();
  }

  // ─── DEMO DATA ──────────────────────────────────────────────
  List<GrindEntry> _demoEntries(String uid, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return [
      GrindEntry(
        id: 'demo_1',
        userId: uid,
        date: d,
        startTime: '05:30',
        endTime: '06:15',
        activityType: GrindActivityType.roadWork,
        title: 'Morning Run — 5km Tempo',
        notes: 'Easy pace first 2km, last 3km at fight pace',
        location: 'Outdoor Track',
        priority: GrindPriority.high,
        durationMinutes: 45,
        createdAt: d,
        updatedAt: d,
      ),
      GrindEntry(
        id: 'demo_2',
        userId: uid,
        date: d,
        startTime: '07:00',
        endTime: '08:30',
        activityType: GrindActivityType.striking,
        title: 'Boxing — Pad Work + Combinations',
        notes: 'Focus on jab-cross-hook combo with Coach Mitchell',
        location: 'Absolute MMA Melbourne',
        coach: 'Coach Mitchell',
        priority: GrindPriority.critical,
        durationMinutes: 90,
        createdAt: d,
        updatedAt: d,
      ),
      GrindEntry(
        id: 'demo_3',
        userId: uid,
        date: d,
        startTime: '10:00',
        endTime: '11:00',
        activityType: GrindActivityType.strength,
        title: 'Strength — Upper Body + Core',
        location: 'UFC Gym Sydney',
        createdAt: d,
        updatedAt: d,
      ),
      GrindEntry(
        id: 'demo_4',
        userId: uid,
        date: d,
        startTime: '14:00',
        endTime: '15:30',
        activityType: GrindActivityType.grappling,
        title: 'BJJ — Guard Passing & Sweeps',
        notes: 'Work on butterfly guard entries',
        location: 'Southern Cross BJJ Melbourne',
        coach: 'Professor Machado',
        priority: GrindPriority.high,
        durationMinutes: 90,
        createdAt: d,
        updatedAt: d,
      ),
      GrindEntry(
        id: 'demo_5',
        userId: uid,
        date: d,
        startTime: '17:00',
        endTime: '17:30',
        activityType: GrindActivityType.recovery,
        title: 'Ice Bath + Stretching',
        notes: '3min cold / 1min warm × 4 rounds',
        location: 'Home',
        durationMinutes: 30,
        isCompleted: true,
        createdAt: d,
        updatedAt: d,
      ),
    ];
  }

  List<GrindEntry> _demoWeek(String uid, DateTime weekStart) {
    final all = <GrindEntry>[];
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      if (i == 6) {
        // Sunday rest
        all.add(
          GrindEntry(
            id: 'week_rest_$i',
            userId: uid,
            date: day,
            startTime: '00:00',
            endTime: '23:59',
            activityType: GrindActivityType.rest,
            title: 'REST DAY — Active Recovery Only',
            priority: GrindPriority.low,
            durationMinutes: 0,
            createdAt: day,
            updatedAt: day,
          ),
        );
      } else {
        all.addAll(_demoEntries(uid, day));
      }
    }
    return all;
  }
}
