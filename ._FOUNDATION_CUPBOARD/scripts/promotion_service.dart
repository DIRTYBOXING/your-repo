import '../../sql/dataconnect/dfc_db.dart';
import 'promotion_model.dart';
import '../fighters/fighter_model.dart';
import '../../events/event_model.dart';

class PromotionService {
  final DfcDb _db;

  PromotionService(this._db);

  Future<Promotion?> getPromotion(String id) async {
    final res = await _db.promotionById(id: id).get();
    final p = res.data;
    if (p == null) return null;

    return Promotion(
      id: p.id,
      name: p.name,
      primaryColor: p.primaryColor ?? '#FF0055',
      secondaryColor: p.secondaryColor ?? '#FFFFFF',
      logoUrl: p.logoUrl ?? '',
      bannerUrl: p.bannerUrl ?? '',
    );
  }

  Future<List<Event>> getPromotionEvents(String promotionId) async {
    final res = await _db.eventsByPromotionId(promotionId: promotionId).get();
    return res.data
        .map(
          (e) => Event(
            id: e.id,
            name: e.name,
            venue: e.venue ?? '',
            city: e.city ?? '',
            startTime: DateTime.parse(e.startTime),
            posterUrl: e.posterUrl ?? '',
            promotionId: e.promotionId ?? '',
            priceCents: e.ppvPriceCents ?? 0,
          ),
        )
        .toList();
  }

  Future<List<Fighter>> getPromotionFighters(String promotionId) async {
    // For this, you would ideally have a query in SQL connect like fightersByPromotionId
    // Assuming it's defined similarly to fightersByGymId:
    final res = await _db.fightersByPromotionId(promotionId: promotionId).get();
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
