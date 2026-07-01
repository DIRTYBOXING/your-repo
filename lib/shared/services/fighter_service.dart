import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/fighter_model.dart';
import '../../core/utils/app_logger.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHTER SERVICE - Manages fighter profiles and matchup database
/// ═══════════════════════════════════════════════════════════════════════════
class FighterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'fighters';

  // ═══════════════════════════════════════════════════════════════════════════
  // FIGHTER PROFILE CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get fighter profile by ID
  Future<FighterModel?> getFighterProfile(String fighterId) async {
    try {
      // If 'current_user', use authenticated user's ID
      final id = fighterId == 'current_user'
          ? _auth.currentUser?.uid ?? fighterId
          : fighterId;

      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists || doc.data() == null) {
        AppLogger.debug('Fighter not found: $id', tag: 'FighterService');
        return null;
      }

      return FighterModel.fromFirestore(doc);
    } catch (e) {
      AppLogger.error(
        'Error fetching fighter profile',
        error: e,
        tag: 'FighterService',
      );
      return null;
    }
  }

  /// Get current user's fighter profile
  Future<FighterModel?> getCurrentFighterProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getFighterProfile(user.uid);
  }

  /// Create or update fighter profile
  Future<bool> saveFighterProfile(FighterModel fighter) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(fighter.id)
          .set(fighter.toFirestore(), SetOptions(merge: true));
      AppLogger.info(
        'Fighter profile saved: ${fighter.id}',
        tag: 'FighterService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error saving fighter profile',
        error: e,
        tag: 'FighterService',
      );
      return false;
    }
  }

  /// Update fighter's location
  Future<bool> updateLocation({
    required String fighterId,
    required String city,
    String? state,
    required String country,
    double? latitude,
    double? longitude,
    int? maxTravelDistanceKm,
  }) async {
    try {
      await _firestore.collection(_collection).doc(fighterId).update({
        'city': city,
        'state': state,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'maxTravelDistanceKm': maxTravelDistanceKm,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info(
        'Fighter location updated: $fighterId',
        tag: 'FighterService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error updating location',
        error: e,
        tag: 'FighterService',
      );
      return false;
    }
  }

  /// Update matchup availability
  Future<bool> updateMatchupAvailability({
    required String fighterId,
    required MatchupAvailability availability,
    DateTime? availableFrom,
    DateTime? availableUntil,
    String? matchupNotes,
    bool? willingToTravel,
    double? minimumPurse,
    List<String>? preferredWeightClasses,
    List<String>? preferredOpponentStyles,
  }) async {
    try {
      final updates = <String, dynamic>{
        'matchupAvailability': availability.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (availableFrom != null) {
        updates['availableFrom'] = Timestamp.fromDate(availableFrom);
      }
      if (availableUntil != null) {
        updates['availableUntil'] = Timestamp.fromDate(availableUntil);
      }
      if (matchupNotes != null) updates['matchupNotes'] = matchupNotes;
      if (willingToTravel != null) updates['willingToTravel'] = willingToTravel;
      if (minimumPurse != null) updates['minimumPurse'] = minimumPurse;
      if (preferredWeightClasses != null) {
        updates['preferredWeightClasses'] = preferredWeightClasses;
      }
      if (preferredOpponentStyles != null) {
        updates['preferredOpponentStyles'] = preferredOpponentStyles;
      }

      await _firestore.collection(_collection).doc(fighterId).update(updates);
      AppLogger.info(
        'Matchup availability updated: $fighterId',
        tag: 'FighterService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error updating matchup availability',
        error: e,
        tag: 'FighterService',
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MATCHUP DISCOVERY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Find available fighters for matchup
  Future<List<FighterModel>> findAvailableFighters({
    String? weightClass,
    String? country,
    String? sportType,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where(
            'matchupAvailability',
            isEqualTo: MatchupAvailability.available.name,
          )
          .where('status', isEqualTo: FighterStatus.active.name);

      if (weightClass != null) {
        query = query.where('weightClass', isEqualTo: weightClass);
      }
      if (country != null) {
        query = query.where('country', isEqualTo: country);
      }
      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map(FighterModel.fromFirestore)
          .where((f) => f.isAvailableForMatchup)
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error finding available fighters',
        error: e,
        tag: 'FighterService',
      );
      return [];
    }
  }

  /// Find fighters near a location
  Future<List<FighterModel>> findFightersNearLocation({
    required String country,
    String? state,
    String? city,
    String? weightClass,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('country', isEqualTo: country)
          .where(
            'matchupAvailability',
            isEqualTo: MatchupAvailability.available.name,
          );

      if (state != null) {
        query = query.where('state', isEqualTo: state);
      }
      if (weightClass != null) {
        query = query.where('weightClass', isEqualTo: weightClass);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map(FighterModel.fromFirestore)
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error finding fighters near location',
        error: e,
        tag: 'FighterService',
      );
      return [];
    }
  }

  /// Get potential matchups for a fighter
  Future<List<FighterModel>> getPotentialMatchups(String fighterId) async {
    try {
      final fighter = await getFighterProfile(fighterId);
      if (fighter == null) return [];

      // Find fighters in same weight class
      final query = _firestore
          .collection(_collection)
          .where('weightClass', isEqualTo: fighter.weightClass)
          .where(
            'matchupAvailability',
            isEqualTo: MatchupAvailability.available.name,
          )
          .where('status', isEqualTo: FighterStatus.active.name)
          .limit(20);

      final snapshot = await query.get();

      return snapshot.docs
          .map(FighterModel.fromFirestore)
          .where((f) => f.id != fighterId) // Exclude self
          .where(
            (f) => !fighter.blockedFighterIds.contains(f.id),
          ) // Exclude blocked
          .where((f) => f.isAvailableForMatchup)
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error getting potential matchups',
        error: e,
        tag: 'FighterService',
      );
      return [];
    }
  }

  /// Block a fighter from matchups
  Future<bool> blockFighter(String fighterId, String blockedFighterId) async {
    try {
      await _firestore.collection(_collection).doc(fighterId).update({
        'blockedFighterIds': FieldValue.arrayUnion([blockedFighterId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error(
        'Error blocking fighter',
        error: e,
        tag: 'FighterService',
      );
      return false;
    }
  }

  /// Unblock a fighter
  Future<bool> unblockFighter(String fighterId, String blockedFighterId) async {
    try {
      await _firestore.collection(_collection).doc(fighterId).update({
        'blockedFighterIds': FieldValue.arrayRemove([blockedFighterId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error(
        'Error unblocking fighter',
        error: e,
        tag: 'FighterService',
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream fighter profile
  Stream<FighterModel?> streamFighterProfile(String fighterId) {
    final id = fighterId == 'current_user'
        ? _auth.currentUser?.uid ?? fighterId
        : fighterId;

    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return FighterModel.fromFirestore(doc);
    });
  }

  /// Stream available fighters in weight class
  Stream<List<FighterModel>> streamAvailableFighters(String weightClass) {
    return _firestore
        .collection(_collection)
        .where('weightClass', isEqualTo: weightClass)
        .where(
          'matchupAvailability',
          isEqualTo: MatchupAvailability.available.name,
        )
        .where('status', isEqualTo: FighterStatus.active.name)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(FighterModel.fromFirestore)
              .where((f) => f.isAvailableForMatchup)
              .toList(),
        );
  }
}
