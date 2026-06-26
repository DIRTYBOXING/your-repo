import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

/// Watch party member state.
class PartyMember {
  final String odid;
  final String displayName;
  final String? avatarUrl;
  final bool isHost;
  final bool isReady;

  const PartyMember({
    required this.odid,
    required this.displayName,
    this.avatarUrl,
    this.isHost = false,
    this.isReady = false,
  });

  factory PartyMember.fromMap(Map<String, dynamic> map) => PartyMember(
    odid: map['uid'] ?? '',
    displayName: map['displayName'] ?? 'Fighter',
    avatarUrl: map['avatarUrl'],
    isHost: map['isHost'] ?? false,
    isReady: map['isReady'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'uid': odid,
    'displayName': displayName,
    'avatarUrl': avatarUrl,
    'isHost': isHost,
    'isReady': isReady,
  };
}

/// A chat message in the watch party.
class PartyMessage {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String? reaction; // fire, ko, champ, skull

  const PartyMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.reaction,
  });

  factory PartyMessage.fromMap(Map<String, dynamic> map) => PartyMessage(
    senderId: map['senderId'] ?? '',
    senderName: map['senderName'] ?? '',
    text: map['text'] ?? '',
    timestamp: map['timestamp'] is Timestamp
        ? (map['timestamp'] as Timestamp).toDate()
        : DateTime.now(),
    reaction: map['reaction'],
  );

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'senderName': senderName,
    'text': text,
    'timestamp': FieldValue.serverTimestamp(),
    'reaction': reaction,
  };
}

/// Watch party state.
enum PartyState { idle, creating, waiting, syncing, watching, ended }

/// Synchronized watch party — watch fights together with friends.
/// Real-time sync via Firestore, chat + reactions overlay.
/// This is the social differentiator that Paramount+/DAZN/TrillerTV don't have.
class WatchPartyService extends ChangeNotifier {
  static final WatchPartyService _instance = WatchPartyService._internal();
  factory WatchPartyService() => _instance;
  WatchPartyService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();

  // ── State ─────────────────────────────────────────────────────────────
  PartyState _state = PartyState.idle;
  String? _partyId;
  String? _eventId;
  String? _eventTitle;
  String? _streamUrl;
  bool _isHost = false;
  final List<PartyMember> _members = [];
  final List<PartyMessage> _messages = [];
  Duration _syncPosition = Duration.zero;
  bool _hostIsPlaying = false;

  StreamSubscription? _membersSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _syncSub;

  // ── Getters ───────────────────────────────────────────────────────────
  PartyState get state => _state;
  String? get partyId => _partyId;
  String? get eventId => _eventId;
  String? get eventTitle => _eventTitle;
  String? get streamUrl => _streamUrl;
  bool get isHost => _isHost;
  List<PartyMember> get members => List.unmodifiable(_members);
  List<PartyMessage> get messages => List.unmodifiable(_messages);
  Duration get syncPosition => _syncPosition;
  bool get hostIsPlaying => _hostIsPlaying;
  int get memberCount => _members.length;

  /// Shareable join code (first 8 chars of party ID).
  String? get joinCode => _partyId?.substring(0, 8).toUpperCase();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Fighter';
  String? get _avatarUrl => FirebaseAuth.instance.currentUser?.photoURL;

  // ── Party Lifecycle ───────────────────────────────────────────────────

  /// Create a new watch party as host.
  Future<String?> createParty({
    required String eventId,
    required String eventTitle,
    required String streamUrl,
  }) async {
    final uid = _uid;
    if (uid == null) return null;

    _state = PartyState.creating;
    notifyListeners();

    final id = _uuid.v4();
    _partyId = id;
    _eventId = eventId;
    _eventTitle = eventTitle;
    _streamUrl = streamUrl;
    _isHost = true;

    // Create party document in Firestore
    await _firestore.collection('watch_parties').doc(id).set({
      'eventId': eventId,
      'eventTitle': eventTitle,
      'streamUrl': streamUrl,
      'hostUid': uid,
      'hostName': _displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'syncPosition': 0,
      'isPlaying': false,
    });

    // Add host as member
    await _firestore
        .collection('watch_parties')
        .doc(id)
        .collection('members')
        .doc(uid)
        .set(
          PartyMember(
            odid: uid,
            displayName: _displayName,
            avatarUrl: _avatarUrl,
            isHost: true,
            isReady: true,
          ).toMap(),
        );

    // Start listening
    _listenToParty(id);

    _state = PartyState.waiting;
    notifyListeners();
    return id;
  }

  /// Join an existing watch party by code or ID.
  Future<bool> joinParty(String codeOrId) async {
    final uid = _uid;
    if (uid == null) return false;

    // Try to find party by code (first 8 chars) or full ID
    final partyQuery = await _firestore
        .collection('watch_parties')
        .where('isActive', isEqualTo: true)
        .get();

    DocumentSnapshot? partyDoc;
    for (final doc in partyQuery.docs) {
      if (doc.id == codeOrId ||
          doc.id.substring(0, 8).toUpperCase() == codeOrId.toUpperCase()) {
        partyDoc = doc;
        break;
      }
    }

    if (partyDoc == null || !partyDoc.exists) return false;

    final data = partyDoc.data() as Map<String, dynamic>;
    _partyId = partyDoc.id;
    _eventId = data['eventId'];
    _eventTitle = data['eventTitle'];
    _streamUrl = data['streamUrl'];
    _isHost = false;

    // Add self as member
    await _firestore
        .collection('watch_parties')
        .doc(_partyId)
        .collection('members')
        .doc(uid)
        .set(
          PartyMember(
            odid: uid,
            displayName: _displayName,
            avatarUrl: _avatarUrl,
          ).toMap(),
        );

    _listenToParty(_partyId!);

    _state = PartyState.waiting;
    notifyListeners();
    return true;
  }

  /// Mark self as ready.
  Future<void> setReady(bool ready) async {
    final uid = _uid;
    if (uid == null || _partyId == null) return;

    await _firestore
        .collection('watch_parties')
        .doc(_partyId)
        .collection('members')
        .doc(uid)
        .update({'isReady': ready});
  }

  /// Host starts playback (syncs all members).
  Future<void> startWatching() async {
    if (!_isHost || _partyId == null) return;

    await _firestore.collection('watch_parties').doc(_partyId).update({
      'isPlaying': true,
      'syncPosition': 0,
      'startedAt': FieldValue.serverTimestamp(),
    });

    _state = PartyState.watching;
    notifyListeners();
  }

  /// Host syncs playback position.
  Future<void> pushSyncPosition(Duration position, bool isPlaying) async {
    if (!_isHost || _partyId == null) return;

    await _firestore.collection('watch_parties').doc(_partyId).update({
      'syncPosition': position.inMilliseconds,
      'isPlaying': isPlaying,
    });
  }

  // ── Chat ──────────────────────────────────────────────────────────────

  /// Send a chat message to the watch party.
  Future<void> sendMessage(String text) async {
    final uid = _uid;
    if (uid == null || _partyId == null || text.trim().isEmpty) return;

    await _firestore
        .collection('watch_parties')
        .doc(_partyId)
        .collection('chat')
        .add(
          PartyMessage(
            senderId: uid,
            senderName: _displayName,
            text: text.trim(),
            timestamp: DateTime.now(),
          ).toMap(),
        );
  }

  /// Send a reaction (fire, ko, champ, skull).
  Future<void> sendReaction(String reaction) async {
    final uid = _uid;
    if (uid == null || _partyId == null) return;

    await _firestore
        .collection('watch_parties')
        .doc(_partyId)
        .collection('chat')
        .add(
          PartyMessage(
            senderId: uid,
            senderName: _displayName,
            text: '',
            timestamp: DateTime.now(),
            reaction: reaction,
          ).toMap(),
        );
  }

  // ── Real-time Listeners ───────────────────────────────────────────────

  void _listenToParty(String partyId) {
    // Members
    _membersSub = _firestore
        .collection('watch_parties')
        .doc(partyId)
        .collection('members')
        .snapshots()
        .listen((snap) {
          _members.clear();
          for (final doc in snap.docs) {
            _members.add(PartyMember.fromMap(doc.data()));
          }
          notifyListeners();
        });

    // Chat
    _chatSub = _firestore
        .collection('watch_parties')
        .doc(partyId)
        .collection('chat')
        .orderBy('timestamp', descending: false)
        .limitToLast(100)
        .snapshots()
        .listen((snap) {
          _messages.clear();
          for (final doc in snap.docs) {
            _messages.add(PartyMessage.fromMap(doc.data()));
          }
          notifyListeners();
        });

    // Sync position (guests follow host)
    if (!_isHost) {
      _syncSub = _firestore
          .collection('watch_parties')
          .doc(partyId)
          .snapshots()
          .listen((snap) {
            final data = snap.data();
            if (data == null) return;
            _syncPosition = Duration(milliseconds: data['syncPosition'] ?? 0);
            _hostIsPlaying = data['isPlaying'] ?? false;

            if (_hostIsPlaying && _state != PartyState.watching) {
              _state = PartyState.watching;
            }
            notifyListeners();
          });
    }
  }

  // ── Leave / End ───────────────────────────────────────────────────────

  /// Leave the watch party.
  Future<void> leaveParty() async {
    final uid = _uid;

    if (_partyId != null && uid != null) {
      await _firestore
          .collection('watch_parties')
          .doc(_partyId)
          .collection('members')
          .doc(uid)
          .delete()
          .catchError((_) {});

      // If host, mark party as ended
      if (_isHost) {
        await _firestore
            .collection('watch_parties')
            .doc(_partyId)
            .update({'isActive': false})
            .catchError((_) {});
      }
    }

    _cleanup();
  }

  void _cleanup() {
    _membersSub?.cancel();
    _chatSub?.cancel();
    _syncSub?.cancel();
    _members.clear();
    _messages.clear();
    _partyId = null;
    _eventId = null;
    _eventTitle = null;
    _streamUrl = null;
    _isHost = false;
    _state = PartyState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _membersSub?.cancel();
    _chatSub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }
}
