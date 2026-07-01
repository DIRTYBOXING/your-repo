import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/pricing_engine.dart';
import '../../core/constants/stripe_config.dart';
// NOTE: flutter_stripe requires Firebase Core ^3.x
// Once Firebase is upgraded, uncomment:
// import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe Publishable Keys — loaded from build-time environment variables.
/// Set via `--dart-define=STRIPE_PK_TEST=pk_test_...` and `STRIPE_PK_LIVE=pk_live_...`
/// NEVER hardcode real keys in source code.
class StripeConfig {
  static const String publishableKeyTest = String.fromEnvironment(
    'STRIPE_PK_TEST',
    defaultValue: 'pk_test_NOT_CONFIGURED',
  );
  static const String publishableKeyLive = String.fromEnvironment(
    'STRIPE_PK_LIVE',
    defaultValue: 'pk_live_NOT_CONFIGURED',
  );

  static String get publishableKey => const bool.fromEnvironment('PRODUCTION')
      ? publishableKeyLive
      : publishableKeyTest;

  // Stripe requires Apple Merchant ID for Apple Pay
  static const String appleMerchantId = 'merchant.com.datafightcentral';
}

/// Payment Plans for Stripe integration
/// Note: Uses different class name to avoid conflict with SubscriptionPlan in subscription_service.dart
class PaymentPlan {
  final String id;
  final String name;
  final String stripePriceId;
  final double monthlyPrice;
  final List<String> features;

  const PaymentPlan({
    required this.id,
    required this.name,
    required this.stripePriceId,
    required this.monthlyPrice,
    required this.features,
  });

  static const free = PaymentPlan(
    id: 'free',
    name: 'Free',
    stripePriceId: '',
    monthlyPrice: 0,
    features: ['Basic dashboard', 'Community access', 'Limited AI insights'],
  );

  static const pro = PaymentPlan(
    id: 'pro',
    name: 'Pro Fighter',
    stripePriceId: 'price_pro_monthly', // Replace with actual Stripe Price ID
    monthlyPrice: 2.99,
    features: [
      'Full dashboard',
      'AI coaching',
      'Health signals',
      'Priority support',
    ],
  );

  static const elite = PaymentPlan(
    id: 'elite',
    name: 'Elite',
    stripePriceId: 'price_elite_monthly', // Replace with actual Stripe Price ID
    monthlyPrice: 9.99,
    features: [
      'Everything in Pro',
      'Personal AI coach',
      'Camp management',
      'Matchmaking',
    ],
  );

  static const supporter = PaymentPlan(
    id: 'supporter',
    name: 'Supporter',
    stripePriceId: 'price_supporter_monthly',
    monthlyPrice: 1.99,
    features: ['Ad-free feed', 'Supporter badge', 'Early event access'],
  );

  static List<PaymentPlan> get all => [free, supporter, pro, elite];
}

enum PaymentRail {
  card,
  applePay,
  googlePay,
  paypal,
  bankTransfer,
  bnpl,
  localWallet,
}

class GlobalPaymentRecommendation {
  final PaymentRail primary;
  final List<PaymentRail> fallbacks;
  final String reason;

  const GlobalPaymentRecommendation({
    required this.primary,
    required this.fallbacks,
    required this.reason,
  });

  String get primaryLabel {
    switch (primary) {
      case PaymentRail.applePay:
        return 'Apple Pay';
      case PaymentRail.googlePay:
        return 'Google Pay';
      case PaymentRail.paypal:
        return 'PayPal';
      case PaymentRail.bankTransfer:
        return 'Bank Transfer';
      case PaymentRail.bnpl:
        return 'Buy Now Pay Later';
      case PaymentRail.localWallet:
        return 'Local Wallet';
      case PaymentRail.card:
        return 'Card';
    }
  }
}

/// Payments + Subscriptions orchestration (Stripe/Play/App Store)
///
/// Hosted checkout mode uses Stripe Payment Links while native sheet setup
/// remains disabled until mobile Stripe SDK wiring is completed.
class PaymentsService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // Hosted Stripe Checkout via Cloud Functions.
  // Native PaymentSheet can be enabled when flutter_stripe SDK is upgraded.

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  PaymentPlan _currentPlan = PaymentPlan.free;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PaymentPlan get currentPlan => _currentPlan;
  bool get isPremium => _currentPlan.id != 'free';

  PaymentPlan _planFromId(String planId) {
    final normalized = planId.toLowerCase().trim();
    switch (normalized) {
      case 'free':
        return PaymentPlan.free;
      case 'supporter':
      case 'fan':
        return PaymentPlan.supporter;
      case 'pro':
      case 'fighter':
      case 'fighterpro':
        return PaymentPlan.pro;
      case 'elite':
      case 'coachmentor':
      case 'promotergym':
        return PaymentPlan.elite;
      default:
        return PaymentPlan.free;
    }
  }

  GlobalPaymentRecommendation recommendCheckoutRail({
    required String countryCode,
    required double amount,
    required bool isMobile,
  }) {
    final country = countryCode.toUpperCase();

    if (country == 'US' || country == 'CA' || country == 'GB') {
      return GlobalPaymentRecommendation(
        primary: isMobile ? PaymentRail.applePay : PaymentRail.card,
        fallbacks: const [
          PaymentRail.googlePay,
          PaymentRail.paypal,
          PaymentRail.card,
        ],
        reason:
            'Wallet-first conversion path for high card-penetration markets.',
      );
    }

    if (country == 'AU' || country == 'NZ') {
      return const GlobalPaymentRecommendation(
        primary: PaymentRail.bankTransfer,
        fallbacks: [
          PaymentRail.bnpl,
          PaymentRail.applePay,
          PaymentRail.googlePay,
          PaymentRail.card,
        ],
        reason:
            'Australia/NZ users favor account transfer + wallet + BNPL combinations.',
      );
    }

    if (country == 'IN' || country == 'PH' || country == 'ID') {
      return const GlobalPaymentRecommendation(
        primary: PaymentRail.localWallet,
        fallbacks: [PaymentRail.card, PaymentRail.bankTransfer],
        reason:
            'Mobile-first regions typically convert best with local wallet rails.',
      );
    }

    return GlobalPaymentRecommendation(
      primary: isMobile ? PaymentRail.googlePay : PaymentRail.card,
      fallbacks: const [
        PaymentRail.paypal,
        PaymentRail.bankTransfer,
        PaymentRail.card,
      ],
      reason: 'Global default: wallet-first on mobile, card-first on desktop.',
    );
  }

  Future<bool> openGlobalSubscriptionCheckout({
    required String userId,
    required String tier,
    required String billingCycle,
    required String countryCode,
    required bool isMobile,
  }) async {
    final yearly = billingCycle == 'yearly';
    final tierForStripe = switch (tier.toLowerCase()) {
      'fighter' => 'fighter pro',
      'promoter' => 'promoter & gym',
      'supporter' => 'supporter',
      _ => tier,
    };

    final link = DfcStripeLinks.subscriptionLink(tierForStripe, yearly: yearly);
    if (link == null) {
      _error = 'No checkout link configured for $tier / $billingCycle.';
      notifyListeners();
      return false;
    }

    final productKey = switch (tier.toLowerCase()) {
      'fighter' => 'fighter_pro',
      'promoter' => 'promoter_cmd',
      'supporter' => 'supporter',
      _ => 'fighter_pro',
    };

    final monthlyAmount = DfcPricingEngine.priceFor(
      productKey: productKey,
      countryCode: countryCode,
    ).usd;
    final amount = billingCycle == 'yearly'
        ? DfcPricingEngine.yearlyPrice(
            productKey: productKey,
            countryCode: countryCode,
          )
        : monthlyAmount;

    final recommendation = recommendCheckoutRail(
      countryCode: countryCode,
      amount: amount,
      isMobile: isMobile,
    );

    await _firestore.collection('checkout_attempts').add({
      'userId': userId,
      'tier': tier,
      'billingCycle': billingCycle,
      'countryCode': countryCode.toUpperCase(),
      'isMobile': isMobile,
      'recommendedPrimaryRail': recommendation.primary.name,
      'recommendedFallbackRails': recommendation.fallbacks
          .map((r) => r.name)
          .toList(),
      'checkoutLink': link,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final opened = await DfcStripeLinks.openPaymentLink(link);
    if (!opened) {
      _error = 'Could not open secure checkout link.';
      notifyListeners();
      return false;
    }

    return true;
  }

  /// Initialize Stripe SDK
  ///
  /// Currently uses hosted Stripe Checkout (Payment Links + Cloud Functions)
  /// so no client-side SDK initialization is needed. When flutter_stripe is
  /// enabled for native payment sheets, uncomment the SDK init block.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Hosted checkout mode — no client SDK required.
      // Validate that publishable key is configured (for future native use).
      final key = StripeConfig.publishableKey;
      if (key.contains('NOT_CONFIGURED')) {
        debugPrint(
          'PaymentsService: Stripe key not configured — '
          'hosted checkout still works via Cloud Functions.',
        );
      }

      // Load the user's current plan from Firestore if available
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize payments: $e';
      debugPrint(_error);
    }
  }

  /// Load user's current subscription from Firestore
  Future<void> loadUserSubscription(String userId) async {
    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (doc.exists) {
        final planId = doc.data()?['planId'] as String? ?? 'free';
        _currentPlan = _planFromId(planId);
      } else {
        _currentPlan = PaymentPlan.free;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load subscription: $e');
    }
  }

  /// Client-triggered sync after returning from hosted checkout.
  /// Returns true when an active paid subscription is detected.
  Future<bool> syncPostCheckoutStatus(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final callable = _functions.httpsCallable('syncSubscriptionStatus');
      final result = await callable.call({'userId': userId});
      final data = Map<String, dynamic>.from(result.data as Map);

      final isActive = (data['active'] as bool?) ?? false;
      final planId = (data['planId'] as String?) ?? 'free';

      _currentPlan = isActive ? _planFromId(planId) : PaymentPlan.free;
      notifyListeners();
      return isActive && _currentPlan.id != 'free';
    } catch (e) {
      _error = 'Failed to sync payment status: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Create a Stripe Checkout Session and redirect user
  Future<String?> createCheckoutSession({
    required String userId,
    required String planId,
    String? couponCode,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      // Call Cloud Function to create Stripe Checkout Session
      final callable = _functions.httpsCallable('createStripeCheckout');
      final result = await callable.call({
        'userId': userId,
        'planId': planId,
        'couponCode': couponCode,
        'successUrl': 'https://datafightcentral.web.app/',
        'cancelUrl': 'https://datafightcentral.web.app/',
      });

      final sessionUrl = result.data['url'] as String?;
      return sessionUrl;
    } catch (e) {
      _error = 'Failed to create checkout session: $e';
      debugPrint(_error);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Subscribe using hosted Stripe Checkout (redirects to Stripe-hosted page).
  ///
  /// Creates a Checkout Session via Cloud Function which returns a URL.
  /// The session enforces billing address collection so the user's
  /// postal/ZIP code is captured by Stripe automatically.
  Future<bool> subscribeWithPaymentSheet({
    required String userId,
    required PaymentPlan plan,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _setLoading(true);
    _error = null;

    try {
      // Map plan ID to a tier name for the checkout link system
      final tier = switch (plan.id) {
        'supporter' => 'supporter',
        'elite' => 'promoter & gym',
        'pro' => 'fighter pro',
        _ => 'fighter pro',
      };

      // Try hosted checkout via Cloud Function first
      final sessionUrl = await createCheckoutSession(
        userId: userId,
        planId: plan.id,
      );

      if (sessionUrl != null) {
        final opened = await DfcStripeLinks.openPaymentLink(sessionUrl);
        if (opened) {
          return true;
        }
      }

      // Fallback: direct payment link
      final opened = await openGlobalSubscriptionCheckout(
        userId: userId,
        tier: tier,
        billingCycle: 'monthly',
        countryCode: 'AU',
        isMobile: !kIsWeb,
      );
      return opened;
    } catch (e) {
      _error = 'Failed to open payment: $e';
      debugPrint(_error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final callable = _functions.httpsCallable('cancelSubscription');
      await callable.call({'userId': userId});

      _currentPlan = PaymentPlan.free;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to cancel subscription: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Restore purchases (for App Store / Play Store)
  Future<bool> restorePurchases(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      final callable = _functions.httpsCallable('restorePurchases');
      final result = await callable.call({'userId': userId});

      final planId = result.data['planId'] as String?;
      if (planId != null) {
        _currentPlan = PaymentPlan.all.firstWhere(
          (p) => p.id == planId,
          orElse: () => PaymentPlan.free,
        );
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = 'Failed to restore purchases: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Check if a specific feature is available on current plan
  bool hasFeature(String feature) {
    return _currentPlan.features.any(
      (f) => f.toLowerCase().contains(feature.toLowerCase()),
    );
  }

  /// Subscribe to a plan (convenience method for subscription_screen)
  /// This wraps subscribeWithPaymentSheet for simpler API
  Future<bool> subscribe({
    required String userId,
    required String planId,
  }) async {
    final plan = PaymentPlan.all.firstWhere(
      (p) => p.id == planId,
      orElse: () => PaymentPlan.free,
    );
    return subscribeWithPaymentSheet(userId: userId, plan: plan);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PROMO CODES / COUPONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Validate a promo code and get discount info
  /// Returns: {valid, code, percentOff, amountOffCents, discountCents, finalAmountCents, error}
  Future<Map<String, dynamic>> validatePromoCode({
    required String code,
    required String productType,
    required int amountCents,
  }) async {
    try {
      final callable = _functions.httpsCallable('validatePromoCode');
      final result = await callable.call({
        'code': code,
        'productType': productType,
        'amountCents': amountCents,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      return {'valid': false, 'error': 'Failed to validate promo code: $e'};
    }
  }

  /// Apply promo code and create payment intent with discount
  /// Returns: {paymentIntentId, clientSecret, finalAmountCents, discountCents, error}
  Future<Map<String, dynamic>> applyPromoCode({
    required String code,
    required String userId,
    required int amountCents,
    required String currency,
    required String productType,
    String? productId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final callable = _functions.httpsCallable('applyPromoCode');
      final result = await callable.call({
        'code': code,
        'userId': userId,
        'amountCents': amountCents,
        'currency': currency,
        'productType': productType,
        'productId': productId,
        'metadata': metadata,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      return {'error': 'Failed to apply promo code: $e'};
    }
  }

  /// Create a promo code (admin only)
  /// Returns: {success, couponId, code, error}
  Future<Map<String, dynamic>> createPromoCoupon({
    required String code,
    int? percentOff,
    int? amountOffCents,
    String currency = 'usd',
    int? maxRedemptions,
    DateTime? expiresAt,
    List<String>? productTypes,
  }) async {
    try {
      final callable = _functions.httpsCallable('createPromoCoupon');
      final result = await callable.call({
        'code': code,
        'percentOff': percentOff,
        'amountOffCents': amountOffCents,
        'currency': currency,
        'maxRedemptions': maxRedemptions,
        'expiresAt': expiresAt?.toIso8601String(),
        'productTypes': productTypes,
      });
      return Map<String, dynamic>.from(result.data as Map);
    } catch (e) {
      return {'error': 'Failed to create promo code: $e'};
    }
  }
}
