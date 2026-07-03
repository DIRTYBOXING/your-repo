import 'api_service.dart';

class CreatorSubscriptionRepository {
  final ApiService api;
  CreatorSubscriptionRepository(this.api);

  Future<List<Map<String, dynamic>>> listOffers(String creatorId) async {
    final data = await api.callFunction("listCreatorOffers", {
      "creatorId": creatorId,
    });
    return List<Map<String, dynamic>>.from(data);
  }

  Future<String> createOffer(Map<String, dynamic> payload) async {
    final res = await api.callFunction("createCreatorOffer", payload);
    return res["offerId"];
  }

  Future<String> subscribeToOffer(String offerId) async {
    final res = await api.callFunction("subscribeToOffer", {
      "offerId": offerId,
    });
    return res["entitlementId"];
  }

  Future<List<Map<String, dynamic>>> listEntitlements() async {
    final data = await api.callFunction("listUserEntitlements", {});
    return List<Map<String, dynamic>>.from(data);
  }
}