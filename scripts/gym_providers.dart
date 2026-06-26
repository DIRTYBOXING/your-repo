import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sql/dataconnect/dfc_db.dart';
import 'gym_service.dart';
import 'gym_model.dart';
import '../fighters/fighter_model.dart';

final gymServiceProvider = Provider<GymService>((ref) {
  return GymService(DfcDb());
});

final gymProvider = FutureProvider.family<Gym?, String>((ref, id) async {
  return ref.watch(gymServiceProvider).getGym(id);
});

final gymFightersProvider = FutureProvider.family<List<Fighter>, String>((
  ref,
  gymId,
) async {
  return ref.watch(gymServiceProvider).getGymFighters(gymId);
});
