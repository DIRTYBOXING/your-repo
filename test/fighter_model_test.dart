import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/models/fighter_model.dart';

void main() {
  final now = DateTime(2026, 1, 15);

  FighterModel makeFighter({
    int wins = 15,
    int losses = 3,
    int draws = 1,
    int noContests = 0,
    int knockouts = 8,
    int submissions = 4,
    FighterStatus status = FighterStatus.active,
    MatchupAvailability matchupAvailability = MatchupAvailability.available,
    DateTime? availableFrom,
    DateTime? availableUntil,
  }) {
    return FighterModel(
      id: 'f1',
      userId: 'u1',
      fullName: 'Mike Zambidis',
      nickname: 'The Iron Mike',
      nationality: 'Greek',
      weightClass: 'Lightweight',
      sportType: 'Kickboxing',
      stance: FighterStance.orthodox,
      status: status,
      heightCm: 170,
      reachCm: 175,
      wins: wins,
      losses: losses,
      draws: draws,
      noContests: noContests,
      knockouts: knockouts,
      submissions: submissions,
      city: 'Athens',
      state: 'Attica',
      country: 'Greece',
      matchupAvailability: matchupAvailability,
      availableFrom: availableFrom,
      availableUntil: availableUntil,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('FighterModel — computed properties', () {
    test('record returns W-L-D format', () {
      final f = makeFighter();
      expect(f.record, '15-3-1');
    });

    test('totalFights sums wins + losses + draws + noContests', () {
      final f = makeFighter(noContests: 2);
      expect(f.totalFights, 21); // 15+3+1+2
    });

    test('winPercentage is correct', () {
      final f = makeFighter(); // 15 wins out of 19 fights
      expect(f.winPercentage, closeTo(78.9, 0.1));
    });

    test('winPercentage is 0 when no fights', () {
      final f = makeFighter(wins: 0, losses: 0, draws: 0);
      expect(f.winPercentage, 0.0);
    });

    test('finishRate is (KO + Sub) / Wins * 100', () {
      final f = makeFighter(); // 8 KO + 4 Sub / 15 Wins = 80%
      expect(f.finishRate, closeTo(80.0, 0.1));
    });

    test('finishRate is 0 when no wins', () {
      final f = makeFighter(wins: 0, knockouts: 0, submissions: 0);
      expect(f.finishRate, 0.0);
    });

    test('locationDisplay joins city, state, country', () {
      final f = makeFighter();
      expect(f.locationDisplay, 'Athens, Attica, Greece');
    });

    test('locationDisplay fallback when no location', () {
      final f = FighterModel(
        id: 'f2',
        userId: 'u2',
        fullName: 'Test',
        createdAt: now,
        updatedAt: now,
      );
      expect(f.locationDisplay, 'Location not set');
    });
  });

  group('FighterModel — matchup availability', () {
    test('isAvailableForMatchup true when active + available', () {
      final f = makeFighter();
      expect(f.isAvailableForMatchup, true);
    });

    test('isAvailableForMatchup false when retired', () {
      final f = makeFighter(status: FighterStatus.retired);
      expect(f.isAvailableForMatchup, false);
    });

    test('isAvailableForMatchup false when negotiating', () {
      final f = makeFighter(
        matchupAvailability: MatchupAvailability.negotiating,
      );
      expect(f.isAvailableForMatchup, false);
    });

    test('isAvailableForMatchup false when before availableFrom', () {
      final f = makeFighter(
        availableFrom: DateTime.now().add(const Duration(days: 30)),
      );
      expect(f.isAvailableForMatchup, false);
    });

    test('isAvailableForMatchup false when after availableUntil', () {
      final f = makeFighter(
        availableUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(f.isAvailableForMatchup, false);
    });
  });

  group('FighterModel — toFirestore round-trip', () {
    test('toFirestore produces expected keys', () {
      final f = makeFighter();
      final map = f.toFirestore();

      expect(map['fullName'], 'Mike Zambidis');
      expect(map['nickname'], 'The Iron Mike');
      expect(map['wins'], 15);
      expect(map['losses'], 3);
      expect(map['draws'], 1);
      expect(map['status'], 'active');
      expect(map['stance'], 'orthodox');
      expect(map['city'], 'Athens');
      expect(map['matchupAvailability'], 'available');
      expect(map['willingToTravel'], true);
    });
  });

  group('FighterModel — copyWith', () {
    test('copyWith preserves unchanged fields', () {
      final f = makeFighter();
      final copy = f.copyWith(wins: 20);

      expect(copy.wins, 20);
      expect(copy.fullName, f.fullName);
      expect(copy.losses, f.losses);
      expect(copy.city, f.city);
    });

    test('copyWith updates multiple fields', () {
      final f = makeFighter();
      final copy = f.copyWith(
        status: FighterStatus.retired,
        matchupAvailability: MatchupAvailability.unavailable,
      );

      expect(copy.status, FighterStatus.retired);
      expect(copy.matchupAvailability, MatchupAvailability.unavailable);
    });
  });

  group('FighterModel — Equatable', () {
    test('identical fighters are equal', () {
      final a = makeFighter();
      final b = makeFighter();
      expect(a, equals(b));
    });

    test('different IDs are not equal', () {
      final a = makeFighter();
      final b = a.copyWith(id: 'f99');
      expect(a, isNot(equals(b)));
    });
  });

  group('FighterStance enum', () {
    test('all stances are available', () {
      expect(FighterStance.values.length, 3);
      expect(FighterStance.values, contains(FighterStance.switch_));
    });
  });
}
