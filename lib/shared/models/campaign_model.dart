import 'package:equatable/equatable.dart';

class Campaign extends Equatable {
  final String id;
  final String title;
  final String description;
  final double goalAmount;
  final double currentAmount;
  final String organizerId;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isActive;

  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.goalAmount,
    required this.currentAmount,
    required this.organizerId,
    this.imageUrl,
    required this.createdAt,
    required this.isActive,
  });

  factory Campaign.fromMap(Map<String, dynamic> map, String id) {
    return Campaign(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      goalAmount: (map['goalAmount'] ?? 0).toDouble(),
      currentAmount: (map['currentAmount'] ?? 0).toDouble(),
      organizerId: map['organizerId'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'goalAmount': goalAmount,
      'currentAmount': currentAmount,
      'organizerId': organizerId,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    goalAmount,
    currentAmount,
    organizerId,
    imageUrl,
    createdAt,
    isActive,
  ];
}
