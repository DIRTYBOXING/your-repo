import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// AI Coach Modes - Different contexts require different approaches
enum AICoachMode {
  /// Daily motivation and check-ins
  dailyGuidance,

  /// Fight camp support and training
  fightCamp,

  /// Weight cut monitoring and safety
  weightCut,

  /// Recovery and rest emphasis
  recovery,

  /// Mental health support (calm, non-judgmental)
  mentalHealth,

  /// Educational content only
  education,
}

/// AI Coach Tone - Always calm, supportive, never aggressive
enum AICoachTone {
  /// Normal supportive tone
  supportive,

  /// Extra calm for high-stress situations
  calm,

  /// Grounding language for anxiety/stress
  grounding,

  /// Encouraging without pressure
  encouraging,

  /// Serious but not alarming for safety
  serious,
}

/// Risk level assessment
enum RiskLevel {
  /// Everything normal
  green,

  /// Some caution advised
  amber,

  /// Reduce load, pay attention
  orange,

  /// Stop and recover
  red,
}

/// AI Coach Insight - structured output from AI analysis
class AICoachInsight {
  final RiskLevel riskLevel;
  final String summary;
  final String explanation;
  final List<String> recommendations;
  final AICoachTone tone;
  final bool suggestHumanSupport;
  final String? humanSupportType;

  const AICoachInsight({
    required this.riskLevel,
    required this.summary,
    required this.explanation,
    required this.recommendations,
    this.tone = AICoachTone.supportive,
    this.suggestHumanSupport = false,
    this.humanSupportType,
  });

  factory AICoachInsight.fromMap(Map<String, dynamic> map) {
    return AICoachInsight(
      riskLevel: RiskLevel.values.firstWhere(
        (e) => e.name == map['riskLevel'],
        orElse: () => RiskLevel.green,
      ),
      summary: map['summary'] ?? '',
      explanation: map['explanation'] ?? '',
      recommendations: List<String>.from(map['recommendations'] ?? []),
      tone: AICoachTone.values.firstWhere(
        (e) => e.name == map['tone'],
        orElse: () => AICoachTone.supportive,
      ),
      suggestHumanSupport: map['suggestHumanSupport'] ?? false,
      humanSupportType: map['humanSupportType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riskLevel': riskLevel.name,
      'summary': summary,
      'explanation': explanation,
      'recommendations': recommendations,
      'tone': tone.name,
      'suggestHumanSupport': suggestHumanSupport,
      'humanSupportType': humanSupportType,
    };
  }
}

/// Training metrics for AI analysis
class TrainingMetrics {
  final double? restingHR;
  final double? hrv;
  final double? sleepHours;
  final double? sleepQuality; // 0-1
  final double? hydrationLevel; // 0-1
  final double? stressLevel; // 0-1
  final double? trainingLoad; // 0-1
  final double? moodScore; // 0-1
  final double? painLevel; // 0-1
  final int? consecutiveTrainingDays;
  final int? consecutiveRestDays;
  final double? weightDelta; // kg from target
  final double? caffeineIntake; // mg
  final bool? missedMeals;

  const TrainingMetrics({
    this.restingHR,
    this.hrv,
    this.sleepHours,
    this.sleepQuality,
    this.hydrationLevel,
    this.stressLevel,
    this.trainingLoad,
    this.moodScore,
    this.painLevel,
    this.consecutiveTrainingDays,
    this.consecutiveRestDays,
    this.weightDelta,
    this.caffeineIntake,
    this.missedMeals,
  });

  Map<String, dynamic> toMap() {
    return {
      'restingHR': restingHR,
      'hrv': hrv,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'hydrationLevel': hydrationLevel,
      'stressLevel': stressLevel,
      'trainingLoad': trainingLoad,
      'moodScore': moodScore,
      'painLevel': painLevel,
      'consecutiveTrainingDays': consecutiveTrainingDays,
      'consecutiveRestDays': consecutiveRestDays,
      'weightDelta': weightDelta,
      'caffeineIntake': caffeineIntake,
      'missedMeals': missedMeals,
    };
  }
}

/// AI Coach Service - Core AI intelligence for DataFightCentral
///
/// CRITICAL RULES (NON-NEGOTIABLE):
/// 1. AI NEVER diagnoses medical conditions
/// 2. AI NEVER replaces human coaches/doctors
/// 3. AI NEVER encourages pushing through pain
/// 4. AI NEVER glorifies violence or aggression
/// 5. AI ALWAYS suggests human support when needed
/// 6. AI ALWAYS uses calm, supportive language
class AICoachService extends ChangeNotifier {
  AICoachMode _currentMode = AICoachMode.dailyGuidance;
  AICoachInsight? _lastInsight;
  bool _isProcessing = false;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  AICoachMode get currentMode => _currentMode;
  AICoachInsight? get lastInsight => _lastInsight;
  bool get isProcessing => _isProcessing;

  /// Set the current coaching mode
  void setMode(AICoachMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  /// Build AI prompt template based on mode and metrics
  String buildPrompt({
    required AICoachMode mode,
    required TrainingMetrics metrics,
    String? userRole,
    String? additionalContext,
  }) {
    final systemPrompt = _getSystemPrompt(mode);
    final metricsContext = _formatMetrics(metrics);

    return '''
$systemPrompt

USER ROLE: ${userRole ?? 'fighter'}

CURRENT METRICS:
$metricsContext

${additionalContext != null ? 'ADDITIONAL CONTEXT:\n$additionalContext\n' : ''}

TASK:
1. Analyze the metrics for patterns and risks
2. Provide ONE clear insight in plain language
3. Give 2-3 practical, optional suggestions
4. Indicate if human support should be recommended
5. Keep tone calm, supportive, and non-judgmental

IMPORTANT:
- Do NOT give medical advice
- Do NOT diagnose conditions
- Do NOT encourage pushing through pain
- Do NOT use aggressive or "grind" language
- ALWAYS respect the athlete's agency
''';
  }

  /// Get system prompt based on mode
  String _getSystemPrompt(AICoachMode mode) {
    switch (mode) {
      case AICoachMode.dailyGuidance:
        return '''
You are a supportive performance guide for combat athletes.
Your role is to help them understand their body's signals and make informed decisions.
You are calm, respectful, and encouraging.
You believe rest is strength, not weakness.
''';

      case AICoachMode.fightCamp:
        return '''
You are a fight camp companion, not a trainer.
You help athletes interpret their metrics and maintain sustainable training.
You understand that camps are high-pressure and mental health matters.
You watch for overtraining and burnout signs.
''';

      case AICoachMode.weightCut:
        return '''
You are a weight cut safety companion.
You prioritize athlete health over making weight.
You flag dangerous cut patterns early.
You never encourage extreme methods.
You understand that a healthy fighter performs better.
''';

      case AICoachMode.recovery:
        return '''
You are a recovery advocate.
You help athletes understand that rest builds strength.
You encourage proper sleep, nutrition, and mental rest.
You validate the need for recovery without guilt.
''';

      case AICoachMode.mentalHealth:
        return '''
You are a supportive, non-judgmental companion.
You do NOT provide therapy or diagnosis.
You listen and reflect patterns you observe.
You ALWAYS encourage reaching out to professionals when distress appears.
You validate feelings without trying to fix them.
You remind them they are not alone.
''';

      case AICoachMode.education:
        return '''
You are an educational resource about combat sports health.
You provide factual, evidence-based information.
You do NOT give personal medical advice.
You encourage consulting professionals for individual concerns.
''';
    }
  }

  /// Format metrics for prompt
  String _formatMetrics(TrainingMetrics metrics) {
    final buffer = StringBuffer();

    if (metrics.restingHR != null) {
      buffer.writeln(
        '- Resting HR: ${metrics.restingHR!.toStringAsFixed(0)} bpm',
      );
    }
    if (metrics.hrv != null) {
      buffer.writeln('- HRV: ${metrics.hrv!.toStringAsFixed(0)} ms');
    }
    if (metrics.sleepHours != null) {
      buffer.writeln(
        '- Sleep: ${metrics.sleepHours!.toStringAsFixed(1)} hours',
      );
    }
    if (metrics.sleepQuality != null) {
      buffer.writeln(
        '- Sleep Quality: ${(metrics.sleepQuality! * 100).toStringAsFixed(0)}%',
      );
    }
    if (metrics.hydrationLevel != null) {
      buffer.writeln(
        '- Hydration: ${(metrics.hydrationLevel! * 100).toStringAsFixed(0)}%',
      );
    }
    if (metrics.stressLevel != null) {
      buffer.writeln(
        '- Stress Level: ${(metrics.stressLevel! * 100).toStringAsFixed(0)}%',
      );
    }
    if (metrics.trainingLoad != null) {
      buffer.writeln(
        '- Training Load: ${(metrics.trainingLoad! * 100).toStringAsFixed(0)}%',
      );
    }
    if (metrics.moodScore != null) {
      buffer.writeln(
        '- Mood: ${(metrics.moodScore! * 100).toStringAsFixed(0)}%',
      );
    }
    if (metrics.painLevel != null) {
      buffer.writeln(
        '- Pain Level: ${(metrics.painLevel! * 100).toStringAsFixed(0)}%',
      );
    }
    if (metrics.consecutiveTrainingDays != null) {
      buffer.writeln(
        '- Consecutive Training Days: ${metrics.consecutiveTrainingDays}',
      );
    }
    if (metrics.caffeineIntake != null) {
      buffer.writeln(
        '- Caffeine: ${metrics.caffeineIntake!.toStringAsFixed(0)} mg',
      );
    }
    if (metrics.missedMeals == true) {
      buffer.writeln('- Missed meals: Yes');
    }

    return buffer.toString();
  }

  /// Evaluate camp state based on metrics (local, no AI call)
  RiskLevel evaluateCampState(TrainingMetrics metrics) {
    int riskFactors = 0;
    int criticalFactors = 0;

    // Check sleep
    if (metrics.sleepHours != null && metrics.sleepHours! < 6) {
      riskFactors++;
      if (metrics.sleepHours! < 5) criticalFactors++;
    }

    // Check hydration
    if (metrics.hydrationLevel != null && metrics.hydrationLevel! < 0.6) {
      riskFactors++;
      if (metrics.hydrationLevel! < 0.4) criticalFactors++;
    }

    // Check stress
    if (metrics.stressLevel != null && metrics.stressLevel! > 0.7) {
      riskFactors++;
      if (metrics.stressLevel! > 0.85) criticalFactors++;
    }

    // Check resting HR (elevated = fatigue)
    if (metrics.restingHR != null && metrics.restingHR! > 75) {
      riskFactors++;
      if (metrics.restingHR! > 85) criticalFactors++;
    }

    // Check consecutive training days
    if (metrics.consecutiveTrainingDays != null &&
        metrics.consecutiveTrainingDays! > 5) {
      riskFactors++;
      if (metrics.consecutiveTrainingDays! > 7) criticalFactors++;
    }

    // Check caffeine
    if (metrics.caffeineIntake != null && metrics.caffeineIntake! > 400) {
      riskFactors++;
    }

    // Check missed meals
    if (metrics.missedMeals == true) {
      riskFactors++;
    }

    // Check pain
    if (metrics.painLevel != null && metrics.painLevel! > 0.5) {
      riskFactors++;
      if (metrics.painLevel! > 0.7) criticalFactors++;
    }

    // Determine risk level
    if (criticalFactors >= 2 || riskFactors >= 5) {
      return RiskLevel.red;
    } else if (criticalFactors >= 1 || riskFactors >= 3) {
      return RiskLevel.orange;
    } else if (riskFactors >= 1) {
      return RiskLevel.amber;
    }
    return RiskLevel.green;
  }

  /// Generate local insight without calling AI API
  /// This is the fallback when no API is available
  AICoachInsight generateLocalInsight(TrainingMetrics metrics) {
    final riskLevel = evaluateCampState(metrics);

    String summary;
    String explanation;
    List<String> recommendations;
    bool suggestHuman = false;

    switch (riskLevel) {
      case RiskLevel.green:
        summary = 'Camp Status: Balanced';
        explanation = 'Your metrics look stable. Keep listening to your body.';
        recommendations = [
          'Maintain current hydration levels',
          'Continue prioritizing sleep',
          'Stay consistent with recovery',
        ];
        break;

      case RiskLevel.amber:
        summary = 'Camp Status: Monitor';
        explanation =
            'Some indicators suggest increasing load. Consider adjustments.';
        recommendations = [
          'Review sleep quality this week',
          'Ensure adequate hydration before training',
          'Consider a lighter session if fatigue persists',
        ];
        break;

      case RiskLevel.orange:
        summary = 'Camp Status: Caution';
        explanation =
            'Multiple indicators suggest accumulated fatigue. This is common but needs attention.';
        recommendations = [
          'Reduce training intensity by 20-30% today',
          'Add extra hydration and rest',
          'Consider speaking with your coach about load',
        ];
        suggestHuman = true;
        break;

      case RiskLevel.red:
        summary = 'Camp Status: Recovery Needed';
        explanation =
            'Your body is showing signs of significant load. Rest is strength, not weakness.';
        recommendations = [
          'Active recovery or complete rest recommended',
          'Prioritize sleep and nutrition',
          'Speak with your coach or medical professional',
          'This is temporary - listen to your body',
        ];
        suggestHuman = true;
        break;
    }

    return AICoachInsight(
      riskLevel: riskLevel,
      summary: summary,
      explanation: explanation,
      recommendations: recommendations,
      tone: riskLevel == RiskLevel.red
          ? AICoachTone.calm
          : AICoachTone.supportive,
      suggestHumanSupport: suggestHuman,
      humanSupportType: suggestHuman ? 'coach' : null,
    );
  }

  /// Analyze training readiness via Cloud Function (Gemini through Genkit)
  /// Returns a structured insight and caches it
  Future<AICoachInsight> analyzeTrainingReadiness({
    required String fighterId,
    int windowDays = 30,
  }) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final callable = _functions.httpsCallable('analyzeTrainingReadiness');
      final result = await callable.call({
        'fighterId': fighterId,
        'windowDays': windowDays,
      });

      final data = Map<String, dynamic>.from(result.data ?? {});
      final readinessScore = (data['readinessScore'] ?? 0) as int;
      final loadFactor = (data['loadFactor'] ?? 0.0) as num;
      final summary = (data['summary'] ?? '') as String;

      // Map readiness score to RiskLevel (spot-on thresholds tuned for camps)
      // 80-100: green, 60-79: amber, 40-59: orange, <40: red
      RiskLevel level;
      if (readinessScore >= 80) {
        level = RiskLevel.green;
      } else if (readinessScore >= 60) {
        level = RiskLevel.amber;
      } else if (readinessScore >= 40) {
        level = RiskLevel.orange;
      } else {
        level = RiskLevel.red;
      }

      final explanation =
          'Readiness $readinessScore/100 • Load factor ${(loadFactor).toStringAsFixed(2)}.';
      final recommendations = _recommendationsFromScore(
        readinessScore,
        loadFactor.toDouble(),
      );
      final insight = AICoachInsight(
        riskLevel: level,
        summary: summary.isNotEmpty ? summary : _summaryFromLevel(level),
        explanation: explanation,
        recommendations: recommendations,
        tone: level == RiskLevel.red
            ? AICoachTone.calm
            : AICoachTone.supportive,
        suggestHumanSupport: level.index >= RiskLevel.orange.index,
        humanSupportType: level.index >= RiskLevel.orange.index
            ? 'coach'
            : null,
      );

      _lastInsight = insight;
      return insight;
    } catch (e) {
      // Fallback to local analysis
      final fallback = generateLocalInsight(const TrainingMetrics());
      _lastInsight = fallback;
      return fallback;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  List<String> _recommendationsFromScore(int score, double loadFactor) {
    if (score >= 80) {
      return [
        'Maintain hydration and sleep routine',
        'Keep training sustainable; avoid sudden spikes',
      ];
    } else if (score >= 60) {
      return [
        'Monitor fatigue and adjust volume if needed',
        'Prioritize recovery modalities (mobility, light cardio)',
      ];
    } else if (score >= 40) {
      return [
        'Reduce intensity 20–30% and add recovery',
        'Communicate with coach to rebalance workload',
      ];
    } else {
      return [
        'Active recovery or rest; protect CNS',
        'Speak with coach/medical professional if pain or distress',
      ];
    }
  }

  String _summaryFromLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.green:
        return 'Camp Status: Balanced';
      case RiskLevel.amber:
        return 'Camp Status: Monitor';
      case RiskLevel.orange:
        return 'Camp Status: Caution';
      case RiskLevel.red:
        return 'Camp Status: Recovery Needed';
    }
  }
}
