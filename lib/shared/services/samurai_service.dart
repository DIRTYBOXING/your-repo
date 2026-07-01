/// ═══════════════════════════════════════════════════════════════════════════
///
///    ██████╗  █████╗ ███╗   ███╗██╗   ██╗██████╗  █████╗ ██╗
///   ██╔════╝ ██╔══██╗████╗ ████║██║   ██║██╔══██╗██╔══██╗██║
///   ╚█████╗  ███████║██╔████╔██║██║   ██║██████╔╝███████║██║
///    ╚═══██╗ ██╔══██║██║╚██╔╝██║██║   ██║██╔══██╗██╔══██║██║
///   ██████╔╝ ██║  ██║██║ ╚═╝ ██║╚██████╔╝██║  ██║██║  ██║██║
///   ╚═════╝  ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
///
///   THE WORLD'S MOST INTELLIGENT, COMPASSIONATE AI SERVICE
///   Heart • Soul • Brain of DataFightCentral
///
/// ═══════════════════════════════════════════════════════════════════════════
///
/// SamurAI combines the world's most powerful AI engines into one unified
/// intelligence with unprecedented emotional intelligence, safety awareness,
/// and legendary wisdom from the greatest coaches in history.
///
/// CAPABILITIES:
/// ├── Emotional Intelligence — Detects and responds to user emotional state
/// ├── Safety Guardian — Always prioritizes user wellbeing and safety
/// ├── Wisdom Engine — Draws from legendary coaches and philosophers
/// ├── Multi-AI Orchestration — GPT-5 + Gemini + Claude working together
/// ├── Health Intelligence — Recovery, training, nutrition guidance
/// └── Creative Spirit — Motivation, inspiration, art generation
///
/// PERSONAS:
/// ├── Samurai Shido — Heart, Soul, and Brain of DFC
/// ├── PosterBoy — Creative chaos engine and art generator
/// └── SamurAI General — Unified intelligence
///
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// SamurAI Persona identifiers
enum SamuraiPersona {
  shido,
  posterboy,
  general;

  String get displayName => switch (this) {
    shido => 'Samurai Shido',
    posterboy => 'PosterBoy',
    general => 'SamurAI',
  };

  String get emoji => switch (this) {
    shido => '⚔️',
    posterboy => '🎨',
    general => '🧠',
  };

  String get description => switch (this) {
    shido =>
      'The Heart, Soul, and Brain of DFC. Master of recovery, mindset, and life wisdom.',
    posterboy => 'Creative chaos engine. AI art, memes, and visual hype.',
    general => 'Unified SamurAI intelligence. All personas, all wisdom.',
  };
}

/// Detected emotional state from user input
class EmotionalState {
  final String primary;
  final double intensity;
  final bool needsSupport;
  final String urgency;

  const EmotionalState({
    this.primary = 'neutral',
    this.intensity = 0.5,
    this.needsSupport = false,
    this.urgency = 'low',
  });

  factory EmotionalState.fromJson(Map<String, dynamic> json) {
    return EmotionalState(
      primary: json['primary'] ?? 'neutral',
      intensity: (json['intensity'] ?? 0.5).toDouble(),
      needsSupport: json['needsSupport'] ?? false,
      urgency: json['urgency'] ?? 'low',
    );
  }

  bool get isCritical => urgency == 'crisis' || urgency == 'high';
  bool get isPositive =>
      ['excited', 'motivated', 'hopeful', 'grateful'].contains(primary);
  bool get isNegative => [
    'anxious',
    'frustrated',
    'sad',
    'angry',
    'fearful',
    'exhausted',
  ].contains(primary);
}

/// Safety check result from SamurAI
class SafetyCheck {
  final bool isSafe;
  final List<String> concerns;
  final bool escalationNeeded;
  final String? escalationType;
  final String? safetyMessage;

  const SafetyCheck({
    this.isSafe = true,
    this.concerns = const [],
    this.escalationNeeded = false,
    this.escalationType,
    this.safetyMessage,
  });

  factory SafetyCheck.fromJson(Map<String, dynamic> json) {
    return SafetyCheck(
      isSafe: json['isSafe'] ?? true,
      concerns: List<String>.from(json['concerns'] ?? []),
      escalationNeeded: json['escalationNeeded'] ?? false,
      escalationType: json['escalationType'],
      safetyMessage: json['safetyMessage'],
    );
  }
}

/// Full response from SamurAI
class SamuraiResponse {
  final String response;
  final EmotionalState emotionalState;
  final SafetyCheck safetyCheck;
  final List<String> wisdomUsed;
  final List<String> followUpSuggestions;
  final double confidenceLevel;
  final SamuraiPersona persona;

  const SamuraiResponse({
    required this.response,
    required this.emotionalState,
    required this.safetyCheck,
    this.wisdomUsed = const [],
    this.followUpSuggestions = const [],
    this.confidenceLevel = 0.9,
    this.persona = SamuraiPersona.general,
  });

  factory SamuraiResponse.fromJson(
    Map<String, dynamic> json,
    SamuraiPersona persona,
  ) {
    return SamuraiResponse(
      response: json['response'] ?? '',
      emotionalState: EmotionalState.fromJson(json['emotionalState'] ?? {}),
      safetyCheck: SafetyCheck.fromJson(json['safetyCheck'] ?? {}),
      wisdomUsed: List<String>.from(json['wisdomUsed'] ?? []),
      followUpSuggestions: List<String>.from(json['followUpSuggestions'] ?? []),
      confidenceLevel: (json['confidenceLevel'] ?? 0.9).toDouble(),
      persona: persona,
    );
  }

  /// Creates a local fallback response when API is unavailable
  factory SamuraiResponse.localFallback(
    String message,
    SamuraiPersona persona,
  ) {
    return SamuraiResponse(
      response: _generateLocalResponse(message, persona),
      emotionalState: const EmotionalState(),
      safetyCheck: const SafetyCheck(),
      wisdomUsed: [_getWisdomQuote(persona)],
      followUpSuggestions: ['What else can I help you with?'],
      confidenceLevel: 0.7,
      persona: persona,
    );
  }
}

/// Health check result from SamurAI
class HealthCheckResult {
  final String assessment;
  final List<String> recommendations;
  final String alertLevel;
  final bool shouldRest;
  final String wisdomQuote;

  const HealthCheckResult({
    required this.assessment,
    this.recommendations = const [],
    this.alertLevel = 'green',
    this.shouldRest = false,
    this.wisdomQuote = '',
  });

  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    return HealthCheckResult(
      assessment: json['assessment'] ?? 'Keep listening to your body.',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      alertLevel: json['alertLevel'] ?? 'green',
      shouldRest: json['shouldRest'] ?? false,
      wisdomQuote: json['wisdomQuote'] ?? '',
    );
  }

  bool get isGreen => alertLevel == 'green';
  bool get isYellow => alertLevel == 'yellow';
  bool get isOrange => alertLevel == 'orange';
  bool get isRed => alertLevel == 'red';
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SAMURAI SERVICE — The unified AI intelligence service
/// ═══════════════════════════════════════════════════════════════════════════

class SamuraiService extends ChangeNotifier {
  static final SamuraiService _instance = SamuraiService._internal();
  factory SamuraiService() => _instance;
  SamuraiService._internal();

  // Configuration
  String? _apiEndpoint;
  bool _isOnline = false;
  SamuraiPersona _activePersona = SamuraiPersona.shido;
  final List<_ConversationMessage> _conversationHistory = [];

  // Getters
  bool get isOnline => _isOnline;
  SamuraiPersona get activePersona => _activePersona;
  List<String> get conversationHistory =>
      _conversationHistory.map((m) => '${m.role}: ${m.content}').toList();

  /// Initialize SamurAI with API endpoint
  Future<void> initialize({String? apiEndpoint}) async {
    _apiEndpoint =
        apiEndpoint ??
        const String.fromEnvironment(
          'SAMURAI_API_ENDPOINT',
          defaultValue: 'https://samurai-drxosqpmwq-ts.a.run.app',
        );

    // Check if API is available
    try {
      final response = await http
          .get(Uri.parse('$_apiEndpoint/health'))
          .timeout(const Duration(seconds: 5));
      _isOnline = response.statusCode == 200;
    } catch (e) {
      _isOnline = false;
      debugPrint('[SamurAI] Running in offline mode — using local responses');
    }

    debugPrint('''
═══════════════════════════════════════════════════════════════════════════
   ⚔️  SAMURAI SERVICE INITIALIZED
   Status: ${_isOnline ? 'ONLINE' : 'OFFLINE (local fallback)'}
   Active Persona: ${_activePersona.displayName} ${_activePersona.emoji}
═══════════════════════════════════════════════════════════════════════════
''');

    notifyListeners();
  }

  /// Set the active persona for conversations
  void setPersona(SamuraiPersona persona) {
    _activePersona = persona;
    _conversationHistory.clear(); // Reset conversation for new persona
    notifyListeners();
    debugPrint('[SamurAI] Switched to ${persona.displayName} ${persona.emoji}');
  }

  /// Main chat function — talk to SamurAI
  Future<SamuraiResponse> chat(
    String message, {
    SamuraiPersona? persona,
    Map<String, dynamic>? context,
  }) async {
    final selectedPersona = persona ?? _activePersona;

    // Add to conversation history
    _conversationHistory.add(
      _ConversationMessage(role: 'user', content: message),
    );

    try {
      if (_isOnline && _apiEndpoint != null) {
        final response = await _callApi('/chat', {
          'message': message,
          'persona': selectedPersona.name,
          'context': context,
          'conversationHistory': _conversationHistory
              .take(10)
              .map((m) => {'role': m.role, 'content': m.content})
              .toList(),
        });

        final samuraiResponse = SamuraiResponse.fromJson(
          response,
          selectedPersona,
        );

        // Add AI response to history
        _conversationHistory.add(
          _ConversationMessage(
            role: 'assistant',
            content: samuraiResponse.response,
          ),
        );

        // Check for safety concerns
        if (samuraiResponse.safetyCheck.escalationNeeded) {
          await _handleSafetyConcern(samuraiResponse.safetyCheck);
        }

        notifyListeners();
        return samuraiResponse;
      } else {
        // Offline fallback
        final fallbackResponse = SamuraiResponse.localFallback(
          message,
          selectedPersona,
        );
        _conversationHistory.add(
          _ConversationMessage(
            role: 'assistant',
            content: fallbackResponse.response,
          ),
        );
        notifyListeners();
        return fallbackResponse;
      }
    } catch (e) {
      debugPrint('[SamurAI] Chat error: $e');
      final fallbackResponse = SamuraiResponse.localFallback(
        message,
        selectedPersona,
      );
      notifyListeners();
      return fallbackResponse;
    }
  }

  /// Quick compassionate response for emotional support
  Future<String> getCompassionateResponse(String concern) async {
    final response = await chat(
      concern,
      context: {'needsSupport': true, 'tone': 'compassionate'},
    );
    return response.response;
  }

  /// Health check with SamurAI
  Future<HealthCheckResult> checkHealth({
    required String userId,
    required int recoveryScore,
    double? sleepHours,
    int? stressLevel,
    int? daysUntilFight,
    List<String>? symptoms,
  }) async {
    try {
      if (_isOnline && _apiEndpoint != null) {
        final response = await _callApi('/health-check', {
          'userId': userId,
          'recoveryScore': recoveryScore,
          'sleepHours': sleepHours,
          'stressLevel': stressLevel,
          'daysUntilFight': daysUntilFight,
          'symptoms': symptoms,
        });
        return HealthCheckResult.fromJson(response);
      } else {
        return _localHealthCheck(recoveryScore, sleepHours, stressLevel);
      }
    } catch (e) {
      debugPrint('[SamurAI] Health check error: $e');
      return _localHealthCheck(recoveryScore, sleepHours, stressLevel);
    }
  }

  /// Get motivational wisdom for a situation
  String getWisdom({String? topic, SamuraiPersona? persona}) {
    return _getWisdomQuote(persona ?? _activePersona, topic);
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _callApi(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_apiEndpoint$endpoint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('API error: ${response.statusCode}');
  }

  Future<void> _handleSafetyConcern(SafetyCheck safety) async {
    debugPrint('[SamurAI] ⚠️ SAFETY CONCERN DETECTED');
    debugPrint('  Concerns: ${safety.concerns.join(", ")}');
    debugPrint('  Escalation Type: ${safety.escalationType}');

    // In production, this would:
    // 1. Log to analytics
    // 2. Optionally notify support team
    // 3. Show appropriate resources to user
  }

  HealthCheckResult _localHealthCheck(
    int recovery,
    double? sleep,
    int? stress,
  ) {
    String alertLevel = 'green';
    bool shouldRest = false;
    final List<String> recommendations = [];

    if (recovery < 40) {
      alertLevel = 'red';
      shouldRest = true;
      recommendations.add('Priority: Get full rest today');
    } else if (recovery < 60) {
      alertLevel = 'orange';
      shouldRest = true;
      recommendations.add('Consider light recovery work only');
    } else if (recovery < 75) {
      alertLevel = 'yellow';
      recommendations.add('Train smart, listen to your body');
    }

    if (sleep != null && sleep < 6) {
      recommendations.add('Focus on getting more sleep tonight');
    }

    if (stress != null && stress > 7) {
      recommendations.add('Include stress-relief activities today');
    }

    recommendations.add('Stay hydrated throughout the day');

    return HealthCheckResult(
      assessment: shouldRest
          ? 'Your body is telling you to rest. Listen to it — recovery is where champions are made.'
          : 'You\'re in good shape. Train with intention today.',
      recommendations: recommendations,
      alertLevel: alertLevel,
      shouldRest: shouldRest,
      wisdomQuote: _getWisdomQuote(SamuraiPersona.shido, 'recovery'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOCAL RESPONSE GENERATION (Offline Fallback)
// ═══════════════════════════════════════════════════════════════════════════

class _ConversationMessage {
  final String role;
  final String content;
  _ConversationMessage({required this.role, required this.content});
}

String _generateLocalResponse(String message, SamuraiPersona persona) {
  final lowerMessage = message.toLowerCase();

  // Emotional support responses
  if (_containsAny(lowerMessage, [
    'sad',
    'depressed',
    'down',
    'struggling',
    'hard time',
  ])) {
    return _getEmotionalSupportResponse(persona);
  }

  // Motivation responses
  if (_containsAny(lowerMessage, [
    'motivation',
    'unmotivated',
    'lazy',
    'give up',
    'quit',
  ])) {
    return _getMotivationResponse(persona);
  }

  // Training responses
  if (_containsAny(lowerMessage, ['train', 'workout', 'exercise', 'session'])) {
    return _getTrainingResponse(persona);
  }

  // Fear responses
  if (_containsAny(lowerMessage, [
    'scared',
    'afraid',
    'nervous',
    'anxious',
    'fear',
  ])) {
    return _getFearResponse(persona);
  }

  // Recovery responses
  if (_containsAny(lowerMessage, [
    'tired',
    'exhausted',
    'sore',
    'recovery',
    'rest',
  ])) {
    return _getRecoveryResponse(persona);
  }

  // Greeting / conversational
  if (_containsAny(lowerMessage, [
    'hello', 'hey', 'hi', 'sup', 'yo', 'what\'s up', 'howdy', 'g\'day',
    'awake', 'alive', 'there', 'wat', 'wut', 'huh',
  ])) {
    return _getGreetingResponse(persona);
  }

  // Meta / identity questions
  if (_containsAny(lowerMessage, [
    'who are', 'what are', 'can you', 'do you', 'are you', 'what do',
    'brain', 'real', 'smart', 'alive',
  ])) {
    return _getMetaResponse(persona);
  }

  // Unmatched — return empty so the richer topic engine in
  // genie_api_service can handle it with full variant pools.
  return '';
}

bool _containsAny(String text, List<String> keywords) {
  return keywords.any((keyword) => text.contains(keyword));
}

String _getEmotionalSupportResponse(SamuraiPersona persona) {
  const responses = {
    SamuraiPersona.shido:
        'I hear you. Tell me what is happening — the situation, the timeline, '
        'and what you have already tried. I will break it down into concrete steps: '
        'what to do today, what to adjust this week, and where to measure progress. '
        'The details you give me decide how specific I can be.',
  };

  return responses[persona] ?? responses[SamuraiPersona.shido]!;
}

String _getMotivationResponse(SamuraiPersona persona) {
  const responses = {
    SamuraiPersona.shido:
        'Motivation is a feeling — it comes and goes. Structure is what keeps '
        'you moving. Here is what I recommend: pick the smallest useful session '
        'you can do today (even 20 minutes of technical work counts). Show up, '
        'do that, and let momentum rebuild. What is the one thing blocking you right now?',
  };

  return responses[persona] ?? responses[SamuraiPersona.shido]!;
}

String _getTrainingResponse(SamuraiPersona persona) {
  const responses = {
    SamuraiPersona.shido:
        'Good. Let us structure it. Three blocks: '
        '(1) Technical — 35-45 min on one skill with intent. '
        '(2) Conditioning — 12-18 min intervals matched to your fight pace. '
        '(3) Recovery — mobility and breathing to downshift. '
        'What are you training today and how did you sleep last night?',
  };

  return responses[persona] ?? responses[SamuraiPersona.shido]!;
}

String _getFearResponse(SamuraiPersona persona) {
  const responses = {
    SamuraiPersona.shido:
        'Pre-competition nerves are a sign your system is preparing for output. '
        'Physiologically it is the same as excitement — only the label changes. '
        'Breathing protocol: 4 seconds in, 2 hold, 6 out, for 2 minutes. '
        'Then visualize your first successful exchange, not the outcome. '
        'What specifically are you nervous about?',
  };

  return responses[persona] ?? responses[SamuraiPersona.shido]!;
}

String _getRecoveryResponse(SamuraiPersona persona) {
  const responses = {
    SamuraiPersona.shido:
        'Recovery is where adaptation happens. Your muscles, CNS, and '
        'connective tissue grow stronger during rest, not during the session. '
        'Prioritize: (1) sleep quality and duration, (2) hydration and protein timing '
        'within 90 min post-session, (3) active recovery like walking or light mobility. '
        'How many hours did you sleep and what does your soreness level look like?',
    SamuraiPersona.posterboy:
        'Rest day = gains day in disguise! 🎨 Your muscles are '
        'literally getting stronger while you chill. Science, baby! Now go take a nap '
        'and dream of victory. I\'ll be here when you wake up!',
  };

  return responses[persona] ?? responses[SamuraiPersona.shido]!;
}

String _getGreetingResponse(SamuraiPersona persona) {
  const responses = {
    SamuraiPersona.shido:
        'Hey. What are you working on right now? Training, fight prep, '
        'recovery — give me a direction and I will give you something useful.',
    SamuraiPersona.posterboy:
        'Yo! 🎨 Creative mode is live. What do you want to make?',
    SamuraiPersona.general: 'Hey. What do you need today?',
  };
  return responses[persona] ?? responses[SamuraiPersona.general]!;
}

String _getMetaResponse(SamuraiPersona persona) {
  const responses = {
    SamuraiPersona.shido:
        'I am Samurai Shido — the coaching brain behind DataFightCentral. '
        'I handle training structure, fight strategy, recovery science, weight '
        'management, conditioning, mental performance, injury rehab, and mobility. '
        'I am not a chatbot giving you motivational quotes. '
        'Give me specifics and I will give you a plan.',
    SamuraiPersona.posterboy:
        'I am PosterBoy — DFC\'s creative engine. I design fight posters, '
        'memes, cards, and visual hype. Give me an idea and I will make it look sick.',
    SamuraiPersona.general: 'SamurAI — unified intelligence for combat sports. What do you need?',
  };
  return responses[persona] ?? responses[SamuraiPersona.general]!;
}

String _getWisdomQuote(SamuraiPersona persona, [String? topic]) {
  final wisdomBank = <String, List<String>>{
    'motivation': [
      '"Fear is not weakness — it is fuel. The question is whether you burn it or let it burn you."',
      '"Every sunrise is a round you get to fight. Make it count."',
      '"Today is victory over yourself of yesterday." — Miyamoto Musashi',
      '"The impediment to action advances action. What stands in the way becomes the way." — Marcus Aurelius',
    ],
    'technique': [
      '"Flow like water — formless, shapeless, unstoppable. Adapt to every challenge."',
      '"Your mind is your strongest weapon — but only if you keep it sharp and open."',
      '"Take what works, discard what does not. Evolution is the fighter\'s way."',
      '"Mastery is not doing many things — it is doing one thing with absolute precision."',
    ],
    'recovery': [
      '"Rest is a weapon. The body grows stronger not through training, but through recovery."',
      '"Champions are made when no one is watching."',
      '"The strong do what they must, and the wise do what they should."',
    ],
    'fear': [
      '"Fear is fire. It can warm you or burn you."',
      '"Courage is not the absence of fear, but the judgment that something is more important than fear."',
      '"You gain strength, courage, and confidence by every experience in which you stop to look fear in the face."',
    ],
    'defeat': [
      '"Only a man who knows what it is like to be defeated can reach down to the bottom of his soul and come back."',
      '"Fall seven times, stand up eight." — Japanese proverb',
      '"The master has failed more times than the beginner has even tried."',
    ],
  };

  // Select appropriate topic
  final topicLower = (topic ?? 'motivation').toLowerCase();
  final quotes = wisdomBank.entries
      .firstWhere(
        (e) => topicLower.contains(e.key),
        orElse: () => wisdomBank.entries.first,
      )
      .value;

  // Return random quote from topic
  return quotes[(DateTime.now().millisecond % quotes.length)];
}
