import '../../sql/dataconnect/dfc_db.dart';
import 'event_model.dart';

class EventService {
  final DfcDb _db;
  EventService(this._db);

  Future<Event?> getEvent(String id) async {
    final res = await _db.eventById(id: id).get();
    final e = res.data;
    if (e == null) return null;

    return Event(
      id: e.id,
      name: e.name,
      venue: e.venue ?? '',
      city: e.city ?? '',
      startTime: DateTime.parse(e.startTime),
      posterUrl: e.posterUrl ?? '',
      promotionId: e.promotionId ?? '',
      priceCents: e.ppvPriceCents ?? 0,
    );
  }

  Future<List<FightCardEntry>> getFightCard(String eventId) async {
    final res = await _db.fightsByEventId(eventId: eventId).get();
    return res.data
        .map(
          (f) => FightCardEntry(
            id: f.id,
            fighterAId: f.fighterAId,
            fighterBId: f.fighterBId,
            order: f.fightOrder ?? 0,
          ),
        )
        .toList();
  }
}
