import '../entities/ranking.dart';

class ComputeP4pLadder {
  List<Ranking> call(List<Ranking> divisionalLeaders, Map<String, double> qualityOfCompetition) {
    final scored = divisionalLeaders
        .map((r) => Ranking(
              fighterId: r.fighterId,
              division: 'P4P',
              position: r.position,
              rating: (r.rating * 0.7) + ((qualityOfCompetition[r.fighterId] ?? 0) * 0.3),
            ))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    for (var i = 0; i < scored.length; i++) {
      scored[i] = Ranking(
        fighterId: scored[i].fighterId,
        division: scored[i].division,
        position: i + 1,
        rating: scored[i].rating,
      );
    }

    return scored;
  }
}
