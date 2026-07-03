import 'package:flutter/foundation.dart';
import '../repositories/subscription_repository.dart';
import '../state/subscription_state.dart';

class SubscriptionController extends ChangeNotifier {
  final SubscriptionRepository repo;

  SubscriptionState _state = SubscriptionInitial();
  SubscriptionState get state => _state;

  SubscriptionController({required this.repo});

  Future<void> loadSubscription() async {
    _state = SubscriptionLoading();
    notifyListeners();
    try {
      final data = await repo.getUserSubscription();
      _state = SubscriptionLoaded(data);
    } catch (e) {
      _state = SubscriptionError(e.toString());
    } finally {
      notifyListeners();
    }
  }
}
