import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import '../services/event_api_service.dart';

final eventApiServiceProvider = Provider<EventApiService>((ref) {
  return EventApiService();
});

final eventListProvider = FutureProvider<List<EventModel>>((ref) async {
  return ref.watch(eventApiServiceProvider).getEvents();
});
