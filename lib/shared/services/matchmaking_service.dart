import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bout_slot_model.dart';
import '../models/bout_offer_model.dart';
import '../models/fighter_model.dart';

/// Service for the DFC Matchmaking Engine.
/// Manages open bout slots on fight cards and fighter applications.
class MatchmakingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _slotsCollection = 'bout_slots';
  static const String _offersCollection = 'bout_offers';

  // ── Slots ──────────────────────────────────────────────────────────────────

  /// Stream all open bout slots sorted by event date (client-side).
  Stream<List<BoutSlotModel>> streamOpenSlots() {
    return _firestore
        .collection(_slotsCollection)
        .where('status', isEqualTo: BoutSlotStatus.open.name)
        .snapshots()
        .map((snap) {
          final slots = snap.docs.map(BoutSlotModel.fromFirestore).toList();
          slots.sort((a, b) => a.eventDate.compareTo(b.eventDate));
          return slots;
        });
  }

  /// Create a new open slot on a promoter's fight card.
  Future<String> createSlot(BoutSlotModel slot) async {
    final data = slot.toFirestore();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await _firestore.collection(_slotsCollection).add(data);
    return ref.id;
  }

  /// Change the status of a slot (e.g. open → filled after acceptance).
  Future<void> updateSlotStatus(String slotId, BoutSlotStatus status) async {
    await _firestore.collection(_slotsCollection).doc(slotId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Fighters ───────────────────────────────────────────────────────────────

  /// Stream fighters who are actively available for matchups.
  Stream<List<FighterModel>> streamAvailableFighters() {
    return _firestore
        .collection('fighters')
        .where(
          'matchupAvailability',
          isEqualTo: MatchupAvailability.available.name,
        )
        .snapshots()
        .map((snap) {
          final fighters = snap.docs
              .map(FighterModel.fromFirestore)
              .where((f) => f.status == FighterStatus.active)
              .toList();
          fighters.sort((a, b) => b.wins.compareTo(a.wins));
          return fighters;
        });
  }

  // ── Offers ─────────────────────────────────────────────────────────────────

  /// Submit a fighter application for an open slot.
  /// Atomically increments the slot's [applicationCount].
  Future<void> submitOffer(BoutOfferModel offer) async {
    final batch = _firestore.batch();

    final offerRef = _firestore.collection(_offersCollection).doc();
    final offerData = offer.toFirestore();
    offerData['createdAt'] = FieldValue.serverTimestamp();
    offerData['updatedAt'] = FieldValue.serverTimestamp();
    batch.set(offerRef, offerData);

    final slotRef = _firestore.collection(_slotsCollection).doc(offer.slotId);
    batch.update(slotRef, {
      'applicationCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Accept or reject a fighter's offer.
  Future<void> updateOfferStatus(String offerId, BoutOfferStatus status) async {
    await _firestore.collection(_offersCollection).doc(offerId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream all applications for a specific slot (promoter view).
  Stream<List<BoutOfferModel>> streamOffersForSlot(String slotId) {
    return _firestore
        .collection(_offersCollection)
        .where('slotId', isEqualTo: slotId)
        .snapshots()
        .map((snap) {
          final offers = snap.docs.map(BoutOfferModel.fromFirestore).toList();
          offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return offers;
        });
  }

  /// Stream all offers submitted by a specific fighter.
  Stream<List<BoutOfferModel>> streamOffersForFighter(String fighterId) {
    return _firestore
        .collection(_offersCollection)
        .where('fighterId', isEqualTo: fighterId)
        .snapshots()
        .map((snap) {
          final offers = snap.docs.map(BoutOfferModel.fromFirestore).toList();
          offers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return offers;
        });
  }
}
