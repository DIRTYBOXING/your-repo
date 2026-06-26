import '../../shared/services/corner_voice_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CORNER VOICE - Training Motivation & Coaching Messages
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Static methods for quick offline messages.
/// Use [CornerVoiceService] for AI-powered personalized messages.
///
/// STATIC METHODS (instant, offline):
/// - readiness(score) - Message based on readiness %
/// - campDay(day, total) - Camp progress motivation
/// - weightCut(current, target, days) - Weight cut guidance
/// - quote(dayOfYear) - Rotating daily quotes
/// - supportMessage() - Crisis support message
///
/// AI-POWERED (requires network):
/// ```dart
/// final service = CornerVoiceService();
/// final response = await service.getCornerMessage(
///   userId: 'user123',
///   context: CornerContext.trainingStart,
///   metrics: CornerMetrics(readinessScore: 85),
/// );
/// ```
/// ═══════════════════════════════════════════════════════════════════════════

class CornerVoice {
  CornerVoice._();

  /// Get AI-powered corner message (async, requires network)
  static Future<String> live({
    required String userId,
    required CornerContext context,
    CornerMetrics? metrics,
    String? fighterName,
    CornerTone tone = CornerTone.motivational,
  }) async {
    final service = CornerVoiceService();
    final response = await service.getCornerMessage(
      userId: userId,
      context: context,
      metrics: metrics,
      fighterName: fighterName,
      preferredTone: tone,
    );
    if (response.secondaryMessage != null) {
      return '${response.primaryMessage} ${response.secondaryMessage}';
    }
    return response.primaryMessage;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATIC METHODS (offline, instant)
  // ═══════════════════════════════════════════════════════════════════════════

  static String readiness(int s) {
    if (s >= 90) return "You're sharp. No hesitation. Do what we trained for.";
    if (s >= 75) return "Good shape. Not perfect - push today.";
    if (s >= 60) return "Not 100. Train smart. Controlled rounds.";
    if (s >= 40) return "Light work only. Recovery is strategy.";
    return "Sit down. You're not training today. Rest. Tomorrow.";
  }

  static String campDay(int day, int total) {
    final r = total - day;
    if (day == 1) return "Day 1. Every rep matters. Let's work.";
    if (r <= 3) return "Final stretch. Trust your preparation.";
    final p = (day / total * 100).round();
    if (p < 30) return "Day $day. Building the base. Grind.";
    if (p < 70) return "Day $day. Where most quit. Not you.";
    return "Day $day. $r days left. Be dangerous.";
  }

  static String weightCut(double cur, double tgt, int days) {
    final d = cur - tgt;
    if (d <= 0) return "On weight. Focus on the game plan.";
    final r = d / (days > 0 ? days : 1);
    if (r > 1.5) return "Dangerous territory. Nutritionist needed NOW.";
    if (r > 0.5) {
      return "${d.toStringAsFixed(1)}kg to go. Tight but manageable.";
    }
    return "On track. ${d.toStringAsFixed(1)}kg left. Stay disciplined.";
  }

  static String quote(int d) {
    const q = [
      'John Scida: 50 years of hard work. Ultimate Honour.',
      'Ricky Hatton: True champions fight their demons and win. You are not alone.',
      'It is okay to not be okay. The real fight is sometimes outside the ring.',
      'Leave the ego at the door. The data doesn\'t judge, it guides.',
      'Strength is asking for help. Break the cycle of addiction.',
      'We stand against violence, poverty, and homelessness. Support the community.',
      'Healthy choices in the kitchen win fights in the cage.',
      'We are here to support your gym, not to compete with it.',
      'Respect the legacy. Better every day, together.',
      'Ultimate Honour Elite Mentorship: Built on 50 years of trust.',
      'Discipline is doing what you hate, like you love it.',
      'The fight is won far from witnesses - in the gym.',
      'Fear is like fire. Cook with it or it burns your house down.',
      'Champions are made in the dark. Keep grinding.',
      'Rest is a weapon. Use it.',
      'Your opponent is training right now.',
      'Consistency over intensity. Every single time.',
      'Hard work beats talent when talent doesn t work hard.',
      'The body achieves what the mind believes. Data doesn t lie.',
      'Train like the underdog. Fight like the champion.',
      'John Scida: From Ultimate Muay Thai to Ultimate Legends. 30+ years. The legacy runs deep.',
      'Joey Demicoli: A corner man, a promoter, a brother. Real ones build together.',
      'James and Jordan Roesler. Father and son. One corner, one legacy. That is combat sports.',
      'Thailand to Melbourne. The art of eight limbs connects the world. Train global, fight local.',
    ];
    return q[d % q.length];
  }

  static String supportMessage() {
    return "Crisis Support: You are not alone. Mental health, addiction, and safety are our priority. Reach out to a mentor or professional today.";
  }
}
