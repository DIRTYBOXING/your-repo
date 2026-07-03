import 'shakura_memory.dart';
import 'shakura_awareness_messaging.dart';

enum ShakuraState {
  stable,
  concern,
}

class ShakuraScanResult {
  final ShakuraState state;
  final String recommendation;

  ShakuraScanResult({
    required this.state,
    required this.recommendation,
  });
}

class ShakuraLogic {
  final ShakuraMemory memory;

  ShakuraLogic({required this.memory});

  /// Main emotional scan entry point
  ShakuraScanResult scan({
    required int moodScore,     // 1–10
    required int stressScore,   // 1–10
    required String lastMessageTone, // "neutral", "sad", "worried"
  }) {
    // Emotional thresholds
    final bool highStress = stressScore >= 8;
    final bool lowMood = moodScore <= 3;
    final bool concerningTone = lastMessageTone == "worried" || lastMessageTone == "sad";

    // Determine emotional state
    if (highStress || lowMood || concerningTone) {
      return ShakuraScanResult(
        state: ShakuraState.concern,
        recommendation: "AwarenessTap",
      );
    }

    return ShakuraScanResult(
      state: ShakuraState.stable,
      recommendation: "JournalEntry",
    );
  }

  /// Awareness routing logic
  String awarenessMessage({
    required int moodScore,
    required int stressScore,
  }) {
    if (stressScore >= 8 || moodScore <= 3) {
      return "Hey, I'm feeling a bit off today. Could we talk sometime soon?";
    }

    if (stressScore >= 5) {
      return "Just checking in, I'd love to catch up when you're free.";
    }

    return "Thinking of you, hope you're well.";
  }

  /// Trigger awareness
  Future<void> triggerAwareness({
    required String ownerId,
    required String contactId,
    required String contactType,
    required int moodScore,
    required int stressScore,
    required ShakuraAwarenessMessagingService messaging,
  }) async {
    final msg = awarenessMessage(
      moodScore: moodScore,
      stressScore: stressScore,
    );

    await messaging.sendAwareness(
      contactId: contactId,
      message: msg,
    );

    await memory.rememberAwarenessTap(
      ownerId: ownerId,
      contactId: contactId,
      contactType: contactType,
      moodScore: moodScore,
      stressScore: stressScore,
      message: msg,
    );
  }
}
