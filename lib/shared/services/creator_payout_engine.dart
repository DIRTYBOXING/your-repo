import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CREATOR PAYOUT ENGINE — Revenue Distribution & Disbursement
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles the full payout lifecycle for promoters, fighters, and creators:
///
///   1. Earnings Accumulation — track revenue per creator from PPV, tickets,
///      marketplace sales, tips, and sponsorships
///   2. Payout Scheduling — configurable cycles (weekly, biweekly, monthly)
///   3. Disbursement — Stripe Connect transfers, PayPal, or bank wire
///   4. Tax Compliance — 1099 (US), W-8BEN (international), GST/VAT
///   5. Revenue Transparency — real-time earnings dashboard data
///
/// Revenue Splits — DFC Sliding Agreement:
///   PPV:         Sliding 30–50% DFC / 70–50% creator (based on exposure)
///   Tickets:     85% promoter / 15% DFC
///   Marketplace: 75% seller  / 25% DFC
///   Donations:   100% recipient (DFC absorbs Stripe fees)
///   Sponsorship: 75% creator / 25% DFC
///
/// Firestore Collections:
///   creator_earnings/{creatorId}       — Accumulated earnings balance
///   payout_requests/{requestId}        — Payout request records
///   payout_history/{payoutId}          — Completed payout audit trail
///   payout_schedules/{creatorId}       — Payout schedule preferences
///   tax_profiles/{creatorId}           — Tax form status & withholding
///
/// ═══════════════════════════════════════════════════════════════════════════
class CreatorPayoutEngine with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State ──
  bool _isProcessing = false;
  String? _error;

  bool get isProcessing => _isProcessing;
  String? get error => _error;

  // ── Minimum Payout Thresholds (USD equivalent) ──
  static const Map<String, double> minimumPayouts = {
    'AUD': 50.0,
    'USD': 25.0,
    'GBP': 20.0,
    'EUR': 25.0,
    'NZD': 50.0,
    'THB': 750.0,
    'SGD': 35.0,
    'CAD': 30.0,
    'ZAR': 500.0,
    'NGN': 15000.0,
    'BRL': 100.0,
    'MXN': 500.0,
    'INR': 2000.0,
    'PHP': 1500.0,
    'JPY': 3000.0,
  };

  // ── Platform Fee Constants ──
  // PPV uses a sliding agreement (30–50% DFC) based on exposure.
  // The base constant is the floor; actual PPV split is computed dynamically.
  static const double ppvCreatorShareFloor = 0.70; // At 0 buys (DFC gets 30%)
  static const double ppvCreatorShareCeiling =
      0.50; // At 10k+ buys (DFC gets 50%)
  static const double ticketCreatorShare = 0.85;
  static const double marketplaceCreatorShare = 0.75;
  static const double donationCreatorShare = 1.0;
  static const double sponsorshipCreatorShare = 0.75;

  /// Sliding PPV creator share based on buy count / exposure.
  /// Smoothly interpolates: 70% creator at 0 buys → 50% creator at 10k+ buys.
  static double ppvCreatorShareForExposure(int exposure) {
    const int maxExposure = 10000;
    if (exposure <= 0) return ppvCreatorShareFloor;
    if (exposure >= maxExposure) return ppvCreatorShareCeiling;
    return ppvCreatorShareFloor -
        (ppvCreatorShareFloor - ppvCreatorShareCeiling) *
            (exposure / maxExposure);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EARNINGS TRACKING
  // ═══════════════════════════════════════════════════════════════════════

  /// Record earnings from a completed transaction
  Future<void> recordEarnings({
    required String creatorId,
    required String transactionId,
    required EarningsType type,
    required double grossAmount,
    required String currency,
    String? sourceEventId,
    String? buyerUserId,
  }) async {
    try {
      final creatorShare = switch (type) {
        EarningsType.ppv =>
          ppvCreatorShareFloor, // Base floor; caller can override with sliding
        EarningsType.ticket => ticketCreatorShare,
        EarningsType.marketplace => marketplaceCreatorShare,
        EarningsType.donation => donationCreatorShare,
        EarningsType.sponsorship => sponsorshipCreatorShare,
        EarningsType.tip => donationCreatorShare,
      };

      final netAmount = grossAmount * creatorShare;
      final platformFee = grossAmount - netAmount;

      // Record individual earning
      await _firestore.collection('creator_earnings_ledger').add({
        'creatorId': creatorId,
        'transactionId': transactionId,
        'type': type.name,
        'grossAmount': grossAmount,
        'netAmount': netAmount,
        'platformFee': platformFee,
        'currency': currency,
        'sourceEventId': sourceEventId,
        'buyerUserId': buyerUserId,
        'status': 'cleared',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update running balance
      await _firestore.collection('creator_earnings').doc(creatorId).set({
        'creatorId': creatorId,
        'pendingBalance': FieldValue.increment(netAmount),
        'lifetimeEarnings': FieldValue.increment(netAmount),
        'lifetimePlatformFees': FieldValue.increment(platformFee),
        'lastEarningAt': FieldValue.serverTimestamp(),
        'currency': currency,
        'transactionCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('CreatorPayoutEngine.recordEarnings error: $e');
    }
  }

  /// Get creator's current earnings summary
  Future<CreatorEarningsSummary?> getEarningsSummary(String creatorId) async {
    try {
      final doc = await _firestore
          .collection('creator_earnings')
          .doc(creatorId)
          .get();

      if (!doc.exists) {
        return CreatorEarningsSummary(
          creatorId: creatorId,
          pendingBalance: 0,
          lifetimeEarnings: 0,
          lifetimePaidOut: 0,
          currency: 'AUD',
        );
      }

      final data = doc.data()!;
      return CreatorEarningsSummary(
        creatorId: creatorId,
        pendingBalance: (data['pendingBalance'] as num?)?.toDouble() ?? 0,
        lifetimeEarnings: (data['lifetimeEarnings'] as num?)?.toDouble() ?? 0,
        lifetimePaidOut: (data['lifetimePaidOut'] as num?)?.toDouble() ?? 0,
        currency: data['currency'] as String? ?? 'AUD',
        lastEarningAt: (data['lastEarningAt'] as Timestamp?)?.toDate(),
        lastPayoutAt: (data['lastPayoutAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      debugPrint('CreatorPayoutEngine.getEarningsSummary error: $e');
      return null;
    }
  }

  /// Get detailed earnings breakdown by type
  Future<Map<EarningsType, double>> getEarningsBreakdown(
    String creatorId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      Query query = _firestore
          .collection('creator_earnings_ledger')
          .where('creatorId', isEqualTo: creatorId);

      if (from != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: from);
      }
      if (to != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: to);
      }

      final snap = await query.get();
      final breakdown = <EarningsType, double>{};

      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final typeStr = data['type'] as String? ?? 'ppv';
        final type = EarningsType.values.firstWhere(
          (t) => t.name == typeStr,
          orElse: () => EarningsType.ppv,
        );
        final amount = (data['netAmount'] as num?)?.toDouble() ?? 0;
        breakdown[type] = (breakdown[type] ?? 0) + amount;
      }

      return breakdown;
    } catch (e) {
      debugPrint('getEarningsBreakdown error: $e');
      return {};
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAYOUT SCHEDULING
  // ═══════════════════════════════════════════════════════════════════════

  /// Set creator's payout schedule preferences
  Future<void> setPayoutSchedule({
    required String creatorId,
    required PayoutFrequency frequency,
    required PayoutMethod method,
    String? bankAccountId,
    String? paypalEmail,
    String? stripeConnectId,
  }) async {
    try {
      await _firestore.collection('payout_schedules').doc(creatorId).set({
        'creatorId': creatorId,
        'frequency': frequency.name,
        'method': method.name,
        'bankAccountId': bankAccountId,
        'paypalEmail': paypalEmail,
        'stripeConnectId': stripeConnectId,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('setPayoutSchedule error: $e');
    }
  }

  /// Request a manual payout (outside scheduled cycle)
  Future<PayoutResult> requestPayout({
    required String creatorId,
    double? amount,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Get current balance
      final earnings = await getEarningsSummary(creatorId);
      if (earnings == null) {
        return _payoutError('Could not fetch earnings');
      }

      final payoutAmount = amount ?? earnings.pendingBalance;

      // Check minimum threshold
      final minPayout = minimumPayouts[earnings.currency] ?? 25.0;
      if (payoutAmount < minPayout) {
        return _payoutError(
          'Minimum payout is ${earnings.currency} $minPayout',
        );
      }

      if (payoutAmount > earnings.pendingBalance) {
        return _payoutError('Insufficient balance');
      }

      // Check tax compliance
      final taxOk = await _checkTaxCompliance(creatorId);
      if (!taxOk) {
        return _payoutError(
          'Tax forms required before payout. Complete your tax profile.',
        );
      }

      // Create payout request
      final ref = _firestore.collection('payout_requests').doc();
      await ref.set({
        'payoutId': ref.id,
        'creatorId': creatorId,
        'amount': payoutAmount,
        'currency': earnings.currency,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      // Deduct from pending balance
      await _firestore.collection('creator_earnings').doc(creatorId).update({
        'pendingBalance': FieldValue.increment(-payoutAmount),
        'lifetimePaidOut': FieldValue.increment(payoutAmount),
        'lastPayoutAt': FieldValue.serverTimestamp(),
      });

      // Record in payout history
      await _firestore.collection('payout_history').add({
        'payoutId': ref.id,
        'creatorId': creatorId,
        'amount': payoutAmount,
        'currency': earnings.currency,
        'status': 'processing',
        'requestedAt': FieldValue.serverTimestamp(),
      });

      return PayoutResult(
        success: true,
        payoutId: ref.id,
        amount: payoutAmount,
        currency: earnings.currency,
        estimatedArrival: _estimateArrival(),
      );
    } catch (e) {
      _error = 'Payout request failed: $e';
      return _payoutError('System error processing payout');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  PayoutResult _payoutError(String message) {
    _error = message;
    return PayoutResult(success: false, errorMessage: message);
  }

  DateTime _estimateArrival() {
    // Stripe Connect: 2 business days standard, 1 day instant
    return DateTime.now().add(const Duration(days: 3));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TAX COMPLIANCE
  // ═══════════════════════════════════════════════════════════════════════

  /// Get creator's tax profile status
  Future<TaxProfile?> getTaxProfile(String creatorId) async {
    try {
      final doc = await _firestore
          .collection('tax_profiles')
          .doc(creatorId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return TaxProfile(
        creatorId: creatorId,
        country: data['country'] as String? ?? '',
        taxFormType: data['taxFormType'] as String? ?? '',
        isCompliant: data['isCompliant'] as bool? ?? false,
        taxId: data['taxId'] as String?,
        withholdingRate: (data['withholdingRate'] as num?)?.toDouble() ?? 0,
        lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save/update creator tax profile
  Future<void> saveTaxProfile({
    required String creatorId,
    required String country,
    required String taxFormType,
    String? taxId,
  }) async {
    try {
      // Determine withholding rate based on country
      final withholdingRate = _getWithholdingRate(country, taxFormType);

      await _firestore.collection('tax_profiles').doc(creatorId).set({
        'creatorId': creatorId,
        'country': country,
        'taxFormType': taxFormType,
        'taxId': taxId,
        'withholdingRate': withholdingRate,
        'isCompliant': taxId != null && taxId.isNotEmpty,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('saveTaxProfile error: $e');
    }
  }

  double _getWithholdingRate(String country, String formType) {
    // US creators: 0% if W-9 filed, 24% backup withholding otherwise
    if (country == 'US') return formType == 'W-9' ? 0.0 : 0.24;
    // Treaty countries with W-8BEN: reduced rate
    const treatyCountries = {
      'AU': 0.05,
      'GB': 0.0,
      'CA': 0.0,
      'NZ': 0.05,
      'DE': 0.0,
      'FR': 0.0,
      'JP': 0.10,
      'TH': 0.15,
      'SG': 0.0,
      'IE': 0.0,
      'NL': 0.0,
    };
    if (treatyCountries.containsKey(country)) {
      return treatyCountries[country]!;
    }
    // Non-treaty international: 30% withholding
    return formType == 'W-8BEN' ? 0.30 : 0.30;
  }

  Future<bool> _checkTaxCompliance(String creatorId) async {
    final profile = await getTaxProfile(creatorId);
    // Allow payout if no profile yet (first-time) or if compliant
    return profile == null || profile.isCompliant;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PAYOUT HISTORY & REPORTING
  // ═══════════════════════════════════════════════════════════════════════

  /// Get payout history for a creator
  Future<List<PayoutRecord>> getPayoutHistory(
    String creatorId, {
    int limit = 20,
  }) async {
    try {
      final snap = await _firestore
          .collection('payout_history')
          .where('creatorId', isEqualTo: creatorId)
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return PayoutRecord(
          payoutId: data['payoutId'] as String? ?? doc.id,
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          currency: data['currency'] as String? ?? 'AUD',
          status: data['status'] as String? ?? 'unknown',
          requestedAt: (data['requestedAt'] as Timestamp?)?.toDate(),
          completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('getPayoutHistory error: $e');
      return [];
    }
  }

  /// Platform-wide payout analytics (admin)
  Future<PayoutAnalytics> getPlatformPayoutAnalytics() async {
    try {
      final pending = await _firestore
          .collection('payout_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      final completed = await _firestore
          .collection('payout_history')
          .where('status', isEqualTo: 'completed')
          .get();

      double totalPending = 0;
      for (final doc in pending.docs) {
        totalPending += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }

      double totalPaidOut = 0;
      for (final doc in completed.docs) {
        totalPaidOut += (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }

      return PayoutAnalytics(
        pendingPayouts: pending.docs.length,
        totalPendingAmount: totalPending,
        completedPayouts: completed.docs.length,
        totalPaidOut: totalPaidOut,
      );
    } catch (e) {
      return const PayoutAnalytics(
        pendingPayouts: 0,
        totalPendingAmount: 0,
        completedPayouts: 0,
        totalPaidOut: 0,
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum EarningsType { ppv, ticket, marketplace, donation, sponsorship, tip }

enum PayoutFrequency { weekly, biweekly, monthly, manual }

enum PayoutMethod { stripeConnect, paypal, bankWire }

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class CreatorEarningsSummary {
  final String creatorId;
  final double pendingBalance;
  final double lifetimeEarnings;
  final double lifetimePaidOut;
  final String currency;
  final DateTime? lastEarningAt;
  final DateTime? lastPayoutAt;

  const CreatorEarningsSummary({
    required this.creatorId,
    required this.pendingBalance,
    required this.lifetimeEarnings,
    required this.lifetimePaidOut,
    required this.currency,
    this.lastEarningAt,
    this.lastPayoutAt,
  });

  double get availableForPayout => pendingBalance;
}

class PayoutResult {
  final bool success;
  final String? payoutId;
  final double? amount;
  final String? currency;
  final DateTime? estimatedArrival;
  final String? errorMessage;

  const PayoutResult({
    required this.success,
    this.payoutId,
    this.amount,
    this.currency,
    this.estimatedArrival,
    this.errorMessage,
  });
}

class PayoutRecord {
  final String payoutId;
  final double amount;
  final String currency;
  final String status;
  final DateTime? requestedAt;
  final DateTime? completedAt;

  const PayoutRecord({
    required this.payoutId,
    required this.amount,
    required this.currency,
    required this.status,
    this.requestedAt,
    this.completedAt,
  });
}

class TaxProfile {
  final String creatorId;
  final String country;
  final String taxFormType;
  final bool isCompliant;
  final String? taxId;
  final double withholdingRate;
  final DateTime? lastUpdated;

  const TaxProfile({
    required this.creatorId,
    required this.country,
    required this.taxFormType,
    required this.isCompliant,
    this.taxId,
    required this.withholdingRate,
    this.lastUpdated,
  });
}

class PayoutAnalytics {
  final int pendingPayouts;
  final double totalPendingAmount;
  final int completedPayouts;
  final double totalPaidOut;

  const PayoutAnalytics({
    required this.pendingPayouts,
    required this.totalPendingAmount,
    required this.completedPayouts,
    required this.totalPaidOut,
  });
}
