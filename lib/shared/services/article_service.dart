import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/news_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ARTICLE SERVICE — CRUD for feed_content articles
///
/// Reads/writes to Firestore `feed_content` collection.
/// Supports viewing, liking, sharing, and seeding editorial content.
/// ═══════════════════════════════════════════════════════════════════════════
class ArticleService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const _collection = 'feed_content';

  // ── Single article by ID ──────────────────────────────────────────────
  Future<NewsModel?> getArticle(String articleId) async {
    try {
      final doc = await _db.collection(_collection).doc(articleId).get();
      if (!doc.exists) return null;
      return NewsModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('ArticleService.getArticle error: $e');
      return null;
    }
  }

  // ── Published articles stream (newest first) ──────────────────────────
  Stream<List<NewsModel>> articlesStream({
    int limit = 20,
    String? category,
    bool featuredOnly = false,
  }) {
    Query<Map<String, dynamic>> q = _db
        .collection(_collection)
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(limit);

    if (category != null && category.isNotEmpty) {
      q = q.where('categories', arrayContains: category);
    }
    if (featuredOnly) {
      q = q.where('isFeatured', isEqualTo: true);
    }

    return q.snapshots().map(
      (snap) => snap.docs.map(NewsModel.fromFirestore).toList(),
    );
  }

  // ── Increment view count ──────────────────────────────────────────────
  Future<void> recordView(String articleId) async {
    try {
      await _db.collection(_collection).doc(articleId).update({
        'viewsCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('ArticleService.recordView error: $e');
    }
  }

  // ── Like / unlike ─────────────────────────────────────────────────────
  Future<void> toggleLike(String articleId, String userId) async {
    final likeRef = _db
        .collection(_collection)
        .doc(articleId)
        .collection('likes')
        .doc(userId);
    final snap = await likeRef.get();
    if (snap.exists) {
      await likeRef.delete();
      await _db.collection(_collection).doc(articleId).update({
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      await _db.collection(_collection).doc(articleId).update({
        'likesCount': FieldValue.increment(1),
      });
    }
  }

  Future<bool> hasLiked(String articleId, String userId) async {
    final snap = await _db
        .collection(_collection)
        .doc(articleId)
        .collection('likes')
        .doc(userId)
        .get();
    return snap.exists;
  }

  // ── Share count increment ─────────────────────────────────────────────
  Future<void> recordShare(String articleId) async {
    try {
      await _db.collection(_collection).doc(articleId).update({
        'sharesCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('ArticleService.recordShare error: $e');
    }
  }

  // ── Seed an article (used for editorial content) ──────────────────────
  Future<String> publishArticle({
    required String title,
    required String summary,
    required String content,
    String? featuredImageUrl,
    List<String> mediaUrls = const [],
    List<String> tags = const [],
    List<String> categories = const [],
    String? sourceUrl,
    String authorId = 'dfc_editorial',
    String authorName = 'DFC FightMedia',
    bool isFeatured = false,
    bool isBreaking = false,
    List<String> relatedFighterIds = const [],
    List<String> relatedEventIds = const [],
  }) async {
    final readTime = NewsModel.calculateReadTime(content);
    final now = DateTime.now();

    final model = NewsModel(
      id: '',
      authorId: authorId,
      title: title,
      summary: summary,
      content: content,
      featuredImageUrl: featuredImageUrl,
      mediaUrls: mediaUrls,
      tags: tags,
      categories: categories,
      sourceUrl: sourceUrl,
      sourceName: 'Data Fight Central',
      relatedFighterIds: relatedFighterIds,
      relatedEventIds: relatedEventIds,
      isFeatured: isFeatured,
      isBreakingNews: isBreaking,
      isPublished: true,
      publishedAt: now,
      readTime: readTime,
      createdAt: now,
      updatedAt: now,
    );

    final doc = await _db.collection(_collection).add(model.toFirestore());
    return doc.id;
  }
}
