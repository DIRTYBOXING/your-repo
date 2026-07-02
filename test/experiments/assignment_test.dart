import 'package:flutter_test/flutter_test.dart';

import '../../backend/experiments/assignment_service.dart';
import '../../backend/experiments/experiment_service.dart';

class FakeDb implements DbAdapter {
  final Map<String, List<Map<String, dynamic>>> _store =
      <String, List<Map<String, dynamic>>>{};

  @override
  Future<void> insert(String table, Map<String, dynamic> row) async {
    _store.putIfAbsent(table, () => <Map<String, dynamic>>[]).add(row);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    Map<String, dynamic>? whereArgs,
  }) async {
    var rows = List<Map<String, dynamic>>.from(
      _store[table] ?? const <Map<String, dynamic>>[],
    );

    if (whereArgs == null || whereArgs.isEmpty) {
      return rows;
    }

    bool rowMatches(Map<String, dynamic> row) {
      for (final entry in whereArgs.entries) {
        final lookupKey = switch (entry.key) {
          'uid' => 'userId',
          'eid' => 'experimentId',
          'id' => 'experimentId',
          _ => entry.key,
        };
        if (row[lookupKey] != entry.value) {
          return false;
        }
      }
      return true;
    }

    rows = rows.where(rowMatches).toList();
    return rows;
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> row, {
    String? where,
    Map<String, dynamic>? whereArgs,
  }) async {
    final rows = _store[table] ?? <Map<String, dynamic>>[];
    final id = whereArgs?['id'];
    if (id == null) {
      return;
    }

    for (var i = 0; i < rows.length; i++) {
      if (rows[i]['experimentId'] == id) {
        rows[i] = row;
        return;
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String query) async {
    if (query.contains('experiments')) {
      return List<Map<String, dynamic>>.from(
        _store['experiments'] ?? const <Map<String, dynamic>>[],
      );
    }
    return <Map<String, dynamic>>[];
  }
}

void main() {
  group('AssignmentService', () {
    late FakeDb db;
    late ExperimentService experimentService;
    late AssignmentService assignmentService;

    setUp(() {
      db = FakeDb();
      experimentService = ExperimentService(db);
      assignmentService = AssignmentService(db);
    });

    test('deterministic assignment is stable and idempotent', () async {
      final experimentId = await experimentService.createExperiment(
        experimentId: 'exp-001',
        config: <String, dynamic>{'hypothesis': 'variant_a wins'},
        variants: <String>['control', 'variant_a', 'variant_b'],
      );

      final a1 = await assignmentService.assign(
        userId: 'user-1',
        experimentId: experimentId!,
      );
      final a2 = await assignmentService.assign(
        userId: 'user-1',
        experimentId: experimentId,
      );

      expect(a1.variant, equals(a2.variant));
      expect(a1.userId, equals(a2.userId));
    });

    test('assignment distributes variants across users', () async {
      final experimentId = await experimentService.createExperiment(
        experimentId: 'exp-002',
        config: <String, dynamic>{'hypothesis': 'rollout'},
        variants: <String>['control', 'treatment'],
      );

      final assignments = <String>{};
      for (var i = 0; i < 100; i++) {
        final a = await assignmentService.assign(
          userId: 'user-$i',
          experimentId: experimentId!,
        );
        assignments.add(a.variant);
      }

      expect(assignments.length, greaterThanOrEqualTo(2));
    });
  });
}
