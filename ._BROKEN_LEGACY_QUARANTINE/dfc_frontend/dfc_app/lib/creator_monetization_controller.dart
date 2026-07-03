import 'package:flutter/foundation.dart';
import '../models/creator_offer_model.dart';
import '../services/creator_monetization_service.dart';

class CreatorMonetizationController extends ChangeNotifier {
  final _service = CreatorMonetizationService();

  bool isLoading = true;
  String? error;
  List<CreatorOfferModel> offers = [];

  Future<void> loadOffers(String creatorId) async {
    isLoading = true;
    notifyListeners();

    try {
      offers = await _service.getOffers(creatorId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> subscribe(String offerId) async {
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate checkout
  }
}