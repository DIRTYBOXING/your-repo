import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';

class NeuralCoachDashboardScreen extends StatefulWidget {
  const NeuralCoachDashboardScreen({super.key});

  @override
  State<NeuralCoachDashboardScreen> createState() => _NeuralCoachDashboardScreenState();
}

class _NeuralCoachDashboardScreenState extends State<NeuralCoachDashboardScreen> {
  // Mock Telemetry Data
  final int _heartRate = 48;
  final int _hrv = 82;
  final int _bloodOx = 99;
  final int _recoveryScore = 92;
  
  final double _punchVelocity = 9.4;
  final String _impactLoad = 'MODERATE';
  
  final double _currentWeight = 174.2;
  final double _targetWeight = 170.0;
  final double _hydrationLevel = 88.5;

  final String _sleepDuration = '8h 12m';
  final String _remSleep = '2h 15m';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory, color: AppColors.neonCyan, size: 20),
            SizedBox(width: 8),
            Text(
              'NEURAL COACH & ASTROHEALTH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRecoveryHero(),
            const SizedBox(height: 16),
            _buildVitalTelemetry(),
            const SizedBox(height: 16),
            _buildMovementMetrics(),
            const SizedBox(height: 16),
            _buildWeightAndHydration(),
            const SizedBox(height: 16),
            _buildSleepAndInjury(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRecoveryHero() {
    return GlassPanel(
      backgroundColor: AppColors.neonCyan.withValues(alpha: 0.1),
      borderColor: AppColors.neonCyan.withValues(alpha: 0.4),
      shadows: NeonGlow.softCyan(),
      child: Column(
        children: [
          const Text(
            'SYSTEM READINESS SCORE',
            style: TextStyle(
              color: AppColors.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_recoveryScore',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Prime condition. Ready for high-intensity sparring.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalTelemetry() {
    return _buildSection(
      title: 'VITAL TELEMETRY (LIVE)',
      icon: Icons.favorite,
      color: AppColors.neonMagenta,
      content: Row(
        children: [
          _buildStatBox('RESTING HR', '$_heartRate', 'bpm', AppColors.neonMagenta),
          const SizedBox(width: 12),
          _buildStatBox('HRV', '$_hrv', 'ms', AppColors.neonMagenta),
          const SizedBox(width: 12),
          _buildStatBox('SPO2', '$_bloodOx', '%', AppColors.neonMagenta),
        ],
      ),
    );
  }

  Widget _buildMovementMetrics() {
    return _buildSection(
      title: 'MOVEMENT & IMPACT',
      icon: Icons.speed,
      color: AppColors.neonCyan,
      content: Row(
        children: [
          _buildStatBox('PEAK VELOCITY', '$_punchVelocity', 'm/s', AppColors.neonCyan),
          const SizedBox(width: 12),
          _buildStatBox('IMPACT LOAD', _impactLoad, '', AppColors.neonCyan, isSmallText: true),
        ],
      ),
    );
  }

  Widget _buildWeightAndHydration() {
    return _buildSection(
      title: 'CUT PROGRESS & HYDRATION',
      icon: Icons.water_drop,
      color: Colors.blueAccent,
      content: Column(
        children: [
          Row(
            children: [
              _buildStatBox('CURRENT', '$_currentWeight', 'lbs', Colors.blueAccent),
              const SizedBox(width: 12),
              _buildStatBox('TARGET', '$_targetWeight', 'lbs', Colors.white54),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('HYDRATION LEVEL', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('$_hydrationLevel%', style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: _hydrationLevel / 100,
                backgroundColor: Colors.white10,
                color: Colors.blueAccent,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepAndInjury() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildSection(
            title: 'SLEEP',
            icon: Icons.bedtime,
            color: Colors.deepPurpleAccent,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_sleepDuration, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('REM: $_remSleep', style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSection(
            title: 'INJURY RISK',
            icon: Icons.warning_amber_rounded,
            color: Colors.greenAccent, // Green for LOW risk
            content: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LOW', style: TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('All systems nominal.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: color.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value, String unit, Color valueColor, {bool isSmallText = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: isSmallText ? 16 : 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      color: valueColor.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}