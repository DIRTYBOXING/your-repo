import 'package:flutter/foundation.dart';
import 'creator_subscription_repository.dart';

class CreatorSubscriptionController extends ChangeNotifier {
  final CreatorSubscriptionRepository repo;

  bool loading = false;
  String? error;

  List<Map<String, dynamic>> offers = [];
  List<Map<String, dynamic>> entitlements = [];

  CreatorSubscriptionController(this.repo);

  Future<void> loadOffers(String creatorId) async {
    loading = true;
    notifyListeners();
    try {
      offers = await repo.listOffers(creatorId);
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadEntitlements() async {
    try {
      entitlements = await repo.listEntitlements();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  bool hasAccess(String creatorId, String scope, {String? level}) {
    return entitlements.any((e) {
      final matchCreator = e["creatorId"] == creatorId;
      final matchScope = e["scope"] == scope;
      final matchLevel = level == null || e["level"] == level;
      return matchCreator && matchScope && matchLevel && e["active"] == true;
    });
  }

  Future<String?> subscribe(String offerId) async {
    try {
      final id = await repo.subscribeToOffer(offerId);
      await loadEntitlements();
      return id;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return null;
    }
  }
}