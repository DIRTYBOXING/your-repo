import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/models/fight_card_template.dart';

void main() {
  final now = DateTime(2026, 3);

  FightCardBout makeBout({
    String id = 'b1',
    BoutPosition position = BoutPosition.prelim,
    int boutOrder = 0,
    String redCornerName = 'Red Fighter',
    String blueCornerName = 'Blue Fighter',
  }) {
    return FightCardBout(
      id: id,
      position: position,
      boutOrder: boutOrder,
      redCornerName: redCornerName,
      blueCornerName: blueCornerName,
      weightClass: 'Welterweight',
    );
  }

  FightCardTemplate makeCard({List<FightCardBout>? bouts}) {
    return FightCardTemplate(
      id: 'card1',
      creatorId: 'user1',
      creatorName: 'Promoter Joe',
      eventName: 'DFC Fight Night 1',
      promotionName: 'DFC Promotions',
      venue: 'Melbourne Arena',
      city: 'Melbourne',
      eventDate: now,
      bouts: bouts ?? [],
      createdAt: now,
      updatedAt: now,
    );
  }

  group('BoutPosition extension', () {
    test('labels are human-readable', () {
      expect(BoutPosition.mainEvent.label, 'MAIN EVENT');
      expect(BoutPosition.semiMain.label, 'SEMI-MAIN');
      expect(BoutPosition.coMain.label, 'CO-MAIN');
      expect(BoutPosition.prelim.label, 'PRELIM');
      expect(BoutPosition.undercard.label, 'UNDERCARD');
      expect(BoutPosition.superfight.label, 'SUPER FIGHT');
      expect(BoutPosition.exhibition.label, 'EXHIBITION');
    });

    test(
      'sortOrder: mainEvent < semiMain < coMain < superfight < prelim < undercard < exhibition',
      () {
        final ordered = BoutPosition.values.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        expect(ordered.first, BoutPosition.mainEvent);
        expect(ordered.last, BoutPosition.exhibition);
      },
    );
  });

  group('FightCardBout — serialization', () {
    test('toMap / fromMap round-trip', () {
      final bout = makeBout(
        id: 'bout42',
        position: BoutPosition.mainEvent,
        redCornerName: 'Fighter A',
        blueCornerName: 'Fighter B',
      );
      final map = bout.toMap();
      final restored = FightCardBout.fromMap(map);

      expect(restored.id, bout.id);
      expect(restored.position, bout.position);
      expect(restored.redCornerName, bout.redCornerName);
      expect(restored.blueCornerName, bout.blueCornerName);
      expect(restored.rounds, bout.rounds);
      expect(restored.sportType, bout.sportType);
    });

    test('fromMap handles missing fields with defaults', () {
      final bout = FightCardBout.fromMap(const {'id': 'x'});

      expect(bout.id, 'x');
      expect(bout.position, BoutPosition.prelim);
      expect(bout.rounds, 3);
      expect(bout.sportType, 'MMA');
      expect(bout.rules, 'Full Contact');
    });

    test('fromMap handles unknown position gracefully', () {
      final bout = FightCardBout.fromMap(const {
        'id': 'x',
        'position': 'nonExistent',
      });
      expect(bout.position, BoutPosition.prelim);
    });
  });

  group('FightCardBout — copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final bout = makeBout();
      final copy = bout.copyWith(rounds: 5);

      expect(copy.rounds, 5);
      expect(copy.id, bout.id);
      expect(copy.redCornerName, bout.redCornerName);
    });
  });

  group('FightCardTemplate — sortedBouts', () {
    test('sorts main event first, then by boutOrder', () {
      final card = makeCard(
        bouts: [
          makeBout(),
          makeBout(id: 'b2', position: BoutPosition.mainEvent),
          makeBout(id: 'b3', position: BoutPosition.coMain),
          makeBout(id: 'b4', boutOrder: 1),
        ],
      );

      final sorted = card.sortedBouts;
      expect(sorted[0].id, 'b2'); // mainEvent
      expect(sorted[1].id, 'b3'); // coMain
      expect(sorted[2].id, 'b1'); // prelim order 0
      expect(sorted[3].id, 'b4'); // prelim order 1
    });

    test('sortedBouts does not mutate original list', () {
      final bouts = [
        makeBout(),
        makeBout(id: 'b2', position: BoutPosition.mainEvent),
      ];
      final card = makeCard(bouts: bouts);
      card.sortedBouts;
      expect(card.bouts[0].id, 'b1'); // original order preserved
    });
  });

  group('FightCardTemplate — totalBouts', () {
    test('returns count of bouts', () {
      final card = makeCard(
        bouts: [
          makeBout(id: 'a'),
          makeBout(id: 'b'),
          makeBout(id: 'c'),
        ],
      );
      expect(card.totalBouts, 3);
    });

    test('returns 0 for empty card', () {
      final card = makeCard();
      expect(card.totalBouts, 0);
    });
  });

  group('FightCardTemplate — toFirestore', () {
    test('produces expected keys', () {
      final card = makeCard(bouts: [makeBout()]);
      final map = card.toFirestore();

      expect(map['eventName'], 'DFC Fight Night 1');
      expect(map['creatorId'], 'user1');
      expect(map['sportType'], 'MMA');
      expect(map['isDraft'], true);
      expect(map['bouts'], isList);
      expect((map['bouts'] as List).length, 1);
    });
  });

  group('FightCardTemplate — copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final card = makeCard();
      final copy = card.copyWith(eventName: 'Updated Event');

      expect(copy.eventName, 'Updated Event');
      expect(copy.creatorId, card.creatorId);
      expect(copy.city, card.city);
    });
  });

  group('FightCardTemplate — Equatable', () {
    test('same id + creatorId + eventName + eventDate are equal', () {
      final a = makeCard();
      final b = makeCard();
      expect(a, equals(b));
    });

    test('different eventName are not equal', () {
      final a = makeCard();
      final b = a.copyWith(eventName: 'Different');
      expect(a, isNot(equals(b)));
    });
  });
}
