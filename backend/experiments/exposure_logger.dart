import 'experiment_service.dart';

class Exposure {
  final String exposureId;
  final String userId;
  final String experimentId;
  final String variant;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Exposure({
    required this.exposureId,
    required this.userId,
    required this.experimentId,
    required this.variant,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'exposureId': exposureId,
      'userId': userId,
      'experimentId': experimentId,
      'variant': variant,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Exposure.fromMap(Map<String, dynamic> map) {
    return Exposure(
      exposureId: map['exposureId'] as String,
      userId: map['userId'] as String,
      experimentId: map['experimentId'] as String,
      variant: map['variant'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map),
    );
  }
}

class ExposureLogger {
  final DbAdapter db;

  ExposureLogger(this.db);

  /// Append-only exposure logging for analytics consumption.
  Future<void> logExposure({
    required String userId,
    required String experimentId,
    required String variant,
    required Map<String, dynamic> context,
  }) async {
    final exposure = Exposure(
      exposureId: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      experimentId: experimentId,
      variant: variant,
      timestamp: DateTime.now().toUtc(),
      metadata: {
        'context': context,
        'loggedAt': DateTime.now().toUtc().toIso8601String(),
      },
    );

    await db.insert('exposures', exposure.toMap());
  }

  Future<List<Exposure>> getExposuresForUser(String userId) async {
    final result = await db.query(
      'exposures',
      where: 'userId = @uid',
      whereArgs: {'uid': userId},
    );

    return result.map((m) => Exposure.fromMap(m)).toList();
  }

  Future<List<Exposure>> getExposuresForExperiment(String experimentId) async {
    final result = await db.query(
      'exposures',
      where: 'experimentId = @eid',
      whereArgs: {'eid': experimentId},
    );

    return result.map((m) => Exposure.fromMap(m)).toList();
  }
}
