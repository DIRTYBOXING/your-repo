import '../services/ai_memory_engine.dart';
import '../models/ai_memory_record.dart';

class ShakuraMemory {
  final AiMemoryEngine engine;
  final String personaId = "shakura";

  ShakuraMemory(this.engine);

  Future<void> rememberAwarenessTap({
    required String ownerId,
    required String contactId,
    required String contactType,
    required int moodScore,
    required int stressScore,
    required String message,
  }) {
    return engine.remember(
      AiMemoryRecord(
        personaId: personaId,
        ownerId: ownerId,
        domain: "awareness_tap",
        type: AiMemoryType.episode,
        timestamp: DateTime.now(),
        data: {
          "contactId": contactId,
          "contactType": contactType,
          "moodScore": moodScore,
          "stressScore": stressScore,
          "message": message,
        },
        tags: ["awareness", contactType],
      ),
    );
  }

  Future<void> rememberInboxTone({
    required String ownerId,
    required String tone,
    required String message,
  }) {
    return engine.remember(
      AiMemoryRecord(
        personaId: personaId,
        ownerId: ownerId,
        domain: "dm_inbox",
        type: AiMemoryType.session,
        timestamp: DateTime.now(),
        data: {
          "tone": tone,
          "message": message,
        },
        tags: ["inbox", tone],
      ),
    );
  }

  Future<List<AiMemoryRecord>> recallEmotionalPatterns(String ownerId) {
    return engine.recall(
      personaId: personaId,
      ownerId: ownerId,
      domain: "wellness_journal",
      tags: ["stress", "emotion"],
    );
  }
}
