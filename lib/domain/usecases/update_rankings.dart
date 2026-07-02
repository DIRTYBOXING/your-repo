import '../entities/ranking.dart';

class UpdateRankings {
  List<Ranking> call(List<Ranking> current, Map<String, double> fightDeltaByFighterId) {
    final updated = current
        .map((r) => Ranking(
              fighterId: r.fighterId,
              division: r.division,
              position: r.position,
              rating: r.rating + (fightDeltaByFighterId[r.fighterId] ?? 0),
            ))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    for (var i = 0; i < updated.length; i++) {
      updated[i] = Ranking(
        fighterId: updated[i].fighterId,
        division: updated[i].division,
        position: i + 1,
        rating: updated[i].rating,
      );
    }

    return updated;
  }
}
