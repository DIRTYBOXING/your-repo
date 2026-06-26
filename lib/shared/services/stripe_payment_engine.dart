import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// STRIPE PAYMENT ENGINE — The Money Plumbing
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles the full Stripe payment lifecycle:
///   • PaymentIntent creation via Cloud Functions
///   • Webhook event processing (charge.succeeded, charge.failed, etc.)
///   • Subscription lifecycle (create, renew, cancel, dunning)
///   • PPV one-time purchases with token-gated access
///   • Multi-currency support (AUD, USD, THB, GBP, EUR, NZD)
///   • Refund processing
///   • Dispute handling
///
/// Firestore Collections:
///   payment_intents/{intentId}     — Stripe PaymentIntent mirror
///   transactions/{txnId}           — Completed transaction ledger
///   refunds/{refundId}             — Refund records
///   stripe_customers/{userId}      — Stripe customer mapping
///   webhook_events/{eventId}       — Webhook audit trail
///
/// Revenue Split (Sliding Agreement — NOT fixed tiers):
///   PPV:           70-50% promoter / 30-50% DFC (sliding based on exposure)
///   Subscriptions: 100% DFC platform
///   Marketplace:   75% seller / 25% DFC platform
///   Tickets:       85% promoter / 15% DFC platform
///   Donations:     100% to recipient (DFC absorbs Stripe fees)
///
/// ═══════════════════════════════════════════════════════════════════════════
class StripePaymentEngine with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  Future<String?> _resolvePpvDocumentId(String ppvEventId) async {
    try {
      final directDoc = await _firestore
          .collection('ppv_events')
          .doc(ppvEventId)
          .get();
      if (directDoc.exists) {
        return directDoc.id;
      }

      final eventIdSnapshot = await _firestore
          .collection('ppv_events')
          .where('eventId', isEqualTo: ppvEventId)
          .limit(1)
          .get();
      if (eventIdSnapshot.docs.isNotEmpty) {
        return eventIdSnapshot.docs.first.id;
      }
    } catch (e) {
      debugPrint('StripePaymentEngine._resolvePpvDocumentId error: $e');
    }
    return null;
  }

  // ── State ──
  bool _isProcessing = false;
  String? _error;
  String? _lastTransactionId;

  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String? get lastTransactionId => _lastTransactionId;

  // ── Revenue Split Constants (sliding model — PPV floor) ──
  static const double ppvPlatformFee = 0.30;
  static const double marketplacePlatformFee = 0.25;
  static const double ticketPlatformFee = 0.15;
  static const double donationPlatformFee = 0.0;

  // ── Supported Currencies ──
  static const Map<String, CurrencyConfig> supportedCurrencies = {
    'AUD': CurrencyConfig(
      code: 'AUD',
      symbol: r'A$',
      name: 'Australian Dollar',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'USD': CurrencyConfig(
      code: 'USD',
      symbol: r'$',
      name: 'US Dollar',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'GBP': CurrencyConfig(
      code: 'GBP',
      symbol: '£',
      name: 'British Pound',
      stripeMin: 30,
      decimalPlaces: 2,
    ),
    'EUR': CurrencyConfig(
      code: 'EUR',
      symbol: '€',
      name: 'Euro',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'NZD': CurrencyConfig(
      code: 'NZD',
      symbol: r'NZ$',
      name: 'New Zealand Dollar',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'THB': CurrencyConfig(
      code: 'THB',
      symbol: '฿',
      name: 'Thai Baht',
      stripeMin: 1000,
      decimalPlaces: 2,
    ),
    'SGD': CurrencyConfig(
      code: 'SGD',
      symbol: r'S$',
      name: 'Singapore Dollar',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'CAD': CurrencyConfig(
      code: 'CAD',
      symbol: r'C$',
      name: 'Canadian Dollar',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'JPY': CurrencyConfig(
      code: 'JPY',
      symbol: '¥',
      name: 'Japanese Yen',
      stripeMin: 50,
      decimalPlaces: 0,
    ),
    'ZAR': CurrencyConfig(
      code: 'ZAR',
      symbol: 'R',
      name: 'South African Rand',
      stripeMin: 500,
      decimalPlaces: 2,
    ),
    'NGN': CurrencyConfig(
      code: 'NGN',
      symbol: '₦',
      name: 'Nigerian Naira',
      stripeMin: 5000,
      decimalPlaces: 2,
    ),
    'BRL': CurrencyConfig(
      code: 'BRL',
      symbol: r'R$',
      name: 'Brazilian Real',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'MXN': CurrencyConfig(
      code: 'MXN',
      symbol: r'MX$',
      name: 'Mexican Peso',
      stripeMin: 1000,
      decimalPlaces: 2,
    ),
    'INR': CurrencyConfig(
      code: 'INR',
      symbol: '₹',
      name: 'Indian Rupee',
      stripeMin: 50,
      decimalPlaces: 2,
    ),
    'PHP': CurrencyConfig(
      code: 'PHP',
      symbol: '₱',
      name: 'Philippine Peso',
      stripeMin: 2500,
      decimalPlaces: 2,
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════
  // PAYMENT INTENT — Create + Confirm
  // ═══════════════════════════════════════════════════════════════════════

  /// Create a PaymentIntent for a PPV purchase
  Future<PaymentIntentResult?> createPPVPaymentIntent({
    required String userId,
    required String ppvEventId,
    required int amountCents,
    required String currency,
    required String tier,
    Map<String, String>? metadata,
  }) async {
    _error =
        'PPV PaymentIntent checkout has been retired. Use hosted checkout instead.';
    notifyListeners();
    return null;
  }

  /// Create a PaymentIntent for event tickets
  Future<PaymentIntentResult?> createTicketPaymentIntent({
    required String userId,
    required String eventId,
    required int amountCents,
    required String currency,
    required String ticketTier,
    required int quantity,
  }) async {
    return _createPaymentIntent(
      userId: userId,
      amountCents: amountCents * quantity,
      currency: currency,
      productType: 'ticket',
      productId: eventId,
      metadata: {
        'event_id': eventId,
        'ticket_tier': ticketTier,
        'quantity': quantity.toString(),
        'platform_fee_pct': ticketPlatformFee.toString(),
      },
    );
  }

  /// Create a PaymentIntent for marketplace purchases
  Future<PaymentIntentResult?> createMarketplacePaymentIntent({
    required String userId,
    required String orderId,
    required String sellerId,
    required int amountCents,
    required String currency,
  }) async {
    return _createPaymentIntent(
      userId: userId,
      amountCents: amountCents,
      currency: currency,
      productType: 'marketplace',
      productId: orderId,
      metadata: {
        'order_id': orderId,
        'seller_id': sellerId,
        'platform_fee_pct': marketplacePlatformFee.toString(),
      },
    );
  }

  /// Create a PaymentIntent for donations
  Future<PaymentIntentResult?> createDonationPaymentIntent({
    required String userId,
    required String recipientId,
    required int amountCents,
    required String currency,
    String? message,
  }) async {
    return _createPaymentIntent(
      userId: userId,
      amountCents: amountCents,
      currency: currency,
      productType: 'donation',
      productId: 'donation_$recipientId',
      metadata: {
        'recipient_id': recipientId,
        // ignore: use_null_aware_elements
        if (message != null) 'message': message,
        'platform_fee_pct': donationPlatformFee.toString(),
      },
    );
  }

  Future<PaymentIntentResult?> _createPaymentIntent({
    required String userId,
    required int amountCents,
    required String currency,
    required String productType,
    required String productId,
    Map<String, String>? metadata,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Validate currency
      final curr = currency.toUpperCase();
      final config = supportedCurrencies[curr];
      if (config == null) {
        _error = 'Currency $curr is not supported';
        return null;
      }
      if (amountCents < config.stripeMin) {
        _error =
            'Amount below minimum for $curr (${config.stripeMin} ${config.code})';
        return null;
      }

      // Call Cloud Function to create PaymentIntent
      final callable = _functions.httpsCallable('createPaymentIntent');
      final result = await callable.call({
        'userId': userId,
        'amountCents': amountCents,
        'currency': curr,
        'productType': productType,
        'productId': productId,
        'metadata': metadata ?? {},
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final intentResult = PaymentIntentResult(
        paymentIntentId: data['paymentIntentId'] as String,
        clientSecret: data['clientSecret'] as String,
        status: data['status'] as String? ?? 'requires_payment_method',
        amountCents: amountCents,
        currency: curr,
      );

      // Record in Firestore for audit
      await _firestore
          .collection('payment_intents')
          .doc(intentResult.paymentIntentId)
          .set({
            'userId': userId,
            'amountCents': amountCents,
            'currency': curr,
            'productType': productType,
            'productId': productId,
            'status': intentResult.status,
            'metadata': metadata,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return intentResult;
    } catch (e) {
      _error = 'Payment failed: $e';
      debugPrint('StripePaymentEngine._createPaymentIntent error: $e');
      return null;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TRANSACTION RECORDING
  // ═══════════════════════════════════════════════════════════════════════

  /// Record a completed transaction (called by webhook handler)
  Future<String?> recordTransaction({
    required String paymentIntentId,
    required String userId,
    required String productType,
    required String productId,
    required int amountCents,
    required String currency,
    required double platformFeePct,
    String? promoterId,
    String? sellerId,
  }) async {
    try {
      final platformFeeCents = (amountCents * platformFeePct).round();
      final payoutCents = amountCents - platformFeeCents;
      final recipientId = promoterId ?? sellerId;

      // Use batch write for atomicity — both transaction record and
      // payment intent update succeed or fail together
      final batch = _firestore.batch();

      final txnRef = _firestore.collection('transactions').doc();
      batch.set(txnRef, {
        'paymentIntentId': paymentIntentId,
        'userId': userId,
        'productType': productType,
        'productId': productId,
        'amountCents': amountCents,
        'currency': currency,
        'platformFeeCents': platformFeeCents,
        'platformFeePct': platformFeePct,
        'payoutCents': payoutCents,
        'recipientId': recipientId,
        'payoutStatus': recipientId != null ? 'pending' : 'n/a',
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.update(
        _firestore.collection('payment_intents').doc(paymentIntentId),
        {
          'status': 'succeeded',
          'transactionId': txnRef.id,
          'completedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      _lastTransactionId = txnRef.id;

      notifyListeners();
      return txnRef.id;
    } catch (e) {
      debugPrint('StripePaymentEngine.recordTransaction CRITICAL error: $e');
      // Record the failure for manual reconciliation
      try {
        await _firestore.collection('failed_transactions').add({
          'paymentIntentId': paymentIntentId,
          'userId': userId,
          'productType': productType,
          'productId': productId,
          'amountCents': amountCents,
          'error': e.toString(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        debugPrint(
          'StripePaymentEngine: Failed to record transaction failure audit log',
        );
      }
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // WEBHOOK EVENT PROCESSING
  // ═══════════════════════════════════════════════════════════════════════

  /// Process incoming Stripe webhook events
  /// Called by Cloud Function that receives Stripe webhooks
  Future<void> processWebhookEvent({
    required String eventId,
    required String eventType,
    required Map<String, dynamic> eventData,
  }) async {
    // Audit trail — every webhook event gets logged
    await _firestore.collection('webhook_events').doc(eventId).set({
      'eventType': eventType,
      'data': eventData,
      'processedAt': FieldValue.serverTimestamp(),
      'status': 'processing',
    });

    try {
      switch (eventType) {
        case 'charge.succeeded':
          await _handleChargeSucceeded(eventData);
          break;
        case 'charge.failed':
          await _handleChargeFailed(eventData);
          break;
        case 'charge.refunded':
          await _handleChargeRefunded(eventData);
          break;
        case 'customer.subscription.created':
          await _handleSubscriptionCreated(eventData);
          break;
        case 'customer.subscription.updated':
          await _handleSubscriptionUpdated(eventData);
          break;
        case 'customer.subscription.deleted':
          await _handleSubscriptionCancelled(eventData);
          break;
        case 'invoice.payment_failed':
          await _handleInvoicePaymentFailed(eventData);
          break;
        case 'charge.dispute.created':
          await _handleDisputeCreated(eventData);
          break;
      }

      // Mark webhook as processed
      await _firestore.collection('webhook_events').doc(eventId).update({
        'status': 'processed',
      });
    } catch (e) {
      await _firestore.collection('webhook_events').doc(eventId).update({
        'status': 'failed',
        'error': e.toString(),
      });
    }
  }

  Future<void> _handleChargeSucceeded(Map<String, dynamic> data) async {
    final paymentIntentId = data['payment_intent'] as String?;
    if (paymentIntentId == null) return;

    // Idempotency check — prevent double-processing from webhook retries
    final existingTxn = await _firestore
        .collection('transactions')
        .where('paymentIntentId', isEqualTo: paymentIntentId)
        .where('status', isEqualTo: 'completed')
        .limit(1)
        .get();

    if (existingTxn.docs.isNotEmpty) {
      debugPrint(
        'Webhook idempotency: transaction already recorded for $paymentIntentId',
      );
      return;
    }

    // Look up the payment intent to find the product
    final piDoc = await _firestore
        .collection('payment_intents')
        .doc(paymentIntentId)
        .get();
    if (!piDoc.exists) return;

    final piData = piDoc.data()!;
    final userId = piData['userId'] as String;
    final productType = piData['productType'] as String;
    final productId = piData['productId'] as String;
    final amountCents = (piData['amountCents'] as num).toInt();
    final currency = piData['currency'] as String;
    final feePct =
        double.tryParse(
          (piData['metadata'] as Map?)?['platform_fee_pct']?.toString() ?? '0',
        ) ??
        0.0;

    final txnId = await recordTransaction(
      paymentIntentId: paymentIntentId,
      userId: userId,
      productType: productType,
      productId: productId,
      amountCents: amountCents,
      currency: currency,
      platformFeePct: feePct,
      promoterId: (piData['metadata'] as Map?)?['promoter_id'],
      sellerId: (piData['metadata'] as Map?)?['seller_id'],
    );

    // Only grant access if transaction was successfully recorded
    if (txnId == null) {
      debugPrint(
        'CRITICAL: Transaction recording failed for $paymentIntentId — access NOT granted',
      );
      return;
    }

    // Product-specific post-payment actions
    if (productType == 'ppv') {
      await _grantPPVAccess(userId, productId);
    } else if (productType == 'ticket') {
      await _issueTicket(userId, productId, piData['metadata'] as Map?);
    }
  }

  Future<void> _handleChargeFailed(Map<String, dynamic> data) async {
    final paymentIntentId = data['payment_intent'] as String?;
    if (paymentIntentId == null) return;

    await _firestore.collection('payment_intents').doc(paymentIntentId).update({
      'status': 'failed',
      'failureMessage': data['failure_message'],
      'failedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleChargeRefunded(Map<String, dynamic> data) async {
    final paymentIntentId = data['payment_intent'] as String?;
    final amountRefunded = (data['amount_refunded'] as num?)?.toInt() ?? 0;
    if (paymentIntentId == null) return;

    await _firestore.collection('refunds').add({
      'paymentIntentId': paymentIntentId,
      'amountRefundedCents': amountRefunded,
      'reason': data['reason'] ?? 'customer_request',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('payment_intents').doc(paymentIntentId).update({
      'status': 'refunded',
      'refundedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleSubscriptionCreated(Map<String, dynamic> data) async {
    final stripeSubId = data['id'] as String?;
    final customerId = data['customer'] as String?;
    if (stripeSubId == null || customerId == null) return;

    // Find DFC user by Stripe customer ID
    final userQuery = await _firestore
        .collection('stripe_customers')
        .where('stripeCustomerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;
    final userId = userQuery.docs.first.id;

    final priceId =
        (data['items']?['data'] as List?)?.firstOrNull?['price']?['id'];

    await _firestore.collection('subscriptions').doc(userId).set({
      'stripeSubscriptionId': stripeSubId,
      'stripeCustomerId': customerId,
      'stripePriceId': priceId,
      'status': 'active',
      'currentPeriodStart': data['current_period_start'],
      'currentPeriodEnd': data['current_period_end'],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _handleSubscriptionUpdated(Map<String, dynamic> data) async {
    final customerId = data['customer'] as String?;
    if (customerId == null) return;

    final userQuery = await _firestore
        .collection('stripe_customers')
        .where('stripeCustomerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;
    final userId = userQuery.docs.first.id;

    await _firestore.collection('subscriptions').doc(userId).update({
      'status': data['status'],
      'cancelAtPeriodEnd': data['cancel_at_period_end'] ?? false,
      'currentPeriodEnd': data['current_period_end'],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleSubscriptionCancelled(Map<String, dynamic> data) async {
    final customerId = data['customer'] as String?;
    if (customerId == null) return;

    final userQuery = await _firestore
        .collection('stripe_customers')
        .where('stripeCustomerId', isEqualTo: customerId)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) return;
    final userId = userQuery.docs.first.id;

    await _firestore.collection('subscriptions').doc(userId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleInvoicePaymentFailed(Map<String, dynamic> data) async {
    final customerId = data['customer'] as String?;
    if (customerId == null) return;

    // Dunning — record failed payment attempt for retry logic
    await _firestore.collection('dunning_events').add({
      'stripeCustomerId': customerId,
      'invoiceId': data['id'],
      'amountDueCents': data['amount_due'],
      'attemptCount': data['attempt_count'] ?? 1,
      'nextPaymentAttempt': data['next_payment_attempt'],
      'status': 'failed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _handleDisputeCreated(Map<String, dynamic> data) async {
    await _firestore.collection('disputes').add({
      'chargeId': data['charge'],
      'amountCents': data['amount'],
      'reason': data['reason'],
      'status': data['status'] ?? 'needs_response',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // POST-PAYMENT ACTIONS
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _grantPPVAccess(String userId, String ppvEventId) async {
    final resolvedPpvDocId = await _resolvePpvDocumentId(ppvEventId);
    if (resolvedPpvDocId == null || resolvedPpvDocId.isEmpty) {
      throw Exception('PPV event document could not be resolved');
    }

    await _firestore.collection('ppv_purchases').add({
      'userId': userId,
      'ppvEventId': resolvedPpvDocId,
      'status': 'completed',
      'accessGranted': true,
      'purchasedAt': FieldValue.serverTimestamp(),
    });

    // Increment purchase count
    await _firestore.collection('ppv_events').doc(resolvedPpvDocId).update({
      'purchaseCount': FieldValue.increment(1),
    });
  }

  Future<void> _issueTicket(
    String userId,
    String eventId,
    Map? metadata,
  ) async {
    await _firestore.collection('tickets').add({
      'userId': userId,
      'eventId': eventId,
      'tier': metadata?['ticket_tier'] ?? 'general',
      'quantity': int.tryParse(metadata?['quantity']?.toString() ?? '1') ?? 1,
      'status': 'valid',
      'issuedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REFUNDS
  // ═══════════════════════════════════════════════════════════════════════

  /// Request a refund for a transaction
  Future<bool> requestRefund({
    required String transactionId,
    required String reason,
    int? amountCents,
  }) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      final txnDoc = await _firestore
          .collection('transactions')
          .doc(transactionId)
          .get();
      if (!txnDoc.exists) {
        _error = 'Transaction not found';
        return false;
      }

      final txnData = txnDoc.data()!;
      final paymentIntentId = txnData['paymentIntentId'] as String;

      final callable = _functions.httpsCallable('createRefund');
      await callable.call({
        'paymentIntentId': paymentIntentId,
        'amountCents': amountCents,
        'reason': reason,
      });

      await _firestore.collection('transactions').doc(transactionId).update({
        'status': amountCents != null ? 'partially_refunded' : 'refunded',
        'refundedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _error = 'Refund failed: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CUSTOMER MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Get or create Stripe customer for a DFC user
  Future<String?> getOrCreateCustomer({
    required String userId,
    required String email,
    String? name,
  }) async {
    try {
      // Check if customer already exists
      final doc = await _firestore
          .collection('stripe_customers')
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data()?['stripeCustomerId'] as String?;
      }

      // Create via Cloud Function
      final callable = _functions.httpsCallable('createStripeCustomer');
      final result = await callable.call({
        'userId': userId,
        'email': email,
        'name': name,
      });

      final customerId = result.data['customerId'] as String?;
      if (customerId != null) {
        await _firestore.collection('stripe_customers').doc(userId).set({
          'stripeCustomerId': customerId,
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return customerId;
    } catch (e) {
      debugPrint('StripePaymentEngine.getOrCreateCustomer error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REVENUE ANALYTICS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get total platform revenue for a date range
  Future<RevenueSnapshot> getRevenueSnapshot({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      var query = _firestore
          .collection('transactions')
          .where('status', isEqualTo: 'completed');

      if (from != null) {
        query = query.where('completedAt', isGreaterThanOrEqualTo: from);
      }
      if (to != null) {
        query = query.where('completedAt', isLessThanOrEqualTo: to);
      }

      final snapshot = await query.limit(5000).get();

      int totalRevenueCents = 0;
      int platformFeeCents = 0;
      int ppvRevenueCents = 0;
      int subscriptionRevenueCents = 0;
      int marketplaceRevenueCents = 0;
      int ticketRevenueCents = 0;
      int donationRevenueCents = 0;
      int transactionCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amountCents'] as num?)?.toInt() ?? 0;
        final fee = (data['platformFeeCents'] as num?)?.toInt() ?? 0;
        final type = data['productType'] as String? ?? '';

        totalRevenueCents += amount;
        platformFeeCents += fee;
        transactionCount++;

        switch (type) {
          case 'ppv':
            ppvRevenueCents += amount;
            break;
          case 'subscription':
            subscriptionRevenueCents += amount;
            break;
          case 'marketplace':
            marketplaceRevenueCents += amount;
            break;
          case 'ticket':
            ticketRevenueCents += amount;
            break;
          case 'donation':
            donationRevenueCents += amount;
            break;
        }
      }

      return RevenueSnapshot(
        totalRevenueCents: totalRevenueCents,
        platformFeeCents: platformFeeCents,
        ppvRevenueCents: ppvRevenueCents,
        subscriptionRevenueCents: subscriptionRevenueCents,
        marketplaceRevenueCents: marketplaceRevenueCents,
        ticketRevenueCents: ticketRevenueCents,
        donationRevenueCents: donationRevenueCents,
        transactionCount: transactionCount,
        from: from,
        to: to,
      );
    } catch (e) {
      debugPrint('StripePaymentEngine.getRevenueSnapshot error: $e');
      return RevenueSnapshot.empty();
    }
  }

  /// Get promoter-specific revenue
  Future<PromoterRevenue> getPromoterRevenue(String promoterId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('recipientId', isEqualTo: promoterId)
          .where('status', isEqualTo: 'completed')
          .limit(5000)
          .get();

      int totalEarnedCents = 0;
      int totalPaidOutCents = 0;
      int pendingPayoutCents = 0;
      int ppvSales = 0;
      int ticketSales = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final payout = (data['payoutCents'] as num?)?.toInt() ?? 0;
        final type = data['productType'] as String? ?? '';
        final payoutStatus = data['payoutStatus'] as String? ?? 'pending';

        totalEarnedCents += payout;
        if (payoutStatus == 'completed') {
          totalPaidOutCents += payout;
        } else {
          pendingPayoutCents += payout;
        }

        if (type == 'ppv') ppvSales++;
        if (type == 'ticket') ticketSales++;
      }

      return PromoterRevenue(
        promoterId: promoterId,
        totalEarnedCents: totalEarnedCents,
        totalPaidOutCents: totalPaidOutCents,
        pendingPayoutCents: pendingPayoutCents,
        ppvSales: ppvSales,
        ticketSales: ticketSales,
      );
    } catch (e) {
      debugPrint('StripePaymentEngine.getPromoterRevenue error: $e');
      return PromoterRevenue.empty(promoterId);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class CurrencyConfig {
  final String code;
  final String symbol;
  final String name;
  final int stripeMin; // Minimum charge in smallest unit (cents/pence/etc.)
  final int decimalPlaces;

  const CurrencyConfig({
    required this.code,
    required this.symbol,
    required this.name,
    required this.stripeMin,
    required this.decimalPlaces,
  });

  String format(int amountSmallestUnit) {
    if (decimalPlaces == 0) return '$symbol$amountSmallestUnit';
    final divisor = _pow10(decimalPlaces);
    return '$symbol${(amountSmallestUnit / divisor).toStringAsFixed(decimalPlaces)}';
  }

  static int _pow10(int n) {
    int result = 1;
    for (int i = 0; i < n; i++) {
      result *= 10;
    }
    return result;
  }
}

class PaymentIntentResult {
  final String paymentIntentId;
  final String clientSecret;
  final String status;
  final int amountCents;
  final String currency;

  const PaymentIntentResult({
    required this.paymentIntentId,
    required this.clientSecret,
    required this.status,
    required this.amountCents,
    required this.currency,
  });
}

class RevenueSnapshot {
  final int totalRevenueCents;
  final int platformFeeCents;
  final int ppvRevenueCents;
  final int subscriptionRevenueCents;
  final int marketplaceRevenueCents;
  final int ticketRevenueCents;
  final int donationRevenueCents;
  final int transactionCount;
  final DateTime? from;
  final DateTime? to;

  const RevenueSnapshot({
    required this.totalRevenueCents,
    required this.platformFeeCents,
    required this.ppvRevenueCents,
    required this.subscriptionRevenueCents,
    required this.marketplaceRevenueCents,
    required this.ticketRevenueCents,
    required this.donationRevenueCents,
    required this.transactionCount,
    this.from,
    this.to,
  });

  factory RevenueSnapshot.empty() => const RevenueSnapshot(
    totalRevenueCents: 0,
    platformFeeCents: 0,
    ppvRevenueCents: 0,
    subscriptionRevenueCents: 0,
    marketplaceRevenueCents: 0,
    ticketRevenueCents: 0,
    donationRevenueCents: 0,
    transactionCount: 0,
  );

  double get totalRevenue => totalRevenueCents / 100.0;
  double get platformFees => platformFeeCents / 100.0;
}

class PromoterRevenue {
  final String promoterId;
  final int totalEarnedCents;
  final int totalPaidOutCents;
  final int pendingPayoutCents;
  final int ppvSales;
  final int ticketSales;

  const PromoterRevenue({
    required this.promoterId,
    required this.totalEarnedCents,
    required this.totalPaidOutCents,
    required this.pendingPayoutCents,
    required this.ppvSales,
    required this.ticketSales,
  });

  factory PromoterRevenue.empty(String id) => PromoterRevenue(
    promoterId: id,
    totalEarnedCents: 0,
    totalPaidOutCents: 0,
    pendingPayoutCents: 0,
    ppvSales: 0,
    ticketSales: 0,
  );

  double get totalEarned => totalEarnedCents / 100.0;
  double get totalPaidOut => totalPaidOutCents / 100.0;
  double get pendingPayout => pendingPayoutCents / 100.0;
}
