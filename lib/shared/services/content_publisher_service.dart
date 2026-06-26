import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// DFC CONTENT PUBLISHER SERVICE
// ═══════════════════════════════════════════════════════════════════════════════
// Allows admin/promoter to publish content directly to Firestore from within
// the app. No code changes, no redeployment, no logging out users.
// Collections: news_articles, events, posts, ppv_events, fight_show_cards
// ═══════════════════════════════════════════════════════════════════════════════

/// Types of content that can be published
enum DfcContentType { news, fightShow, post, event, ppv, signal }

/// A published content item stored in Firestore
class PublishedContent {
  final String id;
  final DfcContentType type;
  final String title;
  final String body;
  final String? imageUrl;
  final String? promotion;
  final String? location;
  final String? date;
  final String? mainEvent;
  final String? broadcastInfo;
  final String? ticketUrl;
  final String? sportType;
  final int? fightCount;
  final bool isFeatured;
  final bool isBreaking;
  final bool isPublished;
  final String authorId;
  final String authorName;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? publishedAt;

  const PublishedContent({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.promotion,
    this.location,
    this.date,
    this.mainEvent,
    this.broadcastInfo,
    this.ticketUrl,
    this.sportType,
    this.fightCount,
    this.isFeatured = false,
    this.isBreaking = false,
    this.isPublished = true,
    required this.authorId,
    required this.authorName,
    this.metadata,
    required this.createdAt,
    this.publishedAt,
  });

  factory PublishedContent.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PublishedContent(
      id: doc.id,
      type: DfcContentType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'post'),
        orElse: () => DfcContentType.post,
      ),
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      imageUrl: d['imageUrl'],
      promotion: d['promotion'],
      location: d['location'],
      date: d['date'],
      mainEvent: d['mainEvent'],
      broadcastInfo: d['broadcastInfo'],
      ticketUrl: d['ticketUrl'],
      sportType: d['sportType'],
      fightCount: d['fightCount'],
      isFeatured: d['isFeatured'] ?? false,
      isBreaking: d['isBreaking'] ?? false,
      isPublished: d['isPublished'] ?? true,
      authorId: d['authorId'] ?? '',
      authorName: d['authorName'] ?? '',
      metadata: d['metadata'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      publishedAt: (d['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type': type.name,
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
    'promotion': promotion,
    'location': location,
    'date': date,
    'mainEvent': mainEvent,
    'broadcastInfo': broadcastInfo,
    'ticketUrl': ticketUrl,
    'sportType': sportType,
    'fightCount': fightCount,
    'isFeatured': isFeatured,
    'isBreaking': isBreaking,
    'isPublished': isPublished,
    'authorId': authorId,
    'authorName': authorName,
    'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt),
    'publishedAt': publishedAt != null
        ? Timestamp.fromDate(publishedAt!)
        : null,
  };
}

class ContentPublisherService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _collection = 'dfc_content';

  List<PublishedContent> _items = [];
  List<PublishedContent> get items => _items;
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  // ── CREATE ──────────────────────────────────────────────────────────────

  /// Publish new content to Firestore. Instantly visible to all users.
  Future<PublishedContent?> publish(PublishedContent content) async {
    try {
      final ref = _db.collection(_collection).doc();
      final item = PublishedContent(
        id: ref.id,
        type: content.type,
        title: content.title,
        body: content.body,
        imageUrl: content.imageUrl,
        promotion: content.promotion,
        location: content.location,
        date: content.date,
        mainEvent: content.mainEvent,
        broadcastInfo: content.broadcastInfo,
        ticketUrl: content.ticketUrl,
        sportType: content.sportType,
        fightCount: content.fightCount,
        isFeatured: content.isFeatured,
        isBreaking: content.isBreaking,
        authorId: content.authorId,
        authorName: content.authorName,
        metadata: content.metadata,
        createdAt: DateTime.now(),
        publishedAt: DateTime.now(),
      );
      await ref.set(item.toFirestore());
      _items.insert(0, item);
      notifyListeners();

      // Also write to the canonical collection for the content type
      await _crossPublish(item);

      return item;
    } catch (e) {
      _error = 'Failed to publish: $e';
      notifyListeners();
      return null;
    }
  }

  /// Cross-publish to the canonical Firestore collection so existing screens
  /// (social feed, events, fightwire, news) pick it up automatically.
  Future<void> _crossPublish(PublishedContent item) async {
    try {
      switch (item.type) {
        case DfcContentType.news:
          await _db.collection('news_articles').doc(item.id).set({
            'authorId': item.authorId,
            'title': item.title,
            'summary': item.body.length > 200
                ? '${item.body.substring(0, 200)}...'
                : item.body,
            'content': item.body,
            'featuredImageUrl': item.imageUrl,
            'tags': [],
            'categories': ['fight-news'],
            'isFeatured': item.isFeatured,
            'isBreakingNews': item.isBreaking,
            'isPublished': true,
            'publishedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'viewsCount': 0,
            'likesCount': 0,
            'commentsCount': 0,
            'sharesCount': 0,
          });
          break;

        case DfcContentType.event:
        case DfcContentType.fightShow:
          await _db.collection('events').doc(item.id).set({
            'promoterId': item.authorId,
            'name': item.title,
            'description': item.body,
            'venue': item.location ?? '',
            'city': _extractCity(item.location),
            'country': 'Australia',
            'eventDate': item.date != null
                ? Timestamp.fromDate(
                    DateTime.tryParse(item.date!) ?? DateTime.now(),
                  )
                : Timestamp.now(),
            'sportType': item.sportType ?? 'boxing',
            'status': 'upcoming',
            'isFeatured': item.isFeatured,
            'broadcastInfo': item.broadcastInfo ?? '',
            'ticketUrl': item.ticketUrl ?? '',
            'posterUrl': item.imageUrl ?? '',
            'fightIds': [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          break;

        case DfcContentType.post:
          await _db.collection('posts').doc(item.id).set({
            'userId': item.authorId,
            'content': '${item.title}\n\n${item.body}',
            'userDisplayName': item.authorName,
            'userRole': 'promoter',
            'postType': 'text',
            'mediaUrls': item.imageUrl != null ? [item.imageUrl] : <String>[],
            'likes': 0,
            'likedBy': <String>[],
            'bookmarkedBy': <String>[],
            'commentCount': 0,
            'shareCount': 0,
            'location': item.location ?? '',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          break;

        case DfcContentType.signal:
          // Fightwire signals go into posts with a special metadata tag
          await _db.collection('posts').doc(item.id).set({
            'userId': item.authorId,
            'content': '⚡ SIGNAL: ${item.title}\n\n${item.body}',
            'userDisplayName': item.authorName,
            'userRole': 'admin',
            'postType': 'signal',
            'mediaUrls': item.imageUrl != null ? [item.imageUrl] : <String>[],
            'likes': 0,
            'likedBy': <String>[],
            'bookmarkedBy': <String>[],
            'commentCount': 0,
            'shareCount': 0,
            'location': item.location ?? '',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          break;

        case DfcContentType.ppv:
          await _db.collection('ppv_events').doc(item.id).set({
            'eventId': item.id,
            'promoterId': item.authorId,
            'title': item.title,
            'subtitle': item.mainEvent ?? '',
            'description': item.body,
            'posterUrl': item.imageUrl ?? '',
            'eventDate': item.date != null
                ? Timestamp.fromDate(
                    DateTime.tryParse(item.date!) ?? DateTime.now(),
                  )
                : Timestamp.now(),
            'status': 'announced',
            'standardPriceCents': 2499,
            'currency': 'AUD',
            'streamPlatforms': ['DFC'],
            'purchaseCount': 0,
            'chatEnabled': true,
            'predictionsEnabled': true,
            'fightCard': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
          break;
      }
    } catch (e) {
      debugPrint('Cross-publish to ${item.type.name} failed: $e');
    }
  }

  String _extractCity(String? location) {
    if (location == null || location.isEmpty) return '';
    final parts = location.split(',');
    return parts.first.trim();
  }

  // ── READ ────────────────────────────────────────────────────────────────

  /// Load all published content (most recent first)
  Future<void> loadAll({DfcContentType? filterType}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      Query query = _db
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .limit(100);

      if (filterType != null) {
        query = query.where('type', isEqualTo: filterType.name);
      }

      final snap = await query.get();
      _items = snap.docs.map(PublishedContent.fromFirestore).toList();
    } catch (e) {
      _error = 'Failed to load content: $e';
    }

    _loading = false;
    notifyListeners();
  }

  /// Stream published content in real-time
  Stream<List<PublishedContent>> streamContent({DfcContentType? filterType}) {
    Query query = _db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(50);

    if (filterType != null) {
      query = query.where('type', isEqualTo: filterType.name);
    }

    return query.snapshots().map(
      (snap) =>
          snap.docs.map(PublishedContent.fromFirestore).toList(),
    );
  }

  // ── UPDATE ──────────────────────────────────────────────────────────────

  Future<bool> update(String contentId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection(_collection).doc(contentId).update(updates);
      await loadAll();
      return true;
    } catch (e) {
      _error = 'Failed to update: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle featured status
  Future<bool> toggleFeatured(String contentId, bool featured) {
    return update(contentId, {'isFeatured': featured});
  }

  /// Toggle published/draft
  Future<bool> togglePublished(String contentId, bool published) {
    return update(contentId, {'isPublished': published});
  }

  // ── DELETE ──────────────────────────────────────────────────────────────

  Future<bool> delete(String contentId) async {
    try {
      await _db.collection(_collection).doc(contentId).delete();
      _items.removeWhere((c) => c.id == contentId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete: $e';
      notifyListeners();
      return false;
    }
  }
}
