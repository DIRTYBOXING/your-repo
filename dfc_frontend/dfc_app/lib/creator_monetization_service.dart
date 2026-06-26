import '../models/creator_offer_model.dart';

class CreatorMonetizationService {
  Future<List<CreatorOfferModel>> getOffers(String creatorId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      CreatorOfferModel(
        id: 'offer_1',
        title: 'INNER CIRCLE ACCESS',
        description: 'Get exclusive sparring footage, diet logs, and private DMs.',
        priceCents: 999,
        currency: 'USD',
        scope: 'fighter:vault',
        level: 'pro',
      ),
      CreatorOfferModel(
        id: 'offer_2',
        title: 'PPV + VAULT BUNDLE',
        description: 'Includes this weekend\'s PPV plus 1 month of vault access.',
        priceCents: 6499,
        currency: 'USD',
        scope: 'event:bundle',
        level: 'elite',
      ),
    ];
  }
}