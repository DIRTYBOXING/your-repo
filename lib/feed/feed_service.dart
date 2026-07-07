// lib/feed/feed_service.dart (only the key method shown)
import 'dart:convert';

import '../services/api_client.dart';

class FeedService {
  final ApiClient api;
  FeedService(this.api);

  Future<List<dynamic>> fetchHomeFeed({
    int limit = 20,
    bool includePromotions = true,
  }) async {
    final res = await api.get(
      '/api/v1/feeds/home',
      params: {
        'limit': limit.toString(),
        'include_promotions': includePromotions ? 'true' : 'false',
      },
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['items'] as List<dynamic>;
    }
    return [];
  }
}
