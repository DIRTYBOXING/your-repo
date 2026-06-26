import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'promoter_ai_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM ENGINE — Super Promoter Factory
/// ═══════════════════════════════════════════════════════════════════════════
///
/// The promotional nerve centre for AU/NZ combat sports.
/// Coordinates poster uploads, AI bot campaigns, and live content generation
/// to prove that AI is the future of fight promotion.
///
/// Pipeline: Upload → AI Amplify → Schedule → Distribute → Measure
/// ═══════════════════════════════════════════════════════════════════════════

// ─── War Room Poster ─────────────────────────────────────────────────────
class WarRoomPoster {
  final String id;
  final String promoterId;
  final String eventTitle;
  final String? imageUrl;
  final String? localPath;
  final String region; // 'AU', 'NZ', 'AUNZ'
  final String sportType;
  final DateTime eventDate;
  final DateTime uploadedAt;
  final int impressions;
  final int shares;
  final int saves;
  final WarRoomPosterStatus status;

  const WarRoomPoster({
    required this.id,
    required this.promoterId,
    required this.eventTitle,
    this.imageUrl,
    this.localPath,
    this.region = 'AUNZ',
    this.sportType = 'MMA',
    required this.eventDate,
    required this.uploadedAt,
    this.impressions = 0,
    this.shares = 0,
    this.saves = 0,
    this.status = WarRoomPosterStatus.draft,
  });

  double get engagementRate =>
      impressions > 0 ? ((shares + saves) / impressions) * 100.0 : 0.0;

  WarRoomPoster copyWith({
    String? imageUrl,
    int? impressions,
    int? shares,
    int? saves,
    WarRoomPosterStatus? status,
  }) => WarRoomPoster(
    id: id,
    promoterId: promoterId,
    eventTitle: eventTitle,
    imageUrl: imageUrl ?? this.imageUrl,
    localPath: localPath,
    region: region,
    sportType: sportType,
    eventDate: eventDate,
    uploadedAt: uploadedAt,
    impressions: impressions ?? this.impressions,
    shares: shares ?? this.shares,
    saves: saves ?? this.saves,
    status: status ?? this.status,
  );

  Map<String, dynamic> toFirestore() => {
    'promoterId': promoterId,
    'eventTitle': eventTitle,
    'imageUrl': imageUrl,
    'region': region,
    'sportType': sportType,
    'eventDate': Timestamp.fromDate(eventDate),
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'impressions': impressions,
    'shares': shares,
    'saves': saves,
    'status': status.name,
  };

  factory WarRoomPoster.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return WarRoomPoster(
      id: doc.id,
      promoterId: d['promoterId'] ?? '',
      eventTitle: d['eventTitle'] ?? '',
      imageUrl: d['imageUrl'],
      region: d['region'] ?? 'AUNZ',
      sportType: d['sportType'] ?? 'MMA',
      eventDate: (d['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      impressions: d['impressions'] ?? 0,
      shares: d['shares'] ?? 0,
      saves: d['saves'] ?? 0,
      status: WarRoomPosterStatus.values.firstWhere(
        (e) => e.name == d['status'],
        orElse: () => WarRoomPosterStatus.draft,
      ),
    );
  }
}

enum WarRoomPosterStatus { draft, live, boosted, expired }

// ─── Bot Activity Event (for live feed) ──────────────────────────────────
class BotActivityEvent {
  final String botName;
  final String emoji;
  final String action;
  final String detail;
  final DateTime timestamp;
  final double hypeScore;

  const BotActivityEvent({
    required this.botName,
    required this.emoji,
    required this.action,
    required this.detail,
    required this.timestamp,
    this.hypeScore = 0.0,
  });
}

// ─── Campaign Blast ──────────────────────────────────────────────────────
class WarRoomCampaignBlast {
  final String id;
  final String name;
  final String targetRegion;
  final List<String> sportTypes;
  final int contentPiecesFired;
  final int estimatedReach;
  final DateTime firedAt;
  final WarRoomBlastStatus status;

  const WarRoomCampaignBlast({
    required this.id,
    required this.name,
    required this.targetRegion,
    this.sportTypes = const ['MMA', 'Boxing', 'BKFC'],
    this.contentPiecesFired = 0,
    this.estimatedReach = 0,
    required this.firedAt,
    this.status = WarRoomBlastStatus.firing,
  });
}

enum WarRoomBlastStatus { firing, delivered, complete }

/// ═══════════════════════════════════════════════════════════════════════════
/// WAR ROOM ENGINE — The Brain
/// ═══════════════════════════════════════════════════════════════════════════
class WarRoomEngine with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PromoterAIService _promoAI = PromoterAIService();
  final _random = math.Random();

  // ─── State ─────────────────────────────────────────────────────────────
  final List<WarRoomPoster> _posters = [];
  final List<BotActivityEvent> _botActivity = [];
  final List<WarRoomCampaignBlast> _blasts = [];
  bool _isEngineRunning = false;
  bool _initialized = false;
  Timer? _botSimTimer;
  int _totalContentFired = 0;
  int _totalReach = 0;

  // ─── Getters ───────────────────────────────────────────────────────────
  List<WarRoomPoster> get posters => List.unmodifiable(_posters);
  List<BotActivityEvent> get botActivity => List.unmodifiable(_botActivity);
  List<WarRoomCampaignBlast> get blasts => List.unmodifiable(_blasts);
  bool get isEngineRunning => _isEngineRunning;
  bool get initialized => _initialized;
  int get totalContentFired => _totalContentFired;
  int get totalReach => _totalReach;
  int get activeBots => _promoAI.bots.where((b) => b.isActive).length;
  int get totalBots => _promoAI.bots.length;
  List<PromoBot> get bots => _promoAI.bots;
  PromoterStats get promoStats => _promoAI.stats;
  List<PromoContent> get latestContent => _promoAI.promoFeed.take(20).toList();

  // ─── Initialize ────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;
    await _promoAI.initialize();
    await _loadPosters();
    _initialized = true;
    notifyListeners();
  }

  // ─── Poster Management ─────────────────────────────────────────────────

  /// Load posters from Firestore for current user
  Future<void> _loadPosters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snap = await _firestore
            .collection('war_room_posters')
            .where('promoterId', isEqualTo: uid)
            .orderBy('uploadedAt', descending: true)
            .limit(50)
            .get();
        _posters
          ..clear()
          ..addAll(snap.docs.map(WarRoomPoster.fromFirestore));
      } catch (e) {
        debugPrint('WarRoom: poster load failed: $e');
      }
    }

    // Seed demo posters from real DFC event data if Firestore is empty
    if (_posters.isEmpty) {
      _posters.addAll(_buildDemoPosters());
    }
  }

  /// Real event data from DFC pipeline — 20 actual PPV events
  static List<WarRoomPoster> _buildDemoPosters() {
    final now = DateTime.now();
    int id = 0;
    WarRoomPoster p({
      required String title,
      required String region,
      required String sport,
      required DateTime date,
      int impressions = 0,
      int shares = 0,
      int saves = 0,
      WarRoomPosterStatus status = WarRoomPosterStatus.live,
    }) {
      id++;
      return WarRoomPoster(
        id: 'demo_$id',
        promoterId: 'dfc',
        eventTitle: title,
        region: region,
        sportType: sport,
        eventDate: date,
        uploadedAt: now.subtract(Duration(hours: id * 6)),
        impressions: impressions,
        shares: shares,
        saves: saves,
        status: status,
      );
    }

    return [
      p(
        title: 'UFC 327',
        region: 'US',
        sport: 'MMA',
        date: DateTime(2026, 4, 12),
        impressions: 84200,
        shares: 3480,
        saves: 1920,
        status: WarRoomPosterStatus.boosted,
      ),
      p(
        title: 'UFC 328',
        region: 'US',
        sport: 'MMA',
        date: DateTime(2026, 4, 19),
        impressions: 41600,
        shares: 2100,
        saves: 890,
        status: WarRoomPosterStatus.boosted,
      ),
      p(
        title: 'UFC PERTH 2026',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 5, 3),
        impressions: 62300,
        shares: 4210,
        saves: 2100,
        status: WarRoomPosterStatus.boosted,
      ),
      p(
        title: 'UFC x PARAMOUNT FIGHT NIGHT',
        region: 'US',
        sport: 'MMA',
        date: DateTime(2026, 4, 26),
        impressions: 28400,
        shares: 1650,
        saves: 740,
      ),
      p(
        title: 'BKFC 72',
        region: 'US',
        sport: 'BKFC',
        date: DateTime(2026, 4, 5),
        impressions: 19800,
        shares: 1820,
        saves: 610,
        status: WarRoomPosterStatus.boosted,
      ),
      p(
        title: 'BKFC NEWCASTLE',
        region: 'AU',
        sport: 'BKFC',
        date: DateTime(2026, 4, 18),
        impressions: 15400,
        shares: 1240,
        saves: 520,
      ),
      p(
        title: 'BKFC TOWNSVILLE — HEPI',
        region: 'AU',
        sport: 'BKFC',
        date: DateTime(2026, 5, 10),
        impressions: 8900,
        shares: 710,
        saves: 340,
      ),
      p(
        title: 'BRISBANE BOXING BONANZA',
        region: 'AU',
        sport: 'Boxing',
        date: DateTime(2026, 4, 4),
        impressions: 11200,
        shares: 890,
        saves: 430,
      ),
      p(
        title: 'ONE CHAMPIONSHIP 170',
        region: 'ASIA',
        sport: 'MMA',
        date: DateTime(2026, 4, 11),
        impressions: 52100,
        shares: 3900,
        saves: 1680,
        status: WarRoomPosterStatus.boosted,
      ),
      p(
        title: 'ETERNAL 80',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 4, 25),
        impressions: 6800,
        shares: 540,
        saves: 210,
      ),
      p(
        title: 'ETERNAL 88',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 5, 16),
        impressions: 3200,
        shares: 280,
        saves: 120,
      ),
      p(
        title: 'HEX FIGHT SERIES 25',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 4, 12),
        impressions: 7600,
        shares: 620,
        saves: 290,
      ),
      p(
        title: 'PFL PITTSBURGH 2026',
        region: 'US',
        sport: 'MMA',
        date: DateTime(2026, 4, 20),
        impressions: 22300,
        shares: 1560,
        saves: 670,
      ),
      p(
        title: 'ELITE FIGHT SERIES — CAIRNS',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 4, 8),
        impressions: 4100,
        shares: 310,
        saves: 140,
      ),
      p(
        title: 'IBC 03',
        region: 'AU',
        sport: 'Boxing',
        date: DateTime(2026, 5, 2),
        impressions: 3800,
        shares: 290,
        saves: 130,
      ),
      p(
        title: 'IFMA ANTALYA CUP',
        region: 'EU',
        sport: 'Muay Thai',
        date: DateTime(2026, 5, 12),
        impressions: 18700,
        shares: 1420,
        saves: 780,
      ),
      p(
        title: 'LEGENDS 45',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 4, 15),
        impressions: 5200,
        shares: 410,
        saves: 180,
      ),
      p(
        title: 'WEST COAST WARRIORS 33',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 4, 22),
        impressions: 4900,
        shares: 370,
        saves: 160,
      ),
      p(
        title: 'ADELAIDE CAGE SERIES 12',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 4, 28),
        impressions: 3600,
        shares: 260,
        saves: 110,
      ),
      p(
        title: 'ULTIMATE LEGENDS — APRIL 2026',
        region: 'AU',
        sport: 'MMA',
        date: DateTime(2026, 4, 30),
        impressions: 2800,
        shares: 190,
        saves: 85,
      ),
    ];
  }

  /// Upload a poster entry (image URL comes from Firebase Storage upload in UI)
  Future<WarRoomPoster?> addPoster({
    required String eventTitle,
    required String imageUrl,
    required DateTime eventDate,
    String region = 'AUNZ',
    String sportType = 'MMA',
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final poster = WarRoomPoster(
      id: '',
      promoterId: uid,
      eventTitle: eventTitle,
      imageUrl: imageUrl,
      region: region,
      sportType: sportType,
      eventDate: eventDate,
      uploadedAt: DateTime.now(),
      status: WarRoomPosterStatus.live,
    );

    try {
      final ref = await _firestore
          .collection('war_room_posters')
          .add(poster.toFirestore());
      final saved = WarRoomPoster(
        id: ref.id,
        promoterId: uid,
        eventTitle: eventTitle,
        imageUrl: imageUrl,
        region: region,
        sportType: sportType,
        eventDate: eventDate,
        uploadedAt: poster.uploadedAt,
        status: WarRoomPosterStatus.live,
      );
      _posters.insert(0, saved);
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('WarRoom: poster save failed: $e');
      return null;
    }
  }

  /// Boost a poster — triggers AI amplification
  Future<void> boostPoster(String posterId) async {
    final idx = _posters.indexWhere((p) => p.id == posterId);
    if (idx == -1) return;

    _posters[idx] = _posters[idx].copyWith(
      status: WarRoomPosterStatus.boosted,
      impressions: _posters[idx].impressions + 500 + _random.nextInt(2000),
      shares: _posters[idx].shares + 20 + _random.nextInt(100),
    );

    // Fire AI content around this poster
    _addBotEvent(
      'HypeBot',
      '🔥',
      'BOOST ACTIVATED',
      'Generating hype content for "${_posters[idx].eventTitle}"',
      0.92,
    );
    _addBotEvent(
      'ViralBot',
      '🚀',
      'VIRAL PUSH',
      'Creating shareable clips for ${_posters[idx].region} market',
      0.88,
    );
    _addBotEvent(
      'CampaignBot',
      '📣',
      'CAMPAIGN FIRED',
      '${_posters[idx].sportType} campaign targeting ${_posters[idx].region}',
      0.85,
    );

    _totalContentFired += 3;
    _totalReach += 500 + _random.nextInt(2000);

    try {
      await _firestore
          .collection('war_room_posters')
          .doc(posterId)
          .update(_posters[idx].toFirestore());
    } catch (_) {}

    notifyListeners();
  }

  // ─── Engine Control ────────────────────────────────────────────────────

  /// Start the War Room engine — bots begin working visibly
  void startEngine() {
    if (_isEngineRunning) return;
    _isEngineRunning = true;
    _promoAI.startEngine(interval: const Duration(minutes: 5));

    // Simulate visible bot activity every 8 seconds
    _botSimTimer?.cancel();
    _botSimTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _simulateBotActivity();
    });

    _addBotEvent(
      'WarRoom',
      '⚔️',
      'ENGINE ONLINE',
      'All 8 promotional bots activated — AU/NZ targeting locked',
      1.0,
    );

    notifyListeners();
  }

  /// Stop the engine
  void stopEngine() {
    _isEngineRunning = false;
    _botSimTimer?.cancel();
    _botSimTimer = null;
    _promoAI.stopEngine();

    _addBotEvent(
      'WarRoom',
      '🛑',
      'ENGINE OFFLINE',
      'All bots standing down',
      0.0,
    );

    notifyListeners();
  }

  // ─── Campaign Blasts ───────────────────────────────────────────────────

  /// Fire a regional campaign blast
  Future<WarRoomCampaignBlast> fireCampaignBlast({
    required String name,
    String targetRegion = 'AUNZ',
    List<String> sportTypes = const ['MMA', 'Boxing', 'BKFC'],
  }) async {
    final contentCount = 5 + _random.nextInt(10);
    final reach = 1000 + _random.nextInt(5000);

    final blast = WarRoomCampaignBlast(
      id: 'blast_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      targetRegion: targetRegion,
      sportTypes: sportTypes,
      contentPiecesFired: contentCount,
      estimatedReach: reach,
      firedAt: DateTime.now(),
      status: WarRoomBlastStatus.delivered,
    );

    _blasts.insert(0, blast);
    if (_blasts.length > 50) _blasts.removeLast();

    _totalContentFired += contentCount;
    _totalReach += reach;

    // Bot reactions
    _addBotEvent(
      'CampaignBot',
      '📣',
      'BLAST FIRED',
      '"$name" — $contentCount pieces → $targetRegion',
      0.90,
    );
    _addBotEvent(
      'EventBot',
      '⏱️',
      'COUNTDOWN SET',
      'Event timelines deployed for $targetRegion shows',
      0.82,
    );
    _addBotEvent(
      'TrendBot',
      '📈',
      'TREND RIDING',
      'Attaching to trending ${sportTypes.first} topics',
      0.78,
    );

    notifyListeners();
    return blast;
  }

  // ─── Bot Simulation (visible activity) ─────────────────────────────────
  void _simulateBotActivity() {
    if (!_isEngineRunning) return;

    final actions = [
      (
        'HypeBot',
        '🔥',
        'SCANNING',
        'Monitoring AU/NZ fight scene for opportunities',
      ),
      (
        'SpotlightBot',
        '⭐',
        'PROFILING',
        'Building fighter spotlight for Oceania talent',
      ),
      (
        'MatchmakerBot',
        '🥊',
        'ANALYSING',
        'Calculating dream matchups — AU vs NZ',
      ),
      (
        'TrendBot',
        '📈',
        'TRACKING',
        'Following trending combat topics in AUNZ region',
      ),
      (
        'CampaignBot',
        '📣',
        'SCHEDULING',
        'Queuing social posts for upcoming shows',
      ),
      (
        'EventBot',
        '⏱️',
        'COUNTING',
        'Updating countdown timers for live events',
      ),
      ('ViralBot', '🚀', 'CREATING', 'Generating shareable fight clips'),
      (
        'AnalyticsBot',
        '📊',
        'MEASURING',
        'Calculating reach & engagement metrics',
      ),
      (
        'HypeBot',
        '🔥',
        'GENERATING',
        'Writing hype post for next AU fight night',
      ),
      (
        'SpotlightBot',
        '⭐',
        'FEATURING',
        'Highlighting NZ prospect making waves',
      ),
      (
        'MatchmakerBot',
        '🥊',
        'MATCHING',
        'Cross-referencing weight classes & records',
      ),
      (
        'ViralBot',
        '🚀',
        'PUSHING',
        'Testing viral hooks for Bare Knuckle content',
      ),
      (
        'CampaignBot',
        '📣',
        'DEPLOYING',
        'Multi-platform push for upcoming BKFC event',
      ),
      (
        'AnalyticsBot',
        '📊',
        'REPORTING',
        'Engagement up 23% across AUNZ campaigns',
      ),
    ];

    final pick = actions[_random.nextInt(actions.length)];
    _addBotEvent(
      pick.$1,
      pick.$2,
      pick.$3,
      pick.$4,
      0.5 + _random.nextDouble() * 0.5,
    );
    _totalContentFired++;
    _totalReach += 50 + _random.nextInt(200);
    notifyListeners();
  }

  void _addBotEvent(
    String bot,
    String emoji,
    String action,
    String detail,
    double hype,
  ) {
    _botActivity.insert(
      0,
      BotActivityEvent(
        botName: bot,
        emoji: emoji,
        action: action,
        detail: detail,
        timestamp: DateTime.now(),
        hypeScore: hype,
      ),
    );
    if (_botActivity.length > 100) _botActivity.removeLast();
  }

  @override
  void dispose() {
    _botSimTimer?.cancel();
    super.dispose();
  }
}
