import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../shared/widgets/dfc_network_image.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_url_sanitizer.dart';
import '../../../shared/models/event_model.dart';
import '../../../shared/models/fight_model.dart';
import '../../../shared/services/event_service.dart';

class EventDetailsScreen extends StatefulWidget {
final String eventId;
final EventModel? initialEvent;

const EventDetailsScreen({super.key, required this.eventId, this.initialEvent});

@override
State<EventDetailsScreen> createState() => \_EventDetailsScreenState();
}

class \_EventDetailsScreenState extends State<EventDetailsScreen> {
EventModel? \_event;
late TextEditingController \_eventNameController;
bool \_isEditingName = false;
List<FightModel>? \_fightCard;
bool \_isLoading = true;
final ImagePicker \_picker = ImagePicker();
bool \_isUploadingPoster = false;

String \_safePoster(String? raw) {
final sanitized = ImageUrlSanitizer.sanitize(
raw,
fallback: ImageAssets.eventPlaceholder,
);
// If it's still the generic badge, pick a sport-specific poster instead
if (sanitized == ImageAssets.dfcBrandedPlaceholder) {
return ImageAssets.posterForSport(\_event?.sportType);
}
return sanitized;
}

@override
void initState() {
super.initState();
\_eventNameController = TextEditingController();
\_loadEvent();
}

@override
void dispose() {
\_eventNameController.dispose();
super.dispose();
}

/// Load event + fight card — Firestore first, demo fallback
void \_loadEvent() async {
final eid = widget.eventId;

    // ── Try Firestore first ──────────────────────────────────────
    try {
      final svc = EventService();
      final firestoreEvent = await svc.getEvent(eid);
      if (firestoreEvent != null) {
        final fightCard = await svc.getEventFightCard(eid);
        if (mounted) {
          setState(() {
            _event = firestoreEvent;
            _eventNameController.text = firestoreEvent.name;
            _fightCard = fightCard;
            _isLoading = false;
          });
        }
        return;
      }
    } catch (_) {
      // Fall through to demo data
    }

    // ── Demo fallback ────────────────────────────────────────────
    final now = DateTime.now();

    // Helper to create fight entries concisely
    FightModel bout(
      String eventId,
      String f1,
      String f2,
      String wc,
      int rds,
      int pos, {
      bool main = false,
      bool coMain = false,
      bool title = false,
      String? titleName,
    }) {
      return FightModel(
        id: '${eventId}_bout_$pos',
        eventId: eventId,
        fighter1Id: f1,
        fighter2Id: f2,
        weightClass: wc,
        scheduledRounds: rds,
        isMainEvent: main,
        isCoMainEvent: coMain,
        isTitleFight: title,
        titleOnTheLine: titleName,
        cardPosition: pos,
        createdAt: now,
        updatedAt: now,
      );
    }

    // ── Demo events (mirrors events_screen demo lists) ────────────
    final demoEvents = <String, EventModel>{
      'demo-ufc-313': EventModel(
        id: 'demo-ufc-313',
        promoterId: 'ufc',
        name: 'UFC 313: Santos vs Aliyev',
        venue: 'T-Mobile Arena',
        city: 'Las Vegas',
        country: 'USA',
        eventDate: now.add(const Duration(days: 8)),
        mainCardTime: now.add(const Duration(days: 8, hours: 22)),
        sportType: 'mma',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'ESPN+ PPV',
        fightIds: [],
        ticketUrl: 'https://www.ufc.com/events',
        posterUrl: ImageAssets.posterForSport('mma'),
      ),
      'demo-one-170': EventModel(
        id: 'demo-one-170',
        promoterId: 'one',
        name: 'ONE 170: Superlek vs Takeru',
        venue: 'Impact Arena',
        city: 'Bangkok',
        country: 'Thailand',
        eventDate: now.add(const Duration(days: 15)),
        sportType: 'muay thai',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'Amazon Prime',
        fightIds: [],
        ticketUrl: 'https://www.onefc.com/events',
        posterUrl: ImageAssets.posterForSport('muay thai'),
      ),
      'demo-pfl-9': EventModel(
        id: 'demo-pfl-9',
        promoterId: 'pfl',
        name: 'PFL 9: 2025 Playoffs — Semifinals',
        venue: 'Copper Box Arena',
        city: 'London',
        country: 'UK',
        eventDate: now.add(const Duration(days: 22)),
        sportType: 'mma',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'ESPN',
        fightIds: [],
        ticketUrl: 'https://www.pflmma.com/events',
        posterUrl: ImageAssets.posterForSport('mma'),
      ),
      'demo-bkfc-62': EventModel(
        id: 'demo-bkfc-62',
        promoterId: 'bkfc',
        name: 'BKFC 62: Knucklemania IV',
        venue: 'Seminole Hard Rock',
        city: 'Hollywood',
        country: 'USA',
        eventDate: now,
        sportType: 'bkfc',
        status: EventStatus.live,
        broadcastInfo: 'BKFC App',
        fightIds: [],
        ticketUrl: 'https://www.bareknuckle.tv',
        posterUrl: ImageAssets.posterForSport('bkfc'),
      ),
      'demo-ufc-fn': EventModel(
        id: 'demo-ufc-fn',
        promoterId: 'ufc',
        name: 'UFC Fight Night: Moreno vs Royval 3',
        venue: 'UFC APEX',
        city: 'Las Vegas',
        country: 'USA',
        eventDate: now,
        sportType: 'mma',
        status: EventStatus.live,
        broadcastInfo: 'ESPN+',
        fightIds: [],
        ticketUrl: 'https://www.ufc.com/events',
        posterUrl: ImageAssets.posterForSport('mma'),
      ),
      'demo-glory-92': EventModel(
        id: 'demo-glory-92',
        promoterId: 'glory',
        name: 'GLORY 92: Collision',
        venue: 'Gelredome',
        city: 'Arnhem',
        country: 'Netherlands',
        eventDate: now.add(const Duration(days: 3)),
        sportType: 'kickboxing',
        status: EventStatus.upcoming,
        broadcastInfo: 'GLORY.tv',
        fightIds: [],
        ticketUrl: 'https://www.glorykickboxing.com/events',
        posterUrl: ImageAssets.posterForSport('kickboxing'),
      ),
      'demo-ufc-fn-2': EventModel(
        id: 'demo-ufc-fn-2',
        promoterId: 'ufc',
        name: 'UFC Fight Night: Allen vs Daukaus',
        venue: 'O2 Arena',
        city: 'London',
        country: 'UK',
        eventDate: now.add(const Duration(days: 5)),
        sportType: 'mma',
        status: EventStatus.upcoming,
        broadcastInfo: 'ESPN+',
        fightIds: [],
        ticketUrl: 'https://www.ufc.com/events',
        posterUrl: ImageAssets.posterForSport('mma'),
      ),
      'demo-bkfc-63': EventModel(
        id: 'demo-bkfc-63',
        promoterId: 'bkfc',
        name: 'BKFC Fight Night: Tampa',
        venue: 'Amalie Arena',
        city: 'Tampa',
        country: 'USA',
        eventDate: now.add(const Duration(days: 7)),
        sportType: 'bkfc',
        status: EventStatus.upcoming,
        broadcastInfo: 'BKFC App',
        fightIds: [],
        ticketUrl: 'https://www.bareknuckle.tv',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'demo-boxing-1': EventModel(
        id: 'demo-boxing-1',
        promoterId: 'matchroom',
        name: 'Matchroom: Kozlov vs Volkov 2',
        venue: 'Kingdom Arena',
        city: 'Riyadh',
        country: 'Saudi Arabia',
        eventDate: now.add(const Duration(days: 12)),
        sportType: 'boxing',
        status: EventStatus.upcoming,
        broadcastInfo: 'DAZN',
        fightIds: [],
        ticketUrl: 'https://www.dazn.com',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'demo-wwe-1': EventModel(
        id: 'demo-wwe-1',
        promoterId: 'wwe',
        name: 'WWE Money in the Bank 2025',
        venue: 'Intuit Dome',
        city: 'Los Angeles',
        country: 'USA',
        eventDate: now.add(const Duration(days: 18)),
        sportType: 'pro wrestling',
        status: EventStatus.upcoming,
        broadcastInfo: 'Peacock',
        fightIds: [],
        ticketUrl: 'https://www.wwe.com/events',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'demo-mt-1': EventModel(
        id: 'demo-mt-1',
        promoterId: 'rajadamnern',
        name: 'Rajadamnern World Series: Grand Prix',
        venue: 'Rajadamnern Stadium',
        city: 'Bangkok',
        country: 'Thailand',
        eventDate: now.add(const Duration(days: 10)),
        sportType: 'muay thai',
        status: EventStatus.upcoming,
        broadcastInfo: 'YouTube',
        fightIds: [],
        ticketUrl: 'https://rajadamnern.com',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'demo-pfl-10': EventModel(
        id: 'demo-pfl-10',
        promoterId: 'pfl',
        name: 'PFL 10: 2025 Championship Finals',
        venue: 'Madison Square Garden',
        city: 'New York',
        country: 'USA',
        eventDate: now.add(const Duration(days: 30)),
        sportType: 'mma',
        status: EventStatus.upcoming,
        broadcastInfo: 'ESPN',
        fightIds: [],
        ticketUrl: 'https://www.pflmma.com/events',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'demo-kb-1': EventModel(
        id: 'demo-kb-1',
        promoterId: 'k1',
        name: 'K-1 World Grand Prix 2025: Quarter Finals',
        venue: 'Saitama Super Arena',
        city: 'Saitama',
        country: 'Japan',
        eventDate: now.add(const Duration(days: 25)),
        sportType: 'kickboxing',
        status: EventStatus.upcoming,
        broadcastInfo: 'ABEMA',
        fightIds: [],
        ticketUrl: 'https://www.k-1.co.jp/en/',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'ibc-03-gold-coast': EventModel(
        id: 'ibc-03-gold-coast',
        promoterId: 'ibc',
        name: 'IBC 03: International Brawling Championship',
        description:
            'The International Brawling Championship returns for IBC III at the Gold Coast Sports & Leisure Centre. Closed-fist hybrid format — no grappling, standing 8-count, all action. Created by Gold Coast entrepreneur Danny Mac. Main Event: Jay Cutler vs Luke Modini for the Light Heavyweight Title. Co-Main: Isaac Hardman vs Jonathan Tuhu for the IBC Championship. 11 bouts. Live on Main Event, Kayo Sports & TrillerTV+.',
        venue: 'Gold Coast Sports & Leisure Centre',
        city: 'Gold Coast',
        country: 'Australia',
        eventDate: DateTime(2026, 3, 7, 19, 0),
        mainCardTime: DateTime(2026, 3, 7, 19, 0),
        sportType: 'brawling',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'Main Event / Kayo Sports / TrillerTV+ PPV',
        fightIds: [],
        ticketUrl: 'https://www.internationalbrawling.com',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'ufc-perth-2026': EventModel(
        id: 'ufc-perth-2026',
        promoterId: 'ufc',
        name: 'UFC Fight Night: Della Maddalena vs Prates',
        description:
            'First-ever UFC Fight Night in Perth. Western Australia\'s Jack Della Maddalena headlines against Carlos "The Nightmare" Prates at RAC Arena.',
        venue: 'RAC Arena',
        city: 'Perth',
        country: 'Australia',
        eventDate: now.add(const Duration(days: 57)),
        mainCardTime: now.add(const Duration(days: 57, hours: 20)),
        sportType: 'mma',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'ESPN+ / Kayo Sports',
        fightIds: [],
        ticketUrl: 'https://www.ufc.com/perth',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'eternal-mma-perth-80': EventModel(
        id: 'eternal-mma-perth-80',
        promoterId: 'eternal',
        name: 'Eternal MMA 80: Perth',
        description:
            'Australia\'s premier MMA promotion brings a stacked 16-fight card to Perth featuring WA vs QLD superfight series.',
        venue: 'HBF Stadium',
        city: 'Perth',
        country: 'Australia',
        eventDate: now.add(const Duration(days: 44)),
        mainCardTime: now.add(const Duration(days: 44, hours: 19)),
        sportType: 'mma',
        status: EventStatus.upcoming,
        broadcastInfo: 'UFC Fight Pass',
        fightIds: [],
        ticketUrl: 'https://eternalmma.com',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      'empire-fight-series-5': EventModel(
        id: 'empire-fight-series-5',
        promoterId: 'empire',
        name: 'Empire Fight Series: Inception 5',
        description:
            'WA vs QLD national Muay Thai showdown. Cian Lougheed (WA) vs Jaga Chan headlines the biggest domestic fight of the year.',
        venue: 'Claremont Showground',
        city: 'Perth',
        country: 'Australia',
        eventDate: now.add(const Duration(days: 100)),
        mainCardTime: now.add(const Duration(days: 100, hours: 18)),
        sportType: 'muay thai',
        status: EventStatus.upcoming,
        broadcastInfo: 'PPV',
        fightIds: [],
        ticketUrl: 'https://claremontshowground.com.au',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      // ── Ultimate Legends — WBC Silver Australian Title (source: ultimatelegends.com.au) ──
      'ultimate-legends-apr-2026': EventModel(
        id: 'ultimate-legends-apr-2026',
        promoterId: 'ultimate-legends',
        name: 'Ultimate Legends Fight Night: WBC Silver Australian Title',
        description:
            'Melbourne\'s premier combat sports event — 30+ years strong! WBC Silver Australian Title headlines a stacked card of professional Boxing, K1, Kickboxing & Muay Thai. Founded by John Scida (5th Degree Black Belt, Zen Do Kai) in 1992 and co-promoted by Joey Demicoli. Main Event: Jordan Roesler — WBC Silver Australian Title. Father James Roesler in the corner. A father-and-son legacy built through Ultimate Legends. Livestream via Live Combat Sports. Sponsored by Palmerbet.',
        venue: 'Melbourne Pavilion',
        city: 'Melbourne',
        country: 'Australia',
        eventDate: DateTime(2026, 4, 24, 18, 0),
        mainCardTime: DateTime(2026, 4, 24, 19, 0),
        sportType: 'boxing',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'Live Combat Sports / Livestream',
        fightIds: [],
        ticketUrl: 'https://www.ultimatelegends.com.au/contact',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
      // ── BKFC Fight Night Australia — Townsville (HEPI EDITION) ────────
      'demo_event_15': EventModel(
        id: 'demo_event_15',
        promoterId: 'bkfc_promotions',
        name: 'BKFC Fight Night Australia — Townsville Debut',
        description:
            'HEPI EDITION — From Logan\'s Islander Heart to Townsville\'s Bare-Knuckle Spotlight. '
            'MAIN EVENT: Haze "The Huntsman" Hepi (3-1) vs Krzysztof "The Big Man" Wisniewski (3-0) — Heavyweight Rematch. '
            'Rematch from BKFC 83 Rome. Doctor stoppage R3 last time. Both demanded the rematch. '
            'ALSO: Mark "Bam Bam" Flanagan (24-7, 17KOs boxing) bare-knuckle debut. '
            'Former WBA cruiserweight title challenger. '
            '"We\'re thrilled to announce our first show in the fighting rich country of Australia" — David Feldman, BKFC President.',
        venue: 'Townsville Entertainment and Convention Centre',
        city: 'Townsville',
        state: 'Queensland',
        country: 'Australia',
        eventDate: DateTime(2026, 4, 18, 19, 0),
        mainCardTime: DateTime(2026, 4, 18, 19, 0),
        sportType: 'bkfc',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'BKFC App / DFC FightPipe PPV',
        fightIds: [],
        ticketUrl: 'https://bfranchise.com',
        posterUrl: ImageAssets.posterForSport('bkfc'),
      ),
      // ── Legends Fight Show 45 — Margaret Court Arena, Melbourne ──────
      'demo_event_1': EventModel(
        id: 'demo_event_1',
        promoterId: 'legends_fight_show',
        name: 'Legends Fight Show 45',
        description:
            'Victorian MMA Championships - Main Card. Melbourne\u2019s premier regional MMA showcase returns to Margaret Court Arena with a stacked card of local and national talent.',
        venue: 'Margaret Court Arena',
        city: 'Melbourne',
        state: 'Victoria',
        country: 'Australia',
        eventDate: DateTime(2026, 3, 25, 0, 39),
        mainCardTime: DateTime(2026, 3, 25, 0, 39),
        sportType: 'mma',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'Kayo Sports',
        fightIds: [],
        ticketUrl: 'https://ticketek.com.au',
        posterUrl: ImageAssets.posterForSport('mma'),
      ),
      // ── RIZIN 52 — Saitama Super Arena ────────────────────────────────
      'demo-rizin-52': EventModel(
        id: 'demo-rizin-52',
        promoterId: 'rizin',
        name: 'RIZIN 52: Super Arena',
        description:
            'RIZIN Fighting Federation returns to the legendary Saitama Super Arena for RIZIN 52 — Japan\'s biggest MMA event of 2026. Championship bouts, cross-promotional superfights, and the electric Saitama atmosphere. The spirit of PRIDE lives on. #RIZIN52',
        venue: 'Saitama Super Arena',
        city: 'Saitama',
        country: 'Japan',
        eventDate: DateTime(2026, 4, 29, 17, 0),
        mainCardTime: DateTime(2026, 4, 29, 19, 0),
        sportType: 'mma',
        status: EventStatus.upcoming,
        isFeatured: true,
        broadcastInfo: 'U-NEXT / ABEMA / RIZIN LIVE',
        fightIds: [],
        ticketUrl: 'https://www.rizinff.com',
        posterUrl: 'assets/logos/dfc_hex_badge.png',
      ),
    };

    // ── Demo fight cards — real bout lineups per event ────────────
    final demoCards = <String, List<FightModel>>{
      'demo-ufc-313': [
        bout(
          'demo-ufc-313',
          'Alex Pereira',
          'Magomed Ankalaev',
          'Light Heavyweight',
          5,
          0,
          main: true,
          title: true,
          titleName: 'UFC Light Heavyweight Title',
        ),
        bout(
          'demo-ufc-313',
          'Jailton Almeida',
          'Derrick Lewis',
          'Heavyweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-ufc-313',
          'Justin Gaethje',
          'Nathan Cross',
          'Lightweight',
          3,
          2,
        ),
        bout('demo-ufc-313', 'Bo Nickal', 'Paul Craig', 'Middleweight', 3, 3),
        bout(
          'demo-ufc-313',
          'Raoni Barcelos',
          'Cristian Quinonez',
          'Bantamweight',
          3,
          4,
        ),
      ],
      'demo-one-170': [
        bout(
          'demo-one-170',
          'Superlek',
          'Takeru',
          'Flyweight',
          5,
          0,
          main: true,
          title: true,
          titleName: 'ONE Kickboxing Flyweight Title',
        ),
        bout(
          'demo-one-170',
          'Apichai',
          'Jo Nattawut',
          'Featherweight',
          5,
          1,
          coMain: true,
          title: true,
          titleName: 'ONE Muay Thai Featherweight Title',
        ),
        bout(
          'demo-one-170',
          'Somsak Kiatmook',
          'Jacob Smith',
          'Flyweight',
          3,
          2,
        ),
        bout(
          'demo-one-170',
          'Stamp Fairtex',
          'Denice Zamboanga',
          'Atomweight',
          3,
          3,
        ),
        bout(
          'demo-one-170',
          'Nong-O Hama',
          'Alaverdi Ramazanov',
          'Bantamweight',
          3,
          4,
        ),
      ],
      'demo-pfl-9': [
        bout(
          'demo-pfl-9',
          'Brendan Loughnane',
          'Bubba Jenkins',
          'Featherweight',
          3,
          0,
          main: true,
        ),
        bout(
          'demo-pfl-9',
          'Sadibou Sy',
          'Magomed Magomedkerimov',
          'Welterweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-pfl-9',
          'Dakota Ditcheva',
          'Taila Santos',
          'Flyweight',
          3,
          2,
        ),
        bout('demo-pfl-9', 'Aspen Ladd', 'Julia Budd', 'Featherweight', 3, 3),
      ],
      'demo-bkfc-62': [
        bout(
          'demo-bkfc-62',
          'Mike Perry',
          'Luke Rockhold',
          'Middleweight',
          5,
          0,
          main: true,
        ),
        bout(
          'demo-bkfc-62',
          'Christine Ferea',
          'Bec Rawlings',
          'Flyweight',
          5,
          1,
          coMain: true,
        ),
        bout(
          'demo-bkfc-62',
          'Lorenzo Hunt',
          'Bobo O\'Brien',
          'Heavyweight',
          5,
          2,
        ),
        bout(
          'demo-bkfc-62',
          'Howard Davis',
          'Travis Thompson',
          'Welterweight',
          5,
          3,
        ),
      ],
      'demo-ufc-fn': [
        bout(
          'demo-ufc-fn',
          'Brandon Moreno',
          'Brandon Royval',
          'Flyweight',
          5,
          0,
          main: true,
        ),
        bout(
          'demo-ufc-fn',
          'Cub Swanson',
          'Bill Algeo',
          'Featherweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-ufc-fn',
          'Alonzo Menifield',
          'Dustin Jacoby',
          'Light Heavyweight',
          3,
          2,
        ),
        bout('demo-ufc-fn', 'Andrea Lee', 'Viviane Araujo', 'Flyweight', 3, 3),
      ],
      'demo-glory-92': [
        bout(
          'demo-glory-92',
          'Rico Verhoeven',
          'Jamal Ben Saddik',
          'Heavyweight',
          5,
          0,
          main: true,
          title: true,
          titleName: 'GLORY Heavyweight Title',
        ),
        bout(
          'demo-glory-92',
          'Donegi Abena',
          'Sergej Maslobojev',
          'Light Heavyweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-glory-92',
          'Endy Semeleer',
          'Murthel Groenhart',
          'Welterweight',
          3,
          2,
        ),
        bout(
          'demo-glory-92',
          'Tiffany van Soest',
          'Anissa Meksen',
          'Super Bantamweight',
          3,
          3,
        ),
      ],
      'demo-ufc-fn-2': [
        bout(
          'demo-ufc-fn-2',
          'Brendan Allen',
          'Chris Daukaus',
          'Middleweight',
          5,
          0,
          main: true,
        ),
        bout(
          'demo-ufc-fn-2',
          'Paddy Pimblett',
          'Bobby Green',
          'Lightweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-ufc-fn-2',
          'Molly McCann',
          'Hannah Goldy',
          'Flyweight',
          3,
          2,
        ),
        bout(
          'demo-ufc-fn-2',
          'Jack Shore',
          'Ricky Simon',
          'Bantamweight',
          3,
          3,
        ),
      ],
      'demo-bkfc-63': [
        bout(
          'demo-bkfc-63',
          'David Mundell',
          'Chase Sherman',
          'Heavyweight',
          5,
          0,
          main: true,
        ),
        bout(
          'demo-bkfc-63',
          'Kai Stewart',
          'Tyler Goodjohn',
          'Welterweight',
          5,
          1,
          coMain: true,
        ),
        bout(
          'demo-bkfc-63',
          'Taylor Starling',
          'Charisa Sigala',
          'Flyweight',
          5,
          2,
        ),
      ],
      'demo-boxing-1': [
        bout(
          'demo-boxing-1',
          'Sergei Kozlov',
          'Artem Volkov',
          'Light Heavyweight',
          12,
          0,
          main: true,
          title: true,
          titleName: 'Undisputed Light Heavyweight Title',
        ),
        bout(
          'demo-boxing-1',
          'Vergil Ortiz Jr',
          'Eimantas Stanionis',
          'Welterweight',
          12,
          1,
          coMain: true,
        ),
        bout(
          'demo-boxing-1',
          'Jesse Rodriguez',
          'Juan Francisco Estrada',
          'Super Flyweight',
          12,
          2,
          title: true,
          titleName: 'WBC Super Flyweight Title',
        ),
        bout(
          'demo-boxing-1',
          'Conor Benn',
          'Chris Eubank Jr',
          'Middleweight',
          12,
          3,
        ),
      ],
      'demo-wwe-1': [
        bout(
          'demo-wwe-1',
          'Cody Rhodes',
          'Gunther',
          'Universal Championship',
          1,
          0,
          main: true,
          title: true,
          titleName: 'Undisputed WWE Title',
        ),
        bout(
          'demo-wwe-1',
          'Men\'s MITB Ladder Match',
          '8-Man Ladder',
          'Ladder Match',
          1,
          1,
          coMain: true,
        ),
        bout(
          'demo-wwe-1',
          'Women\'s MITB Ladder Match',
          '8-Woman Ladder',
          'Ladder Match',
          1,
          2,
        ),
        bout(
          'demo-wwe-1',
          'Rhea Ripley',
          'Liv Morgan',
          'Women\'s World Title',
          1,
          3,
          title: true,
          titleName: 'Women\'s World Championship',
        ),
      ],
      'demo-mt-1': [
        bout(
          'demo-mt-1',
          'Saenchai',
          'Petchmorakot',
          'Featherweight',
          5,
          0,
          main: true,
        ),
        bout(
          'demo-mt-1',
          'Buakaw Banchamek',
          'Yodsanklai Fairtex',
          'Welterweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-mt-1',
          'Nong-O Gaiyanghadao',
          'Sangmanee',
          'Bantamweight',
          5,
          2,
        ),
        bout(
          'demo-mt-1',
          'Kulabdam',
          'Seksan Or Kwanmuang',
          'Bantamweight',
          5,
          3,
        ),
      ],
      'demo-pfl-10': [
        bout(
          'demo-pfl-10',
          'Brendan Loughnane',
          'Movlid Khaybulaev',
          'Featherweight',
          5,
          0,
          main: true,
          title: true,
          titleName: 'PFL Featherweight Championship',
        ),
        bout(
          'demo-pfl-10',
          'Sadibou Sy',
          'Magomed Magomedkerimov',
          'Welterweight',
          5,
          1,
          coMain: true,
          title: true,
          titleName: 'PFL Welterweight Championship',
        ),
        bout(
          'demo-pfl-10',
          'Dakota Ditcheva',
          'Larissa Pacheco',
          'Lightweight',
          5,
          2,
          title: true,
          titleName: 'PFL Women\'s Lightweight Championship',
        ),
        bout(
          'demo-pfl-10',
          'Impa Kasanganay',
          'Biaggio Ali Walsh',
          'Light Heavyweight',
          5,
          3,
          title: true,
          titleName: 'PFL Light Heavyweight Championship',
        ),
      ],
      'demo-kb-1': [
        bout(
          'demo-kb-1',
          'Takeru Segawa',
          'Leona Pettas',
          'Super Bantamweight',
          3,
          0,
          main: true,
        ),
        bout(
          'demo-kb-1',
          'Wei Rui',
          'Masaaki Noiri',
          'Super Lightweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-kb-1',
          'Gonnapar Weerachaiyo',
          'Yuto Shinohara',
          'Super Featherweight',
          3,
          2,
        ),
        bout(
          'demo-kb-1',
          'Jordan Pikeur',
          'Moto Konishi',
          'Super Middleweight',
          3,
          3,
        ),
      ],
      'ufc-perth-2026': [
        bout(
          'ufc-perth-2026',
          'Jack Della Maddalena',
          'Carlos Prates',
          'Welterweight',
          5,
          0,
          main: true,
        ),
        bout(
          'ufc-perth-2026',
          'Tyson Pedro',
          'Jimmy Crute',
          'Light Heavyweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'ufc-perth-2026',
          'Casey O\'Neill',
          'Luana Santos',
          'Flyweight',
          3,
          2,
        ),
        bout(
          'ufc-perth-2026',
          'Steve Erceg',
          'Kai Kara-France',
          'Flyweight',
          3,
          3,
        ),
        bout(
          'ufc-perth-2026',
          'Shannon Ross',
          'Quillan Salkilld',
          'Bantamweight',
          3,
          4,
        ),
      ],
      'eternal-mma-perth-80': [
        bout(
          'eternal-mma-perth-80',
          'Kyle Redfern',
          'Mitch Ramirez',
          'Welterweight',
          5,
          0,
          main: true,
          title: true,
          titleName: 'Eternal Welterweight Title',
        ),
        bout(
          'eternal-mma-perth-80',
          'Nadia Sumalee',
          'Jasmine Favero',
          'Strawweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'eternal-mma-perth-80',
          'Tom Sherrin',
          'Jake Linney',
          'Lightweight',
          3,
          2,
        ),
        bout(
          'eternal-mma-perth-80',
          'Brogan Stewart',
          'Caleb McIntyre',
          'Middleweight',
          3,
          3,
        ),
      ],
      'empire-fight-series-5': [
        bout(
          'empire-fight-series-5',
          'Cian Lougheed',
          'Jaga Chan',
          'Super Welterweight',
          5,
          0,
          main: true,
        ),
        bout(
          'empire-fight-series-5',
          'Amber Kitchen',
          'Georgia Smith',
          'Flyweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'empire-fight-series-5',
          'Dylan Fry',
          'Koby Cheong',
          'Lightweight',
          3,
          2,
        ),
        bout(
          'empire-fight-series-5',
          'Reece Thomson',
          'Liam Nuku',
          'Middleweight',
          3,
          3,
        ),
      ],
      'ibc-03-gold-coast': [
        // REAL IBC 3 FIGHT CARD — Tapology verified
        bout(
          'ibc-03-gold-coast',
          'Jay Cutler',
          'Luke Modini',
          'Light Heavyweight',
          5,
          0,
          main: true,
          title: true,
          titleName: 'IBC Light Heavyweight Championship',
        ),
        bout(
          'ibc-03-gold-coast',
          'Isaac Hardman',
          'Jonathan Tuhu',
          'IBC Championship',
          5,
          1,
          coMain: true,
          title: true,
          titleName: 'IBC Championship',
        ),
        bout(
          'ibc-03-gold-coast',
          'Louis Kapua',
          'Viktor Rosinhaskev',
          'Heavyweight',
          3,
          2,
        ),
        bout(
          'ibc-03-gold-coast',
          'Loulanting',
          'Cody Irvine',
          'Middleweight',
          3,
          3,
        ),
        bout(
          'ibc-03-gold-coast',
          'Cody Stevens',
          'Daniel Hull',
          'Welterweight',
          3,
          4,
        ),
        bout(
          'ibc-03-gold-coast',
          'Chris Vaotusa',
          'Braden Kaye',
          'Light Heavyweight',
          3,
          5,
        ),
        bout(
          'ibc-03-gold-coast',
          'Tevita Mita',
          'James Eccles',
          'Heavyweight',
          3,
          6,
        ),
        bout(
          'ibc-03-gold-coast',
          'Elijah Alexander',
          'Joshua Mason',
          'Middleweight',
          3,
          7,
        ),
        bout(
          'ibc-03-gold-coast',
          'Tavita Phillips',
          'Tama Johnson',
          'Super Welterweight',
          3,
          8,
        ),
        bout(
          'ibc-03-gold-coast',
          'Catalin Ion',
          'Zak Hepi',
          'Welterweight',
          3,
          9,
        ),
        bout(
          'ibc-03-gold-coast',
          'Joshua Hepi',
          'Kane Halcrow',
          'Lightweight',
          3,
          10,
        ),
      ],
      'ultimate-legends-apr-2026': [
        bout(
          'ultimate-legends-apr-2026',
          'Jordan Roesler',
          'TBA',
          'WBC Silver Australian Title',
          10,
          0,
          main: true,
          title: true,
          titleName: 'WBC Silver Australian Title',
        ),
        bout(
          'ultimate-legends-apr-2026',
          'TBA',
          'TBA',
          'Co-Main Event (K1)',
          5,
          1,
          coMain: true,
        ),
        bout(
          'ultimate-legends-apr-2026',
          'TBA',
          'TBA',
          'Professional Kickboxing',
          5,
          2,
        ),
        bout(
          'ultimate-legends-apr-2026',
          'TBA',
          'TBA',
          'Professional Muay Thai',
          5,
          3,
        ),
        bout(
          'ultimate-legends-apr-2026',
          'TBA',
          'TBA',
          'Professional Boxing',
          4,
          4,
        ),
      ],
      // ── RIZIN 52 — Saitama Super Arena fight card ──────────────
      'demo-rizin-52': [
        bout(
          'demo-rizin-52',
          'Mikuru Asakura',
          'Roberto de Souza',
          'Lightweight',
          3,
          0,
          main: true,
          title: true,
          titleName: 'RIZIN Lightweight Championship',
        ),
        bout(
          'demo-rizin-52',
          'Kyoji Horiguchi',
          'Hiromasa Ougikubo',
          'Bantamweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo-rizin-52',
          'Kai Asakura',
          'Yutaka Saito',
          'Featherweight',
          3,
          2,
        ),
        bout(
          'demo-rizin-52',
          'Vugar Keramov',
          'Naoki Inoue',
          'Bantamweight',
          3,
          3,
        ),
        bout(
          'demo-rizin-52',
          'Kota Miura',
          'Tatsuki Saomoto',
          'Flyweight',
          3,
          4,
        ),
        bout('demo-rizin-52', 'Yuki Motoya', 'Sho Ogawa', 'Flyweight', 3, 5),
        bout(
          'demo-rizin-52',
          'Takahiro Ashida',
          'Juan Archuleta',
          'Featherweight',
          3,
          6,
        ),
        bout(
          'demo-rizin-52',
          'Erson Yamamoto',
          'Koji Takeda',
          'Lightweight',
          3,
          7,
        ),
      ],
      // ── BKFC Fight Night Australia — Townsville (HEPI EDITION) fight card ──
      'demo_event_15': [
        bout(
          'demo_event_15',
          'Haze Hepi',
          'Krzysztof Wisniewski',
          'Heavyweight',
          5,
          0,
          main: true,
        ),
        bout(
          'demo_event_15',
          'Mark Flanagan',
          'TBA',
          'Cruiserweight',
          5,
          1,
          coMain: true,
        ),
        bout(
          'demo_event_15',
          'Sam Soliman',
          'TBA',
          'Middleweight',
          5,
          2,
        ),
        bout(
          'demo_event_15',
          'BK Bau',
          'TBA',
          'Heavyweight',
          5,
          3,
        ),
        bout(
          'demo_event_15',
          'TBA',
          'TBA',
          'Welterweight',
          5,
          4,
        ),
        bout(
          'demo_event_15',
          'TBA',
          'TBA',
          'Lightweight',
          5,
          5,
        ),
      ],
      // ── Legends Fight Show 45 — Victorian MMA Championships fight card ──
      'demo_event_1': [
        bout(
          'demo_event_1',
          'Jake Matthews',
          'Callan Potter',
          'Welterweight',
          5,
          0,
          main: true,
          title: true,
          titleName: 'Victorian MMA Welterweight Title',
        ),
        bout(
          'demo_event_1',
          'Nik Bagley',
          'Shannon Ross',
          'Lightweight',
          3,
          1,
          coMain: true,
        ),
        bout(
          'demo_event_1',
          'Kit Symmetry',
          'Jace Balanzategui',
          'Featherweight',
          3,
          2,
        ),
        bout(
          'demo_event_1',
          'Dion Harvie',
          'Braiden Sameri',
          'Middleweight',
          3,
          3,
        ),
        bout(
          'demo_event_1',
          'Jade Gallagher',
          'Sara Collins',
          'Women\'s Strawweight',
          3,
          4,
        ),
        bout(
          'demo_event_1',
          'Tom Sherrin',
          'Luke Vella',
          'Bantamweight',
          3,
          5,
        ),
      ],
    };

    final event = demoEvents[eid] ?? widget.initialEvent;
    setState(() {
      _event = event;
      _eventNameController.text = event?.name ?? '';
      _fightCard = demoCards[eid] ?? [];
      _isLoading = false;
    });

}

Future<void> _pickAndUploadPoster() async {
if (\_event == null) return;
final picked = await \_picker.pickImage(
source: ImageSource.gallery,
imageQuality: 80,
);
if (picked == null) return;
if (!mounted) return;
setState(() => \_isUploadingPoster = true);
final messenger = ScaffoldMessenger.of(context);
try {
final storageRef = FirebaseStorage.instance.ref().child(
'event_posters/${\_event!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
);
await storageRef.putData(await picked.readAsBytes());
final url = await storageRef.getDownloadURL();
setState(() {
\_event = EventModel(
id: \_event!.id,
promoterId: \_event!.promoterId,
name: \_event!.name,
description: \_event!.description,
venue: \_event!.venue,
city: \_event!.city,
state: \_event!.state,
country: \_event!.country,
eventDate: \_event!.eventDate,
mainCardTime: \_event!.mainCardTime,
sportType: \_event!.sportType,
status: \_event!.status,
posterUrl: url,
broadcastInfo: \_event!.broadcastInfo,
ticketUrl: \_event!.ticketUrl,
isFeatured: \_event!.isFeatured,
fightIds: \_event!.fightIds,
createdAt: \_event!.createdAt,
updatedAt: DateTime.now(),
);
});
// TODO: Persist posterUrl to Firestore via EventService
} catch (e) {
if (!mounted) return;
messenger.showSnackBar(
SnackBar(
content: Text('Failed to upload image: $e'),
backgroundColor: Colors.red,
),
);
} finally {
if (mounted) {
setState(() => \_isUploadingPoster = false);
}
}
}

void \_saveEventName() async {
if (\_event == null) return;
final newName = \_eventNameController.text.trim();
if (newName.isEmpty || newName == \_event!.name) {
setState(() => \_isEditingName = false);
return;
}
// Save to Firestore (or local model for demo)
setState(() {
\_event = EventModel(
id: \_event!.id,
promoterId: \_event!.promoterId,
name: newName,
description: \_event!.description,
venue: \_event!.venue,
city: \_event!.city,
state: \_event!.state,
country: \_event!.country,
eventDate: \_event!.eventDate,
mainCardTime: \_event!.mainCardTime,
sportType: \_event!.sportType,
status: \_event!.status,
posterUrl: \_event!.posterUrl,
broadcastInfo: \_event!.broadcastInfo,
ticketUrl: \_event!.ticketUrl,
isFeatured: \_event!.isFeatured,
fightIds: \_event!.fightIds,
createdAt: \_event!.createdAt,
updatedAt: DateTime.now(),
);
\_isEditingName = false;
});
// TODO: Persist to Firestore via EventService
}

@override
Widget build(BuildContext context) {
if (\_isLoading) {
return Scaffold(
backgroundColor: AppTheme.primaryBackground,
appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
body: const Center(
child: CircularProgressIndicator(
valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
),
),
);
}

    if (_event == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
          child: Text(
            'Event not found',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // Collapsing Header with Event Poster
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.cardBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Poster background
                  GestureDetector(
                    onTap: _pickAndUploadPoster,
                    child: Stack(
                      children: [
                        if (_event!.posterUrl != null &&
                            _event!.posterUrl!.isNotEmpty)
                          Builder(
                            builder: (_) {
                              final url = _safePoster(_event!.posterUrl);
                              if (ImageAssets.isLocalAsset(url)) {
                                return Image.asset(
                                  url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, _, _) =>
                                      _buildPlaceholderPoster(),
                                );
                              }
                              return DfcNetworkImage(
                                url: url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              );
                            },
                          )
                        else
                          _buildPlaceholderPoster(),
                        if (_isUploadingPoster)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black45,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.neonCyan,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryBackground.withValues(alpha: 0.8),
                          AppTheme.primaryBackground,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Event Info at bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live badge
                        if (_event!.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 8,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'LIVE NOW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Sport type
                        Text(
                          (_event!.sportType ?? 'MMA').toUpperCase(),
                          style: TextStyle(
                            color: _getSportColor(_event!.sportType ?? 'MMA'),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Event name (editable)
                        GestureDetector(
                          onTap: () {
                            setState(() => _isEditingName = true);
                          },
                          child: _isEditingName
                              ? FocusScope(
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      if (!hasFocus) _saveEventName();
                                    },
                                    child: TextField(
                                      controller: _eventNameController,
                                      autofocus: true,
                                      onSubmitted: (_) => _saveEventName(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _event!.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.edit,
                                      color: Colors.white54,
                                      size: 18,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareEvent(),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _setReminder(),
              ),
            ],
          ),

          // Event Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date, Time, Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Date',
                          _formatDate(_event!.eventDate),
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        _buildInfoRow(
                          Icons.access_time,
                          'Time',
                          _formatTime(_event!.eventDate),
                        ),
                        const Divider(color: Colors.white12, height: 24),
                        _buildInfoRow(
                          Icons.location_on,
                          'Venue',
                          _event!.venue.isNotEmpty ? _event!.venue : 'TBD',
                        ),
                        if (_event!.fullLocation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 40),
                            child: Text(
                              _event!.fullLocation,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        if (_event!.streamingPlatform != null) ...[
                          const Divider(color: Colors.white12, height: 24),
                          _buildInfoRow(
                            Icons.live_tv,
                            'Watch on',
                            _event!.streamingPlatform!,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Watch/Buy Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/ticket-purchase/${widget.eventId}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _event!.isLive
                            ? Colors.red
                            : AppTheme.neonCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        _event!.isLive
                            ? Icons.play_arrow
                            : Icons.confirmation_number,
                      ),
                      label: Text(
                        _event!.isLive ? 'WATCH LIVE' : 'BUY TICKETS',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (!_event!.isLive) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _watchEvent(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('View on Promoter Site'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── SOCIAL SHARE PACK ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A1628), Color(0xFF162040)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.neonCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.campaign,
                              color: AppTheme.neonCyan,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'SHARE & PROMOTE',
                              style: TextStyle(
                                color: AppTheme.neonCyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap to copy ready-to-post promo and paste it on your socials — tag @DataFightCentral',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 14),

                        // Instagram / TikTok
                        _buildSocialCopyTile(
                          icon: Icons.camera_alt,
                          label: 'INSTAGRAM / TIKTOK',
                          color: const Color(0xFFE1306C),
                          onTap: () => _copySocialPost('instagram'),
                        ),
                        const SizedBox(height: 8),

                        // Facebook / Meta
                        _buildSocialCopyTile(
                          icon: Icons.facebook,
                          label: 'FACEBOOK / META',
                          color: const Color(0xFF1877F2),
                          onTap: () => _copySocialPost('facebook'),
                        ),
                        const SizedBox(height: 8),

                        // X / Twitter
                        _buildSocialCopyTile(
                          icon: Icons.tag,
                          label: 'X / TWITTER',
                          color: Colors.white,
                          onTap: () => _copySocialPost('twitter'),
                        ),
                        const SizedBox(height: 8),

                        // General Share (opens share sheet)
                        _buildSocialCopyTile(
                          icon: Icons.share,
                          label: 'SHARE LINK',
                          color: AppTheme.neonCyan,
                          onTap: () => _shareEvent(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Fight Card Section
                  const Text(
                    'FIGHT CARD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Fight Card List
          if (_fightCard != null && _fightCard!.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final fight = _fightCard![index];
                return _buildFightCardItem(fight, index);
              }, childCount: _fightCard!.length),
            )
          else
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_mma, size: 48, color: Colors.white24),
                    SizedBox(height: 12),
                    Text(
                      'Fight card coming soon',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );

}

Widget \_buildPlaceholderPoster() {
final sport = \_event!.sportType ?? 'MMA';
final accent = \_getSportColor(sport);
final icon = \_sportIcon(sport);

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.4,
          colors: [
            accent.withValues(alpha: 0.35),
            AppTheme.cardBackground,
            const Color(0xFF030810),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Diagonal slash accent
          CustomPaint(painter: _PosterSlashPainter(color: accent)),
          // Sport icon watermark
          Positioned(
            right: -30,
            bottom: -20,
            child: Icon(icon, size: 200, color: accent.withValues(alpha: 0.08)),
          ),
          // Event info overlay
          Positioned(
            left: 24,
            right: 24,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sport pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    sport.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Event name
                Text(
                  _event!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                // Venue + City
                if (_event!.venue.isNotEmpty)
                  Text(
                    '${_event!.venue}, ${_event!.city}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          // Main event VS badge (if fight card has a main event)
          if (_fightCard != null && _fightCard!.isNotEmpty)
            Positioned(
              top: 24,
              right: 24,
              child: _buildPosterVsBadge(accent),
            ),
        ],
      ),
    );

}

Widget \_buildPosterVsBadge(Color accent) {
final main = \_fightCard!.firstWhere(
(f) => f.isMainEvent,
orElse: () => \_fightCard!.first,
);
return Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
decoration: BoxDecoration(
color: Colors.black.withValues(alpha: 0.6),
borderRadius: BorderRadius.circular(10),
border: Border.all(color: accent.withValues(alpha: 0.4)),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
main.fighter1Id.split(' ').last.toUpperCase(),
style: const TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.w800,
letterSpacing: 0.5,
),
),
Container(
margin: const EdgeInsets.symmetric(vertical: 4),
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
decoration: BoxDecoration(
color: accent.withValues(alpha: 0.85),
borderRadius: BorderRadius.circular(4),
),
child: const Text(
'VS',
style: TextStyle(
color: Colors.white,
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 2,
),
),
),
Text(
main.fighter2Id.split(' ').last.toUpperCase(),
style: const TextStyle(
color: Colors.white,
fontSize: 12,
fontWeight: FontWeight.w800,
letterSpacing: 0.5,
),
),
],
),
);
}

IconData \_sportIcon(String sportType) {
switch (sportType.toLowerCase()) {
case 'mma':
return Icons.sports_mma;
case 'bkfc':
case 'bare knuckle':
return Icons.back_hand;
case 'boxing':
return Icons.sports_mma;
case 'kickboxing':
case 'muay thai':
return Icons.sports_kabaddi;
case 'brawling':
return Icons.local_fire_department;
case 'pro wrestling':
return Icons.stadium;
default:
return Icons.sports_mma;
}
}

Widget \_buildInfoRow(IconData icon, String label, String value) {
return Row(
children: [
Icon(icon, color: AppTheme.neonCyan, size: 20),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
label,
style: const TextStyle(color: Colors.white54, fontSize: 11),
),
Text(
value,
style: const TextStyle(
color: Colors.white,
fontSize: 15,
fontWeight: FontWeight.w500,
),
),
],
),
),
],
);
}

Widget \_buildFightCardItem(FightModel fight, int index) {
final isMainEvent = fight.isMainEvent || index == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: isMainEvent
            ? Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.5),
                width: 2,
              )
            : null,
      ),
      child: Column(
        children: [
          // Main Event badge
          if (isMainEvent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
              ),
              child: const Text(
                '★ MAIN EVENT ★',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Weight class
                Text(
                  '${(fight.weightClass ?? 'Open Weight').toUpperCase()} • ${fight.scheduledRounds ?? 3} RDS',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Fighters
                Row(
                  children: [
                    // Fighter 1
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white12,
                            child: Text(
                              fight.fighter1Id.isNotEmpty
                                  ? fight.fighter1Id[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fight.fighter1Id,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // VS
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Fighter 2
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white12,
                            child: Text(
                              fight.fighter2Id.isNotEmpty
                                  ? fight.fighter2Id[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fight.fighter2Id,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Title fight badge
                if (fight.isTitleFight) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '🏆 TITLE FIGHT',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

}

Color \_getSportColor(String sportType) {
switch (sportType.toLowerCase()) {
case 'mma':
return AppTheme.neonCyan;
case 'bkfc':
return Colors.orange;
case 'boxing':
return const Color(0xFFFFD700);
case 'kickboxing':
return AppTheme.neonMagenta;
case 'pro wrestling':
return Colors.purple;
case 'muay thai':
return Colors.red;
default:
return AppTheme.neonCyan;
}
}

String \_formatDate(DateTime dt) {
final months = [
'January',
'February',
'March',
'April',
'May',
'June',
'July',
'August',
'September',
'October',
'November',
'December',
];
final weekdays = [
'Monday',
'Tuesday',
'Wednesday',
'Thursday',
'Friday',
'Saturday',
'Sunday',
];
return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String \_formatTime(DateTime dt) {
final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
final period = dt.hour >= 12 ? 'PM' : 'AM';
return '$hour:${dt.minute.toString().padLeft(2, '0')} $period ET';
}

void \_watchEvent() async {
// Open the promoter's ticket / streaming page
final promoterUrls = <String, String>{
'ufc': 'https://www.ufc.com/events',
'one': 'https://www.onefc.com/events',
'pfl': 'https://www.pflmma.com/events',
'bkfc': 'https://www.bareknuckle.tv',
'glory': 'https://www.glorykickboxing.com/events',
'matchroom': 'https://www.dazn.com',
'wwe': 'https://www.wwe.com/events',
'rajadamnern': 'https://rajadamnern.com',
'k1': 'https://www.k-1.co.jp/en/',
};
final url =
\_event?.ticketUrl ??
promoterUrls[_event?.promoterId] ??
'https://www.google.com/search?q=${Uri.encodeComponent(_event?.name ?? "fight event")}+tickets';
final uri = Uri.parse(url);
if (await canLaunchUrl(uri)) {
await launchUrl(uri, mode: LaunchMode.externalApplication);
}
}

void \_shareEvent() async {
if (\_event == null) return;
final text = StringBuffer()
..writeln('\u{1F94A} ${_event!.name}')
      ..writeln(
        '\u{1F4C5} ${_formatDate(_event!.eventDate)} @ ${_formatTime(_event!.eventDate)}',
      )
      ..writeln('\u{1F4CD} ${_event!.fullLocation}')
      ..writeln('');
    if (_event!.description != null && _event!.description!.isNotEmpty) {
      text.writeln(_event!.description!);
      text.writeln('');
    }
    if (_event!.ticketUrl != null && _event!.ticketUrl!.isNotEmpty) {
      text.writeln('\u{1F3AB} Tickets: ${_event!.ticketUrl}');
    }
    text.writeln('\u{1F525} Powered by Data Fight Central');
    text.writeln('https://datafightcentral.web.app/event/${\_event!.id}');

    final shareText = text.toString().trim();
    // Sharing functionality disabled for web build
    await Clipboard.setData(ClipboardData(text: shareText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event link copied to clipboard!'),
          backgroundColor: AppTheme.neonCyan,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

}

void \_setReminder() {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: const Text('Reminder set!'),
backgroundColor: AppTheme.neonCyan,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
),
);
}

// ── Social Share Pack helpers ──────────────────────────────────

Widget \_buildSocialCopyTile({
required IconData icon,
required String label,
required Color color,
required VoidCallback onTap,
}) {
return Material(
color: Colors.transparent,
child: InkWell(
onTap: onTap,
borderRadius: BorderRadius.circular(12),
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: color.withValues(alpha: 0.25)),
),
child: Row(
children: [
Icon(icon, color: color, size: 22),
const SizedBox(width: 12),
Expanded(
child: Text(
label,
style: TextStyle(
color: color,
fontWeight: FontWeight.w700,
fontSize: 13,
letterSpacing: 1,
),
),
),
Icon(
Icons.content_copy,
color: color.withValues(alpha: 0.6),
size: 18,
),
],
),
),
),
);
}

void \_copySocialPost(String platform) {
if (\_event == null) return;

    final name = _event!.name;
    final date = _formatDate(_event!.eventDate);
    final time = _formatTime(_event!.eventDate);
    final location = _event!.fullLocation;
    final link = 'https://datafightcentral.web.app/event/${_event!.id}';
    final desc = _event!.description ?? '';

    String post;

    switch (platform) {
      case 'instagram':
        post =
            '''$name

$date \u2022 $time
$location
${desc.isNotEmpty ? '\n$desc\n' : ''}
\u{1F525} Don't miss this!
\u{1F3AB} Link in bio or visit datafightcentral.web.app

#DataFightCentral #DFC #CombatSports #FightNight #MMA #Boxing #LiveFighting #FightHype #${name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}
@DataFightCentral''';
break;

      case 'facebook':
        post =
            '''\u{1F94A} $name

\u{1F4C5} $date @ $time
\u{1F4CD} $location
${desc.isNotEmpty ? '\n$desc\n' : ''}
\u{1F525} Who's coming?! Tag your fight crew!
\u{1F3AB} ${\_event!.ticketUrl ?? link}

Powered by @DataFightCentral \u2014 The AI-Powered Combat Sports Platform
$link''';
break;

      case 'twitter':
        post =
            '''\u{1F94A} $name

\u{1F4C5} $date \u2022 $location

${desc.isNotEmpty ? '$desc\n\n' : ''}Who's watching?! \u{1F525}\u{1F525}\u{1F525}

$link

#DataFightCentral #DFC #CombatSports #FightNight @DataFightCntrl''';
break;

      default:
        post = '$name \u2014 $date @ $location\n$link';
    }

    Clipboard.setData(ClipboardData(text: post));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${platform.toUpperCase()} promo copied! Paste & post \u{1F680}',
        ),
        backgroundColor: AppTheme.neonGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

}
}

/// Diagonal slash accent for programmatic event posters.
class \_PosterSlashPainter extends CustomPainter {
final Color color;
\_PosterSlashPainter({required this.color});

@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = color.withValues(alpha: 0.12)
..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.55, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);

}

@override
bool shouldRepaint(covariant \_PosterSlashPainter old) => old.color != color;
}
