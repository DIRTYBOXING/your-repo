import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── FighterGymService stub ────────────────────────────────────────────────────
// Provides gym discovery, fighter-gym linkage, and team management.

class FighterGymService extends ChangeNotifier {
  static final FighterGymService _instance = FighterGymService._();
  factory FighterGymService() => _instance;
  FighterGymService._();

  final _fs = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getGyms({String? city}) async {
    try {
      var q = _fs.collection('gyms').limit(50);
      if (city != null) q = q.where('city', isEqualTo: city) as Query<Map<String, dynamic>> as CollectionReference<Map<String, dynamic>>;
      final snap = await _fs.collection('gyms').limit(50).get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('FighterGymService.getGyms: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getFighterWithGym(String uid) async {
    try {
      final fighterDoc = await _fs.collection('fighters').doc(uid).get();
      if (!fighterDoc.exists) return null;
      final data = fighterDoc.data()!;
      final gymId = data['primaryGymId'] as String?;
      Map<String, dynamic>? gymData;
      if (gymId != null) {
        gymData = await getGym(gymId);
      }
      return {'fighter': data, 'gyms': gymData};
    } catch (e) {
      debugPrint('FighterGymService.getFighterWithGym: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGym(String gymId) async {
    try {
      final doc = await _fs.collection('gyms').doc(gymId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      debugPrint('FighterGymService.getGym: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getFighterWithGym(String uid) async {
    try {
      final fighterDoc = await _fs.collection('fighters').doc(uid).get();
      if (!fighterDoc.exists) return null;
      final data = fighterDoc.data()!;
      final gymId = data['primaryGymId'] as String?;
      Map<String, dynamic>? gymData;
      if (gymId != null) {
        gymData = await getGym(gymId);
      }
      return {'fighter': data, 'gyms': gymData};
    } catch (e) {
      debugPrint('FighterGymService.getFighterWithGym: $e');
      return null;
    }
  }
    try {
      final snap = await _fs
          .collection('gyms')
          .doc(gymId)
          .collection('members')
          .limit(100)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      debugPrint('FighterGymService.getGymMembers: $e');
      return [];
    }
  }
}
