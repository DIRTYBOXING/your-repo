import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import 'coach_telemetry_bar.dart';
import 'coach_metric_ring.dart';
import 'training_plan_card.dart';
import 'coach_tip_card.dart';

class SmartCoachDashboardScreen extends StatelessWidget {
  const SmartCoachDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'SMART COACH',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: DesignTokens.neonCyan,
            ),
            onPressed: () => context.push(
              '/coach',
            ), // Connects to your existing SmartCoach Chat
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CoachTelemetryBar(),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CoachMetricRing(
                  label: 'RECOVERY',
                  percentage: 0.82,
                  color: DesignTokens.neonGreen,
                ),
                CoachMetricRing(
                  label: 'STRAIN',
                  percentage: 0.65,
                  color: DesignTokens.neonAmber,
                ),
                CoachMetricRing(
                  label: 'SLEEP',
                  percentage: 0.91,
                  color: DesignTokens.neonCyan,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const CoachTipCard(),
            const SizedBox(height: 24),
            const TrainingPlanCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/coach'),
                icon: const Icon(Icons.psychology, size: 20),
                label: const Text(
                  'OPEN AI CHAT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.neonCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
