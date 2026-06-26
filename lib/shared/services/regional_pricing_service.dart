import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REGIONAL PRICING SERVICE — PPP + Currency Auto-Switch
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Calls the Cloud Function to get localized pricing based on user region.
/// AU/NZ markets get base AUD pricing, emerging markets get PPP-adjusted
/// rates, ensuring micro-transactions stay affordable worldwide.
///
/// Also handles round-by-round micro-unlock for live events.
///
/// Cloud Functions:
///   getRegionalPricing       → Returns localized price + micro-tier menu
///   purchaseRoundWithCredits → Spend DFC credits for one round
///   createRoundPaymentIntent → Stripe card payment for one round
///   checkRoundAccess         → Verify user has round-level access
///   getUnlockedRounds        → List all unlocked rounds for a fight
///
/// ═══════════════════════════════════════════════════════════════════════════
class RegionalPricingService with ChangeNotifier {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // ── State ──
  RegionalPrice? _currentPrice;
  String _detectedCountry = 'AU';
  bool _isLoading = false;
  String? _error;

  RegionalPrice? get currentPrice => _currentPrice;
  String get detectedCountry => _detectedCountry;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ═══════════════════════════════════════════════════════════════════════
  // REGIONAL PRICING — Get Localized Price
  // ═══════════════════════════════════════════════════════════════════════

  /// Fetch regional pricing for a base price in AUD cents.
  Future<RegionalPrice?> getRegionalPrice({
    required int basePriceCents,
    String? countryCode,
    String? tierId,
    String? eventId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _functions.httpsCallable('getRegionalPricing').call({
        'basePriceCents': basePriceCents,
        'countryCode': countryCode ?? _detectedCountry,
        'tierId': tierId,
        'eventId': eventId,
      });

      final data = result.data as Map<String, dynamic>;
      if (data.containsKey('error')) {
        _error = data['error'] as String;
        return null;
      }

      _currentPrice = RegionalPrice.fromMap(data);
      _detectedCountry = _currentPrice!.country;
      return _currentPrice;
    } catch (e) {
      _error = e.toString();
      debugPrint('RegionalPricingService.getRegionalPrice error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set detected country (e.g. from device locale or IP lookup).
  void setCountry(String countryCode) {
    _detectedCountry = countryCode.toUpperCase();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ROUND-BY-ROUND ACCESS — Micro-Unlock Per Round
  // ═══════════════════════════════════════════════════════════════════════

  /// Purchase a single round using DFC Fight Credits.
  Future<RoundAccessResult> purchaseRoundWithCredits({
    required String userId,
    required String ppvId,
    required String fightId,
    required int roundNumber,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('purchaseRoundWithCredits')
          .call({
            'userId': userId,
            'ppvId': ppvId,
            'fightId': fightId,
            'roundNumber': roundNumber,
          });

      final data = result.data as Map<String, dynamic>;
      return RoundAccessResult.fromMap(data);
    } catch (e) {
      debugPrint('purchaseRoundWithCredits error: $e');
      return RoundAccessResult(status: 'error', error: e.toString());
    }
  }

  /// Create a Stripe PaymentIntent for a single round (card payment).
  Future<RoundPaymentResult> createRoundPaymentIntent({
    required String userId,
    required String ppvId,
    required String fightId,
    required int roundNumber,
    String? promoterStripeAccountId,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createRoundPaymentIntent')
          .call({
            'userId': userId,
            'ppvId': ppvId,
            'fightId': fightId,
            'roundNumber': roundNumber,
            'countryCode': _detectedCountry,
            'promoterStripeAccountId': promoterStripeAccountId,
          });

      final data = result.data as Map<String, dynamic>;
      return RoundPaymentResult.fromMap(data);
    } catch (e) {
      debugPrint('createRoundPaymentIntent error: $e');
      return RoundPaymentResult(error: e.toString());
    }
  }

  /// Check if user has access to a specific round.
  Future<bool> checkRoundAccess({
    required String userId,
    required String ppvId,
    required String fightId,
    required int roundNumber,
  }) async {
    try {
      final result = await _functions.httpsCallable('checkRoundAccess').call({
        'userId': userId,
        'ppvId': ppvId,
        'fightId': fightId,
        'roundNumber': roundNumber,
      });

      final data = result.data as Map<String, dynamic>;
      return data['hasAccess'] == true;
    } catch (e) {
      debugPrint('checkRoundAccess error: $e');
      return false;
    }
  }

  /// Get all unlocked rounds for a fight.
  Future<List<UnlockedRound>> getUnlockedRounds({
    required String userId,
    required String ppvId,
    String? fightId,
  }) async {
    try {
      final result = await _functions.httpsCallable('getUnlockedRounds').call({
        'userId': userId,
        'ppvId': ppvId,
        'fightId': ?fightId,
      });

      final data = result.data as Map<String, dynamic>;
      final rounds = (data['rounds'] as List<dynamic>?) ?? [];
      return rounds
          .map((r) => UnlockedRound.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('getUnlockedRounds error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FIGHTER WALLET — Read Fighter Earnings
  // ═══════════════════════════════════════════════════════════════════════

  /// Get fighter's earnings wallet.
  Future<FighterWallet?> getFighterWallet(String fighterId) async {
    try {
      final result = await _functions.httpsCallable('getFighterWallet').call({
        'fighterId': fighterId,
      });

      final data = result.data as Map<String, dynamic>;
      if (data.containsKey('error')) return null;
      return FighterWallet.fromMap(data);
    } catch (e) {
      debugPrint('getFighterWallet error: $e');
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

class RegionalPrice {
  final String country;
  final String currency;
  final int priceCents;
  final String displayPrice;
  final double multiplier;
  final int roundPriceCents;
  final int mainEventPriceCents;
  final List<MicroTier> microTiers;
  final String region;

  RegionalPrice({
    required this.country,
    required this.currency,
    required this.priceCents,
    required this.displayPrice,
    required this.multiplier,
    required this.roundPriceCents,
    required this.mainEventPriceCents,
    this.microTiers = const [],
    this.region = 'global',
  });

  factory RegionalPrice.fromMap(Map<String, dynamic> m) {
    return RegionalPrice(
      country: m['country'] ?? 'AU',
      currency: m['currency'] ?? 'aud',
      priceCents: m['priceCents'] ?? 0,
      displayPrice: m['displayPrice'] ?? '',
      multiplier: (m['multiplier'] ?? 1.0).toDouble(),
      roundPriceCents: m['roundPriceCents'] ?? 250,
      mainEventPriceCents: m['mainEventPriceCents'] ?? 999,
      microTiers: ((m['microTiers'] as List<dynamic>?) ?? [])
          .map((t) => MicroTier.fromMap(t as Map<String, dynamic>))
          .toList(),
      region: m['region'] ?? 'global',
    );
  }
}

class MicroTier {
  final String id;
  final String name;
  final int priceCents;
  final String display;
  final String type;

  MicroTier({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.display,
    required this.type,
  });

  factory MicroTier.fromMap(Map<String, dynamic> m) {
    return MicroTier(
      id: m['id'] ?? '',
      name: m['name'] ?? '',
      priceCents: m['priceCents'] ?? 0,
      display: m['display'] ?? '',
      type: m['type'] ?? 'micro',
    );
  }
}

class RoundAccessResult {
  final String status;
  final String? compositeId;
  final String? method;
  final int? creditsUsed;
  final int? remainingBalance;
  final String? expiresAt;
  final String? error;

  RoundAccessResult({
    required this.status,
    this.compositeId,
    this.method,
    this.creditsUsed,
    this.remainingBalance,
    this.expiresAt,
    this.error,
  });

  bool get isSuccess => status == 'unlocked' || status == 'already_unlocked';

  factory RoundAccessResult.fromMap(Map<String, dynamic> m) {
    return RoundAccessResult(
      status: m['status'] ?? 'error',
      compositeId: m['compositeId'],
      method: m['method'],
      creditsUsed: m['creditsUsed'],
      remainingBalance: m['remainingBalance'],
      expiresAt: m['expiresAt'],
      error: m['error'],
    );
  }
}

class RoundPaymentResult {
  final String? clientSecret;
  final String? paymentIntentId;
  final int? amountCents;
  final String? currency;
  final String? displayPrice;
  final String? compositeId;
  final String? error;

  RoundPaymentResult({
    this.clientSecret,
    this.paymentIntentId,
    this.amountCents,
    this.currency,
    this.displayPrice,
    this.compositeId,
    this.error,
  });

  bool get hasError => error != null;

  factory RoundPaymentResult.fromMap(Map<String, dynamic> m) {
    return RoundPaymentResult(
      clientSecret: m['clientSecret'],
      paymentIntentId: m['paymentIntentId'],
      amountCents: m['amountCents'],
      currency: m['currency'],
      displayPrice: m['displayPrice'],
      compositeId: m['compositeId'],
      error: m['error'],
    );
  }
}

class UnlockedRound {
  final String fightId;
  final int roundNumber;
  final String method;

  UnlockedRound({
    required this.fightId,
    required this.roundNumber,
    required this.method,
  });

  factory UnlockedRound.fromMap(Map<String, dynamic> m) {
    return UnlockedRound(
      fightId: m['fightId'] ?? '',
      roundNumber: m['roundNumber'] ?? 0,
      method: m['method'] ?? 'unknown',
    );
  }
}

class FighterWallet {
  final String fighterId;
  final int pendingBalanceCents;
  final int lifetimeEarningsCents;
  final int totalPayoutsCents;
  final String currency;

  FighterWallet({
    required this.fighterId,
    required this.pendingBalanceCents,
    required this.lifetimeEarningsCents,
    required this.totalPayoutsCents,
    required this.currency,
  });

  double get pendingBalance => pendingBalanceCents / 100;
  double get lifetimeEarnings => lifetimeEarningsCents / 100;
  double get totalPayouts => totalPayoutsCents / 100;

  factory FighterWallet.fromMap(Map<String, dynamic> m) {
    return FighterWallet(
      fighterId: m['fighterId'] ?? '',
      pendingBalanceCents: m['pendingBalanceCents'] ?? 0,
      lifetimeEarningsCents: m['lifetimeEarningsCents'] ?? 0,
      totalPayoutsCents: m['totalPayoutsCents'] ?? 0,
      currency: m['currency'] ?? 'AUD',
    );
  }
}
