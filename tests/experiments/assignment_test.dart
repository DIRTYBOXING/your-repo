import 'package:test/test.dart';
import 'package:datafightcentral/experiments/assignment_service.dart';
import 'package:datafightcentral/experiments/experiment_service.dart';

class FakeDb implements DbAdapter {
  final Map<String, List<Map<String, dynamic>>> _store = {};
  final Map<String, Map<String, dynamic>> _experiments = {};

  @override
  Future<void> insert(String table, Map<String, dynamic> row) async {
    _store.putIfAbsent(table, () => []).add(row);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    Map<String, dynamic>? whereArgs,
  }) async {
    var rows = _store[table] ?? [];
    if (where != null && whereArgs != null) {
      final key = where.replaceAll('@', '');
      final value = whereArgs.values.first;
      rows = rows.where((row) => row[key] == value).toList();
    }
    return rows;
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> row, {
    String? where,
    Map<String, dynamic>? whereArgs,
  }) async {
    // Test stub
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String query) async {
    if (query.contains('experiments')) {
      return _store['experiments'] ?? [];
    }
    return [];
  }
}

void main() {
  group('AssignmentService', () {
    late FakeDb db;
    late ExperimentService experimentService;
    late AssignmentService assignmentService;

    setUp(() async {
      db = FakeDb();
      experimentService = ExperimentService(db);
      assignmentService = AssignmentService(db);
    });

    test('deterministic assignment is stable', () async {
      final experimentId = await experimentService.createExperiment(
        experimentId: 'exp-001',
        config: {'hypothesis': 'variant_a wins'},
        variants: ['control', 'variant_a', 'variant_b'],
      );

      final a1 = await assignmentService.assign(userId: 'user-1', experimentId: experimentId);
      final a2 = await assignmentService.assign(userId: 'user-1', experimentId: experimentId);

      expect(a1.variant, equals(a2.variant));
    });

    test('assignment returns multiple variants across users', () async {
      final experimentId = await experimentService.createExperiment(
        experimentId: 'exp-002',
        config: {'hypothesis': 'rollout'},
        variants: ['control', 'treatment'],
      );

      final assignments = <String>{};
      for (var i = 0; i < 100; i++) {
        final a = await assignmentService.assign(userId: 'user-$i', experimentId: experimentId);
        assignments.add(a.variant);
      }

      expect(assignments.length, greaterThanOrEqualTo(2));
    });
  });
}
