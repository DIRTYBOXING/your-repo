class Event {
  Event({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
}
