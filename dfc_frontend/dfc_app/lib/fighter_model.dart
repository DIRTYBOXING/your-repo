class FighterModel {
  final String id;
  final String name;
  final String weightClass;
  final int wins;
  final int losses;

  FighterModel({
    required this.id,
    required this.name,
    required this.weightClass,
    required this.wins,
    required this.losses,
  });

  factory FighterModel.fromJson(Map<String, dynamic> json) {
    return FighterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Fighter',
      weightClass: json['weightClass'] ?? 'Unranked',
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weightClass': weightClass,
      'wins': wins,
      'losses': losses,
    };
  }
}
