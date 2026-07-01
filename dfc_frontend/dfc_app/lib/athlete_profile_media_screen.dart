import 'package:flutter/foundation.dart';
import '../repositories/social_feed_repository.dart';
import '../state/social_feed_state.dart';

class SocialFeedController extends ChangeNotifier {
  final SocialFeedRepository repo;

  SocialFeedState _state = SocialFeedInitial();
  SocialFeedState get state => _state;

  SocialFeedController({required this.repo});

  Future<void> loadFeed() async {
    _state = SocialFeedLoading();
    notifyListeners();

    try {
      final feed = await repo.getFeed();
      _state = SocialFeedLoaded(feed);
    } catch (e) {
      _state = SocialFeedError(e.toString());
    } finally {
      notifyListeners();
    }
  }
}
