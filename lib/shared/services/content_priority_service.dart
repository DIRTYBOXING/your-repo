import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// CONTENT PRIORITY SERVICE — Facebook-Style Admin Content Controls
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Professional social media content management:
///  - Pin posts / events / news to top of feeds
///  - Boost content visibility (priority score)
///  - Schedule featured content windows
///  - Admin-only controls for content ordering
///  - Auto-expire pinned content after set duration
///  - Content state management (draft → published → archived)
///
/// Firestore collection: `content_priority`
/// ═══════════════════════════════════════════════════════════════════════════

enum ContentType { post, event, news, video, promotion, announcement }

enum ContentState { draft, scheduled, published, pinned, archived, removed }

enum PriorityLevel { normal, elevated, high, featured, pinned }

class PrioritizedContent {
  final String id;
  final String contentId;
  final ContentType type;
  final ContentState state;
  final PriorityLevel priority;
  final String? pinnedBy; // admin uid
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? expiresAt;
  final double boostScore; // 0.0 – 1.0
  final String? note; // admin note
  final Map<String, dynamic> metadata;

  const PrioritizedContent({
    required this.id,
    required this.contentId,
    required this.type,
    this.state = ContentState.published,
    this.priority = PriorityLevel.normal,
    this.pinnedBy,
    required this.createdAt,
    this.scheduledFor,
    this.expiresAt,
    this.boostScore = 0.0,
    this.note,
    this.metadata = const {},
  });

  bool get isPinned => priority == PriorityLevel.pinned;
  bool get isFeatured =>
      priority == PriorityLevel.featured || priority == PriorityLevel.pinned;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isScheduled =>
      scheduledFor != null && DateTime.now().isBefore(scheduledFor!);
  bool get isActive =>
      state == ContentState.published || state == ContentState.pinned;

  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'type': type.name,
    'state': state.name,
    'priority': priority.name,
    'pinnedBy': pinnedBy,
    'createdAt': Timestamp.fromDate(createdAt),
    'scheduledFor': scheduledFor != null
        ? Timestamp.fromDate(scheduledFor!)
        : null,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'boostScore': boostScore,
    'note': note,
    'metadata': metadata,
  };

  factory PrioritizedContent.fromMap(String id, Map<String, dynamic> map) {
    return PrioritizedContent(
      id: id,
      contentId: map['contentId'] as String? ?? '',
      type: ContentType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'post'),
        orElse: () => ContentType.post,
      ),
      state: ContentState.values.firstWhere(
        (s) => s.name == (map['state'] as String? ?? 'published'),
        orElse: () => ContentState.published,
      ),
      priority: PriorityLevel.values.firstWhere(
        (p) => p.name == (map['priority'] as String? ?? 'normal'),
        orElse: () => PriorityLevel.normal,
      ),
      pinnedBy: map['pinnedBy'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledFor: (map['scheduledFor'] as Timestamp?)?.toDate(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      boostScore: (map['boostScore'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String?,
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map<dynamic, dynamic>? ?? {},
      ),
    );
  }
}

class ContentPriorityService extends ChangeNotifier {
  ContentPriorityService._();
  static final ContentPriorityService _instance = ContentPriorityService._();
  factory ContentPriorityService() => _instance;

  final _firestore = FirebaseFirestore.instance;
  static const _collection = 'content_priority';

  final List<PrioritizedContent> _items = [];
  Timer? _expiryTimer;

  List<PrioritizedContent> get allItems => List.unmodifiable(_items);
  List<PrioritizedContent> get activeItems => _items
      .where((i) => i.isActive && !i.isExpired && !i.isScheduled)
      .toList();
  List<PrioritizedContent> get pinnedItems =>
      activeItems.where((i) => i.isPinned).toList();
  List<PrioritizedContent> get featuredItems =>
      activeItems.where((i) => i.isFeatured).toList();

  /// Initialize — load from Firestore and start expiry checks
  Future<void> initialize() async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      _items.clear();
      for (final doc in snap.docs) {
        _items.add(PrioritizedContent.fromMap(doc.id, doc.data()));
      }
      _cleanExpired();
      _startExpiryTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('[ContentPriority] Init error: $e');
    }
  }

  /// Stream of pinned content (real-time)
  Stream<List<PrioritizedContent>> pinnedStream() {
    return _firestore
        .collection(_collection)
        .where('priority', isEqualTo: 'pinned')
        .where('state', whereIn: ['published', 'pinned'])
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PrioritizedContent.fromMap(d.id, d.data()))
              .where((p) => !p.isExpired)
              .toList(),
        );
  }

  // ── Admin Actions ─────────────────────────────────────────────────────

  /// Pin content to top of feed (admin only)
  Future<bool> pinContent({
    required String contentId,
    required ContentType type,
    required String adminId,
    Duration duration = const Duration(hours: 24),
    String? note,
  }) async {
    try {
      final doc = _firestore.collection(_collection).doc();
      final item = PrioritizedContent(
        id: doc.id,
        contentId: contentId,
        type: type,
        state: ContentState.pinned,
        priority: PriorityLevel.pinned,
        pinnedBy: adminId,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(duration),
        boostScore: 1.0,
        note: note,
      );
      await doc.set(item.toMap());
      _items.insert(0, item);
      notifyListeners();
      debugPrint('[ContentPriority] Pinned: $contentId (${type.name})');
      return true;
    } catch (e) {
      debugPrint('[ContentPriority] Pin error: $e');
      return false;
    }
  }

  /// Boost content visibility (raises it in feed ranking)
  Future<bool> boostContent({
    required String contentId,
    required ContentType type,
    required String adminId,
    double boostScore = 0.8,
    Duration duration = const Duration(hours: 12),
  }) async {
    try {
      final doc = _firestore.collection(_collection).doc();
      final item = PrioritizedContent(
        id: doc.id,
        contentId: contentId,
        type: type,
        priority: PriorityLevel.elevated,
        pinnedBy: adminId,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(duration),
        boostScore: boostScore,
      );
      await doc.set(item.toMap());
      _items.add(item);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ContentPriority] Boost error: $e');
      return false;
    }
  }

  /// Schedule content to go live at a future time
  Future<bool> scheduleContent({
    required String contentId,
    required ContentType type,
    required String adminId,
    required DateTime goLiveAt,
    Duration? activeDuration,
  }) async {
    try {
      final doc = _firestore.collection(_collection).doc();
      final item = PrioritizedContent(
        id: doc.id,
        contentId: contentId,
        type: type,
        state: ContentState.scheduled,
        priority: PriorityLevel.featured,
        pinnedBy: adminId,
        createdAt: DateTime.now(),
        scheduledFor: goLiveAt,
        expiresAt: activeDuration != null ? goLiveAt.add(activeDuration) : null,
        boostScore: 0.9,
      );
      await doc.set(item.toMap());
      _items.add(item);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ContentPriority] Schedule error: $e');
      return false;
    }
  }

  /// Unpin / remove priority from content
  Future<bool> unpinContent(String priorityId) async {
    try {
      await _firestore.collection(_collection).doc(priorityId).update({
        'state': ContentState.archived.name,
        'priority': PriorityLevel.normal.name,
      });
      _items.removeWhere((i) => i.id == priorityId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ContentPriority] Unpin error: $e');
      return false;
    }
  }

  /// Archive content (soft delete)
  Future<bool> archiveContent(String priorityId) async {
    return unpinContent(priorityId);
  }

  /// Get priority score for a given content item (used by feed ranking)
  double getPriorityScore(String contentId) {
    final matches = activeItems.where((i) => i.contentId == contentId);
    if (matches.isEmpty) return 0.0;
    return matches.map((i) => i.boostScore).reduce((a, b) => a > b ? a : b);
  }

  /// Check if content is pinned
  bool isContentPinned(String contentId) {
    return pinnedItems.any((i) => i.contentId == contentId);
  }

  /// Sort a list of items by priority (pinned first, then boosted, then normal)
  List<T> sortByPriority<T>(List<T> items, String Function(T) getId) {
    final sorted = List<T>.from(items);
    sorted.sort((a, b) {
      final scoreA = getPriorityScore(getId(a));
      final scoreB = getPriorityScore(getId(b));
      return scoreB.compareTo(scoreA);
    });
    return sorted;
  }

  // ── Internal ──────────────────────────────────────────────────────────

  void _cleanExpired() {
    _items.removeWhere((i) => i.isExpired);
  }

  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final before = _items.length;
      _cleanExpired();
      if (_items.length != before) {
        notifyListeners();
        debugPrint(
          '[ContentPriority] Cleaned ${before - _items.length} expired items',
        );
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    super.dispose();
  }
}
