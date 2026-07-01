// lib/models/feed_item.dart
import 'dart:convert';

class DfcFeedItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final bool isPromotion;

  DfcFeedItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.isPromotion = false,
  });

  factory DfcFeedItem.fromJson(Map<String, dynamic> json) {
    return DfcFeedItem(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      isPromotion: json['promotion'] == true,
    );
  }

  static List<DfcFeedItem> listFromJson(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((e) => DfcFeedItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
