import '../../sql/dataconnect/dfc_db.dart';
import 'gym_model.dart';
import '../fighters/fighter_model.dart';

class GymService {
  final DfcDb _db;

  GymService(this._db);

  Future<Gym?> getGym(String id) async {
    final res = await _db.gymById(id: id).get();
    final g = res.data;
    if (g == null) return null;

    return Gym(
      id: g.id,
      name: g.name,
      suburb: g.suburb ?? '',
      state: g.state ?? '',
      bannerUrl: g.bannerUrl ?? '',
      pinkShield: g.pinkShield ?? false,
      goldCoin: g.goldCoin ?? false,
    );
  }

  Future<List<Fighter>> getGymFighters(String gymId) async {
    final res = await _db.fightersByGymId(gymId: gymId).get();
    return res.data
        .map(
          (f) => Fighter(
            id: f.id,
            firstName: f.firstName,
            lastName: f.lastName,
            nickname: f.nickname ?? '',
            weightClass: f.weightClass,
            wins: f.recordWins ?? 0,
            losses: f.recordLosses ?? 0,
            draws: f.recordDraws ?? 0,
            gymId: f.gymId ?? '',
            promotionId: f.promotionId ?? '',
            profileImageUrl: f.profileImageUrl ?? '',
            status: f.status ?? 'active',
          ),
        )
        .toList();
  }
}
