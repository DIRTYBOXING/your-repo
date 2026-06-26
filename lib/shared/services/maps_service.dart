/// ═══════════════════════════════════════════════════════════════════════════
/// MAPS SERVICE - Location, Gym Finder & Event Discovery
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Features:
/// - Find nearby gyms and training facilities
/// - Discover upcoming MMA events
/// - Track training locations
/// - Navigate to venues
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'package:flutter/foundation.dart';

/// Location coordinates
class GeoLocation {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
  });
}

/// Gym/Training facility
class TrainingVenue {
  final String id;
  final String name;
  final String type; // 'gym', 'dojo', 'arena', 'academy'
  final GeoLocation location;
  final double rating;
  final int reviewCount;
  final List<String> disciplines; // 'MMA', 'BJJ', 'Boxing', etc.
  final bool isOpen;
  final String? distance;
  final String? imageUrl;
  final String? phoneNumber;
  final String? website;

  TrainingVenue({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    this.rating = 0,
    this.reviewCount = 0,
    this.disciplines = const [],
    this.isOpen = true,
    this.distance,
    this.imageUrl,
    this.phoneNumber,
    this.website,
  });
}

/// Event location
class EventVenue {
  final String id;
  final String name;
  final String eventName;
  final DateTime eventDate;
  final GeoLocation location;
  final String organization;
  final bool isPPV;
  final String? ticketUrl;
  final double? ticketPrice;

  EventVenue({
    required this.id,
    required this.name,
    required this.eventName,
    required this.eventDate,
    required this.location,
    required this.organization,
    this.isPPV = false,
    this.ticketUrl,
    this.ticketPrice,
  });

  bool get isUpcoming => eventDate.isAfter(DateTime.now());
  int get daysUntil => eventDate.difference(DateTime.now()).inDays;
}

/// Maps Service
class MapsService extends ChangeNotifier {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();

  // State
  GeoLocation? _currentLocation;
  final List<TrainingVenue> _nearbyGyms = [];
  final List<EventVenue> _upcomingEvents = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  GeoLocation? get currentLocation => _currentLocation;
  List<TrainingVenue> get nearbyGyms => List.unmodifiable(_nearbyGyms);
  List<EventVenue> get upcomingEvents => List.unmodifiable(_upcomingEvents);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize the service
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate location fetch
      await Future.delayed(const Duration(milliseconds: 300));

      _currentLocation = GeoLocation(
        latitude: 36.1699,
        longitude: -115.1398,
        address: '3111 S Las Vegas Blvd',
        city: 'Las Vegas',
        country: 'USA',
      );

      await _loadNearbyGyms();
      await _loadUpcomingEvents();

      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('🗺️ Maps Service initialized');
  }

  Future<void> _loadNearbyGyms() async {
    _nearbyGyms.clear();
    _nearbyGyms.addAll([
      TrainingVenue(
        id: 'gym_1',
        name: 'UFC Performance Institute',
        type: 'academy',
        location: GeoLocation(
          latitude: 36.0857,
          longitude: -115.1531,
          address: '2275 S Highland Dr',
          city: 'Las Vegas',
        ),
        rating: 4.9,
        reviewCount: 245,
        disciplines: ['MMA', 'Wrestling', 'BJJ', 'Striking'],
        distance: '2.3 mi',
      ),
      TrainingVenue(
        id: 'gym_2',
        name: 'Xtreme Couture MMA',
        type: 'gym',
        location: GeoLocation(
          latitude: 36.1389,
          longitude: -115.1725,
          address: '4221 W Sahara Ave',
          city: 'Las Vegas',
        ),
        rating: 4.7,
        reviewCount: 189,
        disciplines: ['MMA', 'BJJ', 'Muay Thai', 'Boxing'],
        distance: '3.1 mi',
      ),
      TrainingVenue(
        id: 'gym_3',
        name: 'Syndicate MMA',
        type: 'gym',
        location: GeoLocation(
          latitude: 36.1108,
          longitude: -115.2154,
          address: '6435 S Jones Blvd',
          city: 'Las Vegas',
        ),
        rating: 4.8,
        reviewCount: 156,
        disciplines: ['MMA', 'Wrestling', 'Kickboxing'],
        distance: '4.5 mi',
      ),
      TrainingVenue(
        id: 'gym_4',
        name: 'Robert Garcia Boxing Academy',
        type: 'gym',
        location: GeoLocation(
          latitude: 33.9425,
          longitude: -117.2297,
          address: '475 N D St',
          city: 'San Bernardino',
        ),
        rating: 4.9,
        reviewCount: 312,
        disciplines: ['Boxing'],
        distance: '210 mi',
      ),
    ]);
  }

  Future<void> _loadUpcomingEvents() async {
    _upcomingEvents.clear();
    _upcomingEvents.addAll([
      EventVenue(
        id: 'event_1',
        name: 'T-Mobile Arena',
        eventName: 'UFC 305',
        eventDate: DateTime.now().add(const Duration(days: 45)),
        location: GeoLocation(
          latitude: 36.1669,
          longitude: -115.1761,
          address: '3780 Las Vegas Blvd S',
          city: 'Las Vegas',
        ),
        organization: 'UFC',
        isPPV: true,
        ticketPrice: 250,
      ),
      EventVenue(
        id: 'event_2',
        name: 'Madison Square Garden',
        eventName: 'UFC 306',
        eventDate: DateTime.now().add(const Duration(days: 75)),
        location: GeoLocation(
          latitude: 40.7505,
          longitude: -73.9934,
          address: '4 Pennsylvania Plaza',
          city: 'New York',
        ),
        organization: 'UFC',
        isPPV: true,
        ticketPrice: 350,
      ),
      EventVenue(
        id: 'event_3',
        name: 'The Forum',
        eventName: 'Bellator 307',
        eventDate: DateTime.now().add(const Duration(days: 21)),
        location: GeoLocation(
          latitude: 33.9583,
          longitude: -118.3419,
          address: '3900 W Manchester Blvd',
          city: 'Inglewood',
        ),
        organization: 'Bellator',
        ticketPrice: 85,
      ),
    ]);
  }

  /// Search for gyms by discipline
  List<TrainingVenue> searchGyms(String discipline) {
    return _nearbyGyms
        .where(
          (g) => g.disciplines.any(
            (d) => d.toLowerCase().contains(discipline.toLowerCase()),
          ),
        )
        .toList();
  }

  /// Get events by organization
  List<EventVenue> getEventsByOrganization(String org) {
    return _upcomingEvents
        .where((e) => e.organization.toLowerCase() == org.toLowerCase())
        .toList();
  }

  /// Calculate distance between two points (simplified)
  double calculateDistance(GeoLocation from, GeoLocation to) {
    // Simplified distance calculation
    final latDiff = (from.latitude - to.latitude).abs();
    final lngDiff = (from.longitude - to.longitude).abs();
    return (latDiff + lngDiff) * 69; // Rough miles
  }

  /// Refresh location
  Future<void> refreshLocation() async {
    await initialize();
  }
}
