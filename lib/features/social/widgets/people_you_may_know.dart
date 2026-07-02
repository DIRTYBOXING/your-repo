import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../shared/services/enhanced_friends_service.dart';
import '../../../shared/services/friend_suggestions_engine.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SUGGESTED CONNECTIONS — professional relationship cards
///
/// • Horizontal scroll of user cards
/// • Avatar + name + mutual friends count + "Add Friend" button
/// • Dismiss (X) button on each card
/// • Uses FriendSuggestionsEngine data when available, demo seeds otherwise
/// ═══════════════════════════════════════════════════════════════════════════
class PeopleYouMayKnowBar extends StatefulWidget {
  const PeopleYouMayKnowBar({super.key});

  @override
  State<PeopleYouMayKnowBar> createState() => _PeopleYouMayKnowBarState();
}

class _PeopleYouMayKnowBarState extends State<PeopleYouMayKnowBar> {
  final Set<String> _dismissed = {};
  late Future<List<_Suggestion>> _suggestionsFuture;

  // Demo suggestions — fallback when Firestore returns empty
  static const _demoSuggestions = <_Suggestion>[
    _Suggestion(
      userId: 'jordan_roesler',
      name: 'Jordan Roesler',
      role: 'Fighter',
      mutualCount: 14,
      avatarIcon: Icons.sports_mma,
    ),
    _Suggestion(
      userId: 'joshy_bomber_richards',
      name: 'Joshy "Bomber" Richards',
      role: 'Fighter',
      mutualCount: 9,
      avatarIcon: Icons.sports_mma,
    ),
    _Suggestion(
      userId: 'joey_demicoli',
      name: 'Joey Demicoli',
      role: 'Promoter',
      mutualCount: 22,
      avatarIcon: Icons.campaign,
    ),
    _Suggestion(
      userId: 'sumire_yamanaka',
      name: 'Sumire Yamanaka',
      role: 'Fighter',
      mutualCount: 7,
      avatarIcon: Icons.sports_mma,
    ),
    _Suggestion(
      userId: 'justis_huni',
      name: 'Justis Huni',
      role: 'Fighter',
      mutualCount: 31,
      avatarIcon: Icons.sports_mma,
    ),
    _Suggestion(
      userId: 'stephanie_cutting',
      name: 'Stephanie Lee Cutting',
      role: 'Fighter',
      mutualCount: 11,
      avatarIcon: Icons.sports_mma,
    ),
    _Suggestion(
      userId: 'karim_maatalla',
      name: 'Karim Maatalla',
      role: 'Fighter',
      mutualCount: 16,
      avatarIcon: Icons.sports_mma,
    ),
    _Suggestion(
      userId: 'john_scida',
      name: 'John Scida',
      role: 'Promoter',
      mutualCount: 19,
      avatarIcon: Icons.campaign,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _loadSuggestions();
  }

  Future<List<_Suggestion>> _loadSuggestions() async {
    try {
      final engine = FriendSuggestionsEngine();
      final results = await engine.generateSuggestions(limit: 10);
      if (results.isNotEmpty) {
        return results
            .map(
              (s) => _Suggestion(
                userId: s.userId,
                name: s.userName,
                role: s.userRole.isNotEmpty
                    ? '${s.userRole[0].toUpperCase()}${s.userRole.substring(1)}'
                    : 'Fan',
                mutualCount: s.mutualFriendsCount,
                avatarIcon: _iconForRole(s.userRole),
              ),
            )
            .toList();
      }
    } catch (_) {
      // Fall through to demo data
    }
    return _demoSuggestions;
  }

  static IconData _iconForRole(String role) {
    switch (role.toLowerCase()) {
      case 'fighter':
        return Icons.sports_mma;
      case 'coach':
        return Icons.fitness_center;
      case 'promoter':
        return Icons.campaign;
      case 'gym':
        return Icons.store;
      case 'sponsor':
        return Icons.handshake;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Suggested connections',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/friend-suggestions'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: DesignTokens.neonCyan,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Horizontal card scroll
        SizedBox(
          height: 240,
          child: FutureBuilder<List<_Suggestion>>(
            future: _suggestionsFuture,
            builder: (context, snapshot) {
              final suggestions = snapshot.data ?? _demoSuggestions;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final s = suggestions[index];
                  if (_dismissed.contains(s.userId)) {
                    return const SizedBox.shrink();
                  }
                  return _SuggestionCard(
                    suggestion: s,
                    onDismiss: () =>
                        setState(() => _dismissed.add(s.userId)),
                    onAdd: () async {
                      final svc = context.read<EnhancedFriendsService>();
                      bool sent = true;
                      try {
                        await svc.sendFriendRequest(recipientId: s.userId);
                      } catch (_) {
                        sent = false;
                      }
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            sent
                                ? 'Friend request sent to ${s.name}'
                                : 'Could not send request — try again',
                          ),
                          backgroundColor: DesignTokens.bgCard,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onTap: () => context.push('/user/${s.userId}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.userId,
    required this.name,
    required this.role,
    required this.mutualCount,
    required this.avatarIcon,
  });
  final String userId;
  final String name;
  final String role;
  final int mutualCount;
  final IconData avatarIcon;
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onDismiss,
    required this.onAdd,
    required this.onTap,
  });

  final _Suggestion suggestion;
  final VoidCallback onDismiss;
  final VoidCallback onAdd;
  final VoidCallback onTap;

  Color _roleColor() {
    return AppTheme.getRoleColor(suggestion.role);
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: GlassPanel(
        width: 176,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        backgroundColor: DesignTokens.bgCard,
        borderColor: Colors.white.withValues(alpha: 0.08),
        borderWidth: 0.5,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DesignTokens.radiusSmall),
                    ),
                    color: const Color(0xFF101A2A),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    children: [
                      Icon(
                        suggestion.avatarIcon,
                        color: _roleColor().withValues(alpha: 0.82),
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        suggestion.role.toUpperCase(),
                        style: TextStyle(
                          color: _roleColor().withValues(alpha: 0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.bgSecondary,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1.2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(suggestion.name),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          suggestion.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${suggestion.mutualCount} shared connections',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFF122338),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 0.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Connect',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Dismiss X button
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onDismiss,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white54,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
