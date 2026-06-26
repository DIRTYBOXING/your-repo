import 'package:equatable/equatable.dart';

class MarketItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int price;
  final String category;

  const MarketItem({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'price': price,
    'category': category,
  };

  factory MarketItem.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MarketItem(
      id: docId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] as num?)?.toInt() ?? 0,
      category: map['category'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, description, imageUrl, price, category];
}
