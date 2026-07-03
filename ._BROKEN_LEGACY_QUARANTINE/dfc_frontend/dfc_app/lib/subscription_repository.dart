import '../../api_service.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final ApiService api;
  SubscriptionRepository({required this.api});

  Future<SubscriptionModel> getUserSubscription() async {
    final data = await api.callFunction("getUserSubscription");
    return SubscriptionModel.fromJson(data);
  }
}
