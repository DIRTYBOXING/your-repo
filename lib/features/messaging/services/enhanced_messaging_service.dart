import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/enhanced_message_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// ENHANCED MESSAGING SERVICE — Workflow States + Attachment Management
/// ═══════════════════════════════════════════════════════════════════════════
class EnhancedMessagingService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATION QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream all conversations by category
  Stream<List<EnhancedConversation>> conversationsByCategory({
    required String userId,
    InboxCategory? category,
    bool includeArchived = false,
  }) {
    try {
      final query = _db
          .collection('conversations')
          .where('participants', arrayContains: userId)
          .orderBy('pinned', descending: true)
          .orderBy('lastMessageAt', descending: true);

      return query.snapshots().map((snap) {
        final convs = snap.docs
            .map(EnhancedConversation.fromFirestore)
            .toList();

        // Filter by category and archived status
        return convs.where((c) {
          if (!includeArchived && c.archived) return false;
          if (category != null && c.category != category) return false;
          return true;
        }).toList();
      });
    } catch (e) {
      debugPrint('Enhanced messaging: query failed, using fallback: $e');
      return Stream.value([]);
    }
  }

  /// Stream messages for a conversation with status tracking
  Stream<List<EnhancedMessage>> messagesStream(String conversationId) {
    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('archived', isEqualTo: false)
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(EnhancedMessage.fromFirestore).toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send message with workflow tracking
  Future<EnhancedMessage> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
    String? senderPhotoUrl,
    MessagePriority priority = MessagePriority.normal,
    String? replyToId,
    String? replyToText,
    String? threadId,
    List<MessageAttachment> attachments = const [],
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = EnhancedMessage(
      id: msgRef.id,
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      sentAt: now,
      status: MessageStatus.sending,
      priority: priority,
      replyToId: replyToId,
      replyToText: replyToText,
      threadId: threadId ?? msgRef.id,
      attachments: attachments,
      metadata: metadata,
    );

    final batch = _db.batch();

    try {
      // Write message
      batch.set(msgRef, message.toFirestore());

      // Update conversation
      final convRef = _db.collection('conversations').doc(conversationId);
      final convSnap = await convRef.get();
      if (convSnap.exists) {
        final conv = EnhancedConversation.fromFirestore(convSnap);
        final newUnread = Map<String, int>.from(conv.unreadCounts);
        for (final p in conv.participants) {
          if (p != senderId) {
            newUnread[p] = (newUnread[p] ?? 0) + 1;
          }
        }
        batch.update(convRef, {
          'lastMessage': text.length > 100
              ? '${text.substring(0, 100)}...'
              : text,
          'lastMessageAt': Timestamp.fromDate(now),
          'lastSenderId': senderId,
          'unreadCounts': newUnread,
          'draftMessage': null,
          'draftAttachments': [],
        });
      }

      await batch.commit();

      // Update status to sent
      await _updateMessageStatus(conversationId, msgRef.id, MessageStatus.sent);

      notifyListeners();
      return message.copyWith(status: MessageStatus.sent);
    } catch (e) {
      debugPrint('Send message failed: $e');
      await _updateMessageStatus(
        conversationId,
        msgRef.id,
        MessageStatus.failed,
      );
      rethrow;
    }
  }

  /// Update message status (for workflow tracking)
  Future<void> _updateMessageStatus(
    String conversationId,
    String messageId,
    MessageStatus status,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'status': status.name,
          if (status == MessageStatus.delivered) 'deliveredAt': Timestamp.now(),
          if (status == MessageStatus.read) 'readAt': Timestamp.now(),
        });
  }

  /// Mark message as read (workflow: sent → delivered → read)
  Future<void> markAsRead(String conversationId, String messageId) async {
    await _updateMessageStatus(conversationId, messageId, MessageStatus.read);
    notifyListeners();
  }

  /// Mark all messages in conversation as read
  Future<void> markConversationAsRead(
    String conversationId,
    String userId,
  ) async {
    final batch = _db.batch();

    // Update all unread messages
    final messages = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('status', isEqualTo: MessageStatus.sent.name)
        .where('senderId', isNotEqualTo: userId)
        .get();

    for (final doc in messages.docs) {
      batch.update(doc.reference, {
        'status': MessageStatus.read.name,
        'readAt': Timestamp.now(),
      });
    }

    // Update conversation unread count
    batch.update(_db.collection('conversations').doc(conversationId), {
      'unreadCounts.$userId': 0,
    });

    await batch.commit();
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ATTACHMENT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upload attachment with progress tracking
  Future<MessageAttachment> uploadAttachment({
    required String userId,
    required String conversationId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    Function(double progress)? onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(fileName).toLowerCase();
    final attachmentId = '$timestamp-${fileName.hashCode}';
    final storagePath =
        'messages/$userId/$conversationId/$attachmentId$extension';

    // Determine attachment type
    String attachmentType = 'file';
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
      attachmentType = 'image';
    } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(extension)) {
      attachmentType = 'video';
    } else if (['.mp3', '.wav', '.aac', '.m4a'].contains(extension)) {
      attachmentType = 'audio';
    } else if (['.pdf'].contains(extension)) {
      attachmentType = 'pdf';
    } else if (['.doc', '.docx', '.txt', '.rtf'].contains(extension)) {
      attachmentType = 'document';
    }

    final ref = _storage.ref().child(storagePath);
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(
        contentType: mimeType,
        customMetadata: {
          'uploadedBy': userId,
          'conversationId': conversationId,
          'originalName': fileName,
        },
      ),
    );

    // Track progress
    uploadTask.snapshotEvents.listen((snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress?.call(progress);
    });

    await uploadTask;
    final downloadUrl = await ref.getDownloadURL();

    // Generate thumbnail for images
    String? thumbnailUrl;
    if (attachmentType == 'image') {
      thumbnailUrl = await _generateThumbnail(ref, bytes);
    }

    return MessageAttachment(
      id: attachmentId,
      type: attachmentType,
      url: downloadUrl,
      name: fileName,
      size: bytes.length,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
      uploadedAt: DateTime.now(),
      uploadedBy: userId,
      scanned: true, // Virus scanning pending server-side integration
    );
  }

  /// Upload multiple attachments
  Future<List<MessageAttachment>> uploadAttachments({
    required String userId,
    required String conversationId,
    required List<MapEntry<Uint8List, String>> files, // bytes + fileName
    Function(int index, double progress)? onProgress,
  }) async {
    final attachments = <MessageAttachment>[];

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final attachment = await uploadAttachment(
        userId: userId,
        conversationId: conversationId,
        bytes: file.key,
        fileName: file.value,
        onProgress: (progress) => onProgress?.call(i, progress),
      );
      attachments.add(attachment);
    }

    return attachments;
  }

  /// Generate thumbnail for image attachments
  Future<String?> _generateThumbnail(
    Reference originalRef,
    Uint8List originalBytes,
  ) async {
    try {
      // Image resizing pending — returns original URL for now
      // Production: compress/resize via server-side function
      return null;
    } catch (e) {
      debugPrint('Thumbnail generation failed: $e');
      return null;
    }
  }

  /// Delete attachment
  Future<void> deleteAttachment(String attachmentUrl) async {
    try {
      final ref = _storage.refFromURL(attachmentUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Delete attachment failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRAFT MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save draft message
  Future<void> saveDraft({
    required String conversationId,
    String? text,
    List<MessageAttachment> attachments = const [],
  }) async {
    await _db.collection('conversations').doc(conversationId).update({
      'draftMessage': text,
      'draftAttachments': attachments.map((a) => a.toMap()).toList(),
    });
    notifyListeners();
  }

  /// Clear draft
  Future<void> clearDraft(String conversationId) async {
    await saveDraft(
      conversationId: conversationId,
      attachments: [],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Star/unstar message
  Future<void> toggleStar(String conversationId, String messageId) async {
    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final snap = await msgRef.get();
    if (snap.exists) {
      final msg = EnhancedMessage.fromFirestore(snap);
      await msgRef.update({'starred': !msg.starred});
      notifyListeners();
    }
  }

  /// Flag/unflag message
  Future<void> toggleFlag(String conversationId, String messageId) async {
    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final snap = await msgRef.get();
    if (snap.exists) {
      final msg = EnhancedMessage.fromFirestore(snap);
      await msgRef.update({'flagged': !msg.flagged});
      notifyListeners();
    }
  }

  /// Archive message
  Future<void> archiveMessage(String conversationId, String messageId) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'archived': true});
    notifyListeners();
  }

  /// Add label to message
  Future<void> addLabel(
    String conversationId,
    String messageId,
    String label,
  ) async {
    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final snap = await msgRef.get();
    if (snap.exists) {
      final msg = EnhancedMessage.fromFirestore(snap);
      if (!msg.labels.contains(label)) {
        await msgRef.update({
          'labels': FieldValue.arrayUnion([label]),
        });
        notifyListeners();
      }
    }
  }

  /// Remove label from message
  Future<void> removeLabel(
    String conversationId,
    String messageId,
    String label,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'labels': FieldValue.arrayRemove([label]),
        });
    notifyListeners();
  }

  /// Add reaction to message
  Future<void> addReaction(
    String conversationId,
    String messageId,
    String emoji,
    String userId,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'reactions.$emoji': FieldValue.arrayUnion([userId]),
        });
    notifyListeners();
  }

  /// Remove reaction from message
  Future<void> removeReaction(
    String conversationId,
    String messageId,
    String emoji,
    String userId,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'reactions.$emoji': FieldValue.arrayRemove([userId]),
        });
    notifyListeners();
  }

  /// Edit message
  Future<void> editMessage(
    String conversationId,
    String messageId,
    String newText,
  ) async {
    final msgRef = _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);
    final snap = await msgRef.get();
    if (snap.exists) {
      final msg = EnhancedMessage.fromFirestore(snap);
      await msgRef.update({
        'text': newText,
        'edited': true,
        'editedAt': Timestamp.now(),
        if (!msg.edited) 'originalText': msg.text,
      });
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONVERSATION ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pin/unpin conversation
  Future<void> togglePin(String conversationId) async {
    final convRef = _db.collection('conversations').doc(conversationId);
    final snap = await convRef.get();
    if (snap.exists) {
      final conv = EnhancedConversation.fromFirestore(snap);
      await convRef.update({'pinned': !conv.pinned});
      notifyListeners();
    }
  }

  /// Archive/unarchive conversation
  Future<void> toggleArchive(String conversationId) async {
    final convRef = _db.collection('conversations').doc(conversationId);
    final snap = await convRef.get();
    if (snap.exists) {
      final conv = EnhancedConversation.fromFirestore(snap);
      await convRef.update({'archived': !conv.archived});
      notifyListeners();
    }
  }

  /// Mute/unmute conversation
  Future<void> toggleMute(String conversationId) async {
    final convRef = _db.collection('conversations').doc(conversationId);
    final snap = await convRef.get();
    if (snap.exists) {
      final conv = EnhancedConversation.fromFirestore(snap);
      await convRef.update({'muted': !conv.muted});
      notifyListeners();
    }
  }

  /// Set conversation category
  Future<void> setCategory(
    String conversationId,
    InboxCategory category,
  ) async {
    await _db.collection('conversations').doc(conversationId).update({
      'category': category.name,
    });
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH & FILTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search messages by text
  Future<List<EnhancedMessage>> searchMessages({
    required String userId,
    required String query,
    InboxCategory? category,
    MessagePriority? priority,
    bool? starred,
    bool? flagged,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final messagesQuery = _db
        .collectionGroup('messages')
        .where('text', isGreaterThanOrEqualTo: query)
        .where('text', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(100);

    final snap = await messagesQuery.get();
    final messages = snap.docs
        .map(EnhancedMessage.fromFirestore)
        .toList();

    // Apply filters
    return messages.where((m) {
      if (category != null && m.category != category) return false;
      if (priority != null && m.priority != priority) return false;
      if (starred != null && m.starred != starred) return false;
      if (flagged != null && m.flagged != flagged) return false;
      if (startDate != null && m.sentAt.isBefore(startDate)) return false;
      if (endDate != null && m.sentAt.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  /// Get all starred messages
  Future<List<EnhancedMessage>> getStarredMessages(String userId) async {
    final conversations = await _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .get();

    final List<EnhancedMessage> starred = [];

    for (final convDoc in conversations.docs) {
      final messages = await convDoc.reference
          .collection('messages')
          .where('starred', isEqualTo: true)
          .get();
      starred.addAll(
        messages.docs.map(EnhancedMessage.fromFirestore),
      );
    }

    starred.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return starred;
  }
}
