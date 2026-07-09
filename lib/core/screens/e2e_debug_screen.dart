import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../utils/e2e_test_runner.dart';
import '../theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// E2E VALIDATION DEBUG SCREEN — Tier 6D Testing UI
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Debug screen for running E2E tests and viewing results.
/// Only visible in debug mode.
///
/// Usage (add to router or as a debug shortcut):
///   context.push('/debug/e2e-tests');
///
/// ═══════════════════════════════════════════════════════════════════════════

class E2EDebugScreen extends StatefulWidget {
  const E2EDebugScreen({super.key});

  @override
  State<E2EDebugScreen> createState() => _E2EDebugScreenState();
}

class _E2EDebugScreenState extends State<E2EDebugScreen> {
  final _runner = E2ETestRunner();
  bool _isRunning = false;
  String _currentStatus = 'Ready';
  List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text(
          'E2E Validation Dashboard',
          style: TextStyle(
            color: DesignTokens.neonCyan,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        elevation: 0,
        border: const Border(
          bottom: BorderSide(color: DesignTokens.neonCyan, width: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 16),

            // Scenario Buttons
            _buildScenarioButtons(),
            const SizedBox(height: 16),

            // Logs
            _buildLogsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isRunning ? DesignTokens.neonCyan : DesignTokens.neonGreen,
          width: 2,
        ),
        color: (_isRunning ? DesignTokens.neonCyan : DesignTokens.neonGreen)
            .withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isRunning
                      ? DesignTokens.neonCyan
                      : DesignTokens.neonGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isRunning ? 'Running...' : 'Ready',
                style: TextStyle(
                  color: _isRunning
                      ? DesignTokens.neonCyan
                      : DesignTokens.neonGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Scenarios',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        _buildScenarioButton(
          label: 'Scenario 1: Full Pipeline',
          subtitle: 'Knockdown → Clip → Feed → Engagement → PPV',
          onPressed: _isRunning ? null : _runScenario1,
          color: DesignTokens.neonRed,
        ),
        const SizedBox(height: 8),
        _buildScenarioButton(
          label: 'Scenario 2: Event Sequence',
          subtitle: 'Multiple events (round end, knockdown, submission)',
          onPressed: _isRunning ? null : _runScenario2,
          color: DesignTokens.neonAmber,
        ),
        const SizedBox(height: 8),
        _buildScenarioButton(
          label: 'Scenario 3: Engagement Load',
          subtitle: '100 users, 1000+ interactions',
          onPressed: _isRunning ? null : _runScenario3,
          color: DesignTokens.neonCyan,
        ),
        const SizedBox(height: 8),
        _buildScenarioButton(
          label: 'Scenario 4: Multiple Creators',
          subtitle: 'Revenue distribution accuracy',
          onPressed: _isRunning ? null : _runScenario4,
          color: DesignTokens.neonGreen,
        ),
      ],
    );
  }

  Widget _buildScenarioButton({
    required String label,
    required String subtitle,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(onPressed == null ? 0.3 : 0.6),
              width: 1.5,
            ),
            color: color.withOpacity(onPressed == null ? 0.02 : 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(
                    onPressed == null ? 0.4 : 0.7,
                  ),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Test Logs',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            if (_logs.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _logs.clear()),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            color: Colors.black.withOpacity(0.3),
          ),
          child: _logs.isEmpty
              ? Center(
                  child: Text(
                    'Run a test scenario to see logs',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final isSuccess = log.contains('✅') || log.contains('✓');
                    final isError = log.contains('❌') || log.contains('✗');

                    return Text(
                      log,
                      style: TextStyle(
                        color: isError
                            ? DesignTokens.neonRed
                            : isSuccess
                            ? DesignTokens.neonGreen
                            : Colors.white.withOpacity(0.8),
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _runScenario1() async {
    _runScenarioWithUI(
      'Scenario 1: Full Pipeline',
      _runner.runScenario1_FullKnockdownToEarnings,
    );
  }

  Future<void> _runScenario2() async {
    _runScenarioWithUI(
      'Scenario 2: Event Sequence',
      _runner.runScenario2_MultipleEventsSequence,
    );
  }

  Future<void> _runScenario3() async {
    _runScenarioWithUI(
      'Scenario 3: Engagement Load',
      _runner.runScenario3_EngagementLoad,
    );
  }

  Future<void> _runScenario4() async {
    _runScenarioWithUI(
      'Scenario 4: Multiple Creators',
      _runner.runScenario4_MultipleCreators,
    );
  }

  Future<void> _runScenarioWithUI(
    String scenarioName,
    Future<dynamic> Function() testFn,
  ) async {
    setState(() {
      _isRunning = true;
      _currentStatus = 'Starting $scenarioName...';
      _logs.clear();
      _logs.add('▶️ $scenarioName');
      _logs.add('═' * 80);
    });

    try {
      final result = await testFn();

      setState(() {
        _logs.addAll(result.successLog);
        _logs.addAll(result.failureLog);
        _logs.add('═' * 80);
        _logs.add('Metrics:');
        for (final entry in result.metrics.entries) {
          _logs.add('  ${entry.key}: ${entry.value}');
        }
        _logs.add('═' * 80);
        _logs.add(
          result.passed
              ? '✅ PASSED in ${result.totalDuration.inSeconds}s'
              : '❌ FAILED in ${result.totalDuration.inSeconds}s',
        );
        _currentStatus = result.passed ? 'Test Passed ✅' : 'Test Failed ❌';
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _logs.add('❌ Exception: $e');
        _currentStatus = 'Error: $e';
        _isRunning = false;
      });
    }
  }
}
