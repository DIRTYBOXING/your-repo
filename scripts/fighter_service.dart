import '../../sql/dataconnect/dfc_db.dart';
import 'fighter_model.dart';

class FighterService {
  final DfcDb _db;

  FighterService(this._db);

  Future<Fighter?> getFighter(String id) async {
    final res = await _db.fighterById(id: id).get();
    final f = res.data;
    if (f == null) return null;

    return Fighter(
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
    );
  }
}
