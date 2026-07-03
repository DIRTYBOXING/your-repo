import '../models/ai_memory_record.dart';

/// The Swiss-Clock AI Memory Layer interface.
/// Defines how all DFC AI personas store, retrieve, and summarize their memories
/// without violating safety boundaries or causing cross-persona data leakage.
abstract class AiMemoryEngine {
  
  /// Writes a new memory record (short-term, long-term, episodic, or domain).
  /// Enforces tagging with persona_id, owner_id, domain, and type.
  Future<void> remember(AiMemoryRecord record);

  /// Reads relevant past records to adapt AI advice.
  /// Can be filtered by owner, domain, tags, or a specific time window.
  Future<List<AiMemoryRecord>> recall({
    required String ownerId,
    required String personaId,
    AiMemoryType? type,
    String? domain,
    List<String>? tags,
    DateTime? since,
  });

  /// Compresses many records into a single summary record (e.g., per camp, per event).
  /// Keeps storage lean and ensures long-term memories don't infinitely expand.
  Future<AiMemoryRecord> summarize({
    required String ownerId,
    required String personaId,
    required String episodeId,
    required String domain,
  });

  /// Hard purge of memory (used for privacy compliance or wiping a session).
  Future<void> forget({
    required String ownerId,
    String? personaId,
    AiMemoryType? type,
  });
}
