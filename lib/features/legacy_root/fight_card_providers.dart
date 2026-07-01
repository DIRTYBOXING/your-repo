import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fight_model.dart';
import 'fight_card_api_service.dart';

final fightCardApiServiceProvider = Provider<FightCardApiService>((ref) {
  return FightCardApiService();
});

class FightListNotifier extends FamilyAsyncNotifier<List<FightModel>, String> {
  @override
  Future<List<FightModel>> build(String arg) async {
    return ref.watch(fightCardApiServiceProvider).getFights(arg);
  }

  Future<void> reorderFights(int oldIndex, int newIndex) async {
    final previousState = state;

    if (state.value == null) return;

    // 1. Optimistic Local Update (Zero Latency)
    final currentFights = List<FightModel>.from(state.value!);
    final item = currentFights.removeAt(oldIndex);
    currentFights.insert(newIndex, item);

    // 2. Re-assign the fightOrder integers
    final updatedFights = <FightModel>[];
    for (int i = 0; i < currentFights.length; i++) {
      updatedFights.add(
        FightModel(
          id: currentFights[i].id,
          fighterAId: currentFights[i].fighterAId,
          fighterBId: currentFights[i].fighterBId,
          fightOrder: i + 1,
        ),
      );
    }

    state = AsyncValue.data(updatedFights);

    // 3. Background Network Sync
    try {
      await ref
          .read(fightCardApiServiceProvider)
          .updateFightOrders(arg, updatedFights);
    } catch (e) {
      // Rollback silently on failure and throw error to the UI
      state = previousState;
      throw Exception('Network sync failed: $e');
    }
  }
}

final fightListProvider =
    AsyncNotifierProviderFamily<FightListNotifier, List<FightModel>, String>(
      () {
        return FightListNotifier();
      },
    );
