import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promoter_model.dart';
import '../services/promoter_api_service.dart';

final promoterApiServiceProvider = Provider<PromoterApiService>((ref) {
  return PromoterApiService();
});

final promoterListProvider = FutureProvider<List<PromoterModel>>((ref) async {
  return ref.watch(promoterApiServiceProvider).getPromoters();
});
