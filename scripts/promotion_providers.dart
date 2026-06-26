import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sql/dataconnect/dfc_db.dart';
import 'promotion_service.dart';
import 'promotion_model.dart';
import '../fighters/fighter_model.dart';
import '../../events/event_model.dart';

final promotionServiceProvider = Provider<PromotionService>((ref) {
  return PromotionService(DfcDb());
});

final promotionProvider = FutureProvider.family<Promotion?, String>((
  ref,
  id,
) async {
  return ref.watch(promotionServiceProvider).getPromotion(id);
});

final promotionEventsProvider = FutureProvider.family<List<Event>, String>((
  ref,
  id,
) async {
  return ref.watch(promotionServiceProvider).getPromotionEvents(id);
});

final promotionFightersProvider = FutureProvider.family<List<Fighter>, String>((
  ref,
  id,
) async {
  return ref.watch(promotionServiceProvider).getPromotionFighters(id);
});
