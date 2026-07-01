import 'package:flutter/material.dart';

class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      body: SafeArea(
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
                    'SYSTEM ADMIN',
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
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'SUPERUSER',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── 2. PLATFORM HEALTH ──────────────────────────────────────────
            _buildSectionHeader(
              Icons.monitor_heart,
              'PLATFORM HEALTH',
              Colors.greenAccent,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'API STATUS',
                    'ONLINE',
                    '12ms latency',
                    Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'ACTIVE USERS',
                    '12.4K',
                    '+4% this week',
                    Colors.cyanAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── 3. USER MANAGEMENT ──────────────────────────────────────────
            _buildSectionHeader(
              Icons.manage_accounts,
              'USER MANAGEMENT',
              Colors.blueAccent,
            ),
            _DfcCard(
              height: 220,
              child: Column(
                children: [
                  _buildAdminActionRow(
                    title: 'Review Athlete Profiles',
                    subtitle: '4 pending KYC approvals',
                    icon: Icons.verified_user,
                    color: Colors.blueAccent,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.white10),
                  ),
                  _buildAdminActionRow(
                    title: 'Gym & Camp Verification',
                    subtitle: '2 new camps requesting access',
                    icon: Icons.store,
                    color: Colors.amberAccent,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.white10),
                  ),
                  _buildAdminActionRow(
                    title: 'Suspensions & Bans',
                    subtitle: 'Manage restricted accounts',
                    icon: Icons.gavel,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 4. CONTENT MODERATION ───────────────────────────────────────
            _buildSectionHeader(
              Icons.policy,
              'CONTENT MODERATION',
              Colors.purpleAccent,
            ),
            _DfcCard(
              height: 150,
              child: Column(
                children: [
                  _buildAdminActionRow(
                    title: 'Flagged Media Uploads',
                    subtitle: '0 items in queue',
                    icon: Icons.video_library,
                    color: Colors.purpleAccent,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.white10),
                  ),
                  _buildAdminActionRow(
                    title: 'Community Chat Logs',
                    subtitle: 'Review reported messages',
                    icon: Icons.forum,
                    color: Colors.purpleAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── 5. SYSTEM LOGS & ALERTS ─────────────────────────────────────
            _buildSectionHeader(Icons.terminal, 'SYSTEM LOGS', Colors.white54),
            _DfcCard(
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSystemLog(
                    time: '07:02 AM',
                    message: 'Stripe webhook processed for PPV ID: DFC-001.',
                    isError: false,
                  ),
                  const SizedBox(height: 12),
                  _buildSystemLog(
                    time: '06:45 AM',
                    message:
                        'Cloud Function [processVideoUpload] timeout limit reached.',
                    isError: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSystemLog(
                    time: '06:30 AM',
                    message:
                        'Admin Heath E. elevated privileges for user ID 8492.',
                    isError: false,
                  ),
                  const SizedBox(height: 12),
                  _buildSystemLog(
                    time: '05:15 AM',
                    message:
                        'Daily AI Blueprint batch generation completed successfully.',
                    isError: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
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

  Widget _buildMetricCard(
    String label,
    String value,
    String subValue,
    Color color,
  ) {
    return _DfcCard(
      height: 110,
      glow: true,
      child: Column(
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
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionRow({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
      ],
    );
  }

  Widget _buildSystemLog({
    required String time,
    required String message,
    required bool isError,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: TextStyle(
            color: isError ? Colors.redAccent : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: isError
                  ? Colors.redAccent.withValues(alpha: 0.8)
                  : Colors.white70,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
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
                  color: Colors.greenAccent.withValues(alpha: 0.05),
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
