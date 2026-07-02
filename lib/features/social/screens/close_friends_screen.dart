import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/glass_panel.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CLOSE FRIENDS — Instagram-grade close friends management
///
/// • Toggle users into your close friends list
/// • Close friends see exclusive story content
/// • Green ring indicator for close friend stories
/// • Search + filter your connections
/// ═══════════════════════════════════════════════════════════════════════════

class CloseFriendsScreen extends StatefulWidget {
  const CloseFriendsScreen({super.key});

  @override
  State<CloseFriendsScreen> createState() => _CloseFriendsScreenState();
}

class _CloseFriendsScreenState extends State<CloseFriendsScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = '';
  bool _loading = true;

  // Loaded from Firestore; falls back to demo if offline/empty
  List<_FriendEntry> _friends = [];

  static final List<_FriendEntry> _demoFriends = [
    _FriendEntry(
      uid: 'tai_tuivasa',
      name: 'Tai Tuivasa',
      handle: '@bambamtuivasa',
      avatar: Icons.sports_mma_rounded,
      isClose: true,
    ),
    _FriendEntry(
      uid: 'rob_whittaker',
      name: 'Robert Whittaker',
      handle: '@robwhittaker',
      avatar: Icons.sports_mma_rounded,
      isClose: true,
    ),
    _FriendEntry(
      uid: 'volk',
      name: 'Volk',
      handle: '@alexvolkanovski',
      avatar: Icons.sports_mma_rounded,
      isClose: false,
    ),
    _FriendEntry(
      uid: 'israel_adesanya',
      name: 'Israel Adesanya',
      handle: '@stylebender',
      avatar: Icons.sports_mma_rounded,
      isClose: false,
    ),
    _FriendEntry(
      uid: 'molly_mccann',
      name: 'Molly McCann',
      handle: '@meatballmolly',
      avatar: Icons.sports_mma_rounded,
      isClose: true,
    ),
    _FriendEntry(
      uid: 'dan_hooker',
      name: 'Dan Hooker',
      handle: '@danhangman',
      avatar: Icons.sports_mma_rounded,
      isClose: false,
    ),
    _FriendEntry(
      uid: 'kai_kara_france',
      name: 'Kai Kara-France',
      handle: '@kaboross',
      avatar: Icons.sports_mma_rounded,
      isClose: false,
    ),
    _FriendEntry(
      uid: 'jack_della',
      name: 'Jack Della Maddalena',
      handle: '@jackdellamma',
      avatar: Icons.sports_mma_rounded,
      isClose: true,
    ),
    _FriendEntry(
      uid: 'casey_oneill',
      name: "Casey O'Neill",
      handle: '@kingcasey',
      avatar: Icons.sports_mma_rounded,
      isClose: false,
    ),
    _FriendEntry(
      uid: 'tyson_pedro',
      name: 'Tyson Pedro',
      handle: '@tysonpedro',
      avatar: Icons.sports_mma_rounded,
      isClose: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('close_friends')
            .get();
        if (snap.docs.isNotEmpty) {
          _friends = snap.docs.map((d) {
            final data = d.data();
            return _FriendEntry(
              uid: d.id,
              name: data['name'] ?? '',
              handle: data['handle'] ?? '',
              avatar: Icons.sports_mma_rounded,
              isClose: data['isClose'] == true,
            );
          }).toList();
          if (mounted) setState(() => _loading = false);
          return;
        }
      }
    } catch (_) {
      // Firestore unavailable — use demo
    }
    _friends = _demoFriends.map((f) => _FriendEntry(
      uid: f.uid,
      name: f.name,
      handle: f.handle,
      avatar: f.avatar,
      isClose: f.isClose,
    )).toList();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleClose(_FriendEntry entry) async {
    setState(() => entry.isClose = !entry.isClose);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('close_friends')
            .doc(entry.uid)
            .set({
          'name': entry.name,
          'handle': entry.handle,
          'isClose': entry.isClose,
        });
      }
    } catch (_) {
      // Offline — toggle still reflected in local state
    }
  }

  List<_FriendEntry> get _filtered {
    if (_filter.isEmpty) return _friends;
    final q = _filter.toLowerCase();
    return _friends
        .where((f) => f.name.toLowerCase().contains(q) || f.handle.contains(q))
        .toList();
  }

  int get _closeCount => _friends.where((f) => f.isClose).length;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: DesignTokens.bgPrimary,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        title: const Text(
          'Close Friends',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_closeCount selected',
                  style: const TextStyle(
                    color: DesignTokens.neonGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassPanel(
            padding: const EdgeInsets.all(14),
            backgroundColor: DesignTokens.neonGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            borderColor: DesignTokens.neonGreen.withValues(alpha: 0.2),
            child: Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: DesignTokens.neonGreen,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Close friends see exclusive stories with a green ring. Only you know who\'s on this list.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _filter = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search friends...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                filled: true,
                fillColor: DesignTokens.bgCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final f = filtered[i];
                return _FriendTile(
                  entry: f,
                  onToggle: () => _toggleClose(f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final _FriendEntry entry;
  final VoidCallback onToggle;

  const _FriendTile({required this.entry, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GlassPanel(
      padding: EdgeInsets.zero,
      backgroundColor: entry.isClose
          ? DesignTokens.neonGreen.withValues(alpha: 0.06)
          : DesignTokens.bgCard,
      borderRadius: BorderRadius.circular(12),
      borderColor: entry.isClose
          ? DesignTokens.neonGreen.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.06),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: entry.isClose
              ? DesignTokens.neonGreen.withValues(alpha: 0.15)
              : DesignTokens.bgSecondary,
          child: Icon(
            entry.avatar,
            color: entry.isClose
                ? DesignTokens.neonGreen
                : Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
        ),
        title: Text(
          entry.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          entry.handle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        trailing: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: entry.isClose
                  ? DesignTokens.neonGreen
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: entry.isClose
                    ? DesignTokens.neonGreen
                    : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              entry.isClose ? 'Added' : 'Add',
              style: TextStyle(
                color: entry.isClose ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _FriendEntry {
  final String uid;
  final String name;
  final String handle;
  final IconData avatar;
  bool isClose;

  _FriendEntry({
    required this.uid,
    required this.name,
    required this.handle,
    required this.avatar,
    required this.isClose,
  });
}
