import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/messaging/services/messaging_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';

String _cleanMemberText(String? value) {
  if (value == null) return '';
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isUsableMemberLabel(String value) {
  if (value.isEmpty) return false;
  if (!RegExp(r'[A-Za-z0-9]').hasMatch(value)) return false;
  return value.runes.any((codePoint) {
    final isAsciiControl = codePoint < 32 || codePoint == 127;
    return !isAsciiControl;
  });
}

String _resolveMemberName({String? displayName, String? username}) {
  final cleanedDisplayName = _cleanMemberText(displayName);
  if (_isUsableMemberLabel(cleanedDisplayName)) {
    return cleanedDisplayName;
  }

  final cleanedUsername = _cleanMemberText(username);
  if (_isUsableMemberLabel(cleanedUsername)) {
    return cleanedUsername;
  }

  return 'DFC Member';
}

String _resolveMemberSearchText(Map<String, dynamic> data) {
  final resolvedName = _resolveMemberName(
    displayName: data['displayName'] as String?,
    username: data['username'] as String?,
  );
  final username = _cleanMemberText(data['username'] as String?);
  final email = _cleanMemberText(data['email'] as String?);
  return [
    resolvedName,
    username,
    email,
  ].where((value) => value.isNotEmpty).join(' ').toLowerCase();
}

/// ═══════════════════════════════════════════════════════════════════════════
/// MEMBER DIRECTORY — Free for all registered users
/// See who signed up. Message anyone. Connect with anyone.
/// ═══════════════════════════════════════════════════════════════════════════
class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() => _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState extends State<MemberDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  String _roleFilter = 'ALL';

  static const _roles = [
    'ALL',
    'FIGHTER',
    'COACH',
    'GYM',
    'PROMOTER',
    'SPONSOR',
    'FAN',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final currentUser = auth.currentUser;
    final currentUserId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        foregroundColor: AppTheme.neonCyan,
        elevation: 0,
        title: const Text(
          'MEMBERS',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              Icons.chat_bubble,
              color: AppTheme.neonCyan.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: 56,
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search members...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.neonCyan,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.white38,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.neonCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.neonCyan.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.neonCyan),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) =>
                    setState(() => _search = v.toLowerCase().trim()),
              ),
            ),
          ),

          // ── Role filter chips ──
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _roles.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final role = _roles[i];
                final selected = _roleFilter == role;
                return GestureDetector(
                  onTap: () => setState(() => _roleFilter = role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.neonCyan.withValues(alpha: 0.18)
                          : AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppTheme.neonCyan : Colors.white24,
                      ),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        color: selected ? AppTheme.neonCyan : Colors.white60,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── Member list ──
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .limit(200)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.neonCyan),
                  );
                }
                if (snap.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load members',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                var docs = (snap.data?.docs ?? [])
                    .where((d) => d.id != currentUserId)
                    .toList();

                // Client-side search
                if (_search.isNotEmpty) {
                  docs = docs.where((d) {
                    final searchText = _resolveMemberSearchText(d.data());
                    return searchText.contains(_search);
                  }).toList();
                }

                // Role filter
                if (_roleFilter != 'ALL') {
                  docs = docs.where((d) {
                    final role = ((d.data()['role'] ?? '') as String)
                        .toUpperCase();
                    return role == _roleFilter.toLowerCase() ||
                        role == _roleFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 52,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _search.isNotEmpty || _roleFilter != 'ALL'
                              ? 'No members match your filter'
                              : 'No members yet — be the first!',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort by display name on the client
                docs.sort((a, b) {
                  final na = _resolveMemberName(
                    displayName: a.data()['displayName'] as String?,
                    username: a.data()['username'] as String?,
                  ).toLowerCase();
                  final nb = _resolveMemberName(
                    displayName: b.data()['displayName'] as String?,
                    username: b.data()['username'] as String?,
                  ).toLowerCase();
                  return na.compareTo(nb);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final user = UserModel.fromFirestore(doc);
                    return _MemberCard(
                      user: user,
                      currentUserId: currentUserId,
                      currentUserName: currentUser?.displayName ?? 'User',
                      currentUserPhotoUrl: currentUser?.photoURL ?? '',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Member card
// ─────────────────────────────────────────────────────────────────────────────
class _MemberCard extends StatefulWidget {
  final UserModel user;
  final String currentUserId;
  final String currentUserName;
  final String currentUserPhotoUrl;

  const _MemberCard({
    required this.user,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPhotoUrl,
  });

  @override
  State<_MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<_MemberCard> {
  bool _messagingBusy = false;
  bool _connectingBusy = false;

  String get _memberName => _resolveMemberName(
    displayName: widget.user.displayName,
    username: widget.user.username,
  );

  Color get _roleColor {
    switch (widget.user.role) {
      case UserRole.fighter:
        return AppTheme.neonCyan;
      case UserRole.coach:
        return AppTheme.neonGreen;
      case UserRole.gym:
        return AppTheme.neonMagenta;
      case UserRole.promoter:
        return AppTheme.neonOrange;
      case UserRole.sponsor:
        return AppTheme.neonPurple;
      case UserRole.admin:
        return AppTheme.errorColor;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _startChat(BuildContext context) async {
    if (_messagingBusy || widget.currentUserId.isEmpty) return;
    setState(() => _messagingBusy = true);
    try {
      final messaging = context.read<MessagingService>();
      final convId = await messaging.createConversation(
        currentUserId: widget.currentUserId,
        currentUserName: widget.currentUserName,
        otherUserId: widget.user.id,
        otherUserName: _memberName,
        currentUserPhotoUrl: widget.currentUserPhotoUrl,
        otherUserPhotoUrl: widget.user.photoUrl ?? '',
      );
      if (!context.mounted) return;
      context.push(
        '/messaging/chat/$convId',
        extra: {
          'otherName': _memberName,
          'otherPhotoUrl': widget.user.photoUrl ?? '',
          'otherUserId': widget.user.id,
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start chat: $e')));
    } finally {
      if (mounted) setState(() => _messagingBusy = false);
    }
  }

  Future<void> _connect(BuildContext context) async {
    if (_connectingBusy || widget.currentUserId.isEmpty) return;
    setState(() => _connectingBusy = true);
    try {
      final friends = context.read<EnhancedFriendsService>();
      await friends.sendFriendRequest(recipientId: widget.user.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent to $_memberName!'),
          backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.85),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send request: $e')));
    } finally {
      if (mounted) setState(() => _connectingBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _memberName;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final roleLabel = widget.user.role.displayName.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _roleColor.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Avatar ──
            DfcCircleAvatar(
              imageUrl: widget.user.photoUrl,
              radius: 24,
              backgroundColor: _roleColor.withValues(alpha: 0.18),
              borderColor: _roleColor.withValues(alpha: 0.35),
              borderWidth: 1,
              fallbackText: initials,
              fallbackIconColor: _roleColor,
            ),

            const SizedBox(width: 12),

            // ── Name + role badge ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppTheme.neonCyan,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _roleColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _roleColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: _roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Action buttons ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionBtn(
                  icon: Icons.chat_bubble_outline,
                  color: AppTheme.neonCyan,
                  loading: _messagingBusy,
                  onTap: () => _startChat(context),
                  tooltip: 'Message',
                ),
                const SizedBox(width: 8),
                _ActionBtn(
                  icon: Icons.person_add_outlined,
                  color: AppTheme.neonGreen,
                  loading: _connectingBusy,
                  onTap: () => _connect(context),
                  tooltip: 'Connect',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact action button
// ─────────────────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.loading,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
