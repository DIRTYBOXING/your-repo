import 'package:flutter/material.dart';
import 'smart_coach_controller.dart';
import 'smart_coach_repository.dart';
import 'api_service.dart';
import 'smart_coach_state.dart';

class SmartCoachScreen extends StatefulWidget {
  const SmartCoachScreen({super.key});

  @override
  State<SmartCoachScreen> createState() => _SmartCoachScreenState();
}

class _SmartCoachScreenState extends State<SmartCoachScreen> {
  late final SmartCoachController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SmartCoachController(
      repository: SmartCoachRepository(apiService: ApiService()),
    );
    _controller.loadSmartCoach();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            if (state is SmartCoachInitial || state is SmartCoachLoading) {
              return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
            }
            if (state is SmartCoachError) {
              return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.redAccent)));
            }
            if (state is SmartCoachLoaded) {
              return _buildContent(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SmartCoachLoaded state) {
    return RefreshIndicator(
      onRefresh: _controller.loadSmartCoach,
      color: Colors.cyanAccent,
      backgroundColor: const Color(0xFF0A0E17),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: [
              const SizedBox(height: 32),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'AI SMARTCOACH',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
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
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'ENGINE: ACTIVE',
                      style: TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // FIGHT PREDICTION ENGINE
              _buildSectionHeader(
                Icons.online_prediction,
                'OPPONENT SCOUTING & PREDICTION',
                Colors.cyanAccent,
              ),
              _DfcCard(
                height: 220,
                glow: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoutProfile(
                            'Heath Ewart',
                            'Striker',
                            '${state.data.winProbability}% Win Prob',
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildScoutProfile(
                            state.data.opponent,
                            'Grappler',
                            '${100 - state.data.winProbability}% Win Prob',
                            isRedCorner: false,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.cyanAccent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Text(
                        'AI ANALYSIS: Ewart\'s takedown defense (88%) neutralizes Johnson\'s primary win condition. Expect a standing battle favoring Ewart\'s volume.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // STYLE & TRAIT BREAKDOWN
              _buildSectionHeader(
                Icons.radar,
                'STYLE BREAKDOWN: HEATH EWART',
                Colors.purpleAccent,
              ),
              Row(
                children: [
                  Expanded(
                    child: _DfcCard(
                      height: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STRENGTHS',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTraitBar(
                            'Distance Management',
                            0.92,
                            Colors.greenAccent,
                          ),
                          _buildTraitBar(
                            'Cardio Output',
                            0.88,
                            Colors.greenAccent,
                          ),
                          _buildTraitBar(
                            'Counter Right Cross',
                            0.85,
                            Colors.greenAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DfcCard(
                      height: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WEAKNESSES',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTraitBar(
                            'Clinch Exits',
                            0.45,
                            Colors.redAccent,
                          ),
                          _buildTraitBar(
                            'Leg Kick Defense',
                            0.52,
                            Colors.redAccent,
                          ),
                          _buildTraitBar(
                            'Submission Escapes',
                            0.60,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // WORKLOAD & INJURY RISK
              _buildSectionHeader(
                Icons.warning_amber_rounded,
                'WORKLOAD & INJURY TELEMETRY',
                Colors.orangeAccent,
              ),
              _DfcCard(
                height: 140,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ACUTE TRAINING LOAD',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.data.workloadStatus,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Spike in sparring rounds detected over 7 days. Recommend deload phase.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: CircularProgressIndicator(
                            value: 0.85,
                            strokeWidth: 8,
                            backgroundColor: Colors.white10,
                            color: Colors.orangeAccent,
                          ),
                        ),
                        const Text(
                          '85%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SESSION PLANNER
              _buildSectionHeader(
                Icons.calendar_month,
                'AI SESSION PLANNER',
                Colors.blueAccent,
              ),
              _DfcCard(
                height: 120,
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY: ${state.data.title.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.data.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ],
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
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

  Widget _buildScoutProfile(
    String name,
    String style,
    String prob, {
    bool isRedCorner = true,
  }) {
    final color = isRedCorner ? Colors.redAccent : Colors.blueAccent;
    return Column(
      crossAxisAlignment: isRedCorner
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          style,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            prob,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTraitBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white10,
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

class _DfcCard extends StatelessWidget {
  final double height;
  final bool glow;
  final Widget child;

  const _DfcCard({
    required this.height,
    this.glow = false,
    required this.child,
  });

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
                  color: Colors.cyanAccent.withValues(alpha: 0.05),
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
