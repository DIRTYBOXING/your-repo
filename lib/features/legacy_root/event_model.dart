class EventModel {
  final String id;
  final String name;
  final String venue;
  final String city;
  final DateTime startTime;
  final String posterUrl;
  final String promotionId;
  final int ppvPriceCents;

  EventModel({
    required this.id,
    required this.name,
    required this.venue,
    required this.city,
    required this.startTime,
    required this.posterUrl,
    required this.promotionId,
    required this.ppvPriceCents,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      venue: json['venue'] ?? '',
      city: json['city'] ?? '',
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      posterUrl: json['poster_url'] ?? '',
      promotionId: json['promotion_id'] ?? '',
      ppvPriceCents: json['ppv_price_cents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'venue': venue,
    'city': city,
    'start_time': startTime.toIso8601String(),
    'poster_url': posterUrl,
    'promotion_id': promotionId,
    'ppv_price_cents': ppvPriceCents,
  };
}
