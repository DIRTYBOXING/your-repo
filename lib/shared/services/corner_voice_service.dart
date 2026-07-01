import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CORNER VOICE LIVE AI SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Real-time AI-powered motivational coaching messages.
/// Connects to the `cornerVoiceLive` Cloud Function (Gemini via Genkit).
///
/// USAGE:
/// ```dart
/// final service = CornerVoiceService();
/// final response = await service.getCornerMessage(
///   userId: 'user123',
///   context: CornerContext.trainingStart,
///   metrics: CornerMetrics(readinessScore: 85, campDay: 15, totalCampDays: 56),
///   preferredTone: CornerTone.intense,
/// );
/// debugPrint(response.primaryMessage);
/// ```
/// ═══════════════════════════════════════════════════════════════════════════

enum CornerContext {
  trainingStart,
  betweenRounds,
  trainingEnd,
  morningCheck,
  preFight,
  weightCut,
  recoveryDay,
  mentalSupport,
}

enum CornerTone { intense, calm, motivational, tactical }

enum CornerUrgency { low, medium, high }

class CornerMetrics {
  final int? readinessScore;
  final int? campDay;
  final int? totalCampDays;
  final int? daysUntilFight;
  final double? currentWeight;
  final double? targetWeight;
  final int? moodScore;
  final int? energyLevel;
  final String? lastSessionType;

  const CornerMetrics({
    this.readinessScore,
    this.campDay,
    this.totalCampDays,
    this.daysUntilFight,
    this.currentWeight,
    this.targetWeight,
    this.moodScore,
    this.energyLevel,
    this.lastSessionType,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (readinessScore != null) map['readinessScore'] = readinessScore;
    if (campDay != null) map['campDay'] = campDay;
    if (totalCampDays != null) map['totalCampDays'] = totalCampDays;
    if (daysUntilFight != null) map['daysUntilFight'] = daysUntilFight;
    if (currentWeight != null) map['currentWeight'] = currentWeight;
    if (targetWeight != null) map['targetWeight'] = targetWeight;
    if (moodScore != null) map['moodScore'] = moodScore;
    if (energyLevel != null) map['energyLevel'] = energyLevel;
    if (lastSessionType != null) map['lastSessionType'] = lastSessionType;
    return map;
  }
}

class CornerVoiceResponse {
  final String primaryMessage;
  final String? secondaryMessage;
  final CornerTone voiceTone;
  final CornerUrgency urgency;

  const CornerVoiceResponse({
    required this.primaryMessage,
    this.secondaryMessage,
    required this.voiceTone,
    required this.urgency,
  });

  factory CornerVoiceResponse.fromMap(Map<String, dynamic> map) {
    return CornerVoiceResponse(
      primaryMessage: map['primaryMessage'] as String? ?? "Let's work.",
      secondaryMessage: map['secondaryMessage'] as String?,
      voiceTone: _parseTone(map['voiceTone'] as String?),
      urgency: _parseUrgency(map['urgency'] as String?),
    );
  }

  static CornerTone _parseTone(String? value) {
    switch (value) {
      case 'intense':
        return CornerTone.intense;
      case 'calm':
        return CornerTone.calm;
      case 'tactical':
        return CornerTone.tactical;
      default:
        return CornerTone.motivational;
    }
  }

  static CornerUrgency _parseUrgency(String? value) {
    switch (value) {
      case 'low':
        return CornerUrgency.low;
      case 'high':
        return CornerUrgency.high;
      default:
        return CornerUrgency.medium;
    }
  }
}

class CornerVoiceService {
  final FirebaseFunctions _functions;

  CornerVoiceService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  /// Get a real-time AI-powered corner voice message
  ///
  /// [userId] - The user's ID for logging
  /// [context] - The situation context (training, rest, fight, etc.)
  /// [metrics] - Optional current metrics for personalization
  /// [fighterName] - Optional name for personalized messages
  /// [preferredTone] - The coaching style (intense, calm, motivational, tactical)
  Future<CornerVoiceResponse> getCornerMessage({
    required String userId,
    required CornerContext context,
    CornerMetrics? metrics,
    String? fighterName,
    CornerTone preferredTone = CornerTone.motivational,
  }) async {
    try {
      final callable = _functions.httpsCallable('cornerVoiceLive');

      final result = await callable.call<Map<String, dynamic>>({
        'userId': userId,
        'context': _contextToString(context),
        'metrics': metrics?.toMap(),
        'fighterName': fighterName,
        'preferredTone': _toneToString(preferredTone),
      });

      return CornerVoiceResponse.fromMap(result.data);
    } catch (e) {
      // Fallback to static message on error
      return _getFallbackMessage(context);
    }
  }

  String _contextToString(CornerContext context) {
    switch (context) {
      case CornerContext.trainingStart:
        return 'training_start';
      case CornerContext.betweenRounds:
        return 'between_rounds';
      case CornerContext.trainingEnd:
        return 'training_end';
      case CornerContext.morningCheck:
        return 'morning_check';
      case CornerContext.preFight:
        return 'pre_fight';
      case CornerContext.weightCut:
        return 'weight_cut';
      case CornerContext.recoveryDay:
        return 'recovery_day';
      case CornerContext.mentalSupport:
        return 'mental_support';
    }
  }

  String _toneToString(CornerTone tone) {
    switch (tone) {
      case CornerTone.intense:
        return 'intense';
      case CornerTone.calm:
        return 'calm';
      case CornerTone.motivational:
        return 'motivational';
      case CornerTone.tactical:
        return 'tactical';
    }
  }

  CornerVoiceResponse _getFallbackMessage(CornerContext context) {
    // Static fallbacks for offline/error scenarios
    const fallbacks = {
      CornerContext.trainingStart: "Let's work. Every rep matters.",
      CornerContext.betweenRounds: "Breathe. Reset. Execute.",
      CornerContext.trainingEnd: "Good work today. Rest up.",
      CornerContext.morningCheck: "New day. New opportunity. Let's go.",
      CornerContext.preFight: "Trust your preparation. This is your moment.",
      CornerContext.weightCut: "Stay disciplined. You've done this before.",
      CornerContext.recoveryDay: "Rest is strategy. Recover smart.",
      CornerContext.mentalSupport:
          "It's okay to not be okay. You're not alone.",
    };

    return CornerVoiceResponse(
      primaryMessage: fallbacks[context] ?? "Let's work.",
      voiceTone: CornerTone.motivational,
      urgency: CornerUrgency.medium,
    );
  }
}
