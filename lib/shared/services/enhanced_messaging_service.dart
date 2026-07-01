import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/models/group_chat_model.dart';
import '../../features/messaging/models/message_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENHANCED MESSAGING SERVICE — 1-on-1 + Group Chats
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Supports:
/// - 1-on-1 conversations (legacy compatibility)
/// - Group chats (3-50 members)
/// - Admin roles and permissions
/// - Message threading and replies
/// - Read receipts and typing indicators
/// - Message attachments
/// - System messages (member joined/left/promoted)
/// - Unread counts per participant
/// ═══════════════════════════════════════════════════════════════════════════
class EnhancedMessagingService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _conversationsCollection = 'conversations';
  static const String _groupChatsCollection = 'group_chats';
  static const String ninjaUserId = 'dfc_ninja';
  static const String ninjaDisplayName = 'DFC Ninja';

  String? get currentUserId => _auth.currentUser?.uid;

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP CHAT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new group chat
  Future<String> createGroupChat({
    required String name,
    required List<String> memberIds,
    String? description,
    String? avatarUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    if (memberIds.length < 2 || memberIds.length > 50) {
      throw Exception('Group must have 3-50 members');
    }

    // Add creator if not in list
    if (!memberIds.contains(userId)) {
      memberIds = [userId, ...memberIds];
    }

    // Get member details
    final memberDetails = <String, Map<String, dynamic>>{};
    for (final memberId in memberIds) {
      final userDoc = await _db.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        memberDetails[memberId] = {
          'name': data['displayName'] ?? 'Unknown',
          'photoUrl': data['photoURL'] ?? '',
          'role': data['role'] ?? 'fighter',
        };
      }
    }

    final groupRef = _db.collection(_groupChatsCollection).doc();
    final now = DateTime.now();

    final group = GroupChat(
      id: groupRef.id,
      name: name,
      description: description ?? '',
      avatarUrl: avatarUrl,
      memberIds: memberIds,
      memberNames: {
        for (final memberId in memberIds)
          memberId: memberDetails[memberId]?['name'] ?? 'Unknown',
      },
      memberPhotoUrls: {
        for (final memberId in memberIds)
          memberId: memberDetails[memberId]?['photoUrl'] ?? '',
      },
      memberRoles: {userId: 'admin'}, // Creator is admin
      createdBy: userId,
      createdAt: now,
      unreadCounts: {for (final memberId in memberIds) memberId: 0},
    );

    await groupRef.set(group.toFirestore());

    // Send system message
    await _sendGroupSystemMessage(
      groupId: groupRef.id,
      text: 'Group created by ${memberDetails[userId]?['name'] ?? 'Unknown'}',
      type: 'group_created',
    );

    AppLogger.info(
      'Group chat created: ${groupRef.id} with ${memberIds.length} members',
      tag: 'EnhancedMessagingService',
    );
    notifyListeners();
    return groupRef.id;
  }

  /// Add members to group
  Future<void> addGroupMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final groupDoc = await _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .get();
    if (!groupDoc.exists) throw Exception('Group not found');

    final group = GroupChat.fromFirestore(groupDoc);

    // Check if user is admin
    if (!group.isAdmin(userId)) {
      throw Exception('Only admins can add members');
    }

    // Check size limit
    if (group.memberIds.length + memberIds.length > 50) {
      throw Exception('Group member limit is 50');
    }

    // Get new member details
    final newMemberNames = Map<String, String>.from(group.memberNames);
    final newMemberPhotoUrls = Map<String, String>.from(group.memberPhotoUrls);
    for (final memberId in memberIds) {
      if (group.memberIds.contains(memberId)) continue;

      final userDoc = await _db.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        newMemberNames[memberId] = data['displayName'] ?? 'Unknown';
        newMemberPhotoUrls[memberId] = data['photoURL'] ?? '';
      }
    }

    final batch = _db.batch();

    // Update group
    batch.update(_db.collection(_groupChatsCollection).doc(groupId), {
      'memberIds': FieldValue.arrayUnion(memberIds),
      'memberNames': newMemberNames,
      'memberPhotoUrls': newMemberPhotoUrls,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Send system messages
    for (final memberId in memberIds) {
      final memberName = newMemberNames[memberId] ?? 'Someone';
      await _sendGroupSystemMessage(
        groupId: groupId,
        text: '$memberName joined the group',
        type: 'member_added',
      );
    }

    AppLogger.info(
      'Added ${memberIds.length} members to group: $groupId',
      tag: 'EnhancedMessagingService',
    );
    notifyListeners();
  }

  /// Remove member from group
  Future<void> removeGroupMember({
    required String groupId,
    required String memberId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final groupDoc = await _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .get();
    if (!groupDoc.exists) throw Exception('Group not found');

    final group = GroupChat.fromFirestore(groupDoc);

    // Check if user is admin or removing self
    if (!group.isAdmin(userId) && userId != memberId) {
      throw Exception('Only admins can remove members');
    }

    final batch = _db.batch();

    // Update group
    batch.update(_db.collection(_groupChatsCollection).doc(groupId), {
      'memberIds': FieldValue.arrayRemove([memberId]),
      'memberRoles.$memberId': FieldValue.delete(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Send system message
    final memberName = group.memberNames[memberId] ?? 'Someone';
    await _sendGroupSystemMessage(
      groupId: groupId,
      text: userId == memberId
          ? '$memberName left the group'
          : '$memberName was removed',
      type: userId == memberId ? 'member_left' : 'member_removed',
    );

    AppLogger.info(
      'Member $memberId removed from group: $groupId',
      tag: 'EnhancedMessagingService',
    );
    notifyListeners();
  }

  /// Promote member to admin
  Future<void> promoteToAdmin({
    required String groupId,
    required String memberId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final groupDoc = await _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .get();
    if (!groupDoc.exists) throw Exception('Group not found');

    final group = GroupChat.fromFirestore(groupDoc);

    // Check if user is admin
    if (!group.isAdmin(userId)) {
      throw Exception('Only admins can promote members');
    }

    if (group.isAdmin(memberId)) {
      throw Exception('Member is already an admin');
    }

    await _db.collection(_groupChatsCollection).doc(groupId).update({
      'memberRoles.$memberId': 'admin',
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Send system message
    final memberName = group.memberNames[memberId] ?? 'Someone';
    await _sendGroupSystemMessage(
      groupId: groupId,
      text: '$memberName is now an admin',
      type: 'member_promoted',
    );

    AppLogger.info(
      'Member $memberId promoted to admin in group: $groupId',
      tag: 'EnhancedMessagingService',
    );
    notifyListeners();
  }

  /// Update group details
  Future<void> updateGroupDetails({
    required String groupId,
    String? name,
    String? description,
    String? avatarUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final groupDoc = await _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .get();
    if (!groupDoc.exists) throw Exception('Group not found');

    final group = GroupChat.fromFirestore(groupDoc);

    if (!group.isAdmin(userId)) {
      throw Exception('Only admins can update group details');
    }

    final updates = <String, dynamic>{
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    await _db.collection(_groupChatsCollection).doc(groupId).update(updates);

    AppLogger.info(
      'Group details updated: $groupId',
      tag: 'EnhancedMessagingService',
    );
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP MESSAGING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send message in group chat
  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
    String? replyToId,
    String? attachmentType,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final userDoc = await _db.collection('users').doc(userId).get();
    final userData = userDoc.data() ?? {};
    final senderName = userData['displayName'] ?? 'Unknown';

    final groupDoc = await _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .get();
    if (!groupDoc.exists) throw Exception('Group not found');

    final group = GroupChat.fromFirestore(groupDoc);

    if (!group.memberIds.contains(userId)) {
      throw Exception('Not a member of this group');
    }

    final msgRef = _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .collection('messages')
        .doc();

    final now = DateTime.now();
    final message = GroupMessage(
      id: msgRef.id,
      groupId: groupId,
      senderId: userId,
      senderName: senderName,
      text: text,
      sentAt: now,
      replyToId: replyToId,
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
    );

    // Increment unread for all other members
    final newUnread = Map<String, int>.from(group.unreadCounts);
    for (final memberId in group.memberIds) {
      if (memberId != userId) {
        newUnread[memberId] = (newUnread[memberId] ?? 0) + 1;
      }
    }

    final batch = _db.batch();

    // Write message
    batch.set(msgRef, message.toFirestore());

    // Update group metadata
    batch.update(_db.collection(_groupChatsCollection).doc(groupId), {
      'lastMessage': text.length > 80 ? '${text.substring(0, 80)}...' : text,
      'lastMessageAt': Timestamp.fromDate(now),
      'lastSenderId': userId,
      'unreadCounts': newUnread,
    });

    await batch.commit();
    notifyListeners();
  }

  /// Send system message (internal use)
  Future<void> _sendGroupSystemMessage({
    required String groupId,
    required String text,
    required String type,
  }) async {
    final msgRef = _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .collection('messages')
        .doc();

    final now = DateTime.now();
    final message = GroupMessage(
      id: msgRef.id,
      groupId: groupId,
      senderId: 'system',
      senderName: 'System',
      text: text,
      sentAt: now,
      isSystemMessage: true,
      metadata: {'type': type},
    );

    await msgRef.set(message.toFirestore());
  }

  /// Mark group messages as read
  Future<void> markGroupAsRead(String groupId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _db.collection(_groupChatsCollection).doc(groupId).update({
      'unreadCounts.$userId': 0,
    });
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream of user's group chats
  Stream<List<GroupChat>> streamGroupChats() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _db
        .collection(_groupChatsCollection)
        .where('memberIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(GroupChat.fromFirestore).toList(),
        );
  }

  /// Stream of group messages
  Stream<List<GroupMessage>> streamGroupMessages(String groupId) {
    return _db
        .collection(_groupChatsCollection)
        .doc(groupId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(GroupMessage.fromFirestore).toList(),
        );
  }

  /// Stream of 1-on-1 conversations (legacy support)
  Stream<List<Conversation>> conversationsStream(String userId) {
    return _db
        .collection(_conversationsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          final convs = snap.docs
              .map(Conversation.fromFirestore)
              .toList();
          convs.sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });
          return convs;
        });
  }

  /// Stream of 1-on-1 messages (legacy support)
  Stream<List<Message>> messagesStream(String conversationId) {
    return _db
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Message.fromFirestore).toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY 1-ON-1 SUPPORT (backward compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? replyToId,
    String? replyToText,
    String? attachmentType,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    final now = DateTime.now();
    final msgRef = _db
        .collection(_conversationsCollection)
        .doc(conversationId)
        .collection('messages')
        .doc();

    final msg = Message(
      id: msgRef.id,
      senderId: senderId,
      senderName: senderName,
      text: text,
      sentAt: now,
      replyToId: replyToId,
      replyToText: replyToText,
      attachmentType: attachmentType,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
    );

    final batch = _db.batch();
    batch.set(msgRef, msg.toFirestore());

    // Update conversation metadata
    final convRef = _db
        .collection(_conversationsCollection)
        .doc(conversationId);
    final convSnap = await convRef.get();
    if (convSnap.exists) {
      final conv = Conversation.fromFirestore(convSnap);
      final newUnread = Map<String, int>.from(conv.unreadCounts);
      for (final p in conv.participants) {
        if (p != senderId) {
          newUnread[p] = (newUnread[p] ?? 0) + 1;
        }
      }
      batch.update(convRef, {
        'lastMessage': text.length > 80 ? '${text.substring(0, 80)}...' : text,
        'lastMessageAt': Timestamp.fromDate(now),
        'lastSenderId': senderId,
        'unreadCounts': newUnread,
      });
    }

    await batch.commit();
    notifyListeners();
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    await _db.collection(_conversationsCollection).doc(conversationId).update({
      'unreadCounts.$userId': 0,
    });
    notifyListeners();
  }

  Future<String> createConversation({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    String currentUserPhotoUrl = '',
    String otherUserPhotoUrl = '',
  }) async {
    // Check if conversation already exists
    final existing = await _db
        .collection(_conversationsCollection)
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    // Create new
    final ref = _db.collection(_conversationsCollection).doc();
    final conv = Conversation(
      id: ref.id,
      participants: [currentUserId, otherUserId],
      participantNames: {
        currentUserId: currentUserName,
        otherUserId: otherUserName,
      },
      participantPhotoUrls: {
        currentUserId: currentUserPhotoUrl,
        otherUserId: otherUserPhotoUrl,
      },
      createdAt: DateTime.now(),
    );
    await ref.set(conv.toFirestore());
    return ref.id;
  }
}
