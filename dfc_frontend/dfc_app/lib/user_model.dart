class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String token;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? 'Fighter',
      role: json['role'] ?? 'user',
      token: json['token'] ?? '',
    );
  }
}
