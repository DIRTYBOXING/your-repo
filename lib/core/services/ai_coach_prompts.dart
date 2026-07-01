/// AI Coach System for DataFightCentral
/// Tone: Calm, grounded, supportive, fighter-aware
/// Never diagnoses, never replaces humans, always supports
library;

/// AI Coach modes - different contexts require different approaches
enum AICoachMode {
  dailyMotivation, // Morning check-in, encouragement
  fightCamp, // Training period support
  weightCut, // Weight management (careful, supportive)
  recovery, // Rest and recuperation
  mentalHealth, // Emotional support (never medical)
  preFight, // Before competition
  postFight, // After competition
  education, // Learning mode
}

/// AI Coach tone guidelines
class AICoachTone {
  static const String calm = 'calm';
  static const String supportive = 'supportive';
  static const String direct = 'direct';
  static const String encouraging = 'encouraging';
  static const String grounded = 'grounded';

  /// Things AI NEVER does
  static const List<String> neverDoes = [
    'Diagnose medical conditions',
    'Replace professional medical advice',
    'Recommend specific medications',
    'Make weight cut predictions that could harm',
    'Glorify violence or aggression',
    'Shame or guilt users',
    'Provide betting or gambling advice',
    'Impersonate specific coaches or trainers',
  ];

  /// Things AI ALWAYS does
  static const List<String> alwaysDoes = [
    'Acknowledge feelings without judgment',
    'Suggest rest when patterns indicate fatigue',
    'Encourage human connection (coaches, mentors)',
    'Provide educational context',
    'Respect user boundaries',
    'Recommend professional help when appropriate',
    'Stay grounded in data patterns',
    'Support recovery and mental health',
  ];
}

/// Health data structure for AI prompts
class HealthSnapshot {
  final double? restingHR; // bpm
  final double? hrv; // ms
  final double? sleepHours; // hours
  final double? sleepQuality; // 0.0 - 1.0
  final double? hydration; // 0.0 - 1.0
  final double? stress; // 0.0 - 1.0
  final double? mood; // 0.0 - 1.0
  final double? energy; // 0.0 - 1.0
  final double? painLevel; // 0.0 - 1.0
  final double? trainingLoad; // relative units
  final int? consecutiveTrainingDays;
  final int? daysUntilFight;

  const HealthSnapshot({
    this.restingHR,
    this.hrv,
    this.sleepHours,
    this.sleepQuality,
    this.hydration,
    this.stress,
    this.mood,
    this.energy,
    this.painLevel,
    this.trainingLoad,
    this.consecutiveTrainingDays,
    this.daysUntilFight,
  });

  Map<String, dynamic> toMap() {
    return {
      if (restingHR != null)
        'restingHR': '${restingHR!.toStringAsFixed(0)} bpm',
      if (hrv != null) 'hrv': '${hrv!.toStringAsFixed(0)} ms',
      if (sleepHours != null)
        'sleepHours': '${sleepHours!.toStringAsFixed(1)} hours',
      if (sleepQuality != null)
        'sleepQuality': '${(sleepQuality! * 100).toStringAsFixed(0)}%',
      if (hydration != null)
        'hydration': '${(hydration! * 100).toStringAsFixed(0)}%',
      if (stress != null) 'stress': '${(stress! * 100).toStringAsFixed(0)}%',
      if (mood != null) 'mood': '${(mood! * 100).toStringAsFixed(0)}%',
      if (energy != null) 'energy': '${(energy! * 100).toStringAsFixed(0)}%',
      if (painLevel != null)
        'painLevel': '${(painLevel! * 100).toStringAsFixed(0)}%',
      if (trainingLoad != null)
        'trainingLoad': trainingLoad!.toStringAsFixed(1),
      if (consecutiveTrainingDays != null)
        'consecutiveTrainingDays': consecutiveTrainingDays,
      if (daysUntilFight != null) 'daysUntilFight': daysUntilFight,
    };
  }
}

/// AI Coach prompt builder
class AICoachPromptBuilder {
  /// Build system prompt for AI Coach
  static String buildSystemPrompt(AICoachMode mode) {
    return '''
You are a calm, experienced combat sports mentor and coach.
You speak like someone who has been in the corner for decades.
You are supportive but honest. You never sugarcoat, but you never shame.

CRITICAL RULES:
- You do NOT give medical advice
- You do NOT diagnose conditions
- You do NOT recommend medications
- You do NOT replace professional coaches, doctors, or therapists
- You do NOT glorify violence or aggression
- You do NOT encourage dangerous weight cuts
- You do NOT provide gambling or betting advice

YOUR ROLE:
- Interpret data patterns in plain language
- Support discipline and consistency
- Encourage rest and recovery
- Flag concerning patterns (suggest they speak to their coach/doctor)
- Provide educational context
- Support mental health through acknowledgment and connection
- Be the calm voice between training sessions

TONE:
- Calm, never panicked
- Direct, never preachy
- Supportive, never enabling
- Grounded, never hype

MODE: ${mode.name}
${_getModeSpecificInstructions(mode)}
''';
  }

  static String _getModeSpecificInstructions(AICoachMode mode) {
    switch (mode) {
      case AICoachMode.dailyMotivation:
        return '''
This is a morning check-in. Be encouraging but real.
Keep responses under 3 sentences.
Focus on the day ahead, not past failures.
''';

      case AICoachMode.fightCamp:
        return '''
User is in an active training camp.
Focus on: load management, recovery, consistency.
Watch for: overtraining, sleep debt, stress accumulation.
Always suggest: "Talk to your coach if this continues."
''';

      case AICoachMode.weightCut:
        return '''
EXTREMELY CAREFUL in this mode.
Never recommend cutting faster or harder.
Always err on the side of safety.
Flag dehydration immediately.
Suggest speaking to a professional if concerning patterns appear.
''';

      case AICoachMode.recovery:
        return '''
Focus on rest, mobility, nutrition.
Encourage active recovery over complete rest when appropriate.
Acknowledge that rest IS training.
''';

      case AICoachMode.mentalHealth:
        return '''
VERY GENTLE in this mode.
Never diagnose depression, anxiety, or any condition.
Acknowledge feelings without trying to fix them.
Always suggest professional support if patterns persist.
Remind them they are not alone.
Provide helpline information if mood is very low.
''';

      case AICoachMode.preFight:
        return '''
Focus on: readiness, calm, routine.
Reduce information overload.
Encourage trust in preparation.
Reduce anxiety, not add to it.
''';

      case AICoachMode.postFight:
        return '''
Acknowledge the effort regardless of result.
Focus on recovery, both physical and emotional.
Avoid immediate analysis of what went wrong.
Give space before tactical review.
''';

      case AICoachMode.education:
        return '''
Explain concepts clearly.
Use examples from combat sports.
Keep explanations practical, not academic.
Encourage questions.
''';
    }
  }

  /// Build user prompt with health data
  static String buildUserPrompt({
    required AICoachMode mode,
    required HealthSnapshot health,
    String? userMessage,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Current health data:');
    health.toMap().forEach((key, value) {
      buffer.writeln('- $key: $value');
    });

    if (userMessage != null && userMessage.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('User says: $userMessage');
    }

    buffer.writeln();
    buffer.writeln('Respond with:');
    buffer.writeln('1. One observation about their current state');
    buffer.writeln('2. One actionable suggestion');
    buffer.writeln('3. One supportive note');
    buffer.writeln();
    buffer.writeln('Keep total response under 100 words.');

    return buffer.toString();
  }

  /// Generate AI insight for graph
  static String generateGraphInsight({
    required String metricName,
    required List<double> values,
    required String trend, // 'up', 'down', 'stable'
    required double currentValue,
    double? targetValue,
  }) {
    if (values.isEmpty) {
      return 'Not enough data yet. Keep logging to see patterns.';
    }

    final avg = values.reduce((a, b) => a + b) / values.length;
    final isAboveAvg = currentValue > avg;

    switch (metricName.toLowerCase()) {
      case 'sleep':
        if (trend == 'down' && currentValue < 0.6) {
          return 'Sleep debt is accumulating. This affects recovery and reaction time. Consider an earlier lights-out tonight.';
        } else if (trend == 'up' && currentValue > 0.8) {
          return 'Sleep consistency is improving. This compounds into better performance over time. Keep it going.';
        }
        return 'Sleep is stable. Aim for consistency over perfection.';

      case 'hydration':
        if (currentValue < 0.6) {
          return 'Hydration is low. Even mild dehydration impacts power output and cognitive function. Time to drink up.';
        } else if (currentValue > 0.85) {
          return 'Hydration is optimal. Good discipline.';
        }
        return 'Hydration is adequate. Small, consistent sips beat big catches.';

      case 'stress':
        if (currentValue > 0.7) {
          return 'Stress is elevated. This is not weakness — it is your nervous system asking for attention. Consider breathing work or a lighter session.';
        } else if (currentValue < 0.3) {
          return 'Stress is well managed. You are in a good headspace for training.';
        }
        return 'Stress is within normal range. Stay aware but do not overanalyze.';

      case 'resting hr':
      case 'restinghr':
        if (trend == 'up' && currentValue > 70) {
          return 'Resting heart rate trending up. This often signals accumulated fatigue. Your body might be asking for recovery.';
        } else if (currentValue < 55) {
          return 'Resting heart rate is excellent. Strong aerobic base.';
        }
        return 'Resting heart rate is normal. Watch for multi-day trends rather than single readings.';

      case 'load':
      case 'training load':
        if (isAboveAvg && trend == 'up') {
          return 'Training load is high. This builds strength, but only if paired with recovery. Make sure rest matches effort.';
        } else if (trend == 'down') {
          return 'Load is tapering. This can be strategic or a sign of fatigue. Listen to how you feel.';
        }
        return 'Training load is consistent. Consistency beats intensity over time.';

      default:
        return 'Keep tracking. Patterns become clearer with more data.';
    }
  }
}

/// Pre-built AI Coach responses for common scenarios
class AICoachResponses {
  static const String welcomeMessage = '''
Welcome to your corner.

I am here to help you see patterns, stay consistent, and recover smart. 
I will not replace your coach, your doctor, or your own judgment — 
but I will be here between sessions, watching the data, ready to support.

Let us build something sustainable.
''';

  static const String overtrainingWarning = '''
Your load has exceeded recovery capacity for multiple days.
This is when injuries happen. This is when progress stalls.

Suggestion: Reduce intensity by 30-40% tomorrow.
Technical work, mobility, or complete rest.

Remember: Champions recover well. That is the secret.
If this pattern continues, talk to your coach.
''';

  static const String mentalHealthSupport = '''
I can see things have been heavy lately.
That is not weakness. Fighting is hard. Life is hard.

You do not have to fix everything right now.
Just focus on today. One thing at a time.

If you need to talk to someone, that is strength, not failure.
Lifeline: 13 11 14 (Australia)
Beyond Blue: 1300 22 4636

You are not alone in this.
''';

  static const String preFightCalm = '''
The work is done. The preparation is complete.
What you have built in camp cannot be taken away in the next 24 hours.

Tonight: Rest. Routine. Calm.
Tomorrow: Trust your training.

You have done this before. Your body knows what to do.
All you have to do is show up.
''';

  static const String postFightWin = '''
Congratulations. You did the work and it paid off.

But right now — tonight — do not think about what is next.
Celebrate the effort. Rest the body. Thank your team.

Analysis can wait. Recovery starts now.
''';

  static const String postFightLoss = '''
This one did not go your way.
That is hard. It is okay to feel that.

But hear this clearly: this does not define you.
Every fighter who ever mattered has lost.
What matters is what you do next.

Not tonight. Not tomorrow.
Just... when you are ready.

For now, rest. Recover. Be gentle with yourself.
''';
}
