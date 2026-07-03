import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gym_model.dart';
import '../services/gym_api_service.dart';

final gymApiServiceProvider = Provider<GymApiService>((ref) {
  return GymApiService();
});

final adminGymListProvider = FutureProvider<List<GymModel>>((ref) async {
  return ref.watch(gymApiServiceProvider).getGyms();
});
