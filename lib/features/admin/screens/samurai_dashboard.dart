import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import '../../../core/config/router_constants.dart' as routes;
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/admin_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// 🥷 SAMURAI DASHBOARD — Master Control System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The command center for the entire DFC ecosystem.
///
/// Access:
/// • System status
/// • Growth metrics
/// • Ninja alerts
/// • User management
/// • Content moderation
/// • Campaign control
/// • Analytics
///
/// ═══════════════════════════════════════════════════════════════════════════
class SamuraiDashboard extends StatefulWidget {
  final String adminId;

  const SamuraiDashboard({super.key, required this.adminId});

  @override
  State<SamuraiDashboard> createState() => _SamuraiDashboardState();
}

class _SamuraiDashboardState extends State<SamuraiDashboard> {
  final _adminService = AdminService();

  SystemStatus? _systemStatus;
  GrowthMetrics? _growthMetrics;
  SystemHealth? _systemHealth;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final status = await _adminService.getSystemStatus();
      final growth = await _adminService.getGrowthMetrics();
      final health = await _adminService.getSystemHealth();

      setState(() {
        _systemStatus = status;
        _growthMetrics = growth;
        _systemHealth = health;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load dashboard: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.neonGreen),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: _buildDashboard(),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      title: const Row(
        children: [
          Text('🥷', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text(
            'Samurai Panel',
            style: TextStyle(
              color: AppTheme.neonGreen,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        if (_systemHealth != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: _systemHealth!.isHealthy ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  _systemHealth!.isHealthy ? 'Healthy' : 'Issues',
                  style: TextStyle(
                    color: _systemHealth!.isHealthy ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSystemStatusSection(),
          const SizedBox(height: 24),
          _buildGrowthSection(),
          const SizedBox(height: 24),
          _buildNinjaAlertsSection(),
          const SizedBox(height: 24),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildSystemStatusSection() {
    if (_systemStatus == null) return const SizedBox.shrink();

    return _buildSection(
      title: 'DFC System Status',
      icon: Icons.dashboard,
      child: Column(
        children: [
          _buildMetricRow(
            label: 'Users Online',
            value: _systemStatus!.usersOnline.toString(),
            icon: Icons.people,
            color: AppTheme.neonGreen,
          ),
          _buildMetricRow(
            label: 'Posts Today',
            value: _systemStatus!.postsToday.toString(),
            icon: Icons.article,
            color: AppTheme.accentTeal,
          ),
          _buildMetricRow(
            label: 'Messages Sent',
            value: _systemStatus!.messagesToday.toString(),
            icon: Icons.chat,
            color: AppTheme.accentPurple,
          ),
          _buildMetricRow(
            label: 'Campaign Donations',
            value: '\$${_systemStatus!.donationsToday.toStringAsFixed(2)}',
            icon: Icons.favorite,
            color: Colors.pinkAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthSection() {
    if (_growthMetrics == null) return const SizedBox.shrink();

    return _buildSection(
      title: 'Growth Rate',
      icon: Icons.trending_up,
      child: Column(
        children: [
          _buildMetricRow(
            label: 'New Users Today',
            value: _growthMetrics!.newUsersToday.toString(),
            icon: Icons.person_add,
            color: Colors.greenAccent,
          ),
          _buildMetricRow(
            label: 'Total Users',
            value: _growthMetrics!.totalUsers.toString(),
            icon: Icons.groups,
            color: AppTheme.neonGreen,
          ),
          _buildMetricRow(
            label: 'Invites Sent (7d)',
            value: _growthMetrics!.invitesSent.toString(),
            icon: Icons.share,
            color: AppTheme.accentTeal,
          ),
          _buildMetricRow(
            label: 'Active Regions',
            value: _growthMetrics!.activeRegions.toString(),
            icon: Icons.public,
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildNinjaAlertsSection() {
    if (_systemStatus == null) return const SizedBox.shrink();

    return _buildSection(
      title: '🥷 Ninja Alerts',
      icon: Icons.warning_amber,
      child: Column(
        children: [
          _buildAlertCard(
            label: 'Reports Pending Review',
            value: _systemStatus!.pendingReports.toString(),
            color: _systemStatus!.pendingReports > 10
                ? Colors.red
                : Colors.orange,
            onTap: () {
              context.push(
                routes.RouteConstants.adminNinjaModerationPath,
                extra: widget.adminId,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionCard(
              title: 'User\nManagement',
              icon: Icons.person_search,
              color: AppTheme.neonGreen,
              onTap: () {
                context.push(
                  routes.RouteConstants.adminUserManagementScreenPath,
                  extra: widget.adminId,
                );
              },
            ),
            _buildActionCard(
              title: 'Ninja\nModeration',
              icon: Icons.shield,
              color: Colors.deepOrange,
              onTap: () {
                context.push(
                  routes.RouteConstants.adminNinjaModerationPath,
                  extra: widget.adminId,
                );
              },
            ),
            _buildActionCard(
              title: 'Campaign\nControl',
              icon: Icons.campaign,
              color: AppTheme.accentPurple,
              onTap: () {
                context.push(
                  routes.RouteConstants.adminCampaignControlPath,
                  extra: widget.adminId,
                );
              },
            ),
            _buildActionCard(
              title: 'Analytics\nWar Room',
              icon: Icons.analytics,
              color: AppTheme.accentTeal,
              onTap: () {
                context.push(
                  routes.RouteConstants.adminAnalyticsWarRoomPath,
                  extra: widget.adminId,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.neonGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
