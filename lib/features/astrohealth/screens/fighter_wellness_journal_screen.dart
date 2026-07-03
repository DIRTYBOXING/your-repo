import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../core/theme/glow_effects.dart';
import '../../../shared/widgets/dfc_glow_button.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER WELLNESS & DEVICE HUB
/// The personal doctor, therapist, and camp companion for the fighter.
/// Tracks mood, stress, food, fluids, and smart device integrations.
/// ═══════════════════════════════════════════════════════════════════════════
class FighterWellnessJournalScreen extends StatefulWidget {
  const FighterWellnessJournalScreen({super.key});

  @override
  State<FighterWellnessJournalScreen> createState() => _FighterWellnessJournalScreenState();
}

class _FighterWellnessJournalScreenState extends State<FighterWellnessJournalScreen> {
  // Manual Entry States
  double _moodLevel = 7; // 1-10
  double _stressLevel = 8; // 1-10 (High stress)
  double _waterIntake = 2.5; // Liters
  
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
        title: const Text(
          'CAMP WELLNESS & SYNC',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMentalHealthCheckIn(),
            const SizedBox(height: 24),
            _buildNutritionAndHydration(),
            const SizedBox(height: 24),
            _buildDeviceIntegration(),
            const SizedBox(height: 24),
            _buildCampCharts(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMentalHealthCheckIn() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: AppColors.neonMagenta.withValues(alpha: 0.3),
      shadows: NeonGlow.softCyan(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: AppColors.neonMagenta, size: 20),
              SizedBox(width: 8),
              Text(
                'MIND & LIFE CHECK-IN',
                style: TextStyle(
                  color: AppColors.neonMagenta,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The fight game is more than physical. Track your mental state, financial stress, and isolation so your coaches know when you need a lifeline.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 24),
          _buildSlider(
            label: 'Emotional Mood / Motivation',
            value: _moodLevel,
            activeColor: Colors.greenAccent,
            onChanged: (val) => setState(() => _moodLevel = val),
          ),
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Life & Financial Stress (Poverty/Camp Costs)',
            value: _stressLevel,
            activeColor: AppColors.neonRed,
            onChanged: (val) => setState(() => _stressLevel = val),
          ),
          const SizedBox(height: 16),
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Private Journal: How are you feeling today?',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionAndHydration() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: Colors.blueAccent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blueAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'WEIGHT CUT & NUTRITION',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDataInputCard('Calories In', '2,450', 'kcal', Icons.restaurant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDataInputCard('Fluid Intake', '${_waterIntake.toStringAsFixed(1)}', 'Liters', Icons.local_drink),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Weight Cut Gauge (Target: 155 lbs)', style: TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.85,
            backgroundColor: Colors.white10,
            color: Colors.blueAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIntegration() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: AppColors.neonCyan.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.watch, color: AppColors.neonCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'SMART DEVICE INTERCONNECTORS',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDeviceRow('Apple Health', 'Connected • Last sync 2m ago', true),
          _buildDeviceRow('Whoop Strap 4.0', 'Connected • Streaming HR', true),
          _buildDeviceRow('Garmin Fenix', 'Not paired', false),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: DfcGlowButton(
              color: AppColors.neonCyan,
              onPressed: () {},
              child: const Text('PAIR NEW BLUETOOTH DEVICE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampCharts() {
    return GlassPanel(
      backgroundColor: AppColors.glassMedium,
      borderColor: Colors.greenAccent.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph, color: Colors.greenAccent, size: 20),
              SizedBox(width: 8),
              Text(
                '8-WEEK CAMP PROGRESSION',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Center(
              child: Text(
                '[ Line Chart Graphic: HRV vs Training Load ]\nAwaiting charting package integration.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            Text('${value.toInt()}/10', style: TextStyle(color: activeColor, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 1,
          max: 10,
          activeColor: activeColor,
          inactiveColor: Colors.white10,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDataInputCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(String name, String status, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: isConnected ? AppColors.neonCyan : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(status, style: TextStyle(color: isConnected ? Colors.white70 : Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          if (!isConnected)
            const Text('CONNECT', style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}