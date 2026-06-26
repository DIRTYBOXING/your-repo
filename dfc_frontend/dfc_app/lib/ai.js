class GymModel {
  final String name;
  final String location;
  final String imageUrl;
  final Map<String, dynamic> stats;
  final List<dynamic> coaches;
  final List<dynamic> roster;
  final List<dynamic> schedule;

  GymModel({
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.stats,
    required this.coaches,
    required this.roster,
    required this.schedule,
  });

  factory GymModel.fromJson(Map<String, dynamic> json) {
    return GymModel(
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      stats: json['stats'] ?? {},
      coaches: json['coaches'] ?? [],
      roster: json['roster'] ?? [],
      schedule: json['schedule'] ?? [],
    );
  }
}