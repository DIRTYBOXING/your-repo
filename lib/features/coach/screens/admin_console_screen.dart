import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
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
}
