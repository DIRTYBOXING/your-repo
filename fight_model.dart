class FightModel {
  final String id;
  final String fighterAId;
  final String fighterBId;
  final int fightOrder;

  FightModel({
    required this.id,
    required this.fighterAId,
    required this.fighterBId,
    required this.fightOrder,
  });

  factory FightModel.fromJson(Map<String, dynamic> json) {
    return FightModel(
      id: json['id'] ?? '',
      fighterAId: json['fighter_a_id'] ?? '',
      fighterBId: json['fighter_b_id'] ?? '',
      fightOrder: json['fight_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fighter_a_id': fighterAId,
    'fighter_b_id': fighterBId,
    'fight_order': fightOrder,
  };
}
