import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// VIDEO STREAMING SERVICE — PPV Delivery, YouTube, HLS, RTMP Integration
/// ═══════════════════════════════════════════════════════════════════════════

final _firestore = FirebaseFirestore.instance;
final _functions = FirebaseFunctions.instanceFor(
  region: 'australia-southeast1',
);

enum StreamType { youtube, hls, rtmp, dash, webrtc }

enum StreamQuality { auto, sd480, hd720, hd1080, uhd4k }

enum StreamStatus { scheduled, live, ended, vod, error }

enum PPVAccessLevel { none, preview, purchased, vip, promoter }

class LiveStream {
  final String id;
  final String title;
  final String description;
  final StreamType type;
  final StreamStatus status;
  final String streamUrl;
  final String? hlsUrl;
  final String? dashUrl;
  final String? youtubeId;
  final String thumbnailUrl;
  final String? eventId;
  final String? fightId;
  final int viewerCount;
  final DateTime? scheduledStart;
  final DateTime? actualStart;
  final DateTime? endedAt;
  final bool isPPV;
  final int ppvPriceCents;
  final Map<String, dynamic> metadata;

  const LiveStream({
    required this.id,
    required this.title,
    this.description = '',
    required this.type,
    required this.status,
    required this.streamUrl,
    this.hlsUrl,
    this.dashUrl,
    this.youtubeId,
    required this.thumbnailUrl,
    this.eventId,
    this.fightId,
    this.viewerCount = 0,
    this.scheduledStart,
    this.actualStart,
    this.endedAt,
    this.isPPV = false,
    this.ppvPriceCents = 0,
    this.metadata = const {},
  });

  factory LiveStream.fromMap(Map<String, dynamic> map) => LiveStream(
    id: map['id'] ?? '',
    title: map['title'] ?? 'Untitled Stream',
    description: map['description'] ?? '',
    type: StreamType.values.firstWhere(
      (t) => t.name == map['type'],
      orElse: () => StreamType.hls,
    ),
    status: StreamStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => StreamStatus.scheduled,
    ),
    streamUrl: map['streamUrl'] ?? '',
    hlsUrl: map['hlsUrl'],
    dashUrl: map['dashUrl'],
    youtubeId: map['youtubeId'],
    thumbnailUrl: map['thumbnailUrl'] ?? '',
    eventId: map['eventId'],
    fightId: map['fightId'],
    viewerCount: map['viewerCount'] ?? 0,
    scheduledStart: (map['scheduledStart'] as Timestamp?)?.toDate(),
    actualStart: (map['actualStart'] as Timestamp?)?.toDate(),
    endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
    isPPV: map['isPPV'] ?? false,
    ppvPriceCents: map['ppvPriceCents'] ?? 0,
    metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'status': status.name,
    'streamUrl': streamUrl,
    'hlsUrl': hlsUrl,
    'dashUrl': dashUrl,
    'youtubeId': youtubeId,
    'thumbnailUrl': thumbnailUrl,
    'eventId': eventId,
    'fightId': fightId,
    'viewerCount': viewerCount,
    'isPPV': isPPV,
    'ppvPriceCents': ppvPriceCents,
    'metadata': metadata,
  };

  String get playbackUrl {
    if (type == StreamType.youtube && youtubeId != null) {
      return 'https://www.youtube.com/watch?v=$youtubeId';
    }
    if (hlsUrl != null && hlsUrl!.isNotEmpty) return hlsUrl!;
    if (dashUrl != null && dashUrl!.isNotEmpty) return dashUrl!;
    return streamUrl;
  }

  bool get isLive => status == StreamStatus.live;
  bool get isVOD => status == StreamStatus.vod;
}

class PPVPurchase {
  final String id;
  final String userId;
  final String streamId;
  final String eventId;
  final int pricePaidCents;
  final PPVAccessLevel accessLevel;
  final DateTime purchasedAt;
  final DateTime? expiresAt;
  final bool isActive;

  const PPVPurchase({
    required this.id,
    required this.userId,
    required this.streamId,
    required this.eventId,
    required this.pricePaidCents,
    required this.accessLevel,
    required this.purchasedAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory PPVPurchase.fromMap(Map<String, dynamic> map) => PPVPurchase(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    streamId: map['streamId'] ?? '',
    eventId: map['eventId'] ?? '',
    pricePaidCents: map['pricePaidCents'] ?? 0,
    accessLevel: PPVAccessLevel.values.firstWhere(
      (a) => a.name == map['accessLevel'],
      orElse: () => PPVAccessLevel.none,
    ),
    purchasedAt: (map['purchasedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
    isActive: map['isActive'] ?? true,
  );
}

class VideoStreamingService with ChangeNotifier {
  static final VideoStreamingService _instance =
      VideoStreamingService._internal();
  factory VideoStreamingService() => _instance;
  VideoStreamingService._internal();

  StreamSubscription<QuerySnapshot>? _liveStreamsSub;
  final List<LiveStream> _liveStreams = [];
  final List<LiveStream> _vodLibrary = [];
  final Map<String, PPVPurchase> _userPurchases = {};
  LiveStream? _currentStream;
  StreamQuality _preferredQuality = StreamQuality.auto;

  List<LiveStream> get liveStreams => List.unmodifiable(_liveStreams);
  List<LiveStream> get vodLibrary => List.unmodifiable(_vodLibrary);
  LiveStream? get currentStream => _currentStream;
  StreamQuality get preferredQuality => _preferredQuality;

  Future<void> initialize(String userId) async {
    debugPrint('📺 VideoStreamingService: Initializing...');
    await Future.wait([_loadUserPurchases(userId), _subscribeLiveStreams()]);
    notifyListeners();
  }

  Future<void> _loadUserPurchases(String userId) async {
    try {
      final snap = await _firestore
          .collection('ppv_purchases')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();
      _userPurchases.clear();
      for (final doc in snap.docs) {
        final purchase = PPVPurchase.fromMap({...doc.data(), 'id': doc.id});
        _userPurchases[purchase.streamId] = purchase;
      }
    } catch (e) {
      debugPrint('VideoStreamingService: Load purchases failed: $e');
    }
  }

  Future<void> _subscribeLiveStreams() async {
    _liveStreamsSub?.cancel();
    _liveStreamsSub = _firestore
        .collection('live_streams')
        .where('status', whereIn: ['scheduled', 'live'])
        .orderBy('scheduledStart', descending: false)
        .limit(20)
        .snapshots()
        .listen((snap) {
          _liveStreams.clear();
          for (final doc in snap.docs) {
            _liveStreams.add(LiveStream.fromMap({...doc.data(), 'id': doc.id}));
          }
          notifyListeners();
        });
  }

  Future<void> loadVODLibrary({String? eventId, int limit = 50}) async {
    try {
      var query = _firestore
          .collection('live_streams')
          .where('status', isEqualTo: 'vod');
      if (eventId != null) query = query.where('eventId', isEqualTo: eventId);
      final snap = await query
          .orderBy('endedAt', descending: true)
          .limit(limit)
          .get();
      _vodLibrary.clear();
      for (final doc in snap.docs) {
        _vodLibrary.add(LiveStream.fromMap({...doc.data(), 'id': doc.id}));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('VideoStreamingService: Load VOD failed: $e');
    }
  }

  PPVAccessLevel getAccessLevel(String streamId) {
    final purchase = _userPurchases[streamId];
    return purchase?.accessLevel ?? PPVAccessLevel.none;
  }

  bool hasPPVAccess(String streamId) {
    final level = getAccessLevel(streamId);
    return level == PPVAccessLevel.purchased ||
        level == PPVAccessLevel.vip ||
        level == PPVAccessLevel.promoter;
  }

  Future<String?> getStreamPlaybackUrl(
    String streamId, {
    StreamQuality? quality,
  }) async {
    try {
      final callable = _functions.httpsCallable('getSecureStreamUrl');
      final result = await callable.call<Map<String, dynamic>>({
        'streamId': streamId,
        'quality': (quality ?? _preferredQuality).name,
      });
      if (result.data['error'] != null) {
        debugPrint('VideoStreamingService: ${result.data['error']}');
        return null;
      }
      return result.data['url'] as String?;
    } catch (e) {
      debugPrint('VideoStreamingService: Get playback URL failed: $e');
      return null;
    }
  }

  void setCurrentStream(LiveStream? stream) {
    _currentStream = stream;
    notifyListeners();
  }

  void setPreferredQuality(StreamQuality quality) {
    _preferredQuality = quality;
    notifyListeners();
  }

  Future<void> reportViewerJoined(String streamId) async {
    await _firestore.collection('live_streams').doc(streamId).update({
      'viewerCount': FieldValue.increment(1),
    });
  }

  Future<void> reportViewerLeft(String streamId) async {
    await _firestore.collection('live_streams').doc(streamId).update({
      'viewerCount': FieldValue.increment(-1),
    });
  }

  Future<LiveStream?> getStream(String streamId) async {
    try {
      final doc = await _firestore
          .collection('live_streams')
          .doc(streamId)
          .get();
      if (doc.exists) return LiveStream.fromMap({...doc.data()!, 'id': doc.id});
    } catch (e) {
      debugPrint('VideoStreamingService: Get stream failed: $e');
    }
    return null;
  }

  @override
  void dispose() {
    _liveStreamsSub?.cancel();
    super.dispose();
  }
}
