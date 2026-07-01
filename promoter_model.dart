class PromoterModel {
  final String id;
  final String name;
  final String companyName;
  final String email;

  PromoterModel({
    required this.id,
    required this.name,
    required this.companyName,
    required this.email,
  });

  factory PromoterModel.fromJson(Map<String, dynamic> json) {
    return PromoterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      companyName: json['company_name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'company_name': companyName,
    'email': email,
  };
}
