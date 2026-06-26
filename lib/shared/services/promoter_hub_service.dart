import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PROMOTER HUB SERVICE — One-Stop Promotions Platform
// ═════════════════════════════════════════════════════════════════════════════
//
// Provides:
//   • User media POOL — shared event assets (posters, clips, banners) between
//     a promoter and their collaborators (friends/team members).
//   • Distribution ACCOUNTING — per-channel, per-region tracking of every
//     publish action: reach, cost, revenue attribution.
//   • Collaborator NETWORK — pull friends/team members and enable direct
//     message context (creates conversations via MessagingService).
//   • PPV + video channel REGISTRY — list known international broadcast
//     channels and track which are active for a given event.
//   • Revenue SETTLEMENT — per-channel split breakdown, running totals.
//
// Firestore Collections:
//   promoter_media_pools/{eventId}/assets       — shared media assets
//   promoter_media_pools/{eventId}/members      — collaborators on this pool
//   distribution_runs/{runId}                   — per-publish accounting log
//   distribution_channel_configs/{channelId}    — channel on/off + credentials
//   promoter_revenue/{promoterId}/settlements   — revenue tracking per event
//
// Firebase Storage Paths:
//   event_pools/{eventId}/{assetType}/{fileName} — pooled event media
//
// ═════════════════════════════════════════════════════════════════════════════

// ── Models ─────────────────────────────────────────────────────────────────

enum PoolAssetType { poster, banner, clip, thumbnail, fightCard, other }

enum ChannelRegion {
  au,
  nz,
  us,
  gb,
  eu,
  in_,
  pk,
  ph,
  ng,
  br,
  jp,
  ae,
  za,
  th,
  sg,
  my,
  id_,
  mx,
  co,
  ar;

  String get flag =>
      const {
        'au': '🇦🇺',
        'nz': '🇳🇿',
        'us': '🇺🇸',
        'gb': '🇬🇧',
        'eu': '🇪🇺',
        'in_': '🇮🇳',
        'pk': '🇵🇰',
        'ph': '🇵🇭',
        'ng': '🇳🇬',
        'br': '🇧🇷',
        'jp': '🇯🇵',
        'ae': '🇦🇪',
        'za': '🇿🇦',
        'th': '🇹🇭',
        'sg': '🇸🇬',
        'my': '🇲🇾',
        'id_': '🇮🇩',
        'mx': '🇲🇽',
        'co': '🇨🇴',
        'ar': '🇦🇷',
      }[name] ??
      '🌐';

  String get label =>
      const {
        'au': 'Australia',
        'nz': 'New Zealand',
        'us': 'United States',
        'gb': 'United Kingdom',
        'eu': 'Europe',
        'in_': 'India',
        'pk': 'Pakistan',
        'ph': 'Philippines',
        'ng': 'Nigeria',
        'br': 'Brazil',
        'jp': 'Japan',
        'ae': 'UAE / Middle East',
        'za': 'South Africa',
        'th': 'Thailand',
        'sg': 'Singapore',
        'my': 'Malaysia',
        'id_': 'Indonesia',
        'mx': 'Mexico',
        'co': 'Colombia',
        'ar': 'Argentina',
      }[name] ??
      name;
}

class PoolAsset {
  final String id;
  final String eventId;
  final String uploaderId;
  final String uploaderName;
  final PoolAssetType type;
  final String downloadUrl;
  final String storagePath;
  final String fileName;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final String? notes;

  const PoolAsset({
    required this.id,
    required this.eventId,
    required this.uploaderId,
    required this.uploaderName,
    required this.type,
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.uploadedAt,
    this.notes,
  });

  factory PoolAsset.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PoolAsset(
      id: doc.id,
      eventId: d['eventId'] ?? '',
      uploaderId: d['uploaderId'] ?? '',
      uploaderName: d['uploaderName'] ?? 'Unknown',
      type: PoolAssetType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => PoolAssetType.other,
      ),
      downloadUrl: d['downloadUrl'] ?? '',
      storagePath: d['storagePath'] ?? '',
      fileName: d['fileName'] ?? '',
      fileSizeBytes: d['fileSizeBytes'] ?? 0,
      uploadedAt: (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: d['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'uploaderId': uploaderId,
    'uploaderName': uploaderName,
    'type': type.name,
    'downloadUrl': downloadUrl,
    'storagePath': storagePath,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    if (notes != null) 'notes': notes,
  };
}

class DistributionRun {
  final String id;
  final String eventId;
  final String promoterId;
  final String
  channel; // 'instagram' | 'facebook' | 'youtube' | 'tiktok' | 'dfc' | 'ppv' | 'broadcast'
  final String region; // ChannelRegion name
  final String status; // 'queued' | 'sent' | 'failed'
  final int estimatedReachK; // estimated reach in thousands
  final int actualReachK;
  final int revenueCents; // revenue attributed to this channel for this event
  final DateTime? sentAt;
  final DateTime createdAt;
  final String? errorMessage;
  final String? posterUrl;
  final String? caption;

  const DistributionRun({
    required this.id,
    required this.eventId,
    required this.promoterId,
    required this.channel,
    required this.region,
    required this.status,
    this.estimatedReachK = 0,
    this.actualReachK = 0,
    this.revenueCents = 0,
    this.sentAt,
    required this.createdAt,
    this.errorMessage,
    this.posterUrl,
    this.caption,
  });

  factory DistributionRun.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DistributionRun(
      id: doc.id,
      eventId: d['eventId'] ?? '',
      promoterId: d['promoterId'] ?? '',
      channel: d['channel'] ?? '',
      region: d['region'] ?? 'au',
      status: d['status'] ?? 'queued',
      estimatedReachK: d['estimatedReachK'] ?? 0,
      actualReachK: d['actualReachK'] ?? 0,
      revenueCents: d['revenueCents'] ?? 0,
      sentAt: (d['sentAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      errorMessage: d['errorMessage'],
      posterUrl: d['posterUrl'],
      caption: d['caption'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'promoterId': promoterId,
    'channel': channel,
    'region': region,
    'status': status,
    'estimatedReachK': estimatedReachK,
    'actualReachK': actualReachK,
    'revenueCents': revenueCents,
    if (sentAt != null) 'sentAt': Timestamp.fromDate(sentAt!),
    'createdAt': Timestamp.fromDate(createdAt),
    if (errorMessage != null) 'errorMessage': errorMessage,
    if (posterUrl != null) 'posterUrl': posterUrl,
    if (caption != null) 'caption': caption,
  };
}

class DistributionChannelConfig {
  final String channelId;
  final bool enabled;
  final List<String> activeRegions;
  final int totalSent;
  final int totalReachK;
  final int totalRevenueCents;
  final DateTime? lastSentAt;

  const DistributionChannelConfig({
    required this.channelId,
    required this.enabled,
    required this.activeRegions,
    this.totalSent = 0,
    this.totalReachK = 0,
    this.totalRevenueCents = 0,
    this.lastSentAt,
  });

  factory DistributionChannelConfig.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DistributionChannelConfig(
      channelId: doc.id,
      enabled: d['enabled'] ?? false,
      activeRegions: List<String>.from(d['activeRegions'] ?? []),
      totalSent: d['totalSent'] ?? 0,
      totalReachK: d['totalReachK'] ?? 0,
      totalRevenueCents: d['totalRevenueCents'] ?? 0,
      lastSentAt: (d['lastSentAt'] as Timestamp?)?.toDate(),
    );
  }
}

class HubCollaborator {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String role; // 'promoter' | 'media' | 'fighter' | 'manager' | 'crew'
  final bool isOnline;
  final DateTime? lastSeen;

  const HubCollaborator({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.role,
    this.isOnline = false,
    this.lastSeen,
  });

  factory HubCollaborator.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HubCollaborator(
      userId: doc.id,
      displayName: d['displayName'] ?? d['name'] ?? 'Unknown',
      photoUrl: d['photoUrl'] ?? d['photoURL'],
      role: d['role'] ?? 'crew',
      isOnline: d['isOnline'] ?? false,
      lastSeen: (d['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
}

// ── Revenue Settlement ─────────────────────────────────────────────────────

class ChannelRevenueLine {
  final String channel;
  final String region;
  final int salesCount;
  final int grossRevenueCents;
  final int platformFeeCents;
  final int promoterShareCents;
  final bool settled;

  const ChannelRevenueLine({
    required this.channel,
    required this.region,
    required this.salesCount,
    required this.grossRevenueCents,
    required this.platformFeeCents,
    required this.promoterShareCents,
    this.settled = false,
  });
}

// ── International PPV/Broadcast Channel Registry ───────────────────────────

class IntlBroadcastChannel {
  final String id;
  final String name;
  final String
  type; // 'streaming' | 'broadcast' | 'free-to-air' | 'ppv' | 'social'
  final String region;
  final String domain;
  final bool available;

  const IntlBroadcastChannel({
    required this.id,
    required this.name,
    required this.type,
    required this.region,
    required this.domain,
    this.available = true,
  });
}

// ── Service ────────────────────────────────────────────────────────────────

class PromoterHubService extends ChangeNotifier {
  static final PromoterHubService _instance = PromoterHubService._();
  factory PromoterHubService() => _instance;
  PromoterHubService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ── Firestore collection keys ────────────────────────────────────────────
  static const _mediaPoolsCol = 'promoter_media_pools';
  static const _distRunsCol = 'distribution_runs';
  static const _channelConfigsCol = 'distribution_channel_configs';
  // ignore: unused_field
  static const _revenueCol = 'promoter_revenue';
  static const _usersCol = 'users';

  // Accept platform IDs from registry + operational aliases used by DFC flows.
  static final Set<String> _extraChannelIds = {
    'ppv',
    'broadcast',
    'twitter',
    'x',
  };

  static final Set<String> _supportedChannelIds = {
    ...kIntlChannels.map((c) => c.id),
    ..._extraChannelIds,
  };

  static final Set<String> _supportedRegions = {
    ...ChannelRegion.values.map((r) => r.name),
    'global',
    'apac',
  };

  // ── International Broadcast Registry (static — extend as needed) ─────────
  static const List<IntlBroadcastChannel> kIntlChannels = [
    // ── Streaming ──────────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'dfc',
      name: 'DataFightCentral',
      type: 'ppv',
      region: 'global',
      domain: 'datafightcentral.com',
    ),
    IntlBroadcastChannel(
      id: 'espn_plus',
      name: 'ESPN+',
      type: 'streaming',
      region: 'us',
      domain: 'espnplus.com',
    ),
    IntlBroadcastChannel(
      id: 'dazn',
      name: 'DAZN',
      type: 'streaming',
      region: 'global',
      domain: 'dazn.com',
    ),
    IntlBroadcastChannel(
      id: 'prime_video',
      name: 'Prime Video',
      type: 'streaming',
      region: 'global',
      domain: 'primevideo.com',
    ),
    IntlBroadcastChannel(
      id: 'kayo',
      name: 'Kayo Sports',
      type: 'streaming',
      region: 'au',
      domain: 'kayosports.com.au',
    ),
    IntlBroadcastChannel(
      id: 'foxtel',
      name: 'Foxtel',
      type: 'streaming',
      region: 'au',
      domain: 'foxtel.com.au',
    ),
    IntlBroadcastChannel(
      id: 'one_fc',
      name: 'ONE Championship',
      type: 'streaming',
      region: 'apac',
      domain: 'onefc.com',
    ),
    IntlBroadcastChannel(
      id: 'sky_sports',
      name: 'Sky Sports',
      type: 'broadcast',
      region: 'gb',
      domain: 'skysports.com',
    ),
    IntlBroadcastChannel(
      id: 'bt_sport',
      name: 'TNT Sports (BT)',
      type: 'broadcast',
      region: 'gb',
      domain: 'tntsports.co.uk',
    ),
    IntlBroadcastChannel(
      id: 'jiocinema',
      name: 'JioCinema',
      type: 'streaming',
      region: 'in_',
      domain: 'jiocinema.com',
    ),
    IntlBroadcastChannel(
      id: 'voot',
      name: 'Voot Sports',
      type: 'streaming',
      region: 'in_',
      domain: 'voot.com',
    ),
    // ── Social / Video ─────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'youtube',
      name: 'YouTube',
      type: 'social',
      region: 'global',
      domain: 'youtube.com',
    ),
    IntlBroadcastChannel(
      id: 'facebook',
      name: 'Facebook',
      type: 'social',
      region: 'global',
      domain: 'facebook.com',
    ),
    IntlBroadcastChannel(
      id: 'instagram',
      name: 'Instagram',
      type: 'social',
      region: 'global',
      domain: 'instagram.com',
    ),
    IntlBroadcastChannel(
      id: 'tiktok',
      name: 'TikTok',
      type: 'social',
      region: 'global',
      domain: 'tiktok.com',
    ),
    // ── Free-to-Air ────────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'channel9_au',
      name: 'Channel 9 AU',
      type: 'free-to-air',
      region: 'au',
      domain: '9now.com.au',
    ),
    IntlBroadcastChannel(
      id: 'tvnz',
      name: 'TVNZ Pacific',
      type: 'free-to-air',
      region: 'nz',
      domain: 'tvnz.co.nz',
    ),
    IntlBroadcastChannel(
      id: 'rtv_ng',
      name: 'RTV Nigeria',
      type: 'broadcast',
      region: 'ng',
      domain: 'rtv.com.ng',
    ),
    IntlBroadcastChannel(
      id: 'supercanal',
      name: 'Supercanal',
      type: 'broadcast',
      region: 'ar',
      domain: 'supercanal.tv',
    ),
    IntlBroadcastChannel(
      id: 'sbn_ph',
      name: 'SBN Philippines',
      type: 'broadcast',
      region: 'ph',
      domain: 'sbn.com.ph',
    ),
    // ── Africa ─────────────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'supersport',
      name: 'SuperSport',
      type: 'broadcast',
      region: 'za',
      domain: 'supersport.com',
    ),
    IntlBroadcastChannel(
      id: 'showmax',
      name: 'Showmax',
      type: 'streaming',
      region: 'za',
      domain: 'showmax.com',
    ),
    IntlBroadcastChannel(
      id: 'dstv_now',
      name: 'DStv Now',
      type: 'streaming',
      region: 'za',
      domain: 'dstv.com',
    ),
    IntlBroadcastChannel(
      id: 'africa_magic',
      name: 'Africa Magic',
      type: 'broadcast',
      region: 'ng',
      domain: 'africamagic.tv',
    ),
    // ── APAC ───────────────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'abema',
      name: 'AbemaTV',
      type: 'streaming',
      region: 'jp',
      domain: 'abema.tv',
    ),
    IntlBroadcastChannel(
      id: 'u_next',
      name: 'U-NEXT',
      type: 'streaming',
      region: 'jp',
      domain: 'video.unext.jp',
    ),
    IntlBroadcastChannel(
      id: 'iqiyi',
      name: 'iQIYI',
      type: 'streaming',
      region: 'cn',
      domain: 'iqiyi.com',
    ),
    IntlBroadcastChannel(
      id: 'bilibili',
      name: 'Bilibili',
      type: 'social',
      region: 'cn',
      domain: 'bilibili.com',
    ),
    IntlBroadcastChannel(
      id: 'kumu',
      name: 'Kumu',
      type: 'social',
      region: 'ph',
      domain: 'kumu.ph',
    ),
    IntlBroadcastChannel(
      id: 'vidio',
      name: 'Vidio',
      type: 'streaming',
      region: 'id',
      domain: 'vidio.com',
    ),
    // ── Europe ─────────────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'canal_plus',
      name: 'Canal+',
      type: 'broadcast',
      region: 'eu',
      domain: 'canalplus.com',
    ),
    IntlBroadcastChannel(
      id: 'viaplay',
      name: 'Viaplay',
      type: 'streaming',
      region: 'eu',
      domain: 'viaplay.com',
    ),
    IntlBroadcastChannel(
      id: 'rai_sport',
      name: 'RaiSport',
      type: 'broadcast',
      region: 'eu',
      domain: 'raisport.rai.it',
    ),
    IntlBroadcastChannel(
      id: 'movistar_plus',
      name: 'Movistar+',
      type: 'streaming',
      region: 'eu',
      domain: 'movistarplus.es',
    ),
    // ── MENA ───────────────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'shahid',
      name: 'Shahid',
      type: 'streaming',
      region: 'ae',
      domain: 'shahid.mbc.net',
    ),
    IntlBroadcastChannel(
      id: 'starzplay',
      name: 'StarzPlay Arabia',
      type: 'streaming',
      region: 'ae',
      domain: 'starzplay.com',
    ),
    IntlBroadcastChannel(
      id: 'anghami_live',
      name: 'Anghami Live',
      type: 'social',
      region: 'ae',
      domain: 'anghami.com',
    ),
    IntlBroadcastChannel(
      id: 'bein_sports',
      name: 'beIN Sports',
      type: 'broadcast',
      region: 'ae',
      domain: 'beinsports.com',
    ),
    // ── LATAM ──────────────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'combate',
      name: 'Combate',
      type: 'broadcast',
      region: 'br',
      domain: 'combate.com',
    ),
    IntlBroadcastChannel(
      id: 'claro_video',
      name: 'Claro Video',
      type: 'streaming',
      region: 'mx',
      domain: 'clarovideo.com',
    ),
    IntlBroadcastChannel(
      id: 'directv_la',
      name: 'DirecTV LATAM',
      type: 'broadcast',
      region: 'ar',
      domain: 'directvla.com',
    ),
    IntlBroadcastChannel(
      id: 'espn_latam',
      name: 'ESPN LATAM',
      type: 'streaming',
      region: 'br',
      domain: 'espn.com.br',
    ),
    // ── North America ──────────────────────────────────────────────────────
    IntlBroadcastChannel(
      id: 'fite_tv',
      name: 'FITE TV',
      type: 'ppv',
      region: 'us',
      domain: 'fite.tv',
    ),
    IntlBroadcastChannel(
      id: 'tubi_sports',
      name: 'Tubi Sports',
      type: 'streaming',
      region: 'us',
      domain: 'tubi.tv',
    ),
    IntlBroadcastChannel(
      id: 'roku_channel',
      name: 'The Roku Channel',
      type: 'streaming',
      region: 'us',
      domain: 'therokuchannel.roku.com',
    ),
    IntlBroadcastChannel(
      id: 'peacock',
      name: 'Peacock Sports',
      type: 'streaming',
      region: 'us',
      domain: 'peacocktv.com',
    ),
  ];

  String _normalizeRegion(String value) {
    final raw = value.trim().toLowerCase();
    if (raw == 'in') return 'in_';
    if (raw == 'id') return 'id_';
    return raw;
  }

  String _normalizeChannel(String value) {
    final raw = value.trim().toLowerCase();
    if (raw == 'x') return 'twitter';
    return raw;
  }

  bool isSupportedChannel(String channel) {
    return _supportedChannelIds.contains(_normalizeChannel(channel));
  }

  bool isSupportedRegion(String region) {
    return _supportedRegions.contains(_normalizeRegion(region));
  }

  void _assertEventId(String eventId) {
    if (eventId.trim().isEmpty) {
      throw ArgumentError('eventId is required');
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MEDIA POOL
  // ═════════════════════════════════════════════════════════════════════════

  /// Stream all pooled assets for a given event.
  Stream<List<PoolAsset>> streamPoolAssets(String eventId) {
    return _db
        .collection(_mediaPoolsCol)
        .doc(eventId)
        .collection('assets')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PoolAsset.fromFirestore).toList())
        .handleError((_) => <PoolAsset>[]);
  }

  /// Register a new asset in the pool (after upload via MediaAssetUploadService).
  Future<void> registerPoolAsset({
    required String eventId,
    required String downloadUrl,
    required String storagePath,
    required String fileName,
    required PoolAssetType type,
    required int fileSizeBytes,
    String? notes,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final userDoc = await _db.collection(_usersCol).doc(uid).get();
    final uploaderName =
        (userDoc.data()?['displayName'] as String?) ?? 'Promoter';

    final asset = PoolAsset(
      id: '',
      eventId: eventId,
      uploaderId: uid,
      uploaderName: uploaderName,
      type: type,
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      uploadedAt: DateTime.now(),
      notes: notes,
    );

    await _db
        .collection(_mediaPoolsCol)
        .doc(eventId)
        .collection('assets')
        .add(asset.toFirestore());

    // Update pool metadata
    await _db.collection(_mediaPoolsCol).doc(eventId).set({
      'eventId': eventId,
      'ownerId': uid,
      'assetCount': FieldValue.increment(1),
      'totalBytes': FieldValue.increment(fileSizeBytes),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    notifyListeners();
  }

  /// Delete a pooled asset (owner or admin only enforced via Firestore rules).
  Future<void> deletePoolAsset(String eventId, PoolAsset asset) async {
    // Remove from Storage
    try {
      await _storage.ref(asset.storagePath).delete();
    } catch (_) {
      /* ignore missing file */
    }

    // Remove Firestore record
    await _db
        .collection(_mediaPoolsCol)
        .doc(eventId)
        .collection('assets')
        .doc(asset.id)
        .delete();

    // Decrement count
    await _db.collection(_mediaPoolsCol).doc(eventId).update({
      'assetCount': FieldValue.increment(-1),
      'totalBytes': FieldValue.increment(-asset.fileSizeBytes),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // COLLABORATORS
  // ═════════════════════════════════════════════════════════════════════════

  /// Stream collaborators added to an event pool.
  Stream<List<HubCollaborator>> streamCollaborators(String eventId) {
    return _db
        .collection(_mediaPoolsCol)
        .doc(eventId)
        .collection('members')
        .snapshots()
        .asyncMap((s) async {
          final results = <HubCollaborator>[];
          for (final doc in s.docs) {
            final userId = doc.id;
            final userDoc = await _db.collection(_usersCol).doc(userId).get();
            if (userDoc.exists) {
              results.add(HubCollaborator.fromFirestore(userDoc));
            }
          }
          return results;
        })
        .handleError((_) => <HubCollaborator>[]);
  }

  /// Add a collaborator to an event pool.
  Future<void> addCollaborator({
    required String eventId,
    required String userId,
    required String role,
  }) async {
    final me = currentUserId;
    if (me == null) throw Exception('Not authenticated');

    await _db
        .collection(_mediaPoolsCol)
        .doc(eventId)
        .collection('members')
        .doc(userId)
        .set({
          'addedBy': me,
          'role': role,
          'addedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Remove a collaborator from an event pool.
  Future<void> removeCollaborator({
    required String eventId,
    required String userId,
  }) async {
    await _db
        .collection(_mediaPoolsCol)
        .doc(eventId)
        .collection('members')
        .doc(userId)
        .delete();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DISTRIBUTION ACCOUNTING
  // ═════════════════════════════════════════════════════════════════════════

  /// Stream distribution runs for an event, newest first.
  Stream<List<DistributionRun>> streamDistributionRuns(String eventId) {
    if (eventId.trim().isEmpty) return Stream.value([]);
    return _db
        .collection(_distRunsCol)
        .where('eventId', isEqualTo: eventId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(DistributionRun.fromFirestore).toList())
        .handleError((_) => <DistributionRun>[]);
  }

  /// Log a distribution run (called when a channel publish is triggered).
  Future<String> logDistributionRun({
    required String eventId,
    required String channel,
    required String region,
    String? posterUrl,
    String? caption,
    int estimatedReachK = 0,
  }) async {
    _assertEventId(eventId);
    if (estimatedReachK < 0 || estimatedReachK > 100000) {
      throw ArgumentError('estimatedReachK must be between 0 and 100000');
    }

    final normalizedChannel = _normalizeChannel(channel);
    final normalizedRegion = _normalizeRegion(region);
    if (!isSupportedChannel(normalizedChannel)) {
      throw ArgumentError('Unsupported channel: $channel');
    }
    if (!isSupportedRegion(normalizedRegion)) {
      throw ArgumentError('Unsupported region: $region');
    }

    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final now = DateTime.now();

    final run = DistributionRun(
      id: '',
      eventId: eventId,
      promoterId: uid,
      channel: normalizedChannel,
      region: normalizedRegion,
      status: 'queued',
      estimatedReachK: estimatedReachK,
      createdAt: now,
      posterUrl: posterUrl,
      caption: caption,
    );

    final ref = await _db.collection(_distRunsCol).add(run.toFirestore());

    // Update channel config counters
    await _db
        .collection(_channelConfigsCol)
        .doc('${uid}_$normalizedChannel')
        .set({
          'channelId': normalizedChannel,
          'promoterId': uid,
          'totalSent': FieldValue.increment(1),
          'lastSentAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    notifyListeners();
    return ref.id;
  }

  /// Mark a distribution run as sent with actual reach data.
  Future<void> markRunSent({
    required String runId,
    required int actualReachK,
    int revenueCents = 0,
  }) async {
    if (runId.trim().isEmpty) throw ArgumentError('runId is required');
    if (actualReachK < 0) throw ArgumentError('actualReachK must be >= 0');
    if (revenueCents < 0) throw ArgumentError('revenueCents must be >= 0');

    await _db.collection(_distRunsCol).doc(runId).update({
      'status': 'sent',
      'actualReachK': actualReachK,
      'revenueCents': revenueCents,
      'sentAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  /// Mark a run as failed.
  Future<void> markRunFailed(String runId, String errorMessage) async {
    if (runId.trim().isEmpty) throw ArgumentError('runId is required');
    await _db.collection(_distRunsCol).doc(runId).update({
      'status': 'failed',
      'errorMessage': errorMessage,
    });
    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CHANNEL CONFIGS
  // ═════════════════════════════════════════════════════════════════════════

  /// Stream all channel configs for the current promoter.
  Stream<List<DistributionChannelConfig>> streamChannelConfigs() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection(_channelConfigsCol)
        .where('promoterId', isEqualTo: uid)
        .snapshots()
        .map(
          (s) => s.docs.map(DistributionChannelConfig.fromFirestore).toList(),
        )
        .handleError((_) => <DistributionChannelConfig>[]);
  }

  /// Toggle a channel on/off.
  Future<void> setChannelEnabled({
    required String channel,
    required bool enabled,
    List<String>? activeRegions,
  }) async {
    final normalizedChannel = _normalizeChannel(channel);
    if (!isSupportedChannel(normalizedChannel)) {
      throw ArgumentError('Unsupported channel: $channel');
    }

    final uid = currentUserId;
    if (uid == null) throw Exception('Not authenticated');

    final regions = activeRegions
        ?.map(_normalizeRegion)
        .where(_supportedRegions.contains)
        .toSet()
        .toList();

    await _db
        .collection(_channelConfigsCol)
        .doc('${uid}_$normalizedChannel')
        .set({
          'channelId': normalizedChannel,
          'promoterId': uid,
          'enabled': enabled,
          'activeRegions': ?regions,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    notifyListeners();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // REVENUE SETTLEMENT
  // ═════════════════════════════════════════════════════════════════════════

  /// Build revenue lines from distribution runs for an event.
  Future<List<ChannelRevenueLine>> getRevenueLines(String eventId) async {
    try {
      final snap = await _db
          .collection(_distRunsCol)
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'sent')
          .get();

      final map = <String, ChannelRevenueLine>{};
      for (final doc in snap.docs) {
        final run = DistributionRun.fromFirestore(doc);
        final key = '${run.channel}_${run.region}';
        final existing = map[key];
        if (existing == null) {
          map[key] = ChannelRevenueLine(
            channel: run.channel,
            region: run.region,
            salesCount: run.revenueCents > 0 ? 1 : 0,
            grossRevenueCents: run.revenueCents,
            platformFeeCents: (run.revenueCents * 0.15).round(),
            promoterShareCents: (run.revenueCents * 0.85).round(),
          );
        } else {
          map[key] = ChannelRevenueLine(
            channel: existing.channel,
            region: existing.region,
            salesCount: existing.salesCount + (run.revenueCents > 0 ? 1 : 0),
            grossRevenueCents: existing.grossRevenueCents + run.revenueCents,
            platformFeeCents:
                ((existing.grossRevenueCents + run.revenueCents) * 0.15)
                    .round(),
            promoterShareCents:
                ((existing.grossRevenueCents + run.revenueCents) * 0.85)
                    .round(),
          );
        }
      }

      return map.values.toList()
        ..sort((a, b) => b.grossRevenueCents.compareTo(a.grossRevenueCents));
    } catch (_) {
      return [];
    }
  }

  /// Aggregate total distribution stats for an event.
  Future<Map<String, int>> getEventDistributionStats(String eventId) async {
    try {
      final snap = await _db
          .collection(_distRunsCol)
          .where('eventId', isEqualTo: eventId)
          .get();

      int totalSent = 0, totalReach = 0, totalRevenue = 0, totalFailed = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final status = d['status'] ?? '';
        if (status == 'sent') {
          totalSent++;
          totalReach += (d['actualReachK'] as int? ?? 0);
          totalRevenue += (d['revenueCents'] as int? ?? 0);
        } else if (status == 'failed') {
          totalFailed++;
        }
      }

      return {
        'totalSent': totalSent,
        'totalReachK': totalReach,
        'totalRevenueCents': totalRevenue,
        'totalFailed': totalFailed,
      };
    } catch (_) {
      return {};
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // DEMO FALLBACK
  // ═════════════════════════════════════════════════════════════════════════

  List<DistributionRun> get demoRuns => [
    DistributionRun(
      id: 'demo-1',
      eventId: 'demo',
      promoterId: 'demo',
      channel: 'instagram',
      region: 'au',
      status: 'sent',
      estimatedReachK: 45,
      actualReachK: 48,
      revenueCents: 189900,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      sentAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    DistributionRun(
      id: 'demo-2',
      eventId: 'demo',
      promoterId: 'demo',
      channel: 'facebook',
      region: 'au',
      status: 'sent',
      estimatedReachK: 30,
      actualReachK: 29,
      revenueCents: 99900,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      sentAt: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    DistributionRun(
      id: 'demo-3',
      eventId: 'demo',
      promoterId: 'demo',
      channel: 'youtube',
      region: 'global',
      status: 'sent',
      estimatedReachK: 80,
      actualReachK: 91,
      revenueCents: 349900,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      sentAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    DistributionRun(
      id: 'demo-4',
      eventId: 'demo',
      promoterId: 'demo',
      channel: 'dfc',
      region: 'au',
      status: 'sent',
      estimatedReachK: 12,
      actualReachK: 14,
      revenueCents: 559800,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      sentAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    DistributionRun(
      id: 'demo-5',
      eventId: 'demo',
      promoterId: 'demo',
      channel: 'tiktok',
      region: 'ph',
      status: 'queued',
      estimatedReachK: 120,
      createdAt: DateTime.now(),
    ),
  ];

  List<PoolAsset> get demoAssets => [
    PoolAsset(
      id: 'a1',
      eventId: 'demo',
      uploaderId: 'u1',
      uploaderName: 'Heath (Promoter)',
      type: PoolAssetType.poster,
      fileName: 'dfc_poster_hero.webp',
      downloadUrl: 'https://placehold.co/1080x1350',
      storagePath: 'event_pools/demo/poster/dfc_poster_hero.webp',
      fileSizeBytes: 340000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PoolAsset(
      id: 'a2',
      eventId: 'demo',
      uploaderId: 'u1',
      uploaderName: 'Heath (Promoter)',
      type: PoolAssetType.fightCard,
      fileName: 'fight_card_main.webp',
      downloadUrl: 'https://placehold.co/1080x1080',
      storagePath: 'event_pools/demo/fightCard/fight_card_main.webp',
      fileSizeBytes: 215000,
      uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PoolAsset(
      id: 'a3',
      eventId: 'demo',
      uploaderId: 'u2',
      uploaderName: 'Jordan (Photographer)',
      type: PoolAssetType.clip,
      fileName: 'promo_clip_60s.mp4',
      downloadUrl: 'https://placehold.co/1920x1080',
      storagePath: 'event_pools/demo/clip/promo_clip_60s.mp4',
      fileSizeBytes: 14500000,
      uploadedAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
  ];

  List<HubCollaborator> get demoCollaborators => const [
    HubCollaborator(
      userId: 'c1',
      displayName: 'Jordan Roesler',
      role: 'fighter',
      isOnline: true,
    ),
    HubCollaborator(
      userId: 'c2',
      displayName: 'Joey Demicoli',
      role: 'manager',
    ),
    HubCollaborator(
      userId: 'c3',
      displayName: 'DFC Media Team',
      role: 'media',
      isOnline: true,
    ),
  ];
}
