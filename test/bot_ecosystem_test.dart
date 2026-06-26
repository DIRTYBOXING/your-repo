import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/services/shido_wisdom_engine.dart';
import 'package:datafightcentral/shared/services/shakura_safety_bot_service.dart';
import 'package:datafightcentral/shared/services/fight_camp_coach_bot_service.dart';
import 'package:datafightcentral/shared/services/bot_orchestrator_service.dart';

// NOTE: ShidoWisdomEngine, ShakuraSafetyBotService, and FightCampCoachBotService
// are singletons that eagerly init FirebaseFirestore.instance in their constructor.
// Tests below focus on pure model logic (enums, computed properties, serialization)
// without instantiating the singletons to avoid requiring Firebase initialization.

void main() {
  // ── ShidoWisdomEngine — model tests ───────────────────────────────────

  group('ShidoWisdomEngine — FighterProfile model', () {
    test('FighterProfile computes ACWR from training loads', () {
      final profile = const FighterProfile(
        fighterId: 'test-6',
        weightKg: 75.0,
        targetWeightKg: 74.0,
        age: 26,
        weightClass: 'Lightweight',
        trainingLoad7Day: 600,
        trainingLoad28Day: 2000,
      );
      expect(profile.acwr, isNotNull);
      // ACWR = 600 / (2000 / 4) = 600 / 500 = 1.2
      expect(profile.acwr, closeTo(1.2, 0.01));
    });

    test('FighterProfile weightDelta', () {
      final profile = const FighterProfile(
        fighterId: 'test-7',
        weightKg: 80.0,
        targetWeightKg: 77.0,
        age: 25,
        weightClass: 'Welterweight',
      );
      expect(profile.weightDelta, closeTo(3.0, 0.01));
    });

    test('FighterProfile hasActiveFight', () {
      final withFight = const FighterProfile(
        fighterId: 'a',
        weightKg: 70,
        targetWeightKg: 70,
        age: 25,
        weightClass: 'LW',
        daysUntilFight: 30,
      );
      final noFight = const FighterProfile(
        fighterId: 'b',
        weightKg: 70,
        targetWeightKg: 70,
        age: 25,
        weightClass: 'LW',
      );
      expect(withFight.hasActiveFight, isTrue);
      expect(noFight.hasActiveFight, isFalse);
    });

    test('FighterProfile BMI calculation', () {
      final profile = const FighterProfile(
        fighterId: 'test-bmi',
        weightKg: 80.0,
        targetWeightKg: 77.0,
        age: 25,
        weightClass: 'Welterweight',
      );
      // BMI = 80 / (1.75^2) ≈ 26.12
      expect(profile.bmi, closeTo(26.12, 0.1));
    });

    test('FighterProfile ACWR is null without training loads', () {
      final profile = const FighterProfile(
        fighterId: 'test-null-acwr',
        weightKg: 70.0,
        targetWeightKg: 70.0,
        age: 22,
        weightClass: 'Lightweight',
      );
      expect(profile.acwr, isNull);
    });

    test('ShidoDomain enum values', () {
      expect(ShidoDomain.values, contains(ShidoDomain.periodization));
      expect(ShidoDomain.values, contains(ShidoDomain.recoveryScience));
      expect(ShidoDomain.values, contains(ShidoDomain.fightIQ));
      expect(ShidoDomain.values, contains(ShidoDomain.weightManagement));
    });

    test('PeriodizationBlock enum ordering', () {
      expect(PeriodizationBlock.anatomicalAdaptation.index, 0);
      expect(
        PeriodizationBlock.competition.index,
        greaterThan(PeriodizationBlock.taper.index),
      );
    });

    test('NutritionPhase has 6 phases', () {
      expect(NutritionPhase.values.length, 6);
    });

    test('RecoveryProtocol has 7 protocols', () {
      expect(RecoveryProtocol.values.length, 7);
    });
  });

  // ── ShakuraSafetyBotService ───────────────────────────────────────────

  group('ShakuraSafetyBotService — models', () {
    test('SafetyCheckIn requiresAction for emergency', () {
      final checkIn = SafetyCheckIn(
        id: 'c1',
        userId: 'u1',
        timestamp: DateTime.now(),
        status: SafetyStatus.emergency,
      );
      expect(checkIn.requiresAction, isTrue);
    });

    test('SafetyCheckIn requiresAction for urgent', () {
      final checkIn = SafetyCheckIn(
        id: 'c2',
        userId: 'u1',
        timestamp: DateTime.now(),
        status: SafetyStatus.urgent,
      );
      expect(checkIn.requiresAction, isTrue);
    });

    test('SafetyCheckIn does not require action when safe', () {
      final checkIn = SafetyCheckIn(
        id: 'c3',
        userId: 'u1',
        timestamp: DateTime.now(),
        status: SafetyStatus.safe,
      );
      expect(checkIn.requiresAction, isFalse);
    });

    test('SafetyCheckIn Firestore round-trip', () {
      final original = SafetyCheckIn(
        id: 'c4',
        userId: 'u1',
        timestamp: DateTime(2026, 4, 3, 12),
        status: SafetyStatus.concerned,
        concerns: [
          SafetyConcernType.verbalHarassment,
          SafetyConcernType.bodyShaming,
        ],
        note: 'Uncomfortable vibes at training',
        isAnonymous: true,
      );
      final map = original.toFirestore();
      final restored = SafetyCheckIn.fromFirestore('c4', map);
      // When isAnonymous is true, userId is redacted in Firestore
      expect(restored.userId, anyOf('u1', 'anonymous'));
      expect(restored.status, SafetyStatus.concerned);
      expect(restored.concerns, contains(SafetyConcernType.verbalHarassment));
      expect(restored.isAnonymous, isTrue);
      expect(restored.note, contains('Uncomfortable'));
    });

    test('TrustedContact Firestore round-trip', () {
      final original = const TrustedContact(
        id: 'tc1',
        name: 'Sarah',
        phone: '+61400000000',
        email: 'sarah@example.com',
        relationship: 'coach',
        isEmergencyContact: true,
      );
      final map = original.toFirestore();
      final restored = TrustedContact.fromFirestore('tc1', map);
      expect(restored.name, 'Sarah');
      expect(restored.phone, '+61400000000');
      expect(restored.isEmergencyContact, isTrue);
      expect(restored.relationship, 'coach');
    });

    test('SafetyStatus enum has 5 levels', () {
      expect(SafetyStatus.values.length, 5);
      expect(SafetyStatus.values.first, SafetyStatus.safe);
      expect(SafetyStatus.values.last, SafetyStatus.emergency);
    });

    test('SafetyConcernType covers key categories', () {
      expect(SafetyConcernType.values, contains(SafetyConcernType.stalking));
      expect(
        SafetyConcernType.values,
        contains(SafetyConcernType.inappropriateContact),
      );
      expect(
        SafetyConcernType.values,
        contains(SafetyConcernType.financialExploitation),
      );
    });
  });

  // ── FightCampCoachBotService ──────────────────────────────────────────

  group('FightCampCoachBotService — models', () {
    test('DailyCheckIn computed properties', () {
      final checkIn = DailyCheckIn(
        id: 'ci4',
        fighterId: 'f1',
        timestamp: DateTime.now(),
        mood: CampMood.breaking,
        sleepHours: 4.5,
        sleepQuality: 0.2,
        weight: 84.0,
        targetWeight: 77.0,
        motivationScore: 0.2,
        energyLevel: 0.1,
        painLevel: 0.7,
        stressLevel: 0.9,
        homesickLevel: 0.8,
      );
      expect(checkIn.weightDelta, closeTo(7.0, 0.01));
      expect(checkIn.isOverweight, isTrue);
      expect(checkIn.isCriticalWeight, isTrue);
      expect(checkIn.isSleepDeprived, isTrue);
      expect(checkIn.isHighStress, isTrue);
      expect(checkIn.isHomesick, isTrue);
      expect(checkIn.isLowMotivation, isTrue);
      expect(checkIn.isInPain, isTrue);
    });

    test('DailyCheckIn Firestore round-trip', () {
      final original = DailyCheckIn(
        id: 'ci5',
        fighterId: 'f1',
        timestamp: DateTime(2026, 4, 3, 8),
        mood: CampMood.steady,
        sleepHours: 7.5,
        sleepQuality: 0.8,
        weight: 77.0,
        targetWeight: 77.0,
        motivationScore: 0.85,
        energyLevel: 0.8,
        concerns: [CampConcern.sleepIssues],
        journalNote: 'Good day',
        daysUntilFight: 21,
      );
      final map = original.toFirestore();
      final restored = DailyCheckIn.fromFirestore('ci5', map);
      expect(restored.fighterId, 'f1');
      expect(restored.mood, CampMood.steady);
      expect(restored.sleepHours, 7.5);
      expect(restored.weight, 77.0);
      expect(restored.motivationScore, 0.85);
      expect(restored.concerns, contains(CampConcern.sleepIssues));
      expect(restored.mindset, FighterMindset.disciplined);
      expect(restored.journalNote, 'Good day');
    });

    test('CampAdvisoryLevel has correct ordering', () {
      expect(
        CampAdvisoryLevel.green.index,
        lessThan(CampAdvisoryLevel.yellow.index),
      );
      expect(
        CampAdvisoryLevel.yellow.index,
        lessThan(CampAdvisoryLevel.orange.index),
      );
      expect(
        CampAdvisoryLevel.orange.index,
        lessThan(CampAdvisoryLevel.red.index),
      );
      expect(
        CampAdvisoryLevel.red.index,
        lessThan(CampAdvisoryLevel.black.index),
      );
    });
  });

  // ── BotOrchestratorService — models ───────────────────────────────────

  group('BotOrchestratorService — models & routing', () {
    test('BotDefinition isActive', () {
      final bot = BotDefinition(
        id: 'shido',
        displayName: 'Shido',
        description: 'Wisdom engine',
        type: BotType.advanced,
        capabilities: {
          BotCapability.provideCoaching,
          BotCapability.naturalLanguageChat,
        },
        registeredAt: DateTime.now(),
      );
      expect(bot.isActive, isTrue);
    });

    test('BotDefinition hasCapability', () {
      final bot = BotDefinition(
        id: 'shakura',
        displayName: 'Shakura',
        description: 'Safety guardian',
        type: BotType.warning,
        capabilities: {
          BotCapability.sendAlert,
          BotCapability.detectThreat,
          BotCapability.escalateToHuman,
        },
        registeredAt: DateTime.now(),
      );
      expect(bot.hasCapability(BotCapability.sendAlert), isTrue);
      expect(bot.hasCapability(BotCapability.predictFightOutcome), isFalse);
    });

    test('BotDefinition paused is not active', () {
      final bot = BotDefinition(
        id: 'paused-bot',
        displayName: 'Paused',
        description: 'Test',
        type: BotType.educating,
        status: BotStatus.paused,
        capabilities: {BotCapability.naturalLanguageChat},
        registeredAt: DateTime.now(),
      );
      expect(bot.isActive, isFalse);
    });

    test('BotDefinition toMap / fromMap round-trip', () {
      final original = BotDefinition(
        id: 'coach',
        displayName: 'Camp Coach',
        description: 'Daily check-ins',
        type: BotType.educating,
        capabilities: {
          BotCapability.provideCoaching,
          BotCapability.mentalHealthSupport,
        },
        avatarEmoji: '🥊',
        registeredAt: DateTime(2026),
        totalActions: 42,
      );
      final map = original.toMap();
      final restored = BotDefinition.fromMap(map);
      expect(restored.id, 'coach');
      expect(restored.displayName, 'Camp Coach');
      expect(restored.type, BotType.educating);
      expect(restored.isActive, isTrue);
      expect(restored.totalActions, 42);
      expect(restored.hasCapability(BotCapability.provideCoaching), isTrue);
    });

    test('BotAction toMap contains all fields', () {
      final action = BotAction(
        actionId: 'a1',
        botId: 'shido',
        userId: 'u1',
        actionType: 'analyze_recovery',
        description: 'Analyzed recovery for fighter u1',
        timestamp: DateTime(2026, 4, 3, 12),
      );
      final map = action.toMap();
      expect(map['actionId'], 'a1');
      expect(map['botId'], 'shido');
      expect(map['actionType'], 'analyze_recovery');
      expect(map['success'], isTrue);
    });

    test('BotCapability enum covers all domains', () {
      expect(BotCapability.values, contains(BotCapability.sendAlert));
      expect(BotCapability.values, contains(BotCapability.predictFightOutcome));
      expect(BotCapability.values, contains(BotCapability.generateSeoMeta));
      expect(BotCapability.values, contains(BotCapability.geoTargetContent));
    });

    test('BotType enum has 4 types', () {
      expect(BotType.values.length, 4);
    });

    test('BotStatus enum has 4 statuses', () {
      expect(BotStatus.values.length, 4);
    });
  });
}
