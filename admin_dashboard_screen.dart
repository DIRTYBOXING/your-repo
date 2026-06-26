import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E17),
        title: const Text(
          'DFC COMMAND CENTER',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        elevation: 0,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High-level Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('FIGHTERS', '142', Colors.blueAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('EVENTS', '3', Colors.redAccent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('GYMS', '18', Colors.greenAccent),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'OPERATIONS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Grid of Admin Actions
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    context,
                    title: 'Fighter Roster',
                    icon: Icons.sports_mma,
                    color: Colors.blueAccent,
                    route: '/admin/fighters', // To be defined in your GoRouter
                  ),
                  _buildActionCard(
                    context,
                    title: 'Events & PPV',
                    icon: Icons.event,
                    color: Colors.redAccent,
                    route: '/admin/events',
                  ),
                  _buildActionCard(
                    context,
                    title: 'Gym Directory',
                    icon: Icons.fitness_center,
                    color: Colors.greenAccent,
                    route: '/admin/gyms',
                  ),
                  _buildActionCard(
                    context,
                    title: 'Content Brain',
                    icon: Icons.auto_awesome,
                    color: Colors.purpleAccent,
                    route: '/admin/content',
                  ),
                  _buildActionCard(
                    context,
                    title: 'Analytics',
                    icon: Icons.analytics,
                    color: Colors.orangeAccent,
                    route: '/admin/analytics',
                  ),
                  _buildActionCard(
                    context,
                    title: 'SmartCoach AI',
                    icon: Icons.psychology,
                    color: Colors.orangeAccent,
                    route: '/admin/smartcoach',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C23),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        context.push(route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E17),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
