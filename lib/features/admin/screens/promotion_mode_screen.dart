import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/samurai_swarm_coordinator.dart';
import '../../../shared/services/dfc_social_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ██████╗ ██████╗  ██████╗ ███╗   ███╗ ██████╗     ███╗   ███╗ ██████╗ ██████╗ ███████╗
// ██╔══██╗██╔══██╗██╔═══██╗████╗ ████║██╔═══██╗    ████╗ ████║██╔═══██╗██╔══██╗██╔════╝
// ██████╔╝██████╔╝██║   ██║██╔████╔██║██║   ██║    ██╔████╔██║██║   ██║██║  ██║█████╗
// ██╔═══╝ ██╔══██╗██║   ██║██║╚██╔╝██║██║   ██║    ██║╚██╔╝██║██║  ██║██║  ██║██╔══╝
// ██║     ██║  ██║╚██████╔╝██║ ╚═╝ ██║╚██████╔╝    ██║ ╚═╝ ██║╚██████╔╝██████╔╝███████╗
// ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝ ╚═════╝     ╚═╝     ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
// ═══════════════════════════════════════════════════════════════════════════════
//
// PROMOTION MODE — SAMURAI SWARM'S FIRST MISSION
//
// IBC III International Brawling Championship — Gold Coast
// March 7, 2026 · 7:00 PM AEST
//
// This screen boots the Samurai Swarm in IBC-focused promotion mode,
// seeds IBC content to Firestore, fires promo blasts across all channels,
// and gives the owner one-tap controls to run the entire IBC campaign.
// ═══════════════════════════════════════════════════════════════════════════════

class PromotionModeScreen extends StatefulWidget {
  const PromotionModeScreen({super.key});

  @override
  State<PromotionModeScreen> createState() => _PromotionModeScreenState();
}

class _PromotionModeScreenState extends State<PromotionModeScreen>
    with TickerProviderStateMixin {
  final SamuraiSwarmCoordinator _swarm = SamuraiSwarmCoordinator();
  final DfcSocialEngine _social = DfcSocialEngine();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  late AnimationController _rotateCtrl;

  bool _promoActive = false;
  bool _booting = false;
  bool _seeding = false;
  int _contentSeeded = 0;
  int _blastsFired = 0;
  int _newsSeeded = 0;
  int _socialSeeded = 0;
  int _eventsSeeded = 0;
  Timer? _countdownTimer;
  Duration _timeUntilEvent = Duration.zero;

  // IBC III Event Details
  static final DateTime _ibcDate = DateTime(2026, 3, 7, 19);
  static const String _venue = 'Gold Coast Sports & Leisure Centre';
  static const String _city = 'Gold Coast, QLD, Australia';
  static const String _promoter = 'Danny Mac';
  static const String _format = 'Closed-Fist Hybrid · No Grappling';
  static const String _ibcEventId = 'ibc-03-gold-coast';
  static const String _ibcEventUrl = 'https://www.internationalbrawling.com';
  static const String _ibcWatchUrl = 'https://datafightcentral.com/#/ppv';

  // ═══════════════════════════════════════════════════════════════════════════
  // IBC CONTENT BANKS — Ready to pump into Firestore
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<Map<String, String>> _ibcNews = [
    {
      'title':
          'IBC III TONIGHT — International Brawling Championship Hits Gold Coast',
      'body':
          'The International Brawling Championship returns to the Gold Coast Sports & Leisure Centre for IBC 03 on March 7. Danny Mac\'s closed-fist hybrid format continues to grow as Australia\'s most exciting new combat sport. Main event: Jay Cutler vs Luke Modini for the Light Heavyweight title over 5 rounds. Co-main: Isaac Hardman vs Jonathan Tuhu for the IBC Championship. Full 11-fight card starts at 7:00 PM AEST. Watch live on Main Event, Kayo Sports, or TrillerTV+.',
      'category': 'breaking',
    },
    {
      'title':
          'IBC Main Event Breakdown: Cutler vs Modini — LHW Title, 5 Rounds',
      'body':
          'Jay Cutler faces Luke Modini in the IBC 03 main event for the Light Heavyweight Championship. This 5-round title fight headlines a stacked 11-bout card at the Gold Coast Sports & Leisure Centre. Both fighters bring knockout power and the closed-fist format ensures non-stop action. DFC\'s Samurai AI has this one as a war — tune in live on Main Event, Kayo, or TrillerTV+.',
      'category': 'featured',
    },
    {
      'title': 'Inside IBC: Danny Mac\'s \$1B Vision for Australian Brawling',
      'body':
          'Danny Mac founded the International Brawling Championship with one goal: build a billion-dollar combat sport from the ground up in Australia. The closed-fist hybrid format — no grappling, standing 8-count, raw action — has struck a chord with fans who want pure striking entertainment. From IBC 01 on the Gold Coast to IBC 04 heading to Las Vegas, the trajectory is undeniable. DFC is proud to be IBC\'s official digital platform partner.',
      'category': 'featured',
    },
    {
      'title': 'IBC 03 Full Fight Card Revealed — 11 Bouts, All Action',
      'body':
          'IBC 03 Gold Coast fight card:\n\nMain Event: Jay Cutler vs Luke Modini — LHW Title, 5 Rds\nCo-Main: Isaac Hardman vs Jonathan Tuhu — IBC Championship, 5 Rds\nLouis Kapua vs Viktor Rosinhaskev — HW, 3 Rds\nLoulanting vs Cody Irvine — MW, 3 Rds\nCody Stevens vs Daniel Hull — WW, 3 Rds\nChris Vaotusa vs Braden Kaye — LHW, 3 Rds\nTevita Mita vs James Eccles — HW, 3 Rds\nElijah Alexander vs Joshua Mason — MW, 3 Rds\nTavita Phillips vs Tama Johnson — SWW, 3 Rds\nCatalin Ion vs Zak Hepi — WW, 3 Rds\nJoshua Hepi vs Kane Halcrow — LW, 3 Rds\n\nAll bouts under IBC closed-fist hybrid rules. Watch on Main Event, Kayo Sports, TrillerTV+. In-person tickets on Eventbrite.',
      'category': 'breaking',
    },
    {
      'title': 'Why IBC\'s Closed-Fist Format Is Changing Combat Sports',
      'body':
          'No gloves. No grappling. No excuses. The IBC\'s closed-fist hybrid format sits between traditional boxing and bare-knuckle fighting, creating a unique spectacle that rewards precision striking and pure toughness. With a standing 8-count, no clinching allowed, and 3-minute rounds, the action never stops. Critics called it reckless — fans call it the future. IBC 03 will prove which side is right.',
      'category': 'analysis',
    },
    {
      'title': 'DFC x IBC: How Data Fight Central Powers the Championship',
      'body':
          'Data Fight Central is the official digital platform partner of the International Brawling Championship. From live fight cards and AI-powered predictions to fan voting and PPV distribution, DFC brings the full tech stack to IBC events. The Samurai Swarm AI engine generates real-time fight intelligence, while DFC\'s mobile-first platform delivers the experience direct to fans worldwide. The handshake between DFC and IBC represents the future of combat sports technology.',
      'category': 'featured',
    },
    {
      'title': 'IBC 04 Las Vegas Announced — Danny Mac Takes Brawling Global',
      'body':
          'Fresh off IBC 03 on the Gold Coast, Danny Mac has confirmed IBC 04 will be held in Las Vegas — the fight capital of the world. The expansion marks IBC\'s first international event and signals serious ambitions for the championship. Details are still emerging, but expect a stacked card designed to introduce the closed-fist format to the American market. DFC will provide full digital coverage.',
      'category': 'breaking',
    },
    {
      'title': 'Fan Guide: How to Watch IBC 03 Live',
      'body':
          'IBC 03 streams live on March 7 at 7:00 PM AEST. Here\'s how to watch:\n\n1. Main Event / Kayo Sports — PPV\n2. TrillerTV+ — PPV streaming\n3. DFC (datafightcentral.com) — Live coverage\n4. In-Person — Gold Coast Sports & Leisure Centre (tickets on Eventbrite)\n\nDon\'t miss Cutler vs Modini for the LHW Title and Hardman vs Tuhu for the IBC Championship.',
      'category': 'guide',
    },
  ];

  static const List<Map<String, String>> _ibcSocialPosts = [
    {
      'content':
          '🔴 IBC III IS TONIGHT 🔴\n\nInternational Brawling Championship\nGold Coast Sports & Leisure Centre\nMarch 7 · 7:00 PM AEST\n\n11 fights. No grappling. All action.\nThe wood gets chopped TONIGHT. 🪓🔥\n\n#IBCIII #GoldCoast #DFC #Brawling',
    },
    {
      'content':
          '⚔️ MAIN EVENT ⚔️\n\nJay Cutler\nvs\nLuke Modini\n\nLight Heavyweight Title · 5 Rounds\nIBC Closed-Fist Rules\n\nCo-Main: Isaac Hardman vs Jonathan Tuhu\nIBC Championship · 5 Rounds\n\n11 bouts. Who you got? 🥊\n\n#CutlerVsModini #IBCBrawling #DFC',
    },
    {
      'content':
          '🇦🇺 Danny Mac built this from NOTHING.\n\nIBC 01 → Gold Coast\nIBC 02 → Gold Coast\nIBC 03 → Gold Coast (TOMORROW)\nIBC 04 → LAS VEGAS 🇺🇸\n\nThe \$1B brawling dream is REAL.\nRespect the vision. 💯\n\n#IBC #DannyMac #DFC #CombatSports',
    },
    {
      'content':
          '💥 FULL CARD — IBC 03 💥\n\n🏆 Cutler vs Modini — LHW Title, 5 Rds\n🥊 Hardman vs Tuhu — IBC Championship, 5 Rds\n👊 Kapua vs Rosinhaskev — HW, 3 Rds\n⚡ Loulanting vs Irvine — MW, 3 Rds\n💪 Stevens vs Hull — WW, 3 Rds\n+ 6 more bouts!\n\nAll bouts closed-fist hybrid.\nNot long until the wood gets chopped! 🪓\n\n#IBCIII #FightCard #DFC',
    },
    {
      'content':
          '📺 HOW TO WATCH IBC 03:\n\n1️⃣ DFC — datafightcentral.com\n2️⃣ TrillerTV+\n3️⃣ Kayo Sports PPV\n4️⃣ In-Person — Eventbrite tickets\n\nPPV from \$29.99 AUD\nPremium \$49.99 (multi-cam + stats)\nVIP \$79.99 (replay + meet & greet)\n\n#IBCIII #PPV #WatchLive #DFC',
    },
    {
      'content':
          '🤖 DFC x IBC — OFFICIAL PARTNERSHIP 🤝\n\nData Fight Central is the official digital platform of the International Brawling Championship.\n\n✅ Live fight cards\n✅ AI predictions\n✅ Fan voting\n✅ PPV distribution\n✅ Fighter stats\n✅ FightWire coverage\n\nThe future of combat sports tech.\n\n#DFCxIBC #Handshake #CombatTech',
    },
    {
      'content':
          '🪓 "Not long until the wood gets chopped"\n\nIBC III — Gold Coast Sports & Leisure Centre\nTOMORROW NIGHT · 7 PM AEST\n\nClosed-fist. No grappling. Pure action.\nDanny Mac delivers AGAIN. 🔥\n\nTickets: Eventbrite\nPPV: DFC / TrillerTV+ / Kayo\n\n#WoodGetsChopped #IBC #GoldCoast',
    },
    {
      'content':
          '⭐ CO-MAIN EVENT ⭐\n\nIsaac Hardman vs Jonathan Tuhu\nIBC Championship · 5 Rounds\n\nHardman\'s power meets Tuhu\'s grit.\nThis one could steal the show. 🔥\n\n#HardmanVsTuhu #IBCBrawling #DFC',
    },
    {
      'content':
          '👊 FEATURED BOUT 👊\n\nLouis Kapua vs Viktor Rosinhaskev\nHeavyweight · 3 Rounds\n\nTwo heavyweights throwing closed fists.\nSomeone is going to SLEEP. 💤💥\n\n#KapuaVsRosinhaskev #HWBrawling #IBC #DFC',
    },
    {
      'content':
          '🏋️ HEAVYWEIGHT CLASH 🏋️\n\nTevita Mita vs James Eccles\nHeavyweight · 3 Rounds\n\nTwo big boys swinging closed fists.\nSomeone is going to SLEEP. 💤💥\n\n#MitaVsEccles #HWBrawling #IBC #DFC',
    },
    {
      'content':
          '☕ Buy a Coffee, Not a Coffin ☕\n\nDFC supports fighter welfare.\nEvery dollar goes to:\n🧠 Concussion research\n💚 Fighter recovery\n🛡️ Insurance for independent athletes\n\nWatch IBC III tomorrow — support the sport.\ndatafightcentral.com\n\n#BuyACoffeeNotACoffin #FighterWelfare #DFC',
    },
    {
      'content':
          '🚀 IBC is the FASTEST-GROWING combat sport in Australia.\n\nFrom a Gold Coast startup to Las Vegas in 4 events.\nFrom local warriors to international stage.\nFrom Danny Mac\'s dream to a \$1B vision.\n\nIBC III is TOMORROW. Don\'t miss history. 🇦🇺🔥\n\n#IBCBrawling #AustralianCombatSports #DFC',
    },
  ];

  static const List<Map<String, String>> _ibcStories = [
    {
      'name': 'IBC III',
      'badge': '🪓',
      'body':
          'IBC III TOMORROW — Gold Coast Sports & Leisure Centre. The wood gets chopped!',
    },
    {
      'name': 'Main Event',
      'badge': '🏆',
      'body':
          'Cutler vs Modini — LHW Title, 5 Rounds. Co-Main: Hardman vs Tuhu.',
    },
    {
      'name': 'Fight Card',
      'badge': '📋',
      'body':
          '11 fights. Closed-fist hybrid. All action. March 7 at 7 PM AEST.',
    },
    {
      'name': 'How to Watch',
      'badge': '📺',
      'body': 'Main Event / Kayo Sports / TrillerTV+. Live tonight!',
    },
    {
      'name': 'DFC x IBC',
      'badge': '🤝',
      'body':
          'Official digital platform partner. AI predictions. Fan voting. Live stats.',
    },
    {
      'name': 'Danny Mac',
      'badge': '🇦🇺',
      'body':
          'From nothing to \$1B vision. IBC founder Danny Mac delivers again.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _updateCountdown();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    if (_ibcDate.isAfter(now)) {
      setState(() => _timeUntilEvent = _ibcDate.difference(now));
    } else {
      setState(() => _timeUntilEvent = Duration.zero);
    }
  }

  String _promoNewsImage(String category) {
    switch (category.toLowerCase()) {
      case 'breaking':
        return ImageAssets.ppvIbc03Hero;
      case 'featured':
        return ImageAssets.ppvIbc03Thumb;
      case 'analysis':
        return ImageAssets.bkfcPlaceholder;
      default:
        return ImageAssets.posterForSport('Brawling');
    }
  }

  String _promoPostImage(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('ppv') || lower.contains('watch')) {
      return ImageAssets.ppvIbc03Hero;
    }
    if (lower.contains('danny mac') || lower.contains('las vegas')) {
      return ImageAssets.bgCentral;
    }
    if (lower.contains('cutler') || lower.contains('modini')) {
      return ImageAssets.ppvIbc03Thumb;
    }
    return ImageAssets.posterForSport('Brawling');
  }

  String _promoCtaRoute(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('ppv') || lower.contains('watch')) return '/ppv';
    if (lower.contains('ticket') || lower.contains('eventbrite')) {
      return '/events';
    }
    return '/fightwire';
  }

  String _promoCtaLabel(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('ppv') || lower.contains('watch')) return 'Watch Live';
    if (lower.contains('ticket') || lower.contains('eventbrite')) {
      return 'Get Tickets';
    }
    return 'Read Coverage';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROMOTION ENGINE — The actual work
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _activatePromoMode() async {
    setState(() => _booting = true);

    // Step 1: Boot the Swarm if not already running
    if (!_swarm.initialized) {
      await _swarm.bootSwarm();
    }

    setState(() {
      _booting = false;
      _promoActive = true;
    });

    // Step 2: Log activation to Firestore
    try {
      await _firestore.collection('platform_config').doc('promotion_mode').set({
        'active': true,
        'campaign': 'IBC III — Gold Coast',
        'activatedAt': FieldValue.serverTimestamp(),
        'activatedBy': 'admin',
        'targetEvent': 'ibc-03-gold-coast',
        'eventDate': Timestamp.fromDate(_ibcDate),
      });
    } catch (e) {
      debugPrint('⚠️ Promo mode log: $e');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚔️ PROMOTION MODE ACTIVATED — Samurai Swarm online, IBC mission engaged',
          ),
          backgroundColor: Colors.deepOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _seedIbcNews() async {
    setState(() => _seeding = true);
    int count = 0;

    try {
      final batch = _firestore.batch();

      for (final article in _ibcNews) {
        final newsImageUrl = _promoNewsImage(article['category'] ?? 'featured');
        final ctaRoute = _promoCtaRoute(article['body'] ?? '');
        final ctaLabel = _promoCtaLabel(article['body'] ?? '');
        // Write to fight_news
        final newsRef = _firestore.collection('fight_news').doc();
        batch.set(newsRef, {
          'title': article['title'],
          'summary': article['body']!.substring(
            0,
            article['body']!.length.clamp(0, 200),
          ),
          'fullContent': article['body'],
          'category': article['category'],
          'source': 'DFC × IBC Official',
          'promotion': 'International Brawling Championship',
          'eventId': _ibcEventId,
          'sportType': 'Brawling',
          'imageUrl': newsImageUrl,
          'mediaUrls': [newsImageUrl],
          'thumbnailUrl': newsImageUrl,
          'linkUrl': ctaRoute,
          'ctaRoute': ctaRoute,
          'ctaLabel': ctaLabel,
          'sourceUrl': _ibcEventUrl,
          'isBreaking': article['category'] == 'breaking',
          'isFeatured': article['category'] == 'featured',
          'publishedAt': Timestamp.fromDate(DateTime.now()),
          'createdAt': FieldValue.serverTimestamp(),
          'generatedBy': 'promotion_mode',
          'tags': ['IBC', 'IBC III', 'Gold Coast', 'Brawling', 'DFC'],
        });

        // Also write to news collection
        final newsRef2 = _firestore.collection('news').doc();
        batch.set(newsRef2, {
          'title': article['title'],
          'body': article['body'],
          'category': article['category'],
          'source': 'DFC × IBC Official',
          'promotion': 'International Brawling Championship',
          'eventId': _ibcEventId,
          'sportType': 'Brawling',
          'imageUrl': newsImageUrl,
          'mediaUrls': [newsImageUrl],
          'thumbnailUrl': newsImageUrl,
          'url': _ibcEventUrl,
          'linkUrl': ctaRoute,
          'ctaRoute': ctaRoute,
          'ctaLabel': ctaLabel,
          'isBreaking': article['category'] == 'breaking',
          'isFeatured': true,
          'views': 0,
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'createdAt': FieldValue.serverTimestamp(),
          'generatedBy': 'promotion_mode',
        });

        count += 2;
      }

      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ IBC news seed: $e');
    }

    setState(() {
      _newsSeeded += count;
      _contentSeeded += count;
      _seeding = false;
    });

    _snack('📰 $count IBC news articles seeded to Firestore');
  }

  Future<void> _seedIbcSocialPosts() async {
    setState(() => _seeding = true);
    int count = 0;

    try {
      final batch = _firestore.batch();

      for (final post in _ibcSocialPosts) {
        final ref = _firestore.collection('posts').doc();
        final content = post['content'] ?? '';
        final postImageUrl = _promoPostImage(content);
        final ctaRoute = _promoCtaRoute(content);
        batch.set(ref, {
          'userId': 'dfc_ibc_official',
          'authorId': 'dfc_ibc_official',
          'userName': 'DFC × IBC Official',
          'userDisplayName': 'DFC × IBC Official',
          'authorName': 'DFC × IBC Official',
          'content': content,
          'imageUrl': postImageUrl,
          'mediaUrls': [postImageUrl],
          'thumbnailUrl': postImageUrl,
          'likes': 0,
          'comments': 0,
          'commentCount': 0,
          'shares': 0,
          'shareCount': 0,
          'postType': 'announcement',
          'type': 'promotion_mode',
          'sportType': 'Brawling',
          'promotion': 'International Brawling Championship',
          'eventId': _ibcEventId,
          'linkUrl': ctaRoute,
          'ctaRoute': ctaRoute,
          'ctaLabel': _promoCtaLabel(content),
          'sourceUrl': _ibcWatchUrl,
          'visibility': 'public',
          'isVerified': true,
          'userRole': 'promoter',
          'adMetadata': {
            'placement': 'promotion_mode',
            'format': 'campaign',
            'campaign': 'IBC III - Gold Coast',
          },
          'timestamp': FieldValue.serverTimestamp(),
          'tags': ['IBC', 'IBCIII', 'GoldCoast', 'DFC', 'Brawling'],
        });
        count++;
      }

      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ IBC social seed: $e');
    }

    setState(() {
      _socialSeeded += count;
      _contentSeeded += count;
      _seeding = false;
    });

    _snack('📱 $count IBC social posts seeded to Firestore');
  }

  Future<void> _seedIbcStories() async {
    setState(() => _seeding = true);
    int count = 0;

    try {
      final batch = _firestore.batch();

      for (int i = 0; i < _ibcStories.length; i++) {
        final story = _ibcStories[i];
        final ref = _firestore.collection('stories').doc();
        batch.set(ref, {
          'name': story['name'],
          'color': '#FF6D00',
          'badge': story['badge'],
          'order': i + 1,
          'body': story['body'],
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'promotion_mode',
        });
        count++;
      }

      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ IBC stories seed: $e');
    }

    setState(() {
      _contentSeeded += count;
      _seeding = false;
    });

    _snack('📖 $count IBC stories seeded to Firestore');
  }

  Future<void> _seedIbcEvents() async {
    setState(() => _seeding = true);
    int count = 0;

    try {
      // Seed the IBC 03 event to Firestore events collection
      await _firestore.collection('events').doc('ibc-03-gold-coast').set({
        'title': 'IBC 03: International Brawling Championship',
        'description':
            'Australia\'s fastest-growing combat sport returns to the Gold Coast. Closed-fist hybrid format, no grappling, all action. Main event: Jay Cutler vs Luke Modini for the Light Heavyweight title. Co-main: Isaac Hardman vs Jonathan Tuhu for the IBC Championship.',
        'date': Timestamp.fromDate(_ibcDate),
        'venue': _venue,
        'city': 'Gold Coast',
        'state': 'QLD',
        'country': 'Australia',
        'promotion': 'IBC (International Brawling Championship)',
        'imageUrl': ImageAssets.ppvIbc03Hero,
        'thumbnailUrl': ImageAssets.ppvIbc03Thumb,
        'posterUrl': ImageAssets.ppvIbc03Hero,
        'type': 'fight_night',
        'status': 'upcoming',
        'isFeatured': true,
        'sportType': 'brawling',
        'broadcastInfo': 'Main Event / Kayo Sports / TrillerTV+ PPV',
        'ticketUrl': _ibcEventUrl,
        'streamUrl': _ibcWatchUrl,
        'linkUrl': '/events',
        'ppvPrice': 29.99,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'promotion_mode',
        'fightCard': [
          {
            'red': 'Jay Cutler',
            'blue': 'Luke Modini',
            'weight': 'Light Heavyweight',
            'rounds': 5,
            'title': true,
          },
          {
            'red': 'Isaac Hardman',
            'blue': 'Jonathan Tuhu',
            'weight': 'Championship',
            'rounds': 5,
            'title': true,
          },
          {
            'red': 'Louis Kapua',
            'blue': 'Viktor Rosinhaskev',
            'weight': 'Heavyweight',
            'rounds': 3,
            'title': false,
          },
          {
            'red': 'Loulanting',
            'blue': 'Cody Irvine',
            'weight': 'Middleweight',
            'rounds': 3,
            'title': false,
          },
          {
            'red': 'Joshua Hepi',
            'blue': 'Kane Halcrow',
            'weight': 'Lightweight',
            'rounds': 3,
            'title': false,
          },
          {
            'red': 'Tevita Mita',
            'blue': 'James Eccles',
            'weight': 'Heavyweight',
            'rounds': 3,
            'title': false,
          },
        ],
      });
      count++;

      // Also seed IBC 04 Las Vegas announcement
      await _firestore.collection('events').doc('ibc-04-las-vegas').set({
        'title': 'IBC 04: Las Vegas (Announced)',
        'description':
            'The International Brawling Championship goes global — first international event in Las Vegas. Danny Mac\'s vision takes on the fight capital of the world.',
        'date': Timestamp.fromDate(DateTime(2026, 7, 15, 19)),
        'venue': 'TBA',
        'city': 'Las Vegas',
        'state': 'NV',
        'country': 'USA',
        'promotion': 'IBC',
        'imageUrl': ImageAssets.ppvIbc03Thumb,
        'thumbnailUrl': ImageAssets.ppvIbc03Thumb,
        'type': 'fight_night',
        'status': 'announced',
        'isFeatured': false,
        'sportType': 'brawling',
        'broadcastInfo': 'TrillerTV+ PPV',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'promotion_mode',
      });
      count++;
    } catch (e) {
      debugPrint('⚠️ IBC events seed: $e');
    }

    setState(() {
      _eventsSeeded += count;
      _contentSeeded += count;
      _seeding = false;
    });

    _snack('📅 $count IBC events seeded to Firestore');
  }

  Future<void> _firePromoBlast() async {
    setState(() => _seeding = true);

    try {
      await _social.firePromoBlast(
        headline:
            '🔴 IBC III TOMORROW — International Brawling Championship · Gold Coast · March 7 · 7 PM AEST',
        description:
            'Closed-fist. No grappling. All action. Main Event: Cutler vs Modini for the Light Heavyweight title. Co-main: Hardman vs Tuhu. Watch on DFC, TrillerTV+, and Kayo. PPV \$29.99 AUD. The wood gets chopped TOMORROW! 🪓🔥 #IBCIII #DFC',
      );
    } catch (e) {
      debugPrint('⚠️ Promo blast: $e');
    }

    setState(() {
      _blastsFired++;
      _seeding = false;
    });

    _snack('🔥 IBC promo blast fired across all social platforms!');
  }

  Future<void> _megaSeed() async {
    setState(() => _seeding = true);

    // Fire everything at once
    await _seedIbcNews();
    await _seedIbcSocialPosts();
    await _seedIbcStories();
    await _seedIbcEvents();

    // Also fire the swarm content pump
    if (_swarm.initialized) {
      await _swarm.forcePump();
    }

    // Fire a promo blast
    await _firePromoBlast();

    setState(() => _seeding = false);

    _snack(
      '🚀 MEGA SEED COMPLETE — $_contentSeeded items pumped into Firestore!',
    );
  }

  Future<void> _fireSwarmPump() async {
    if (!_swarm.initialized) {
      _snack('⚠️ Boot the Swarm first');
      return;
    }
    await _swarm.forcePump();
    _snack('⚔️ Swarm content pump fired!');
  }

  Future<void> _fireAll() async {
    if (!_swarm.initialized) {
      _snack('⚠️ Boot the Swarm first');
      return;
    }
    await _swarm.fireAll();
    setState(() => _blastsFired++);
    _snack('🔥 FIRE ALL — Swarm publishing to all platforms!');
  }

  Future<void> _swarmSeedAll() async {
    if (!_swarm.initialized) {
      _snack('⚠️ Boot the Swarm first');
      return;
    }
    setState(() => _seeding = true);
    final count = await _swarm.seedAllPages();
    setState(() {
      _contentSeeded += count;
      _seeding = false;
    });
    _snack('⚔️ Swarm MEGA SEED: $count items generated across all pages!');
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.deepOrange.shade900,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: _promoActive
            ? Colors.deepOrange.shade900
            : Colors.grey.shade900,
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Opacity(
                opacity: _promoActive ? _pulse.value : 0.5,
                child: const Icon(Icons.campaign, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'PROMOTION MODE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
        actions: [
          if (_promoActive)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Opacity(
                opacity: _pulse.value,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          if (_swarm.initialized)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                '${_swarm.onlineAgents}/${_swarm.totalAgents}',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _booting
          ? _buildBootingScreen()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCountdownBanner(),
                const SizedBox(height: 16),
                _buildActivationCard(),
                const SizedBox(height: 16),
                if (_promoActive) ...[
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    'IBC CONTENT — SEED TO FIRESTORE',
                    Icons.cloud_upload,
                  ),
                  const SizedBox(height: 8),
                  _buildSeedButton(
                    icon: Icons.newspaper,
                    label: 'Seed IBC News (${_ibcNews.length} articles)',
                    subtitle: 'Writes to fight_news + news collections',
                    color: Colors.blue,
                    onTap: _seedIbcNews,
                  ),
                  const SizedBox(height: 8),
                  _buildSeedButton(
                    icon: Icons.forum,
                    label:
                        'Seed IBC Social Posts (${_ibcSocialPosts.length} posts)',
                    subtitle: 'Writes to posts collection for social feed',
                    color: Colors.purple,
                    onTap: _seedIbcSocialPosts,
                  ),
                  const SizedBox(height: 8),
                  _buildSeedButton(
                    icon: Icons.auto_stories,
                    label: 'Seed IBC Stories (${_ibcStories.length} stories)',
                    subtitle:
                        'Writes to stories collection for story highlights',
                    color: Colors.orange,
                    onTap: _seedIbcStories,
                  ),
                  const SizedBox(height: 8),
                  _buildSeedButton(
                    icon: Icons.event,
                    label: 'Seed IBC Events (IBC 03 + IBC 04)',
                    subtitle:
                        'Writes to events collection with full fight card',
                    color: Colors.teal,
                    onTap: _seedIbcEvents,
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader(
                    'FIRE COMMANDS',
                    Icons.local_fire_department,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildFireButton(
                          icon: Icons.rocket_launch,
                          label: 'MEGA\nSEED',
                          color: Colors.deepOrange,
                          onTap: _megaSeed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFireButton(
                          icon: Icons.bolt,
                          label: 'SWARM\nPUMP',
                          color: AppTheme.neonCyan,
                          onTap: _fireSwarmPump,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFireButton(
                          icon: Icons.local_fire_department,
                          label: 'FIRE\nALL',
                          color: Colors.red,
                          onTap: _fireAll,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFireButton(
                          icon: Icons.campaign,
                          label: 'PROMO\nBLAST',
                          color: Colors.amber.shade700,
                          onTap: _firePromoBlast,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _seeding ? null : _swarmSeedAll,
                      icon: const Icon(Icons.rocket_launch, size: 28),
                      label: const Text(
                        '⚔️ SWARM MEGA SEED — Fill ALL Pages',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'IBC III — FIGHT CARD PREVIEW',
                    Icons.sports_mma,
                  ),
                  const SizedBox(height: 8),
                  ..._buildFightCardPreview(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('QUICK NAV', Icons.navigation),
                  const SizedBox(height: 8),
                  _buildNavGrid(),
                  const SizedBox(height: 40),
                ],
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBootingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _rotateCtrl,
            builder: (_, child) =>
                Transform.rotate(angle: _rotateCtrl.value * 6.28, child: child),
            child: const Icon(
              Icons.settings,
              color: AppTheme.neonCyan,
              size: 80,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'BOOTING SAMURAI SWARM...',
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '53 agents · 25 engines · 1 hive mind',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              color: AppTheme.neonCyan,
              backgroundColor: Colors.white12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBanner() {
    final hours = _timeUntilEvent.inHours;
    final minutes = _timeUntilEvent.inMinutes % 60;
    final seconds = _timeUntilEvent.inSeconds % 60;
    final isLive = _timeUntilEvent == Duration.zero;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [Colors.red.shade900, Colors.deepOrange.shade900]
              : [Colors.deepOrange.shade900, Colors.orange.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_mma, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              const Text(
                'IBC III',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isLive ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLive ? 'LIVE NOW' : 'TOMORROW',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'International Brawling Championship',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 2),
          const Text(
            '$_venue · $_city',
            style: TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!isLive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _countdownBox(hours.toString().padLeft(2, '0'), 'HRS'),
                const Text(
                  ' : ',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _countdownBox(minutes.toString().padLeft(2, '0'), 'MIN'),
                const Text(
                  ' : ',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _countdownBox(seconds.toString().padLeft(2, '0'), 'SEC'),
              ],
            ),
          ] else
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Opacity(
                opacity: _pulse.value,
                child: const Text(
                  '🔴 EVENT IS LIVE',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Promoter: $_promoter · Format: $_format',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _countdownBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActivationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _promoActive
              ? [Colors.green.shade900, Colors.green.shade800]
              : [Colors.grey.shade900, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _promoActive ? Colors.green : Colors.grey.shade700,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _promoActive ? Icons.check_circle : Icons.power_settings_new,
            color: _promoActive ? Colors.green : Colors.grey,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _promoActive ? 'PROMOTION MODE ACTIVE' : 'PROMOTION MODE OFFLINE',
            style: TextStyle(
              color: _promoActive ? Colors.green : Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _promoActive
                ? 'Samurai Swarm online · ${_swarm.onlineAgents} agents · IBC mission engaged'
                : 'Tap to boot the Samurai Swarm and activate IBC promotion',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!_promoActive)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _booting ? null : _activatePromoMode,
                icon: const Icon(Icons.power_settings_new, size: 28),
                label: const Text(
                  'ACTIVATE PROMOTION MODE',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('Content\nSeeded', '$_contentSeeded', Colors.blue),
        const SizedBox(width: 8),
        _statCard('News\nArticles', '$_newsSeeded', Colors.cyan),
        const SizedBox(width: 8),
        _statCard('Social\nPosts', '$_socialSeeded', Colors.purple),
        const SizedBox(width: 8),
        _statCard('Events\nSeeded', '$_eventsSeeded', Colors.teal),
        const SizedBox(width: 8),
        _statCard('Promo\nBlasts', '$_blastsFired', Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 9),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.orange,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSeedButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _seeding ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_seeding)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withValues(alpha: 0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFireButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _seeding ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFightCardPreview() {
    const bouts = [
      {
        'emoji': '🏆',
        'type': 'MAIN EVENT',
        'red': 'Jay Cutler',
        'blue': 'Luke Modini',
        'weight': 'LHW Title · 5 Rds',
        'ai': 'Cutler TKO R4 — 61%',
      },
      {
        'emoji': '⭐',
        'type': 'CO-MAIN',
        'red': 'Isaac Hardman',
        'blue': 'Jonathan Tuhu',
        'weight': 'IBC Championship · 5 Rds',
        'ai': 'Hardman KO R2 — 64%',
      },
      {
        'emoji': '👊',
        'type': 'FEATURED',
        'red': 'Nikita Davids (5-0)',
        'blue': 'Sarah King (4-1)',
        'weight': 'SW · 3 Rds',
        'ai': 'Davids Decision — 64%',
      },
      {
        'emoji': '⚡',
        'type': 'UNDERCARD',
        'red': 'Danny Torres (7-3)',
        'blue': 'Koji Tanaka (6-2)',
        'weight': 'LW · 3 Rds',
        'ai': 'Tanaka TKO R2 — 55%',
      },
      {
        'emoji': '💪',
        'type': 'OPENER',
        'red': 'Liam O\'Brien (3-1)',
        'blue': 'Ratu Vunipola (4-0)',
        'weight': 'HW · 3 Rds',
        'ai': 'Vunipola KO R1 — 61%',
      },
    ];

    return bouts.map((bout) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(bout['emoji']!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    bout['type']!,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    bout['weight']!,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${bout['red']}  vs  ${bout['blue']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '🤖 AI: ${bout['ai']}',
                style: TextStyle(
                  color: AppTheme.neonCyan.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildNavGrid() {
    final navItems = [
      {
        'icon': Icons.handshake,
        'label': 'IBC Partnership',
        'route': '/ibc',
        'color': Colors.orange,
      },
      {
        'icon': Icons.list_alt,
        'label': 'Fight Card',
        'route': '/ibc/fight-card',
        'color': Colors.red,
      },
      {
        'icon': Icons.dashboard,
        'label': 'Swarm Dashboard',
        'route': '/swarm-dashboard',
        'color': AppTheme.neonCyan,
      },
      {
        'icon': Icons.article,
        'label': 'Content Center',
        'route': '/content-command-center',
        'color': Colors.purple,
      },
      {
        'icon': Icons.event,
        'label': 'Events',
        'route': '/events',
        'color': Colors.teal,
      },
      {
        'icon': Icons.payment,
        'label': 'PPV/Tickets',
        'route': '/ticket-purchase/ibc-03-gold-coast',
        'color': Colors.green,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.3,
      children: navItems.map((item) {
        final color = item['color'] as Color;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push(item['route'] as String);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
