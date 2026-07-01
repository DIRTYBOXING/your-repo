import 'package:datafightcentral/shared/services/auto_feed_orchestrator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoFeedOrchestratorService hardening', () {
    final service = AutoFeedOrchestratorService();
    final now = DateTime.utc(2026, 4, 19, 12);

    AutoFeedItem item({
      required String id,
      required String title,
      required DateTime publishedAt,
      String source = 'Trusted Source',
      String? linkUrl,
      String body = 'Body content',
    }) {
      return AutoFeedItem(
        id: id,
        title: title,
        body: body,
        source: source,
        sourceType: FeedSourceType.news,
        publishedAt: publishedAt,
        linkUrl: linkUrl,
      );
    }

    test('removes stale and malformed items', () {
      final fresh = item(
        id: 'fresh-1',
        title: 'Fresh valid title',
        publishedAt: now.subtract(const Duration(hours: 1)),
      );
      final stale = item(
        id: 'stale-1',
        title: 'Old title',
        publishedAt: now.subtract(const Duration(hours: 100)),
      );
      final malformed = item(id: '', title: 'Bad', publishedAt: now);

      final hardened = service.debugApplyFeedHardening([
        fresh,
        stale,
        malformed,
      ], now: now);

      expect(hardened.length, 1);
      expect(hardened.first.id, 'fresh-1');
    });

    test('dedupes matching links and keeps newer item', () {
      final older = item(
        id: 'dup-old',
        title: 'Duplicate story older',
        publishedAt: now.subtract(const Duration(hours: 2)),
        linkUrl: 'https://example.com/story',
      );
      final newer = item(
        id: 'dup-new',
        title: 'Duplicate story newer',
        publishedAt: now.subtract(const Duration(hours: 1)),
        linkUrl: 'https://example.com/story',
      );

      final hardened = service.debugApplyFeedHardening([
        older,
        newer,
      ], now: now);

      expect(hardened.length, 1);
      expect(hardened.first.id, 'dup-new');
      expect(hardened.first.linkUrl, 'https://example.com/story');
    });

    test('canonicalizes links by removing tracker params', () {
      final tracked = item(
        id: 'tracked-1',
        title: 'Tracked link title',
        publishedAt: now.subtract(const Duration(hours: 1)),
        linkUrl: 'https://example.com/story?utm_source=abc&gclid=xyz',
      );

      final hardened = service.debugApplyFeedHardening([tracked], now: now);

      expect(hardened.length, 1);
      expect(hardened.first.linkUrl, 'https://example.com/story');
    });
  });

  group('AutoFeedOrchestratorService ranking', () {
    final service = AutoFeedOrchestratorService();
    final now = DateTime.utc(2026, 4, 19, 12);

    test(
      'recency increases composite score when trust and strategy are equal',
      () {
        final newer = AutoFeedItem(
          id: 'newer',
          title: 'Newer trusted story',
          body: 'Body',
          source: 'Source',
          sourceType: FeedSourceType.news,
          publishedAt: now.subtract(const Duration(hours: 1)),
          trustScore: 0.8,
          strategicScore: 0.6,
        );

        final older = AutoFeedItem(
          id: 'older',
          title: 'Older trusted story',
          body: 'Body',
          source: 'Source',
          sourceType: FeedSourceType.news,
          publishedAt: now.subtract(const Duration(hours: 48)),
          trustScore: 0.8,
          strategicScore: 0.6,
        );

        final newerScore = service.debugCompositeRankScore(newer, now: now);
        final olderScore = service.debugCompositeRankScore(older, now: now);

        expect(newerScore, greaterThan(olderScore));
      },
    );
  });
}
