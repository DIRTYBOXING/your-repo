/// ═══════════════════════════════════════════════════════════════════════════
/// MAP MARKER SERVICE — Unified Location Data Layer for All DFC Maps
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Single source of truth for every marker on every map screen.
/// Feeds: DFCGlobalMapScreen, CommunityMapScreen, GymMapCommandScreen,
///        FindAGymScreen, FightWorldMapScreen, combat maps, mentor maps.
///
/// Features:
///  • GeoJSON-compatible data pipeline (FeatureCollection output)
///  • Dynamic marker registry (gyms, events, campaigns, mentors)
///  • Real-time LIVE event detection + status cycling
///  • Firestore hydration with demo fallback
///  • Haversine distance calculations
///  • Bounding-box viewport queries for performance
///  • Tag/filter engine (discipline, tier, type, status)
///  • Marker metadata for info windows & detail panels
///  • Stream-based updates for real-time UI refresh
/// ═══════════════════════════════════════════════════════════════════════════
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

// ─── ENUMS ──────────────────────────────────────────────────────────────────

enum MarkerType { gym, event, campaign, mentor }

enum GymTier { elite, premier, standard, community }

enum EventLiveStatus { live, upcoming, ppv, past, cancelled }

enum CampaignKind { pinkShield, goldCoin, coffeeNotCoffin }

enum MentorTier { pinkDiamond, goldDiamond, community }

// ─── CORE MODELS ────────────────────────────────────────────────────────────

/// Universal coordinate with address metadata.
class MapCoordinate {
  final double lat;
  final double lng;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? countryFlag;

  const MapCoordinate({
    required this.lat,
    required this.lng,
    this.address,
    this.city,
    this.state,
    this.country,
    this.countryFlag,
  });

  /// Full display location: "city, state, country" or available subset.
  String get displayLocation {
    final parts = <String>[?city, ?state, ?country];
    return parts.join(', ');
  }

  /// GeoJSON [longitude, latitude] array.
  List<double> get geoJsonCoordinates => [lng, lat];

  Map<String, dynamic> toMap() => {
    'lat': lat,
    'lng': lng,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (state != null) 'state': state,
    if (country != null) 'country': country,
    if (countryFlag != null) 'countryFlag': countryFlag,
  };

  factory MapCoordinate.fromMap(Map<String, dynamic> m) => MapCoordinate(
    lat: (m['lat'] as num).toDouble(),
    lng: (m['lng'] as num).toDouble(),
    address: m['address'] as String?,
    city: m['city'] as String?,
    state: m['state'] as String?,
    country: m['country'] as String?,
    countryFlag: m['countryFlag'] as String?,
  );
}

/// A single mappable point with full metadata for any marker type.
class MapMarkerData {
  final String id;
  final String name;
  final MarkerType type;
  final MapCoordinate coordinate;
  final String? description;
  final String? imageUrl;
  final String? websiteUrl;
  final String? phoneNumber;
  final List<String> disciplines;
  final List<String> tags;
  final Map<String, dynamic> meta;

  // Gym-specific
  final GymTier? gymTier;
  final double? rating;
  final int? reviewCount;
  final List<String> amenities;
  final bool isVerified;
  final bool isOpen;

  // Event-specific
  final EventLiveStatus? eventStatus;
  final DateTime? eventDate;
  final String? organization;
  final bool isPPV;
  final double? ticketPrice;
  final String? ticketUrl;

  // Campaign-specific
  final CampaignKind? campaignKind;

  // Mentor-specific
  final MentorTier? mentorTier;
  final String? mentorSpecialty;

  const MapMarkerData({
    required this.id,
    required this.name,
    required this.type,
    required this.coordinate,
    this.description,
    this.imageUrl,
    this.websiteUrl,
    this.phoneNumber,
    this.disciplines = const [],
    this.tags = const [],
    this.meta = const {},
    this.gymTier,
    this.rating,
    this.reviewCount,
    this.amenities = const [],
    this.isVerified = false,
    this.isOpen = true,
    this.eventStatus,
    this.eventDate,
    this.organization,
    this.isPPV = false,
    this.ticketPrice,
    this.ticketUrl,
    this.campaignKind,
    this.mentorTier,
    this.mentorSpecialty,
  });

  /// Whether this event is happening now.
  bool get isLive => eventStatus == EventLiveStatus.live;

  /// Whether this event is in the future.
  bool get isUpcoming =>
      eventDate != null && eventDate!.isAfter(DateTime.now());

  /// Days until the event (negative = past).
  int get daysUntil =>
      eventDate != null ? eventDate!.difference(DateTime.now()).inDays : 0;

  /// Display tier string for any marker type.
  String get tierLabel {
    switch (type) {
      case MarkerType.gym:
        return (gymTier ?? GymTier.standard).name.toUpperCase();
      case MarkerType.event:
        return (eventStatus ?? EventLiveStatus.upcoming).name.toUpperCase();
      case MarkerType.campaign:
        switch (campaignKind) {
          case CampaignKind.pinkShield:
            return 'PINK SHIELD';
          case CampaignKind.goldCoin:
            return 'GOLD COIN';
          case CampaignKind.coffeeNotCoffin:
            return 'COFFEE NOT COFFIN';
          case null:
            return 'CAMPAIGN';
        }
      case MarkerType.mentor:
        return (mentorTier ?? MentorTier.community).name.toUpperCase();
    }
  }

  /// Convert to GeoJSON Feature.
  Map<String, dynamic> toGeoJsonFeature() => {
    'type': 'Feature',
    'geometry': {'type': 'Point', 'coordinates': coordinate.geoJsonCoordinates},
    'properties': {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description ?? '',
      'location': coordinate.displayLocation,
      'countryFlag': coordinate.countryFlag ?? '',
      'disciplines': disciplines,
      'tags': tags,
      if (type == MarkerType.gym) ...{
        'tier': (gymTier ?? GymTier.standard).name,
        'rating': rating ?? 0,
        'reviewCount': reviewCount ?? 0,
        'isVerified': isVerified,
        'isOpen': isOpen,
        'amenities': amenities,
      },
      if (type == MarkerType.event) ...{
        'status': (eventStatus ?? EventLiveStatus.upcoming).name,
        'eventDate': eventDate?.toIso8601String(),
        'organization': organization ?? '',
        'isPPV': isPPV,
        'ticketPrice': ticketPrice,
      },
      if (type == MarkerType.campaign)
        'campaignKind': (campaignKind ?? CampaignKind.pinkShield).name,
      if (type == MarkerType.mentor) ...{
        'mentorTier': (mentorTier ?? MentorTier.community).name,
        'specialty': mentorSpecialty ?? '',
      },
    },
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'coordinate': coordinate.toMap(),
    'description': description,
    'disciplines': disciplines,
    'tags': tags,
    'meta': meta,
    if (gymTier != null) 'gymTier': gymTier!.name,
    if (rating != null) 'rating': rating,
    if (reviewCount != null) 'reviewCount': reviewCount,
    'amenities': amenities,
    'isVerified': isVerified,
    if (eventStatus != null) 'eventStatus': eventStatus!.name,
    if (eventDate != null) 'eventDate': eventDate!.toIso8601String(),
    if (organization != null) 'organization': organization,
    'isPPV': isPPV,
    if (campaignKind != null) 'campaignKind': campaignKind!.name,
    if (mentorTier != null) 'mentorTier': mentorTier!.name,
    if (mentorSpecialty != null) 'mentorSpecialty': mentorSpecialty,
  };
}

// ─── BOUNDING BOX ───────────────────────────────────────────────────────────

/// Axis-aligned bounding box for viewport queries.
class MapBounds {
  final double southLat;
  final double westLng;
  final double northLat;
  final double eastLng;

  const MapBounds({
    required this.southLat,
    required this.westLng,
    required this.northLat,
    required this.eastLng,
  });

  bool contains(MapCoordinate c) =>
      c.lat >= southLat &&
      c.lat <= northLat &&
      c.lng >= westLng &&
      c.lng <= eastLng;
}

// ─── FILTER ─────────────────────────────────────────────────────────────────

/// Filter configuration for marker queries.
class MarkerFilter {
  final Set<MarkerType> types;
  final Set<String> disciplines;
  final Set<GymTier> gymTiers;
  final Set<EventLiveStatus> eventStatuses;
  final Set<CampaignKind> campaignKinds;
  final bool onlyVerified;
  final bool onlyOpen;
  final bool onlyLive;
  final String? searchQuery;
  final MapBounds? bounds;
  final double? nearLat;
  final double? nearLng;
  final double? radiusKm;

  const MarkerFilter({
    this.types = const {},
    this.disciplines = const {},
    this.gymTiers = const {},
    this.eventStatuses = const {},
    this.campaignKinds = const {},
    this.onlyVerified = false,
    this.onlyOpen = false,
    this.onlyLive = false,
    this.searchQuery,
    this.bounds,
    this.nearLat,
    this.nearLng,
    this.radiusKm,
  });

  /// Empty filter = show everything.
  bool get isEmpty =>
      types.isEmpty &&
      disciplines.isEmpty &&
      gymTiers.isEmpty &&
      eventStatuses.isEmpty &&
      campaignKinds.isEmpty &&
      !onlyVerified &&
      !onlyOpen &&
      !onlyLive &&
      searchQuery == null &&
      bounds == null &&
      nearLat == null;
}

// ─── SERVICE ────────────────────────────────────────────────────────────────

class MapMarkerService {
  MapMarkerService._();
  static final MapMarkerService instance = MapMarkerService._();

  final _markers = <String, MapMarkerData>{};
  final _controller = StreamController<List<MapMarkerData>>.broadcast();

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Stream of all markers — UI subscribes for real-time updates.
  Stream<List<MapMarkerData>> get markerStream => _controller.stream;

  /// Current snapshot of all markers.
  List<MapMarkerData> get allMarkers => _markers.values.toList();

  /// Count by type.
  int countByType(MarkerType type) =>
      _markers.values.where((m) => m.type == type).length;

  /// Live event count.
  int get liveEventCount => _markers.values.where((m) => m.isLive).length;

  bool get _useSeedFallback =>
      AppConstants.webDemoMode || AppConstants.guestMode;

  // ═══════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════

  /// Load all markers.
  /// In demo mode we seed local markers first; real-auth mode relies on
  /// Firestore-backed collections without injecting demo locations.
  Future<void> initialize() async {
    if (_useSeedFallback) {
      _seedDemoData();
    }

    final firestore = _firestore;
    if (firestore == null) {
      if (_markers.isEmpty && !kReleaseMode) {
        _seedDemoData();
      }
      _notify();
      return;
    }

    await _loadFromFirestore(firestore);
    await _loadGymsFromFirestore(firestore);
    await _loadEventsFromFirestore(firestore);

    if (_markers.isEmpty && _useSeedFallback) {
      _seedDemoData();
    }

    _notify();
  }

  /// Load from the dedicated `map_markers` collection (if populated).
  Future<void> _loadFromFirestore(FirebaseFirestore firestore) async {
    try {
      final snap = await firestore.collection('map_markers').limit(200).get();
      if (snap.docs.isEmpty) return;

      for (final doc in snap.docs) {
        final data = doc.data();
        final type = MarkerType.values.firstWhere(
          (t) => t.name == data['type'],
          orElse: () => MarkerType.gym,
        );
        _markers[doc.id] = MapMarkerData(
          id: doc.id,
          name: data['name'] ?? '',
          type: type,
          coordinate: MapCoordinate.fromMap(
            Map<String, dynamic>.from(data['coordinate'] ?? {}),
          ),
          description: data['description'] as String?,
          disciplines: List<String>.from(data['disciplines'] ?? []),
          tags: List<String>.from(data['tags'] ?? []),
          gymTier: data['gymTier'] != null
              ? GymTier.values.firstWhere(
                  (t) => t.name == data['gymTier'],
                  orElse: () => GymTier.standard,
                )
              : null,
          rating: (data['rating'] as num?)?.toDouble(),
          reviewCount: data['reviewCount'] as int?,
          isVerified: data['isVerified'] == true,
          eventStatus: data['eventStatus'] != null
              ? EventLiveStatus.values.firstWhere(
                  (s) => s.name == data['eventStatus'],
                  orElse: () => EventLiveStatus.upcoming,
                )
              : null,
          eventDate: data['eventDate'] != null
              ? DateTime.tryParse(data['eventDate'])
              : null,
          organization: data['organization'] as String?,
          isPPV: data['isPPV'] == true,
          campaignKind: data['campaignKind'] != null
              ? CampaignKind.values.firstWhere(
                  (k) => k.name == data['campaignKind'],
                  orElse: () => CampaignKind.pinkShield,
                )
              : null,
          mentorTier: data['mentorTier'] != null
              ? MentorTier.values.firstWhere(
                  (t) => t.name == data['mentorTier'],
                  orElse: () => MentorTier.community,
                )
              : null,
          mentorSpecialty: data['mentorSpecialty'] as String?,
        );
      }
    } catch (e) {
      debugPrint('📍 MapMarkerService: map_markers load failed ($e)');
    }
  }

  /// Load gyms from the `gyms` collection (seeded by DatabaseSeeder).
  Future<void> _loadGymsFromFirestore(FirebaseFirestore firestore) async {
    try {
      final snap = await firestore.collection('gyms').limit(200).get();
      if (snap.docs.isEmpty) return;

      for (final doc in snap.docs) {
        final d = doc.data();
        final lat = (d['latitude'] as num?)?.toDouble();
        final lng = (d['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final name = d['name'] as String? ?? '';
        final sports = List<String>.from(d['sportTypes'] ?? []);
        final rating = (d['rating'] as num?)?.toDouble();
        final reviews = d['reviewCount'] as int?;

        // Infer tier from rating
        GymTier tier = GymTier.standard;
        if (rating != null && rating >= 4.9) {
          tier = GymTier.elite;
        } else if (rating != null && rating >= 4.7) {
          tier = GymTier.premier;
        }

        // Parse city/country from address
        final address = d['address'] as String? ?? '';
        String? city;
        String? state;
        String country = 'Australia';
        String flag = '🇦🇺';
        final parts = address.split(',').map((s) => s.trim()).toList();
        if (parts.length >= 3) {
          city = parts[parts.length - 3];
          // Extract state from "VIC 3000" pattern
          final stateZip = parts[parts.length - 2];
          state = stateZip.split(' ').first;
          country = parts.last;
          if (country.contains('New Zealand')) flag = '🇳🇿';
        }

        _markers['fs_gym_${doc.id}'] = MapMarkerData(
          id: 'fs_gym_${doc.id}',
          name: name,
          type: MarkerType.gym,
          coordinate: MapCoordinate(
            lat: lat,
            lng: lng,
            address: address,
            city: city,
            state: state,
            country: country,
            countryFlag: flag,
          ),
          description: d['description'] as String?,
          disciplines: sports,
          gymTier: tier,
          rating: rating,
          reviewCount: reviews,
          isVerified: d['isVerified'] == true,
          phoneNumber: d['phone'] as String?,
          websiteUrl: d['website'] as String?,
        );
      }
      debugPrint(
        '📍 MapMarkerService: loaded ${snap.docs.length} gyms from Firestore',
      );
    } catch (e) {
      debugPrint('📍 MapMarkerService: gyms collection load failed ($e)');
    }
  }

  /// Load events from the `events` collection (seeded by DatabaseSeeder).
  Future<void> _loadEventsFromFirestore(FirebaseFirestore firestore) async {
    try {
      final snap = await firestore.collection('events').limit(200).get();
      if (snap.docs.isEmpty) return;

      for (final doc in snap.docs) {
        final d = doc.data();
        final lat = (d['latitude'] as num?)?.toDouble();
        final lng = (d['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final name = d['title'] as String? ?? d['name'] as String? ?? '';
        DateTime? eventDate;
        if (d['date'] is Timestamp) {
          eventDate = (d['date'] as Timestamp).toDate();
        } else if (d['date'] is String) {
          eventDate = DateTime.tryParse(d['date'] as String);
        }

        // Determine live status
        EventLiveStatus status = EventLiveStatus.upcoming;
        if (eventDate != null) {
          final now = DateTime.now();
          if (eventDate.isBefore(now.subtract(const Duration(hours: 6)))) {
            status = EventLiveStatus.past;
          } else if (eventDate.isBefore(now.add(const Duration(hours: 6))) &&
              eventDate.isAfter(now.subtract(const Duration(hours: 6)))) {
            status = EventLiveStatus.live;
          }
        }
        final isPPV = d['isPPV'] == true;
        if (isPPV && status == EventLiveStatus.upcoming) {
          status = EventLiveStatus.ppv;
        }

        // Parse location
        final venue = d['venue'] as String? ?? '';
        final city = d['city'] as String? ?? '';
        final country = d['country'] as String? ?? 'Australia';
        String flag = '🇦🇺';
        if (country.contains('New Zealand')) flag = '🇳🇿';
        if (country.contains('USA') || country.contains('United States')) {
          flag = '🇺🇸';
        }
        if (country.contains('Thailand')) flag = '🇹🇭';
        if (country.contains('Japan')) flag = '🇯🇵';

        _markers['fs_evt_${doc.id}'] = MapMarkerData(
          id: 'fs_evt_${doc.id}',
          name: name,
          type: MarkerType.event,
          coordinate: MapCoordinate(
            lat: lat,
            lng: lng,
            city: city,
            country: country,
            countryFlag: flag,
          ),
          description: venue,
          organization:
              d['organization'] as String? ?? d['promoter'] as String?,
          eventStatus: status,
          eventDate: eventDate,
          isPPV: isPPV,
          imageUrl: d['posterUrl'] as String? ?? d['imageUrl'] as String?,
          ticketUrl: d['ticketUrl'] as String?,
        );
      }
      debugPrint(
        '📍 MapMarkerService: loaded ${snap.docs.length} events from Firestore',
      );
    } catch (e) {
      debugPrint('📍 MapMarkerService: events collection load failed ($e)');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Filter markers by any combination of criteria.
  List<MapMarkerData> query(MarkerFilter filter) {
    if (filter.isEmpty) return allMarkers;

    return _markers.values.where((m) {
      // Type filter
      if (filter.types.isNotEmpty && !filter.types.contains(m.type)) {
        return false;
      }

      // Discipline filter
      if (filter.disciplines.isNotEmpty) {
        final lowerDisc = filter.disciplines
            .map((d) => d.toLowerCase())
            .toSet();
        if (!m.disciplines.any((d) => lowerDisc.contains(d.toLowerCase()))) {
          return false;
        }
      }

      // Gym tier filter
      if (filter.gymTiers.isNotEmpty &&
          m.type == MarkerType.gym &&
          m.gymTier != null &&
          !filter.gymTiers.contains(m.gymTier)) {
        return false;
      }

      // Event status filter
      if (filter.eventStatuses.isNotEmpty &&
          m.type == MarkerType.event &&
          m.eventStatus != null &&
          !filter.eventStatuses.contains(m.eventStatus)) {
        return false;
      }

      // Campaign kind filter
      if (filter.campaignKinds.isNotEmpty &&
          m.type == MarkerType.campaign &&
          m.campaignKind != null &&
          !filter.campaignKinds.contains(m.campaignKind)) {
        return false;
      }

      // Verified only
      if (filter.onlyVerified && !m.isVerified) return false;

      // Open only
      if (filter.onlyOpen && !m.isOpen) return false;

      // Live only
      if (filter.onlyLive && !m.isLive) return false;

      // Text search
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final q = filter.searchQuery!.toLowerCase();
        if (!m.name.toLowerCase().contains(q) &&
            !(m.description?.toLowerCase().contains(q) ?? false) &&
            !(m.coordinate.city?.toLowerCase().contains(q) ?? false) &&
            !(m.coordinate.country?.toLowerCase().contains(q) ?? false) &&
            !(m.organization?.toLowerCase().contains(q) ?? false)) {
          return false;
        }
      }

      // Bounding box
      if (filter.bounds != null && !filter.bounds!.contains(m.coordinate)) {
        return false;
      }

      // Radius
      if (filter.nearLat != null &&
          filter.nearLng != null &&
          filter.radiusKm != null) {
        final dist = haversineKm(
          filter.nearLat!,
          filter.nearLng!,
          m.coordinate.lat,
          m.coordinate.lng,
        );
        if (dist > filter.radiusKm!) return false;
      }

      return true;
    }).toList();
  }

  /// Get markers within a viewport.
  List<MapMarkerData> inViewport(MapBounds bounds, {MarkerFilter? filter}) {
    final baseFilter = filter ?? const MarkerFilter();
    return query(
      MarkerFilter(
        types: baseFilter.types,
        disciplines: baseFilter.disciplines,
        gymTiers: baseFilter.gymTiers,
        eventStatuses: baseFilter.eventStatuses,
        campaignKinds: baseFilter.campaignKinds,
        onlyVerified: baseFilter.onlyVerified,
        onlyOpen: baseFilter.onlyOpen,
        onlyLive: baseFilter.onlyLive,
        searchQuery: baseFilter.searchQuery,
        bounds: bounds,
      ),
    );
  }

  /// Get nearest N markers to a point.
  List<MapMarkerData> nearest(
    double lat,
    double lng, {
    int limit = 20,
    MarkerFilter? filter,
  }) {
    final candidates = filter != null ? query(filter) : allMarkers;
    final sorted = List<MapMarkerData>.from(candidates)
      ..sort((a, b) {
        final da = haversineKm(lat, lng, a.coordinate.lat, a.coordinate.lng);
        final db = haversineKm(lat, lng, b.coordinate.lat, b.coordinate.lng);
        return da.compareTo(db);
      });
    return sorted.take(limit).toList();
  }

  /// Export all (or filtered) markers as GeoJSON FeatureCollection string.
  String toGeoJson({MarkerFilter? filter}) {
    final features = (filter != null ? query(filter) : allMarkers)
        .map((m) => m.toGeoJsonFeature())
        .toList();
    return jsonEncode({
      'type': 'FeatureCollection',
      'features': features,
      'metadata': {
        'generated': DateTime.now().toIso8601String(),
        'totalFeatures': features.length,
        'source': 'DataFightCentral',
      },
    });
  }

  /// Export as GeoJSON Map (for in-memory use).
  Map<String, dynamic> toGeoJsonMap({MarkerFilter? filter}) {
    final features = (filter != null ? query(filter) : allMarkers)
        .map((m) => m.toGeoJsonFeature())
        .toList();
    return {
      'type': 'FeatureCollection',
      'features': features,
      'metadata': {
        'generated': DateTime.now().toIso8601String(),
        'totalFeatures': features.length,
      },
    };
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Add or update a marker.
  void upsert(MapMarkerData marker) {
    _markers[marker.id] = marker;
    _notify();
  }

  /// Remove a marker.
  void remove(String id) {
    _markers.remove(id);
    _notify();
  }

  /// Set live status on an event marker.
  void setEventLive(String eventId, EventLiveStatus status) {
    final existing = _markers[eventId];
    if (existing == null || existing.type != MarkerType.event) return;
    _markers[eventId] = MapMarkerData(
      id: existing.id,
      name: existing.name,
      type: existing.type,
      coordinate: existing.coordinate,
      description: existing.description,
      imageUrl: existing.imageUrl,
      websiteUrl: existing.websiteUrl,
      phoneNumber: existing.phoneNumber,
      disciplines: existing.disciplines,
      tags: existing.tags,
      meta: existing.meta,
      eventStatus: status,
      eventDate: existing.eventDate,
      organization: existing.organization,
      isPPV: existing.isPPV,
      ticketPrice: existing.ticketPrice,
      ticketUrl: existing.ticketUrl,
    );
    _notify();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════════════════════════════════

  Map<String, dynamic> get stats => {
    'totalMarkers': _markers.length,
    'gyms': countByType(MarkerType.gym),
    'events': countByType(MarkerType.event),
    'campaigns': countByType(MarkerType.campaign),
    'mentors': countByType(MarkerType.mentor),
    'liveNow': liveEventCount,
    'countries': _markers.values
        .map((m) => m.coordinate.country)
        .where((c) => c != null)
        .toSet()
        .length,
  };

  void _notify() {
    _controller.add(allMarkers);
  }

  void dispose() {
    _controller.close();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // HAVERSINE DISTANCE
  // ═══════════════════════════════════════════════════════════════════════

  /// Distance between two points on Earth in km.
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371.0; // Earth radius km
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Same but in miles.
  static double haversineMi(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => haversineKm(lat1, lng1, lat2, lng2) * 0.621371;

  static double _rad(double deg) => deg * pi / 180.0;

  // ═══════════════════════════════════════════════════════════════════════
  // SEED DATA — 60+ real-world combat locations across 6 continents
  // ═══════════════════════════════════════════════════════════════════════

  void _seedDemoData() {
    _markers.clear();

    // ─── ELITE GYMS ─────────────────────────────────────────────────
    _addGym(
      'gym_ufc_pi',
      'UFC Performance Institute',
      36.085,
      -115.153,
      'Las Vegas',
      'NV',
      'USA',
      '🇺🇸',
      tier: GymTier.elite,
      disciplines: ['MMA', 'Wrestling', 'BJJ', 'Striking'],
      rating: 4.9,
      reviewCount: 245,
      verified: true,
    );

    _addGym(
      'gym_tiger',
      'Tiger Muay Thai',
      7.880,
      98.392,
      'Phuket',
      null,
      'Thailand',
      '🇹🇭',
      tier: GymTier.elite,
      disciplines: ['Muay Thai', 'MMA', 'BJJ'],
      rating: 4.8,
      reviewCount: 312,
      verified: true,
    );

    _addGym(
      'gym_att',
      'American Top Team',
      26.254,
      -80.178,
      'Coconut Creek',
      'FL',
      'USA',
      '🇺🇸',
      tier: GymTier.elite,
      disciplines: ['MMA', 'Wrestling', 'Boxing'],
      rating: 4.8,
      reviewCount: 280,
      verified: true,
    );

    _addGym(
      'gym_ckb',
      'City Kickboxing',
      -36.860,
      174.763,
      'Auckland',
      null,
      'New Zealand',
      '🇳🇿',
      tier: GymTier.elite,
      disciplines: ['MMA', 'Kickboxing', 'Wrestling'],
      rating: 4.9,
      reviewCount: 198,
      verified: true,
    );

    _addGym(
      'gym_evolve',
      'Evolve MMA',
      1.280,
      103.851,
      'Singapore',
      null,
      'Singapore',
      '🇸🇬',
      tier: GymTier.elite,
      disciplines: ['MMA', 'Muay Thai', 'BJJ'],
      rating: 4.8,
      reviewCount: 267,
      verified: true,
    );

    _addGym(
      'gym_tristar',
      'Tristar Gym',
      45.508,
      -73.587,
      'Montreal',
      'QC',
      'Canada',
      '🇨🇦',
      tier: GymTier.elite,
      disciplines: ['MMA', 'BJJ', 'Wrestling'],
      rating: 4.9,
      reviewCount: 175,
      verified: true,
    );

    _addGym(
      'gym_jackson',
      'Jackson Wink MMA',
      35.084,
      -106.650,
      'Albuquerque',
      'NM',
      'USA',
      '🇺🇸',
      tier: GymTier.premier,
      disciplines: ['MMA', 'Kickboxing'],
      rating: 4.7,
      reviewCount: 201,
    );

    _addGym(
      'gym_gracie_hq',
      'Gracie Barra HQ',
      -22.906,
      -43.172,
      'Rio de Janeiro',
      null,
      'Brazil',
      '🇧🇷',
      tier: GymTier.elite,
      disciplines: ['BJJ', 'MMA'],
      rating: 4.9,
      reviewCount: 340,
      verified: true,
    );

    _addGym(
      'gym_kings',
      'Kings MMA',
      33.660,
      -117.999,
      'Huntington Beach',
      'CA',
      'USA',
      '🇺🇸',
      tier: GymTier.premier,
      disciplines: ['MMA', 'BJJ', 'Muay Thai'],
      rating: 4.7,
      reviewCount: 156,
    );

    _addGym(
      'gym_fairtex',
      'Fairtex Training Center',
      12.927,
      100.877,
      'Pattaya',
      null,
      'Thailand',
      '🇹🇭',
      tier: GymTier.elite,
      disciplines: ['Muay Thai', 'MMA'],
      rating: 4.8,
      reviewCount: 290,
      verified: true,
    );

    _addGym(
      'gym_atos',
      'ATOS Jiu-Jitsu',
      32.731,
      -117.189,
      'San Diego',
      'CA',
      'USA',
      '🇺🇸',
      tier: GymTier.elite,
      disciplines: ['BJJ'],
      rating: 4.9,
      reviewCount: 178,
      verified: true,
    );

    _addGym(
      'gym_alliance',
      'Alliance MMA',
      32.715,
      -117.161,
      'San Diego',
      'CA',
      'USA',
      '🇺🇸',
      tier: GymTier.premier,
      disciplines: ['MMA', 'Wrestling', 'BJJ'],
      rating: 4.7,
      reviewCount: 145,
    );

    _addGym(
      'gym_shootfighters',
      'London Shootfighters',
      51.507,
      -0.127,
      'London',
      null,
      'United Kingdom',
      '🇬🇧',
      tier: GymTier.premier,
      disciplines: ['MMA', 'BJJ', 'Wrestling'],
      rating: 4.6,
      reviewCount: 134,
    );

    _addGym(
      'gym_nogueira',
      'Team Nogueira',
      -23.550,
      -46.633,
      'São Paulo',
      null,
      'Brazil',
      '🇧🇷',
      tier: GymTier.premier,
      disciplines: ['MMA', 'BJJ', 'Boxing'],
      rating: 4.7,
      reviewCount: 189,
    );

    _addGym(
      'gym_absolute',
      'Absolute MMA',
      -37.813,
      144.963,
      'Melbourne',
      'VIC',
      'Australia',
      '🇦🇺',
      disciplines: ['MMA', 'Boxing', 'Kickboxing', 'BJJ'],
      rating: 4.6,
      reviewCount: 98,
    );

    _addGym(
      'gym_crows',
      'Crows Nest MMA',
      -33.826,
      151.203,
      'Sydney',
      'NSW',
      'Australia',
      '🇦🇺',
      disciplines: ['MMA', 'BJJ', 'Muay Thai'],
      rating: 4.5,
      reviewCount: 87,
    );

    _addGym(
      'gym_eternal',
      'Eternal MMA Training',
      -27.470,
      153.021,
      'Brisbane',
      'QLD',
      'Australia',
      '🇦🇺',
      tier: GymTier.premier,
      disciplines: ['MMA', 'BJJ', 'Muay Thai'],
      rating: 4.7,
      reviewCount: 112,
    );

    _addGym(
      'gym_gc_combat',
      'Gold Coast Combat',
      -27.963,
      153.382,
      'Gold Coast',
      'QLD',
      'Australia',
      '🇦🇺',
      disciplines: ['MMA', 'Boxing', 'Kickboxing'],
      rating: 4.4,
      reviewCount: 67,
    );

    _addGym(
      'gym_perth',
      'Perth MMA Academy',
      -31.950,
      115.860,
      'Perth',
      'WA',
      'Australia',
      '🇦🇺',
      disciplines: ['MMA', 'Wrestling'],
      rating: 4.3,
      reviewCount: 55,
    );

    _addGym(
      'gym_sanford',
      'Sanford MMA',
      26.320,
      -80.100,
      'Deerfield Beach',
      'FL',
      'USA',
      '🇺🇸',
      tier: GymTier.elite,
      disciplines: ['MMA', 'Wrestling', 'Boxing'],
      rating: 4.8,
      reviewCount: 220,
      verified: true,
    );

    _addGym(
      'gym_killcliff',
      'Kill Cliff FC',
      26.318,
      -80.099,
      'Deerfield Beach',
      'FL',
      'USA',
      '🇺🇸',
      tier: GymTier.premier,
      disciplines: ['MMA', 'Wrestling', 'Boxing'],
      rating: 4.7,
      reviewCount: 165,
    );

    _addGym(
      'gym_fightready',
      'Fight Ready',
      33.494,
      -111.926,
      'Scottsdale',
      'AZ',
      'USA',
      '🇺🇸',
      tier: GymTier.premier,
      disciplines: ['MMA', 'Kickboxing'],
      rating: 4.6,
      reviewCount: 132,
    );

    _addGym(
      'gym_10planet',
      '10th Planet Austin',
      30.267,
      -97.743,
      'Austin',
      'TX',
      'USA',
      '🇺🇸',
      disciplines: ['BJJ', 'No-Gi'],
      rating: 4.5,
      reviewCount: 89,
    );

    _addGym(
      'gym_renzo',
      'Renzo Gracie NYC',
      40.750,
      -73.993,
      'New York',
      'NY',
      'USA',
      '🇺🇸',
      tier: GymTier.elite,
      disciplines: ['BJJ', 'MMA'],
      rating: 4.9,
      reviewCount: 310,
      verified: true,
    );

    _addGym(
      'gym_marrok',
      'Marrok Force',
      13.756,
      100.501,
      'Bangkok',
      null,
      'Thailand',
      '🇹🇭',
      disciplines: ['Muay Thai', 'MMA'],
      rating: 4.4,
      reviewCount: 74,
    );

    _addGym(
      'gym_xtreme',
      'Xtreme Couture MMA',
      36.139,
      -115.173,
      'Las Vegas',
      'NV',
      'USA',
      '🇺🇸',
      tier: GymTier.premier,
      disciplines: ['MMA', 'BJJ', 'Muay Thai', 'Boxing'],
      rating: 4.7,
      reviewCount: 189,
    );

    _addGym(
      'gym_syndicate',
      'Syndicate MMA',
      36.111,
      -115.215,
      'Las Vegas',
      'NV',
      'USA',
      '🇺🇸',
      tier: GymTier.premier,
      disciplines: ['MMA', 'Wrestling', 'Kickboxing'],
      rating: 4.8,
      reviewCount: 156,
    );

    // ─── EVENTS ─────────────────────────────────────────────────────
    _addEvent(
      'evt_ufc323',
      'UFC 323',
      -33.847,
      151.063,
      'Sydney',
      'NSW',
      'Australia',
      '🇦🇺',
      org: 'UFC',
      status: EventLiveStatus.ppv,
      date: DateTime(2026, 4, 15),
      isPPV: true,
      desc: 'Qudos Bank Arena · PPV Main Card',
    );

    _addEvent(
      'evt_one144',
      'ONE Friday Fights 144',
      13.753,
      100.543,
      'Bangkok',
      null,
      'Thailand',
      '🇹🇭',
      org: 'ONE Championship',
      status: EventLiveStatus.live,
      date: DateTime.now(),
      desc: 'Lumpinee Stadium · LIVE NOW',
    );

    _addEvent(
      'evt_bellator',
      'Bellator 310',
      33.958,
      -118.342,
      'Inglewood',
      'CA',
      'USA',
      '🇺🇸',
      org: 'Bellator',
      date: DateTime(2026, 4, 22),
      desc: 'The Forum',
    );

    _addEvent(
      'evt_rizin',
      'RIZIN 53',
      35.895,
      139.631,
      'Saitama',
      null,
      'Japan',
      '🇯🇵',
      org: 'RIZIN',
      status: EventLiveStatus.ppv,
      date: DateTime(2026, 4, 29),
      isPPV: true,
      desc: 'Saitama Super Arena · PPV',
    );

    _addEvent(
      'evt_glory',
      'Glory 102',
      51.893,
      4.489,
      'Rotterdam',
      null,
      'Netherlands',
      '🇳🇱',
      org: 'Glory',
      status: EventLiveStatus.live,
      date: DateTime.now(),
      desc: 'Ahoy Rotterdam · LIVE NOW',
    );

    _addEvent(
      'evt_hex',
      'Hex Fight Series 28',
      -27.560,
      153.064,
      'Brisbane',
      'QLD',
      'Australia',
      '🇦🇺',
      org: 'Hex',
      date: DateTime(2026, 4, 14),
      desc: 'Brisbane Entertainment Centre',
    );

    _addEvent(
      'evt_bkfc_au',
      'BKFC Australia 1',
      -31.951,
      115.860,
      'Perth',
      'WA',
      'Australia',
      '🇦🇺',
      org: 'BKFC',
      status: EventLiveStatus.ppv,
      date: DateTime(2026, 5, 5),
      isPPV: true,
      desc: 'Perth Arena · PPV',
    );

    _addEvent(
      'evt_ibc',
      'IBC III',
      -27.963,
      153.382,
      'Gold Coast',
      'QLD',
      'Australia',
      '🇦🇺',
      org: 'IBC',
      date: DateTime(2026, 4, 7),
      desc: 'Gold Coast Training Centre',
    );

    _addEvent(
      'evt_ufc_fn',
      'UFC Fight Night',
      36.080,
      -115.150,
      'Las Vegas',
      'NV',
      'USA',
      '🇺🇸',
      org: 'UFC',
      date: DateTime(2026, 4, 8),
      desc: 'UFC Apex',
    );

    _addEvent(
      'evt_pfl',
      'PFL Europe',
      48.856,
      2.352,
      'Paris',
      null,
      'France',
      '🇫🇷',
      org: 'PFL',
      date: DateTime(2026, 4, 20),
      desc: 'Accor Arena',
    );

    _addEvent(
      'evt_cw',
      'Cage Warriors 180',
      53.483,
      -2.244,
      'Manchester',
      null,
      'United Kingdom',
      '🇬🇧',
      org: 'Cage Warriors',
      date: DateTime(2026, 4, 25),
      desc: 'AO Arena',
    );

    _addEvent(
      'evt_ksw',
      'KSW 100',
      52.229,
      21.012,
      'Warsaw',
      null,
      'Poland',
      '🇵🇱',
      org: 'KSW',
      status: EventLiveStatus.ppv,
      date: DateTime(2026, 5, 12),
      isPPV: true,
      desc: 'National Stadium · PPV',
    );

    // ─── CAMPAIGNS ──────────────────────────────────────────────────
    _addCampaign(
      'camp_ironwill',
      'Iron Will MMA Academy',
      34.052,
      -118.243,
      'Los Angeles',
      'CA',
      'USA',
      '🇺🇸',
      desc: 'DV-safe zone · Women\'s self-defense',
    );

    _addCampaign(
      'camp_harmony',
      'Harmony Fight Club',
      40.750,
      -73.993,
      'New York',
      'NY',
      'USA',
      '🇺🇸',
      desc: 'Anti-bullying certified',
    );

    _addCampaign(
      'camp_phoenix',
      'Phoenix Rising BJJ',
      25.761,
      -80.191,
      'Miami',
      'FL',
      'USA',
      '🇺🇸',
      desc: 'LGBTQ+ friendly',
    );

    _addCampaign(
      'camp_crows',
      'Crows Nest Safe Space',
      -33.826,
      151.203,
      'Sydney',
      'NSW',
      'Australia',
      '🇦🇺',
      desc: 'DV-safe certified',
    );

    _addCampaign(
      'camp_absolute',
      'Absolute MMA Haven',
      -37.813,
      144.963,
      'Melbourne',
      'VIC',
      'Australia',
      '🇦🇺',
      desc: 'Trauma-aware coaches',
    );

    _addCampaign(
      'camp_ckb',
      'CKB Safe Zone',
      -36.860,
      174.763,
      'Auckland',
      null,
      'New Zealand',
      '🇳🇿',
      desc: 'Women\'s empowerment',
    );

    _addCampaign(
      'camp_shootfighters',
      'Shootfighters Refuge',
      51.507,
      -0.127,
      'London',
      null,
      'United Kingdom',
      '🇬🇧',
      desc: 'Confidential support',
    );

    _addCampaign(
      'camp_eternal',
      'Eternal MMA Youth Fund',
      -27.470,
      153.021,
      'Brisbane',
      'QLD',
      'Australia',
      '🇦🇺',
      kind: CampaignKind.goldCoin,
      desc: 'At-risk youth training',
    );

    _addCampaign(
      'camp_gracie',
      'Gracie Barra Scholarship',
      -22.906,
      -43.172,
      'Rio de Janeiro',
      null,
      'Brazil',
      '🇧🇷',
      kind: CampaignKind.goldCoin,
      desc: 'Free BJJ for kids',
    );

    _addCampaign(
      'camp_perth',
      'Perth Youth Boxing',
      -31.950,
      115.860,
      'Perth',
      'WA',
      'Australia',
      '🇦🇺',
      kind: CampaignKind.goldCoin,
      desc: 'Community-funded',
    );

    _addCampaign(
      'camp_att',
      'ATT Youth Program',
      26.254,
      -80.178,
      'Coconut Creek',
      'FL',
      'USA',
      '🇺🇸',
      kind: CampaignKind.goldCoin,
      desc: 'Underprivileged training',
    );

    _addCampaign(
      'camp_gc_coffee',
      '24hr Gold Coast Grind',
      -27.963,
      153.382,
      'Gold Coast',
      'QLD',
      'Australia',
      '🇦🇺',
      kind: CampaignKind.coffeeNotCoffin,
      desc: '24hr safe coffee',
    );

    _addCampaign(
      'camp_vegas_coffee',
      'Vegas Training Fuel',
      36.085,
      -115.153,
      'Las Vegas',
      'NV',
      'USA',
      '🇺🇸',
      kind: CampaignKind.coffeeNotCoffin,
      desc: '24hr athlete café',
    );

    _addCampaign(
      'camp_bkk_coffee',
      'Bangkok Muay Brew',
      13.756,
      100.501,
      'Bangkok',
      null,
      'Thailand',
      '🇹🇭',
      kind: CampaignKind.coffeeNotCoffin,
      desc: '24hr fight culture café',
    );

    // ─── MENTORS ────────────────────────────────────────────────────
    _addMentor(
      'mentor_sarah',
      'Coach Sarah Chen',
      32.715,
      -117.161,
      'San Diego',
      'CA',
      'USA',
      '🇺🇸',
      tier: MentorTier.pinkDiamond,
      specialty: 'BJJ & Women\'s MMA',
    );

    _addMentor(
      'mentor_kru',
      'Master Kru Phet',
      13.756,
      100.501,
      'Bangkok',
      null,
      'Thailand',
      '🇹🇭',
      tier: MentorTier.goldDiamond,
      specialty: 'Muay Thai legend',
    );

    _addMentor(
      'mentor_carlos',
      'Professor Carlos Silva',
      -22.906,
      -43.172,
      'Rio de Janeiro',
      null,
      'Brazil',
      '🇧🇷',
      tier: MentorTier.goldDiamond,
      specialty: 'BJJ 5th degree',
    );

    _addMentor(
      'mentor_mike',
      'Coach Mike Brown',
      26.254,
      -80.178,
      'Coconut Creek',
      'FL',
      'USA',
      '🇺🇸',
      tier: MentorTier.goldDiamond,
      specialty: 'Former UFC champion',
    );

    _addMentor(
      'mentor_ronda',
      'Sensei Ronda',
      34.052,
      -118.243,
      'Los Angeles',
      'CA',
      'USA',
      '🇺🇸',
      tier: MentorTier.pinkDiamond,
      specialty: 'Judo Olympian',
    );
  }

  // ─── SEED HELPERS ─────────────────────────────────────────────────

  void _addGym(
    String id,
    String name,
    double lat,
    double lng,
    String city,
    String? state,
    String country,
    String flag, {
    GymTier tier = GymTier.standard,
    List<String> disciplines = const [],
    double rating = 0,
    int reviewCount = 0,
    bool verified = false,
  }) {
    _markers[id] = MapMarkerData(
      id: id,
      name: name,
      type: MarkerType.gym,
      coordinate: MapCoordinate(
        lat: lat,
        lng: lng,
        city: city,
        state: state,
        country: country,
        countryFlag: flag,
      ),
      disciplines: disciplines,
      gymTier: tier,
      rating: rating,
      reviewCount: reviewCount,
      isVerified: verified,
    );
  }

  void _addEvent(
    String id,
    String name,
    double lat,
    double lng,
    String city,
    String? state,
    String country,
    String flag, {
    String org = '',
    EventLiveStatus status = EventLiveStatus.upcoming,
    DateTime? date,
    bool isPPV = false,
    String desc = '',
  }) {
    _markers[id] = MapMarkerData(
      id: id,
      name: name,
      type: MarkerType.event,
      coordinate: MapCoordinate(
        lat: lat,
        lng: lng,
        city: city,
        state: state,
        country: country,
        countryFlag: flag,
      ),
      description: desc,
      organization: org,
      eventStatus: status,
      eventDate: date,
      isPPV: isPPV,
    );
  }

  void _addCampaign(
    String id,
    String name,
    double lat,
    double lng,
    String city,
    String? state,
    String country,
    String flag, {
    CampaignKind kind = CampaignKind.pinkShield,
    String desc = '',
  }) {
    _markers[id] = MapMarkerData(
      id: id,
      name: name,
      type: MarkerType.campaign,
      coordinate: MapCoordinate(
        lat: lat,
        lng: lng,
        city: city,
        state: state,
        country: country,
        countryFlag: flag,
      ),
      description: desc,
      campaignKind: kind,
    );
  }

  void _addMentor(
    String id,
    String name,
    double lat,
    double lng,
    String city,
    String? state,
    String country,
    String flag, {
    MentorTier tier = MentorTier.community,
    String specialty = '',
  }) {
    _markers[id] = MapMarkerData(
      id: id,
      name: name,
      type: MarkerType.mentor,
      coordinate: MapCoordinate(
        lat: lat,
        lng: lng,
        city: city,
        state: state,
        country: country,
        countryFlag: flag,
      ),
      mentorTier: tier,
      mentorSpecialty: specialty,
    );
  }
}
