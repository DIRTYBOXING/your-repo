#!/usr/bin/env dart
// Quick reference: E2E Test Examples
// Copy and paste these snippets into your code

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 1: Run Full E2E Validation (Simplest)
// ═══════════════════════════════════════════════════════════════════════════

import 'package:datafightcentral/core/utils/e2e_test_harness.dart';

void example1_FullValidation() async {
  final harness = E2ETestHarness();

  final result = await harness.runFullValidation(
    eventId: 'event_ufc_282',
    sessionId: 'session_main_card',
  );

  print(result.summary);
  // Output:
  // ╔═══════════════════════════════════════════════════════════════╗
  // ║ E2E VALIDATION REPORT                                         ║
  // ├───────────────────────────────────────────────────────────────┤
  // ║ Status: PASSED                                                ║
  // ║ Duration: 12.3 seconds                                        ║
  // ║                                                               ║
  // ║ Stages Passed: 10/10                                          ║
  // ║ Success Log: [✅ Setup, ✅ Knockdown, ...]                   ║
  // ║ Metrics: {clipsGenerated: 3, engagementRecorded: 42, ...}    ║
  // ╚═══════════════════════════════════════════════════════════════╝
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 2: Simulate Orchestration Events
// ═══════════════════════════════════════════════════════════════════════════

import 'package:datafightcentral/core/utils/orchestration_event_simulator.dart';

void example2_EventSimulation() async {
  final simulator = OrchestrationEventSimulator();

  // Simulate a single knockdown
  final eventId = await simulator.simulateKnockdown(
    'event_ufc_282',
    'session_main_card',
    'fight_main_event',
    round: 2,
    timeInRound: 45,
  );
  print('Knockdown event created: $eventId');

  // Simulate submission
  final subEventId = await simulator.simulateSubmission(
    'event_ufc_282',
    'session_main_card',
    'fight_main_event',
    submissionType: 'rear_naked_choke',
  );
  print('Submission event created: $subEventId');

  // Simulate full round sequence
  final events = await simulator.simulateSequence(
    'event_ufc_282',
    'session_main_card',
    'fight_main_event',
  );
  print('Generated ${events.length} events');
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 3: Run Comprehensive Test Scenarios
// ═══════════════════════════════════════════════════════════════════════════

import 'package:datafightcentral/core/utils/e2e_test_runner.dart';

void example3_Scenarios() async {
  final runner = E2ETestRunner();

  // Scenario 1: Full pipeline
  print('Running Scenario 1...');
  var result = await runner.runScenario1_FullKnockdownToEarnings();
  print('Scenario 1: ${result.passed ? "PASSED ✅" : "FAILED ❌"}');

  // Scenario 2: Multiple events
  print('Running Scenario 2...');
  result = await runner.runScenario2_MultipleEventsSequence();
  print('Scenario 2: ${result.passed ? "PASSED ✅" : "FAILED ❌"}');

  // Scenario 3: Load test
  print('Running Scenario 3...');
  result = await runner.runScenario3_EngagementLoad();
  print('Scenario 3: ${result.passed ? "PASSED ✅" : "FAILED ❌"}');

  // Scenario 4: Multiple creators
  print('Running Scenario 4...');
  result = await runner.runScenario4_MultipleCreators();
  print('Scenario 4: ${result.passed ? "PASSED ✅" : "FAILED ❌"}');
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 4: Check Individual Test Results
// ═══════════════════════════════════════════════════════════════════════════

void example4_DetailedResults() async {
  final harness = E2ETestHarness();
  final result = await harness.runFullValidation(
    eventId: 'event_test',
    sessionId: 'session_test',
  );

  // Check overall status
  if (result.passed) {
    print('✅ All tests passed!');
  } else {
    print('❌ Some tests failed');
  }

  // Access raw results
  print('Total duration: ${result.totalDuration.inSeconds}s');
  print('Successes: ${result.successLog}');
  print('Failures: ${result.failureLog}');
  print('Metrics: ${result.metrics}');

  // Common metrics to check
  final clipsGenerated = result.metrics['clipsGenerated'] ?? 0;
  final engagementRecorded = result.metrics['engagementRecorded'] ?? 0;
  final conversionsRecorded = result.metrics['conversionsRecorded'] ?? 0;
  final earningsCalculated = result.metrics['earningsCalculated'] ?? 0;

  print('''
  📊 Summary:
     • Clips: $clipsGenerated
     • Engagement: $engagementRecorded
     • Conversions: $conversionsRecorded
     • Earnings: \$$earningsCalculated
  ''');
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 5: Integrate into Debug Screen
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:datafightcentral/core/screens/e2e_debug_screen.dart';

void example5_DebugScreenIntegration(BuildContext context) {
  // Option A: Navigate to debug screen
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const E2EDebugScreen()),
  );

  // Option B: Add to GoRouter (recommended)
  // In lib/core/config/router_config.dart:
  // if (kDebugMode)
  //   GoRoute(
  //     path: '/debug/e2e-tests',
  //     builder: (context, state) => const E2EDebugScreen(),
  //   ),

  // Then use:
  // context.push('/debug/e2e-tests');
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 6: Run as Part of Integration Tests
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';

void integrationTestExample() {
  testWidgets('E2E Viral Loop Integration Test', (WidgetTester tester) async {
    final harness = E2ETestHarness();

    // Run validation
    final result = await harness.runFullValidation(
      eventId: 'event_integration_test',
      sessionId: 'session_integration_test',
    );

    // Assert results
    expect(result.passed, true);
    expect(result.successLog.length, greaterThan(0));
    expect(result.metrics['clipsGenerated'], greaterThan(0));
    expect(result.metrics['engagementRecorded'], greaterThan(0));
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 7: Stream-based Monitoring
// ═══════════════════════════════════════════════════════════════════════════

import 'package:datafightcentral/features/social/services/social_feed_realtime_service.dart';

void example7_RealtimeMonitoring() async {
  final feedService = SocialFeedRealtimeService();

  // Listen to new clips
  feedService.getNewClipsStream(eventId: 'event_test', sessionId: 'session_test')
    .listen((clip) {
      print('🎬 New clip: ${clip.title}');
      print('   Trending: ${clip.trendingScore}');
    });

  // Listen to engagement updates
  feedService.getEngagementUpdatesStream(eventId: 'event_test', sessionId: 'session_test')
    .listen((engagement) {
      print('👁️ Engagement: Views=${engagement.views}, Likes=${engagement.likes}');
    });

  // Listen to trending clips
  feedService.getTrendingClipsStream(eventId: 'event_test', sessionId: 'session_test')
    .listen((clip) {
      print('🔥 Trending: ${clip.title} (Score: ${clip.trendingScore})');
    });
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 8: Performance Benchmarking
// ═══════════════════════════════════════════════════════════════════════════

void example8_Benchmarking() async {
  final harness = E2ETestHarness();
  final stopwatch = Stopwatch()..start();

  final result = await harness.runFullValidation(
    eventId: 'event_benchmark',
    sessionId: 'session_benchmark',
  );

  stopwatch.stop();

  print('''
  ⏱️ Performance Benchmark:
     Total Time: ${stopwatch.elapsedMilliseconds}ms
     Per Stage: ${stopwatch.elapsedMilliseconds / 10}ms avg
     Status: ${result.passed ? "PASSED" : "FAILED"}
  ''');
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 9: Error Handling
// ═══════════════════════════════════════════════════════════════════════════

void example9_ErrorHandling() async {
  final harness = E2ETestHarness();

  try {
    final result = await harness.runFullValidation(
      eventId: 'event_test',
      sessionId: 'session_test',
    );

    if (!result.passed) {
      print('Test failed. Failures:');
      for (final failure in result.failureLog) {
        print('  - $failure');
      }

      // Log for debugging
      result.metrics.forEach((key, value) {
        print('$key: $value');
      });
    }
  } catch (e) {
    print('Exception during E2E test: $e');
    // Handle exception (Firebase not initialized, etc.)
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXAMPLE 10: Complete End-to-End Test Suite
// ═══════════════════════════════════════════════════════════════════════════

void example10_CompleteSuite() async {
  print('''
  🚀 STARTING E2E VALIDATION SUITE
  ═══════════════════════════════════════════════════════════════════
  ''');

  final runner = E2ETestRunner();
  final results = <String, bool>{};

  // Run all scenarios
  for (int i = 1; i <= 4; i++) {
    print('Running Scenario $i...');

    final result = switch (i) {
      1 => await runner.runScenario1_FullKnockdownToEarnings(),
      2 => await runner.runScenario2_MultipleEventsSequence(),
      3 => await runner.runScenario3_EngagementLoad(),
      4 => await runner.runScenario4_MultipleCreators(),
      _ => throw Exception('Invalid scenario'),
    };

    results['Scenario $i'] = result.passed;
    print('Scenario $i: ${result.passed ? "✅ PASSED" : "❌ FAILED"}');
    print('  Duration: ${result.totalDuration.inSeconds}s');
    print('  Errors: ${result.failureLog.length}');
    print('');
  }

  // Print summary
  print('═══════════════════════════════════════════════════════════════════');
  print('📊 SUITE SUMMARY');
  print('═══════════════════════════════════════════════════════════════════');

  results.forEach((scenario, passed) {
    print('$scenario: ${passed ? "✅" : "❌"}');
  });

  final allPassed = results.values.every((p) => p);
  print('');
  print(allPassed ? '✅ ALL TESTS PASSED' : '❌ SOME TESTS FAILED');
}

// ═══════════════════════════════════════════════════════════════════════════
// USAGE IN main()
// ═══════════════════════════════════════════════════════════════════════════

// If you want to run E2E tests before starting the app:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for E2E tests)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run E2E validation (optional, for testing)
  if (const bool.fromEnvironment('RUN_E2E_TESTS', defaultValue: false)) {
    print('🧪 Running E2E tests...');
    example10_CompleteSuite();
  }

  // Run the app
  runApp(const MyApp());
}
