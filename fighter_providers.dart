import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fighter_model.dart';
import '../services/fighter_api_service.dart';

final fighterApiServiceProvider = Provider<FighterApiService>((ref) {
  return FighterApiService();
});

final fighterListProvider = FutureProvider<List<FighterModel>>((ref) async {
  return ref.watch(fighterApiServiceProvider).getFighters();
});
