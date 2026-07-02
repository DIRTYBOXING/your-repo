import 'dart:convert';
import 'dart:math';
import 'experiment_service.dart';

class Assignment {
  final String userId;
  final String experimentId;
  final String variant;
  final DateTime assignedAt;
  final String source;

  Assignment({
    required this.userId,
    required this.experimentId,
    required this.variant,
    required this.assignedAt,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'experimentId': experimentId,
      'variant': variant,
      'assignedAt': assignedAt.toIso8601String(),
      'source': source,
    };
  }

  factory Assignment.fromMap(Map<String, dynamic> map) {
    return Assignment(
      userId: map['userId'] as String,
      experimentId: map['experimentId'] as String,
      variant: map['variant'] as String,
      assignedAt: DateTime.parse(map['assignedAt'] as String),
      source: map['source'] as String,
    );
  }
}

class AssignmentService {
  final DbAdapter db;
  final Random _random = Random.secure();

  AssignmentService(this.db);

  /// Deterministic assignment using seeded hash.
  /// Stable across restarts given same seed/config.
  String _deterministicAssign({
    required String userId,
    required String experimentId,
    required int configVersion,
    required List<String> variants,
  }) {
    final input = '$userId|$experimentId|$configVersion';
    final bytes = utf8.encode(input);
    var hash = 0;
    for (final b in bytes) {
      hash = ((hash << 5) - hash) + b;
      hash |= 0;
    }
    final index = hash.abs() % variants.length;
    return variants[index];
  }

  /// Get or create assignment for user+experiment.
  /// Idempotent: repeated calls return same variant.
  Future<Assignment> assign({
    required String userId,
    required String experimentId,
    String source = 'api',
  }) async {
    // Check existing assignment first (idempotency)
    final existing = await db.query(
      'assignments',
      where: 'userId = @uid AND experimentId = @eid',
      whereArgs: {'uid': userId, 'eid': experimentId},
    );

    if (existing.isNotEmpty) {
      return Assignment.fromMap(existing.first);
    }

    // Load experiment config/version
    final experimentResult = await db.query(
      'experiments',
      where: 'experimentId = @id',
      whereArgs: {'id': experimentId},
    );

    if (experimentResult.isEmpty) {
      throw StateError('Experiment not found');
    }

    final experiment = Experiment.fromMap(experimentResult.first);
    final variant = _deterministicAssign(
      userId: userId,
      experimentId: experimentId,
      configVersion: experiment.configVersion,
      variants: experiment.variants,
    );

    final assignment = Assignment(
      userId: userId,
      experimentId: experimentId,
      variant: variant,
      assignedAt: DateTime.now().toUtc(),
      source: source,
    );

    await db.insert('assignments', assignment.toMap());
    return assignment;
  }

  Future<Assignment?> getAssignment(String userId, String experimentId) async {
    final result = await db.query(
      'assignments',
      where: 'userId = @uid AND experimentId = @eid',
      whereArgs: {'uid': userId, 'eid': experimentId},
    );

    if (result.isEmpty) return null;
    return Assignment.fromMap(result.first);
  }
}
