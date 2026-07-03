import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ai_memory_record.dart';
import 'ai_memory_engine.dart';

/// Firestore implementation of the AiMemoryEngine.
/// 
/// Stores memory records in:
///   ai_memory/{ownerId}/{personaId}/records/{autoId}
/// Summaries in:
///   ai_summaries/{ownerId}/{personaId}/{episodeId}
class AiMemoryEngineFirestore implements AiMemoryEngine {
  final FirebaseFirestore _db;

  AiMemoryEngineFirestore(this._db);

  @override
  Future<void> remember(AiMemoryRecord record) async {
    final ref = _db
        .collection('ai_memory')
        .doc(record.ownerId)
        .collection(record.personaId)
        .doc('records')
        .collection('entries')
        .doc();

    await ref.set(record.toJson());
  }

  @override
  Future<List<AiMemoryRecord>> recall({
    required String ownerId,
    required String personaId,
    AiMemoryType? type,
    String? domain,
    List<String>? tags,
    DateTime? since,
    DateTime? until,
  }) async {
    Query query = _db
        .collection('ai_memory')
        .doc(ownerId)
        .collection(personaId)
        .doc('records')
        .collection('entries');

    if (domain != null) query = query.where('domain', isEqualTo: domain);
    if (type != null) query = query.where('type', isEqualTo: type.name);
    
    // Note: Firestore only supports one array-contains or array-contains-any per query
    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }
    
    if (since != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: since.toIso8601String());
    }
    
    if (until != null) {
      query = query.where('timestamp',
          isLessThanOrEqualTo: until.toIso8601String());
    }

    // Sort by timestamp if we did a range query on it, otherwise standard sort
    if (since != null || until != null) {
      query = query.orderBy('timestamp', descending: true);
    }

    final snap = await query.get();
    
    return snap.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return AiMemoryRecord.fromJson(data);
    }).toList();
  }

  @override
  Future<AiMemoryRecord> summarize({
    required String ownerId,
    required String personaId,
    required String episodeId,
    required String domain,
    List<AiMemoryRecord>? recordsToSummarize,
  }) async {
    // If no records provided, fetch episode records
    final records = recordsToSummarize ?? await recall(
      ownerId: ownerId, 
      personaId: personaId,
      domain: domain,
      tags: [episodeId], // Convention: tag episodic records with the episodeId
    );
    
    // Simple summarization: compress data
    final summaryData = <String, dynamic>{
      'count': records.length,
      'latestTimestamp': records.isNotEmpty
          ? records.last.timestamp.toIso8601String()
          : null,
      'compressed_tags': records.expand((r) => r.tags).toSet().toList(),
      'summary': 'Compressed ${records.length} records for episode $episodeId',
      // In a real AI system, this would call an LLM to generate a semantic summary
    };

    final summaryRecord = AiMemoryRecord(
      personaId: personaId,
      ownerId: ownerId,
      domain: domain,
      type: AiMemoryType.episode,
      timestamp: DateTime.now(),
      data: summaryData,
      tags: [episodeId, 'summary'],
    );

    final ref = _db
        .collection('ai_summaries')
        .doc(ownerId)
        .collection(personaId)
        .doc(episodeId);

    await ref.set(summaryRecord.toJson());

    return summaryRecord;
  }

  @override
  Future<void> forget({
    required String ownerId,
    String? personaId,
    AiMemoryType? type,
  }) async {
    // Note: Doing deep deletes in Firestore from client is discouraged.
    // In production, this should trigger a Cloud Function.
    // This is a stub implementation for the interface.
    // debugPrint('WARNING: forget() called for owner: $ownerId. Triggering backend cleanup...');
    
    if (personaId != null) {
      // In a real implementation, you'd batch delete the subcollection
      final collection = _db
          .collection('ai_memory')
          .doc(ownerId)
          .collection(personaId)
          .doc('records')
          .collection('entries');
          
      if (type != null) {
        final query = collection.where('type', isEqualTo: type.name);
        final snap = await query.get();
        final batch = _db.batch();
        for (var doc in snap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
  }
}
