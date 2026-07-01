import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/services/readiness_score_engine.dart';
import 'package:datafightcentral/shared/services/trend_detection_service.dart';
import 'package:datafightcentral/shared/services/autonomous_engagement_service.dart';
import 'package:datafightcentral/shared/services/biometric_feedback_bridge.dart';
import 'package:datafightcentral/shared/services/digital_wellbeing_coach.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════
  // 1. READINESS SCORE ENGINE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('ReadinessScoreEngine', () {
    final engine = ReadinessScoreEngine.instance;

    test('peak readiness from optimal inputs', () {
      final result = engine.compute(
        const ReadinessInput(
          sleepHours: 8.5,
          deepSleepHours: 2.0,
          hrvMs: 85,
          restingHR: 55,
          baselineRHR: 58,
          trainingLoad7Day: 500,
          trainingLoad28Day: 2000,
          waterIntakeLiters: 3.5,
          caloriesConsumed: 2500,
          calorieTarget: 2500,
          proteinGrams: 180,
          proteinTargetGrams: 170,
          moodRating: 9,
          stressLevel: 2,
        ),
      );

      expect(result.overallScore, greaterThan(75));
      expect(result.zone, anyOf(ReadinessZone.good, ReadinessZone.peak));
      expect(result.pillars, hasLength(6));
      expect(result.recommendations, isNotEmpty);
    });

    test('critical readiness from poor inputs', () {
      final result = engine.compute(
        const ReadinessInput(
          sleepHours: 3.5,
          hrvMs: 20,
          restingHR: 80,
          baselineRHR: 58,
          trainingLoad7Day: 900,
          trainingLoad28Day: 1200,
          waterIntakeLiters: 0.5,
          moodRating: 2,
          stressLevel: 9,
        ),
      );

      expect(result.overallScore, lessThan(50));
      expect(
        result.zone,
        anyOf(
          ReadinessZone.critical,
          ReadinessZone.low,
          ReadinessZone.moderate,
        ),
      );
      expect(result.topLimiter, isNotNull);
    });

    test('neutral defaults when no data provided', () {
      final result = engine.compute(const ReadinessInput());
      // All pillars should get baseline 60
      expect(result.overallScore, closeTo(60, 5));
      expect(result.pillars.every((p) => p.normalizedScore == 60), isTrue);
    });

    test('wearable sleep score takes priority over raw hours', () {
      final result = engine.compute(
        const ReadinessInput(
          sleepScore: 95,
          sleepHours: 4.0, // bad hours, but wearable says 95
        ),
      );

      final sleepPillar = result.pillars.firstWhere(
        (p) => p.pillar == ReadinessPillar.sleep,
      );
      expect(sleepPillar.normalizedScore, equals(95));
    });

    test('ACWR sweet spot (1.0) yields high training load score', () {
      final result = engine.compute(
        const ReadinessInput(
          trainingLoad7Day: 500,
          trainingLoad28Day: 2000, // ACWR = 500 / 500 = 1.0
        ),
      );

      final loadPillar = result.pillars.firstWhere(
        (p) => p.pillar == ReadinessPillar.trainingLoad,
      );
      expect(loadPillar.normalizedScore, greaterThanOrEqualTo(80));
    });

    test('ACWR danger zone (>1.5) yields low training load score', () {
      final result = engine.compute(
        const ReadinessInput(
          trainingLoad7Day: 1000,
          trainingLoad28Day: 2000, // ACWR = 1000 / 500 = 2.0
        ),
      );

      final loadPillar = result.pillars.firstWhere(
        (p) => p.pillar == ReadinessPillar.trainingLoad,
      );
      expect(loadPillar.normalizedScore, lessThan(40));
    });

    test('toMap serialization', () {
      final result = engine.compute(const ReadinessInput(sleepHours: 7.5));
      final map = result.toMap();
      expect(map['overallScore'], isA<double>());
      expect(map['zone'], isA<String>());
      expect(map['pillars'], isA<List>());
      expect(map['recommendations'], isA<List>());
      expect(map['computedAt'], isA<String>());
    });
  });

  group('ReadinessZone', () {
    test('fromScore returns correct zones', () {
      expect(ReadinessZone.fromScore(10), ReadinessZone.critical);
      expect(ReadinessZone.fromScore(35), ReadinessZone.low);
      expect(ReadinessZone.fromScore(55), ReadinessZone.moderate);
      expect(ReadinessZone.fromScore(75), ReadinessZone.good);
      expect(ReadinessZone.fromScore(90), ReadinessZone.peak);
    });
  });

  group('ReadinessPillar weights', () {
    test('pillar weights sum to ~1.0', () {
      final sum = ReadinessPillar.values.fold<double>(
        0,
        (s, p) => s + p.weight,
      );
      expect(sum, closeTo(1.0, 0.01));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 2. TREND DETECTION SERVICE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('TrendDetectionService', () {
    final service = TrendDetectionService.instance;

    test('scoreContent returns valid virality score', () {
      final content = ContentMetadata(
        contentId: 'test-1',
        title: 'UFC 300 Main Event Knockout',
        body: 'Incredible finish in the title fight tonight!',
        tags: ['UFC', 'knockout', 'title fight'],
        authorId: 'user-1',
        authorFollowerCount: 50000,
        authorVerified: true,
        publishedAt: DateTime.now(),
      );

      final score = service.scoreContent(content);
      expect(score.overallScore, greaterThanOrEqualTo(0));
      expect(score.overallScore, lessThanOrEqualTo(100));
      expect(score.potential, isA<ViralPotential>());
      expect(score.signalScores.length, equals(TrendSignal.values.length));
    });

    test('verified creator with followers scores higher authority', () {
      final verified = ContentMetadata(
        contentId: 'v1',
        title: 'Test',
        body: 'Test content',
        tags: [],
        authorId: 'a1',
        authorFollowerCount: 100000,
        authorVerified: true,
        publishedAt: DateTime.now(),
      );

      final unverified = ContentMetadata(
        contentId: 'v2',
        title: 'Test',
        body: 'Test content',
        tags: [],
        authorId: 'a2',
        authorFollowerCount: 50,
        publishedAt: DateTime.now(),
      );

      final scoreV = service.scoreContent(verified);
      final scoreU = service.scoreContent(unverified);

      expect(
        scoreV.signalScores[TrendSignal.creatorAuthority],
        greaterThan(scoreU.signalScores[TrendSignal.creatorAuthority]!),
      );
    });

    test('ingestEngagementBatch populates active trends', () {
      final batch = [
        ContentMetadata(
          contentId: 'b1',
          title: 'UFC knockout highlight',
          body: 'What a knockout in the main event',
          tags: ['UFC', 'knockout'],
          authorId: 'u1',
          publishedAt: DateTime.now(),
        ),
        ContentMetadata(
          contentId: 'b2',
          title: 'UFC press conference recap',
          body: 'Press conference before main event',
          tags: ['UFC'],
          authorId: 'u2',
          publishedAt: DateTime.now(),
        ),
      ];

      service.ingestEngagementBatch(batch);
      expect(service.activeTrends, isNotEmpty);
      expect(service.activeTrends.any((t) => t.keyword == 'UFC'), isTrue);
    });

    test('ViralPotential.fromScore maps correctly', () {
      expect(ViralPotential.fromScore(5), ViralPotential.cold);
      expect(ViralPotential.fromScore(25), ViralPotential.warming);
      expect(ViralPotential.fromScore(45), ViralPotential.trending);
      expect(ViralPotential.fromScore(65), ViralPotential.hot);
      expect(ViralPotential.fromScore(85), ViralPotential.viral);
    });

    test('toMap serialization', () {
      final score = service.scoreContent(
        ContentMetadata(
          contentId: 'ser-1',
          title: 'Test',
          body: 'body',
          tags: [],
          authorId: 'a',
          publishedAt: DateTime.now(),
        ),
      );
      final map = score.toMap();
      expect(map['contentId'], equals('ser-1'));
      expect(map['overallScore'], isA<double>());
      expect(map['potential'], isA<String>());
    });

    test('TrendTopic isBreakout logic', () {
      final topic = TrendTopic(
        keyword: 'UFC',
        momentum: 80,
        mentionCount: 10,
        mentionDelta: 8,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
      );
      expect(topic.isBreakout, isTrue);

      final notBreakout = TrendTopic(
        keyword: 'test',
        momentum: 10,
        mentionCount: 100,
        mentionDelta: 2,
        firstSeen: DateTime.now(),
        lastSeen: DateTime.now(),
      );
      expect(notBreakout.isBreakout, isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 3. AUTONOMOUS ENGAGEMENT SERVICE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('AutonomousEngagementService', () {
    final service = AutonomousEngagementService.instance;

    test('generateActions returns actions for posts', () {
      final posts = [
        PostContext(
          postId: 'p1',
          content: 'Incredible knockout in the main event tonight!',
          postType: 'text',
          authorId: 'u1',
          authorVerified: true,
          likes: 100,
          tags: ['knockout', 'UFC'],
          createdAt: DateTime.now(),
        ),
        PostContext(
          postId: 'p2',
          content: 'Welcome to my first training camp update!',
          postType: 'image',
          authorId: 'u2',
          likes: 5,
          tags: ['training'],
          createdAt: DateTime.now(),
        ),
      ];

      final actions = service.generateActions(posts);
      expect(actions, isNotEmpty);
      expect(actions.every((a) => a.confidenceScore >= 0.4), isTrue);
    });

    test('generateComment picks correct persona for KO content', () {
      final koPost = PostContext(
        postId: 'ko1',
        content: 'What a knockout! Best finish of the year!',
        postType: 'video',
        authorId: 'u1',
        createdAt: DateTime.now(),
      );

      final action = service.generateComment(koPost);
      expect(action.persona, equals(BotPersona.hypeMan));
      expect(action.type, equals(EngagementActionType.comment));
      expect(action.commentText, isNotNull);
    });

    test('generateComment picks analyst for stats content', () {
      final statsPost = PostContext(
        postId: 'stats1',
        content: 'Looking at the record and streak this fighter is on',
        postType: 'text',
        authorId: 'u1',
        createdAt: DateTime.now(),
      );

      final action = service.generateComment(statsPost);
      expect(action.persona, equals(BotPersona.analyst));
    });

    test('generateComment picks coach for training content', () {
      final trainPost = PostContext(
        postId: 'train1',
        content: 'New sparring drill we used in camp today',
        postType: 'video',
        authorId: 'u1',
        createdAt: DateTime.now(),
      );

      final action = service.generateComment(trainPost);
      expect(action.persona, equals(BotPersona.coach));
    });

    test('action toMap serialization', () {
      final action = EngagementAction(
        actionId: 'test-action',
        persona: BotPersona.hypeMan,
        type: EngagementActionType.react,
        targetPostId: 'p1',
        reactionType: 'warrior',
        confidenceScore: 0.8,
        reasoning: 'test',
        generatedAt: DateTime.now(),
      );
      final map = action.toMap();
      expect(map['actionId'], equals('test-action'));
      expect(map['persona'], equals('hype_man'));
      expect(map['reactionType'], equals('warrior'));
    });

    test('BotPersona enum has all required fields', () {
      for (final persona in BotPersona.values) {
        expect(persona.id, isNotEmpty);
        expect(persona.name, isNotEmpty);
        expect(persona.emoji, isNotEmpty);
        expect(persona.voice, isNotEmpty);
        expect(persona.expertise, isNotEmpty);
      }
    });

    test('strategy update changes behavior', () {
      final customStrategy = const EngagementStrategy(
        engagementRate: 5,
        commentRatio: 0.8,
        reactionRatio: 0.1,
        boostRatio: 0.1,
      );
      service.updateStrategy(customStrategy);
      expect(service.strategy.commentRatio, equals(0.8));
      // Reset
      service.updateStrategy(const EngagementStrategy());
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 4. BIOMETRIC FEEDBACK BRIDGE TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('BiometricFeedbackBridge', () {
    final bridge = BiometricFeedbackBridge.instance;

    test('process healthy snapshot yields good readiness', () {
      final decision = bridge.process(
        fighterId: 'fighter-1',
        snapshot: const BeastBiometricSnapshot(
          sleepHours: 8.0,
          deepSleepHours: 1.8,
          hrvMs: 75,
          restingHR: 55,
          baselineRHR: 58,
          trainingLoad7Day: 500,
          trainingLoad28Day: 2000,
          waterIntakeLiters: 3.0,
          moodRating: 8,
          stressLevel: 3,
        ),
      );

      expect(decision.readiness.overallScore, greaterThan(60));
      expect(decision.modifier.forceRestDay, isFalse);
      expect(decision.botDirectives, isNotEmpty);
      // Should always have a Shido directive
      expect(
        decision.botDirectives.any((d) => d.target == BotDirectiveTarget.shido),
        isTrue,
      );
    });

    test('process critical snapshot forces rest day', () {
      final decision = bridge.process(
        fighterId: 'fighter-2',
        snapshot: const BeastBiometricSnapshot(
          sleepHours: 3.0,
          hrvMs: 18, // critically low
          restingHR: 78,
          baselineRHR: 58, // +20 elevated
          trainingLoad7Day: 1200,
          trainingLoad28Day: 2000, // ACWR = 2.4 (danger)
          waterIntakeLiters: 0.5,
          moodRating: 2,
          stressLevel: 9,
        ),
      );

      expect(decision.alerts, isNotEmpty);
      expect(decision.alerts.any((a) => a.severity == 'danger'), isTrue);
      expect(decision.modifier.forceRestDay, isTrue);
      expect(decision.modifier.intensityMultiplier, equals(0.0));
      // Should have Shakura safety alert
      expect(
        decision.botDirectives.any(
          (d) => d.target == BotDirectiveTarget.shakura,
        ),
        isTrue,
      );
    });

    test('peak snapshot triggers peakWindow alert', () {
      final decision = bridge.process(
        fighterId: 'fighter-3',
        snapshot: const BeastBiometricSnapshot(
          sleepScore: 95,
          hrvMs: 90,
          restingHR: 50,
          baselineRHR: 55,
          recoveryScore: 95,
          trainingLoad7Day: 500,
          trainingLoad28Day: 2000,
          waterIntakeLiters: 3.5,
          caloriesConsumed: 2500,
          calorieTarget: 2500,
          proteinGrams: 180,
          proteinTargetGrams: 170,
          moodRating: 9,
          stressLevel: 1,
        ),
      );

      expect(decision.readiness.overallScore, greaterThan(75));
      expect(
        decision.alerts.any(
          (a) =>
              a == BiometricAlert.peakWindow ||
              a == BiometricAlert.recoveryGreen,
        ),
        isTrue,
      );
    });

    test('low nutrition triggers blotato directive', () {
      final decision = bridge.process(
        fighterId: 'fighter-4',
        snapshot: const BeastBiometricSnapshot(
          caloriesConsumed: 800,
          calorieTarget: 2500,
        ),
      );

      expect(
        decision.botDirectives.any(
          (d) => d.target == BotDirectiveTarget.blotato,
        ),
        isTrue,
      );
    });

    test('toMap serialization', () {
      final decision = bridge.process(
        fighterId: 'ser-1',
        snapshot: const BeastBiometricSnapshot(),
      );
      final map = decision.toMap();
      expect(map['fighterId'], equals('ser-1'));
      expect(map['readinessScore'], isA<double>());
      expect(map['alerts'], isA<List>());
    });
  });

  group('BiometricAlert', () {
    test('all alerts have severity and explanation', () {
      for (final alert in BiometricAlert.values) {
        expect(alert.label, isNotEmpty);
        expect(alert.severity, isNotEmpty);
        expect(alert.explanation, isNotEmpty);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════
  // 5. DIGITAL WELLBEING COACH TESTS
  // ═══════════════════════════════════════════════════════════════════════

  group('DigitalWellbeingCoach', () {
    late DigitalWellbeingCoach coach;

    setUp(() {
      coach = DigitalWellbeingCoach.instance;
      coach.resetDaily();
    });

    test('startSession creates a session', () {
      coach.startSession();
      expect(coach.currentSession, isNotNull);
    });

    test('recordInteraction updates session counters', () {
      coach.startSession();
      coach.recordInteraction(
        screenName: 'feed',
        isFeedScroll: true,
        isPostView: true,
      );
      coach.recordInteraction(screenName: 'dashboard');

      final session = coach.currentSession!;
      expect(session.screenTaps, equals(2));
      expect(session.feedScrolls, equals(1));
      expect(session.postsViewed, equals(1));
      expect(session.socialScreenViews, equals(1));
      expect(session.trainingScreenViews, equals(1));
    });

    test('socialRatio computed correctly', () {
      coach.startSession();
      for (int i = 0; i < 8; i++) {
        coach.recordInteraction(screenName: 'feed');
      }
      for (int i = 0; i < 2; i++) {
        coach.recordInteraction(screenName: 'training');
      }

      expect(coach.currentSession!.socialRatio, closeTo(0.8, 0.01));
    });

    test('logWaterGlass tracks hydration', () {
      coach.logWaterGlass();
      coach.logWaterGlass();
      coach.logWaterGlass();

      final summary = coach.generateDailySummary();
      expect(
        summary.improvementAreas.any((s) => s.contains('Hydration')),
        isTrue,
      );
    });

    test('generateDailySummary returns valid summary', () {
      coach.startSession();
      coach.recordInteraction(screenName: 'dashboard');

      final summary = coach.generateDailySummary();
      expect(summary.wellbeingScore, greaterThanOrEqualTo(0));
      expect(summary.wellbeingScore, lessThanOrEqualTo(100));
      expect(summary.totalScreenTime, isA<Duration>());
    });

    test('daily summary toMap serialization', () {
      final summary = coach.generateDailySummary();
      final map = summary.toMap();
      expect(map['screenMinutes'], isA<int>());
      expect(map['wellbeingScore'], isA<double>());
      expect(map['highlights'], isA<List>());
    });

    test('resetDaily clears all state', () {
      coach.startSession();
      coach.recordInteraction(screenName: 'feed');
      coach.logWaterGlass();
      coach.resetDaily();

      expect(coach.currentSession, isNull);
      expect(coach.todayNudges, isEmpty);
    });

    test('WellbeingProfile has sensible defaults', () {
      const profile = WellbeingProfile();
      expect(profile.dailyScreenTarget, equals(const Duration(hours: 2)));
      expect(profile.breakInterval, equals(const Duration(minutes: 45)));
      expect(profile.targetWaterGlasses, equals(8));
    });

    test('NudgeType enum covers all categories', () {
      final categories = NudgeType.values.map((n) => n.category).toSet();
      expect(
        categories,
        containsAll([
          'rest',
          'health',
          'recovery',
          'balance',
          'performance',
          'motivation',
          'nutrition',
        ]),
      );
    });
  });
}
