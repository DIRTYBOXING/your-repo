import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/services/fight_news_service.dart';

void main() {
  group('FightNewsArticle — timeAgo', () {
    test('shows minutes for < 1 hour', () {
      final article = FightNewsArticle(
        id: '1',
        title: 'Test',
        summary: 'Sum',
        source: 'UFC',
        category: NewsSource.ufc,
        publishedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      expect(article.timeAgo, '30m ago');
    });

    test('shows hours for < 1 day', () {
      final article = FightNewsArticle(
        id: '2',
        title: 'Test',
        summary: 'Sum',
        source: 'UFC',
        category: NewsSource.ufc,
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      );
      expect(article.timeAgo, '5h ago');
    });

    test('shows days for < 1 week', () {
      final article = FightNewsArticle(
        id: '3',
        title: 'Test',
        summary: 'Sum',
        source: 'UFC',
        category: NewsSource.ufc,
        publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(article.timeAgo, '3d ago');
    });

    test('shows weeks for >= 7 days', () {
      final article = FightNewsArticle(
        id: '4',
        title: 'Test',
        summary: 'Sum',
        source: 'UFC',
        category: NewsSource.ufc,
        publishedAt: DateTime.now().subtract(const Duration(days: 14)),
      );
      expect(article.timeAgo, '2w ago');
    });
  });

  group('FightNewsArticle — sourceDisplay', () {
    test('UFC displays correctly', () {
      final article = FightNewsArticle(
        id: '1',
        title: 'T',
        summary: 'S',
        source: 'x',
        category: NewsSource.ufc,
        publishedAt: DateTime.now(),
      );
      expect(article.sourceDisplay, 'UFC');
    });

    test('muayThai displays correctly', () {
      final article = FightNewsArticle(
        id: '1',
        title: 'T',
        summary: 'S',
        source: 'x',
        category: NewsSource.muayThai,
        publishedAt: DateTime.now(),
      );
      expect(article.sourceDisplay, 'Muay Thai');
    });

    test('bareKnuckle displays correctly', () {
      final article = FightNewsArticle(
        id: '1',
        title: 'T',
        summary: 'S',
        source: 'x',
        category: NewsSource.bareKnuckle,
        publishedAt: DateTime.now(),
      );
      expect(article.sourceDisplay, 'BKFC');
    });
  });

  group('FightNewsService — core operations', () {
    // FightNewsService is a singleton — do NOT dispose between tests
    final service = FightNewsService();

    test('refreshNews returns non-empty list', () async {
      final news = await service.refreshNews();
      expect(news, isNotEmpty);
    });

    test('cachedNews is populated after refresh', () async {
      await service.refreshNews();
      expect(service.cachedNews, isNotEmpty);
    });

    test('getBreaking returns only breaking articles', () async {
      await service.refreshNews();
      final breaking = service.getBreaking();
      for (final article in breaking) {
        expect(article.isBreaking, true);
      }
    });

    test('getFeatured returns only featured articles', () async {
      await service.refreshNews();
      final featured = service.getFeatured();
      for (final article in featured) {
        expect(article.isFeatured, true);
      }
    });

    test('getByCategory filters correctly', () async {
      await service.refreshNews();
      final ufcNews = service.getByCategory(NewsSource.ufc);
      for (final article in ufcNews) {
        expect(article.category, NewsSource.ufc);
      }
    });

    test('search matches title content', () async {
      await service.refreshNews();
      final results = service.search('UFC');
      expect(results, isNotEmpty);
    });

    test('search is case-insensitive', () async {
      await service.refreshNews();
      final upper = service.search('UFC');
      final lower = service.search('ufc');
      expect(upper.length, lower.length);
    });

    test('newsStream emits on refresh', () async {
      final future = service.newsStream.first;
      await service.refreshNews();
      final emitted = await future;
      expect(emitted, isNotEmpty);
    });
  });

  group('AIContentGenerator', () {
    test('generatePromo returns valid content', () {
      final gen = AIContentGenerator();
      final promo = gen.generatePromo(targetAudience: 'fighters');
      expect(promo.headline, isNotEmpty);
      expect(promo.body, isNotEmpty);
      expect(promo.ctaText, isNotEmpty);
      expect(promo.targetAudience, 'fighters');
    });

    test('generateSportAd returns content for sport', () {
      final gen = AIContentGenerator();
      final ad = gen.generateSportAd(NewsSource.boxing);
      expect(ad.headline.toLowerCase(), contains('boxing'));
      expect(ad.targetAudience, 'boxing_enthusiasts');
    });
  });

  group('NewsSource enum', () {
    test('has all expected sources', () {
      expect(NewsSource.values.length, 14);
      expect(NewsSource.values, contains(NewsSource.ufc));
      expect(NewsSource.values, contains(NewsSource.muayThai));
      expect(NewsSource.values, contains(NewsSource.bareKnuckle));
      expect(NewsSource.values, contains(NewsSource.brawling));
      expect(NewsSource.values, contains(NewsSource.mma));
      expect(NewsSource.values, contains(NewsSource.rizin));
    });
  });
}
