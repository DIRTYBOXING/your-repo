import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fighter_model.dart';
import '../../core/utils/app_logger.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DATABANK SERVICE — Fighter Pool & Search Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// When a fighter loads their data, it's stacked in the DataBank pool.
/// Promoters / matchmakers can search for available fighters for upcoming
/// events, last-minute replacements, or AI-driven matchmaking.
/// ═══════════════════════════════════════════════════════════════════════════
class DatabankService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _databankCollection = 'fighter_databank';

  // ─────────────────────────────────────────────────────────────────────────
  // REGISTER / UPDATE IN DATABANK
  // ─────────────────────────────────────────────────────────────────────────

  /// Register or update a fighter's DataBank entry.
  /// Called whenever a fighter saves/updates their profile.
  Future<bool> registerInDatabank(FighterModel fighter) async {
    try {
      final entry = {
        'fighterId': fighter.id,
        'userId': fighter.userId,
        'fullName': fighter.fullName,
        'nickname': fighter.nickname,
        'nationality': fighter.nationality,
        'weightClass': fighter.weightClass,
        'sportType': fighter.sportType,
        'stance': fighter.stance?.name,
        'status': fighter.status.name,
        'record': fighter.record,
        'wins': fighter.wins,
        'losses': fighter.losses,
        'draws': fighter.draws,
        'knockouts': fighter.knockouts,
        'submissions': fighter.submissions,
        'totalFights': fighter.totalFights,
        'winPercentage': fighter.winPercentage,
        'finishRate': fighter.finishRate,
        'heightCm': fighter.heightCm,
        'reachCm': fighter.reachCm,
        'photoUrl': fighter.photoUrl,
        // Location
        'city': fighter.city,
        'state': fighter.state,
        'country': fighter.country,
        'latitude': fighter.latitude,
        'longitude': fighter.longitude,
        'maxTravelDistanceKm': fighter.maxTravelDistanceKm,
        'willingToTravel': fighter.willingToTravel,
        // Availability
        'matchupAvailability': fighter.matchupAvailability.name,
        'availableFrom': fighter.availableFrom != null
            ? Timestamp.fromDate(fighter.availableFrom!)
            : null,
        'availableUntil': fighter.availableUntil != null
            ? Timestamp.fromDate(fighter.availableUntil!)
            : null,
        'matchupNotes': fighter.matchupNotes,
        'minimumPurse': fighter.minimumPurse,
        'preferredWeightClasses': fighter.preferredWeightClasses,
        'preferredOpponentStyles': fighter.preferredOpponentStyles,
        // Gym
        'currentGymId': fighter.currentGymId,
        // Metadata
        'registeredAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'isInPool': fighter.isAvailableForMatchup,
        // Search keywords (lowercase for text search)
        'searchKeywords': _generateSearchKeywords(fighter),
      };

      await _firestore
          .collection(_databankCollection)
          .doc(fighter.id)
          .set(entry, SetOptions(merge: true));

      AppLogger.info(
        'Fighter registered in DataBank: ${fighter.fullName} (${fighter.id})',
        tag: 'DatabankService',
      );
      return true;
    } catch (e) {
      AppLogger.error(
        'Error registering fighter in DataBank',
        error: e,
        tag: 'DatabankService',
      );
      return false;
    }
  }

  /// Generate search keywords from fighter data for text search
  List<String> _generateSearchKeywords(FighterModel fighter) {
    final keywords = <String>{};
    // Full name parts
    for (final part in fighter.fullName.toLowerCase().split(' ')) {
      keywords.add(part);
      // Add prefixes for partial matching
      for (int i = 1; i <= part.length; i++) {
        keywords.add(part.substring(0, i));
      }
    }
    // Nickname
    if (fighter.nickname != null) {
      keywords.add(fighter.nickname!.toLowerCase());
    }
    // Weight class
    if (fighter.weightClass != null) {
      keywords.add(fighter.weightClass!.toLowerCase());
    }
    // Sport type
    if (fighter.sportType != null) {
      keywords.add(fighter.sportType!.toLowerCase());
    }
    // Location
    if (fighter.city != null) keywords.add(fighter.city!.toLowerCase());
    if (fighter.country != null) keywords.add(fighter.country!.toLowerCase());
    // Nationality
    if (fighter.nationality != null) {
      keywords.add(fighter.nationality!.toLowerCase());
    }

    return keywords.toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POOL QUERIES — Available fighters stacked for events
  // ─────────────────────────────────────────────────────────────────────────

  /// Get all fighters currently in the available pool
  Future<List<Map<String, dynamic>>> getAvailablePool({
    String? weightClass,
    String? sportType,
    String? country,
    bool onlyWillingToTravel = false,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection(_databankCollection)
          .where('isInPool', isEqualTo: true)
          .where('status', isEqualTo: FighterStatus.active.name);

      if (weightClass != null) {
        query = query.where('weightClass', isEqualTo: weightClass);
      }
      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType);
      }
      if (country != null) {
        query = query.where('country', isEqualTo: country);
      }
      if (onlyWillingToTravel) {
        query = query.where('willingToTravel', isEqualTo: true);
      }

      final snapshot = await query.limit(limit).get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching available pool',
        error: e,
        tag: 'DatabankService',
      );
      return [];
    }
  }

  /// Search the DataBank by keyword (name, nickname, location, etc.)
  Future<List<Map<String, dynamic>>> searchDatabank(
    String query, {
    int limit = 30,
  }) async {
    try {
      final keyword = query.toLowerCase().trim();
      if (keyword.isEmpty) return [];

      final snapshot = await _firestore
          .collection(_databankCollection)
          .where('searchKeywords', arrayContains: keyword)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error(
        'Error searching DataBank',
        error: e,
        tag: 'DatabankService',
      );
      return [];
    }
  }

  /// Get fighters available for a specific upcoming event date range
  Future<List<Map<String, dynamic>>> getFightersForEvent({
    required DateTime eventDate,
    String? weightClass,
    String? sportType,
    int limit = 30,
  }) async {
    try {
      Query query = _firestore
          .collection(_databankCollection)
          .where('isInPool', isEqualTo: true)
          .where('status', isEqualTo: FighterStatus.active.name);

      if (weightClass != null) {
        query = query.where('weightClass', isEqualTo: weightClass);
      }
      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType);
      }

      final snapshot = await query.limit(limit).get();

      // Client-side filter for date range
      return snapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['docId'] = doc.id;
            return data;
          })
          .where((data) {
            // Check availability dates
            final availFrom = (data['availableFrom'] as Timestamp?)?.toDate();
            final availUntil = (data['availableUntil'] as Timestamp?)?.toDate();
            if (availFrom != null && eventDate.isBefore(availFrom)) {
              return false;
            }
            if (availUntil != null && eventDate.isAfter(availUntil)) {
              return false;
            }
            return true;
          })
          .toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching fighters for event',
        error: e,
        tag: 'DatabankService',
      );
      return [];
    }
  }

  /// Get last-minute replacement fighters (available NOW, willing to travel)
  Future<List<Map<String, dynamic>>> getLastMinuteReplacements({
    String? weightClass,
    String? sportType,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_databankCollection)
          .where('isInPool', isEqualTo: true)
          .where('status', isEqualTo: FighterStatus.active.name)
          .where('willingToTravel', isEqualTo: true);

      if (weightClass != null) {
        query = query.where('weightClass', isEqualTo: weightClass);
      }
      if (sportType != null) {
        query = query.where('sportType', isEqualTo: sportType);
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.error(
        'Error fetching last-minute replacements',
        error: e,
        tag: 'DatabankService',
      );
      return [];
    }
  }

  /// Get DataBank stats (total pool size, by weight class, etc.)
  Future<Map<String, dynamic>> getDatabankStats() async {
    try {
      final poolSnapshot = await _firestore
          .collection(_databankCollection)
          .where('isInPool', isEqualTo: true)
          .get();

      final totalSnapshot = await _firestore
          .collection(_databankCollection)
          .get();

      // Count by weight class
      final weightClassCounts = <String, int>{};
      final sportTypeCounts = <String, int>{};
      int urgentCount = 0;

      for (final doc in poolSnapshot.docs) {
        final data = doc.data();
        final wc = data['weightClass'] as String?;
        final st = data['sportType'] as String?;
        final travel = data['willingToTravel'] as bool? ?? false;
        if (wc != null) {
          weightClassCounts[wc] = (weightClassCounts[wc] ?? 0) + 1;
        }
        if (st != null) {
          sportTypeCounts[st] = (sportTypeCounts[st] ?? 0) + 1;
        }
        if (travel) urgentCount++;
      }

      return {
        'totalRegistered': totalSnapshot.docs.length,
        'totalInPool': poolSnapshot.docs.length,
        'urgentAvailable': urgentCount,
        'weightClassCounts': weightClassCounts,
        'sportTypeCounts': sportTypeCounts,
      };
    } catch (e) {
      AppLogger.error(
        'Error fetching DataBank stats',
        error: e,
        tag: 'DatabankService',
      );
      return {'totalRegistered': 0, 'totalInPool': 0, 'urgentAvailable': 0};
    }
  }

  /// Remove fighter from the DataBank pool
  Future<bool> removeFromPool(String fighterId) async {
    try {
      await _firestore.collection(_databankCollection).doc(fighterId).update({
        'isInPool': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      AppLogger.error(
        'Error removing from pool',
        error: e,
        tag: 'DatabankService',
      );
      return false;
    }
  }

  /// Stream the DataBank pool for real-time updates
  Stream<List<Map<String, dynamic>>> streamAvailablePool({
    String? weightClass,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection(_databankCollection)
        .where('isInPool', isEqualTo: true)
        .where('status', isEqualTo: FighterStatus.active.name);

    if (weightClass != null) {
      query = query.where('weightClass', isEqualTo: weightClass);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        return data;
      }).toList();
    });
  }
}
