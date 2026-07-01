/// ═══════════════════════════════════════════════════════════════════════════
///
///   ███████╗ █████╗ ███╗   ███╗██╗   ██╗██████╗  █████╗ ██╗
///   ██╔════╝██╔══██╗████╗ ████║██║   ██║██╔══██╗██╔══██╗██║
///   ███████╗███████║██╔████╔██║██║   ██║██████╔╝███████║██║
///   ╚════██║██╔══██║██║╚██╔╝██║██║   ██║██╔══██╗██╔══██║██║
///   ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║  ██║██║  ██║██║
///   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
///
///   UNIFIED AI ORCHESTRATOR
///   The World's Most Intelligent Fight & Wellness Intelligence
///
/// ═══════════════════════════════════════════════════════════════════════════
///
/// FORGED BY 45 YEARS OF FIGHTING KNOWLEDGE
/// BUILT FROM STRUGGLE • TEMPERED BY PAIN • RISEN FROM NOTHING
///
/// This orchestrator unifies ALL AI capabilities:
/// ├── SamurAI Core (emotional intelligence, compassion, wisdom)
/// ├── Quantum Optimizer (fight prediction, matchmaking, training)
/// ├── DFC Nexus (street wisdom, social intelligence, nutrition science)
/// ├── ESO Engine (fight commentary, analysis)
/// ├── Genies (Shido, PosterBoy)
/// └── Content Safety (moderation, protection)
///
/// INTELLIGENCE SOURCES:
/// ├── Facebook, TikTok, Twitter/X Pattern Analysis
/// ├── Quantum Computing & Physics Principles
/// ├── 45 Years Street-Tested Survival Wisdom
/// ├── Food as Medicine / Nutritional Science
/// ├── Graphs & Charts / Data Visualization AI
/// └── Extension Modules / Plugin Architecture
///
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'samurai_service.dart';
import 'quantum_optimization_service.dart';
import 'dfc_nexus.dart';
import 'samurai_core_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ORCHESTRATOR MODELS
/// ═══════════════════════════════════════════════════════════════════════════

/// Intent detected from user message
enum UserIntent {
  // Conversation
  greeting,
  farewell,
  gratitude,

  // Emotional
  seekingSupport,
  celebratingWin,
  processingLoss,
  anxious,
  motivated,

  // Fight-related
  fightAnalysis,
  fightPrediction,
  matchmakingQuery,
  techniqueQuestion,

  // Training
  trainingAdvice,
  nutritionAdvice,
  recoveryAdvice,
  injuryConsult,

  // Health & Wellness
  mentalHealthSupport,
  motivationNeeded,
  goalSetting,

  // Information
  generalQuestion,
  newsQuery,
  eventQuery,

  // App-related
  appHelp,
  featureRequest,

  // Unknown
  unknown,
}

/// Conversation context for multi-turn dialogue
class ConversationContext {
  final List<ChatMessage> history;
  final SamuraiPersona currentPersona;
  final EmotionalState? lastEmotionalState;
  final UserIntent? lastIntent;
  final Map<String, dynamic> sessionData;
  final DateTime sessionStart;

  ConversationContext({
    this.history = const [],
    this.currentPersona = SamuraiPersona.shido,
    this.lastEmotionalState,
    this.lastIntent,
    this.sessionData = const {},
    DateTime? sessionStart,
  }) : sessionStart = sessionStart ?? DateTime.now();

  ConversationContext copyWith({
    List<ChatMessage>? history,
    SamuraiPersona? currentPersona,
    EmotionalState? lastEmotionalState,
    UserIntent? lastIntent,
    Map<String, dynamic>? sessionData,
  }) {
    return ConversationContext(
      history: history ?? this.history,
      currentPersona: currentPersona ?? this.currentPersona,
      lastEmotionalState: lastEmotionalState ?? this.lastEmotionalState,
      lastIntent: lastIntent ?? this.lastIntent,
      sessionData: sessionData ?? this.sessionData,
      sessionStart: sessionStart,
    );
  }

  int get messageCount => history.length;
  Duration get sessionDuration => DateTime.now().difference(sessionStart);
  bool get isNewSession => messageCount == 0;
}

/// Chat message in conversation
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final SamuraiPersona? persona;
  final EmotionalState? emotionalState;
  final UserIntent? intent;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.persona,
    this.emotionalState,
    this.intent,
    this.metadata,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  bool get isSamurai => !isUser;
}

/// Orchestrated response with full context
class OrchestratedResponse {
  final String message;
  final SamuraiPersona respondingPersona;
  final EmotionalState? detectedEmotion;
  final UserIntent detectedIntent;
  final List<String>? suggestedFollowups;
  final Map<String, dynamic>? additionalData;
  final bool requiresEscalation;
  final String? escalationReason;

  const OrchestratedResponse({
    required this.message,
    required this.respondingPersona,
    this.detectedEmotion,
    required this.detectedIntent,
    this.suggestedFollowups,
    this.additionalData,
    this.requiresEscalation = false,
    this.escalationReason,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// SAMURAI ORCHESTRATOR - THE UNIFIED INTELLIGENCE
/// ═══════════════════════════════════════════════════════════════════════════

class SamuraiOrchestrator extends ChangeNotifier {
  static final SamuraiOrchestrator _instance = SamuraiOrchestrator._internal();
  factory SamuraiOrchestrator() => _instance;
  SamuraiOrchestrator._internal();

  // Sub-services - THE FULL POWERHOUSE
  final SamuraiService _samurai = SamuraiService();
  final QuantumOptimizationService _quantum = QuantumOptimizationService();
  final DfcNexus _nexus = DfcNexus();
  final SamuraiCoreEngine _core = SamuraiCoreEngine();

  // Expose Nexus for direct access
  DfcNexus get nexus => _nexus;
  SamuraiCoreEngine get core => _core;

  // State
  ConversationContext _context = ConversationContext();
  bool _isProcessing = false;
  bool _isInitialized = false;

  // Getters
  ConversationContext get context => _context;
  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;
  SamuraiPersona get currentPersona => _context.currentPersona;
  List<ChatMessage> get messages => _context.history;

  /// Initialize all AI systems
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('''
╔═══════════════════════════════════════════════════════════════════════════════════╗
║                                                                                   ║
║   ███████╗ █████╗ ███╗   ███╗██╗   ██╗██████╗  █████╗ ██╗    ██████╗ ███████╗██╗  ║
║   ██╔════╝██╔══██╗████╗ ████║██║   ██║██╔══██╗██╔══██╗██║    ██╔══██╗██╔════╝██║  ║
║   ███████╗███████║██╔████╔██║██║   ██║██████╔╝███████║██║    ██║  ██║█████╗  ██║  ║
║   ╚════██║██╔══██║██║╚██╔╝██║██║   ██║██╔══██╗██╔══██║██║    ██║  ██║██╔══╝  ██║  ║
║   ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝██║  ██║██║  ██║██║    ██████╔╝██║     ██║  ║
║   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═════╝ ╚═╝     ╚═╝  ║
║                                                                                   ║
║   ═══════════════════════════════════════════════════════════════════════════     ║
║   FORGED BY 45 YEARS OF FIGHTING KNOWLEDGE • BUILT FROM STRUGGLE                 ║
║   ═══════════════════════════════════════════════════════════════════════════     ║
║                                                                                   ║
║   LOADING THE WORLD'S MOST INTELLIGENT FIGHT & WELLNESS AI...                    ║
║                                                                                   ║
║   ├── SamurAI Core Intelligence                                                  ║
║   ├── Quantum Optimization Engine                                                ║
║   ├── DFC Nexus (Street Wisdom + Social Intel + Nutrition)                       ║
║   ├── Emotional Intelligence Layer                                               ║
║   ├── Multi-Persona System (7 Expert Guides)                                     ║
║   ├── Safety Guardian                                                            ║
║   ├── Graph/Chart Intelligence                                                   ║
║   └── Extension Plugin System                                                    ║
║                                                                                   ║
║   INTELLIGENCE SOURCES:                                                           ║
║   ├── 45 Years Fighting Knowledge (Street-Tested)                                ║
║   ├── Facebook, TikTok, Twitter/X Patterns                                       ║
║   ├── Quantum Physics Principles                                                 ║
║   ├── Food as Medicine / Nutritional Science                                     ║
║   └── Persistence & Resistance forged by Pain                                    ║
║                                                                                   ║
╚═══════════════════════════════════════════════════════════════════════════════════╝
''');

    // Initialize ALL sub-systems
    await Future.wait([
      _quantum.initialize(),
      _nexus.initialize(),
      _core.initialize(),
    ]);

    _isInitialized = true;
    notifyListeners();

    debugPrint(
      '   ✅ SamurAI DFC Orchestrator ONLINE - The World\'s Most Intelligent AI Ready',
    );
  }

  /// Switch to a different persona
  void switchPersona(SamuraiPersona persona) {
    _context = _context.copyWith(currentPersona: persona);
    notifyListeners();
  }

  /// Clear conversation history
  void clearConversation() {
    _context = ConversationContext(currentPersona: _context.currentPersona);
    notifyListeners();
  }

  /// Process user message and generate intelligent response
  Future<OrchestratedResponse> processMessage(String userMessage) async {
    if (!_isInitialized) await initialize();

    _isProcessing = true;
    notifyListeners();

    try {
      // Add user message to history
      final userChatMessage = ChatMessage(content: userMessage, isUser: true);

      final updatedHistory = [..._context.history, userChatMessage];
      _context = _context.copyWith(history: updatedHistory);
      notifyListeners();

      // Detect user intent
      final intent = _detectIntent(userMessage);

      // Select optimal persona for this intent
      final optimalPersona = _selectPersonaForIntent(intent);

      // Get SamurAI response
      final samuraiResponse = await _samurai.chat(
        userMessage,
        persona: optimalPersona,
      );

      // Build orchestrated response
      final response = OrchestratedResponse(
        message: samuraiResponse.response,
        respondingPersona: optimalPersona,
        detectedEmotion: samuraiResponse.emotionalState,
        detectedIntent: intent,
        suggestedFollowups: _generateFollowups(intent, samuraiResponse),
        additionalData: {'samuraiCore': _core.getExecutiveSummary()},
        requiresEscalation: samuraiResponse.safetyCheck.escalationNeeded,
        escalationReason: samuraiResponse.safetyCheck.escalationNeeded
            ? 'User may need professional support'
            : null,
      );

      // Add AI response to history
      final aiChatMessage = ChatMessage(
        content: response.message,
        isUser: false,
        persona: optimalPersona,
        emotionalState: samuraiResponse.emotionalState,
        intent: intent,
      );

      final finalHistory = [..._context.history, aiChatMessage];
      _context = _context.copyWith(
        history: finalHistory,
        lastEmotionalState: samuraiResponse.emotionalState,
        lastIntent: intent,
        currentPersona: optimalPersona,
      );

      return response;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Detect user intent from message
  UserIntent _detectIntent(String message) {
    final lower = message.toLowerCase();

    // Greeting patterns
    if (RegExp(
      r'^(hi|hey|hello|sup|yo|whats up|good morning|good evening|good afternoon)\b',
    ).hasMatch(lower)) {
      return UserIntent.greeting;
    }

    // Farewell patterns
    if (RegExp(
      r'\b(bye|goodbye|later|see you|gotta go|peace out|talk later)\b',
    ).hasMatch(lower)) {
      return UserIntent.farewell;
    }

    // Gratitude
    if (RegExp(r'\b(thank|thanks|appreciate|grateful)\b').hasMatch(lower)) {
      return UserIntent.gratitude;
    }

    // Emotional support
    if (RegExp(
      r'\b(sad|depressed|anxious|stressed|worried|scared|afraid|nervous|upset|angry|frustrated)\b',
    ).hasMatch(lower)) {
      return UserIntent.seekingSupport;
    }

    // Mental health
    if (RegExp(
      r'\b(mental health|therapy|counselor|suicidal|self-harm|hate myself|give up|hopeless)\b',
    ).hasMatch(lower)) {
      return UserIntent.mentalHealthSupport;
    }

    // Celebrating
    if (RegExp(
      r'\b(won|victory|beat|defeated|champion|first place|medal|title)\b',
    ).hasMatch(lower)) {
      return UserIntent.celebratingWin;
    }

    // Processing loss
    if (RegExp(
      r'\b(lost|loss|defeat|failed|came up short|didnt win|eliminated)\b',
    ).hasMatch(lower)) {
      return UserIntent.processingLoss;
    }

    // Fight analysis/prediction
    if (RegExp(
      r'\b(fight|bout|vs|versus|match|predict|who wins|analysis|breakdown)\b',
    ).hasMatch(lower)) {
      if (lower.contains('predict') ||
          lower.contains('who wins') ||
          lower.contains('think')) {
        return UserIntent.fightPrediction;
      }
      return UserIntent.fightAnalysis;
    }

    // Training
    if (RegExp(
      r'\b(train|training|workout|exercise|drill|spar|sparring|conditioning)\b',
    ).hasMatch(lower)) {
      return UserIntent.trainingAdvice;
    }

    // Technique
    if (RegExp(
      r'\b(technique|how to|jab|cross|hook|uppercut|kick|takedown|submission|guard|mount)\b',
    ).hasMatch(lower)) {
      return UserIntent.techniqueQuestion;
    }

    // Nutrition
    if (RegExp(
      r'\b(diet|eat|food|nutrition|weight cut|weight class|calories|protein|meal)\b',
    ).hasMatch(lower)) {
      return UserIntent.nutritionAdvice;
    }

    // Recovery
    if (RegExp(
      r'\b(recover|rest|sleep|sore|tired|fatigue|ice bath|massage)\b',
    ).hasMatch(lower)) {
      return UserIntent.recoveryAdvice;
    }

    // Injury
    if (RegExp(
      r'\b(injury|injured|hurt|pain|doctor|broken|sprain|strain)\b',
    ).hasMatch(lower)) {
      return UserIntent.injuryConsult;
    }

    // Motivation
    if (RegExp(
      r'\b(motivate|motivation|inspire|push|keep going|give up|quit|cant do)\b',
    ).hasMatch(lower)) {
      return UserIntent.motivationNeeded;
    }

    // Goals
    if (RegExp(
      r'\b(goal|goals|want to|dream|ambition|plan|future)\b',
    ).hasMatch(lower)) {
      return UserIntent.goalSetting;
    }

    // App help
    if (RegExp(
      r'\b(app|feature|button|screen|how do i|where is|help me)\b',
    ).hasMatch(lower)) {
      return UserIntent.appHelp;
    }

    // News/events
    if (RegExp(
      r'\b(news|event|card|upcoming|schedule|ufc|bellator|one fc|pfl)\b',
    ).hasMatch(lower)) {
      return UserIntent.eventQuery;
    }

    return UserIntent.generalQuestion;
  }

  /// Select optimal persona for detected intent
  SamuraiPersona _selectPersonaForIntent(UserIntent intent) {
    switch (intent) {
      // Shido - General guidance, greeting, farewell
      case UserIntent.greeting:
      case UserIntent.farewell:
      case UserIntent.gratitude:
      case UserIntent.generalQuestion:
      case UserIntent.appHelp:
        return SamuraiPersona.shido;

      // Shido - Training, technique, motivation
      case UserIntent.trainingAdvice:
      case UserIntent.techniqueQuestion:
      case UserIntent.motivationNeeded:
        return SamuraiPersona.shido;

      // Shido - Emotional support, mental health, processing loss
      case UserIntent.seekingSupport:
      case UserIntent.mentalHealthSupport:
      case UserIntent.processingLoss:
      case UserIntent.anxious:
        return SamuraiPersona.shido;

      // Shido - Celebrating, confidence, victory
      case UserIntent.celebratingWin:
      case UserIntent.motivated:
        return SamuraiPersona.shido;

      // Shido - Philosophy, technique, self-improvement
      case UserIntent.goalSetting:
        return SamuraiPersona.shido;

      // PosterBoy - Fight analysis, predictions, events
      case UserIntent.fightAnalysis:
      case UserIntent.fightPrediction:
      case UserIntent.matchmakingQuery:
      case UserIntent.eventQuery:
      case UserIntent.newsQuery:
        return SamuraiPersona.posterboy;

      // Shido for health-related
      case UserIntent.nutritionAdvice:
      case UserIntent.recoveryAdvice:
      case UserIntent.injuryConsult:
        return SamuraiPersona.shido;

      // Feature requests go to Shido
      case UserIntent.featureRequest:
        return SamuraiPersona.shido;

      // Default to Shido
      case UserIntent.unknown:
        return SamuraiPersona.shido;
    }
  }

  /// Generate follow-up suggestions based on context
  List<String> _generateFollowups(UserIntent intent, SamuraiResponse response) {
    switch (intent) {
      case UserIntent.greeting:
        return [
          "Tell me about your training goals",
          "What's been on your mind?",
          "Show me upcoming fights",
        ];

      case UserIntent.trainingAdvice:
        return [
          "How should I structure my week?",
          "What about recovery?",
          "Give me a specific drill",
        ];

      case UserIntent.fightAnalysis:
      case UserIntent.fightPrediction:
        return [
          "Who else should fight?",
          "What's the best strategy?",
          "Show me the stats",
        ];

      case UserIntent.seekingSupport:
      case UserIntent.processingLoss:
        return ["Tell me more", "What helps you cope?", "Give me some wisdom"];

      case UserIntent.motivationNeeded:
        return [
          "I need a push",
          "Tell me about a comeback story",
          "What would Cus say?",
        ];

      default:
        return ["Tell me more", "What else?", "Help me with something else"];
    }
  }

  /// Get a quick motivational message
  Future<String> getQuickMotivation() async {
    final response = _samurai.getWisdom(topic: 'motivation');
    return response;
  }

  /// Get fight prediction using quantum optimizer
  FightProbabilities predictFight(
    QuantumFighterProfile fighter1,
    QuantumFighterProfile fighter2,
  ) {
    return _quantum.predictFight(fighter1, fighter2);
  }

  /// Find optimal matchups
  List<MatchQuality> findOptimalMatches(
    QuantumFighterProfile fighter,
    List<QuantumFighterProfile> pool, {
    int topN = 5,
  }) {
    return _quantum.findOptimalMatches(fighter, pool, topN: topN);
  }

  /// Get training optimization
  TrainingOptimization optimizeTraining({
    required double currentRecovery,
    required int daysUntilFight,
    required double recentTrainingLoad,
    required double fatigueLevel,
    double? sleepQuality,
    double? stressLevel,
    List<String>? injuries,
  }) {
    return _quantum.optimizeTraining(
      currentRecovery: currentRecovery,
      daysUntilFight: daysUntilFight,
      recentTrainingLoad: recentTrainingLoad,
      fatigueLevel: fatigueLevel,
      sleepQuality: sleepQuality,
      stressLevel: stressLevel,
      injuries: injuries,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DFC NEXUS INTEGRATION - FULL POWERHOUSE ACCESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get street wisdom (45 years of battle-forged knowledge)
  StreetWisdom getStreetWisdom({StreetWisdomCategory? category}) {
    return _nexus.getStreetWisdom(category: category);
  }

  /// Get nutrition recommendation (food as medicine)
  NutritionIntelligence getNutritionRecommendation({String? forCondition}) {
    return _nexus.getNutritionRecommendation(forCondition: forCondition);
  }

  /// Get social media insight (TikTok, Twitter/X, Facebook patterns)
  SocialInsight getSocialInsight({String? platform, SocialPattern? pattern}) {
    return _nexus.getSocialInsight(platform: platform, pattern: pattern);
  }

  /// Make quantum-inspired decision
  QuantumDecision makeQuantumDecision({
    required String question,
    required List<String> options,
  }) {
    return _nexus.makeQuantumDecision(question: question, options: options);
  }

  /// Analyze data for visualization
  DataVisualizationInsight analyzeForVisualization({
    required String dataType,
    required Map<String, double> metrics,
  }) {
    return _nexus.analyzeForVisualization(dataType: dataType, metrics: metrics);
  }

  /// Full Nexus query - auto-selects appropriate modules
  Future<NexusResponse> queryNexus({required String question}) {
    return _nexus.query(question: question);
  }

  /// Get recovery foods
  List<NutritionIntelligence> getRecoveryFoods({int count = 5}) {
    return _nexus.getRecoveryFoods(count: count);
  }

  /// Get hardest lessons (highest hardship level)
  List<StreetWisdom> getHardestLessons({int count = 5}) {
    return _nexus.getHardestLessons(count: count);
  }

  /// Get complete platform strategy
  List<SocialInsight> getPlatformStrategy(String platform) {
    return _nexus.getPlatformStrategy(platform);
  }

  /// Build a fighter's meal plan
  Map<String, NutritionIntelligence> buildFighterMealPlan() {
    return _nexus.buildFighterMealPlan();
  }
}
