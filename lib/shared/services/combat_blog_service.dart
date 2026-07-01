import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dfc_article_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// COMBAT BLOG SERVICE — Editorial pipeline for curated DFC content
///
/// Uses DfcArticleModel with full editorial lifecycle:
///   draftAi → draftManual → published → archived
///
/// Collection: dfc_articles
/// ═══════════════════════════════════════════════════════════════════════════
class CombatBlogService {
  CombatBlogService._();
  static final CombatBlogService instance = CombatBlogService._();

  final _col = FirebaseFirestore.instance.collection('dfc_articles');

  // ─── READ ────────────────────────────────────────────────────────────

  /// Stream of published articles, newest first.
  Stream<List<DfcArticleModel>> publishedStream({
    int limit = 20,
    DfcArticleType? type,
    String? tag,
  }) {
    Query q = _col
        .where('isPublished', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(limit);

    if (type != null) {
      q = q.where('type', isEqualTo: _typeToString(type));
    }

    return q.snapshots().map(
      (snap) => snap.docs.map(DfcArticleModel.fromFirestore).toList(),
    );
  }

  /// Single article by ID.
  Future<DfcArticleModel?> getArticle(String articleId) async {
    final doc = await _col.doc(articleId).get();
    if (!doc.exists) return null;
    return DfcArticleModel.fromFirestore(doc);
  }

  /// Drafts awaiting editor review.
  Stream<List<DfcArticleModel>> draftsStream({String? editorId}) {
    return _col
        .where('status', whereIn: ['draft_ai', 'draft_manual'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(DfcArticleModel.fromFirestore).toList(),
        );
  }

  // ─── WRITE ───────────────────────────────────────────────────────────

  /// Create a new AI-generated draft article.
  Future<String> createDraft({
    required String title,
    required String body,
    required DfcArticleType type,
    String? subtitle,
    String? eventId,
    List<String> tags = const [],
    List<String> relatedFighterIds = const [],
    List<String> relatedEventIds = const [],
    String createdBy = 'dfc_ai_engine',
  }) async {
    final slug = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    final now = DateTime.now();
    final article = DfcArticleModel(
      id: '',
      slug: slug,
      title: title,
      subtitle: subtitle,
      bodyMarkdown: body,
      type: type,
      status: DfcArticleStatus.draftAi,
      eventId: eventId,
      tags: tags,
      relatedFighterIds: relatedFighterIds,
      relatedEventIds: relatedEventIds,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    final ref = await _col.add(article.toFirestore());
    return ref.id;
  }

  /// Publish a draft (transitions status to published).
  Future<void> publishArticle(String articleId, String editorId) async {
    await _col.doc(articleId).update({
      'status': 'published',
      'isPublished': true,
      'publishedAt': FieldValue.serverTimestamp(),
      'updatedBy': editorId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Archive an article.
  Future<void> archiveArticle(String articleId) async {
    await _col.doc(articleId).update({
      'status': 'archived',
      'isPublished': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── ENGAGEMENT ──────────────────────────────────────────────────────

  /// Record a view on an article.
  Future<void> recordView(String articleId) async {
    await _col.doc(articleId).update({'viewCount': FieldValue.increment(1)});
  }

  /// Toggle like on an article.
  Future<void> toggleLike(String articleId, String userId) async {
    final likesRef = _col.doc(articleId).collection('likes').doc(userId);
    final exists = await likesRef.get();
    if (exists.exists) {
      await likesRef.delete();
      await _col.doc(articleId).update({'likeCount': FieldValue.increment(-1)});
    } else {
      await likesRef.set({'timestamp': FieldValue.serverTimestamp()});
      await _col.doc(articleId).update({'likeCount': FieldValue.increment(1)});
    }
  }

  // ─── DEMO DATA ──────────────────────────────────────────────────────

  /// Returns demo articles when Firestore is empty.
  List<DfcArticleModel> get demoArticles => _demoArticles;

  // ─── HELPERS ─────────────────────────────────────────────────────────

  String _typeToString(DfcArticleType t) {
    switch (t) {
      case DfcArticleType.eventAnnouncement:
        return 'event_announcement';
      case DfcArticleType.eventHypeFeature:
        return 'event_hype_feature';
      case DfcArticleType.resultsRecap:
        return 'results_recap';
      case DfcArticleType.fighterStory:
        return 'fighter_story';
      case DfcArticleType.promoterProfile:
        return 'promoter_profile';
      case DfcArticleType.cityFeature:
        return 'city_feature';
      case DfcArticleType.bkfcSpecial:
        return 'bkfc_special';
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DEMO CONTENT — Rich placeholder articles for first-run experience
// ═════════════════════════════════════════════════════════════════════════════
final _demoArticles = [
  DfcArticleModel(
    id: 'demo_1',
    slug: 'ufc-307-preview',
    title: 'UFC 307 Preview — Main Card Breakdown',
    subtitle: 'Three title fights headline the biggest card of 2026',
    bodyMarkdown: '''
The UFC returns to Las Vegas with a stacked triple-header that could reshape
three divisions. Our AI breakdown covers striking matchups, grappling edges,
and the key metrics that will decide each bout.

## Main Event
The welterweight title is on the line as the champion faces the most dangerous
challenger the division has seen in years. Reach advantage, cage-cutting
efficiency, and takedown defense will be the deciding factors.

## Co-Main Event
A rematch nobody expected — and everyone wanted. The first fight was a split
decision that divided fans and analysts alike.

## Featured Bout
An undefeated prospect meets a veteran gatekeeper in a fight that will
determine the next title contender.
''',
    type: DfcArticleType.eventHypeFeature,
    status: DfcArticleStatus.published,
    tags: const ['UFC', 'Preview', 'Title Fight', 'Las Vegas'],
    createdAt: DateTime(2026, 3, 20),
    updatedAt: DateTime(2026, 3, 20),
    publishedAt: DateTime(2026, 3, 20),
  ),
  DfcArticleModel(
    id: 'demo_2',
    slug: 'bkfc-47-results',
    title: 'BKFC 47 Results — Bare Knuckle Delivers Again',
    subtitle: 'Knockouts, upsets, and a new champion crowned',
    bodyMarkdown: '''
Bare Knuckle Fighting Championship delivered another unforgettable night of
raw combat. Here's our complete results recap with post-fight analysis.

## Main Event Result
A devastating third-round knockout rewrites the rankings and sets up
the superfight fans have been demanding.

## Breakout Star
The undercard produced a new star — a 22-year-old debutant who finished
a veteran in under two minutes.

## What's Next
BKFC 48 is already announced for April, with a card that looks even deeper.
''',
    type: DfcArticleType.resultsRecap,
    status: DfcArticleStatus.published,
    tags: const ['BKFC', 'Bare Knuckle', 'Results', 'Knockout'],
    createdAt: DateTime(2026, 3, 18),
    updatedAt: DateTime(2026, 3, 18),
    publishedAt: DateTime(2026, 3, 18),
  ),
  DfcArticleModel(
    id: 'demo_3',
    slug: 'fighter-story-redemption-arc',
    title: 'From Rock Bottom to Title Shot — A Fighter\'s Redemption',
    subtitle: 'How one loss changed everything for the better',
    bodyMarkdown: '''
Every fighter has a story. But few stories hit as hard as this one.

After a devastating loss that doctors said would end a career, one fighter
refused to quit. Through 18 months of rehabilitation, three comeback bouts,
and the support of a community that never stopped believing, the impossible
happened.

## The Injury
A compound fracture during training camp — the kind that makes surgeons shake
their heads. Most fighters would have retired.

## The Comeback
Starting from scratch. Learning to throw a jab again. Building confidence
one round at a time.

## The Title Shot
Signed, sealed, and scheduled. The redemption arc reaches its climax next month.
''',
    type: DfcArticleType.fighterStory,
    status: DfcArticleStatus.published,
    tags: const ['Fighter Story', 'Comeback', 'Inspiration'],
    createdAt: DateTime(2026, 3, 15),
    updatedAt: DateTime(2026, 3, 15),
    publishedAt: DateTime(2026, 3, 15),
  ),
  DfcArticleModel(
    id: 'demo_4',
    slug: 'coffee-not-coffin-campaign-launch',
    title: 'Coffee Not a Coffin — DFC\'s Safety Campaign Launches Nationwide',
    subtitle: 'Protecting fighters through community, not fear',
    bodyMarkdown: '''
DFC is proud to announce the nationwide launch of **Coffee Not a Coffin** —
our campaign to keep combat sport athletes safe, healthy, and supported.

## What It Is
A network of gyms, mentors, and safe spaces where fighters can access:
- Free health checks
- Mental wellness support
- Financial literacy workshops
- Community connection events

## Why It Matters
Combat sports athletes face unique challenges. Isolation, injury, and
financial pressure create a dangerous combination. This campaign provides
a safety net built by fighters, for fighters.

## How to Get Involved
Every gym can become a Coffee Not a Coffin partner. Sign up through the
DFC app and join the movement.
''',
    type: DfcArticleType.cityFeature,
    status: DfcArticleStatus.published,
    tags: const ['Campaign', 'Safety', 'Coffee Not Coffin', 'Community'],
    createdAt: DateTime(2026, 3, 10),
    updatedAt: DateTime(2026, 3, 10),
    publishedAt: DateTime(2026, 3, 10),
  ),
  DfcArticleModel(
    id: 'demo_5',
    slug: 'pink-shield-zones-expanding',
    title: 'Pink Shield Zones Now Active in 14 Cities',
    subtitle: 'DFC\'s safety initiative reaches new communities',
    bodyMarkdown: '''
The Pink Shield initiative — DFC's commitment to survivor safety in combat
sports — has expanded to 14 cities across three continents.

## Active Cities
Sydney, Melbourne, Brisbane, Los Angeles, New York, London, Tokyo,
Bangkok, Manila, Dubai, São Paulo, Johannesburg, Toronto, and Berlin.

## What Pink Shield Provides
- Safe training zones verified by DFC
- Certified mentors with background checks
- Anonymous reporting system
- Community solidarity network

## The Impact
Over 200 gyms have achieved Pink Shield certification, creating safe spaces
for thousands of athletes who previously faced barriers to training.
''',
    type: DfcArticleType.cityFeature,
    status: DfcArticleStatus.published,
    tags: const ['Pink Shield', 'Safety', 'Community', 'Global'],
    createdAt: DateTime(2026, 3, 5),
    updatedAt: DateTime(2026, 3, 5),
    publishedAt: DateTime(2026, 3, 5),
  ),
];
