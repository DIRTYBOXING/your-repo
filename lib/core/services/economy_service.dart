import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── EconomyService ────────────────────────────────────────────────────────────
// Central service for promoter / fighter / gym financial dashboards.

class EconomyService extends ChangeNotifier {
  static final EconomyService _i = EconomyService._();
  factory EconomyService() => _i;
  EconomyService._();

  final _fs = FirebaseFirestore.instance;

  // ── Promoter ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getPayoutBalance(String type, String id) async {
    try {
      final doc = await _fs.collection('payout_balances').doc(id).get();
      final data = doc.data() ?? {};
      return {
        'balanceCents': (((data['balance'] ?? 0) as num) * 100).round(),
        'balance': ((data['balance'] ?? 0) as num).toDouble(),
        'currency': data['currency'] ?? 'AUD',
        ...data,
      };
    } catch (_) {
      return {'balanceCents': 0, 'balance': 0.0, 'currency': 'AUD'};
    }
  }

  Future<List<Map<String, dynamic>>> getPayoutStatements(
    String type,
    String id,
  ) async {
    try {
      final snap = await _fs
          .collection('payout_statements')
          .where('ownerId', isEqualTo: id)
          .limit(50)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRevenueEventsForOwner(
    String type,
    String id,
  ) async {
    try {
      final snap = await _fs
          .collection('revenue_events')
          .where('ownerId', isEqualTo: id)
          .limit(50)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getPromoterEconomy(String promoterId) async {
    try {
      final doc = await _fs
          .collection('promoter_economy')
          .doc(promoterId)
          .get();
      return doc.exists ? doc.data()! : _defaultPromoterEconomy();
    } catch (e) {
      debugPrint('EconomyService.getPromoterEconomy: $e');
      return _defaultPromoterEconomy();
    }
  }

  Map<String, dynamic> _defaultPromoterEconomy() => {
    'totalRevenue': 0,
    'ticketRevenue': 0,
    'ppvRevenue': 0,
    'sponsorRevenue': 0,
    'pendingPayouts': 0,
    'events': [],
  };

  // ── Fighter ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getFighterEconomy(String fighterId) async {
    try {
      final doc = await _fs.collection('fighter_economy').doc(fighterId).get();
      return doc.exists ? doc.data()! : _defaultFighterEconomy();
    } catch (e) {
      debugPrint('EconomyService.getFighterEconomy: $e');
      return _defaultFighterEconomy();
    }
  }

  Map<String, dynamic> _defaultFighterEconomy() => {
    'totalEarnings': 0,
    'pendingPayouts': 0,
    'purses': [],
    'bonuses': [],
    'sponsorships': [],
  };

  // ── Gym ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getGymEconomy(String gymId) async {
    try {
      final doc = await _fs.collection('gym_economy').doc(gymId).get();
      return doc.exists ? doc.data()! : _defaultGymEconomy();
    } catch (e) {
      debugPrint('EconomyService.getGymEconomy: $e');
      return _defaultGymEconomy();
    }
  }

  Map<String, dynamic> _defaultGymEconomy() => {
    'membershipRevenue': 0,
    'eventRevenue': 0,
    'totalMembers': 0,
    'activeContracts': [],
  };
}
