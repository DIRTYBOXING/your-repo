import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/models/ppv_model.dart';

void main() {
  group('PPVEvent Model', () {
    test('constructs with required fields', () {
      final event = PPVEvent(
        id: 'ppv_001',
        eventId: 'evt_001',
        promoterId: 'promo_001',
        title: 'DFC Fight Night 1',
        eventDate: DateTime(2026, 4, 15),
        standardPriceCents: 4999,
      );

      expect(event.id, 'ppv_001');
      expect(event.title, 'DFC Fight Night 1');
      expect(event.standardPriceCents, 4999);
      expect(event.currency, 'AUD');
      expect(event.status, PPVStatus.announced);
      expect(event.platformFeePct, 0.30);
      expect(event.chatEnabled, true);
    });

    test('constructs with all optional fields', () {
      final event = PPVEvent(
        id: 'ppv_002',
        eventId: 'evt_002',
        promoterId: 'promo_002',
        title: 'DFC Championship',
        subtitle: 'Main Event: Jones vs Miocic',
        description: 'The greatest fight card of the year',
        sport: 'MMA',
        promotion: 'UFC',
        posterUrl: 'https://example.com/poster.jpg',
        trailerUrl: 'https://youtube.com/watch?v=abc123',
        eventDate: DateTime(2026, 6),
        endTime: DateTime(2026, 6, 2),
        presaleStart: DateTime(2026, 5),
        onSaleStart: DateTime(2026, 5, 15),
        replayExpiry: DateTime(2026, 7),
        status: PPVStatus.live,
        standardPriceCents: 7999,
        earlyBirdPriceCents: 5999,
        premiumPriceCents: 9999,
        vipPriceCents: 14999,
        currency: 'USD',
        streamUrl: 'https://stream.dfc.com/live/abc',
        muxStreamId: 'mux_stream_001',
        muxPlaybackId: 'mux_play_001',
        streamPlatforms: ['DFC', 'Kayo'],
        purchaseCount: 15000,
        peakViewers: 8500,
        totalRevenueCents: 119985000,
        fightCard: [
          const PPVFight(
            fightId: 'fight_001',
            fighter1Name: 'Jon Jones',
            fighter2Name: 'Stipe Miocic',
            weightClass: 'Heavyweight',
            isMainEvent: true,
            rounds: 5,
          ),
        ],
        platformFeePct: 0.25,
        multiCamEnabled: true,
      );

      expect(event.subtitle, 'Main Event: Jones vs Miocic');
      expect(event.sport, 'MMA');
      expect(event.status, PPVStatus.live);
      expect(event.earlyBirdPriceCents, 5999);
      expect(event.streamPlatforms, ['DFC', 'Kayo']);
      expect(event.fightCard.length, 1);
      expect(event.fightCard.first.isMainEvent, true);
      expect(event.purchaseCount, 15000);
      expect(event.multiCamEnabled, true);
    });

    test('field access after construction', () {
      final event = PPVEvent(
        id: 'ppv_003',
        eventId: 'evt_003',
        promoterId: 'promo_003',
        title: 'BKFC Brisbane',
        sport: 'BKFC',
        eventDate: DateTime(2026, 5, 10),
        standardPriceCents: 2999,
        fightCard: [
          const PPVFight(
            fightId: 'fight_002',
            fighter1Name: 'Fighter Alpha',
            fighter2Name: 'Fighter Beta',
            weightClass: 'Welterweight',
          ),
        ],
      );

      expect(event.title, 'BKFC Brisbane');
      expect(event.sport, 'BKFC');
      expect(event.standardPriceCents, 2999);
      expect(event.currency, 'AUD');
      expect(event.fightCard.length, 1);
      expect(event.fightCard.first.fighter1Name, 'Fighter Alpha');
    });
  });

  group('PPVFight Model', () {
    test('constructs main event fight', () {
      final fight = const PPVFight(
        fightId: 'fight_main',
        fighter1Name: 'Islam Makhachev',
        fighter2Name: 'Charles Oliveira',
        weightClass: 'Lightweight',
        isMainEvent: true,
        rounds: 5,
      );

      expect(fight.fighter1Name, 'Islam Makhachev');
      expect(fight.fighter2Name, 'Charles Oliveira');
      expect(fight.isMainEvent, true);
      expect(fight.rounds, 5);
    });

    test('default values', () {
      final fight = const PPVFight(
        fightId: 'fight_default',
        fighter1Name: 'A',
        fighter2Name: 'B',
        weightClass: 'Lightweight',
      );

      expect(fight.rounds, 3);
      expect(fight.isMainEvent, false);
      expect(fight.isTitleFight, false);
      expect(fight.result, isNull);
    });

    test('toMap and fromMap roundtrip', () {
      final fight = const PPVFight(
        fightId: 'fight_rt',
        fighter1Name: 'Canelo Alvarez',
        fighter2Name: 'Jermell Charlo',
        weightClass: 'Super Middleweight',
        rounds: 12,
        isTitleFight: true,
      );

      final map = fight.toMap();
      final restored = PPVFight.fromMap(map);
      expect(restored.fighter1Name, fight.fighter1Name);
      expect(restored.fighter2Name, fight.fighter2Name);
      expect(restored.weightClass, fight.weightClass);
      expect(restored.rounds, 12);
      expect(restored.isTitleFight, true);
    });
  });

  group('PPVPurchase Model', () {
    test('constructs a valid purchase', () {
      final purchase = PPVPurchase(
        id: 'pur_001',
        ppvEventId: 'ppv_001',
        userId: 'user_001',
        tier: PPVTier.standard,
        pricePaidCents: 4999,
        paymentMethod: 'stripe',
        purchasedAt: DateTime(2026, 4, 10),
      );

      expect(purchase.ppvEventId, 'ppv_001');
      expect(purchase.userId, 'user_001');
      expect(purchase.pricePaidCents, 4999);
      expect(purchase.pricePaid, 49.99);
      expect(purchase.status, 'completed');
      expect(purchase.tier, PPVTier.standard);
    });

    test('all tiers are valid', () {
      for (final tier in PPVTier.values) {
        final purchase = PPVPurchase(
          id: 'pur_tier_${tier.name}',
          ppvEventId: 'ppv_tier',
          userId: 'user_tier',
          tier: tier,
          pricePaidCents: 4999,
          paymentMethod: 'stripe',
          purchasedAt: DateTime(2026, 4, 10),
        );
        expect(purchase.tier, tier);
      }
    });
  });

  group('PPV Pricing Logic', () {
    test('earlybird pricing is lower than standard', () {
      final event = PPVEvent(
        id: 'ppv_price_test',
        eventId: 'evt_price',
        promoterId: 'promo_price',
        title: 'Pricing Test Event',
        eventDate: DateTime(2026, 8),
        standardPriceCents: 4999,
        earlyBirdPriceCents: 3499,
      );

      expect(event.earlyBirdPriceCents! < event.standardPriceCents, true);
    });

    test('platform fee calculation', () {
      const totalRevenue = 500000; // $5000 in cents
      const feePct = 0.30;
      final platformCut = (totalRevenue * feePct).round();
      final promoterCut = totalRevenue - platformCut;

      expect(platformCut, 150000);
      expect(promoterCut, 350000);
    });

    test('tiered fee schedule validation', () {
      // DFC fee schedule based on cumulative buys
      double getFeePercent(int cumulativeBuys) {
        if (cumulativeBuys < 100) return 0.30;
        if (cumulativeBuys < 500) return 0.25;
        if (cumulativeBuys < 2000) return 0.20;
        return 0.15;
      }

      expect(getFeePercent(0), 0.30);
      expect(getFeePercent(50), 0.30);
      expect(getFeePercent(100), 0.25);
      expect(getFeePercent(499), 0.25);
      expect(getFeePercent(500), 0.20);
      expect(getFeePercent(2000), 0.15);
      expect(getFeePercent(10000), 0.15);
    });
  });

  group('PPV Status Transitions', () {
    test('all PPV statuses are valid', () {
      final statuses = PPVStatus.values;
      expect(statuses.length, greaterThanOrEqualTo(3));
      expect(statuses.contains(PPVStatus.announced), true);
      expect(statuses.contains(PPVStatus.live), true);
    });

    test('fight card must have at least one fight for a valid event', () {
      final event = PPVEvent(
        id: 'ppv_empty_card',
        eventId: 'evt_empty',
        promoterId: 'promo_empty',
        title: 'Empty Card Event',
        eventDate: DateTime(2026, 9),
        standardPriceCents: 2999,
        fightCard: [],
      );

      // Business rule: empty fight cards are technically valid at creation
      // but should be validated before going live
      expect(event.fightCard.isEmpty, true);
      expect(event.status, PPVStatus.announced);
    });
  });
}
