import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/fight_credits_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT CREDITS SERVICE — Micropayment Wallet Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Users buy Credit Packs (single Stripe transaction) then spend credits
/// on individual fights, rounds, replays, and tips. This avoids per-txn
/// card fees (30¢ + 2.9%) killing margins on $1–$2 micro-purchases.
///
/// Firestore Collections:
///   credit_wallets/{userId}                 — Wallet balance + stats
///   credit_wallets/{userId}/transactions    — Ledger of every credit/debit
///
/// Flow:
///   1. User taps "Buy Credits" → pick a pack → Stripe Checkout
///   2. Stripe webhook calls creditWalletTopup Cloud Function
///   3. Cloud Function atomically credits wallet + writes txn record
///   4. User spends credits → atomic debit via Firestore transaction
///
/// ═══════════════════════════════════════════════════════════════════════════
class FightCreditsService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );

  // ── State ──
  CreditWallet? _wallet;
  List<CreditTransaction> _recentTransactions = [];
  bool _isLoading = false;
  String? _error;

  CreditWallet? get wallet => _wallet;
  List<CreditTransaction> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get balance => _wallet?.balance ?? 0;

  // ── Collection Refs ──
  DocumentReference _walletDoc(String userId) =>
      _firestore.collection('credit_wallets').doc(userId);

  CollectionReference _txnCollection(String userId) =>
      _firestore.collection('credit_wallets').doc(userId).collection('transactions');

  // ═══════════════════════════════════════════════════════════════════════
  // WALLET — Read & Stream
  // ═══════════════════════════════════════════════════════════════════════

  /// Load wallet once.
  Future<CreditWallet> getWallet(String userId) async {
    try {
      final doc = await _walletDoc(userId).get();
      if (doc.exists) {
        _wallet = CreditWallet.fromFirestore(doc);
      } else {
        _wallet = CreditWallet.empty(userId);
      }
      notifyListeners();
      return _wallet!;
    } catch (e) {
      debugPrint('FightCreditsService.getWallet error: $e');
      _wallet = CreditWallet.empty(userId);
      notifyListeners();
      return _wallet!;
    }
  }

  /// Real-time wallet stream.
  Stream<CreditWallet> streamWallet(String userId) {
    return _walletDoc(userId).snapshots().map((doc) {
      if (doc.exists) {
        _wallet = CreditWallet.fromFirestore(doc);
      } else {
        _wallet = CreditWallet.empty(userId);
      }
      notifyListeners();
      return _wallet!;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PURCHASE CREDITS — Stripe Checkout
  // ═══════════════════════════════════════════════════════════════════════

  /// Initiate credit pack purchase via Stripe hosted checkout.
  /// Cloud Function creates the session; webhook credits the wallet.
  Future<bool> purchaseCreditPack({
    required String userId,
    required CreditPack pack,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final callable = _functions.httpsCallable('createCreditPackCheckout');
      final result = await callable({
        'userId': userId,
        'packId': pack.id,
        'packName': pack.name,
        'credits': pack.credits,
        'amountCents': pack.priceCentsAUD,
        'currency': 'AUD',
        'stripePriceId': pack.stripePriceId,
      });

      final data = result.data;
      if (data == null || data['error'] != null) {
        throw Exception(data?['error'] ?? 'Checkout session creation failed');
      }

      final checkoutUrl = data['url'] as String?;
      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception('No checkout URL returned');
      }

      // Open Stripe hosted checkout
      final uri = Uri.parse(checkoutUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open checkout URL');
      }

      debugPrint(
        'Credits checkout opened: ${pack.name} (${pack.credits} cr) — '
        'A\$${pack.priceAUD}',
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Purchase failed: $e';
      debugPrint('FightCreditsService.purchaseCreditPack error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SPEND CREDITS — Atomic Firestore Transaction
  // ═══════════════════════════════════════════════════════════════════════

  /// Spend credits on content (fight, round, replay, etc.).
  /// Uses Firestore transaction for atomicity.
  Future<bool> spendCredits({
    required String userId,
    required CreditSpendType spendType,
    int? customAmount,
    String? eventId,
    String? fightId,
    String? description,
  }) async {
    final cost = customAmount ?? CreditCosts.costFor(spendType);
    final desc = description ?? CreditCosts.labelFor(spendType);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _firestore.runTransaction((txn) async {
        final walletSnap = await txn.get(_walletDoc(userId));

        int currentBalance = 0;
        int totalSpent = 0;
        int totalPurchased = 0;

        if (walletSnap.exists) {
          final data = walletSnap.data() as Map<String, dynamic>;
          currentBalance = data['balance'] ?? 0;
          totalSpent = data['totalSpent'] ?? 0;
          totalPurchased = data['totalPurchased'] ?? 0;
        }

        if (currentBalance < cost) {
          throw Exception('Insufficient credits: have $currentBalance, need $cost');
        }

        // Debit wallet
        txn.set(
          _walletDoc(userId),
          {
            'userId': userId,
            'balance': currentBalance - cost,
            'totalSpent': totalSpent + cost,
            'totalPurchased': totalPurchased,
            'lastSpendAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Write transaction record
        final txnRef = _txnCollection(userId).doc();
        txn.set(txnRef, {
          'userId': userId,
          'amount': -cost,
          'description': desc,
          'spendType': spendType.name,
          'relatedEventId': eventId,
          'relatedFightId': fightId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // Refresh local state
      await getWallet(userId);

      debugPrint('Credits spent: $cost for $desc (event:$eventId fight:$fightId)');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('FightCreditsService.spendCredits error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if user can afford a specific spend type.
  bool canAfford(CreditSpendType type) =>
      (_wallet?.balance ?? 0) >= CreditCosts.costFor(type);

  // ═══════════════════════════════════════════════════════════════════════
  // TRANSACTION HISTORY
  // ═══════════════════════════════════════════════════════════════════════

  /// Load recent transactions (paginated).
  Future<List<CreditTransaction>> getTransactions(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final snap = await _txnCollection(userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      _recentTransactions =
          snap.docs.map(CreditTransaction.fromFirestore).toList();
      notifyListeners();
      return _recentTransactions;
    } catch (e) {
      debugPrint('FightCreditsService.getTransactions error: $e');
      return [];
    }
  }

  /// Stream transactions in real-time.
  Stream<List<CreditTransaction>> streamTransactions(
    String userId, {
    int limit = 20,
  }) {
    return _txnCollection(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      _recentTransactions =
          snap.docs.map(CreditTransaction.fromFirestore).toList();
      notifyListeners();
      return _recentTransactions;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GRANT CREDITS (called by webhook / admin)
  // ═══════════════════════════════════════════════════════════════════════

  /// Manually grant credits (for admin, promo codes, referrals, etc.).
  /// In production this should be called from a Cloud Function, not client.
  Future<bool> grantCredits({
    required String userId,
    required int amount,
    required String description,
    String? stripePaymentIntentId,
  }) async {
    try {
      await _firestore.runTransaction((txn) async {
        final walletSnap = await txn.get(_walletDoc(userId));

        int currentBalance = 0;
        int totalPurchased = 0;
        int totalSpent = 0;

        if (walletSnap.exists) {
          final data = walletSnap.data() as Map<String, dynamic>;
          currentBalance = data['balance'] ?? 0;
          totalPurchased = data['totalPurchased'] ?? 0;
          totalSpent = data['totalSpent'] ?? 0;
        }

        txn.set(
          _walletDoc(userId),
          {
            'userId': userId,
            'balance': currentBalance + amount,
            'totalPurchased': totalPurchased + amount,
            'totalSpent': totalSpent,
            'lastPurchaseAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        final txnRef = _txnCollection(userId).doc();
        txn.set(txnRef, {
          'userId': userId,
          'amount': amount,
          'description': description,
          'stripePaymentIntentId': stripePaymentIntentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      await getWallet(userId);
      debugPrint('Credits granted: $amount to $userId — $description');
      return true;
    } catch (e) {
      debugPrint('FightCreditsService.grantCredits error: $e');
      return false;
    }
  }
}
