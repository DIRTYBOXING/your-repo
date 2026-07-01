import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_network_image.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MENTION AUTOCOMPLETE OVERLAY — Real-time @mention user search
///
/// • Detects @ trigger in text field
/// • Queries Firestore users collection with prefix match
/// • Shows floating overlay of matching users
/// • Inserts selected username into text field
/// • Falls back to demo users when offline
/// ═══════════════════════════════════════════════════════════════════════════
class MentionAutocompleteOverlay extends StatefulWidget {
  final TextEditingController textController;
  final FocusNode focusNode;
  final Widget child;

  const MentionAutocompleteOverlay({
    super.key,
    required this.textController,
    required this.focusNode,
    required this.child,
  });

  @override
  State<MentionAutocompleteOverlay> createState() =>
      _MentionAutocompleteOverlayState();
}

class _MentionAutocompleteOverlayState
    extends State<MentionAutocompleteOverlay> {
  OverlayEntry? _overlayEntry;
  List<_MentionUser> _suggestions = [];
  String _currentQuery = '';
  bool _searching = false;
  final LayerLink _layerLink = LayerLink();

  static final _mentionTrigger = RegExp(r'@([\w\d_.]{0,30})$');

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.textController.text;
    final selection = widget.textController.selection;

    if (!selection.isValid || selection.baseOffset != selection.extentOffset) {
      _removeOverlay();
      return;
    }

    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final match = _mentionTrigger.firstMatch(textBeforeCursor);

    if (match != null) {
      final query = match.group(1) ?? '';
      if (query != _currentQuery) {
        _currentQuery = query;
        _searchUsers(query);
      }
    } else {
      _currentQuery = '';
      _removeOverlay();
    }
  }

  Future<void> _searchUsers(String query) async {
    if (_searching) return;
    _searching = true;

    try {
      List<_MentionUser> results;

      if (query.isEmpty) {
        results = _getDemoSuggestions();
      } else {
        results = await _queryFirestore(query);
        if (results.isEmpty) {
          results = _getDemoSuggestions()
              .where(
                (u) =>
                    u.displayName.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        }
      }

      if (mounted && _currentQuery == query) {
        setState(() => _suggestions = results.take(6).toList());
        if (_suggestions.isNotEmpty) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } finally {
      _searching = false;
    }
  }

  Future<List<_MentionUser>> _queryFirestore(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: lowerQuery)
          .where('displayNameLower', isLessThan: '$lowerQuery\uf8ff')
          .limit(6)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return _MentionUser(
          uid: doc.id,
          displayName: data['displayName'] as String? ?? doc.id,
          role: data['role'] as String? ?? 'fan',
          avatarUrl: data['photoUrl'] as String?,
          isVerified: data['isVerified'] as bool? ?? false,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  List<_MentionUser> _getDemoSuggestions() {
    return const [
      _MentionUser(
        uid: 'zhang_weili',
        displayName: 'Zhang Weili',
        role: 'fighter',
        isVerified: true,
      ),
      _MentionUser(
        uid: 'stamp_fairtex',
        displayName: 'Stamp Fairtex',
        role: 'fighter',
        isVerified: true,
      ),
      _MentionUser(
        uid: 'amanda_serrano',
        displayName: 'Amanda Serrano',
        role: 'fighter',
        isVerified: true,
      ),
      _MentionUser(
        uid: 'coach_ray_mitchell',
        displayName: 'Coach Ray Mitchell',
        role: 'coach',
      ),
      _MentionUser(
        uid: 'jake_paul',
        displayName: 'Jake Paul',
        role: 'promoter',
        isVerified: true,
      ),
      _MentionUser(
        uid: 'dfc_official',
        displayName: 'Data Fight Central',
        role: 'admin',
        isVerified: true,
      ),
      _MentionUser(
        uid: 'christine_ferea',
        displayName: 'Christine Ferea',
        role: 'fighter',
        isVerified: true,
      ),
      _MentionUser(
        uid: 'bkfc_official',
        displayName: 'BKFC',
        role: 'promoter',
        isVerified: true,
      ),
      _MentionUser(
        uid: 'ibc_official',
        displayName: 'IBC Official',
        role: 'promoter',
        isVerified: true,
      ),
    ];
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 32,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, -8),
          followerAnchor: Alignment.bottomLeft,
          child: Material(
            color: Colors.transparent,
            child: _buildSuggestionList(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectUser(_MentionUser user) {
    final text = widget.textController.text;
    final selection = widget.textController.selection;
    final textBeforeCursor = text.substring(0, selection.baseOffset);
    final match = _mentionTrigger.firstMatch(textBeforeCursor);

    if (match != null) {
      final beforeMention = text.substring(0, match.start);
      final afterCursor = text.substring(selection.baseOffset);
      final username = user.displayName.replaceAll(' ', '_');
      final newText = '$beforeMention@$username $afterCursor';
      final newCursor =
          beforeMention.length + username.length + 2; // +2 for @ and space

      widget.textController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
    }

    _removeOverlay();
    _currentQuery = '';
  }

  Widget _buildSuggestionList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _suggestions.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
          itemBuilder: (context, index) {
            final user = _suggestions[index];
            return _buildUserTile(user);
          },
        ),
      ),
    );
  }

  Widget _buildUserTile(_MentionUser user) {
    final roleColor = _roleColor(user.role);
    return InkWell(
      onTap: () => _selectUser(user),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Avatar
            DfcCircleAvatar(
              imageUrl: user.avatarUrl,
              radius: 18,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              fallbackIconColor: roleColor,
            ),
            const SizedBox(width: 10),
            // Name + role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                            color: DesignTokens.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: DesignTokens.neonCyan,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _roleBadge(user.role),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // @ indicator
            Text(
              '@${user.displayName.replaceAll(' ', '_')}',
              style: TextStyle(
                color: DesignTokens.neonCyan.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'fighter':
        return DesignTokens.neonCyan;
      case 'coach':
        return DesignTokens.neonGreen;
      case 'promoter':
        return DesignTokens.neonMagenta;
      case 'gym':
        return DesignTokens.neonAmber;
      case 'media':
        return const Color(0xFF74B9FF);
      case 'admin':
        return DesignTokens.neonGold;
      default:
        return Colors.grey;
    }
  }

  String _roleBadge(String role) {
    switch (role) {
      case 'fighter':
        return '🥊 Fighter';
      case 'coach':
        return '🎯 Coach';
      case 'promoter':
        return '📣 Promoter';
      case 'gym':
        return '🏋️ Gym';
      case 'media':
        return '📰 Media';
      case 'admin':
        return '⚡ Official';
      default:
        return '👤 Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(link: _layerLink, child: widget.child);
  }
}

class _MentionUser {
  final String uid;
  final String displayName;
  final String role;
  final String? avatarUrl;
  final bool isVerified;

  const _MentionUser({
    required this.uid,
    required this.displayName,
    this.role = 'fan',
    this.avatarUrl,
    this.isVerified = false,
  });
}
