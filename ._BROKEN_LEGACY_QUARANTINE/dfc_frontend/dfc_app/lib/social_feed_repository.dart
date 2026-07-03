import '../../api_service.dart';
import '../models/social_feed_model.dart';

class SocialFeedRepository {
  final ApiService api;
  SocialFeedRepository({required this.api});

  Future<List<SocialFeedModel>> getFeed() async {
    final data = await api.callFunction("getSocialFeed");
    final list = data["feed"] as List<dynamic>? ?? [];
    return list.map((e) => SocialFeedModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }
}