class FighterModel {
  final String id;
  final String firstName;
  final String lastName;
  final String nickname;
  final String weightClass;
  final String gymId;
  final String promotionId;
  final String profileImageUrl;

  FighterModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.weightClass,
    required this.gymId,
    required this.promotionId,
    required this.profileImageUrl,
  });

  factory FighterModel.fromJson(Map<String, dynamic> json) {
    return FighterModel(
      id: json['id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      nickname: json['nickname'] ?? '',
      weightClass: json['weight_class'] ?? '',
      gymId: json['gym_id'] ?? '',
      promotionId: json['promotion_id'] ?? '',
      profileImageUrl: json['profile_image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'nickname': nickname,
    'weight_class': weightClass,
    'gym_id': gymId,
    'promotion_id': promotionId,
    'profile_image_url': profileImageUrl,
  };
}
