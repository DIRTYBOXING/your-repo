enum ExperimentStatus { draft, running, paused, completed }

class Experiment {
  final String experimentId;
  final Map<String, dynamic> config;
  final List<String> variants;
  final ExperimentStatus status;
  final DateTime createdAt;
  final int configVersion;

  Experiment({
    required this.experimentId,
    required this.config,
    required this.variants,
    required this.status,
    required this.createdAt,
    required this.configVersion,
  });

  factory Experiment.create({
    required String experimentId,
    required Map<String, dynamic> config,
    required List<String> variants,
  }) {
    return Experiment(
      experimentId: experimentId,
      config: config,
      variants: variants,
      status: ExperimentStatus.draft,
      createdAt: DateTime.now().toUtc(),
      configVersion: 1,
    );
  }

  Experiment copyWith({
    String? experimentId,
    Map<String, dynamic>? config,
    List<String>? variants,
    ExperimentStatus? status,
    DateTime? createdAt,
    int? configVersion,
  }) {
    return Experiment(
      experimentId: experimentId ?? this.experimentId,
      config: config ?? this.config,
      variants: variants ?? this.variants,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      configVersion: configVersion ?? this.configVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'experimentId': experimentId,
      'config': config,
      'variants': variants,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'configVersion': configVersion,
    };
  }

  factory Experiment.fromMap(Map<String, dynamic> map) {
    return Experiment(
      experimentId: map['experimentId'] as String,
      config: Map<String, dynamic>.from(map['config'] as Map),
      variants: List<String>.from(map['variants'] as List),
      status: ExperimentStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      configVersion: map['configVersion'] as int,
    );
  }
}

class DbAdapter {
  Future<void> insert(String table, Map<String, dynamic> row) async {
    // TODO: replace with real DB insert
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    Map<String, dynamic>? whereArgs,
  }) async {
    // TODO: replace with real DB query
    return <Map<String, dynamic>>[];
  }

  Future<void> update(
    String table,
    Map<String, dynamic> row, {
    String? where,
    Map<String, dynamic>? whereArgs,
  }) async {
    // TODO: replace with real DB update
  }

  Future<List<Map<String, dynamic>>> rawQuery(String query) async {
    // TODO: replace with real DB raw query
    return <Map<String, dynamic>>[];
  }
}

class ExperimentService {
  final DbAdapter db;

  ExperimentService(this.db);

  Future<String?> createExperiment({
    required String experimentId,
    required Map<String, dynamic> config,
    required List<String> variants,
  }) async {
    final experiment = Experiment.create(
      experimentId: experimentId,
      config: config,
      variants: variants,
    );

    await db.insert('experiments', experiment.toMap());

    await db.insert('experiment_audit', {
      'changeId': 'chg-${DateTime.now().millisecondsSinceEpoch}',
      'experimentId': experimentId,
      'actorId': 'system',
      'change': 'created',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    return experimentId;
  }

  Future<Experiment?> getExperiment(String experimentId) async {
    final result = await db.query(
      'experiments',
      where: 'experimentId = @id',
      whereArgs: {'id': experimentId},
    );

    if (result.isEmpty) return null;
    return Experiment.fromMap(result.first);
  }

  Future<Experiment> updateExperimentConfig({
    required String experimentId,
    required Map<String, dynamic> newConfig,
    required String actorId,
  }) async {
    final existing = await getExperiment(experimentId);
    if (existing == null) {
      throw StateError('Experiment not found');
    }

    final updated = existing.copyWith(
      config: newConfig,
      configVersion: existing.configVersion + 1,
    );

    await db.update(
      'experiments',
      updated.toMap(),
      where: 'experimentId = @id',
      whereArgs: {'id': experimentId},
    );

    await db.insert('experiment_audit', {
      'changeId': 'chg-${DateTime.now().millisecondsSinceEpoch}',
      'experimentId': experimentId,
      'actorId': actorId,
      'change': 'config_updated',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });

    return updated;
  }

  Future<List<Experiment>> listExperiments({
    ExperimentStatus? status,
    int limit = 100,
    int offset = 0,
  }) async {
    var query = 'SELECT * FROM experiments';
    if (status != null) {
      query += " WHERE status = '${status.name}'";
    }
    query += ' LIMIT $limit OFFSET $offset';

    final results = await db.rawQuery(query);
    return results.map((m) => Experiment.fromMap(m)).toList();
  }
}
