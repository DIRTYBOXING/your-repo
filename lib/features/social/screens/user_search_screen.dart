import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/widgets/dfc_network_image.dart';
import '../../../core/theme/glass_panel.dart';
import '../widgets/follow_button.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// USER SEARCH / DISCOVER SCREEN
/// Search for fighters, fans, promoters, coaches — anyone on DFC.
/// ═══════════════════════════════════════════════════════════════════════════
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed == _lastQuery) return;
    _lastQuery = trimmed;
    setState(() => _loading = true);

    try {
      // Search by displayName prefix (case-insensitive via lowercase field)
      final snap = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: trimmed)
          .where('displayName', isLessThanOrEqualTo: '$trimmed\uf8ff')
          .limit(30)
          .get();

      // Also search lowercase if available
      final snapLower = await _firestore
          .collection('users')
          .where(
            'displayNameLower',
            isGreaterThanOrEqualTo: trimmed.toLowerCase(),
          )
          .where(
            'displayNameLower',
            isLessThanOrEqualTo: '${trimmed.toLowerCase()}\uf8ff',
          )
          .limit(30)
          .get();

      // Merge & deduplicate
      final Map<String, Map<String, dynamic>> merged = {};
      for (final doc in [...snap.docs, ...snapLower.docs]) {
        merged.putIfAbsent(doc.id, () => {'id': doc.id, ...doc.data()});
      }

      if (mounted) {
        setState(() {
          _results = merged.values.toList();
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('User search error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthService>().currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        title: const Text(
          'Find People',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search fighters, fans, promoters...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _results = [];
                            _lastQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (v) {
                setState(() {}); // refresh suffix icon
                if (v.trim().length >= 2) _search(v);
              },
              onSubmitted: _search,
            ),
          ),

          // ── Results ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  )
                : _results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 64,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _lastQuery.isEmpty
                              ? 'Search for people on DFC'
                              : 'No results found',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      final uid = user['id'] as String? ?? '';
                      final name = user['displayName'] as String? ?? 'User';
                      final photo = user['photoUrl'] as String? ?? '';
                      final role = user['role'] as String? ?? 'fan';
                      final isSelf = uid == currentUid;

                      return _UserTile(
                        userId: uid,
                        displayName: name,
                        photoUrl: photo,
                        role: role,
                        currentUserId: currentUid ?? '',
                        isSelf: isSelf,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// USER TILE — Avatar + Name + Role + Follow / Message
// ═════════════════════════════════════════════════════════════════════════════
class _UserTile extends StatelessWidget {
  final String userId;
  final String displayName;
  final String photoUrl;
  final String role;
  final String currentUserId;
  final bool isSelf;

  const _UserTile({
    required this.userId,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.currentUserId,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GlassPanel(
      padding: EdgeInsets.zero,
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      borderColor: Colors.white.withValues(alpha: 0.06),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: DfcCircleAvatar(
          imageUrl: photoUrl,
          radius: 24,
          backgroundColor: const Color(0xFF1A2540),
          borderColor: Colors.white.withValues(alpha: 0.08),
          borderWidth: 1,
          fallbackText: displayName.isNotEmpty
              ? displayName[0].toUpperCase()
              : '?',
          fallbackIconColor: Colors.cyanAccent,
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          role.toUpperCase(),
          style: TextStyle(
            color: Colors.cyanAccent.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        trailing: isSelf
            ? Chip(
                label: const Text(
                  'You',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                side: BorderSide.none,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FollowButton(
                    currentUserId: currentUserId,
                    targetUserId: userId,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(
                      Icons.mail_outline,
                      color: Colors.cyanAccent,
                      size: 20,
                    ),
                    onPressed: () => context.push('/messaging'),
                    tooltip: 'Message',
                  ),
                ],
              ),
        onTap: () => context.push('/user/$userId'),
      ),
      ),
    );
  }
}
