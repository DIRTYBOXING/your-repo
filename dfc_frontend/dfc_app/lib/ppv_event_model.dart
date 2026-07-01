class PpvEventModel {
  final String id;
  final String title;
  final String date;
  final String location;
  final String posterUrl;
  final double price;
  final List<PpvFightModel> fights;

  PpvEventModel({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.posterUrl,
    required this.price,
    required this.fights,
  });
}

class PpvFightModel {
  final String id;
  final String redCorner;
  final String blueCorner;
  final String weightClass;
  final bool isMainEvent;

  PpvFightModel({
    required this.id,
    required this.redCorner,
    required this.blueCorner,
    required this.weightClass,
    this.isMainEvent = false,
  });
}