class CreatorOfferModel {
  final String id;
  final String title;
  final String description;
  final int priceCents;
  final String currency;
  final String scope;
  final String level;

  CreatorOfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.scope,
    required this.level,
  });

  factory CreatorOfferModel.fromJson(Map<String, dynamic> json) {
    return CreatorOfferModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priceCents: json['priceCents'] ?? 0,
      currency: json['currency'] ?? 'USD',
      scope: json['scope'] ?? '',
      level: json['level'] ?? '',
    );
  }
}
