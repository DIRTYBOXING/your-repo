import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC STRIPE CONNECT SERVICE — Promoter Direct Payouts via Stripe
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Manages the Stripe Connect V2 onboarding flow for promoters.
///
/// How it works:
///   1. Promoter taps "Set Up Payouts" → creates a Stripe connected account
///   2. Stripe handles identity verification, bank details, compliance
///   3. Once live: every PPV/ticket sale routes money directly to promoter
///   4. DFC auto-collects platform fee (15% PPV, 10% tickets)
///   5. Promoter views earnings in their own Stripe Dashboard
///
/// Trust guarantee:
///   • Stripe sits between DFC, promoter, and the fan
///   • Promoter gets paid by Stripe, not by DFC promises
///   • Fan gets Stripe fraud protection and receipts
///   • DFC gets platform fee automatically, no manual splits
///
/// Firestore:
///   connected_accounts_v2/{userId} — Stripe Connect account status
///
/// ═══════════════════════════════════════════════════════════════════════════
class StripeConnectService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  static const String _connectedAccountsCollection = 'connected_accounts_v2';

  // ── State ──
  bool _isLoading = false;
  String? _error;
  ConnectAccountStatus? _accountStatus;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ConnectAccountStatus? get accountStatus => _accountStatus;

  bool get isFullyOnboarded =>
      _accountStatus?.onboardingStatus == 'complete' &&
      _accountStatus?.chargesEnabled == true &&
      _accountStatus?.payoutsEnabled == true;

  bool get hasAccount => _accountStatus?.hasAccount == true;

  String? _resolveOnboardingStatus({
    required bool hasAccount,
    String? rawStatus,
    bool onboardingComplete = false,
    bool readyToProcessPayments = false,
  }) {
    if (!hasAccount) return null;

    if (readyToProcessPayments) return 'complete';

    switch (rawStatus) {
      case 'active':
        return 'complete';
      case 'pending':
      case 'pending_verification':
        return 'pending_verification';
      case 'onboarding_in_progress':
        return 'onboarding_in_progress';
      case 'onboarding_required':
        return 'onboarding_required';
    }

    return onboardingComplete ? 'pending_verification' : 'onboarding_required';
  }

  ConnectAccountStatus _buildAccountStatusFromCallable(Map<String, dynamic> data) {
    final hasAccount = data['exists'] == true || data['accountId'] != null;
    final onboardingComplete = data['onboardingComplete'] == true;
    final readyToProcessPayments = data['readyToProcessPayments'] == true;

    return ConnectAccountStatus(
      hasAccount: hasAccount,
      accountId: data['accountId'] as String?,
      onboardingStatus: _resolveOnboardingStatus(
        hasAccount: hasAccount,
        rawStatus: data['status'] as String?,
        onboardingComplete: onboardingComplete,
        readyToProcessPayments: readyToProcessPayments,
      ),
      chargesEnabled: readyToProcessPayments,
      payoutsEnabled: readyToProcessPayments,
      detailsSubmitted: onboardingComplete,
      country: data['country'] as String?,
      defaultCurrency: data['defaultCurrency'] as String?,
      requirementsStatus: data['requirementsStatus'] as String?,
      readyToProcessPayments: readyToProcessPayments,
    );
  }

  ConnectAccountStatus _buildAccountStatusFromCache(Map<String, dynamic> data) {
    final readyToProcessPayments = data['cardPaymentsActive'] == true;
    final onboardingComplete = data['onboardingComplete'] == true;

    return ConnectAccountStatus(
      hasAccount: true,
      accountId: data['stripeAccountId'] as String?,
      onboardingStatus: _resolveOnboardingStatus(
        hasAccount: true,
        rawStatus: data['status'] as String?,
        onboardingComplete: onboardingComplete,
        readyToProcessPayments: readyToProcessPayments,
      ),
      chargesEnabled: readyToProcessPayments,
      payoutsEnabled: readyToProcessPayments,
      detailsSubmitted: onboardingComplete,
      country: data['country'] as String?,
      defaultCurrency: data['defaultCurrency'] as String?,
      requirementsStatus: data['requirementsStatus'] as String?,
      readyToProcessPayments: readyToProcessPayments,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONBOARDING
  // ═══════════════════════════════════════════════════════════════════════

  /// Start or resume Stripe Connect onboarding.
  /// Returns a URL to redirect the promoter to Stripe's hosted onboarding.
  Future<String?> startOnboarding({
    required String userId,
    required String email,
    String? businessName,
    String country = 'AU',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createResult = await _functions
          .httpsCallable('createConnectedAccountV2')
          .call({
        'userId': userId,
        'email': email,
        'displayName': businessName,
        'country': country,
      });

      final createData = Map<String, dynamic>.from(createResult.data as Map);
      if (createData['error'] != null) {
        throw Exception(createData['error']);
      }

      final linkResult = await _functions.httpsCallable('createAccountLink').call({
        'userId': userId,
      });

      final linkData = Map<String, dynamic>.from(linkResult.data as Map);
      if (linkData['error'] != null) {
        throw Exception(linkData['error']);
      }

      final accountId =
          (createData['accountId'] ?? linkData['accountId']) as String?;
      final url = linkData['onboardingUrl'] as String?;

      _accountStatus = ConnectAccountStatus(
        hasAccount: accountId != null,
        accountId: accountId,
        onboardingStatus: _resolveOnboardingStatus(
          hasAccount: accountId != null,
          rawStatus: (linkData['status'] ?? createData['status']) as String? ??
              'onboarding_in_progress',
        ),
      );

      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _error = 'Failed to start onboarding: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('StripeConnectService.startOnboarding error: $e');
      return null;
    }
  }

  /// Check the current Connect account status.
  /// Call this on promoter dashboard load to show payout readiness.
  Future<ConnectAccountStatus> checkStatus(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final callable = _functions.httpsCallable('getConnectedAccountStatus');
      final result = await callable.call({'userId': userId});

      final data = Map<String, dynamic>.from(result.data as Map);
      _accountStatus = _buildAccountStatusFromCallable(data);

      _isLoading = false;
      notifyListeners();
      return _accountStatus!;
    } catch (e) {
      _error = 'Failed to check status: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      debugPrint('StripeConnectService.checkStatus error: $e');
      return const ConnectAccountStatus(hasAccount: false);
    }
  }

  /// Get a Stripe-hosted management link for the connected account.
  /// This currently uses the platform billing portal path exposed by Functions.
  Future<String?> getStripeDashboardLink(String userId) async {
    try {
      final callable = _functions.httpsCallable('createBillingPortalSession');
      final result = await callable.call({'userId': userId});
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['error'] != null) {
        throw Exception(data['error']);
      }
      return data['portalUrl'] as String?;
    } catch (e) {
      debugPrint('StripeConnectService.getStripeDashboardLink error: $e');
      _error = 'Failed to generate Stripe management link';
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LOCAL FIRESTORE (cached status for offline/quick access)
  // ═══════════════════════════════════════════════════════════════════════

  /// Load cached Connect status from Firestore (no Stripe API call).
  Future<ConnectAccountStatus?> loadCachedStatus(String userId) async {
    try {
      final doc = await _firestore
          .collection(_connectedAccountsCollection)
          .doc(userId)
          .get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      _accountStatus = _buildAccountStatusFromCache(data);
      notifyListeners();
      return _accountStatus;
    } catch (e) {
      debugPrint('loadCachedStatus error: $e');
      return null;
    }
  }

  /// Check if a specific promoter has Connect set up (for payment routing).
  /// Used by PPV purchase flow to determine if money routes via Connect.
  Future<bool> isPromoterOnboarded(String promoterId) async {
    try {
      final doc = await _firestore
          .collection(_connectedAccountsCollection)
          .doc(promoterId)
          .get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      return data['cardPaymentsActive'] == true &&
          data['onboardingComplete'] == true;
    } catch (e) {
      debugPrint('isPromoterOnboarded error: $e');
      return false;
    }
  }
}

/// Connect account status model
class ConnectAccountStatus {
  final bool hasAccount;
  final String? accountId;
  final String? onboardingStatus;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final String? country;
  final String? defaultCurrency;
  final String? requirementsStatus;
  final bool readyToProcessPayments;

  const ConnectAccountStatus({
    required this.hasAccount,
    this.accountId,
    this.onboardingStatus,
    this.chargesEnabled = false,
    this.payoutsEnabled = false,
    this.detailsSubmitted = false,
    this.country,
    this.defaultCurrency,
    this.requirementsStatus,
    this.readyToProcessPayments = false,
  });
}
