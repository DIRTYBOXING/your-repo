import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/media_library_item.dart';

/// A single entry in the ingestion audit log.
class IngestionLogEntry {
  final String id;
  final DateTime timestamp;
  final String platform;
  final int itemsIngested;
  final List<String> errors;

  const IngestionLogEntry({
    required this.id,
    required this.timestamp,
    required this.platform,
    required this.itemsIngested,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;

  factory IngestionLogEntry.fromMap(String id, Map<String, dynamic> d) {
    return IngestionLogEntry(
      id: id,
      timestamp: d['timestamp'] != null
          ? (d['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      platform: d['platform'] as String? ?? '',
      itemsIngested: d['itemsIngested'] as int? ?? 0,
      errors: List<String>.from(d['errors'] ?? []),
    );
  }
}

/// IngestionService — pulls content from official platform APIs (or demo stubs),
/// deduplicates, writes to `media_library`, and logs to `ingestion_logs`.
///
/// All Firestore writes are wrapped in try/catch so the service is safe in
/// WEB_DEMO_MODE when Firestore may be mocked or unavailable.
class IngestionService {
  static final IngestionService _instance = IngestionService._internal();
  factory IngestionService() => _instance;
  IngestionService._internal();

  static const List<String> supportedPlatforms = [
    'facebook',
    'instagram',
    'youtube',
    'tiktok',
    'whatsapp',
  ];

  // ── Platform ingestion entry points ─────────────────────────────────────────

  Future<int> ingestFacebook() => _ingestPlatform('facebook');
  Future<int> ingestInstagram() => _ingestPlatform('instagram');
  Future<int> ingestYouTube() => _ingestPlatform('youtube');
  Future<int> ingestTikTok() => _ingestPlatform('tiktok');
  Future<int> ingestWhatsApp() => _ingestPlatform('whatsapp');

  /// Ingests all enabled platforms sequentially.
  /// Returns total items written across all platforms.
  Future<int> ingestAll() async {
    int total = 0;
    for (final p in supportedPlatforms) {
      total += await _ingestPlatform(p);
    }
    return total;
  }

  // ── Internal ingestion logic ─────────────────────────────────────────────────

  Future<int> _ingestPlatform(String platform) async {
    // 1. Check if platform ingestion is enabled in distribution_settings
    bool enabled = false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('distribution_settings')
          .doc(platform)
          .get();
      enabled = doc.exists ? (doc.data()?['enabled'] as bool? ?? false) : false;
    } catch (_) {
      // Demo mode — treat as enabled for demo platforms
      enabled = ['facebook', 'instagram', 'youtube'].contains(platform);
    }

    if (!enabled) return 0;

    // 2. Generate demo items (replace with real API calls in production)
    final items = _generateDemoItems(platform, count: 3);

    // 3. Write new items to media_library (skipping duplicates by ID)
    int written = 0;
    for (final item in items) {
      try {
        final ref = FirebaseFirestore.instance
            .collection('media_library')
            .doc(item.id);
        final snap = await ref.get();
        if (!snap.exists) {
          await ref.set({
            ...item.toMap(),
            'syncedAt': FieldValue.serverTimestamp(),
          });
          written++;
        }
      } catch (_) {
        // Demo mode — count as written without Firestore
        written++;
      }
    }

    // 4. Log the ingestion
    await _logIngestion(platform, written, errors: []);
    return written;
  }

  // ── Ingestion log ────────────────────────────────────────────────────────────

  Future<void> _logIngestion(
    String platform,
    int itemsIngested, {
    List<String> errors = const [],
  }) async {
    try {
      await FirebaseFirestore.instance.collection('ingestion_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'platform': platform,
        'itemsIngested': itemsIngested,
        'errors': errors,
      });
    } catch (_) {
      // Ignore in demo mode
    }
  }

  Future<List<IngestionLogEntry>> getRecentLogs({int limit = 20}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('ingestion_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => IngestionLogEntry.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return _demoLogs;
    }
  }

  static final List<IngestionLogEntry> _demoLogs = [
    IngestionLogEntry(
      id: 'i1',
      timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      platform: 'instagram',
      itemsIngested: 3,
      errors: [],
    ),
    IngestionLogEntry(
      id: 'i2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      platform: 'facebook',
      itemsIngested: 3,
      errors: [],
    ),
    IngestionLogEntry(
      id: 'i3',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
      platform: 'youtube',
      itemsIngested: 2,
      errors: [],
    ),
    IngestionLogEntry(
      id: 'i4',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      platform: 'instagram',
      itemsIngested: 3,
      errors: ['Thumbnail unavailable'],
    ),
    IngestionLogEntry(
      id: 'i5',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      platform: 'facebook',
      itemsIngested: 3,
      errors: [],
    ),
  ];

  // ── Demo item generation ─────────────────────────────────────────────────────

  List<MediaLibraryItem> _generateDemoItems(
    String platform, {
    required int count,
  }) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final id = '${platform}_demo_${now.millisecondsSinceEpoch}_$i';
      return MediaLibraryItem(
        id: id,
        mediaUrl: 'https://dfc.placeholder/$platform/$id',
        thumbnailUrl: 'https://dfc.placeholder/$platform/thumb_$id',
        caption: _demoCaption(platform, i),
        postedAt: now.subtract(Duration(hours: i * 2)),
        engagement: 1000 + (i * 150),
        platform: platform,
        tags: _demoTags(platform),
        type: _demoType(platform),
      );
    });
  }

  String _demoCaption(String platform, int i) {
    const captions = [
      '🥊 DFC LIVE — Knockout of the night!',
      '🔥 The fighter everyone is talking about.',
      '💥 Behind the scenes: fight week grind.',
    ];
    return captions[i % captions.length];
  }

  List<String> _demoTags(String platform) {
    const base = ['mma', 'dfc', 'combat'];
    final extra = {
      'facebook': ['reel'],
      'instagram': ['reel'],
      'youtube': ['short'],
      'tiktok': ['viral'],
    };
    return [...base, ...(extra[platform] ?? [])];
  }

  String _demoType(String platform) {
    return {
          'youtube': 'video',
          'tiktok': 'reel',
          'instagram': 'reel',
        }[platform] ??
        'post';
  }

  // ── Convenience: recent ingested items from Firestore ───────────────────────

  Future<List<MediaLibraryItem>> getRecentItems({int limit = 20}) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('media_library')
          .orderBy('syncedAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => MediaLibraryItem.fromMap(d.data())).toList();
    } catch (_) {
      return [];
    }
  }
}
