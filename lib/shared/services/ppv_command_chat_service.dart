import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV COMMAND CHAT SERVICE — Owner Live + Bot After-Hours System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Gives the DFC owner (you) FULL command over PPV live chat:
///   • Go LIVE: you type, users see owner badge, messages pinned at top
///   • After hours: bot responds using canned + smart replies
///   • Announcements: blast to all viewers instantly
///   • Polls: live vote during fights
///   • Pinned messages: sticky important messages
///   • User controls: mute, ban, VIP, mod promotion
///   • Quick replies: pre-loaded fight-specific responses
///   • Bot mode: auto-responds when owner goes offline
///   • Social links: FightPipe YouTube, DFC Instagram, DFC Facebook
///
/// Firestore structure:
///   ppv_command_chat/{roomId} — room config + owner status
///   ppv_command_chat/{roomId}/messages — chat messages
///   ppv_command_chat/{roomId}/polls — live polls
///   ppv_command_chat/{roomId}/pins — pinned messages
///   ppv_command_chat/{roomId}/bans — banned users
///   ppv_command_chat/{roomId}/bot_config — bot replies + schedule
/// ═══════════════════════════════════════════════════════════════════════════

final _fs = FirebaseFirestore.instance;

// ─── Owner Status ─────────────────────────────────────────────────────────
enum OwnerStatus { live, away, offline }

// ─── Command Message Types ────────────────────────────────────────────────
enum CommandMessageType {
  ownerMessage, // owner typing live
  botReply, // automated bot response
  announcement, // blast to all viewers
  pollStart, // live poll question
  pollResult, // poll results
  system, // join/leave/moderation
  userMessage, // normal viewer message
  pinnedMessage, // pinned at top
  socialLink, // FightPipe/IG/FB share
  fightUpdate, // round results, KO alerts
  promoBlast, // next event promo during chat
}

// ─── User Role in Chat ────────────────────────────────────────────────────
enum ChatUserRole { viewer, subscriber, vip, moderator, owner }

// ─── Social Platform ──────────────────────────────────────────────────────
enum SocialPlatform { youtube, instagram, facebook, tiktok, twitter }

// ─── Command Chat Message Model ───────────────────────────────────────────
class CommandChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final CommandMessageType type;
  final ChatUserRole role;
  final bool isPinned;
  final bool isHighlighted;
  final DateTime sentAt;
  final Map<String, int> reactions;
  final String? replyToId;
  final Map<String, dynamic>? metadata;

  const CommandChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.type,
    this.role = ChatUserRole.viewer,
    this.isPinned = false,
    this.isHighlighted = false,
    required this.sentAt,
    this.reactions = const {},
    this.replyToId,
    this.metadata,
  });

  factory CommandChatMessage.fromMap(Map<String, dynamic> m) {
    return CommandChatMessage(
      id: m['id'] ?? '',
      roomId: m['roomId'] ?? '',
      userId: m['userId'] ?? '',
      username: m['username'] ?? 'Anonymous',
      avatarUrl: m['avatarUrl'],
      content: m['content'] ?? '',
      type: CommandMessageType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => CommandMessageType.userMessage,
      ),
      role: ChatUserRole.values.firstWhere(
        (r) => r.name == m['role'],
        orElse: () => ChatUserRole.viewer,
      ),
      isPinned: m['isPinned'] ?? false,
      isHighlighted: m['isHighlighted'] ?? false,
      sentAt: (m['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: Map<String, int>.from(m['reactions'] ?? {}),
      replyToId: m['replyToId'],
      metadata: m['metadata'],
    );
  }

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'userId': userId,
    'username': username,
    'avatarUrl': avatarUrl,
    'content': content,
    'type': type.name,
    'role': role.name,
    'isPinned': isPinned,
    'isHighlighted': isHighlighted,
    'sentAt': FieldValue.serverTimestamp(),
    'reactions': reactions,
    'replyToId': replyToId,
    'metadata': metadata,
  };

  bool get isOwner => role == ChatUserRole.owner;
  bool get isMod => role == ChatUserRole.moderator || isOwner;
  bool get isBot => type == CommandMessageType.botReply;
}

// ─── Live Poll Model ──────────────────────────────────────────────────────
class LivePoll {
  final String id;
  final String roomId;
  final String question;
  final List<String> options;
  final Map<String, int> votes;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  const LivePoll({
    required this.id,
    required this.roomId,
    required this.question,
    required this.options,
    this.votes = const {},
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory LivePoll.fromMap(Map<String, dynamic> m) => LivePoll(
    id: m['id'] ?? '',
    roomId: m['roomId'] ?? '',
    question: m['question'] ?? '',
    options: List<String>.from(m['options'] ?? []),
    votes: Map<String, int>.from(m['votes'] ?? {}),
    createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    expiresAt: (m['expiresAt'] as Timestamp?)?.toDate(),
    isActive: m['isActive'] ?? true,
  );

  int get totalVotes => votes.values.fold(0, (a, b) => a + b);
}

// ─── Bot Auto-Reply Rule ──────────────────────────────────────────────────
class BotAutoReply {
  final String id;
  final List<String> triggers; // keywords that activate this reply
  final String response;
  final bool isEnabled;
  final int priority; // higher = checked first

  const BotAutoReply({
    required this.id,
    required this.triggers,
    required this.response,
    this.isEnabled = true,
    this.priority = 0,
  });

  factory BotAutoReply.fromMap(Map<String, dynamic> m) => BotAutoReply(
    id: m['id'] ?? '',
    triggers: List<String>.from(m['triggers'] ?? []),
    response: m['response'] ?? '',
    isEnabled: m['isEnabled'] ?? true,
    priority: m['priority'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'triggers': triggers,
    'response': response,
    'isEnabled': isEnabled,
    'priority': priority,
  };
}

// ─── Social Links Registry ────────────────────────────────────────────────
class DFCSocialLinks {
  static const String fightPipeYouTube = 'https://www.youtube.com/@FightPipe';
  static const String dfcInstagram =
      'https://www.instagram.com/datafightcentral';
  static const String dfcFacebook = 'https://www.facebook.com/datafightcentral';
  static const String dfcTikTok = 'https://www.tiktok.com/@datafightcentral';
  static const String dfcTwitter = 'https://twitter.com/datafightcentrl';

  static String getLink(SocialPlatform platform) => switch (platform) {
    SocialPlatform.youtube => fightPipeYouTube,
    SocialPlatform.instagram => dfcInstagram,
    SocialPlatform.facebook => dfcFacebook,
    SocialPlatform.tiktok => dfcTikTok,
    SocialPlatform.twitter => dfcTwitter,
  };

  static String getLabel(SocialPlatform platform) => switch (platform) {
    SocialPlatform.youtube => 'FightPipe YouTube',
    SocialPlatform.instagram => 'DFC Instagram',
    SocialPlatform.facebook => 'DFC Facebook',
    SocialPlatform.tiktok => 'DFC TikTok',
    SocialPlatform.twitter => 'DFC Twitter',
  };
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV COMMAND CHAT SERVICE — The Nerve Center
/// ═══════════════════════════════════════════════════════════════════════════
class PPVCommandChatService with ChangeNotifier {
  static final PPVCommandChatService _i = PPVCommandChatService._();
  factory PPVCommandChatService() => _i;
  PPVCommandChatService._();

  Future<String?> _resolvePpvRoomId(String ppvId) async {
    try {
      final existingRoom = await _fs
          .collection('ppv_command_chat')
          .doc(ppvId)
          .get();
      if (existingRoom.exists) {
        return existingRoom.id;
      }

      final directPpvDoc = await _fs.collection('ppv_events').doc(ppvId).get();
      if (directPpvDoc.exists) {
        return directPpvDoc.id;
      }

      final eventIdSnapshot = await _fs
          .collection('ppv_events')
          .where('eventId', isEqualTo: ppvId)
          .limit(1)
          .get();
      if (eventIdSnapshot.docs.isNotEmpty) {
        return eventIdSnapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('CommandChat: resolve room failed: $e');
    }

    return ppvId.isEmpty ? null : ppvId;
  }

  // ─── State ────────────────────────────────────────────────────────────
  StreamSubscription<QuerySnapshot>? _msgSub;
  StreamSubscription<DocumentSnapshot>? _roomSub;
  final List<CommandChatMessage> _messages = [];
  final List<CommandChatMessage> _pinnedMessages = [];
  final List<BotAutoReply> _botReplies = [];
  LivePoll? _activePoll;
  String? _currentRoomId;
  OwnerStatus _ownerStatus = OwnerStatus.offline;
  int _activeViewers = 0;
  bool _botModeActive = false;

  // ─── Getters ──────────────────────────────────────────────────────────
  List<CommandChatMessage> get messages => List.unmodifiable(_messages);
  List<CommandChatMessage> get pinnedMessages =>
      List.unmodifiable(_pinnedMessages);
  LivePoll? get activePoll => _activePoll;
  OwnerStatus get ownerStatus => _ownerStatus;
  int get activeViewers => _activeViewers;
  bool get botModeActive => _botModeActive;
  bool get isOwnerLive => _ownerStatus == OwnerStatus.live;
  String? get currentRoomId => _currentRoomId;

  // ═══════════════════════════════════════════════════════════════════════
  // ROOM LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════

  /// Create or join a command chat room for a PPV event
  Future<void> openRoom(String ppvId) async {
    await closeRoom();
    final roomId = await _resolvePpvRoomId(ppvId);
    if (roomId == null || roomId.isEmpty) {
      debugPrint('🎙️ CommandChat: Could not resolve room for $ppvId');
      return;
    }

    _currentRoomId = roomId;
    debugPrint('🎙️ CommandChat: Opening room $roomId (source: $ppvId)');

    try {
      // Ensure room doc exists
      final roomRef = _fs.collection('ppv_command_chat').doc(roomId);
      final roomSnap = await roomRef.get();
      if (!roomSnap.exists) {
        await roomRef.set({
          'ppvId': roomId,
          'sourcePpvId': ppvId,
          'ownerStatus': OwnerStatus.offline.name,
          'activeViewers': 0,
          'botModeActive': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Listen to room state
      _roomSub = roomRef.snapshots().listen((snap) {
        if (!snap.exists) return;
        final d = snap.data()!;
        _ownerStatus = OwnerStatus.values.firstWhere(
          (s) => s.name == d['ownerStatus'],
          orElse: () => OwnerStatus.offline,
        );
        _activeViewers = d['activeViewers'] ?? 0;
        _botModeActive = d['botModeActive'] ?? false;
        notifyListeners();
      });

      // Listen to messages (last 200)
      _msgSub = roomRef
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(200)
          .snapshots()
          .listen((snap) {
            _messages.clear();
            _pinnedMessages.clear();
            for (final doc in snap.docs.reversed) {
              final msg = CommandChatMessage.fromMap({
                ...doc.data(),
                'id': doc.id,
              });
              _messages.add(msg);
              if (msg.isPinned) _pinnedMessages.add(msg);
            }
            notifyListeners();
          });

      // Load bot replies
      await _loadBotReplies(roomId);

      // Load active poll
      await _loadActivePoll(roomId);

      // Increment viewer count
      await roomRef.update({'activeViewers': FieldValue.increment(1)});
    } catch (e) {
      debugPrint('CommandChat: openRoom failed: $e');
    }
  }

  Future<void> closeRoom() async {
    if (_currentRoomId != null) {
      try {
        await _fs.collection('ppv_command_chat').doc(_currentRoomId).update({
          'activeViewers': FieldValue.increment(-1),
        });
      } catch (_) {}
    }
    await _msgSub?.cancel();
    await _roomSub?.cancel();
    _msgSub = null;
    _roomSub = null;
    _messages.clear();
    _pinnedMessages.clear();
    _activePoll = null;
    _currentRoomId = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OWNER COMMANDS — Full Control
  // ═══════════════════════════════════════════════════════════════════════

  /// Go LIVE — owner is now chatting directly with users
  Future<void> goLive() async {
    if (_currentRoomId == null) return;
    await _fs.collection('ppv_command_chat').doc(_currentRoomId).update({
      'ownerStatus': OwnerStatus.live.name,
      'botModeActive': false,
      'lastLiveAt': FieldValue.serverTimestamp(),
    });
    _ownerStatus = OwnerStatus.live;
    _botModeActive = false;
    notifyListeners();

    // System announcement
    await _sendSystemMessage('🔴 Owner is LIVE — ask your questions!');
  }

  /// Go AWAY — bot takes over with smart replies
  Future<void> goAway() async {
    if (_currentRoomId == null) return;
    await _fs.collection('ppv_command_chat').doc(_currentRoomId).update({
      'ownerStatus': OwnerStatus.away.name,
      'botModeActive': true,
    });
    _ownerStatus = OwnerStatus.away;
    _botModeActive = true;
    notifyListeners();

    await _sendSystemMessage(
      '🤖 Owner is away — DFC Bot is handling questions. '
      'Replies may be automated.',
    );
  }

  /// Go OFFLINE — bot stays on duty
  Future<void> goOffline() async {
    if (_currentRoomId == null) return;
    await _fs.collection('ppv_command_chat').doc(_currentRoomId).update({
      'ownerStatus': OwnerStatus.offline.name,
      'botModeActive': true,
    });
    _ownerStatus = OwnerStatus.offline;
    _botModeActive = true;
    notifyListeners();
  }

  /// Owner sends a message with OWNER badge
  Future<void> sendOwnerMessage({
    required String userId,
    required String username,
    required String content,
    String? avatarUrl,
    String? replyToId,
  }) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add(
          CommandChatMessage(
            id: '',
            roomId: _currentRoomId!,
            userId: userId,
            username: username,
            avatarUrl: avatarUrl,
            content: content,
            type: CommandMessageType.ownerMessage,
            role: ChatUserRole.owner,
            sentAt: DateTime.now(),
            replyToId: replyToId,
          ).toMap(),
        );
  }

  /// Blast announcement to ALL viewers
  Future<void> sendAnnouncement(String content) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add({
          'roomId': _currentRoomId,
          'userId': 'system',
          'username': 'DFC ANNOUNCEMENT',
          'content': content,
          'type': CommandMessageType.announcement.name,
          'role': ChatUserRole.owner.name,
          'isPinned': true,
          'isHighlighted': true,
          'sentAt': FieldValue.serverTimestamp(),
          'reactions': {},
        });
  }

  /// Send fight update (round results, KO, decision)
  Future<void> sendFightUpdate(String content) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add({
          'roomId': _currentRoomId,
          'userId': 'system',
          'username': 'FIGHT UPDATE',
          'content': content,
          'type': CommandMessageType.fightUpdate.name,
          'role': ChatUserRole.owner.name,
          'isPinned': false,
          'isHighlighted': true,
          'sentAt': FieldValue.serverTimestamp(),
          'reactions': {},
        });
  }

  /// Promo blast — push next event during live chat
  Future<void> sendPromoBlast({
    required String eventName,
    required String eventDate,
    required String ticketUrl,
  }) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add({
          'roomId': _currentRoomId,
          'userId': 'system',
          'username': 'DFC PROMO',
          'content':
              '🎫 NEXT UP: $eventName — $eventDate\n'
              'Get tickets now!',
          'type': CommandMessageType.promoBlast.name,
          'role': ChatUserRole.owner.name,
          'isPinned': false,
          'isHighlighted': true,
          'sentAt': FieldValue.serverTimestamp(),
          'reactions': {},
          'metadata': {'ticketUrl': ticketUrl, 'eventName': eventName},
        });
  }

  /// Share social link in chat
  Future<void> shareSocialLink(SocialPlatform platform) async {
    if (_currentRoomId == null) return;
    final label = DFCSocialLinks.getLabel(platform);
    final url = DFCSocialLinks.getLink(platform);
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add({
          'roomId': _currentRoomId,
          'userId': 'system',
          'username': 'DFC',
          'content': '📱 Follow us on $label\n$url',
          'type': CommandMessageType.socialLink.name,
          'role': ChatUserRole.owner.name,
          'isPinned': false,
          'isHighlighted': false,
          'sentAt': FieldValue.serverTimestamp(),
          'reactions': {},
          'metadata': {'platform': platform.name, 'url': url},
        });
  }

  /// Pin a message to the top
  Future<void> pinMessage(String messageId) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': true});
  }

  /// Unpin a message
  Future<void> unpinMessage(String messageId) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .doc(messageId)
        .update({'isPinned': false});
  }

  // ═══════════════════════════════════════════════════════════════════════
  // USER CONTROLS — Mute, Ban, VIP, Mod
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> muteUser(String userId, {int minutes = 10}) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('bans')
        .doc(userId)
        .set({
          'userId': userId,
          'type': 'mute',
          'expiresAt': Timestamp.fromDate(
            DateTime.now().add(Duration(minutes: minutes)),
          ),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> banUser(String userId, {String reason = ''}) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('bans')
        .doc(userId)
        .set({
          'userId': userId,
          'type': 'ban',
          'reason': reason,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> unbanUser(String userId) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('bans')
        .doc(userId)
        .delete();
  }

  Future<void> promoteToMod(String userId) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('mods')
        .doc(userId)
        .set({'userId': userId, 'promotedAt': FieldValue.serverTimestamp()});
  }

  Future<void> grantVIP(String userId) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('vips')
        .doc(userId)
        .set({'userId': userId, 'grantedAt': FieldValue.serverTimestamp()});
  }

  Future<bool> isUserBanned(String userId) async {
    if (_currentRoomId == null) return false;
    final doc = await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('bans')
        .doc(userId)
        .get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    if (data['type'] == 'ban') return true;
    // Check mute expiry
    final expires = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expires != null && DateTime.now().isAfter(expires)) {
      await doc.reference.delete();
      return false;
    }
    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VIEWER MESSAGING — Normal users
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> sendViewerMessage({
    required String userId,
    required String username,
    required String content,
    String? avatarUrl,
    String? replyToId,
  }) async {
    if (_currentRoomId == null) return false;

    // Check ban status
    if (await isUserBanned(userId)) return false;

    // Basic content length check
    if (content.trim().isEmpty || content.length > 500) return false;

    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add(
          CommandChatMessage(
            id: '',
            roomId: _currentRoomId!,
            userId: userId,
            username: username,
            avatarUrl: avatarUrl,
            content: content.trim(),
            type: CommandMessageType.userMessage,
            sentAt: DateTime.now(),
            replyToId: replyToId,
          ).toMap(),
        );

    // If bot mode active, check for auto-reply
    if (_botModeActive) {
      await _checkBotReply(content);
    }

    return true;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LIVE POLLS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> createPoll({
    required String question,
    required List<String> options,
    int durationMinutes = 5,
  }) async {
    if (_currentRoomId == null) return;

    // Close any existing poll
    await closePoll();

    final pollRef = _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('polls')
        .doc();

    final initialVotes = <String, int>{};
    for (int i = 0; i < options.length; i++) {
      initialVotes['option_$i'] = 0;
    }

    await pollRef.set({
      'roomId': _currentRoomId,
      'question': question,
      'options': options,
      'votes': initialVotes,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: durationMinutes)),
      ),
    });

    _activePoll = LivePoll(
      id: pollRef.id,
      roomId: _currentRoomId!,
      question: question,
      options: options,
      votes: initialVotes,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(minutes: durationMinutes)),
    );
    notifyListeners();

    // Announce poll in chat
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add({
          'roomId': _currentRoomId,
          'userId': 'system',
          'username': 'LIVE POLL',
          'content':
              '📊 $question\n'
              '${options.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}\n\n'
              'Vote now! ⏰ ${durationMinutes}min',
          'type': CommandMessageType.pollStart.name,
          'role': ChatUserRole.owner.name,
          'isPinned': true,
          'isHighlighted': true,
          'sentAt': FieldValue.serverTimestamp(),
          'reactions': {},
          'metadata': {'pollId': pollRef.id},
        });
  }

  Future<void> votePoll(String optionKey, String voterId) async {
    if (_currentRoomId == null || _activePoll == null) return;
    // Check if already voted (one vote per user)
    final voteRef = _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('polls')
        .doc(_activePoll!.id)
        .collection('voters')
        .doc(voterId);
    final existing = await voteRef.get();
    if (existing.exists) return; // Already voted

    await voteRef.set({'votedAt': FieldValue.serverTimestamp()});
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('polls')
        .doc(_activePoll!.id)
        .update({'votes.$optionKey': FieldValue.increment(1)});
  }

  Future<void> closePoll() async {
    if (_currentRoomId == null || _activePoll == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('polls')
        .doc(_activePoll!.id)
        .update({'isActive': false});
    _activePoll = null;
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BOT SYSTEM — After Hours Auto-Responder
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _loadBotReplies(String roomId) async {
    try {
      final snap = await _fs
          .collection('ppv_command_chat')
          .doc(roomId)
          .collection('bot_config')
          .orderBy('priority', descending: true)
          .get();
      _botReplies.clear();
      for (final doc in snap.docs) {
        _botReplies.add(BotAutoReply.fromMap({...doc.data(), 'id': doc.id}));
      }
    } catch (e) {
      debugPrint('CommandChat: _loadBotReplies failed: $e');
      // Seed default replies if none exist
      await _seedDefaultBotReplies(roomId);
    }
  }

  Future<void> _seedDefaultBotReplies(String roomId) async {
    final defaults = [
      const BotAutoReply(
        id: 'welcome',
        triggers: ['hello', 'hi', 'hey', 'sup', 'gday', "g'day"],
        response:
            "G'day! Welcome to DFC PPV Chat 🥊 "
            "The owner is currently offline but I'm here to help. "
            "Ask about upcoming events, fight cards, or how to purchase PPV!",
        priority: 100,
      ),
      const BotAutoReply(
        id: 'schedule',
        triggers: ['next event', 'schedule', 'upcoming', 'when', 'next fight'],
        response:
            '📅 Check our upcoming events at the PPV Hub! '
            'We cover MMA, Boxing, BKFC, Kickboxing, Muay Thai, '
            'and every fight show from Aussie & Kiwi local cards '
            'to major international events. No bias — every fighter counts.',
        priority: 90,
      ),
      const BotAutoReply(
        id: 'buy',
        triggers: ['buy', 'purchase', 'price', 'cost', 'ticket', 'ppv'],
        response:
            '🎫 Head to the PPV Store to grab your pass! '
            'We offer Standard, Early Bird, Premium & VIP tiers. '
            'Fight Pass subscribers get priority access + discounts.',
        priority: 85,
      ),
      const BotAutoReply(
        id: 'social',
        triggers: ['youtube', 'instagram', 'social', 'follow', 'subscribe'],
        response:
            '📱 Follow DFC everywhere!\n'
            '🎬 YouTube: FightPipe Channel\n'
            '📸 Instagram: @datafightcentral\n'
            '📘 Facebook: Data Fight Central\n'
            'Hit subscribe — we cover EVERY fight show.',
        priority: 80,
      ),
      const BotAutoReply(
        id: 'fighter',
        triggers: ['fighter', 'sign up', 'register', 'join', 'profile'],
        response:
            '🥊 Want to get on DFC? Create a fighter profile, '
            'link your record, and connect with promoters worldwide. '
            "We don't judge by promotion size — from local Aussie shows "
            'to global PPV cards, everyone gets a platform here.',
        priority: 75,
      ),
      const BotAutoReply(
        id: 'promoter',
        triggers: ['promote', 'promoter', 'host event', 'run show'],
        response:
            '🏟️ Promoters — create your event on DFC, '
            'set pricing tiers, sell PPV worldwide. '
            'Sliding agreement: you start at 70% revenue, DFC takes 30%. '
            'As exposure grows, the DFC cut slides up smoothly to 50% max. '
            'No hard tier jumps — fair, transparent, performance-based. '
            'We handle streaming, payments, international marketing, '
            'and the entire production pipeline.',
        priority: 70,
      ),
      const BotAutoReply(
        id: 'sports',
        triggers: [
          'mma',
          'boxing',
          'bkfc',
          'bare knuckle',
          'kickboxing',
          'muay thai',
          'wrestling',
          'karate',
          'jiu jitsu',
          'bjj',
          'taekwondo',
          'judo',
          'sambo',
          'sanda',
          'lethwei',
        ],
        response:
            '🌏 DFC covers ALL combat sports worldwide:\n'
            'MMA • Boxing • BKFC • Kickboxing • Muay Thai • '
            'Wrestling • BJJ • Karate • Judo • Taekwondo • '
            'Sanda • Lethwei • Sambo • and more.\n'
            'No bias. No gatekeeping. Every fighter deserves a stage.',
        priority: 65,
      ),
      const BotAutoReply(
        id: 'aussie',
        triggers: [
          'aussie',
          'australia',
          'kiwi',
          'new zealand',
          'nz',
          'hex',
          'eternal',
          'afc',
          'dan hooker',
        ],
        response:
            '🇦🇺🇳🇿 Aussie & Kiwi combat sports is our heartbeat! '
            'We promote local shows globally — HEX, Eternal MMA, '
            'AFC, and independent cards across Australia & New Zealand. '
            'From the Gold Coast to Auckland, DFC puts ANZAC fighters on the world stage.',
        priority: 60,
      ),
    ];

    final batch = _fs.batch();
    for (final reply in defaults) {
      batch.set(
        _fs
            .collection('ppv_command_chat')
            .doc(roomId)
            .collection('bot_config')
            .doc(reply.id),
        reply.toMap(),
      );
    }
    await batch.commit();
    _botReplies
      ..clear()
      ..addAll(defaults);
  }

  Future<void> _checkBotReply(String userMessage) async {
    if (_currentRoomId == null || !_botModeActive) return;
    final lower = userMessage.toLowerCase();

    for (final rule in _botReplies) {
      if (!rule.isEnabled) continue;
      final matched = rule.triggers.any((t) => lower.contains(t.toLowerCase()));
      if (matched) {
        // Slight delay to feel natural
        await Future.delayed(const Duration(milliseconds: 800));
        await _fs
            .collection('ppv_command_chat')
            .doc(_currentRoomId)
            .collection('messages')
            .add({
              'roomId': _currentRoomId,
              'userId': 'dfc_bot',
              'username': 'DFC Bot',
              'content': rule.response,
              'type': CommandMessageType.botReply.name,
              'role': ChatUserRole.owner.name,
              'isPinned': false,
              'isHighlighted': false,
              'sentAt': FieldValue.serverTimestamp(),
              'reactions': {},
            });
        return; // First match wins
      }
    }
  }

  /// Add/update a custom bot reply
  Future<void> saveBotReply(BotAutoReply reply) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('bot_config')
        .doc(reply.id)
        .set(reply.toMap());
    await _loadBotReplies(_currentRoomId!);
  }

  /// Delete a bot reply
  Future<void> deleteBotReply(String replyId) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('bot_config')
        .doc(replyId)
        .delete();
    _botReplies.removeWhere((r) => r.id == replyId);
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUICK REPLIES — Pre-loaded fight responses
  // ═══════════════════════════════════════════════════════════════════════

  static const List<String> quickRepliesFight = [
    '🔥 What a round!',
    '💀 That was BRUTAL!',
    '🏆 Championship level!',
    '⚡ The pace is insane!',
    '🥊 War!',
    '🇦🇺 Aussie pride!',
    '🇳🇿 Kiwi strength!',
    '📊 Scorecard check — who you got?',
    '🎯 Head movement on point',
    '💪 Heart of a champion',
  ];

  static const List<String> quickRepliesPromo = [
    '🎫 Grab your PPV pass in the store!',
    '📱 Follow FightPipe on YouTube for highlights!',
    '🔔 Turn on notifications for the next event!',
    '💰 Early bird pricing ends soon!',
    '🌏 DFC — Every fight show, every sport, no bias.',
  ];

  // ═══════════════════════════════════════════════════════════════════════
  // ANALYTICS — Chat stats for the owner
  // ═══════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getRoomStats() async {
    if (_currentRoomId == null) return {};
    try {
      final msgCount = await _fs
          .collection('ppv_command_chat')
          .doc(_currentRoomId)
          .collection('messages')
          .count()
          .get();

      final uniqueUsers = <String>{};
      final recent = await _fs
          .collection('ppv_command_chat')
          .doc(_currentRoomId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(500)
          .get();
      for (final doc in recent.docs) {
        uniqueUsers.add(doc.data()['userId'] ?? '');
      }

      return {
        'totalMessages': msgCount.count ?? 0,
        'uniqueUsers': uniqueUsers.length,
        'activeViewers': _activeViewers,
        'pinnedCount': _pinnedMessages.length,
        'botReplies': _botReplies.length,
        'hasPoll': _activePoll != null,
      };
    } catch (e) {
      return {};
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────

  Future<void> _sendSystemMessage(String content) async {
    if (_currentRoomId == null) return;
    await _fs
        .collection('ppv_command_chat')
        .doc(_currentRoomId)
        .collection('messages')
        .add({
          'roomId': _currentRoomId,
          'userId': 'system',
          'username': 'SYSTEM',
          'content': content,
          'type': CommandMessageType.system.name,
          'role': ChatUserRole.owner.name,
          'isPinned': false,
          'isHighlighted': false,
          'sentAt': FieldValue.serverTimestamp(),
          'reactions': {},
        });
  }

  Future<void> _loadActivePoll(String roomId) async {
    try {
      final snap = await _fs
          .collection('ppv_command_chat')
          .doc(roomId)
          .collection('polls')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        _activePoll = LivePoll.fromMap({
          ...snap.docs.first.data(),
          'id': snap.docs.first.id,
        });
      }
    } catch (e) {
      debugPrint('CommandChat: _loadActivePoll failed: $e');
    }
  }

  @override
  void dispose() {
    closeRoom();
    super.dispose();
  }
}
