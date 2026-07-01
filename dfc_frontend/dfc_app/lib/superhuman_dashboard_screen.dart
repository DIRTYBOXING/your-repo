import 'package:flutter/material.dart';
import '../../../../dfc_theme.dart';
import '../controllers/telemetry_controller.dart';
import '../widgets/bionic_metric_grid.dart';
import '../widgets/telemetry_chart_card.dart';

class SuperhumanDashboardScreen extends StatefulWidget {
  const SuperhumanDashboardScreen({super.key});

  @override
  State<SuperhumanDashboardScreen> createState() =>
      _SuperhumanDashboardScreenState();
}

class _SuperhumanDashboardScreenState extends State<SuperhumanDashboardScreen> {
  late final TelemetryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TelemetryController()..loadTelemetry();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'BIONIC TELEMETRY',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final data = _controller.data;

          if (_controller.isLoading || data == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentCyan),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              // ─── 1. BIONIC SCORE HERO ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentCyan.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentCyan.withValues(alpha: 0.15),
                      blurRadius: 20,
                    ),
                  ],
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentCyan.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    center: Alignment.topRight,
                    radius: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COMBAT EFFICIENCY',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${data.bionicScore}',
                            style: const TextStyle(
                              color: AppColors.accentCyan,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'SUPERHUMAN TIER',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: data.bionicScore / 100,
                            strokeWidth: 8,
                            backgroundColor: AppColors.border,
                            color: AppColors.accentCyan,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        const Icon(
                          Icons.memory,
                          color: AppColors.accentCyan,
                          size: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── 2. CONNECTED SOURCES ──────────────────────────────────────
              const Text(
                'ACTIVE STREAMS',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStreamPill('DFC GLOVES', AppColors.accentCyan),
                  const SizedBox(width: 8),
                  _buildStreamPill('DFC HEADGEAR', AppColors.championGold),
                  const SizedBox(width: 8),
                  _buildStreamPill('GOOGLE FIT', AppColors.accentRed),
                ],
              ),
              const SizedBox(height: 32),

              // ─── 3. METRIC GRID ────────────────────────────────────────────
              BionicMetricGrid(data: data),
              const SizedBox(height: 32),

              // ─── 4. TELEMETRY CHARTS ───────────────────────────────────────
              const TelemetryChartCard(
                title: 'PUNCH ACCURACY DEGRADATION',
                subtitle: 'LIVE FATIGUE',
                color: AppColors.accentCyan,
              ),
              const SizedBox(height: 16),
              const TelemetryChartCard(
                title: 'HEAD MOVEMENT SPEED',
                subtitle: 'EVASION TREND',
                color: AppColors.championGold,
              ),

              const SizedBox(height: 48),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreamPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
