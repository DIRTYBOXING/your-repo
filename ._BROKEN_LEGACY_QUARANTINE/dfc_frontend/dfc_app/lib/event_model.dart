class EventModel {
  final String id;
  String name;
  String date;
  String location;
  List<FightModel> fights;

  EventModel({
    required this.id,
    required this.name,
    required this.date,
    required this.location,
    required this.fights,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      location: json['location'] ?? '',
      fights:
          (json['fights'] as List<dynamic>?)
              ?.map((f) => FightModel.fromJson(Map<String, dynamic>.from(f)))
              .toList() ??
          [],
    );
  }
}

class FightModel {
  final String redCorner;
  final String blueCorner;
  final String weightClass;
  final bool isMainEvent;

  FightModel({
    required this.redCorner,
    required this.blueCorner,
    required this.weightClass,
    this.isMainEvent = false,
  });

  factory FightModel.fromJson(Map<String, dynamic> json) {
    return FightModel(
      redCorner: json['redCorner'] ?? 'TBD',
      blueCorner: json['blueCorner'] ?? 'TBD',
      weightClass: json['weightClass'] ?? 'Catchweight',
      isMainEvent: json['isMainEvent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'redCorner': redCorner,
    'blueCorner': blueCorner,
    'weightClass': weightClass,
    'isMainEvent': isMainEvent,
  };
}
