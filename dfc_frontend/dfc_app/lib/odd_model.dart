class OddModel {
  final String id;
  final String? fighter;
  final String? propName;
  final String odds;
  final bool isFavorite;
  final String type;

  OddModel({
    required this.id,
    this.fighter,
    this.propName,
    required this.odds,
    required this.isFavorite,
    required this.type,
  });

  factory OddModel.fromJson(Map<String, dynamic> json) => OddModel(
    id: json["id"] ?? '',
    fighter: json["fighter"],
    propName: json["propName"],
    odds: json["odds"] ?? '',
    isFavorite: json["isFavorite"] ?? false,
    type: json["type"] ?? 'MONEYLINE',
  );
}
