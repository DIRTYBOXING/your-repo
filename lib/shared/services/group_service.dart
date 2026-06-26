import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/community/group_model.dart';

/// Service for Groups CRUD, membership, moderation, and admin operations.
/// Reads/writes to Firestore `groups` collection.
class GroupService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final bool _useDemoData;

  GroupService({bool useDemoData = false}) : _useDemoData = useDemoData;

  CollectionReference get _groups => _firestore.collection('groups');

  // ── CRUD ──────────────────────────────────────────────────────────────

  Future<String> createGroup({
    required String name,
    required String description,
    required GroupPrivacy privacy,
    required String creatorId,
    String category = 'general',
    String? coverImageUrl,
    String? iconUrl,
  }) async {
    if (_useDemoData) {
      return 'demo_group_${DateTime.now().millisecondsSinceEpoch}';
    }

    final doc = await _groups.add({
      'name': name,
      'description': description,
      'privacy': privacy.name,
      'creatorId': creatorId,
      'memberIds': [creatorId],
      'adminIds': [creatorId],
      'moderatorIds': <String>[],
      'pinnedPostIds': <String>[],
      'bannedUserIds': <String>[],
      'category': category,
      'rules': <String, dynamic>{},
      'memberCount': 1,
      'coverImageUrl': coverImageUrl,
      'iconUrl': iconUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateGroup({
    required String groupId,
    String? name,
    String? description,
    GroupPrivacy? privacy,
    String? category,
    String? coverImageUrl,
    String? iconUrl,
  }) async {
    if (_useDemoData) return;
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (privacy != null) updates['privacy'] = privacy.name;
    if (category != null) updates['category'] = category;
    if (coverImageUrl != null) updates['coverImageUrl'] = coverImageUrl;
    if (iconUrl != null) updates['iconUrl'] = iconUrl;

    await _groups.doc(groupId).update(updates);
  }

  Future<void> deleteGroup(String groupId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).delete();
  }

  Future<GroupModel?> getGroupById(String groupId) async {
    if (_useDemoData) {
      return _demoGroups().firstWhere(
        (g) => g.id == groupId,
        orElse: () => _demoGroups().first,
      );
    }
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // ── Queries ───────────────────────────────────────────────────────────

  Future<List<GroupModel>> getPublicGroups({int limit = 30}) async {
    if (_useDemoData) {
      return _demoGroups()
          .where((g) => g.privacy == GroupPrivacy.public)
          .toList();
    }
    try {
      final snap = await _groups
          .where('privacy', isEqualTo: 'public')
          .orderBy('memberCount', descending: true)
          .limit(limit)
          .get();
      if (snap.docs.isEmpty) return _demoGroups();
      return snap.docs
          .map(
            (d) => GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();
    } catch (e) {
      debugPrint('[GroupService] getPublicGroups error: $e');
      return _demoGroups();
    }
  }

  Future<List<GroupModel>> getMyGroups(String userId, {int limit = 50}) async {
    if (_useDemoData) return _demoGroups();
    try {
      final snap = await _groups
          .where('memberIds', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .limit(limit)
          .get();
      if (snap.docs.isEmpty) return _demoGroups();
      return snap.docs
          .map(
            (d) => GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList();
    } catch (e) {
      debugPrint('[GroupService] getMyGroups error: $e');
      return _demoGroups();
    }
  }

  Stream<List<GroupModel>> groupsStream() {
    return _groups.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) => GroupModel.fromMap(d.data() as Map<String, dynamic>, d.id),
          )
          .toList(),
    );
  }

  // ── Membership ────────────────────────────────────────────────────────

  Future<void> joinGroup(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveGroup(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
      'moderatorIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin / moderation ────────────────────────────────────────────────

  Future<void> addAdmin(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'adminIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeAdmin(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'adminIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addModerator(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'moderatorIds': FieldValue.arrayUnion([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeModerator(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'moderatorIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> banUser(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'bannedUserIds': FieldValue.arrayUnion([userId]),
      'memberIds': FieldValue.arrayRemove([userId]),
      'adminIds': FieldValue.arrayRemove([userId]),
      'moderatorIds': FieldValue.arrayRemove([userId]),
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unbanUser(String groupId, String userId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'bannedUserIds': FieldValue.arrayRemove([userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Pinned posts ──────────────────────────────────────────────────────

  Future<void> pinPost(String groupId, String postId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'pinnedPostIds': FieldValue.arrayUnion([postId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unpinPost(String groupId, String postId) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'pinnedPostIds': FieldValue.arrayRemove([postId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Group rules ───────────────────────────────────────────────────────

  Future<void> updateRules(String groupId, Map<String, dynamic> rules) async {
    if (_useDemoData) return;
    await _groups.doc(groupId).update({
      'rules': rules,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Demo data ─────────────────────────────────────────────────────────

  List<GroupModel> _demoGroups() {
    final now = DateTime.now();
    return [
      GroupModel(
        id: 'demo_group_1',
        name: 'DFC Fight Fans',
        description:
            'The official DFC fan community. Discuss upcoming bouts, share predictions, and connect with fellow fight enthusiasts.',
        privacy: GroupPrivacy.public,
        creatorId: 'dfc_official',
        memberIds: [
          'current_user',
          'dfc_official',
          'jake_paul',
          'stamp_fairtex',
        ],
        adminIds: ['dfc_official'],
        moderatorIds: ['current_user'],
        category: 'fan_club',
        memberCount: 4218,
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      GroupModel(
        id: 'demo_group_2',
        name: 'Team MMA Cardio',
        description:
            'Training tips, sparring footage, and conditioning programs for serious MMA athletes.',
        privacy: GroupPrivacy.public,
        creatorId: 'coach_ray',
        memberIds: ['current_user', 'coach_ray', 'zhang_weili'],
        adminIds: ['coach_ray'],
        category: 'team',
        memberCount: 874,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      GroupModel(
        id: 'demo_group_3',
        name: 'BKFC Underground',
        description:
            'Bare-knuckle fight breakdowns, fighter Q&As, and event watch parties.',
        privacy: GroupPrivacy.private,
        creatorId: 'bkfc_official',
        memberIds: ['bkfc_official', 'christine_ferea'],
        adminIds: ['bkfc_official'],
        category: 'promotion',
        memberCount: 1537,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      GroupModel(
        id: 'demo_group_4',
        name: 'Muay Thai Collective',
        description:
            'Technique of the week, golden-era highlights, and gym recommendations worldwide.',
        privacy: GroupPrivacy.public,
        creatorId: 'stamp_fairtex',
        memberIds: ['current_user', 'stamp_fairtex'],
        adminIds: ['stamp_fairtex'],
        memberCount: 2101,
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now.subtract(const Duration(hours: 12)),
      ),
      GroupModel(
        id: 'demo_group_5',
        name: 'Women in Combat Sports',
        description:
            'Safe space for female fighters, coaches, and fans to connect, share wins, and uplift each other.',
        privacy: GroupPrivacy.private,
        creatorId: 'amanda_serrano',
        memberIds: [
          'amanda_serrano',
          'zhang_weili',
          'christine_ferea',
          'stamp_fairtex',
        ],
        adminIds: ['amanda_serrano'],
        moderatorIds: ['zhang_weili'],
        category: 'fan_club',
        memberCount: 965,
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
