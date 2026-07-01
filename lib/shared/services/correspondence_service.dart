import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'moderation_engine.dart';
import '../../shared/models/moderation_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONTROLLED CORRESPONDENCE SERVICE
// Fan→Fighter moderated communication. No trolling. No DMs. No abuse.
//
// Flow: Fan submits → AI/keyword filter → moderation queue → Fighter inbox
//       Fighter replies → published to public Q&A feed → fan notified
// ═══════════════════════════════════════════════════════════════════════════════

/// Message status through the moderation pipeline
enum MessageStatus {
  pending, // Submitted, awaiting moderation
  approved, // Passed filters, visible to fighter
  rejected, // Failed moderation, not delivered
  answered, // Fighter has responded
  archived, // Old/closed
}

/// Type of fan message
enum FanMessageType {
  question, // Ask the fighter something
  support, // Encouragement / props
  shoutout, // Request a shoutout
  reaction, // Reaction to a fight or post
}

/// Type of fighter response
enum ResponseType {
  text, // Written response
  audio, // Voice clip
  video, // Short video
  template, // Pre-set response ("Thanks for the support!")
}

/// Topic tag for categorizing fan messages
enum QuestionTopic {
  general,
  fightPrep,
  lifestyle,
  advice,
  shoutout,
  event,
  career,
}

/// A message from a fan to a fighter (goes through moderation)
class FanMessage {
  final String id;
  final String fanId;
  final String fanName;
  final String? fanPhotoUrl;
  final String fighterId;
  final String fighterName;
  final String content;
  final FanMessageType type;
  final MessageStatus status;
  final QuestionTopic topic;
  final String? rejectionReason;
  final double toxicityScore;
  final int upvotes; // Other fans can upvote questions
  final DateTime createdAt;
  final DateTime? moderatedAt;
  final bool savedForLater;

  const FanMessage({
    required this.id,
    required this.fanId,
    required this.fanName,
    this.fanPhotoUrl,
    required this.fighterId,
    required this.fighterName,
    required this.content,
    required this.type,
    required this.status,
    this.topic = QuestionTopic.general,
    this.rejectionReason,
    this.toxicityScore = 0.0,
    this.upvotes = 0,
    required this.createdAt,
    this.moderatedAt,
    this.savedForLater = false,
  });

  factory FanMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FanMessage(
      id: doc.id,
      fanId: d['fanId'] ?? '',
      fanName: d['fanName'] ?? '',
      fanPhotoUrl: d['fanPhotoUrl'],
      fighterId: d['fighterId'] ?? '',
      fighterName: d['fighterName'] ?? '',
      content: d['content'] ?? '',
      type: FanMessageType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => FanMessageType.question,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => MessageStatus.pending,
      ),
      topic: QuestionTopic.values.firstWhere(
        (e) => e.name == d['topic'],
        orElse: () => QuestionTopic.general,
      ),
      rejectionReason: d['rejectionReason'],
      toxicityScore: (d['toxicityScore'] ?? 0.0).toDouble(),
      upvotes: d['upvotes'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      moderatedAt: (d['moderatedAt'] as Timestamp?)?.toDate(),
      savedForLater: d['savedForLater'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'fanId': fanId,
    'fanName': fanName,
    'fanPhotoUrl': fanPhotoUrl,
    'fighterId': fighterId,
    'fighterName': fighterName,
    'content': content,
    'type': type.name,
    'status': status.name,
    'topic': topic.name,
    'rejectionReason': rejectionReason,
    'toxicityScore': toxicityScore,
    'upvotes': upvotes,
    'createdAt': Timestamp.fromDate(createdAt),
    'moderatedAt': moderatedAt != null
        ? Timestamp.fromDate(moderatedAt!)
        : null,
    'savedForLater': savedForLater,
  };
}

/// A fighter's response to an approved fan message
class FighterResponse {
  final String id;
  final String messageId; // Links to the FanMessage
  final String fighterId;
  final String fighterName;
  final String? fighterPhotoUrl;
  final String content;
  final ResponseType type;
  final String? mediaUrl; // For audio/video responses
  final int likes;
  final int shares;
  final DateTime createdAt;

  const FighterResponse({
    required this.id,
    required this.messageId,
    required this.fighterId,
    required this.fighterName,
    this.fighterPhotoUrl,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.likes = 0,
    this.shares = 0,
    required this.createdAt,
  });

  factory FighterResponse.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FighterResponse(
      id: doc.id,
      messageId: d['messageId'] ?? '',
      fighterId: d['fighterId'] ?? '',
      fighterName: d['fighterName'] ?? '',
      fighterPhotoUrl: d['fighterPhotoUrl'],
      content: d['content'] ?? '',
      type: ResponseType.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => ResponseType.text,
      ),
      mediaUrl: d['mediaUrl'],
      likes: d['likes'] ?? 0,
      shares: d['shares'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'messageId': messageId,
    'fighterId': fighterId,
    'fighterName': fighterName,
    'fighterPhotoUrl': fighterPhotoUrl,
    'content': content,
    'type': type.name,
    'mediaUrl': mediaUrl,
    'likes': likes,
    'shares': shares,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

/// Main service for controlled fan↔fighter correspondence
class CorrespondenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ModerationEngine _modEngine = ModerationEngine();

  // ── Rate limits ──
  static const int maxQuestionsPerFighterPerDay = 5;
  static const int maxTotalSubmissionsPerDay = 20;

  // ═══════════════════════════════════════════════════════════════════════════
  // DEMO DATA — Fighter inbox / public Q&A when Firestore is empty
  // ═══════════════════════════════════════════════════════════════════════════
  static final List<FanMessage> _demoMessages = [
    FanMessage(
      id: 'demo-msg-1',
      fanId: 'fan_logan_001',
      fanName: 'Tama Kerehoma',
      fighterId: 'haze_hepi',
      fighterName: 'Haze Hepi',
      content:
          'Bro, Logan is behind you 100%. The whole island is watching April 18. Bring that mana to Townsville! 🌺🇳🇿',
      type: FanMessageType.support,
      status: MessageStatus.approved,
      upvotes: 342,
      createdAt: DateTime(2026, 3, 20),
      moderatedAt: DateTime(2026, 3, 20),
    ),
    FanMessage(
      id: 'demo-msg-2',
      fanId: 'fan_qld_002',
      fanName: 'Jake Mitchell',
      fighterId: 'haze_hepi',
      fighterName: 'Haze Hepi',
      content:
          'What\'s your game plan for Wisniewski? He\'s undefeated and huge. How do you beat a guy like that?',
      type: FanMessageType.question,
      status: MessageStatus.answered,
      upvotes: 567,
      createdAt: DateTime(2026, 3, 18),
      moderatedAt: DateTime(2026, 3, 18),
    ),
    FanMessage(
      id: 'demo-msg-3',
      fanId: 'fan_syd_003',
      fanName: 'Maria Solano',
      fighterId: 'haze_hepi',
      fighterName: 'Haze Hepi',
      content:
          'My kids look up to you — can you give them a shoutout? Liam and Aroha, Sydney. They wear your merch to school every Friday!',
      type: FanMessageType.shoutout,
      status: MessageStatus.approved,
      upvotes: 234,
      createdAt: DateTime(2026, 3, 22),
      moderatedAt: DateTime(2026, 3, 22),
    ),
    FanMessage(
      id: 'demo-msg-4',
      fanId: 'fan_melb_004',
      fanName: 'Damien Taulagi',
      fighterId: 'haze_hepi',
      fighterName: 'Haze Hepi',
      content:
          'That doctor stoppage in Rome was robbery. You were winning that fight. Finish him in Townsville — the Islanders demand it. 💪',
      type: FanMessageType.reaction,
      status: MessageStatus.approved,
      upvotes: 891,
      createdAt: DateTime(2026, 3, 15),
      moderatedAt: DateTime(2026, 3, 15),
    ),
    FanMessage(
      id: 'demo-msg-5',
      fanId: 'fan_bris_005',
      fanName: 'Sophie Chen',
      fighterId: 'mark_flanagan',
      fighterName: 'Mark Flanagan',
      content:
          'Watched you fight for the WBA title years ago — incredible to see you go bare knuckle. What made you take the leap?',
      type: FanMessageType.question,
      status: MessageStatus.approved,
      upvotes: 178,
      createdAt: DateTime(2026, 3, 21),
      moderatedAt: DateTime(2026, 3, 21),
    ),
    FanMessage(
      id: 'demo-msg-6',
      fanId: 'fan_auck_006',
      fanName: 'Wiremu Henare',
      fighterId: 'haze_hepi',
      fighterName: 'Haze Hepi',
      content:
          'What does Logan mean to you? The whole community is rallying behind you for April 18.',
      type: FanMessageType.question,
      status: MessageStatus.answered,
      upvotes: 1245,
      createdAt: DateTime(2026, 3, 14),
      moderatedAt: DateTime(2026, 3, 14),
    ),
  ];

  static final List<FighterResponse> _demoResponses = [
    FighterResponse(
      id: 'demo-resp-1',
      messageId: 'demo-msg-2',
      fighterId: 'haze_hepi',
      fighterName: 'Haze Hepi',
      content:
          'Wisniewski is big and he\'s tough — respect to him. But I\'ve been working on things '
          'in camp that\'ll surprise everyone. I\'m faster, I\'m sharper, and this time there\'s no '
          'doctor stopping anything. Game plan? Hit him with everything I\'ve got until he drops. '
          'Simple as that. 🤙',
      type: ResponseType.text,
      likes: 1456,
      shares: 234,
      createdAt: DateTime(2026, 3, 19),
    ),
    FighterResponse(
      id: 'demo-resp-2',
      messageId: 'demo-msg-6',
      fighterId: 'haze_hepi',
      fighterName: 'Haze Hepi',
      content:
          'Logan is everything. It\'s where I learned to fight — not in a gym, but in life. '
          'My family, my community, the Pacific culture. When I step into that ring in Townsville, '
          'I carry all of them with me. Every punch is for the kids in Logan who think they can\'t '
          'make it. You can. I\'m proof. 🌺',
      type: ResponseType.text,
      likes: 2891,
      shares: 567,
      createdAt: DateTime(2026, 3, 16),
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // FAN ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit a message to a fighter (goes through ModerationEngine pipeline)
  Future<String> submitMessage({
    required String fighterId,
    required String fighterName,
    required String content,
    required FanMessageType type,
    QuestionTopic topic = QuestionTopic.general,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be signed in to send messages');

    // Rate limit check
    await _enforceRateLimit(user.uid, fighterId);

    // Run through ModerationEngine Layer 1 (rules) + Layer 2 (AI scoring)
    final modResult = await _modEngine.moderate(
      content: content,
      userId: user.uid,
      type: ModerationType.question,
      targetId: fighterId,
    );

    // Determine message status based on moderation result
    final MessageStatus initialStatus;
    final String? rejectionReason;

    if (modResult.blocked) {
      initialStatus = MessageStatus.rejected;
      rejectionReason =
          modResult.reason ?? 'Content violates community guidelines';
    } else if (modResult.flagged) {
      initialStatus = MessageStatus.pending; // queued for human review
      rejectionReason = null;
    } else {
      initialStatus = MessageStatus.approved; // auto-approved — clean content
      rejectionReason = null;
    }

    final message = FanMessage(
      id: '',
      fanId: user.uid,
      fanName: user.displayName ?? 'Fan',
      fanPhotoUrl: user.photoURL,
      fighterId: fighterId,
      fighterName: fighterName,
      content: content.trim(),
      type: type,
      topic: topic,
      status: initialStatus,
      toxicityScore: modResult.toxicityScore,
      rejectionReason: rejectionReason,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('fan_messages')
        .add(message.toFirestore());

    // If auto-rejected, throw so the UI can inform the user
    if (initialStatus == MessageStatus.rejected) {
      throw Exception(rejectionReason);
    }

    return docRef.id;
  }

  /// Enforce per-user rate limits
  Future<void> _enforceRateLimit(String userId, String fighterId) async {
    final dayAgo = DateTime.now().subtract(const Duration(hours: 24));
    try {
      // Per-fighter limit
      final perFighter = await _firestore
          .collection('fan_messages')
          .where('fanId', isEqualTo: userId)
          .where('fighterId', isEqualTo: fighterId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(dayAgo))
          .count()
          .get();
      if ((perFighter.count ?? 0) >= maxQuestionsPerFighterPerDay) {
        throw Exception(
          'Rate limit: max $maxQuestionsPerFighterPerDay messages per fighter per day',
        );
      }

      // Global daily limit
      final global = await _firestore
          .collection('fan_messages')
          .where('fanId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(dayAgo))
          .count()
          .get();
      if ((global.count ?? 0) >= maxTotalSubmissionsPerDay) {
        throw Exception(
          'Rate limit: max $maxTotalSubmissionsPerDay total messages per day',
        );
      }
    } catch (e) {
      if (e.toString().contains('Rate limit')) rethrow;
      // Firestore unavailable — allow through (demo mode)
      debugPrint('CorrespondenceService: Rate limit check skipped: $e');
    }
  }

  /// Upvote a fan message (so fighters see the most popular questions first)
  Future<void> upvoteMessage(String messageId) async {
    await _firestore.collection('fan_messages').doc(messageId).update({
      'upvotes': FieldValue.increment(1),
    });
  }

  /// Save message for later (fighter action)
  Future<void> saveForLater(String messageId) async {
    await _firestore.collection('fan_messages').doc(messageId).update({
      'savedForLater': true,
    });
  }

  /// Skip / unsave a message
  Future<void> unsaveMessage(String messageId) async {
    await _firestore.collection('fan_messages').doc(messageId).update({
      'savedForLater': false,
    });
  }

  /// Get saved-for-later messages for a fighter
  Stream<List<FanMessage>> getSavedMessages(String fighterId) {
    return _firestore
        .collection('fan_messages')
        .where('fighterId', isEqualTo: fighterId)
        .where('savedForLater', isEqualTo: true)
        .where('status', whereIn: ['approved', 'answered'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(FanMessage.fromFirestore).toList(),
        )
        .handleError((e) {
          debugPrint('CorrespondenceService.getSavedMessages fallback: $e');
          return <FanMessage>[];
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHTER ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get approved messages for a fighter (filtered, safe inbox)
  Stream<List<FanMessage>> getFighterInbox(String fighterId) {
    return _firestore
        .collection('fan_messages')
        .where('fighterId', isEqualTo: fighterId)
        .where('status', whereIn: ['approved', 'answered'])
        .orderBy('upvotes', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs
                .map(FanMessage.fromFirestore)
                .toList();
          }
          return _demoMessages
              .where(
                (m) =>
                    m.fighterId == fighterId &&
                    (m.status == MessageStatus.approved ||
                        m.status == MessageStatus.answered),
              )
              .toList();
        })
        .handleError((e) {
          debugPrint('CorrespondenceService.getFighterInbox fallback: $e');
          return _demoMessages.where((m) => m.fighterId == fighterId).toList();
        });
  }

  /// Get all approved messages across all fighters (for demo/browse)
  Stream<List<FanMessage>> getAllApprovedMessages() {
    return _firestore
        .collection('fan_messages')
        .where('status', whereIn: ['approved', 'answered'])
        .orderBy('upvotes', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs
                .map(FanMessage.fromFirestore)
                .toList();
          }
          return List<FanMessage>.from(_demoMessages);
        })
        .handleError((e) {
          debugPrint(
            'CorrespondenceService.getAllApprovedMessages fallback: $e',
          );
          return List<FanMessage>.from(_demoMessages);
        });
  }

  /// Fighter sends a response to an approved message.
  /// Response goes through a light auto-check before publishing.
  Future<String> respondToMessage({
    required String messageId,
    required String content,
    ResponseType type = ResponseType.text,
    String? mediaUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Must be signed in to respond');

    // Light auto-check on fighter reply (rules only, no heavy AI)
    final rulesCheck = _modEngine.checkRules(content, ModerationType.comment);
    if (rulesCheck.blocked) {
      throw Exception(rulesCheck.reason ?? 'Reply contains prohibited content');
    }

    final response = FighterResponse(
      id: '',
      messageId: messageId,
      fighterId: user.uid,
      fighterName: user.displayName ?? 'Fighter',
      fighterPhotoUrl: user.photoURL,
      content: content.trim(),
      type: type,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection('fighter_responses')
        .add(response.toFirestore());

    // Mark the original message as answered
    await _firestore.collection('fan_messages').doc(messageId).update({
      'status': MessageStatus.answered.name,
    });

    // If reply is clean, publish to feed
    if (!rulesCheck.flagged) {
      await _firestore.collection('fighter_responses').doc(docRef.id).update({
        'publishedToFeed': true,
      });
    }

    return docRef.id;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC Q&A FEED
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get published Q&A pairs (answered messages + responses) for public feed
  Stream<List<FighterResponse>> getPublicResponses({String? fighterId}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('fighter_responses')
        .orderBy('createdAt', descending: true);

    if (fighterId != null) {
      query = query.where('fighterId', isEqualTo: fighterId);
    }

    return query
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs
                .map(FighterResponse.fromFirestore)
                .toList();
          }
          if (fighterId != null) {
            return _demoResponses
                .where((r) => r.fighterId == fighterId)
                .toList();
          }
          return List<FighterResponse>.from(_demoResponses);
        })
        .handleError((e) {
          debugPrint('CorrespondenceService.getPublicResponses fallback: $e');
          return List<FighterResponse>.from(_demoResponses);
        });
  }

  /// Get the original fan message for a response (for displaying Q&A pairs)
  Future<FanMessage?> getMessageForResponse(String messageId) async {
    try {
      final doc = await _firestore
          .collection('fan_messages')
          .doc(messageId)
          .get();
      if (doc.exists) return FanMessage.fromFirestore(doc);
    } catch (e) {
      debugPrint('CorrespondenceService.getMessageForResponse fallback: $e');
    }
    return _demoMessages.where((m) => m.id == messageId).firstOrNull;
  }

  /// Like a fighter's response
  Future<void> likeResponse(String responseId) async {
    await _firestore.collection('fighter_responses').doc(responseId).update({
      'likes': FieldValue.increment(1),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODERATION (admin use)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get pending messages for moderation review
  Stream<List<FanMessage>> getModerationQueue() {
    return _firestore
        .collection('fan_messages')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(FanMessage.fromFirestore)
              .toList(),
        );
  }

  /// Approve a message (moves it to fighter inbox)
  Future<void> approveMessage(String messageId) async {
    await _firestore.collection('fan_messages').doc(messageId).update({
      'status': MessageStatus.approved.name,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Reject a message with reason
  Future<void> rejectMessage(String messageId, String reason) async {
    await _firestore.collection('fan_messages').doc(messageId).update({
      'status': MessageStatus.rejected.name,
      'rejectionReason': reason,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }
}
