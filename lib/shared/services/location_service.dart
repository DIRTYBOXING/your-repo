import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gym_model.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Demo mode flag - set to false for production, true for demo/showcase
  static const bool _useDemoData = false;

  Future<List<GymModel>> getNearbyGyms(
    double lat,
    double lng, {
    double radiusKm = 10,
  }) async {
    // For demo/showcase, always return demo data
    if (_useDemoData) {
      return _getDemoGyms(lat, lng);
    }

    try {
      // Note: Real geo-queries in Firestore require a library like geoflutterfire
      // or specific lat/lng range queries. For MVP, we fetch 'active' gyms.
      final snapshot = await _firestore
          .collection('gyms')
          .where('status', isEqualTo: 'active')
          .limit(20)
          .get();

      if (snapshot.docs.isEmpty) {
        // Return demo gyms when Firestore is empty
        return _getDemoGyms(lat, lng);
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GymModel(
          id: doc.id,
          userId: data['userId'] ?? '',
          name: data['name'] ?? 'Unknown Gym',
          description: data['description'],
          address: data['address'],
          latitude: (data['latitude'] ?? 0.0),
          longitude: (data['longitude'] ?? 0.0),
          sportTypes: List<String>.from(data['sportTypes'] ?? []),
          amenities: List<String>.from(data['amenities'] ?? []),
          photoGallery: List<String>.from(data['photoGallery'] ?? []),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      // Return demo gyms on error
      return _getDemoGyms(lat, lng);
    }
  }

  /// Returns demo gyms for display purposes
  List<GymModel> _getDemoGyms(double centerLat, double centerLng) {
    return [
      GymModel(
        id: 'absolute_mma',
        userId: 'owner_1',
        name: 'Absolute MMA Melbourne',
        description:
            'Premier MMA training facility home to Lachlan Giles and world-class grapplers.',
        address: '288 Lorimer St, Port Melbourne VIC 3207',
        latitude: centerLat + 0.01,
        longitude: centerLng - 0.008,
        sportTypes: const ['MMA', 'Brazilian Jiu-Jitsu', 'Muay Thai', 'Wrestling'],
        amenities: const [
          'Competition Cage',
          'Weight Room',
          'Sauna',
          'Pro Shop',
          'Cardio Area',
        ],
        coachIds: const ['coach_1', 'coach_2'],
        fighterIds: const ['fighter_1', 'fighter_2', 'fighter_3'],
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      GymModel(
        id: 'corp_boxing',
        userId: 'owner_2',
        name: 'Corporate Boxing Melbourne',
        description:
            'Traditional boxing gym focused on fundamentals and championship-level training in the heart of Melbourne.',
        address: '123 Flinders Lane, Melbourne VIC 3000',
        latitude: centerLat - 0.015,
        longitude: centerLng + 0.012,
        sportTypes: const ['Boxing', 'Fitness Boxing'],
        amenities: const [
          'Full Boxing Ring',
          'Heavy Bags',
          'Speed Bags',
          'Conditioning Area',
        ],
        coachIds: const ['coach_3'],
        fighterIds: const ['fighter_4', 'fighter_5'],
        createdAt: DateTime.now().subtract(const Duration(days: 500)),
        updatedAt: DateTime.now(),
      ),
      GymModel(
        id: 'gracie_bjj_melbourne',
        userId: 'owner_3',
        name: 'Southern Cross BJJ Melbourne',
        description:
            'Official Gracie BJJ academy for all skill levels from white to black belt.',
        address: '56 Johnston St, Collingwood VIC 3066',
        latitude: centerLat + 0.008,
        longitude: centerLng + 0.018,
        sportTypes: const ['Brazilian Jiu-Jitsu', 'No-Gi Grappling', 'Wrestling'],
        amenities: const [
          'Competition Mats',
          'Video Analysis Room',
          'Recovery Station',
        ],
        coachIds: const ['coach_4', 'coach_5'],
        fighterIds: const ['fighter_6', 'fighter_7', 'fighter_8'],
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
      GymModel(
        id: 'tiger_muay_thai_brisbane',
        userId: 'owner_4',
        name: 'Golden Dragon Muay Thai Brisbane',
        description:
            'Authentic Muay Thai training with experienced Thai trainers and traditional techniques.',
        address: '42 Vulture St, West End QLD 4101',
        latitude: centerLat - 0.02,
        longitude: centerLng - 0.015,
        sportTypes: const ['Muay Thai', 'Kickboxing', 'Clinch Work'],
        amenities: const ['Thai Pads', 'Heavy Bags', 'Full Ring', 'Meditation Room'],
        coachIds: const ['coach_6'],
        fighterIds: const ['fighter_9', 'fighter_10'],
        createdAt: DateTime.now().subtract(const Duration(days: 730)),
        updatedAt: DateTime.now(),
      ),
      GymModel(
        id: 'ufc_gym_sydney',
        userId: 'owner_5',
        name: 'UFC Gym Sydney',
        description:
            'Multi-discipline combat sports facility with cutting-edge recovery and analytics.',
        address: '12 Harbour St, Sydney NSW 2000',
        latitude: centerLat + 0.025,
        longitude: centerLng - 0.02,
        sportTypes: const ['MMA', 'Boxing', 'Wrestling', 'Strength & Conditioning'],
        amenities: const [
          'Cryotherapy',
          'Float Tank',
          'Biomechanics Lab',
          'Nutrition Bar',
        ],
        coachIds: const ['coach_7', 'coach_8', 'coach_9'],
        fighterIds: const ['fighter_11', 'fighter_12', 'fighter_13', 'fighter_14'],
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}
