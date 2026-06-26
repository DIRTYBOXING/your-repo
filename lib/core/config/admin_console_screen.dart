import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/system_health_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ADMIN CONSOLE
/// Master control for User Management, PPV Approvals, and Moderation.
/// ═══════════════════════════════════════════════════════════════════════════
class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _healthService = SystemHealthService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.panel,
        title: const Text(
          'DFC GOVERNANCE CONSOLE',
          style: TextStyle(
            color: AppColors.neonRed,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.neonRed,
          labelColor: AppColors.neonRed,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: 'USER MANAGEMENT'),
            Tab(text: 'PPV APPROVALS'),
            Tab(text: 'MODERATION'),
            Tab(text: 'SYSTEM CONFIG'),
            Tab(text: 'SYSTEM HEALTH'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildUserManagement(),
          _buildPpvApprovals(),
          const Center(
            child: Text(
              'Content Moderation Queue',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          const Center(
            child: Text(
              'Global System Settings',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          _buildSystemHealth(),
        ],
      ),
    );
  }

  Widget _buildUserManagement() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5, // Mock data count
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.neonCyan,
            child: Icon(Icons.person, color: Colors.black),
          ),
          title: Text(
            'User ${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Text(
            'Role: Fighter | Status: Active',
            style: TextStyle(color: Colors.white54),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppColors.panel,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suspend',
                child: Text(
                  'Suspend Account',
                  style: TextStyle(color: AppColors.neonOrange),
                ),
              ),
              const PopupMenuItem(
                value: 'ban',
                child: Text(
                  'Ban Device',
                  style: TextStyle(color: AppColors.neonRed),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPpvApprovals() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2, // Mock data count
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonAmber.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DFC Fight Night 14',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Requested by: Promoter XYZ',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {},
                child: const Text('APPROVE'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemHealth() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _healthService.streamLatestReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.neonCyan),
          );
        }

        final report = snapshot.data;
        if (report == null) {
          return const Center(
            child: Text(
              'No integrity report found. Scanner pending.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        final status = report['status'] ?? 'UNKNOWN';
        final statusColor = status == 'GREEN'
            ? AppColors.neonGreen
            : status == 'YELLOW'
            ? AppColors.neonAmber
            : AppColors.neonRed;

        final errors = List<String>.from(report['errors'] ?? []);
        final warnings = List<String>.from(report['warnings'] ?? []);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(
                    status == 'GREEN'
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: statusColor,
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLATFORM HEALTH',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CRITICAL ERRORS',
              style: TextStyle(
                color: AppColors.neonRed,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            if (errors.isEmpty)
              const Text(
                'No critical errors detected.',
                style: TextStyle(color: Colors.white54),
              ),
            for (final e in errors)
              ListTile(
                leading: const Icon(Icons.error, color: AppColors.neonRed),
                title: Text(e, style: const TextStyle(color: Colors.white)),
                tileColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'WARNINGS',
              style: TextStyle(
                color: AppColors.neonAmber,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            if (warnings.isEmpty)
              const Text(
                'No warnings detected.',
                style: TextStyle(color: Colors.white54),
              ),
            for (final w in warnings)
              ListTile(
                leading: const Icon(Icons.warning, color: AppColors.neonAmber),
                title: Text(w, style: const TextStyle(color: Colors.white)),
                tileColor: AppColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
          ],
        );
      },
    );
  }
}
