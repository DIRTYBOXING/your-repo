import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/trading_card_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC Trading Card Service — Firestore CRUD for profile/fighter cards
/// ═══════════════════════════════════════════════════════════════════════════
class TradingCardService extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  // ── Stream all cards for a user ─────────────────────────────────────────
  Stream<List<TradingCard>> userCardsStream(String userId) {
    return _db
        .collection('trading_cards')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map(TradingCard.fromFirestore).toList(),
        );
  }

  // ── Create card ─────────────────────────────────────────────────────────
  Future<void> createCard(TradingCard card) async {
    final ref = _db.collection('trading_cards').doc();
    await ref.set(card.toFirestore());
    notifyListeners();
  }

  // ── Update card ─────────────────────────────────────────────────────────
  Future<void> updateCard(TradingCard card) async {
    await _db
        .collection('trading_cards')
        .doc(card.id)
        .update(card.toFirestore());
    notifyListeners();
  }

  // ── Delete card ─────────────────────────────────────────────────────────
  Future<void> deleteCard(String cardId) async {
    await _db.collection('trading_cards').doc(cardId).delete();
    notifyListeners();
  }

  // ── Get single card ─────────────────────────────────────────────────────
  Future<TradingCard?> getCard(String cardId) async {
    final doc = await _db.collection('trading_cards').doc(cardId).get();
    if (!doc.exists) return null;
    return TradingCard.fromFirestore(doc);
  }
}
