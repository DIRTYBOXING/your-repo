class Event {
  final String id;
  final String name;
  final String venue;
  final String city;
  final DateTime startTime;
  final String posterUrl;
  final String promotionId;
  final int priceCents;

  Event({
    required this.id,
    required this.name,
    required this.venue,
    required this.city,
    required this.startTime,
    required this.posterUrl,
    required this.promotionId,
    required this.priceCents,
  });
}

class FightCardEntry {
  final String id;
  final String fighterAId;
  final String fighterBId;
  final int order;

  FightCardEntry({
    required this.id,
    required this.fighterAId,
    required this.fighterBId,
    required this.order,
  });
}
