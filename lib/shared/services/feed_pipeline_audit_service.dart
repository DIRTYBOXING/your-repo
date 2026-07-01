import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_role_registry.dart';

/// In-memory audit trail for feed pipeline orchestration.
class FeedPipelineAuditService {
  static const String collectionName = 'feed_pipeline_audit';

  static final FeedPipelineAuditService _instance =
      FeedPipelineAuditService._internal();
  factory FeedPipelineAuditService() => _instance;
  FeedPipelineAuditService._internal();

  final List<FeedPipelineEvent> _events = [];
  final _controller = StreamController<List<FeedPipelineEvent>>.broadcast();
  String _currentRunId = DateTime.now().microsecondsSinceEpoch.toString();

  Stream<List<FeedPipelineEvent>> get stream => _controller.stream;
  List<FeedPipelineEvent> get events => List.unmodifiable(_events);

  Stream<List<FeedPipelineEvent>> streamPersistedEvents({int limit = 120}) {
    try {
      return FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => FeedPipelineEvent.fromMap(doc.data()))
                .toList(),
          );
    } catch (_) {
      return Stream.value(const <FeedPipelineEvent>[]);
    }
  }

  void log({
    required FeedPipelineStage stage,
    required bool success,
    required String message,
  }) {
    final event = FeedPipelineEvent(
      runId: _currentRunId,
      stage: stage,
      role: AgentRoleRegistry.roleForStage(stage),
      success: success,
      message: message,
      timestamp: DateTime.now(),
    );

    _events.add(event);
    _controller.add(events);
    _persistEvent(event);
  }

  void clear() {
    _events.clear();
    _currentRunId = DateTime.now().microsecondsSinceEpoch.toString();
    _controller.add(events);
  }

  Future<void> _persistEvent(FeedPipelineEvent event) async {
    try {
      await FirebaseFirestore.instance.collection(collectionName).add({
        'runId': event.runId,
        'stage': event.stage.name,
        'role': event.role.name,
        'success': event.success,
        'message': event.message,
        'timestamp': Timestamp.fromDate(event.timestamp),
      });
    } catch (_) {
      // Keep audit persistence non-blocking for feed execution.
    }
  }

  void dispose() {
    _controller.close();
  }
}
