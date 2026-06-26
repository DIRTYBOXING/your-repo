import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../models/message_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC Messaging Service — Real Firestore backend
///
/// Collections:
///   conversations/{convId}               — Conversation metadata
///   conversations/{convId}/messages/{id}  — Individual messages
///
/// Supports: inbox stream, send, reply, mark-read, new conversation,
///           search users to start a chat
/// ═══════════════════════════════════════════════════════════════════════════
class MessagingService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );
  static const String ninjaUserId = 'dfc_ninja';
  static const String ninjaDisplayName = 'DFC Ninja';
  static const bool _useFirebaseEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
  );
  static const int _ninjaWelcomeVersion = 1;
  static final Map<String, String> _ninjaPersonaCache = <String, String>{};
  static bool get _useDemoData {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (_useFirebaseEmulator) {
      return false;
    }
    return AppConstants.webDemoMode ||
        !AppConstants.authEnabled ||
        AppConstants.guestMode ||
        (currentUser?.isAnonymous ?? false) ||
        (kIsWeb && currentUser == null);
  }

  Stream<int>? _totalUnreadStream;
  String? _totalUnreadUserId;
  static final StreamController<List<Conversation>>
  _demoConversationController =
      StreamController<List<Conversation>>.broadcast();
  static final Map<String, List<Message>> _demoLocalMessages = {};
  static final Map<String, Conversation> _demoConversationOverrides = {};
  static final Map<String, StreamController<List<Message>>>
  _demoMessageControllers = {};
  static final Set<String> _demoDeletedConversationIds = <String>{};

  String _photoUrlFromUserData(Map<String, dynamic> data) =>
      (data['photoUrl'] ?? data['photoURL'] ?? '').toString();

  static StreamController<List<Message>> _demoMessageController(
    String conversationId,
  ) {
    return _demoMessageControllers.putIfAbsent(
      conversationId,
      StreamController<List<Message>>.broadcast,
    );
  }

  List<Conversation> _currentDemoConversations(String userId) {
    final merged = <String, Conversation>{};
    for (final conversation in _demoConversations(userId)) {
      if (_demoDeletedConversationIds.contains(conversation.id)) continue;
      merged[conversation.id] = conversation;
    }
    for (final entry in _demoConversationOverrides.entries) {
      final conversation = entry.value;
      if (_demoDeletedConversationIds.contains(conversation.id)) continue;
      if (!conversation.participants.contains(userId)) continue;
      merged[conversation.id] = conversation;
    }

    final conversations = merged.values.toList();
    conversations.sort((a, b) {
      final aIsNinja = _isPinnedNinjaConversation(a, userId);
      final bIsNinja = _isPinnedNinjaConversation(b, userId);
      if (aIsNinja != bIsNinja) {
        return aIsNinja ? -1 : 1;
      }
      final aTime = a.lastMessageAt ?? a.createdAt;
      final bTime = b.lastMessageAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });
    return conversations;
  }

  List<Message> _currentDemoMessages(String conversationId) {
    final messages = _demoLocalMessages[conversationId];
    if (messages != null) {
      final sorted = List<Message>.from(messages);
      sorted.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return sorted;
    }

    final fallback = _demoMessages(conversationId);
    return List<Message>.from(fallback)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  Conversation? _findDemoConversation(String conversationId, String userId) {
    for (final conversation in _currentDemoConversations(userId)) {
      if (conversation.id == conversationId) {
        return conversation;
      }
    }
    return null;
  }

  void _emitDemoMessageUpdate(String conversationId) {
    _demoMessageController(
      conversationId,
    ).add(_currentDemoMessages(conversationId));
  }

  void _emitDemoConversationUpdate(String userId) {
    _demoConversationController.add(_currentDemoConversations(userId));
  }

  int _demoUnreadTotal(String userId) {
    var total = 0;
    for (final conversation in _currentDemoConversations(userId)) {
      total += conversation.unreadCounts[userId] ?? 0;
    }
    return total;
  }

  Future<void> _appendDemoMessage({
    required String conversationId,
    required Message message,
    required String viewerUserId,
  }) async {
    final currentMessages = _currentDemoMessages(conversationId);
    final updatedMessages = List<Message>.from(currentMessages)..add(message);
    updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    _demoLocalMessages[conversationId] = updatedMessages;

    final existingConversation =
        _findDemoConversation(conversationId, viewerUserId) ??
        Conversation(
          id: conversationId,
          participants: [viewerUserId, message.senderId],
          participantNames: {
            viewerUserId: 'You',
            message.senderId: message.senderName,
          },
          createdAt: message.sentAt,
        );

    final unreadCounts = Map<String, int>.from(
      existingConversation.unreadCounts,
    );
    for (final participant in existingConversation.participants) {
      if (participant == message.senderId) continue;
      unreadCounts[participant] = (unreadCounts[participant] ?? 0) + 1;
    }

    _demoConversationOverrides[conversationId] = Conversation(
      id: existingConversation.id,
      participants: existingConversation.participants,
      participantNames: existingConversation.participantNames,
      participantPhotoUrls: existingConversation.participantPhotoUrls,
      lastMessage: message.text.length > 80
          ? '${message.text.substring(0, 80)}...'
          : message.text,
      lastMessageAt: message.sentAt,
      lastSenderId: message.senderId,
      unreadCounts: unreadCounts,
      createdAt: existingConversation.createdAt,
      isGroup: existingConversation.isGroup,
      groupName: existingConversation.groupName,
      groupPhotoUrl: existingConversation.groupPhotoUrl,
      typingUsers: existingConversation.typingUsers,
    );

    _emitDemoMessageUpdate(conversationId);
    _emitDemoConversationUpdate(viewerUserId);
    notifyListeners();
  }

  void _scheduleLocalNinjaReply(
    String conversationId,
    String userId,
    String userText,
  ) {
    Future.delayed(const Duration(milliseconds: 1200), () async {
      final reply = _generateNinjaReply(userText);
      final now = DateTime.now();
      final message = Message(
        id: 'demo_msg_${now.microsecondsSinceEpoch}',
        senderId: ninjaUserId,
        senderName: ninjaDisplayName,
        text: reply,
        sentAt: now,
      );
      await _appendDemoMessage(
        conversationId: conversationId,
        message: message,
        viewerUserId: userId,
      );
    });
  }

  List<Map<String, String>> _demoSearchResults(
    String query, {
    String? excludeUserId,
  }) {
    final lower = query.trim().toLowerCase();
    const contacts = [
      {'uid': 'joey_demicoli', 'displayName': 'Joey Demicoli', 'photoUrl': ''},
      {'uid': 'john_scida', 'displayName': 'John Scida', 'photoUrl': ''},
      {
        'uid': 'jordan_roesler',
        'displayName': 'Jordan Roesler',
        'photoUrl': '',
      },
      {
        'uid': 'stephanie_cutting',
        'displayName': 'Stephanie Lee Cutting',
        'photoUrl': '',
      },
      {'uid': ninjaUserId, 'displayName': ninjaDisplayName, 'photoUrl': ''},
    ];

    return contacts
        .where((contact) => contact['uid'] != excludeUserId)
        .where(
          (contact) =>
              (contact['displayName'] ?? '').toLowerCase().contains(lower) ||
              (contact['uid'] ?? '').toLowerCase().contains(lower),
        )
        .map(Map<String, String>.from)
        .toList();
  }

  // ── Inbox stream ────────────────────────────────────────────────────────
  /// Returns live stream of all conversations the user participates in,
  /// ordered by most recent message first.
  Stream<List<Conversation>> conversationsStream(String userId) {
    if (_useDemoData) {
      return Stream.multi((listener) {
        listener.add(_currentDemoConversations(userId));
        final sub = _demoConversationController.stream.listen(
          (_) => listener.add(_currentDemoConversations(userId)),
        );
        listener.onCancel = sub.cancel;
      });
    }

    return _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((snap) async {
          var convs = snap.docs
              .map(Conversation.fromFirestore)
              .toList();
          if (convs.isEmpty) {
            convs = await _loadLegacyConversations(userId);
          }
          convs.sort((a, b) {
            final aIsNinja = _isPinnedNinjaConversation(a, userId);
            final bIsNinja = _isPinnedNinjaConversation(b, userId);
            if (aIsNinja != bIsNinja) {
              return aIsNinja ? -1 : 1;
            }
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });
          return convs;
        })
        .handleError((_) => <Conversation>[]);
  }

  Future<List<Conversation>> _loadLegacyConversations(String userId) async {
    final sent = await _db
        .collection('messages')
        .where('senderId', isEqualTo: userId)
        .limit(200)
        .get();
    final received = await _db
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .limit(200)
        .get();

    final merged = [...sent.docs, ...received.docs];
    final byPair = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    for (final doc in merged) {
      final data = doc.data();
      final sender = (data['senderId'] ?? '').toString();
      final receiver = (data['receiverId'] ?? '').toString();
      if (sender.isEmpty || receiver.isEmpty) continue;
      final pairId = _legacyPairId(sender, receiver);
      final existing = byPair[pairId];
      if (existing == null) {
        byPair[pairId] = doc;
        continue;
      }
      final existingTs =
          _legacyMessageTime(existing.data()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final incomingTs =
          _legacyMessageTime(data) ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (incomingTs.isAfter(existingTs)) {
        byPair[pairId] = doc;
      }
    }

    return byPair.entries.map((entry) {
      final data = entry.value.data();
      final sender = (data['senderId'] ?? '').toString();
      final receiver = (data['receiverId'] ?? '').toString();
      final createdAt = _legacyMessageTime(data) ?? DateTime.now();
      final senderName = (data['senderName'] ?? sender).toString();
      final receiverName = (data['receiverName'] ?? receiver).toString();
      final lastMessage =
          (data['text'] ?? data['message'] ?? data['content'] ?? '').toString();

      return Conversation(
        id: 'legacy_${entry.key}',
        participants: [sender, receiver],
        participantNames: {sender: senderName, receiver: receiverName},
        lastMessage: lastMessage,
        lastMessageAt: createdAt,
        lastSenderId: sender,
        createdAt: createdAt,
      );
    }).toList();
  }

  String _legacyPairId(String a, String b) {
    final pair = [a, b]..sort();
    return '${pair[0]}__${pair[1]}';
  }

  (String, String)? _parseLegacyConversationId(String conversationId) {
    if (!conversationId.startsWith('legacy_')) return null;
    final raw = conversationId.substring('legacy_'.length);
    final parts = raw.split('__');
    if (parts.length != 2) return null;
    return (parts[0], parts[1]);
  }

  DateTime? _legacyMessageTime(Map<String, dynamic> data) {
    final raw = data['sentAt'] ?? data['createdAt'] ?? data['date'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  /// Demo conversations for showcase when Firestore has no data
  static List<Conversation> _demoConversations(String userId) {
    final now = DateTime.now();
    return [
      Conversation(
        id: 'demo_ninja',
        participants: [userId, ninjaUserId],
        participantNames: {userId: 'You', ninjaUserId: ninjaDisplayName},
        lastMessage:
            'Welcome to DFC! Ask me anything about fights, events, or training.',
        lastMessageAt: now.subtract(const Duration(minutes: 2)),
        lastSenderId: ninjaUserId,
        unreadCounts: {userId: 1},
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      Conversation(
        id: 'demo_joey',
        participants: [userId, 'joey_demicoli'],
        participantNames: {userId: 'You', 'joey_demicoli': 'Joey Demicoli'},
        lastMessage:
            'April 24 card is locked in. 12 bouts confirmed for Ultimate Legends.',
        lastMessageAt: now.subtract(const Duration(minutes: 18)),
        lastSenderId: 'joey_demicoli',
        unreadCounts: {userId: 2},
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Conversation(
        id: 'demo_jordan',
        participants: [userId, 'jordan_roesler'],
        participantNames: {userId: 'You', 'jordan_roesler': 'Jordan Roesler'},
        lastMessage:
            'Fight camp is going well. Weight is on track for the 24th.',
        lastMessageAt: now.subtract(const Duration(hours: 2)),
        lastSenderId: 'jordan_roesler',
        unreadCounts: {userId: 1},
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Conversation(
        id: 'demo_john',
        participants: [userId, 'john_scida'],
        participantNames: {userId: 'You', 'john_scida': 'John Scida'},
        lastMessage: 'Venue is confirmed. Tickets go on sale this week.',
        lastMessageAt: now.subtract(const Duration(hours: 6)),
        lastSenderId: 'john_scida',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Conversation(
        id: 'demo_stephanie',
        participants: [userId, 'stephanie_cutting'],
        participantNames: {
          userId: 'You',
          'stephanie_cutting': 'Stephanie Lee Cutting',
        },
        lastMessage: 'Thanks for the shoutout on the feed! Means a lot.',
        lastMessageAt: now.subtract(const Duration(hours: 14)),
        lastSenderId: 'stephanie_cutting',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Conversation(
        id: 'demo_group',
        participants: [userId, 'joey_demicoli', 'john_scida', 'jordan_roesler'],
        participantNames: {
          userId: 'You',
          'joey_demicoli': 'Joey Demicoli',
          'john_scida': 'John Scida',
          'jordan_roesler': 'Jordan Roesler',
        },
        lastMessage: 'Main event weigh-in is Thursday 5pm. Everyone be there.',
        lastMessageAt: now.subtract(const Duration(days: 1)),
        lastSenderId: 'joey_demicoli',
        unreadCounts: {userId: 3},
        createdAt: now.subtract(const Duration(days: 14)),
        isGroup: true,
        groupName: 'Ultimate Legends — April 24',
      ),
    ];
  }

  bool _isNinjaConversation(Conversation conv) {
    if (conv.participants.contains(ninjaUserId)) return true;
    return conv.participantNames.values.any(
      (name) => name.trim().toLowerCase() == ninjaDisplayName.toLowerCase(),
    );
  }

  bool _isPinnedNinjaConversation(Conversation conv, String userId) {
    if (!_isNinjaConversation(conv)) return false;
    final unread = conv.unreadCounts[userId] ?? 0;
    return unread > 0;
  }

  // ── Ninja auto-reply engine ─────────────────────────────────────────────
  void _scheduleNinjaReply(
    String conversationId,
    String userId,
    String userText,
  ) {
    Future.delayed(const Duration(milliseconds: 1200), () async {
      try {
        final persona = await _resolveNinjaPersona(userId);
        final reply = await _resolveNinjaReplyAsync(userText, persona: persona);
        final now = DateTime.now();
        final msgRef = _db
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .doc();
        final convRef = _db.collection('conversations').doc(conversationId);

        final batch = _db.batch();
        batch.set(msgRef, {
          'senderId': ninjaUserId,
          'senderName': ninjaDisplayName,
          'text': reply,
          'sentAt': Timestamp.fromDate(now),
          'read': false,
        });
        batch.update(convRef, {
          'lastMessage': reply.length > 80
              ? '${reply.substring(0, 80)}...'
              : reply,
          'lastMessageAt': Timestamp.fromDate(now),
          'lastSenderId': ninjaUserId,
          'unreadCounts.$userId': FieldValue.increment(1),
        });
        await batch.commit();
        notifyListeners();
      } catch (_) {
        // Ninja reply is best-effort; don't crash if Firestore fails
      }
    });
  }

  Future<String> _resolveNinjaPersona(String userId) async {
    if (_useDemoData || userId.isEmpty || userId == ninjaUserId) {
      return 'neutral';
    }

    final cached = _ninjaPersonaCache[userId];
    if (cached != null) {
      return cached;
    }

    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data() ?? const <String, dynamic>{};
      final metadata = data['metadata'];
      String sex = '';
      if (metadata is Map<String, dynamic>) {
        sex = (metadata['sex'] ?? '').toString().toLowerCase().trim();
      }

      var persona = 'neutral';
      if (sex == 'female' || sex == 'woman' || sex == 'f') {
        persona = 'female';
      } else if (sex == 'male' || sex == 'man' || sex == 'm') {
        persona = 'male';
      }

      _ninjaPersonaCache[userId] = persona;
      return persona;
    } catch (_) {
      return 'neutral';
    }
  }

  Future<String> _resolveNinjaReplyAsync(
    String userText, {
    required String persona,
  }) async {
    try {
      final callable = _functions.httpsCallable('askNinja');
      final result = await callable
          .call(<String, dynamic>{
            'message': userText.trim(),
            'persona': persona,
          })
          .timeout(const Duration(seconds: 5));

      final data = result.data;
      if (data is Map) {
        final reply = (data['reply'] ?? '').toString().trim();
        if (reply.isNotEmpty) {
          return reply;
        }
      }
    } catch (_) {
      // Fallback to local engine when callable is unavailable or rate-limited.
    }

    return _generateNinjaReply(userText, persona: persona);
  }

  String _generateNinjaReply(String userText, {String persona = 'neutral'}) {
    final lower = userText.toLowerCase().trim();
    final intro = persona == 'female'
        ? 'Shakura here. '
        : persona == 'male'
        ? 'DFC Ninja here. '
        : 'Ninja here. ';

    if (lower.startsWith('hi') ||
        lower.startsWith('hello') ||
        lower.startsWith('hey') ||
        lower.contains('yo ninja')) {
      return '${intro}I can guide fights, training, PPV, maps, social, friends, and messaging. What lane are we locking in first?';
    }

    if (lower.contains('ppv') ||
        lower.contains('pay per view') ||
        (lower.contains('buy') && lower.contains('fight')) ||
        lower.contains('replay')) {
      return '${intro}Open the PPV tab for upcoming and live cards. Purchased events unlock directly into your library for live and replay access.';
    }

    if (lower.contains('event') ||
        lower.contains('card') ||
        lower.contains('main event') ||
        lower.contains('co-main')) {
      return '${intro}For fight cards, use PPV filters by status and discipline, then open a card for lineup, timing, and watch state. We track UFC, ONE, BKFC, boxing, and regional promotions.';
    }

    if (lower.contains('fighter') ||
        lower.contains('record') ||
        lower.contains('rank') ||
        lower.contains('p4p') ||
        lower.contains('champion')) {
      return '${intro}Use Explore for fighter discovery and rankings by weight class and discipline. Atlas is best when you want deeper matchup strategy.';
    }

    if (lower.contains('mma') ||
        lower.contains('ufc') ||
        lower.contains('grappl') ||
        lower.contains('wrestl') ||
        lower.contains('bjj') ||
        lower.contains('submission')) {
      return '${intro}MMA advantage comes from transitions: strike to clinch, cage control, level-change timing, and safe exits. Build rounds around position and momentum, not chaos.';
    }

    if (lower.contains('boxing') ||
        lower.contains('jab') ||
        lower.contains('combination') ||
        lower.contains('footwork') ||
        lower.contains('head movement')) {
      return '${intro}Boxing progression is simple and hard: command the jab, manage distance with your feet, and defend responsibly after combinations.';
    }

    if (lower.contains('muay thai') ||
        lower.contains('kickbox') ||
        lower.contains('clinch') ||
        lower.contains('elbow') ||
        lower.contains('knee')) {
      return '${intro}In striking arts, win range first, punish exits, and use clinch control when opponents shell. Small technical wins stack fast.';
    }

    if (lower.contains('train') ||
        lower.contains('camp') ||
        lower.contains('drill') ||
        lower.contains('program')) {
      return '${intro}Use AI Coach Shido for periodized camp blocks: skill, conditioning, and taper. Include your discipline and fight date for better plan quality.';
    }

    if (lower.contains('weight cut') ||
        lower.contains('cut weight') ||
        lower.contains('rehydrat') ||
        lower.contains('nutrition') ||
        lower.contains('diet')) {
      return '${intro}Weight strategy should be conservative and phased: gradual reduction, controlled cut week, then structured rehydration and sodium recovery.';
    }

    if (lower.contains('injury') ||
        lower.contains('recovery') ||
        lower.contains('overtrain') ||
        lower.contains('fatigue')) {
      return '${intro}Protect longevity with sleep, mobility, and smart deloads. Track fatigue signals before intensity drops your output.';
    }

    if (lower.contains('mindset') ||
        lower.contains('nervous') ||
        lower.contains('confidence') ||
        lower.contains('mental')) {
      return '${intro}Mental edge is built through repetition: breathing resets, process goals, and round-by-round tactical focus.';
    }

    if (lower.contains('post') ||
        lower.contains('feed') ||
        lower.contains('fightwire') ||
        lower.contains('social')) {
      return '${intro}Feed is your growth engine. Post clips and insights, then engage fast in comments to amplify reach and trust.';
    }

    if (lower.contains('friend') ||
        lower.contains('follow') ||
        lower.contains('network') ||
        lower.contains('community')) {
      return '${intro}Network handles friend requests, discovery, and social graph growth. Keep your profile discipline and region accurate for better suggestions.';
    }

    if (lower.contains('message') ||
        lower.contains('inbox') ||
        lower.contains('dm') ||
        lower.contains('messenger')) {
      return '${intro}Inbox supports live threads and quick search. Use it to coordinate camps, cards, and collaboration directly.';
    }

    if (lower.contains('map') ||
        lower.contains('gym') ||
        lower.contains('academy') ||
        lower.contains('location')) {
      return '${intro}Map lane finds nearby gyms and events by discipline and region. Filter first, then message directly from profile entries.';
    }

    if (lower.contains('promoter') ||
        lower.contains('promotion') ||
        lower.contains('sponsor') ||
        lower.contains('career')) {
      return '${intro}For career growth: keep records sharp, publish proof-of-work consistently, and network with promoters and sponsors through messaging and social lanes.';
    }

    if (lower.contains('help') || lower.contains('?')) {
      return '${intro}I can help with:\n'
          '\u2022 PPV \u2014 purchase, live, replay\n'
          '\u2022 Fighters \u2014 rankings and records\n'
          '\u2022 Training \u2014 camps with AI Coach\n'
          '\u2022 Social \u2014 feed growth and engagement\n'
          '\u2022 Maps \u2014 gyms and local events\n'
          '\u2022 Network \u2014 friends and messaging\n\n'
          'Tell me your goal and timeline.';
    }

    return '${intro}Give me your target and timeline, and I will map the fastest DFC lane.';
  }

  // ── Messages stream for a conversation ──────────────────────────────────
  Stream<List<Message>> messagesStream(String conversationId) {
    if (_useDemoData || conversationId.startsWith('demo_')) {
      return Stream.multi((listener) {
        listener.add(_currentDemoMessages(conversationId));
        final sub = _demoMessageController(
          conversationId,
        ).stream.listen(listener.add);
        listener.onCancel = sub.cancel;
      });
    }

    final legacyPair = _parseLegacyConversationId(conversationId);
    if (legacyPair != null) {
      final (a, b) = legacyPair;
      return _db
          .collection('messages')
          .snapshots()
          .map((snap) {
            final filtered =
                snap.docs.where((doc) {
                  final data = doc.data();
                  final sender = (data['senderId'] ?? '').toString();
                  final receiver = (data['receiverId'] ?? '').toString();
                  return (sender == a && receiver == b) ||
                      (sender == b && receiver == a);
                }).toList()..sort((x, y) {
                  final tx =
                      _legacyMessageTime(x.data()) ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final ty =
                      _legacyMessageTime(y.data()) ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return tx.compareTo(ty);
                });

            return filtered.map((doc) {
              final d = doc.data();
              return Message(
                id: doc.id,
                senderId: (d['senderId'] ?? '').toString(),
                senderName: (d['senderName'] ?? d['senderId'] ?? 'User')
                    .toString(),
                text: (d['text'] ?? d['message'] ?? d['content'] ?? '')
                    .toString(),
                sentAt: _legacyMessageTime(d) ?? DateTime.now(),
                read: (d['read'] as bool?) ?? false,
              );
            }).toList();
          })
          .handleError((_) => <Message>[]);
    }

    return _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(Message.fromFirestore).toList())
        .handleError((_) => <Message>[]);
  }

  /// Demo message threads for each demo conversation
  static List<Message> _demoMessages(String conversationId) {
    final now = DateTime.now();
    switch (conversationId) {
      case 'demo_ninja':
        return [
          Message(
            id: 'dn1',
            senderId: ninjaUserId,
            senderName: ninjaDisplayName,
            text:
                'Welcome to DFC! I can help you find fighters, events, or training content. What are you looking for?',
            sentAt: now.subtract(const Duration(minutes: 5)),
          ),
        ];
      case 'demo_joey':
        return [
          Message(
            id: 'dj1',
            senderId: 'joey_demicoli',
            senderName: 'Joey Demicoli',
            text: 'Bro the card is looking insane. 12 bouts confirmed.',
            sentAt: now.subtract(const Duration(hours: 3)),
          ),
          Message(
            id: 'dj2',
            senderId: 'current_user',
            senderName: 'You',
            text: 'All confirmed? No pull-outs?',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 45)),
          ),
          Message(
            id: 'dj3',
            senderId: 'joey_demicoli',
            senderName: 'Joey Demicoli',
            text:
                'All locked in. Scida handled the venue, I sorted the matchmaking. April 24 card is locked in. 12 bouts confirmed for Ultimate Legends.',
            sentAt: now.subtract(const Duration(minutes: 18)),
          ),
        ];
      case 'demo_jordan':
        return [
          Message(
            id: 'dr1',
            senderId: 'current_user',
            senderName: 'You',
            text: 'How is camp going mate?',
            sentAt: now.subtract(const Duration(hours: 6)),
          ),
          Message(
            id: 'dr2',
            senderId: 'jordan_roesler',
            senderName: 'Jordan Roesler',
            text:
                'Good man. Strength is up, cardio is solid. Sparring with the boys at the gym every day.',
            sentAt: now.subtract(const Duration(hours: 5, minutes: 30)),
          ),
          Message(
            id: 'dr3',
            senderId: 'jordan_roesler',
            senderName: 'Jordan Roesler',
            text: 'Fight camp is going well. Weight is on track for the 24th.',
            sentAt: now.subtract(const Duration(hours: 2)),
          ),
        ];
      case 'demo_john':
        return [
          Message(
            id: 'ds1',
            senderId: 'john_scida',
            senderName: 'John Scida',
            text: 'Just finalised the venue contract. All good to go.',
            sentAt: now.subtract(const Duration(hours: 12)),
          ),
          Message(
            id: 'ds2',
            senderId: 'current_user',
            senderName: 'You',
            text: 'Sick. When do tickets drop?',
            sentAt: now.subtract(const Duration(hours: 10)),
          ),
          Message(
            id: 'ds3',
            senderId: 'john_scida',
            senderName: 'John Scida',
            text: 'Venue is confirmed. Tickets go on sale this week.',
            sentAt: now.subtract(const Duration(hours: 6)),
          ),
        ];
      case 'demo_stephanie':
        return [
          Message(
            id: 'dc1',
            senderId: 'stephanie_cutting',
            senderName: 'Stephanie Lee Cutting',
            text:
                'Hey! Saw the post on the feed. Really appreciate the support.',
            sentAt: now.subtract(const Duration(hours: 16)),
          ),
          Message(
            id: 'dc2',
            senderId: 'current_user',
            senderName: 'You',
            text: 'You earned it. That last fight was class.',
            sentAt: now.subtract(const Duration(hours: 15)),
          ),
          Message(
            id: 'dc3',
            senderId: 'stephanie_cutting',
            senderName: 'Stephanie Lee Cutting',
            text: 'Thanks for the shoutout on the feed! Means a lot.',
            sentAt: now.subtract(const Duration(hours: 14)),
          ),
        ];
      case 'demo_group':
        return [
          Message(
            id: 'dg1',
            senderId: 'john_scida',
            senderName: 'John Scida',
            text:
                'Right team, venue is locked. Let us run through the card order.',
            sentAt: now.subtract(const Duration(days: 1, hours: 4)),
          ),
          Message(
            id: 'dg2',
            senderId: 'jordan_roesler',
            senderName: 'Jordan Roesler',
            text: 'I am ready. Put me wherever you need me on the card.',
            sentAt: now.subtract(const Duration(days: 1, hours: 3)),
          ),
          Message(
            id: 'dg3',
            senderId: 'joey_demicoli',
            senderName: 'Joey Demicoli',
            text: 'Main event weigh-in is Thursday 5pm. Everyone be there.',
            sentAt: now.subtract(const Duration(days: 1)),
          ),
        ];
      default:
        return [];
    }
  }

  // ── Send message ────────────────────────────────────────────────────────
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
    if (_useDemoData || conversationId.startsWith('demo_')) {
      final now = DateTime.now();
      final message = Message(
        id: 'demo_msg_${now.microsecondsSinceEpoch}',
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
      await _appendDemoMessage(
        conversationId: conversationId,
        message: message,
        viewerUserId: senderId,
      );
      if (senderId != ninjaUserId && conversationId == 'demo_ninja') {
        _scheduleLocalNinjaReply(conversationId, senderId, text);
      }
      return;
    }

    final legacyPair = _parseLegacyConversationId(conversationId);
    if (legacyPair != null) {
      final (_, otherUserId) = legacyPair.$1 == senderId
          ? (legacyPair.$1, legacyPair.$2)
          : (legacyPair.$2, legacyPair.$1);
      await _db.collection('messages').add({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': otherUserId,
        'text': text,
        'sentAt': Timestamp.fromDate(DateTime.now()),
        'read': false,
      });
      notifyListeners();
      return;
    }

    final now = DateTime.now();
    final msgRef = _db
        .collection('conversations')
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

    // Write message
    batch.set(msgRef, msg.toFirestore());

    // Update conversation metadata
    final convRef = _db.collection('conversations').doc(conversationId);
    final convSnap = await convRef.get();
    if (convSnap.exists) {
      final conv = Conversation.fromFirestore(convSnap);
      // Increment unread for all other participants
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

    // ── Ninja auto-reply: if user messaged the Ninja bot, reply ──────────
    if (senderId != ninjaUserId) {
      final convDoc = await convRef.get();
      if (convDoc.exists) {
        final conv2 = Conversation.fromFirestore(convDoc);
        if (_isNinjaConversation(conv2)) {
          _scheduleNinjaReply(conversationId, senderId, text);
        }
      }
    }
  }

  // ── Mark conversation as read ───────────────────────────────────────────
  Future<void> markAsRead(String conversationId, String userId) async {
    if (_useDemoData || conversationId.startsWith('demo_')) {
      final existingConversation = _findDemoConversation(
        conversationId,
        userId,
      );
      if (existingConversation != null) {
        final unreadCounts = Map<String, int>.from(
          existingConversation.unreadCounts,
        )..[userId] = 0;
        _demoConversationOverrides[conversationId] = Conversation(
          id: existingConversation.id,
          participants: existingConversation.participants,
          participantNames: existingConversation.participantNames,
          participantPhotoUrls: existingConversation.participantPhotoUrls,
          lastMessage: existingConversation.lastMessage,
          lastMessageAt: existingConversation.lastMessageAt,
          lastSenderId: existingConversation.lastSenderId,
          unreadCounts: unreadCounts,
          createdAt: existingConversation.createdAt,
          isGroup: existingConversation.isGroup,
          groupName: existingConversation.groupName,
          groupPhotoUrl: existingConversation.groupPhotoUrl,
          typingUsers: existingConversation.typingUsers,
        );
        _emitDemoConversationUpdate(userId);
      }
      notifyListeners();
      return;
    }

    final legacyPair = _parseLegacyConversationId(conversationId);
    if (legacyPair != null) {
      final (a, b) = legacyPair;
      final snap = await _db.collection('messages').get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        final data = doc.data();
        final sender = (data['senderId'] ?? '').toString();
        final receiver = (data['receiverId'] ?? '').toString();
        final read = (data['read'] as bool?) ?? false;
        final isPair =
            ((sender == a && receiver == b) || (sender == b && receiver == a));
        if (isPair && receiver == userId && !read) {
          batch.update(doc.reference, {
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
        }
      }
      await batch.commit();
      notifyListeners();
      return;
    }

    await _db.collection('conversations').doc(conversationId).update({
      'unreadCounts.$userId': 0,
    });
    notifyListeners();
  }

  // ── Create new conversation ─────────────────────────────────────────────
  Future<String> createConversation({
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required String otherUserName,
    String currentUserPhotoUrl = '',
    String otherUserPhotoUrl = '',
  }) async {
    if (_useDemoData) {
      final existingConversation = _currentDemoConversations(currentUserId)
          .where((conversation) => conversation.participants.length == 2)
          .where(
            (conversation) => conversation.participants.contains(otherUserId),
          )
          .cast<Conversation?>()
          .firstWhere(
            (conversation) => conversation != null,
            orElse: () => null,
          );
      if (existingConversation != null) {
        return existingConversation.id;
      }

      final conversationId =
          'demo_custom_${DateTime.now().millisecondsSinceEpoch}';
      _demoConversationOverrides[conversationId] = Conversation(
        id: conversationId,
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
      _demoDeletedConversationIds.remove(conversationId);
      _emitDemoConversationUpdate(currentUserId);
      return conversationId;
    }

    // Check if conversation already exists between these two users
    final existing = await _db
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return doc.id; // Already exists
      }
    }

    // Create new
    final ref = _db.collection('conversations').doc();
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

  Future<String> ensureNinjaConversationForUser({
    required String currentUserId,
    required String currentUserName,
    String currentUserPhotoUrl = '',
  }) async {
    if (_useDemoData) {
      final existingConversation = _findDemoConversation(
        'demo_ninja',
        currentUserId,
      );
      if (existingConversation != null) {
        return existingConversation.id;
      }
      _demoConversationOverrides['demo_ninja'] = Conversation(
        id: 'demo_ninja',
        participants: [currentUserId, ninjaUserId],
        participantNames: {
          currentUserId: currentUserName,
          ninjaUserId: ninjaDisplayName,
        },
        participantPhotoUrls: {
          currentUserId: currentUserPhotoUrl,
          ninjaUserId: '',
        },
        createdAt: DateTime.now(),
        unreadCounts: {currentUserId: 1, ninjaUserId: 0},
      );
      _emitDemoConversationUpdate(currentUserId);
      return 'demo_ninja';
    }

    final existing = await _db
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (final doc in existing.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(ninjaUserId) && participants.length == 2) {
        return doc.id;
      }
    }

    final ref = _db.collection('conversations').doc();
    final now = DateTime.now();
    final welcomeText =
        'Welcome to DFC. I am your Ninja guide. Tap + to find people and start conversations.';

    final conv = Conversation(
      id: ref.id,
      participants: [currentUserId, ninjaUserId],
      participantNames: {
        currentUserId: currentUserName,
        ninjaUserId: ninjaDisplayName,
      },
      participantPhotoUrls: {
        currentUserId: currentUserPhotoUrl,
        ninjaUserId: '',
      },
      createdAt: now,
      lastMessage: welcomeText,
      lastMessageAt: now,
      lastSenderId: ninjaUserId,
      unreadCounts: {currentUserId: 1, ninjaUserId: 0},
    );

    final msgRef = ref.collection('messages').doc();
    final msg = Message(
      id: msgRef.id,
      senderId: ninjaUserId,
      senderName: ninjaDisplayName,
      text: welcomeText,
      sentAt: now,
    );

    final batch = _db.batch();
    batch.set(ref, conv.toFirestore());
    batch.set(msgRef, msg.toFirestore());
    await batch.commit();

    return ref.id;
  }

  // ── Send Ninja Welcome Broadcast ────────────────────────────────────────
  /// Sends the professional DFC welcome message into the user's existing
  /// Ninja conversation (or creates one if needed). Called once on first
  /// app visit after the welcome overlay appears.
  Future<void> sendNinjaWelcome({
    required String currentUserId,
    required String currentUserName,
    String currentUserPhotoUrl = '',
  }) async {
    const welcomeMsg =
        '\u{1F977} Welcome to DataFight Central.\n\n'
        'Your front-row seat to live combat sports is officially active. '
        'Stream Pay-Per-View events, access world-class training content, '
        'and connect with the global fight community \u2014 all at prices '
        'that respect your corner.\n\n'
        'Flexible payment options including Afterpay and PayPay are '
        'available so you never miss a fight when it matters most.\n\n'
        'Affordable fights. Real training. Your platform.\n\n'
        'Welcome \u2014 and thank you for joining the movement. \u{1F44A}';

    if (_useDemoData) {
      final conversationId = 'demo_ninja';
      final existingMessages = _currentDemoMessages(conversationId);
      if (existingMessages.any((message) => message.text == welcomeMsg)) {
        return;
      }
      await _appendDemoMessage(
        conversationId: conversationId,
        message: Message(
          id: 'demo_msg_${DateTime.now().microsecondsSinceEpoch}',
          senderId: ninjaUserId,
          senderName: ninjaDisplayName,
          text: welcomeMsg,
          sentAt: DateTime.now(),
        ),
        viewerUserId: currentUserId,
      );
      return;
    }

    final convId = await ensureNinjaConversationForUser(
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserPhotoUrl: currentUserPhotoUrl,
    );

    final convRef = _db.collection('conversations').doc(convId);
    final convSnap = await convRef.get();
    final currentVersion =
        (convSnap.data()?['ninjaWelcomeVersion'] as num?)?.toInt() ?? 0;
    if (currentVersion >= _ninjaWelcomeVersion) {
      return;
    }

    final now = DateTime.now();
    final msgRef = convRef.collection('messages').doc();
    final msg = Message(
      id: msgRef.id,
      senderId: ninjaUserId,
      senderName: ninjaDisplayName,
      text: welcomeMsg,
      sentAt: now,
    );

    final batch = _db.batch();
    batch.set(msgRef, msg.toFirestore());
    batch.update(convRef, {
      'lastMessage': welcomeMsg,
      'lastMessageAt': Timestamp.fromDate(now),
      'lastSenderId': ninjaUserId,
      'unreadCounts.$currentUserId': FieldValue.increment(1),
      'ninjaWelcomeVersion': _ninjaWelcomeVersion,
    });
    await batch.commit();
    notifyListeners();
  }

  // ── Search users for new conversation ───────────────────────────────────
  Future<List<Map<String, String>>> searchUsers(
    String query, {
    String? excludeUserId,
  }) async {
    if (query.length < 2) return [];
    if (_useDemoData) {
      return _demoSearchResults(query, excludeUserId: excludeUserId);
    }
    final trimmed = query.trim();
    final lower = trimmed.toLowerCase();

    try {
      final byDisplayName = await _db
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: trimmed)
          .where('displayName', isLessThanOrEqualTo: '$trimmed\uf8ff')
          .limit(30)
          .get();

      QuerySnapshot<Map<String, dynamic>>? byDisplayNameLower;
      try {
        byDisplayNameLower = await _db
            .collection('users')
            .where('displayNameLower', isGreaterThanOrEqualTo: lower)
            .where('displayNameLower', isLessThanOrEqualTo: '$lower\uf8ff')
            .limit(30)
            .get();
      } catch (_) {
        byDisplayNameLower = null;
      }

      QuerySnapshot<Map<String, dynamic>>? byEmail;
      try {
        byEmail = await _db
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: trimmed)
            .where('email', isLessThanOrEqualTo: '$trimmed\uf8ff')
            .limit(20)
            .get();
      } catch (_) {
        byEmail = null;
      }

      final merged = <String, Map<String, String>>{};
      final docs = [
        ...byDisplayName.docs,
        ...?byDisplayNameLower?.docs,
        ...?byEmail?.docs,
      ];

      for (final d in docs) {
        if (excludeUserId != null && d.id == excludeUserId) continue;
        final data = d.data();
        final name = (data['displayName'] ?? data['name'] ?? 'User').toString();
        final photoUrl = _photoUrlFromUserData(data);
        if (name.isEmpty) continue;
        merged[d.id] = {'uid': d.id, 'displayName': name, 'photoUrl': photoUrl};
      }

      if (merged.isNotEmpty) {
        return merged.values.toList();
      }

      final fallback = await _db.collection('users').limit(200).get();
      final filtered = <Map<String, String>>[];
      for (final d in fallback.docs) {
        if (excludeUserId != null && d.id == excludeUserId) continue;
        final data = d.data();
        final name = (data['displayName'] ?? data['name'] ?? '').toString();
        final email = (data['email'] ?? '').toString();
        final photoUrl = _photoUrlFromUserData(data);
        if (name.isEmpty) continue;
        if (name.toLowerCase().contains(lower) ||
            email.toLowerCase().contains(lower)) {
          filtered.add({
            'uid': d.id,
            'displayName': name,
            'photoUrl': photoUrl,
          });
        }
      }
      return filtered.take(20).toList();
    } catch (e) {
      debugPrint('MessagingService.searchUsers failed: $e');
      return <Map<String, String>>[];
    }
  }

  // ── Unread count across all conversations ───────────────────────────────
  Stream<int> totalUnreadStream(String userId) {
    if (_useDemoData) {
      return Stream<int>.multi((listener) {
        listener.add(_demoUnreadTotal(userId));
        final sub = _demoConversationController.stream.listen(
          (_) => listener.add(_demoUnreadTotal(userId)),
        );
        listener.onCancel = sub.cancel;
      }).asBroadcastStream();
    }

    if (_totalUnreadStream != null && _totalUnreadUserId == userId) {
      return _totalUnreadStream!;
    }

    final stream = _db
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snap) {
          int total = 0;
          for (final doc in snap.docs) {
            final unread = doc.data()['unreadCounts'] as Map<String, dynamic>?;
            if (unread != null && unread.containsKey(userId)) {
              total += (unread[userId] as int? ?? 0);
            }
          }
          return total;
        })
        .handleError((_) => 0)
        .asBroadcastStream();

    _totalUnreadUserId = userId;
    _totalUnreadStream = stream;
    return stream;
  }

  // ── Delete conversation ─────────────────────────────────────────────────
  Future<void> deleteConversation(String conversationId) async {
    if (_useDemoData || conversationId.startsWith('demo_')) {
      _demoDeletedConversationIds.add(conversationId);
      _demoConversationOverrides.remove(conversationId);
      _demoLocalMessages.remove(conversationId);
      _emitDemoMessageUpdate(conversationId);
      notifyListeners();
      return;
    }

    // Delete all messages first
    final messages = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .get();

    final batch = _db.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('conversations').doc(conversationId));
    await batch.commit();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TYPING INDICATORS — Firestore presence field on conversation doc
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> setTyping(String conversationId, String userId) async {
    if (_useDemoData || conversationId.startsWith('demo_')) {
      return;
    }
    await _db.collection('conversations').doc(conversationId).update({
      'typingUsers.$userId': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> clearTyping(String conversationId, String userId) async {
    if (_useDemoData || conversationId.startsWith('demo_')) {
      return;
    }
    await _db.collection('conversations').doc(conversationId).update({
      'typingUsers.$userId': FieldValue.delete(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE REACTIONS — emoji reactions per message
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> addReaction(
    String conversationId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': emoji});
  }

  Future<void> removeReaction(
    String conversationId,
    String messageId,
    String userId,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': FieldValue.delete()});
  }

  // ═══════════════════════════════════════════════════════════════════════
  // READ RECEIPTS — mark delivered + read timestamps
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> markMessageDelivered(
    String conversationId,
    String messageId,
  ) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'deliveredAt': Timestamp.fromDate(DateTime.now()),
          'status': 'delivered',
        });
  }

  Future<void> markMessageRead(String conversationId, String messageId) async {
    await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
          'read': true,
          'readAt': Timestamp.fromDate(DateTime.now()),
          'status': 'read',
        });
  }

  Future<void> markAllMessagesRead(String conversationId, String userId) async {
    final unread = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    final now = Timestamp.fromDate(DateTime.now());
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': now,
        'status': 'read',
      });
    }
    batch.update(_db.collection('conversations').doc(conversationId), {
      'unreadCounts.$userId': 0,
    });
    await batch.commit();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GROUP CHAT — create and manage group conversations
  // ═══════════════════════════════════════════════════════════════════════
  Future<String> createGroupConversation({
    required String creatorId,
    required String creatorName,
    required String groupName,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    Map<String, String> memberPhotoUrls = const {},
    String creatorPhotoUrl = '',
  }) async {
    final allParticipants = [creatorId, ...memberIds];
    final allNames = {creatorId: creatorName, ...memberNames};
    final allPhotos = {creatorId: creatorPhotoUrl, ...memberPhotoUrls};

    final ref = _db.collection('conversations').doc();
    final now = DateTime.now();
    final conv = Conversation(
      id: ref.id,
      participants: allParticipants,
      participantNames: allNames,
      participantPhotoUrls: allPhotos,
      createdAt: now,
      isGroup: true,
      groupName: groupName,
      lastMessage: '$creatorName created the group',
      lastMessageAt: now,
      lastSenderId: creatorId,
    );
    await ref.set(conv.toFirestore());
    return ref.id;
  }

  Future<void> addGroupMember(
    String conversationId,
    String userId,
    String userName,
    String photoUrl,
  ) async {
    await _db.collection('conversations').doc(conversationId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'participantNames.$userId': userName,
      'participantPhotoUrls.$userId': photoUrl,
    });
    notifyListeners();
  }

  Future<void> removeGroupMember(String conversationId, String userId) async {
    await _db.collection('conversations').doc(conversationId).update({
      'participants': FieldValue.arrayRemove([userId]),
      'participantNames.$userId': FieldValue.delete(),
      'participantPhotoUrls.$userId': FieldValue.delete(),
    });
    notifyListeners();
  }

  Future<void> updateGroupName(String conversationId, String newName) async {
    await _db.collection('conversations').doc(conversationId).update({
      'groupName': newName,
    });
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGE SEARCH — full-text search within a conversation
  // ═══════════════════════════════════════════════════════════════════════
  Future<List<Message>> searchMessages(
    String conversationId,
    String query,
  ) async {
    if (query.trim().isEmpty) return [];
    final lower = query.trim().toLowerCase();

    // Firestore doesn't support full-text search natively, so we fetch
    // recent messages and filter client-side
    final snap = await _db
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(500)
        .get();

    return snap.docs
        .map(Message.fromFirestore)
        .where((m) => m.text.toLowerCase().contains(lower))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VOICE NOTE — send a voice note message
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> sendVoiceNote({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String audioUrl,
    required int durationMs,
    String? replyToId,
    String? replyToText,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: '\u{1F3A4} Voice note',
      attachmentType: 'voice_note',
      attachmentUrl: audioUrl,
      attachmentSize: durationMs,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VIDEO MESSAGE — send a short video message
  // ═══════════════════════════════════════════════════════════════════════
  Future<void> sendVideoMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String videoUrl,
    required int durationMs,
  }) async {
    return sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      senderName: senderName,
      text: '\u{1F3AC} Video message',
      attachmentType: 'video_message',
      attachmentUrl: videoUrl,
      attachmentSize: durationMs,
    );
  }
}
