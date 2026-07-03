import 'package:flutter/material.dart';
import 'blue/controllers/gym_controller.dart';
import 'blue/state/gym_state.dart';
import 'gym_controller.dart';
import 'gym_state.dart';
import 'api_service.dart';
import 'blue/repositories/gym_repository.dart';
import 'gym_repository.dart';

class GymTeamScreen extends StatefulWidget {
  const GymTeamScreen({super.key});

  @override
  State<GymTeamScreen> createState() => _GymTeamScreenState();
}

class _GymTeamScreenState extends State<GymTeamScreen> {
  late final GymController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GymController(
      repository: GymRepository(apiService: ApiService()),
    );
    // Pass your real Gym ID here in production
    _controller.loadGymProfile('GYM-001');
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

            if (state is GymInitial || state is GymLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amberAccent),
              );
            }

            if (state is GymError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            if (state is GymLoaded) {
              return _buildContent(state);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(GymLoaded state) {
    final data = state.data;
    return RefreshIndicator(
      onRefresh: () => _controller.loadGymProfile('GYM-001'),
      color: Colors.amberAccent,
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
              const Expanded(
                child: Text(
                  'GYM & TEAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amberAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  'VERIFIED CAMP',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ─── 2. GYM PROFILE HERO ─────────────────────────────────────────
          _DfcCard(
            height: 180,
            glow: true,
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amberAccent, width: 2),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&q=80&w=400', // Update dynamically in production
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white54,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            data.location,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatBadge(
                            '${data.stats['fighters'] ?? 0} FIGHTERS',
                            Colors.cyanAccent,
                          ),
                          const SizedBox(width: 8),
                          _buildStatBadge(
                            '${data.stats['coaches'] ?? 0} COACHES',
                            Colors.purpleAccent,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 3. COACHING STAFF ───────────────────────────────────────────
          _buildSectionHeader(
            Icons.groups,
            'COACHING STAFF',
            Colors.purpleAccent,
          ),
          Row(
            children: [
              ...data.coaches
                  .take(2)
                  .map(
                    (coach) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildCoachCard(
                          name: coach['name'],
                          role: coach['role'],
                          avatarUrl: coach['avatarUrl'],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
          const SizedBox(height: 24),

          // ─── 4. ACTIVE ROSTER ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(
                Icons.format_list_bulleted,
                'ACTIVE ROSTER',
                Colors.cyanAccent,
              ),
              const Text(
                'VIEW ALL',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          _DfcCard(
            height: 260,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ...data.roster.map(
                  (fighter) => Column(
                    children: [
                      _buildRosterRow(
                        name: fighter['name'],
                        division: fighter['division'],
                        status: fighter['status'],
                        statusColor: Color(fighter['statusColorHex']),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.white10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 5. TRAINING SCHEDULE ────────────────────────────────────────
          _buildSectionHeader(
            Icons.calendar_today,
            'TODAY\'S SCHEDULE',
            Colors.orangeAccent,
          ),
          _DfcCard(
            height: 180,
            child: Column(
              children: [
                ...data.schedule.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildScheduleRow(
                      item['time'],
                      item['classType'],
                      Color(item['colorHex']),
                    ),
                  ),
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

  Widget _buildStatBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildCoachCard({
    required String name,
    required String role,
    required String avatarUrl,
  }) {
    return _DfcCard(
      height: 80,
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterRow({
    required String name,
    required String division,
    required String status,
    required Color statusColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white10,
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  division,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(String time, String classType, Color color) {
    return Row(
      children: [
        Text(
          time,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Container(width: 2, height: 24, color: color),
        const SizedBox(width: 16),
        Text(
          classType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
                  color: Colors.amberAccent.withValues(alpha: 0.05),
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
