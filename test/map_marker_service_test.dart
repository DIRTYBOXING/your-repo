import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:datafightcentral/shared/services/map_marker_service.dart';

void main() {
  group('MapCoordinate', () {
    test('displayLocation joins available parts', () {
      const c = MapCoordinate(
        lat: 34.0,
        lng: -118.0,
        city: 'Los Angeles',
        state: 'CA',
        country: '🇺🇸',
      );
      expect(c.displayLocation, 'Los Angeles, CA, 🇺🇸');
    });

    test('displayLocation handles missing fields', () {
      const c = MapCoordinate(lat: 0, lng: 0, city: 'London');
      expect(c.displayLocation, 'London');
    });

    test('geoJsonCoordinates returns [lng, lat]', () {
      const c = MapCoordinate(lat: 10.0, lng: 20.0);
      expect(c.geoJsonCoordinates, [20.0, 10.0]);
    });

    test('toMap / fromMap round-trips', () {
      const c = MapCoordinate(
        lat: 34.052,
        lng: -118.243,
        city: 'LA',
        country: '🇺🇸',
      );
      final m = c.toMap();
      final c2 = MapCoordinate.fromMap(m);
      expect(c2.lat, c.lat);
      expect(c2.lng, c.lng);
      expect(c2.city, c.city);
      expect(c2.country, c.country);
    });
  });

  group('MapMarkerData', () {
    late MapMarkerData gym;
    late MapMarkerData event;
    late MapMarkerData campaign;
    late MapMarkerData mentor;

    setUp(() {
      gym = const MapMarkerData(
        id: 'gym_1',
        name: 'Test Gym',
        type: MarkerType.gym,
        coordinate: MapCoordinate(lat: 36.0, lng: -115.0, city: 'Vegas'),
        gymTier: GymTier.elite,
        rating: 4.9,
        reviewCount: 100,
        disciplines: ['MMA', 'BJJ'],
        isVerified: true,
      );

      event = MapMarkerData(
        id: 'evt_1',
        name: 'UFC 300',
        type: MarkerType.event,
        coordinate: const MapCoordinate(lat: 36.0, lng: -115.0),
        eventStatus: EventLiveStatus.live,
        organization: 'UFC',
        isPPV: true,
        eventDate: DateTime.now().add(const Duration(days: 1)),
      );

      campaign = const MapMarkerData(
        id: 'camp_1',
        name: 'Safe Zone',
        type: MarkerType.campaign,
        coordinate: MapCoordinate(lat: 34.0, lng: -118.0),
        campaignKind: CampaignKind.pinkShield,
        tags: ['verified'],
      );

      mentor = const MapMarkerData(
        id: 'mentor_1',
        name: 'Coach Test',
        type: MarkerType.mentor,
        coordinate: MapCoordinate(lat: 32.0, lng: -117.0),
        mentorTier: MentorTier.pinkDiamond,
        mentorSpecialty: 'BJJ',
        rating: 5.0,
      );
    });

    test('isLive returns true for live events', () {
      expect(event.isLive, isTrue);
    });

    test('isLive returns false for gyms', () {
      expect(gym.isLive, isFalse);
    });

    test('isUpcoming returns true for future events', () {
      expect(event.isUpcoming, isTrue);
    });

    test('daysUntil positive for future event', () {
      final futureEvent = MapMarkerData(
        id: 'evt_2',
        name: 'Future',
        type: MarkerType.event,
        coordinate: const MapCoordinate(lat: 0, lng: 0),
        eventDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(futureEvent.daysUntil, greaterThanOrEqualTo(9));
    });

    test('tierLabel returns correct strings', () {
      expect(gym.tierLabel, 'ELITE');
      expect(campaign.tierLabel, 'PINK SHIELD');
      expect(mentor.tierLabel, 'PINKDIAMOND');
    });

    test('toGeoJsonFeature produces valid GeoJSON', () {
      final feature = gym.toGeoJsonFeature();
      expect(feature['type'], 'Feature');
      expect(feature['geometry']['type'], 'Point');
      expect(feature['geometry']['coordinates'], [-115.0, 36.0]);
      expect(feature['properties']['name'], 'Test Gym');
      expect(feature['properties']['type'], 'gym');
      expect(feature['properties']['tier'], 'elite');
    });

    test('toMap / toGeoJsonFeature do not throw', () {
      expect(() => gym.toMap(), returnsNormally);
      expect(() => event.toGeoJsonFeature(), returnsNormally);
      expect(() => campaign.toGeoJsonFeature(), returnsNormally);
      expect(() => mentor.toGeoJsonFeature(), returnsNormally);
    });
  });

  group('MapBounds', () {
    test('contains returns true for point inside', () {
      const bounds = MapBounds(
        southLat: 30.0,
        westLng: -120.0,
        northLat: 40.0,
        eastLng: -100.0,
      );
      expect(
        bounds.contains(const MapCoordinate(lat: 35.0, lng: -110.0)),
        isTrue,
      );
    });

    test('contains returns false for point outside', () {
      const bounds = MapBounds(
        southLat: 30.0,
        westLng: -120.0,
        northLat: 40.0,
        eastLng: -100.0,
      );
      expect(
        bounds.contains(const MapCoordinate(lat: 50.0, lng: -110.0)),
        isFalse,
      );
    });
  });

  group('MapMarkerService', () {
    late MapMarkerService service;

    setUp(() async {
      service = MapMarkerService.instance;
      await service.initialize();
    });

    test('initializes with demo data', () {
      expect(service.allMarkers, isNotEmpty);
    });

    test('allMarkers contains gyms, events, campaigns, mentors', () {
      final types = service.allMarkers.map((m) => m.type).toSet();
      expect(
        types,
        containsAll([
          MarkerType.gym,
          MarkerType.event,
          MarkerType.campaign,
          MarkerType.mentor,
        ]),
      );
    });

    test('query filters by type', () {
      final gyms = service.query(const MarkerFilter(types: {MarkerType.gym}));
      for (final m in gyms) {
        expect(m.type, MarkerType.gym);
      }
      expect(gyms, isNotEmpty);
    });

    test('query filters by multiple types', () {
      final results = service.query(
        const MarkerFilter(types: {MarkerType.gym, MarkerType.event}),
      );
      for (final m in results) {
        expect(m.type, isIn([MarkerType.gym, MarkerType.event]));
      }
    });

    test('query filters by discipline', () {
      final mmaGyms = service.query(
        const MarkerFilter(types: {MarkerType.gym}, disciplines: {'MMA'}),
      );
      for (final m in mmaGyms) {
        expect(m.disciplines.map((d) => d.toUpperCase()), contains('MMA'));
      }
    });

    test('query filters by gym tier', () {
      final elite = service.query(
        const MarkerFilter(types: {MarkerType.gym}, gymTiers: {GymTier.elite}),
      );
      for (final m in elite) {
        expect(m.gymTier, GymTier.elite);
      }
    });

    test('query filters by event status', () {
      final live = service.query(
        const MarkerFilter(
          types: {MarkerType.event},
          eventStatuses: {EventLiveStatus.live},
        ),
      );
      for (final m in live) {
        expect(m.eventStatus, EventLiveStatus.live);
      }
    });

    test('query filters by campaign kind', () {
      final pinkShield = service.query(
        const MarkerFilter(
          types: {MarkerType.campaign},
          campaignKinds: {CampaignKind.pinkShield},
        ),
      );
      for (final m in pinkShield) {
        expect(m.campaignKind, CampaignKind.pinkShield);
      }
    });

    test('query with bounds filters geographically', () {
      final usWest = service.query(
        const MarkerFilter(
          bounds: MapBounds(
            southLat: 25.0,
            westLng: -130.0,
            northLat: 50.0,
            eastLng: -100.0,
          ),
        ),
      );
      for (final m in usWest) {
        expect(m.coordinate.lat, greaterThanOrEqualTo(25.0));
        expect(m.coordinate.lat, lessThanOrEqualTo(50.0));
        expect(m.coordinate.lng, greaterThanOrEqualTo(-130.0));
        expect(m.coordinate.lng, lessThanOrEqualTo(-100.0));
      }
    });

    test('query with radius filters nearby markers', () {
      final nearby = service.query(
        const MarkerFilter(nearLat: 36.085, nearLng: -115.153, radiusKm: 50.0),
      );
      for (final m in nearby) {
        final dist = MapMarkerService.haversineKm(
          36.085,
          -115.153,
          m.coordinate.lat,
          m.coordinate.lng,
        );
        expect(dist, lessThanOrEqualTo(50.0));
      }
    });

    test('query with searchQuery matches name', () {
      final results = service.query(const MarkerFilter(searchQuery: 'UFC'));
      expect(results, isNotEmpty);
      for (final m in results) {
        final nameOrOrg = '${m.name} ${m.organization ?? ''}'.toUpperCase();
        expect(nameOrOrg, contains('UFC'));
      }
    });

    test('inViewport returns markers within bounds', () {
      const bounds = MapBounds(
        southLat: -50.0,
        westLng: 100.0,
        northLat: 0.0,
        eastLng: 180.0,
      );
      final results = service.inViewport(bounds);
      for (final m in results) {
        expect(bounds.contains(m.coordinate), isTrue);
      }
    });

    test('nearest returns closest markers', () {
      final nearest = service.nearest(36.085, -115.153, limit: 3);
      expect(nearest.length, lessThanOrEqualTo(3));
      if (nearest.length >= 2) {
        final d1 = MapMarkerService.haversineKm(
          36.085,
          -115.153,
          nearest[0].coordinate.lat,
          nearest[0].coordinate.lng,
        );
        final d2 = MapMarkerService.haversineKm(
          36.085,
          -115.153,
          nearest[1].coordinate.lat,
          nearest[1].coordinate.lng,
        );
        expect(d1, lessThanOrEqualTo(d2));
      }
    });

    test('stats returns correct counts', () {
      final stats = service.stats;
      expect(stats['totalMarkers'], service.allMarkers.length);
      expect(stats['gyms'], isA<int>());
      expect(stats['events'], isA<int>());
      expect(stats['campaigns'], isA<int>());
      expect(stats['mentors'], isA<int>());
      expect(
        (stats['gyms'] as int) +
            (stats['events'] as int) +
            (stats['campaigns'] as int) +
            (stats['mentors'] as int),
        stats['totalMarkers'],
      );
    });

    test('upsert adds new marker', () {
      final before = service.allMarkers.length;
      const newMarker = MapMarkerData(
        id: 'test_new_gym',
        name: 'New Test Gym',
        type: MarkerType.gym,
        coordinate: MapCoordinate(lat: 0, lng: 0),
      );
      service.upsert(newMarker);
      expect(service.allMarkers.length, before + 1);
      // Clean up
      service.remove('test_new_gym');
    });

    test('upsert replaces existing marker', () {
      service.upsert(
        const MapMarkerData(
          id: 'test_replace',
          name: 'Original',
          type: MarkerType.gym,
          coordinate: MapCoordinate(lat: 0, lng: 0),
        ),
      );
      final count = service.allMarkers.length;
      service.upsert(
        const MapMarkerData(
          id: 'test_replace',
          name: 'Replaced',
          type: MarkerType.gym,
          coordinate: MapCoordinate(lat: 0, lng: 0),
        ),
      );
      expect(service.allMarkers.length, count);
      final found = service.allMarkers.firstWhere(
        (m) => m.id == 'test_replace',
      );
      expect(found.name, 'Replaced');
      service.remove('test_replace');
    });

    test('remove removes a marker', () {
      service.upsert(
        const MapMarkerData(
          id: 'test_remove',
          name: 'ToRemove',
          type: MarkerType.gym,
          coordinate: MapCoordinate(lat: 0, lng: 0),
        ),
      );
      final before = service.allMarkers.length;
      service.remove('test_remove');
      expect(service.allMarkers.length, before - 1);
    });

    test('setEventLive changes event status', () {
      service.upsert(
        const MapMarkerData(
          id: 'test_event_live',
          name: 'Test Event',
          type: MarkerType.event,
          coordinate: MapCoordinate(lat: 0, lng: 0),
          eventStatus: EventLiveStatus.upcoming,
        ),
      );
      service.setEventLive('test_event_live', EventLiveStatus.live);
      final found = service.allMarkers.firstWhere(
        (m) => m.id == 'test_event_live',
      );
      expect(found.eventStatus, EventLiveStatus.live);
      service.remove('test_event_live');
    });

    test('markerStream emits on changes', () async {
      final emissions = <List<MapMarkerData>>[];
      final sub = service.markerStream.listen(emissions.add);

      service.upsert(
        const MapMarkerData(
          id: 'stream_test',
          name: 'Stream',
          type: MarkerType.gym,
          coordinate: MapCoordinate(lat: 0, lng: 0),
        ),
      );

      // Allow async to propagate
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(emissions, isNotEmpty);

      await sub.cancel();
      service.remove('stream_test');
    });
  });

  group('GeoJSON export', () {
    late MapMarkerService service;

    setUp(() async {
      service = MapMarkerService.instance;
      await service.initialize();
    });

    test('toGeoJson returns valid FeatureCollection JSON', () {
      final json = service.toGeoJson();
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      expect(parsed['type'], 'FeatureCollection');
      expect(parsed['features'], isList);
      expect((parsed['features'] as List).length, service.allMarkers.length);
    });

    test('toGeoJsonMap returns Map with correct structure', () {
      final map = service.toGeoJsonMap();
      expect(map['type'], 'FeatureCollection');
      final features = map['features'] as List;
      for (final f in features) {
        final feature = f as Map<String, dynamic>;
        expect(feature['type'], 'Feature');
        expect(feature['geometry']['type'], 'Point');
        final coords = feature['geometry']['coordinates'] as List;
        expect(coords.length, 2);
      }
    });

    test('toGeoJson with filter returns filtered results', () {
      final json = service.toGeoJson(
        filter: const MarkerFilter(types: {MarkerType.gym}),
      );
      final parsed = jsonDecode(json) as Map<String, dynamic>;
      final features = parsed['features'] as List;
      for (final f in features) {
        expect((f as Map)['properties']['type'], 'gym');
      }
    });
  });

  group('Haversine calculations', () {
    test('haversineKm returns correct distance for known cities', () {
      // NY to LA ~ 3944 km
      final dist = MapMarkerService.haversineKm(
        40.7128,
        -74.0060, // New York
        34.0522,
        -118.2437, // Los Angeles
      );
      expect(dist, closeTo(3944, 50));
    });

    test('haversineMi returns distance in miles', () {
      final km = MapMarkerService.haversineKm(
        40.7128,
        -74.006,
        34.052,
        -118.243,
      );
      final mi = MapMarkerService.haversineMi(
        40.7128,
        -74.006,
        34.052,
        -118.243,
      );
      expect(mi, closeTo(km * 0.621371, 1));
    });

    test('same point returns zero distance', () {
      final dist = MapMarkerService.haversineKm(36.0, -115.0, 36.0, -115.0);
      expect(dist, closeTo(0, 0.001));
    });

    test('antipodal points return ~20000 km', () {
      final dist = MapMarkerService.haversineKm(0, 0, 0, 180);
      expect(dist, closeTo(20015, 20));
    });
  });

  group('MarkerFilter', () {
    test('empty filter matches everything', () {
      final filter = const MarkerFilter();
      expect(filter.types, isEmpty);
      expect(filter.disciplines, isEmpty);
    });

    test('onlyVerified flag works', () async {
      final service = MapMarkerService.instance;
      await service.initialize();
      final verified = service.query(const MarkerFilter(onlyVerified: true));
      for (final m in verified) {
        expect(m.isVerified, isTrue);
      }
    });

    test('onlyLive flag works', () async {
      final service = MapMarkerService.instance;
      await service.initialize();
      final live = service.query(const MarkerFilter(onlyLive: true));
      for (final m in live) {
        expect(m.isLive, isTrue);
      }
    });
  });
}
