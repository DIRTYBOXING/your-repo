import 'package:flutter/material.dart';
import 'weight_cut_controller.dart';
import 'weight_cut_repository.dart';
import 'api_service.dart';
import 'weight_cut_state.dart';

class WeightCutEngineScreen extends StatefulWidget {
  const WeightCutEngineScreen({super.key});

  @override
  State<WeightCutEngineScreen> createState() => _WeightCutEngineScreenState();
}

class _WeightCutEngineScreenState extends State<WeightCutEngineScreen> {
  late final WeightCutController _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = WeightCutController(
      repository: WeightCutRepository(apiService: ApiService()),
    );
    _controller.loadTelemetry();
  }

  Widget _buildContent(WeightCutLoaded state) {
    final data = state.data;
    return RefreshIndicator(
      onRefresh: _controller.loadTelemetry,
      color: Colors.blueAccent,
      backgroundColor: const Color(0xFF0A0E17),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          const SizedBox(height: 32),

          // ─── 1. HEADER ───────────────────────────────────────────────────
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Text(
                'WEIGHT CUT ENGINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'ON TRACK',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ─── 2. CORE METRICS ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'CURRENT (LBS)',
                  data.currentWeight.toStringAsFixed(1),
                  Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'TARGET (LBS)',
                  data.targetWeight.toStringAsFixed(1),
                  Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'REMAINING',
                  (data.currentWeight - data.targetWeight).toStringAsFixed(1),
                  Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── 3. PHASE TRACKER (WATER LOADING) ────────────────────────────
          _buildSectionHeader(
            Icons.water_drop,
            'PHASE: ${data.phase.toUpperCase()}',
            Colors.blueAccent,
          ),
          _DfcCard(
            height: 150,
            glow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DAILY WATER INTAKE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${data.waterIntake.toStringAsFixed(1)} / ${data.waterTarget.toStringAsFixed(1)} GAL',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (data.waterIntake / data.waterTarget).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 12,
                    backgroundColor: Colors.white10,
                    color: Colors.blueAccent,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(Icons.remove, '- 0.5 Gal', () {
                      _controller.adjustWaterIntake(-0.5);
                    }),
                    _buildQuickActionButton(Icons.add, '+ 0.5 Gal', () {
                      _controller.adjustWaterIntake(0.5);
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 4. MACROS & NUTRITION RESTRICTIONS ──────────────────────────
          _buildSectionHeader(
            Icons.restaurant_menu,
            'NUTRITION RESTRICTIONS',
            Colors.orangeAccent,
          ),
          _DfcCard(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: _buildRestrictionItem(
                    'CARBS',
                    '< ${data.carbsLimit}g',
                    Colors.orangeAccent,
                  ),
                ),
                Container(width: 1, color: Colors.white10),
                Expanded(
                  child: _buildRestrictionItem(
                    'SODIUM',
                    '< ${data.sodiumLimit}mg',
                    Colors.orangeAccent,
                  ),
                ),
                Container(width: 1, color: Colors.white10),
                Expanded(
                  child: _buildRestrictionItem(
                    'FIBER',
                    'Zero',
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 5. TRAJECTORY TIMELINE ──────────────────────────────────────
          _buildSectionHeader(
            Icons.timeline,
            'CUT TRAJECTORY',
            Colors.purpleAccent,
          ),
          _DfcCard(
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTrajectoryRow(
                  'Tuesday (Today)',
                  '${data.currentWeight.toStringAsFixed(1)} lbs',
                  isCurrent: true,
                ),
                _buildTrajectoryRow('Wednesday', '161.0 lbs'),
                _buildTrajectoryRow('Thursday (Sweat Start)', '158.5 lbs'),
                _buildTrajectoryRow(
                  'Friday (Weigh-in)',
                  '155.0 lbs',
                  isFinal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────────

  Widget _buildMetricCard(String label, String value, Color valueColor) {
    return _DfcCard(
      height: 100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blueAccent.withValues(alpha: 0.1),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictionItem(String label, String value, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTrajectoryRow(
    String day,
    String target, {
    bool isCurrent = false,
    bool isFinal = false,
  }) {
    return Row(
      children: [
        Icon(
          isFinal
              ? Icons.flag
              : (isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
          color: isFinal
              ? Colors.cyanAccent
              : (isCurrent ? Colors.greenAccent : Colors.white38),
          size: 16,
        ),
        const SizedBox(width: 12),
        Text(
          day,
          style: TextStyle(
            color: isCurrent || isFinal ? Colors.white : Colors.white54,
            fontWeight: isCurrent || isFinal
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          target,
          style: TextStyle(
            color: isFinal ? Colors.cyanAccent : Colors.white70,
            fontWeight: isFinal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final state = _controller.state;

            if (state is WeightCutInitial || state is WeightCutLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              );
            }

            if (state is WeightCutError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (state is WeightCutLoaded) {
              return _buildContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _DfcCard extends StatelessWidget {
  const _DfcCard({
    required this.height,
    this.glow = false,
    required this.child,
  });

  final Widget child;
  final bool glow;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E17),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: Colors.blueAccent.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
