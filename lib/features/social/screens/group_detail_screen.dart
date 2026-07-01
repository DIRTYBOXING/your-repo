import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/group_service.dart';
import '../../../shared/models/community/group_model.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final String groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupModel? _group;
  bool _loading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final gs = context.read<GroupService>();
    _currentUserId =
        auth.currentUser?.uid ??
        (auth.isDemoUser ? AuthService.demoUserId : null);
    final g = await gs.getGroupById(widget.groupId);
    if (mounted) {
      setState(() {
        _group = g;
        _loading = false;
      });
    }
  }

  bool get _isMember => _group?.isMember(_currentUserId ?? '') ?? false;
  bool get _isAdmin => _group?.isAdmin(_currentUserId ?? '') ?? false;
  bool get _hasAuthority => _group?.hasAuthority(_currentUserId ?? '') ?? false;

  Future<void> _toggleMembership() async {
    if (_group == null || _currentUserId == null) return;
    HapticFeedback.mediumImpact();
    final gs = context.read<GroupService>();
    if (_isMember) {
      await gs.leaveGroup(_group!.id, _currentUserId!);
    } else {
      await gs.joinGroup(_group!.id, _currentUserId!);
    }
    await _load();
  }

  Future<void> _deleteGroup() async {
    final gs = context.read<GroupService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        title: const Text(
          'Delete Group',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This cannot be undone. All members will be removed.',
          style: TextStyle(color: DesignTokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: DesignTokens.neonRed),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await gs.deleteGroup(_group!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: DesignTokens.neonCyan),
        ),
      );
    }

    if (_group == null) {
      return Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'Group not found',
            style: TextStyle(color: DesignTokens.textMuted),
          ),
        ),
      );
    }

    final group = _group!;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      body: RefreshIndicator(
        color: DesignTokens.neonCyan,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: DesignTokens.bgSecondary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _accentColor.withValues(alpha: 0.25),
                        DesignTokens.bgPrimary,
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
                      child: Row(
                        children: [
                          _groupIcon(48),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _privacyBadge,
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_formatCount(group.memberCount)} members',
                                      style: const TextStyle(
                                        color: DesignTokens.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                if (_isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: DesignTokens.bgCard,
                    onSelected: (val) {
                      if (val == 'delete') _deleteGroup();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: DesignTokens.neonRed,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Delete Group',
                              style: TextStyle(color: DesignTokens.neonRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // ── Join / Leave button ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: DesignTokens.spacingM,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _isMember
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Joined'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DesignTokens.neonGreen,
                                side: const BorderSide(
                                  color: DesignTokens.neonGreen,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _toggleMembership,
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.group_add, size: 16),
                              label: const Text('Join Group'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.neonCyan,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _toggleMembership,
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // ── About section ───────────────────────────
            SliverToBoxAdapter(
              child: _sectionCard(
                title: 'About',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group.description.isNotEmpty)
                      Text(
                        group.description,
                        style: const TextStyle(
                          color: DesignTokens.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    const SizedBox(height: 12),
                    _infoRow(
                      Icons.category,
                      'Category',
                      _categoryLabel(group.category),
                    ),
                    _infoRow(
                      Icons.calendar_today,
                      'Created',
                      _formatDate(group.createdAt),
                    ),
                    _infoRow(Icons.person, 'Creator', group.creatorId),
                  ],
                ),
              ),
            ),

            // ── Members preview ─────────────────────────
            SliverToBoxAdapter(
              child: _sectionCard(
                title: 'Members (${_formatCount(group.memberCount)})',
                child: Column(
                  children: [
                    ...group.adminIds.map((uid) => _memberTile(uid, 'Admin')),
                    ...group.moderatorIds.map(
                      (uid) => _memberTile(uid, 'Moderator'),
                    ),
                    ...group.memberIds
                        .where(
                          (uid) =>
                              !group.adminIds.contains(uid) &&
                              !group.moderatorIds.contains(uid),
                        )
                        .take(5)
                        .map((uid) => _memberTile(uid, 'Member')),
                    if (group.memberIds.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+ ${group.memberIds.length - 8} more',
                          style: const TextStyle(
                            color: DesignTokens.neonCyan,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Moderation section (admins only) ────────
            if (_hasAuthority)
              SliverToBoxAdapter(
                child: _sectionCard(
                  title: 'Moderation',
                  accent: DesignTokens.neonAmber,
                  child: Column(
                    children: [
                      _modAction(Icons.edit, 'Edit Group', _showEditGroupSheet),
                      _modAction(
                        Icons.push_pin,
                        'Pinned Posts',
                        _showPinnedPostsSheet,
                      ),
                      _modAction(
                        Icons.gavel,
                        'Banned Users (${group.bannedUserIds.length})',
                        _showBannedUsersSheet,
                      ),
                      _modAction(
                        Icons.rule,
                        'Group Rules',
                        _showGroupRulesSheet,
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ── Edit group sheet ──────────────────────────────────────────────────

  Future<void> _showEditGroupSheet() async {
    if (_group == null) return;
    final group = _group!;
    final nameCtrl = TextEditingController(text: group.name);
    final descCtrl = TextEditingController(text: group.description);
    GroupPrivacy privacy = group.privacy;
    final String category = group.category;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Group',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Group Name',
                      labelStyle: TextStyle(color: DesignTokens.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: DesignTokens.textMuted),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: DesignTokens.neonCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      labelStyle: TextStyle(color: DesignTokens.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: DesignTokens.textMuted),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: DesignTokens.neonCyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<GroupPrivacy>(
                    initialValue: privacy,
                    dropdownColor: DesignTokens.bgCard,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Privacy',
                      labelStyle: TextStyle(color: DesignTokens.textMuted),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: DesignTokens.textMuted),
                      ),
                    ),
                    items: GroupPrivacy.values
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                              p.name[0].toUpperCase() + p.name.substring(1),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheet(() => privacy = v);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.neonCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final gs = context.read<GroupService>();
                        await gs.updateGroup(
                          groupId: group.id,
                          name: nameCtrl.text.trim().isEmpty
                              ? null
                              : nameCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          privacy: privacy,
                          category: category,
                        );
                        await _load();
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    descCtrl.dispose();
  }

  // ── Pinned posts sheet ───────────────────────────────────────────────

  Future<void> _showPinnedPostsSheet() async {
    if (_group == null) return;
    final group = _group!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pinned Posts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (group.pinnedPostIds.isEmpty)
                const Text(
                  'No pinned posts. Pin a post from the group feed to surface it here.',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 14),
                )
              else
                ...group.pinnedPostIds.map(
                  (postId) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.push_pin,
                      color: DesignTokens.neonCyan,
                      size: 20,
                    ),
                    title: Text(
                      postId,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.push_pin_outlined,
                        color: DesignTokens.neonAmber,
                        size: 18,
                      ),
                      tooltip: 'Unpin',
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final gs = context.read<GroupService>();
                        await gs.unpinPost(group.id, postId);
                        await _load();
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Banned users sheet ───────────────────────────────────────────────

  Future<void> _showBannedUsersSheet() async {
    if (_group == null) return;
    final group = _group!;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Banned Users (${group.bannedUserIds.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              if (group.bannedUserIds.isEmpty)
                const Text(
                  'No banned users in this group.',
                  style: TextStyle(color: DesignTokens.textMuted, fontSize: 14),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView(
                    shrinkWrap: true,
                    children: group.bannedUserIds
                        .map(
                          (uid) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: DesignTokens.neonRed.withValues(
                                alpha: 0.12,
                              ),
                              child: Text(
                                uid.isNotEmpty ? uid[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: DesignTokens.neonRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              uid,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: TextButton(
                              onPressed: () async {
                                Navigator.of(ctx).pop();
                                final gs = context.read<GroupService>();
                                await gs.unbanUser(group.id, uid);
                                await _load();
                              },
                              child: const Text(
                                'Unban',
                                style: TextStyle(color: DesignTokens.neonGreen),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Group rules sheet ────────────────────────────────────────────────

  Future<void> _showGroupRulesSheet() async {
    if (_group == null) return;
    final group = _group!;
    final rules = Map<String, dynamic>.from(group.rules);
    final newRuleCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Rules',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (rules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No rules set yet.',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView(
                        shrinkWrap: true,
                        children: rules.entries
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (e) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: DesignTokens.neonAmber
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    '${e.key + 1}',
                                    style: const TextStyle(
                                      color: DesignTokens.neonAmber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  e.value.value.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: DesignTokens.neonRed,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setSheet(() => rules.remove(e.value.key));
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newRuleCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a rule…',
                            hintStyle: TextStyle(color: DesignTokens.textMuted),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: DesignTokens.neonAmber,
                              ),
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: DesignTokens.neonAmber,
                        ),
                        onPressed: () {
                          final text = newRuleCtrl.text.trim();
                          if (text.isNotEmpty) {
                            setSheet(() {
                              rules['rule_${rules.length + 1}'] = text;
                              newRuleCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.neonAmber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final gs = context.read<GroupService>();
                        await gs.updateRules(group.id, rules);
                        await _load();
                      },
                      child: const Text('Save Rules'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    newRuleCtrl.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────

  Color get _accentColor {
    switch (_group?.category) {
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

  Widget get _privacyBadge {
    final g = _group!;
    final IconData icon;
    final String label;
    final Color color;
    switch (g.privacy) {
      case GroupPrivacy.private:
        icon = Icons.lock;
        label = 'Private';
        color = DesignTokens.neonAmber;
        break;
      case GroupPrivacy.secret:
        icon = Icons.visibility_off;
        label = 'Secret';
        color = DesignTokens.neonMagenta;
        break;
      default:
        icon = Icons.public;
        label = 'Public';
        color = DesignTokens.neonGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupIcon(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: _accentColor.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Icon(_catIcon, color: _accentColor, size: size * 0.5),
  );

  IconData get _catIcon {
    switch (_group?.category) {
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

  Widget _sectionCard({
    required String title,
    required Widget child,
    Color accent = DesignTokens.neonCyan,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: DesignTokens.spacingS,
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: accent.withValues(alpha: 0.12),
            width: DesignTokens.borderThin,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: DesignTokens.textMuted),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: DesignTokens.textMuted, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(String uid, String role) {
    final Color badge;
    switch (role) {
      case 'Admin':
        badge = DesignTokens.neonGold;
        break;
      case 'Moderator':
        badge = DesignTokens.neonAmber;
        break;
      default:
        badge = DesignTokens.textMuted;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: DesignTokens.neonCyan.withValues(alpha: 0.12),
            child: Text(
              uid.isNotEmpty ? uid[0].toUpperCase() : '?',
              style: const TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              uid,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badge.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: badge,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: DesignTokens.neonAmber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: DesignTokens.textMuted,
            ),
          ],
        ),
      ),
    );
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

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
