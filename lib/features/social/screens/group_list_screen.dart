import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/config/router_config.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/group_service.dart';
import '../../../shared/models/community/group_model.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GroupModel> _myGroups = [];
  List<GroupModel> _discoverGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final groupService = context.read<GroupService>();
    final userId =
        auth.currentUser?.uid ??
        (auth.isDemoUser ? AuthService.demoUserId : null);

    final results = await Future.wait([
      userId != null
          ? groupService.getMyGroups(userId)
          : Future.value(<GroupModel>[]),
      groupService.getPublicGroups(),
    ]);

    if (mounted) {
      setState(() {
        _myGroups = results[0];
        _discoverGroups = results[1];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Groups',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: DesignTokens.neonCyan,
            ),
            tooltip: 'Create Group',
            onPressed: () async {
              final created = await context.push<bool>(
                RouterConfig.createGroupPath,
              );
              if (created == true) _loadGroups();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'MY GROUPS'),
            Tab(text: 'DISCOVER'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DesignTokens.neonCyan),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGroupList(
                  _myGroups,
                  emptyMsg: 'You haven\'t joined any groups yet',
                ),
                _buildGroupList(_discoverGroups, emptyMsg: 'No groups found'),
              ],
            ),
    );
  }

  Widget _buildGroupList(List<GroupModel> groups, {required String emptyMsg}) {
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 56,
              color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Group'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.neonCyan,
                side: const BorderSide(color: DesignTokens.neonCyan),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                final created = await context.push<bool>(
                  RouterConfig.createGroupPath,
                );
                if (created == true) _loadGroups();
              },
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: DesignTokens.neonCyan,
      onRefresh: _loadGroups,
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.spacingL),
        itemCount: groups.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: DesignTokens.spacingM),
        itemBuilder: (_, i) => _GroupCard(
          group: groups[i],
          onTap: () => context.push(
            RouterConfig.groupDetailPath.replaceFirst(':groupId', groups[i].id),
          ),
        ),
      ),
    );
  }
}

// ── Group card widget ─────────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.onTap});
  final GroupModel group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.neonCyan.withValues(alpha: 0.12),
            width: DesignTokens.borderThin,
          ),
        ),
        child: Row(
          children: [
            // Group icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _categoryColor(group.category).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _categoryIcon(group.category),
                color: _categoryColor(group.category),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          group.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (group.privacy == GroupPrivacy.private) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.lock,
                          size: 13,
                          color: DesignTokens.neonAmber,
                        ),
                      ],
                      if (group.privacy == GroupPrivacy.secret) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.visibility_off,
                          size: 13,
                          color: DesignTokens.neonMagenta,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatCount(group.memberCount)} members  •  ${_categoryLabel(group.category)}',
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  static IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'gym':
        return Icons.fitness_center;
      case 'team':
        return Icons.people;
      case 'fan_club':
        return Icons.star;
      case 'promotion':
        return Icons.campaign;
      default:
        return Icons.groups;
    }
  }

  static Color _categoryColor(String cat) {
    switch (cat) {
      case 'gym':
        return DesignTokens.neonGreen;
      case 'team':
        return DesignTokens.neonCyan;
      case 'fan_club':
        return DesignTokens.neonGold;
      case 'promotion':
        return DesignTokens.neonMagenta;
      default:
        return DesignTokens.neonAmber;
    }
  }

  static String _categoryLabel(String cat) {
    switch (cat) {
      case 'gym':
        return 'Gym';
      case 'team':
        return 'Team';
      case 'fan_club':
        return 'Fan Club';
      case 'promotion':
        return 'Promotion';
      default:
        return 'General';
    }
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
