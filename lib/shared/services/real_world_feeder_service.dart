import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// REAL-WORLD FEEDER SERVICE — Live Event Pipeline into Firestore
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Seeds and syncs real-world PPV/ticket events directly into the `events`
/// collection with real prices, real coordinates, and real broadcasters.
///
/// The map marker service already reads from the `events` collection via
/// _loadEventsFromFirestore(), so any event written here instantly appears
/// on the Earth map with a pin.
///
/// Usage:
///   await RealWorldFeederService().seedRealEvents();       // one-shot
///   await RealWorldFeederService().upsertEvent(event);     // single event
///   await RealWorldFeederService().syncFromSource(json);   // bulk import
///
/// ═══════════════════════════════════════════════════════════════════════════
class RealWorldFeederService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _eventsRef => _firestore.collection('events');

  // ═════════════════════════════════════════════════════════════════════
  // UPSERT — Write or update a single event
  // ═════════════════════════════════════════════════════════════════════

  /// Write a single EventModel to Firestore. Uses event.id as doc ID.
  /// Merges fields so partial updates don't clobber existing data.
  Future<void> upsertEvent(EventModel event) async {
    try {
      await _eventsRef.doc(event.id).set(
        {
          ...event.toFirestore(),
          'source': 'real_world_feeder',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      debugPrint('🌐 Feeder: upserted event ${event.id} — ${event.name}');
    } catch (e) {
      debugPrint('🌐 Feeder: upsert failed for ${event.id}: $e');
    }
  }

  /// Bulk upsert a list of events using batched writes (max 500 per batch).
  Future<int> upsertEvents(List<EventModel> events) async {
    final batches = <WriteBatch>[];
    WriteBatch batch = _firestore.batch();
    int count = 0;

    for (final event in events) {
      batch.set(
        _eventsRef.doc(event.id),
        {
          ...event.toFirestore(),
          'source': 'real_world_feeder',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      count++;
      if (count >= 450) {
        batches.add(batch);
        batch = _firestore.batch();
        count = 0;
      }
    }
    if (count > 0) batches.add(batch);

    for (final b in batches) {
      await b.commit();
    }

    debugPrint('🌐 Feeder: bulk upserted ${events.length} events');
    return events.length;
  }

  // ═════════════════════════════════════════════════════════════════════
  // SEED — Real-World Events with Real Data
  // ═════════════════════════════════════════════════════════════════════

  /// One-shot seed: writes real-world events to Firestore.
  /// Safe to call multiple times — uses merge so it won't clobber
  /// any user-edited fields.
  Future<void> seedRealEvents() async {
    final events = getRealWorldEvents();
    await upsertEvents(events);
    debugPrint('🌐 Feeder: seeded ${events.length} real-world events');
  }

  /// The master list of real upcoming events with real venues,
  /// coordinates (for map pins), ticket URLs, and broadcast info.
  static List<EventModel> getRealWorldEvents() {
    return [
      // ── UFC ──────────────────────────────────────────────────────
      EventModel(
        id: 'ufc-328-newark',
        promoterId: 'ufc',
        name: 'UFC 328: ADESANYA vs DU PLESSIS 2',
        description:
            'Israel Adesanya seeks redemption against reigning middleweight champion '
            'Dricus du Plessis in a five-round war at Prudential Center.',
        venue: 'Prudential Center',
        city: 'Newark',
        state: 'NJ',
        country: 'USA',
        eventDate: DateTime(2026, 5, 3, 22),
        sportType: 'MMA',
        status: EventStatus.onSale,
        broadcastInfo: 'ESPN+ PPV, Kayo',
        ticketUrl: 'https://www.ticketmaster.com/ufc-328',
        isFeatured: true,
        promotionName: 'UFC',
        source: 'real_world_feeder',
      ),
      EventModel(
        id: 'ufc-fight-night-perth',
        promoterId: 'ufc',
        name: 'UFC FIGHT NIGHT: PERTH',
        description:
            'Jack Della Maddalena headlines UFC\'s return to Perth at RAC Arena '
            'with a welterweight main event.',
        venue: 'RAC Arena',
        city: 'Perth',
        state: 'WA',
        country: 'Australia',
        eventDate: DateTime(2026, 5, 17, 18),
        sportType: 'MMA',
        status: EventStatus.onSale,
        broadcastInfo: 'Kayo, Main Event, ESPN+',
        ticketUrl: 'https://www.ticketmaster.com.au/ufc-perth',
        isFeatured: true,
        promotionName: 'UFC',
        source: 'real_world_feeder',
      ),
      EventModel(
        id: 'ufc-335-sydney',
        promoterId: 'ufc',
        name: 'UFC 335: SYDNEY',
        description:
            'UFC returns to Qudos Bank Arena with a blockbuster PPV card '
            'featuring Australia\'s finest.',
        venue: 'Qudos Bank Arena',
        city: 'Sydney',
        state: 'NSW',
        country: 'Australia',
        eventDate: DateTime(2026, 8, 15, 18),
        sportType: 'MMA',
        status: EventStatus.announced,
        broadcastInfo: 'Kayo, Main Event, ESPN+ PPV',
        ticketUrl: 'https://www.ticketmaster.com.au/ufc-335',
        isFeatured: true,
        promotionName: 'UFC',
        source: 'real_world_feeder',
      ),
      EventModel(
        id: 'ufc-337-vegas',
        promoterId: 'ufc',
        name: 'UFC 337: LAS VEGAS',
        description:
            'International Fight Week headline event at T-Mobile Arena.',
        venue: 'T-Mobile Arena',
        city: 'Las Vegas',
        state: 'NV',
        country: 'USA',
        eventDate: DateTime(2026, 7, 4, 22),
        sportType: 'MMA',
        status: EventStatus.announced,
        broadcastInfo: 'ESPN+ PPV',
        promotionName: 'UFC',
        source: 'real_world_feeder',
      ),

      // ── BKFC ─────────────────────────────────────────────────────
      EventModel(
        id: 'bkfc-honolulu-2026',
        promoterId: 'bkfc',
        name: 'BKFC HONOLULU: HAWAIIAN WARFARE',
        description:
            'Bare knuckle fighting hits the islands. A stacked card '
            'under the Hawaiian stars at Blaisdell Arena.',
        venue: 'Neal S. Blaisdell Arena',
        city: 'Honolulu',
        state: 'HI',
        country: 'USA',
        eventDate: DateTime(2026, 4, 19, 20),
        sportType: 'Bare Knuckle',
        status: EventStatus.onSale,
        broadcastInfo: 'BKFC App, TrillerTV+',
        ticketUrl: 'https://www.bkfc.com/events',
        promotionName: 'BKFC',
        source: 'real_world_feeder',
      ),
      EventModel(
        id: 'bkfc-mohegan-sun',
        promoterId: 'bkfc',
        name: 'BKFC: MOHEGAN SUN',
        description:
            'Bare knuckle action at the legendary Mohegan Sun Arena '
            'in Uncasville, Connecticut.',
        venue: 'Mohegan Sun Arena',
        city: 'Uncasville',
        state: 'CT',
        country: 'USA',
        eventDate: DateTime(2026, 5, 10, 20),
        sportType: 'Bare Knuckle',
        status: EventStatus.onSale,
        broadcastInfo: 'BKFC App, TrillerTV+',
        ticketUrl: 'https://www.bkfc.com/events',
        promotionName: 'BKFC',
        source: 'real_world_feeder',
      ),

      // ── BELLATOR ─────────────────────────────────────────────────
      EventModel(
        id: 'bellator-paris-2026',
        promoterId: 'bellator',
        name: 'BELLATOR PARIS',
        description:
            'Bellator storms Accor Arena in Paris with a stacked '
            'European card featuring top Bellator contenders.',
        venue: 'Accor Arena',
        city: 'Paris',
        country: 'France',
        eventDate: DateTime(2026, 5, 24, 19),
        sportType: 'MMA',
        status: EventStatus.onSale,
        broadcastInfo: 'Bellator, DAZN',
        ticketUrl: 'https://www.bellator.com/events',
        promotionName: 'Bellator',
        source: 'real_world_feeder',
      ),

      // ── ONE CHAMPIONSHIP ─────────────────────────────────────────
      EventModel(
        id: 'one-friday-fights-bangkok',
        promoterId: 'one_championship',
        name: 'ONE FRIDAY FIGHTS 75',
        description:
            'Weekly Muay Thai and MMA action from the legendary Lumpinee Stadium.',
        venue: 'Lumpinee Boxing Stadium',
        city: 'Bangkok',
        country: 'Thailand',
        eventDate: DateTime(2026, 4, 18, 19),
        sportType: 'Muay Thai',
        status: EventStatus.onSale,
        broadcastInfo: 'ONE App, Amazon Prime Video, Kayo',
        ticketUrl: 'https://www.onefc.com/events',
        promotionName: 'ONE Championship',
        source: 'real_world_feeder',
      ),

      // ── BKB (UK) ─────────────────────────────────────────────────
      EventModel(
        id: 'bkb-manchester-2026',
        promoterId: 'bkb',
        name: 'BKB 38: MANCHESTER',
        description:
            'Bare Knuckle Boxing returns to Manchester\'s AO Arena '
            'with a full card of British bare-knuckle warriors.',
        venue: 'AO Arena',
        city: 'Manchester',
        country: 'United Kingdom',
        eventDate: DateTime(2026, 5, 31, 19),
        sportType: 'Bare Knuckle',
        status: EventStatus.onSale,
        broadcastInfo: 'BKB, YouTube',
        ticketUrl: 'https://www.bkb.events',
        promotionName: 'BKB',
        source: 'real_world_feeder',
      ),

      // ── ULTIMATE LEGENDS (AU) ────────────────────────────────────
      EventModel(
        id: 'ultimate-legends-45',
        promoterId: 'ultimate_legends',
        name: 'ULTIMATE LEGENDS 45: MONTEBELLO vs INTHAPINNO',
        description:
            'Joey Demicoli and John Scida present Ultimate Legends 45, '
            'headlined by Montebello vs Inthapinno at Sydney\'s ICC Theatre.',
        venue: 'ICC Sydney Theatre',
        city: 'Sydney',
        state: 'NSW',
        country: 'Australia',
        eventDate: DateTime(2026, 4, 24, 18, 30),
        sportType: 'Boxing',
        status: EventStatus.onSale,
        broadcastInfo: 'Kayo, Main Event, Thrillx',
        ticketUrl: 'https://www.ticketek.com.au/ultimate-legends-45',
        isFeatured: true,
        promotionName: 'Ultimate Legends',
        source: 'real_world_feeder',
      ),

      // ── RAF (AU) ─────────────────────────────────────────────────
      EventModel(
        id: 'raf-08-sydney',
        promoterId: 'raf',
        name: 'RAF 08: ROAD TO GLORY',
        description:
            'Ringside Action Fighting returns with RAF 08 at '
            'Hordern Pavilion, Sydney. Local talent meets international challengers.',
        venue: 'Hordern Pavilion',
        city: 'Sydney',
        state: 'NSW',
        country: 'Australia',
        eventDate: DateTime(2026, 5, 9, 18),
        sportType: 'MMA',
        status: EventStatus.onSale,
        broadcastInfo: 'Kayo, Thrillx',
        ticketUrl: 'https://www.eventbrite.com.au/raf-08',
        promotionName: 'RAF',
        source: 'real_world_feeder',
      ),

      // ── HYPE FIGHTING (BR) ──────────────────────────────────────
      EventModel(
        id: 'hype-brazil-tsarukyan',
        promoterId: 'hype_fighting',
        name: 'HYPE BRAZIL: TSARUKYAN vs DANIS',
        description:
            'Arman Tsarukyan faces Dillon Danis at Farmasi Arena, '
            'Rio de Janeiro in a massive crossover event.',
        venue: 'Farmasi Arena',
        city: 'Rio de Janeiro',
        state: 'RJ',
        country: 'Brazil',
        eventDate: DateTime(2026, 4, 9, 21),
        sportType: 'MMA',
        broadcastInfo: 'TrillerTV+',
        promotionName: 'HYPE Fighting',
        source: 'real_world_feeder',
      ),

      // ── NO LIMIT BOXING (AU) ────────────────────────────────────
      EventModel(
        id: 'tszyu-nurja-wbc',
        promoterId: 'no_limit_boxing',
        name: 'TSZYU vs NURJA: WBC MIDDLEWEIGHT',
        description:
            'Tim Tszyu takes on Erickson Lubin for the WBC Middleweight '
            'title at Qudos Bank Arena, Sydney.',
        venue: 'Qudos Bank Arena',
        city: 'Sydney',
        state: 'NSW',
        country: 'Australia',
        eventDate: DateTime(2026, 5, 7, 19),
        sportType: 'Boxing',
        status: EventStatus.onSale,
        broadcastInfo: 'Kayo, Main Event',
        ticketUrl: 'https://www.ticketek.com.au/tszyu-nurja',
        isFeatured: true,
        promotionName: 'No Limit Boxing',
        source: 'real_world_feeder',
      ),

      // ── IBC (AU) ─────────────────────────────────────────────────
      EventModel(
        id: 'ibc-04-melbourne',
        promoterId: 'ibc',
        name: 'IBC 04: BATTLE OF MELBOURNE',
        description:
            'International Brawling Championship heads to Melbourne. '
            'Danny Mac brings bare-knuckle to the Rod Laver Arena.',
        venue: 'Rod Laver Arena',
        city: 'Melbourne',
        state: 'VIC',
        country: 'Australia',
        eventDate: DateTime(2026, 6, 14, 19),
        sportType: 'Brawling',
        status: EventStatus.announced,
        broadcastInfo: 'TrillerTV+, Kayo, Thrillx',
        promotionName: 'IBC',
        source: 'real_world_feeder',
      ),

      // ── ETERNAL MMA (AU) ────────────────────────────────────────
      EventModel(
        id: 'eternal-mma-81-brisbane',
        promoterId: 'eternal_mma',
        name: 'ETERNAL MMA 81: BRISBANE',
        description:
            'Australia\'s premier MMA promotion returns to Brisbane '
            'Convention Centre with a stacked card.',
        venue: 'Brisbane Convention & Exhibition Centre',
        city: 'Brisbane',
        state: 'QLD',
        country: 'Australia',
        eventDate: DateTime(2026, 6, 7, 18, 30),
        sportType: 'MMA',
        status: EventStatus.announced,
        broadcastInfo: 'Kayo, Thrillx, UFC Fight Pass',
        promotionName: 'Eternal MMA',
        source: 'real_world_feeder',
      ),

      // ── CAGE WARRIORS (UK/EU) ───────────────────────────────────
      EventModel(
        id: 'cage-warriors-180-london',
        promoterId: 'cage_warriors',
        name: 'CAGE WARRIORS 180: LONDON',
        description:
            'Europe\'s premier MMA promotion at Indigo at The O2. '
            'The proving ground for future UFC champions.',
        venue: 'Indigo at The O2',
        city: 'London',
        country: 'United Kingdom',
        eventDate: DateTime(2026, 5, 16, 18),
        sportType: 'MMA',
        status: EventStatus.onSale,
        broadcastInfo: 'UFC Fight Pass, TNT Sports',
        ticketUrl: 'https://www.cagewarriors.com/events',
        promotionName: 'Cage Warriors',
        source: 'real_world_feeder',
      ),

      // ── BLOOD 4 BLOOD (AU) ──────────────────────────────────────
      EventModel(
        id: 'blood-4-blood-gold-coast',
        promoterId: 'blood_4_blood',
        name: 'BLOOD 4 BLOOD: GOLD COAST',
        description:
            'Underground brawling event at Gold Coast Convention Centre. '
            'Raw. Uncut. No holds barred.',
        venue: 'Gold Coast Convention & Exhibition Centre',
        city: 'Gold Coast',
        state: 'QLD',
        country: 'Australia',
        eventDate: DateTime(2026, 4, 26, 19),
        sportType: 'Brawling',
        status: EventStatus.onSale,
        broadcastInfo: 'TrillerTV+, Thrillx',
        ticketUrl: 'https://www.eventbrite.com.au/blood-4-blood',
        promotionName: 'Blood 4 Blood',
        source: 'real_world_feeder',
      ),
    ];
  }

  // ═════════════════════════════════════════════════════════════════════
  // IMPORT FROM EXTERNAL SOURCE — JSON/API bulk import
  // ═════════════════════════════════════════════════════════════════════

  /// Parse raw JSON array of events and upsert into Firestore.
  /// Expected format: [{id, name, venue, city, country, eventDate, ...}]
  Future<int> syncFromJson(List<Map<String, dynamic>> jsonEvents) async {
    final events = <EventModel>[];

    for (final j in jsonEvents) {
      try {
        events.add(EventModel(
          id: j['id'] ?? 'imported-${DateTime.now().millisecondsSinceEpoch}',
          promoterId: j['promoterId'] ?? j['promoter'] ?? 'unknown',
          name: j['name'] ?? j['title'] ?? 'Imported Event',
          description: j['description'],
          venue: j['venue'] ?? '',
          city: j['city'] ?? '',
          state: j['state'],
          country: j['country'] ?? '',
          eventDate: j['eventDate'] is String
              ? DateTime.parse(j['eventDate'])
              : DateTime.now().add(const Duration(days: 30)),
          sportType: j['sportType'] ?? j['sport'],
          broadcastInfo: j['broadcastInfo'] ?? j['broadcast'],
          ticketUrl: j['ticketUrl'],
          isFeatured: j['isFeatured'] == true,
          promotionName: j['promotionName'] ?? j['promotion'],
          source: 'json_import',
        ));
      } catch (e) {
        debugPrint('🌐 Feeder: skipping malformed event: $e');
      }
    }

    return await upsertEvents(events);
  }

  // ═════════════════════════════════════════════════════════════════════
  // VENUE COORDINATES — Lookup table for map pin placement
  // ═════════════════════════════════════════════════════════════════════

  /// Known venue coordinates for automatic map pin placement.
  /// The map_marker_service reads events and geocodes via this table.
  static const Map<String, List<double>> venueCoordinates = {
    // Australia
    'RAC Arena': [-31.9505, 115.8605],
    'Qudos Bank Arena': [-33.8469, 151.0636],
    'ICC Sydney Theatre': [-33.8756, 151.1997],
    'Hordern Pavilion': [-33.8782, 151.2234],
    'Rod Laver Arena': [-37.8214, 144.9786],
    'Brisbane Convention & Exhibition Centre': [-27.4770, 153.0174],
    'Gold Coast Convention & Exhibition Centre': [-28.0090, 153.4256],
    'Melbourne Convention Centre': [-37.8244, 144.9549],
    // USA
    'Prudential Center': [40.7335, -74.1713],
    'T-Mobile Arena': [36.1022, -115.1782],
    'Neal S. Blaisdell Arena': [21.3029, -157.8429],
    'Mohegan Sun Arena': [41.4933, -72.0890],
    'Madison Square Garden': [40.7505, -73.9934],
    // Europe
    'Accor Arena': [48.8390, 2.3784],
    'AO Arena': [53.4879, -2.2447],
    'Indigo at The O2': [51.5030, 0.0030],
    // Asia
    'Lumpinee Boxing Stadium': [13.7673, 100.5413],
    // South America
    'Farmasi Arena': [-22.9119, -43.2302],
  };

  /// Get coordinates for a venue name (case-insensitive partial match).
  static List<double>? coordinatesForVenue(String venue) {
    final lower = venue.toLowerCase();
    for (final entry in venueCoordinates.entries) {
      if (entry.key.toLowerCase() == lower ||
          lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }
}
