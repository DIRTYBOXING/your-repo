import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sql/dataconnect/dfc_db.dart';
import 'event_service.dart';
import 'event_model.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService(DfcDb());
});

final eventProvider = FutureProvider.family<Event?, String>((ref, id) async {
  return ref.watch(eventServiceProvider).getEvent(id);
});

final fightCardProvider = FutureProvider.family<List<FightCardEntry>, String>((
  ref,
  eventId,
) async {
  return ref.watch(eventServiceProvider).getFightCard(eventId);
});
