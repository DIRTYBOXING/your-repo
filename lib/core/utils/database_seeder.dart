import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/image_assets.dart';
import '../../shared/services/ppv_service.dart';
import '../../shared/services/social_post_adapter_service.dart';

/// Helper class to seed initial data into Firestore
class DatabaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _inferSeedSportType(Map<String, dynamic> item) {
    final source = [
      item['sportType'],
      item['category'],
      item['title'],
      item['content'],
      item['summary'],
      item['authorId'],
      item['authorName'],
      item['source'],
    ].whereType<String>().join(' ').toLowerCase();

    if (source.contains('drone')) return 'Drone Racing';
    if (source.contains('bare knuckle') || source.contains('bkfc')) {
      return 'BKFC';
    }
    if (source.contains('brawling')) {
      return 'Brawling';
    }
    if (source.contains('muay thai')) return 'Muay Thai';
    if (source.contains('kickboxing') || source.contains('k-1')) {
      return 'Kickboxing';
    }
    if (source.contains('boxing') || source.contains('wbc')) return 'Boxing';
    if (source.contains('wrestling')) return 'Wrestling';
    return 'MMA';
  }

  String _inferSeedRoute(Map<String, dynamic> item) {
    final source = [
      item['title'],
      item['content'],
      item['summary'],
      item['authorName'],
      item['source'],
    ].whereType<String>().join(' ').toLowerCase();

    if (source.contains('ppv') || source.contains('watch live')) return '/ppv';
    if (source.contains('ticket') ||
        source.contains('eventbrite') ||
        source.contains('fight card') ||
        source.contains('fight night')) {
      return '/events';
    }
    if (source.contains('marketplace') || source.contains('gear')) {
      return '/marketplace';
    }
    if (source.contains('mentor') || source.contains('coach')) {
      return '/gym-mentor';
    }
    if (source.contains('sponsor')) return '/partner';
    return '/fightwire';
  }

  String _inferSeedCtaLabel(Map<String, dynamic> item, String route) {
    final source = [
      item['title'],
      item['content'],
      item['summary'],
    ].whereType<String>().join(' ').toLowerCase();

    if (route == '/ppv') return 'Watch Live';
    if (route == '/marketplace') return 'Shop Now';
    if (source.contains('apply')) return 'Apply Now';
    if (source.contains('ticket')) return 'Get Tickets';
    if (source.contains('mentor') || source.contains('coach')) {
      return 'Find Coach';
    }
    return 'Open';
  }

  String _resolveSeedImage(Map<String, dynamic> item, int index) {
    final sportType = _inferSeedSportType(item);
    final source = [
      item['title'],
      item['content'],
      item['summary'],
      item['authorId'],
      item['authorName'],
      item['source'],
    ].whereType<String>().join(' ').toLowerCase();

    if (source.contains('ultimate legends')) {
      return ImageAssets.ppvUltimateLegends2026Thumb;
    }
    if (source.contains('brawling') || source.contains('gold coast fight')) {
      return ImageAssets.ppvIbc03Thumb;
    }
    if (source.contains('bkfc') || source.contains('hepi')) {
      return ImageAssets.ppvBkfcTownsvilleHepiThumb;
    }
    if (source.contains('hex')) return ImageAssets.ppvHex25Thumb;
    if (source.contains('eternal')) return ImageAssets.ppvEternal88Thumb;
    if (source.contains('drone')) return ImageAssets.bgResized;

    const rotated = [
      ImageAssets.socialPost1,
      ImageAssets.socialPost2,
      ImageAssets.socialPost3,
      ImageAssets.socialPost4,
    ];

    final sportImage = ImageAssets.posterForSport(sportType);
    if (sportImage != ImageAssets.bgLogoSmall) return sportImage;
    return rotated[index % rotated.length];
  }

  /// Seed data for a specific user (e.g., demo user)
  Future<void> seedUserData(String userId, {String? displayName}) async {
    debugPrint('Seeding data for user: $userId');
    await _seedFighterForUser(userId, displayName: displayName);
    await _seedStatsForUser(userId);
    debugPrint('User data seeded!');
  }

  Future<void> seedInitialData() async {
    debugPrint('Starting database seed...');

    int seeded = 0;
    int failed = 0;

    // 1. Seed news articles
    try {
      await _seedNewsArticles();
      seeded++;
      debugPrint('  ✅ News articles seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ News articles seed skipped: $e');
    }

    // 2. Seed events
    try {
      await _seedEvents();
      seeded++;
      debugPrint('  ✅ Events seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Events seed skipped: $e');
    }

    // 3. Seed stories
    try {
      await _seedStories();
      seeded++;
      debugPrint('  ✅ Stories seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Stories seed skipped: $e');
    }

    // 4. Seed priority page identities
    try {
      await _seedPriorityPageProfiles();
      seeded++;
      debugPrint('  ✅ Priority page identities seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Priority page identities skipped: $e');
    }

    // 5. Seed translations
    try {
      await _seedTranslations();
      seeded++;
      debugPrint('  ✅ Translations seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Translations seed skipped: $e');
    }

    // 5. Seed gyms (real AU/NZ locations)
    try {
      await _seedGyms();
      seeded++;
      debugPrint('  ✅ Gyms seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Gyms seed skipped: $e');
    }

    // 6. Seed fighter databank (ranked fighters)
    try {
      await _seedFighterDatabank();
      seeded++;
      debugPrint('  ✅ Fighter databank seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Fighter databank seed skipped: $e');
    }

    // 7. Seed fights (bout records)
    try {
      await _seedFights();
      seeded++;
      debugPrint('  ✅ Fights seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Fights seed skipped: $e');
    }

    // 8. Seed PPV events (for fight camp service)
    try {
      await _seedPPVEvents();
      seeded++;
      debugPrint('  ✅ PPV events seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ PPV events seed skipped: $e');
    }

    // 9. Seed fight card templates
    try {
      await _seedFightCardTemplates();
      seeded++;
      debugPrint('  ✅ Fight card templates seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Fight card templates seed skipped: $e');
    }

    // 10. Seed subscription plans
    try {
      await _seedSubscriptionPlans();
      seeded++;
      debugPrint('  ✅ Subscription plans seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Subscription plans seed skipped: $e');
    }

    // 11. Seed help resources
    try {
      await _seedHelpResources();
      seeded++;
      debugPrint('  ✅ Help resources seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Help resources seed skipped: $e');
    }

    // 12. Seed Haze Hepi editorial stories (feed_content)
    try {
      await _seedHazeHepiStories();
      seeded++;
      debugPrint('  ✅ Haze Hepi stories seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Haze Hepi stories seed skipped: $e');
    }

    // 13. Seed social feed posts (posts collection — main feed)
    try {
      await _seedPosts();
      seeded++;
      debugPrint('  ✅ Feed posts seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Feed posts seed skipped: $e');
    }

    // 14. Seed DFC published content (dfc_content — publisher pipeline)
    try {
      await _seedDFCContent();
      seeded++;
      debugPrint('  ✅ DFC content seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ DFC content seed skipped: $e');
    }

    // 15. Seed feed articles (feed_content — RSS-style news)
    try {
      await _seedFeedArticles();
      seeded++;
      debugPrint('  ✅ Feed articles seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Feed articles seed skipped: $e');
    }

    // 16. Seed promoter subscriptions (feed priority ranking)
    try {
      await _seedSubscriptions();
      seeded++;
      debugPrint('  ✅ Subscriptions seeded');
    } catch (e) {
      failed++;
      debugPrint('  ⚠️ Subscriptions seed skipped: $e');
    }

    debugPrint('Database seed completed! ($seeded succeeded, $failed skipped)');
  }

  /// Seed base translation documents so LocalizationService can pull from Firestore
  Future<void> _seedTranslations() async {
    final colRef = _firestore.collection('translations');
    final existing = await colRef.doc('en').get();
    if (existing.exists) return; // Already seeded

    // Only seed the English doc as a baseline; other locales use built-in maps
    // and can be overridden in Firebase Console per-locale.
    await colRef.doc('en').set({
      'nav_home': 'Home',
      'nav_feed': 'Feed',
      'nav_fights': 'Fights',
      'nav_profile': 'Profile',
      'nav_settings': 'Settings',
      'app_name': 'Data Fight Central',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'sign_up': 'Sign Up',
      'live_now': 'LIVE NOW',
      'upcoming': 'Upcoming',
      'results': 'Results',
      'fighters': 'Fighters',
      'knockout': 'Knockout',
      'submission': 'Submission',
      'decision': 'Decision',
      'post': 'Post',
      'comment': 'Comment',
      'follow': 'Follow',
      'following': 'Following',
      'followers': 'Followers',
    });
  }

  /// Seed stories — edit these anytime in Firebase Console > stories collection
  Future<void> _seedStories() async {
    final storiesRef = _firestore.collection('stories');
    final existing = await storiesRef.limit(1).get();
    if (existing.docs.isNotEmpty) return; // Already seeded

    final stories = [
      {'name': 'Your Story', 'color': '#00E5FF', 'isAdd': true, 'order': 0},
      {'name': 'Coach Eugene', 'color': '#00E676', 'badge': '🥊', 'order': 1},
      {'name': 'UFC News', 'color': '#FF5252', 'badge': '📰', 'order': 2},
      {'name': 'Tiger MT', 'color': '#FFB300', 'badge': '💪', 'order': 3},
      {'name': 'Stamp', 'color': '#E040FB', 'badge': '🏆', 'order': 4},
      {'name': 'DFC Official', 'color': '#FFD700', 'badge': '⚡', 'order': 5},
      {'name': 'Leg Day', 'color': '#64B5F6', 'badge': '🦵', 'order': 6},
    ];

    final batch = _firestore.batch();
    for (final story in stories) {
      batch.set(storiesRef.doc(), story);
    }
    await batch.commit();
    debugPrint('Stories seeded!');
  }

  Future<void> _seedPriorityPageProfiles() async {
    final usersRef = _firestore.collection('users');
    final batch = _firestore.batch();

    final profiles = <Map<String, dynamic>>[
      {
        'id': 'dfc_official',
        'displayName': 'DFC Official',
        'pageDisplayName': 'DFC Official',
        'role': 'admin',
        'pageBio':
            'Official Data Fight Central page for platform signals, fight-week promotion, and premium partner launches.',
        'bio':
            'Official Data Fight Central page for platform signals, fight-week promotion, and premium partner launches.',
        'pageAvatarUrl': ImageAssets.dfcIcon,
        'pageCoverUrl': ImageAssets.dfcHeroBg,
        'pageBannerUrl': ImageAssets.dfcHeroBg,
        'photoUrl': ImageAssets.dfcIcon,
        'coverPhotoUrl': ImageAssets.dfcHeroBg,
        'bannerUrl': ImageAssets.dfcHeroBg,
        'brandLogoUrl': ImageAssets.dfcIcon,
        'city': 'Gold Coast',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'datafightcentral',
        'displayName': 'Data Fight Central',
        'pageDisplayName': 'Data Fight Central',
        'role': 'admin',
        'pageBio':
            'The promoter of promoters. Platform distribution, analytics, campaigns, and community for combat sports.',
        'bio':
            'The promoter of promoters. Platform distribution, analytics, campaigns, and community for combat sports.',
        'pageAvatarUrl': ImageAssets.dfcBrandedPlaceholder,
        'pageCoverUrl': ImageAssets.dfcHeroBg,
        'pageBannerUrl': ImageAssets.dfcHeroBg,
        'photoUrl': ImageAssets.dfcBrandedPlaceholder,
        'coverPhotoUrl': ImageAssets.dfcHeroBg,
        'bannerUrl': ImageAssets.dfcHeroBg,
        'brandLogoUrl': ImageAssets.dfcBrandedPlaceholder,
        'city': 'Gold Coast',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'ibc_official',
        'displayName': 'International Brawling Championships',
        'pageDisplayName': 'International Brawling Championships',
        'role': 'promoter',
        'pageBio':
            'Official IBC page for Gold Coast brawling events, fight cards, and broadcast drops.',
        'bio':
            'Official IBC page for Gold Coast brawling events, fight cards, and broadcast drops.',
        'pageAvatarUrl': ImageAssets.ppvIbc03Thumb,
        'pageCoverUrl': ImageAssets.ppvIbc03Banner,
        'pageBannerUrl': ImageAssets.ppvIbc03Banner,
        'photoUrl': ImageAssets.ppvIbc03Thumb,
        'coverPhotoUrl': ImageAssets.ppvIbc03Banner,
        'bannerUrl': ImageAssets.ppvIbc03Banner,
        'city': 'Gold Coast',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'bkfc_official',
        'displayName': 'BKFC - Bare Knuckle Fighting Championship',
        'pageDisplayName': 'BKFC - Bare Knuckle Fighting Championship',
        'role': 'promoter',
        'pageBio':
            'Official BKFC page for Australian launch events, heavyweight rematches, and bare knuckle fight week.',
        'bio':
            'Official BKFC page for Australian launch events, heavyweight rematches, and bare knuckle fight week.',
        'pageAvatarUrl': ImageAssets.ppvBkfcTownsvilleHepiThumb,
        'pageCoverUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'pageBannerUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'photoUrl': ImageAssets.ppvBkfcTownsvilleHepiThumb,
        'coverPhotoUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'bannerUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'city': 'Townsville',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'bkfc_promotions',
        'displayName': 'BKFC',
        'pageDisplayName': 'BKFC',
        'role': 'promoter',
        'pageBio':
            'BKFC promotion channel for Townsville launch coverage, athlete storylines, and fight-week amplification.',
        'bio':
            'BKFC promotion channel for Townsville launch coverage, athlete storylines, and fight-week amplification.',
        'pageAvatarUrl': ImageAssets.ppvBkfcTownsvilleHepiThumb,
        'pageCoverUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'pageBannerUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'photoUrl': ImageAssets.ppvBkfcTownsvilleHepiThumb,
        'coverPhotoUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'bannerUrl': ImageAssets.ppvBkfcTownsvilleHepiBanner,
        'city': 'Townsville',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'ultimate_legends',
        'displayName': 'Ultimate Legends Promotions',
        'pageDisplayName': 'Ultimate Legends Promotions',
        'role': 'promoter',
        'pageBio':
            'Melbourne-based combat sports promotion founded by John Scida and Joey Demicoli.',
        'bio':
            'Melbourne-based combat sports promotion founded by John Scida and Joey Demicoli.',
        'pageAvatarUrl': ImageAssets.ppvUltimateLegends2026Thumb,
        'pageCoverUrl': ImageAssets.ppvUltimateLegends2026Banner,
        'pageBannerUrl': ImageAssets.ppvUltimateLegends2026Banner,
        'photoUrl': ImageAssets.ppvUltimateLegends2026Thumb,
        'coverPhotoUrl': ImageAssets.ppvUltimateLegends2026Banner,
        'bannerUrl': ImageAssets.ppvUltimateLegends2026Banner,
        'city': 'Melbourne',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'promoter_hex_fs',
        'displayName': 'Hex Fight Series',
        'pageDisplayName': 'Hex Fight Series',
        'role': 'promoter',
        'pageBio':
            'Hex Fight Series page for Melbourne cards, fighter applications, and UFC Fight Pass distribution.',
        'bio':
            'Hex Fight Series page for Melbourne cards, fighter applications, and UFC Fight Pass distribution.',
        'pageAvatarUrl': ImageAssets.ppvHex25Thumb,
        'pageCoverUrl': ImageAssets.ppvHex25Banner,
        'pageBannerUrl': ImageAssets.ppvHex25Banner,
        'photoUrl': ImageAssets.ppvHex25Thumb,
        'coverPhotoUrl': ImageAssets.ppvHex25Banner,
        'bannerUrl': ImageAssets.ppvHex25Banner,
        'city': 'Melbourne',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'promoter_eternal',
        'displayName': 'Eternal MMA',
        'pageDisplayName': 'Eternal MMA',
        'role': 'promoter',
        'pageBio':
            'Official Eternal MMA page for Gold Coast fight cards, recruitment, and event promotion.',
        'bio':
            'Official Eternal MMA page for Gold Coast fight cards, recruitment, and event promotion.',
        'pageAvatarUrl': ImageAssets.ppvEternal88Thumb,
        'pageCoverUrl': ImageAssets.ppvEternal88Banner,
        'pageBannerUrl': ImageAssets.ppvEternal88Banner,
        'photoUrl': ImageAssets.ppvEternal88Thumb,
        'coverPhotoUrl': ImageAssets.ppvEternal88Banner,
        'bannerUrl': ImageAssets.ppvEternal88Banner,
        'city': 'Gold Coast',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'ufc_news',
        'displayName': 'UFC News',
        'pageDisplayName': 'UFC News',
        'role': 'media',
        'pageBio':
            'Daily UFC results, matchmaking updates, and event analytics coverage for the DFC feed.',
        'bio':
            'Daily UFC results, matchmaking updates, and event analytics coverage for the DFC feed.',
        'pageAvatarUrl': ImageAssets.ppvUfcPerth2026Thumb,
        'pageCoverUrl': ImageAssets.ppvUfcPerth2026Banner,
        'pageBannerUrl': ImageAssets.ppvUfcPerth2026Banner,
        'photoUrl': ImageAssets.ppvUfcPerth2026Thumb,
        'coverPhotoUrl': ImageAssets.ppvUfcPerth2026Banner,
        'bannerUrl': ImageAssets.ppvUfcPerth2026Banner,
        'city': 'Las Vegas',
        'country': 'United States',
        'isVerified': true,
      },
      {
        'id': 'boxing_news',
        'displayName': 'Boxing News Global',
        'pageDisplayName': 'Boxing News Global',
        'role': 'media',
        'pageBio':
            'Global boxing headlines, title updates, and analytics-backed fight coverage.',
        'bio':
            'Global boxing headlines, title updates, and analytics-backed fight coverage.',
        'pageAvatarUrl': ImageAssets.ppvAdelaideCs12Thumb,
        'pageCoverUrl': ImageAssets.ppvAdelaideCs12Banner,
        'pageBannerUrl': ImageAssets.ppvAdelaideCs12Banner,
        'photoUrl': ImageAssets.ppvAdelaideCs12Thumb,
        'coverPhotoUrl': ImageAssets.ppvAdelaideCs12Banner,
        'bannerUrl': ImageAssets.ppvAdelaideCs12Banner,
        'city': 'London',
        'country': 'United Kingdom',
        'isVerified': true,
      },
      {
        'id': 'paramount_plus',
        'displayName': 'Paramount+ Australia',
        'pageDisplayName': 'Paramount+ Australia',
        'role': 'media',
        'pageBio':
            'Streaming destination for UFC, BKFC, and fight-night coverage across Australia.',
        'bio':
            'Streaming destination for UFC, BKFC, and fight-night coverage across Australia.',
        'pageAvatarUrl': ImageAssets.ppvUfcParamountFightnightThumb,
        'pageCoverUrl': ImageAssets.ppvUfcParamountFightnightBanner,
        'pageBannerUrl': ImageAssets.ppvUfcParamountFightnightBanner,
        'photoUrl': ImageAssets.ppvUfcParamountFightnightThumb,
        'coverPhotoUrl': ImageAssets.ppvUfcParamountFightnightBanner,
        'bannerUrl': ImageAssets.ppvUfcParamountFightnightBanner,
        'city': 'Sydney',
        'country': 'Australia',
        'isVerified': true,
      },
      {
        'id': 'christine_ferea',
        'displayName': 'Christine "Misfit" Ferea',
        'pageDisplayName': 'Christine "Misfit" Ferea',
        'role': 'fighter',
        'pageBio':
            'BKFC world champion, Misfit Mafia founder, and one of the defining names in women\'s bare knuckle.',
        'bio':
            'BKFC world champion, Misfit Mafia founder, and one of the defining names in women\'s bare knuckle.',
        'pageAvatarUrl': ImageAssets.ppvBkfc72Thumb,
        'pageCoverUrl': ImageAssets.ppvBkfc72Banner,
        'pageBannerUrl': ImageAssets.ppvBkfc72Banner,
        'photoUrl': ImageAssets.ppvBkfc72Thumb,
        'coverPhotoUrl': ImageAssets.ppvBkfc72Banner,
        'bannerUrl': ImageAssets.ppvBkfc72Banner,
        'city': 'Las Vegas',
        'country': 'United States',
        'isVerified': true,
      },
    ];

    for (final profile in profiles) {
      final data = Map<String, dynamic>.from(profile);
      final docId = data.remove('id') as String;
      batch.set(usersRef.doc(docId), data, SetOptions(merge: true));
    }

    await batch.commit();
    debugPrint('Seeded ${profiles.length} priority page profiles');
  }

  /// FULL SEED — Use only for initial demo setup or testing
  /// Run manually: DatabaseSeeder().seedAllDemoData();
  Future<void> seedAllDemoData() async {
    debugPrint('Seeding ALL demo data (for testing only)...');

    await _seedPriorityPageProfiles();
    await _seedGyms();
    await _seedFighter();
    await _seedStats();
    await _seedPosts();
    await _seedSubscriptionPlans();
    await _seedDemoEntitlements(userId: 'current_user');
    await _seedEvents();
    await _seedPromotions();
    await _seedHelpResources();
    await _seedPinkDiamondNetwork();
    await _seedFighterDatabank();
    await _seedFights();
    await _seedFightCardTemplates();
    await _seedNotifications();
    await _seedNewsArticles();
    await _seedMarketplaceItems();
    await _seedSocialAccounts();
    await _seedDroneRacing();

    debugPrint('Full demo seed completed!');
  }

  Future<void> _seedGyms() async {
    final gyms = [
      // 16 Best Muay Thai Gyms in Melbourne - Authentic Database
      {
        'name': 'Honour Martial Arts - Melbourne',
        'description':
            'Top-rated Muay Thai boxing gym with welcoming and knowledgeable coaching staff. Perfect 5.0 rating with 173 reviews. Uplifting community, no animosity, programs for all levels.',
        'address': '2/19 Edward St, Oakleigh VIC 3166, Australia',
        'phone': '+61 451 496 008',
        'website': 'honourmartialarts.com.au',
        'latitude': -37.9070,
        'longitude': 145.1170,
        'sportTypes': ['Muay Thai', 'Boxing'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 173,
        'memberCount': 320,
      },
      {
        'name': 'Absolute MMA (CBD)',
        'description':
            'Renowned martial arts club in Melbourne CBD. Professional coaches, central location, welcoming atmosphere. 4.9 rating, 140 reviews. MMA, Boxing, BJJ, Muay Thai.',
        'address': '136 Exhibition St, Melbourne VIC 3000, Australia',
        'phone': '+61 3 9663 9122',
        'website': 'absolutemma.com.au',
        'latitude': -37.8101,
        'longitude': 144.9687,
        'sportTypes': ['MMA', 'Boxing', 'BJJ', 'Muay Thai'],
        'status': 'active',
        'rating': 4.9,
        'reviewCount': 140,
        'memberCount': 380,
      },
      {
        'name': 'The Ring Gym',
        'description':
            'Premier Muay Thai boxing gym in Braybrook. Perfect 5.0 rating with 68 reviews. Dedicated experienced trainers, vibrant supportive community. Fighting & self-defense for all levels.',
        'address': 'Unit 4/75A Ashley St, Braybrook VIC 3019, Australia',
        'phone': '+61 438 797 477',
        'website': 'theringgym.com.au',
        'latitude': -37.8317,
        'longitude': 144.8635,
        'sportTypes': ['Muay Thai', 'Boxing', 'Self-Defense'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 68,
        'memberCount': 240,
      },
      {
        'name': 'JS Muay Thai',
        'description':
            'Premier gym in Footscray with 5.0 rating and 52 reviews. Knowledgeable and patient coaches. Empowering, inclusive community especially for women. Clean, well-maintained facility.',
        'address': '23 Ann St, Footscray VIC 3011, Australia',
        'phone': '+61 481 591 917',
        'website': 'jsmuaythai.com.au',
        'latitude': -37.8067,
        'longitude': 144.8903,
        'sportTypes': ['Muay Thai', 'Fitness'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 52,
        'memberCount': 185,
      },
      {
        'name': 'Kombat Cardio Boxing & Muay Thai',
        'description':
            'Top-notch gym with Coach Taza. 4.9 rating, 76 reviews. Personalized coaching, welcoming friendly community. Transform your fitness and skills with expert instruction.',
        'address':
            'Unit 12/14-26 Audsley St, Clayton South VIC 3169, Australia',
        'phone': '+61 466 908 849',
        'website': 'kombatcardio.com.au',
        'latitude': -37.9288,
        'longitude': 145.1654,
        'sportTypes': ['Boxing', 'Muay Thai', 'Cardio Fitness'],
        'status': 'active',
        'rating': 4.9,
        'reviewCount': 76,
        'memberCount': 210,
      },
      {
        'name': 'Absolute MMA (Collingwood)',
        'description':
            'Renowned martial arts club in Collingwood. 4.8 rating with 93 reviews. World-class coaches (Simon, Oli, Sam). Inclusive environment for all levels. High safety emphasis.',
        'address': '134 Cromwell St, Collingwood VIC 3066, Australia',
        'phone': '+61 3 9663 9122',
        'website': 'absolutemma.com.au',
        'latitude': -37.8016,
        'longitude': 144.9918,
        'sportTypes': ['MMA', 'Boxing', 'BJJ', 'Muay Thai'],
        'status': 'active',
        'rating': 4.8,
        'reviewCount': 93,
        'memberCount': 350,
      },
      {
        'name': 'Unite Muaythai Gym',
        'description':
            'Premier Muay Thai boxing gym in Ormond. Perfect 5.0 rating with 21 reviews. Friendly atmosphere, professional trainers, excellent feedback. Best gym experience.',
        'address': '667A North Rd, Ormond VIC 3204, Australia',
        'phone': '+61 413 515 905',
        'website': 'unitemuaythaigym.com.au',
        'latitude': -37.9475,
        'longitude': 145.1041,
        'sportTypes': ['Muay Thai', 'Boxing'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 21,
        'memberCount': 155,
      },
      {
        'name': 'Melbourne Muay Thai Academy (MMTA)',
        'description':
            'Premier Muay Thai boxing gym in Epping. 5.0 rating with 20 reviews. Knowledgeable experienced trainers. Great environment for all skill levels. Strong community camaraderie.',
        'address': 'Unit 1/31 Constance Ct, Epping VIC 3076, Australia',
        'phone': '+61 400 668 244',
        'website': 'instagram.com',
        'latitude': -37.7280,
        'longitude': 145.0868,
        'sportTypes': ['Muay Thai', 'Boxing'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 20,
        'memberCount': 175,
      },
      {
        'name': 'Khaoboy Muaythai',
        'description':
            'Renowned Muay Thai boxing gym in Carnegie. 4.9 rating with 27 reviews. Best atmosphere and people. Tailored classes for all skill levels. Supportive and friendly community.',
        'address': '396 Neerim Rd, Carnegie VIC 3163, Australia',
        'phone': '+61 455 219 960',
        'website': 'khaoboymuaythai.com.au',
        'latitude': -37.9145,
        'longitude': 145.0715,
        'sportTypes': ['Muay Thai', 'Kickboxing'],
        'status': 'active',
        'rating': 4.9,
        'reviewCount': 27,
        'memberCount': 165,
      },
      {
        'name': 'Dynamite Muay Thai',
        'description':
            'Premier Muay Thai boxing gym in Melbourne CBD. 4.7 rating with 52 reviews. Expert coaches (Kru Dennis, Lily, Zia). Focuses on teamwork, respect, personalized coaching. Found community here.',
        'address': 'Level 1/388 Bourke St, Melbourne VIC 3000, Australia',
        'phone': '+61 3 9041 7241',
        'website': 'dynamitemuaythai.com',
        'latitude': -37.8157,
        'longitude': 144.9697,
        'sportTypes': ['Muay Thai', 'Boxing', 'Fitness'],
        'status': 'active',
        'rating': 4.7,
        'reviewCount': 52,
        'memberCount': 295,
      },
      {
        'name': 'Sukhari Muay Thai',
        'description':
            'Premier Muay Thai boxing gym in Preston. Perfect 5.0 rating with 6 reviews. Knowledgeable positive trainers. Warm welcoming community for beginners and experts. Authentic techniques.',
        'address': 'Level 2/2 Albert St, Preston VIC 3072, Australia',
        'phone': '+61 406 035 767',
        'website': 'sukharimuaythai.com',
        'latitude': -37.7631,
        'longitude': 145.0271,
        'sportTypes': ['Muay Thai', 'Boxing'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 6,
        'memberCount': 120,
      },
      {
        'name': 'Hongthong Muay Thai Australia',
        'description':
            'Renowned martial arts school in Campbellfield. Perfect 5.0 rating with 5 reviews. Kru Gen Hongthonglek - living legend. Authentic Thai training experience. Highly dedicated trainers.',
        'address': 'Unit 3/85 Cooper St, Campbellfield VIC 3061, Australia',
        'phone': '+61 404 531 065',
        'website': 'hongthongaus.com.au',
        'latitude': -37.6972,
        'longitude': 144.9919,
        'sportTypes': ['Muay Thai', 'Boxing'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 5,
        'memberCount': 140,
      },
      {
        'name': 'Crunch Fitness Richmond Gym',
        'description':
            'Popular fitness center in Richmond. 4.4 rating with 149 reviews. Spacious with state-of-the-art equipment. Separate workout areas, large free weights, friendly staff. 24/7 access.',
        'address': '101 Palmer St, Richmond VIC 3121, Australia',
        'phone': '+61 3 8692 8106',
        'website': 'crunch.com.au',
        'latitude': -37.8214,
        'longitude': 145.0031,
        'sportTypes': ['Fitness', 'Boxing', 'Muay Thai', 'Cardio', 'Strength'],
        'status': 'active',
        'rating': 4.4,
        'reviewCount': 149,
        'memberCount': 450,
      },
      {
        'name': 'Supafight Gym',
        'description':
            'Premier boxing gym in St Kilda. 4.6 rating with 34 reviews. Authentic Thai-style classes. Wide variety of class times. Don is expert fighter & coach. Great community and vibes.',
        'address': '85 Inkerman St, St Kilda VIC 3182, Australia',
        'phone': '+61 402 691 979',
        'website': 'supafightgym.com.au',
        'latitude': -37.8723,
        'longitude': 145.0052,
        'sportTypes': ['Boxing', 'Muay Thai', 'Kickboxing'],
        'status': 'active',
        'rating': 4.6,
        'reviewCount': 34,
        'memberCount': 190,
      },
      {
        'name': 'Melbourne Fight Club - Martial Arts Academy',
        'description':
            'Renowned martial arts school in Melbourne CBD. 4.2 rating with 102 reviews. Muay Thai, Boxing, BJJ, Karate. Welcoming and supportive staff & trainers. Great for families.',
        'address': '9&10/367 Flinders St, Melbourne VIC 3000, Australia',
        'phone': '+61 3 9620 5433',
        'website': 'melbmartialarts.com.au',
        'latitude': -37.8163,
        'longitude': 144.9588,
        'sportTypes': ['Muay Thai', 'Boxing', 'BJJ', 'Karate'],
        'status': 'active',
        'rating': 4.2,
        'reviewCount': 102,
        'memberCount': 320,
      },
      {
        'name': 'Club Lime Express Fitzroy',
        'description':
            '24/7 gym in Fitzroy. 3.0 rating with 6 reviews. Open all hours every day. Clean and tidy with great variety of equipment. Gymnastic rings, dumbbells available.',
        'address': '187 Johnston St, Fitzroy VIC 3065, Australia',
        'phone': '+61 131244',
        'website': 'clublime.com.au',
        'latitude': -37.8000,
        'longitude': 144.9824,
        'sportTypes': ['Fitness', 'General Gym'],
        'status': 'active',
        'rating': 3.0,
        'reviewCount': 6,
        'memberCount': 280,
      },
      // BRISBANE BOXING & MMA GYMS
      {
        'name': 'Fortitude Valley Boxing Co',
        'description':
            'Premier boxing & MMA gym in Brisbane city. World-class trainers, competitive atmosphere. 4.9 rating with 187 reviews. Professional fighters training daily. Sparring rings, strength room.',
        'address': '100 Wickham St, Fortitude Valley QLD 4006, Australia',
        'phone': '+61 7 3012 5555',
        'website': 'fortitudeboxing.com.au',
        'latitude': -27.4568,
        'longitude': 153.0350,
        'sportTypes': ['Boxing', 'MMA', 'Strength & Conditioning'],
        'status': 'active',
        'rating': 4.9,
        'reviewCount': 187,
        'memberCount': 450,
      },
      {
        'name': 'Southside MMA Brisbane',
        'description':
            'Elite MMA training facility in Mount Gravatt. 4.8 rating with 156 reviews. Multiple cage setups, professional conditioning. Specializes in fighter development. Team atmosphere.',
        'address': '45 Wills St, Mount Gravatt QLD 4122, Australia',
        'phone': '+61 7 3342 8899',
        'website': 'southsidemma.com.au',
        'latitude': -27.5438,
        'longitude': 153.0865,
        'sportTypes': ['MMA', 'Boxing', 'BJJ', 'Wrestling'],
        'status': 'active',
        'rating': 4.8,
        'reviewCount': 156,
        'memberCount': 380,
      },
      {
        'name': 'Northside Combat Sports Academy',
        'description':
            'Premier combat academy in Aspley. All disciplines: boxing, MMA, BJJ, wrestling. 4.7 rating with 142 reviews. Professional coaching staff. Strong amateur fighter pipeline.',
        'address': '78 Zillman Rd, Aspley QLD 4034, Australia',
        'phone': '+61 7 3863 2211',
        'website': 'northsidecombat.com.au',
        'latitude': -27.4089,
        'longitude': 153.0456,
        'sportTypes': ['MMA', 'Boxing', 'BJJ', 'Kickboxing'],
        'status': 'active',
        'rating': 4.7,
        'reviewCount': 142,
        'memberCount': 320,
      },
      {
        'name': 'West End Boxing Club',
        'description':
            'Iconic boxing heritage gym in West End. Classic training environment with modern equipment. 4.6 rating with 128 reviews. Fed multiple title holders. Strong community.',
        'address': '12-14 Vulture St, West End QLD 4101, Australia',
        'phone': '+61 7 3846 7722',
        'website': 'westendboxing.com.au',
        'latitude': -27.4798,
        'longitude': 152.9978,
        'sportTypes': ['Boxing', 'Amateur Boxing'],
        'status': 'active',
        'rating': 4.6,
        'reviewCount': 128,
        'memberCount': 290,
      },
      {
        'name': 'Strikeforce MMA Loganholme',
        'description':
            'World-class MMA facility south Brisbane. Competition-ready gyms, pro team on site. 4.9 rating with 163 reviews. Develops international fighters.',
        'address': '89 Tambourine St, Loganholme QLD 4129, Australia',
        'phone': '+61 7 3209 1188',
        'website': 'strikeforcemma.com.au',
        'latitude': -27.6145,
        'longitude': 153.0923,
        'sportTypes': ['MMA', 'Boxing', 'BJJ', 'Muay Thai'],
        'status': 'active',
        'rating': 4.9,
        'reviewCount': 163,
        'memberCount': 410,
      },
      {
        'name': 'City Boxing Gym - Brisbane CBD',
        'description':
            'Central Brisbane boxing authority. Boxing-focused, pro fighters. 4.5 rating with 109 reviews. Modern facilities in CBD. Walk-in welcome.',
        'address': '300 Queen St, Brisbane QLD 4000, Australia',
        'phone': '+61 7 3221 4455',
        'website': 'cityboxing.com.au',
        'latitude': -27.4746,
        'longitude': 153.0277,
        'sportTypes': ['Boxing', 'Fitness'],
        'status': 'active',
        'rating': 4.5,
        'reviewCount': 109,
        'memberCount': 260,
      },
      {
        'name': 'Cannon Combat - Waterloo',
        'description':
            'MMA & kickboxing powerhouse in Waterloo. Authentic Muay Thai, kickboxing instruction. 4.8 rating with 139 reviews. International fighter exchange.',
        'address': '23 Warragul Ave, Waterloo QLD 4135, Australia',
        'phone': '+61 7 3208 5966',
        'website': 'cannoncombat.com.au',
        'latitude': -27.6020,
        'longitude': 153.1234,
        'sportTypes': ['MMA', 'Kickboxing', 'Muay Thai', 'Boxing'],
        'status': 'active',
        'rating': 4.8,
        'reviewCount': 139,
        'memberCount': 340,
      },
      {
        'name': 'Annerley Boxing & MMA',
        'description':
            'Balanced gym for boxing and MMA. 4.7 rating with 121 reviews. Family-friendly, professional program. Active amateur team.',
        'address': '156 Annerley Rd, Annerley QLD 4103, Australia',
        'phone': '+61 7 3848 9123',
        'website': 'annermoyboxing.com.au',
        'latitude': -27.5234,
        'longitude': 152.9867,
        'sportTypes': ['Boxing', 'MMA'],
        'status': 'active',
        'rating': 4.7,
        'reviewCount': 121,
        'memberCount': 275,
      },
      {
        'name': 'Fight Factory Gym - Stones Corner',
        'description':
            'Combat sports facility in Stones Corner. Boxing, kickboxing, conditioning. 4.6 rating with 114 reviews. Strong group classes.',
        'address': '67 Bowman Parade, Stones Corner QLD 4120, Australia',
        'phone': '+61 7 3394 2211',
        'website': 'fightfactory.com.au',
        'latitude': -27.5389,
        'longitude': 153.0612,
        'sportTypes': ['Boxing', 'Kickboxing', 'Fitness'],
        'status': 'active',
        'rating': 4.6,
        'reviewCount': 114,
        'memberCount': 245,
      },
      {
        'name': 'Intensity MMA - Sunnybank',
        'description':
            'High-intensity MMA training. Professional cage, sparring partners. 4.8 rating with 147 reviews. Fighter development focus.',
        'address': '34 Glenlyon St, Sunnybank QLD 4109, Australia',
        'phone': '+61 7 3162 7788',
        'website': 'intensitymma.com.au',
        'latitude': -27.5567,
        'longitude': 153.0745,
        'sportTypes': ['MMA', 'Boxing', 'BJJ'],
        'status': 'active',
        'rating': 4.8,
        'reviewCount': 147,
        'memberCount': 355,
      },
      {
        'name': 'Knockout Gym - Chermside',
        'description':
            'Northside boxing facility. Traditional boxing environment with pro trainers. 4.5 rating with 98 reviews. Competition-ready gym.',
        'address': '112 Hamilton Rd, Chermside QLD 4032, Australia',
        'phone': '+61 7 3359 6644',
        'website': 'knockoutgymbne.com.au',
        'latitude': -27.3978,
        'longitude': 153.0534,
        'sportTypes': ['Boxing', 'Amateur'],
        'status': 'active',
        'rating': 4.5,
        'reviewCount': 98,
        'memberCount': 215,
      },
      // NEW ZEALAND BOXING & MMA GYMS
      {
        'name': 'City Kickboxing Auckland',
        'description':
            'Premier kickboxing & MMA gym in central Auckland. World-class facility, professional fighters. 5.0 rating with 201 reviews. International reputation.',
        'address': '6 Greys Ave, Auckland 1010, New Zealand',
        'phone': '+64 9 308 4129',
        'website': 'citykickboxing.co.nz',
        'latitude': -37.7751,
        'longitude': 174.7628,
        'sportTypes': ['Kickboxing', 'MMA', 'BJJ'],
        'status': 'active',
        'rating': 5.0,
        'reviewCount': 201,
        'memberCount': 480,
      },
      {
        'name': 'SBG Auckland (Strong Body Gym)',
        'description':
            'Elite Brazilian Jiu-Jitsu & MMA in Auckland. Renowned coaches, fighter pipeline. 4.9 rating with 178 reviews. Sister gym to elite international teams.',
        'address': '13 Heather St, Auckland 1010, New Zealand',
        'phone': '+64 9 301 3955',
        'website': 'sbgauckland.co.nz',
        'latitude': -37.7834,
        'longitude': 174.7601,
        'sportTypes': ['BJJ', 'MMA', 'Boxing'],
        'status': 'active',
        'rating': 4.9,
        'reviewCount': 178,
        'memberCount': 420,
      },
      {
        'name': 'Panther Gym - West Auckland',
        'description':
            'Boxing powerhouse in West Auckland. Professional boxing gym, amateur team. 4.7 rating with 134 reviews. Strong winning culture.',
        'address': '234 Great North Rd, Henderson NZ 0610, New Zealand',
        'phone': '+64 9 838 7721',
        'website': 'panthergym.co.nz',
        'latitude': -37.8234,
        'longitude': 174.6456,
        'sportTypes': ['Boxing', 'Amateur Boxing'],
        'status': 'active',
        'rating': 4.7,
        'reviewCount': 134,
        'memberCount': 310,
      },
      {
        'name': 'Southern Cross MMA - Wellington',
        'description':
            'Capital city MMA hub. Full combat sports program. 4.8 rating with 156 reviews. Wellington fighter talent center.',
        'address': '45 Taranaki St, Wellington 6011, New Zealand',
        'phone': '+64 4 384 3621',
        'website': 'southernxmma.co.nz',
        'latitude': -41.2865,
        'longitude': 174.7762,
        'sportTypes': ['MMA', 'Boxing', 'Kickboxing'],
        'status': 'active',
        'rating': 4.8,
        'reviewCount': 156,
        'memberCount': 340,
      },
      {
        'name': 'Christchurch Combat Club',
        'description':
            'South Island MMA & boxing. Comprehensive family-friendly facility. 4.6 rating with 128 reviews. Community first approach.',
        'address': '89 Barbadoes St, Christchurch 8013, New Zealand',
        'phone': '+64 3 366 4466',
        'website': 'chchcombat.co.nz',
        'latitude': -43.5320,
        'longitude': 172.6362,
        'sportTypes': ['MMA', 'Boxing', 'BJJ'],
        'status': 'active',
        'rating': 4.6,
        'reviewCount': 128,
        'memberCount': 290,
      },
      {
        'name': 'Golden Dragon Muay Thai Auckland',
        'description':
            'Authentic Muay Thai & kickboxing in Auckland. Thai coaches, genuine training. 4.8 rating with 142 reviews. Strong competition record.',
        'address': '178 Ponsonby Rd, Ponsonby, Auckland 1011, NZ',
        'phone': '+64 9 376 5121',
        'website': 'tigermuaythai.co.nz',
        'latitude': -37.7923,
        'longitude': 174.7412,
        'sportTypes': ['Muay Thai', 'Kickboxing'],
        'status': 'active',
        'rating': 4.8,
        'reviewCount': 142,
        'memberCount': 325,
      },
      {
        'name': 'Waikato MMA - Hamilton',
        'description':
            'Waikato region combat hub. MMA, boxing, wrestling program. 4.7 rating with 119 reviews. Growing amateur team.',
        'address': '12 Anglesea St, Hamilton 3204, New Zealand',
        'phone': '+64 7 839 3344',
        'website': 'waikatamma.co.nz',
        'latitude': -37.7870,
        'longitude': 175.2793,
        'sportTypes': ['MMA', 'Boxing', 'Wrestling'],
        'status': 'active',
        'rating': 4.7,
        'reviewCount': 119,
        'memberCount': 280,
      },
      {
        'name': 'North Shore Boxing Club - Auckland',
        'description':
            'Premium North Shore boxing facility. Professional boxing environment. 4.5 rating with 97 reviews. Quality trainers.',
        'address': '301 Lake Rd, Takapuna, Auckland 0622, NZ',
        'phone': '+64 9 486 1211',
        'website': 'northshoreboxing.co.nz',
        'latitude': -37.7667,
        'longitude': 174.7889,
        'sportTypes': ['Boxing', 'Amateur'],
        'status': 'active',
        'rating': 4.5,
        'reviewCount': 97,
        'memberCount': 240,
      },
      {
        'name': 'Tauranga Combat - Bay of Plenty',
        'description':
            'Bay of Plenty combat sports center. MMA & boxing for all levels. 4.6 rating with 105 reviews. Growing community.',
        'address': '67 Cameron Rd, Tauranga 3110, New Zealand',
        'phone': '+64 7 571 4455',
        'website': 'taurangacombat.co.nz',
        'latitude': -37.6880,
        'longitude': 176.1645,
        'sportTypes': ['MMA', 'Boxing'],
        'status': 'active',
        'rating': 4.6,
        'reviewCount': 105,
        'memberCount': 215,
      },
      {
        'name': 'Dunedin MMA Academy',
        'description':
            'Southern athlete hub. MMA, boxing, BJJ. 4.7 rating with 113 reviews. Development focus for young fighters.',
        'address': '45 Princes St, Dunedin 9016, New Zealand',
        'phone': '+64 3 477 5588',
        'website': 'dunedimmaa.co.nz',
        'latitude': -45.8788,
        'longitude': 170.5028,
        'sportTypes': ['MMA', 'Boxing', 'BJJ'],
        'status': 'active',
        'rating': 4.7,
        'reviewCount': 113,
        'memberCount': 220,
      },
    ];

    for (var gym in gyms) {
      await _firestore.collection('gyms').add(gym);
    }
    debugPrint('Seeded ${gyms.length} gyms');
  }

  Future<void> _seedFighter() async {
    await _seedFighterForUser('current_user');
  }

  Future<void> _seedFighterForUser(String userId, {String? displayName}) async {
    await _firestore.collection('fighters').doc(userId).set({
      'userId': userId,
      'fullName': displayName ?? 'Alex "The Shadow" Silva',
      'nickname': 'The Shadow',
      'nationality': 'Australia',
      'weightClass': 'Lightweight',
      'sportType': 'MMA',
      'stance': 'orthodox',
      'status': 'active',
      'heightCm': 178.0,
      'reachCm': 183.0,
      'wins': 12,
      'losses': 2,
      'draws': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Seeded fighter profile for $userId');
  }

  Future<void> _seedStats() async {
    await _seedStatsForUser('current_user');
  }

  Future<void> _seedStatsForUser(String userId) async {
    final now = DateTime.now();
    await _firestore.collection('fighter_stats').doc(userId).set({
      'totalSparringMinutes': 2520, // 42 hours
      'totalStrikesLanded': 1240,
      'totalStrikesThrown': 2100,
      'totalTakedowns': 87,
      'winRate': 0.85,
      'avgRoundTime': 4.2,
      'lastUpdated': FieldValue.serverTimestamp(),
      'performanceHistory': [
        {
          'date': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
          'rating': 3.5,
        },
        {
          'date': Timestamp.fromDate(now.subtract(const Duration(days: 25))),
          'rating': 4.0,
        },
        {
          'date': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
          'rating': 3.8,
        },
        {
          'date': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
          'rating': 4.5,
        },
        {
          'date': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
          'rating': 4.2,
        },
        {
          'date': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
          'rating': 4.8,
        },
        {'date': Timestamp.now(), 'rating': 5.0},
      ],
    });
    debugPrint('Seeded fighter stats for $userId');
  }

  Future<void> _seedPosts() async {
    final posts = [
      // ═══════════════════════════════════════════════════════════════
      // GOLD COAST BRAWLING EVENT — MARCH 7 2026
      // DFC EDITORIAL COVERAGE — Third-party event reporting
      // ═══════════════════════════════════════════════════════════════
      {
        'authorId': 'dfc_combat_news',
        'authorName': 'DFC Combat News',
        'content':
            '🩸 GOLD COAST FIGHT NIGHT — TONIGHT 🇦🇺⚔️\n\n'
            'Stand-up brawling returns to the Gold Coast — stacked card of Aussie warriors.\n\n'
            '🏟️ Gold Coast Sports & Leisure Centre\n'
            '🎫 Limited tickets remaining\n\n'
            '🔥 FULL FIGHT CARD:\n'
            '🥊 MAIN EVENT: Cutler vs Modini\n'
            '🥊 Hardman vs Tuhu — Middleweight Title\n'
            '🥊 Corban "The Curse" Mita vs Josh Eccles\n'
            '🥊 Jay "Spoox" Hepi vs Sydney Halcrow\n'
            '🥊 Petaia Samasoni vs Selwyn Alexander\n'
            '🥊 Stevens vs Hull\n\n'
            'No wrestling. No ground game. Pure stand-up warfare. ☠️\n\n'
            '#GoldCoast #FightNight #Brawling #CombatSports #DFC',
        'type': 'announcement',
        'likes': 1247,
        'comments': 389,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      },
      {
        'authorId': 'dfc_combat_news',
        'authorName': 'DFC Combat News',
        'content':
            '😤 Hepi and Halcrow are ALL BUSINESS tonight.\n\n'
            'Jay "Spoox" Hepi says the Hepi name stands firm — looking for 3-0. '
            'Sydney Halcrow has other plans. This one is PERSONAL. 🔥\n\n'
            'Weigh-ins were HEATED. Tonight will be on a whole other level 👀\n\n'
            '#HepiHalcrow #GoldCoast #Brawling',
        'type': 'text',
        'likes': 456,
        'comments': 87,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      {
        'authorId': 'dfc_combat_news',
        'authorName': 'DFC Combat News',
        'content':
            '💥 Haze "The Huntsman" Hepi is hyped to see brothers Jay and Spencer take centre stage tonight on the Gold Coast.\n\n'
            '"These boys are the real deal." 🫡\n\n'
            'Isaac Hardman returns against Jonathan Tuhu — first round KO last time out was a showstopper. '
            'Can Tuhu survive the rematch? 😵‍💫\n\n'
            '#Hardman #IsaacHardman #GoldCoast #KnockoutArtist',
        'type': 'text',
        'likes': 892,
        'comments': 156,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 3)),
        ),
      },
      {
        'authorId': 'dfc_combat_news',
        'authorName': 'DFC Combat News',
        'content':
            '🗡️ STAND-UP ONLY. NOWHERE TO HIDE. ⛓️\n\n'
            'Brawling events are surging across AU/NZ — '
            'world-class strikers in a compact arena with no ground game allowed. '
            '4oz gloves. Pure violence. Nothing nice. 🩸\n\n'
            'Broadcasting deals locking in across AU and NZ. '
            'Respected American fighters reaching out to compete down under. '
            'Stand-up combat sports in Australia are HERE TO STAY. 💪⚔️🔥\n\n'
            '#Brawling #CombatSports #StandUp #AussieFighting #DFC',
        'type': 'announcement',
        'likes': 2134,
        'comments': 467,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 4)),
        ),
      },
      {
        'authorId': 'dfc_combat_news',
        'authorName': 'DFC Combat News',
        'content':
            '🔒 MAIN EVENT LOCKED IN — Cutler vs Modini 💀\n\n'
            'A litmus test like no other. Two warriors. No escape.\n\n'
            'All respect at weigh-ins today 🫡 but come fight night — pure business.\n\n'
            'Corban "The Curse" Mita vs Josh Eccles is SET and OFFICIAL — '
            '"Can\'t wait to throw down. Let\'s steal the show brother" 🫡\n\n'
            '#CutlerModini #TheCurse #GoldCoast #FightNight',
        'type': 'text',
        'likes': 678,
        'comments': 134,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
      },

      // ═══════════════════════════════════════════════════════════════
      // DFC PROMOTES PROMOTIONS — THE PROMOTER'S BEST FRIEND
      // ═══════════════════════════════════════════════════════════════

      // ═══════════════════════════════════════════════════════════════
      // BKFC FIGHT NIGHT AUSTRALIA — APRIL 18 2026 — TOWNSVILLE
      // ═══════════════════════════════════════════════════════════════
      {
        'authorId': 'bkfc_official',
        'authorName': 'BKFC - Bare Knuckle Fighting Championship',
        'content':
            '🥊 BKFC FIGHT NIGHT AUSTRALIA — APRIL 18 — TOWNSVILLE 🇦🇺\n\n'
            'BARE KNUCKLE FIGHTING CHAMPIONSHIP makes its AUSTRALIAN DEBUT!\n\n'
            '🏟️ Townsville Entertainment & Convention Centre\n'
            '📅 Friday April 18, 2026 — 7:00 PM AEST\n'
            '🎫 Tickets at BKFC.com\n'
            '📺 LIVE on watch.bkfc.com\n\n'
            '🔥 MAIN EVENT:\n'
            'Haze "The Huntsman" Hepi vs Krzysztof "The Big Man" Wisniewski\n'
            'Heavyweight Rematch — 5 Rounds — Bare Knuckle\n\n'
            'Doctor stoppage R3 at BKFC 83 Rome. Both demanded the rematch. '
            'Hepi brings the Pacific Islander power. Wisniewski brings Polish steel. '
            'This time it ends with a KO. 💀\n\n'
            'ALSO FEATURING:\n'
            '🥊 Mark Flanagan (24-7, 17KOs boxing) — bare knuckle debut!\n'
            '   Former WBA cruiserweight title challenger\n'
            '🥊 Sam Soliman — the ageless warrior returns\n'
            '🥊 BK Bau — Aussie brawler looking for blood\n'
            '🥊 Full undercard of Australian bare knuckle talent\n\n'
            '#BKFC #BareKnuckle #HepiWisniewski #Townsville #FightNightAustralia #MarkFlanagan',
        'type': 'announcement',
        'likes': 3456,
        'comments': 892,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      },
      {
        'authorId': 'bkfc_official',
        'authorName': 'BKFC - Bare Knuckle Fighting Championship',
        'content':
            '🇳🇿🔥 HAZE HEPI — THE HUNTSMAN — READY FOR WAR\n\n'
            '"Last time the doctor stopped it. This time I finish it myself. '
            'Wisniewski is tough — I respect that — but when you\'re from the islands, '
            'you don\'t need a doctor to tell you when to stop. You stop when your opponent drops." 🫡\n\n'
            'Hepi (3-1 BKFC) carries the mana of Logan, New Zealand. Every Pacific Islander '
            'in Queensland will be at the Townsville Entertainment Centre on April 18. '
            'This is bigger than a fight — this is culture. 🌺\n\n'
            '📺 PPV on DFC + watch.bkfc.com/videos/697\n\n'
            '#HazeHepi #TheHuntsman #BKFC #Townsville #IslanderPride #BareKnuckle',
        'type': 'text',
        'likes': 2134,
        'comments': 567,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      {
        'authorId': 'bkfc_official',
        'authorName': 'BKFC - Bare Knuckle Fighting Championship',
        'content':
            '🇵🇱 KRZYSZTOF WISNIEWSKI — THE BIG MAN — UNFINISHED BUSINESS\n\n'
            '"The doctor took that fight from both of us. I was winning. '
            'Hepi knows it. I know it. April 18 we settle it the right way — '
            'on our feet, bare knuckle, no stoppages until one man can\'t stand." 💀\n\n'
            'Wisniewski (3-0 BKFC) has NEVER been beaten. The Polish heavyweight '
            'flew from Rome to Townsville to prove a point. This is personal.\n\n'
            '#KrzysztofWisniewski #TheBigMan #BKFC #Poland #Heavyweight #BareKnuckle',
        'type': 'text',
        'likes': 1876,
        'comments': 423,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 3)),
        ),
      },
      {
        'authorId': 'bkfc_official',
        'authorName': 'BKFC - Bare Knuckle Fighting Championship',
        'content':
            '🥊 MARK FLANAGAN — "BAM BAM" — BARE KNUCKLE DEBUT 🇦🇺\n\n'
            'Former WBA cruiserweight title challenger Mark "Bam Bam" Flanagan (24-7, 17KOs) '
            'makes his bare knuckle debut on April 18 in Townsville!\n\n'
            '"I\'ve fought for world titles in boxing. I\'ve knocked out men in arenas around the world. '
            'But bare knuckle? This is the rawest form of combat. No gloves. No hiding. '
            'I\'m here to prove Australian fighters are the toughest on earth." 🫡\n\n'
            'Flanagan brings elite boxing pedigree to the BKFC ring. '
            'His opponent TBA — but whoever steps up better be ready for 17KOs worth of power '
            'delivered with bare fists. 💀\n\n'
            '#MarkFlanagan #BamBam #BareKnuckleDebut #BKFC #Townsville #Boxing',
        'type': 'text',
        'likes': 1234,
        'comments': 298,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 4)),
        ),
      },
      {
        'authorId': 'dfc_official',
        'authorName': 'Data Fight Central',
        'content':
            '📢 DFC x BKFC — OFFICIAL PPV PARTNER\n\n'
            'Data Fight Central is proud to announce our partnership with Bare Knuckle Fighting Championship '
            'for BKFC FIGHT NIGHT AUSTRALIA — Townsville, April 18 2026.\n\n'
            '📺 Stream LIVE on DFC + watch.bkfc.com\n'
            '🎟️ PPV available now — \$29.99 AUD\n'
            '📊 Live scoring on DFC during every fight\n'
            '💬 Command Chat — real-time fan reactions\n'
            '🎬 DFC Octane promo videos for all fighters\n\n'
            'BKFC trusts DFC to deliver their Australian debut to the world. '
            'We promote promotions — and BKFC chose the best. 💪\n\n'
            '#DFC #BKFC #PPV #Townsville #BareKnuckle #DataFightCentral #PromotePromotions',
        'type': 'announcement',
        'likes': 2678,
        'comments': 512,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      },

      {
        'authorId': 'dfc_official',
        'authorName': 'Data Fight Central',
        'content':
            '📣 DATA FIGHT CENTRAL IS THE PROMOTER\'S BEST FRIEND\n\n'
            'We\'re not Facebook. We\'re not Instagram. We\'re not a generic social platform where your fight promo competes with cat videos and cooking reels.\n\n'
            'DFC is built BY combat sports, FOR combat sports. When you promote on DFC — WE promote YOU.\n\n'
            '🔥 WHAT PROMOTERS GET ON DFC:\n\n'
            '🎬 DFC Octane Video Editor — Drop 6 fighter photos, get a cinematic 15/20-second promo video. 6 themes. 6 transitions. Custom text overlays. One-click export. No editing software needed.\n\n'
            '🖼️ DFC Image Machine — Fight posters, event flyers, social media graphics. Professional grade. Generated on-platform in seconds.\n\n'
            '📋 Fight Card Builder — Full digital fight cards with matchups, weights, records. Auto-formatted. Share anywhere.\n\n'
            '📺 PPV Streaming — Sell and stream your events live. No middleman. You keep the revenue.\n\n'
            '⚖️ Live Scoring — Real-time judging for every fight on your card.\n\n'
            '📊 Promoter Dashboard — Manage your entire event: fighters, matchups, weigh-ins, results, ticket tracking.\n\n'
            '📢 Marketing HQ — Campaign tools, not just posts and prayers. Targeted reach to COMBAT SPORTS FANS.\n\n'
            '🤝 Sponsor Hub — Manage sponsorship deals in one place. Connect brands with your events.\n\n'
            '🤖 Promoter AI — Intelligent event optimisation. Pricing, scheduling, matchup analysis.\n\n'
            '🔗 QR Promo Codes — Scannable codes linking direct to tickets, PPV, and event pages.\n\n'
            'On Facebook you upload and YOU do all the work. On DFC — WE do the work. We promote promote and PROMOTE. Extra promotions. Extra tools. Extra reach. We get you OUT THERE.\n\n'
            'Tonight the Gold Coast lights up with stand-up brawling action — and DFC is right there promoting it. That\'s what we do. We promote promotions.\n\n'
            '💪 www.datafightcentral.com — The world\'s most advanced combat sports platform.\n\n'
            '#DataFightCentral #DFC #PromotePromotions #FightPromotion #CombatSports #PromoterTools #FightNight',
        'type': 'announcement',
        'likes': 1876,
        'comments': 342,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      {
        'authorId': 'dfc_official',
        'authorName': 'Data Fight Central',
        'content':
            '⚔️ DFC — GOLD COAST FIGHT NIGHT COVERAGE\n\n'
            'Data Fight Central is covering tonight\'s stand-up brawling event live from the Gold Coast Sports & Leisure Centre 🇦🇺🔥\n\n'
            'THIS is what DFC was built for — the worldwide gateway portal. Aussie shows broadcast to America and beyond. The world is watching. Every promoter gets the full collaboration.\n\n'
            '🎫 Last tickets still available\n\n'
            'Brawling events in Australia are growing fast — from grassroots to worldwide broadcast. DFC is the gateway that connects Aussie promotions to global audiences.\n\n'
            'Cutler vs Modini. Hardman vs Tuhu. Mita vs Eccles. Hepi vs Halcrow. Samasoni vs Alexander. Stevens vs Hull.\n\n'
            'Stand-up only. Nowhere to hide. TONIGHT. ☠️\n\n'
            '#DFC #GoldCoast #Brawling #FightNight #DataFightCentral',
        'type': 'announcement',
        'likes': 1543,
        'comments': 278,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      },

      // FIGHTER WELFARE & SAFETY FIRST
      {
        'authorId': 'dfc_wellness',
        'authorName': 'Data Fight Central - Wellness',
        'content':
            '🧠 FIGHTER MENTAL HEALTH MATTERS\n\nWe\'ve partnered with sports psychologists across Brisbane & Auckland to offer FREE mental health resources:\n✅ Burnout prevention\n✅ Injury recovery support\n✅ Career transition counseling\n✅ Post-fight decompression\n\nYour mental health = Your career. Resources in bio. 💪',
        'type': 'announcement',
        'likes': 287,
        'comments': 45,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 6)),
        ),
      },
      {
        'authorId': 'brisbane_gym_coalition',
        'authorName': 'Brisbane Gym Coalition',
        'content':
            'SAFETY CERTIFICATION: All 12 Brisbane DFC partner gyms now certified for:\n✅ Concussion protocols\n✅ Emergency medical\n✅ Harassment prevention\n✅ Fair wage standards\n\nThis is what community-first combat sports looks like. #SafetyFirst #Brisbane',
        'type': 'text',
        'likes': 156,
        'comments': 28,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
      },
      // CROSS-TASMAN COLLABORATION
      {
        'authorId': 'auckland_boxing',
        'authorName': 'City Kickboxing Auckland',
        'content':
            '🔗 CROSS-TASMAN FIGHTER EXCHANGE\n\nWe\'re launching the first-ever AU/NZ fighter pipeline:\n🇦🇺 Brisbane fighters train in Auckland\n🇳🇿 Auckland fighters train in Brisbane\n💰 Stipends provided by DFC boxer coalition\n🏆 Path to international tier\n\nApplications open NOW. First 20 fighters sponsored!',
        'type': 'announcement',
        'likes': 412,
        'comments': 67,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 4)),
        ),
      },
      // TRANSPARENT PROMOTIONS
      {
        'authorId': 'promoter_transparency',
        'authorName': 'DFC - Promoter Standards',
        'content':
            '📊 TRANSPARENT FIGHTER PURSES - NEW STANDARD\n\nAll DFC-backed events now display:\n✅ Fighter pay ranges publicly\n✅ Fair base compensation (\$500+ min)\n✅ Performance bonuses tracked\n✅ No hidden fees\n\nPromoters hiding pay? Not on our platform. Let us normalize transparency. #FightersDeserveIt',
        'type': 'text',
        'likes': 523,
        'comments': 89,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 6)),
        ),
      },
      // MENTORSHIP PROGRAM
      {
        'authorId': 'coach_marcus_brisbane',
        'authorName': 'Coach Marcus - Southside MMA',
        'content':
            '🤝 FREE MENTORSHIP: Amateur -> Pro Pathway\n\nI\'m pairing 10 amateur fighters with pro coaches:\n✅ Career planning\n✅ Contract negotiation\n✅ Brand building\n✅ Injury prevention\n✅ Real talk on fighter survival\n\nDM if interested. DFC community members first. Let\'s build careers properly.',
        'type': 'announcement',
        'likes': 234,
        'comments': 42,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 7)),
        ),
      },
      // INJURY SUPPORT FUND
      {
        'authorId': 'dfc_community_fund',
        'authorName': 'DFC Community Care Fund',
        'content':
            '❤️ FIGHTER IN NEED? WE\'RE HERE.\n\nOur injury support initiative has helped 47 fighters across AU/NZ:\n💰 Medical bills covered\n💰 Income support (injured fighters)\n💰 Mental health sessions\n💰 Rehab equipment\n\nNo fighter gets left behind. Apply confidentially here: [link]',
        'type': 'text',
        'likes': 198,
        'comments': 31,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 8)),
        ),
      },
      // GYM COMMUNITY VOICE
      {
        'authorId': 'northside_combat_gym',
        'authorName': 'Northside Combat Sports Academy',
        'content':
            '🎙️ DFC Says Gym Voice Matters!\n\nOur gym voted on the upcoming Brisbane Regional Championship:\n✅ Weight class structure\n✅ Date/venue preference\n✅ Fighter compensation\n\nFor the first time, WE\'RE deciding our future. #CommunityOwnership #Brisbane',
        'type': 'text',
        'likes': 167,
        'comments': 24,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 9)),
        ),
      },
      // EQUIPMENT SHARING
      {
        'authorId': 'wellington_fighter_collective',
        'authorName': 'Wellington Fighter Collective',
        'content':
            '🥋 GEAR SHARE: Fighting Poverty\n\nWellington fighters collective launching equipment pool:\n✅ Donated gear from retired fighters\n✅ Shared access for emerging fighters\n✅ Repair workshops\n✅ No cost to use\n\nEquipment shouldn\'t be a barrier. #AccessForAll #Wellington',
        'type': 'announcement',
        'likes': 145,
        'comments': 19,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 10)),
        ),
      },
      {
        'authorId': 'current_user',
        'authorName': 'Alex Silva',
        'content':
            'Just finished an intense 5-round sparring session. Feeling ready for the upcoming fight! 🥊',
        'type': 'text',
        'likes': 42,
        'comments': 8,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      {
        'authorId': 'coach_mike',
        'authorName': 'Coach Mike',
        'content':
            'Great training camp progress this week. The team is looking sharp! 💪',
        'type': 'text',
        'likes': 128,
        'comments': 15,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
      },
      {
        'authorId': 'gym_absolute_mma',
        'authorName': 'Absolute MMA Melbourne',
        'content':
            'New beginner BJJ class starting next Monday! Rob Lisita leading the intro sessions. All levels welcome — sign up now for early bird pricing. 🥋',
        'type': 'announcement',
        'likes': 89,
        'comments': 23,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
      {
        'authorId': 'promoter_hex_fs',
        'authorName': 'Hex Fight Series',
        'content':
            '🏆 HEX FIGHT SERIES 27: WAR ON THE SHORE 🏆\n\nMelbourne Pavilion, Kensington VIC\n12-bout card — Live on UFC Fight Pass\n\n✅ Australia\'s best MMA talent\n✅ Fair fighter purses\n✅ Professional production\n\nFighter applications STILL OPEN for undercard.\nApply: hexfs.com.au/apply\n\n#HexFightSeries #MMA #Melbourne #UFCFightPass',
        'type': 'announcement',
        'likes': 342,
        'comments': 67,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 2)),
        ),
      },
      {
        'authorId': 'fighter_whittaker',
        'authorName': 'Robert Whittaker',
        'content':
            'Congratulations to all the fighters who competed at Eternal MMA 82 last weekend. That\'s what real heart looks like. Always respect the grind. #RespectTheGrind #EternalMMA',
        'type': 'text',
        'likes': 287,
        'comments': 42,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 12)),
        ),
      },
      {
        'authorId': 'gym_brace_mma',
        'authorName': 'Brace MMA',
        'content':
            'Women\'s self-defence workshop this Saturday at Hordern Pavilion, Sydney. All levels welcome. DM for details! 💪\n\n#BraceMMA #Sydney #WomenInCombatSports',
        'type': 'announcement',
        'likes': 156,
        'comments': 31,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
      },
      {
        'authorId': 'promoter_eternal',
        'authorName': 'Eternal MMA',
        'content':
            'Fighters needed for Eternal MMA 83: Gold Coast Warfare — Gold Coast Convention Centre. Multiple weight classes available. Submit your fighter profile now! 📋\n\nhttps://eternalmma.com/apply',
        'type': 'announcement',
        'likes': 512,
        'comments': 89,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 4)),
        ),
      },
      {
        'authorId': 'nutrition_expert',
        'authorName': 'Dr. Sarah Nutrition',
        'content':
            'Cutting weight for a fight? Here\'s what I recommend 72 hours before weigh-ins: [detailed nutrition tips]. Follow up post coming tomorrow. Stay hydrated! 💧',
        'type': 'text',
        'likes': 423,
        'comments': 78,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5)),
        ),
      },
      {
        'authorId': 'ultimate_legends',
        'authorName': 'Ultimate Legends Promotions',
        'content':
            '🔥 ULTIMATE LEGENDS IS LIVE 🔥\n\nFounded by: John Scida & Joey Demicoli\n\nWe\'re bringing REAL combat sports back to Melbourne!\n\n📍 VENUE: Melbourne Pavilion, Kensington VIC\n⏰ EVERY MONTH: 12-14+ BOUTS\n🎯 STYLES: Boxing | K1 | Muay Thai | Kickboxing | MMA\n\n✅ Professional Production\n✅ Live Streaming (Live Combat Sports)\n✅ Elite Local Australian Talent\n✅ Fair Fighter Purses\n✅ Real Opportunities\n\nLATEST CARD: December 13, 2025\nFighters: Elias Khouri, Mikeydwcuz, bscerri34 + 9 more\n\nSummer 2026 Championship Series - EARLY BIRD TICKETS NOW\n\n🚨 FIGHTER APPLICATIONS OPEN 🚨\nIf you\'re ready to fight at the highest local level, apply now!\n\nFollow Ultimate Legends Promotions on Facebook & Instagram\n👉 Link in bio\n\n#UltimateLegends #CombatSports #Boxing #MuayThai #MMA #Melbourne #AustralianFighting #Kickboxing #K1 #ProFighting #FightersCommunity',
        'type': 'announcement',
        'likes': 1840,
        'comments': 312,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 6)),
        ),
      },
      {
        'authorId': 'ultimate_legends',
        'authorName': 'Ultimate Legends Promotions',
        'content':
            '🏆 FATHER & SON LEGACY — ROESLER FAMILY 🏆\n\n'
            'Jordan Roesler headlines the WBC Silver Australian Title — April 24, Melbourne Pavilion.\n\n'
            'His father James Roesler has been in the corner since day one. Trained under Sensei John Scida (5th Degree Black Belt, Zen Do Kai) since the Ultimate Muay Thai days.\n\n'
            'Joey Demicoli co-promoting. James in the corner. Jordan under the lights.\n\n'
            'This is what a real combat sports family looks like. 30+ years of legacy, one night to shine. 🔥\n\n'
            '#UltimateLegends #FatherAndSon #JordanRoesler #JamesRoesler #JohnScida #JoeyDemicoli #WBC #Melbourne #Boxing #CombatSportsFamily',
        'type': 'announcement',
        'likes': 2340,
        'comments': 456,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      // SOCIAL MEDIA PLATFORM CONTENT
      {
        'authorId': 'dfc_instagram',
        'authorName': 'DFC Instagram @datafightcentral',
        'content':
            '📸 INSTAGRAM REEL: 2.4M Views!\n\nOur Reels roundup this week:\n🔥 Whittaker\'s training montage — 2.4M views\n🔥 Hex FS 22 highlight reel — 1.1M views\n🔥 Pink Diamond stories — 890K views\n🔥 CKB Auckland gym tour — 620K views\n\nFollow @datafightcentral for daily fight content! 💪\n#DataFightCentral #MMA #Reels #FightContent',
        'type': 'text',
        'likes': 1247,
        'comments': 198,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      },
      {
        'authorId': 'dfc_tiktok',
        'authorName': 'DFC TikTok @datafightcentral',
        'content':
            '🎵 TIKTOK VIRAL: Mako Tua Shoey Comp\n\nOur TikTok blew up this week:\n👟 Bam Bam\'s Shoey compilation — 5.8M views\n🥊 "Day in the life of a fighter" series — 3.2M total\n🏋️ Training fails compilation — 2.1M views\n💎 Pink Diamond athlete spotlight — 1.4M views\n\nFollow @datafightcentral on TikTok! \n#FightTok #MMA #TikTokSports',
        'type': 'text',
        'likes': 2340,
        'comments': 456,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      {
        'authorId': 'dfc_youtube',
        'authorName': 'DFC YouTube @datafightcentral',
        'content':
            '🎬 NEW ON YOUTUBE: Full Documentary Series\n\n📺 "The Factory" — Inside City Kickboxing (52min) — 340K views\n📺 Hex FS 22 Full Replay — LIVE NOW on DFC channel\n📺 "Fight Camp: Brisbane" — Episode 3 dropped\n📺 Red Bull Air Strike Drone Racing — Full event replay\n\nSubscribe: youtube.com/@datafightcentral\n🔔 Bell ON for fight night streams!',
        'type': 'announcement',
        'likes': 876,
        'comments': 134,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 4)),
        ),
      },
      {
        'authorId': 'dfc_twitter',
        'authorName': 'DFC on X @datafightcentral',
        'content':
            '🐦 HOT TAKE THREAD:\n\nAdesanya vs Whittaker 3 needs to happen at a stadium in Auckland. Here\'s why:\n\n1. Both are Oceania\'s biggest stars\n2. CKB vs Smeaton Grange — gym rivalry\n3. NZ vs AU bragging rights\n4. 40,000+ sellout guaranteed\n\nWho wins the trilogy? Reply below 👇\n\n#MMA #Adesanya #Whittaker #UFC',
        'type': 'text',
        'likes': 1567,
        'comments': 723,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 3)),
        ),
      },
      {
        'authorId': 'dfc_facebook',
        'authorName': 'Data Fight Central — Facebook',
        'content':
            '🎉 FACEBOOK LIVE WATCH PARTY\n\nJoin us this Saturday for the Eternal MMA 82 Live Watch Party!\n\n📍 Virtual event — watch from your couch\n🍺 BYO snacks, we bring the commentary\n👥 2,400+ attending so far\n💬 Live Q&A with DFC analysts during the fights\n\nhttps://facebook.com/datafightcentral\n\n#WatchParty #EternalMMA #CombatSports',
        'type': 'announcement',
        'likes': 654,
        'comments': 87,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 8)),
        ),
      },
      {
        'authorId': 'dfc_linkedin',
        'authorName': 'Data Fight Central — LinkedIn',
        'content':
            '💼 INDUSTRY UPDATE: Combat Sports Tech Ecosystem\n\nDFC is hiring:\n✅ Flutter Mobile Developer — Brisbane (Remote OK)\n✅ Sports Data Analyst — Auckland\n✅ Community Manager — Gold Coast\n✅ FPV Drone Racing Event Coordinator — Brisbane\n\nWe\'re building the future of fight sports. Join us.\n\nlinkedin.com/company/datafightcentral\n\n#CombatSportsTech #Hiring #SportsTech',
        'type': 'text',
        'likes': 312,
        'comments': 45,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 10)),
        ),
      },
      // DRONE RACING / RED BULL FPV CONTENT
      {
        'authorId': 'dfc_drone_racing',
        'authorName': 'DFC Drone Racing — Red Bull Air Strike',
        'content':
            '🏎️ RED BULL AIR STRIKE — ROUND 2 RESULTS!\n\n🏆 Open FPV Champion: SkyPilot #7 — 3 laps to 2\n🏆 Micro FPV Champion: ThunderHawk #9 — photo finish!\n🏆 Freestyle Winner: StormChaser #11 — insane inverted gap run\n\n16 pilots. Neon gates. Night racing under Brisbane skyline.\n\nNext round: GRAND FINALE at Brisbane Convention Centre!\n\n🎥 Full replay on DFC YouTube\n#RedBullAirStrike #FPV #DroneRacing #DFC',
        'type': 'announcement',
        'likes': 1890,
        'comments': 267,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 1)),
        ),
      },
      {
        'authorId': 'dfc_fpv_league',
        'authorName': 'DFC FPV League',
        'content':
            '🚁 FPV DRONE RACING 101\n\nNew to FPV? Here\'s what makes it insane:\n✅ First-person view through tiny cameras\n✅ Speeds up to 180km/h\n✅ Neon-lit obstacle courses\n✅ Split-second reactions = everything\n✅ Red Bull Air Strike = combat sports meets drone racing\n\nStarter kits available at DFC Marketplace (\$399)\nBeginner sessions every Sunday, Brisbane Showgrounds\n\n#FPV #DroneRacing #RedBull #NewSport',
        'type': 'text',
        'likes': 987,
        'comments': 156,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 5)),
        ),
      },
      {
        'authorId': 'redbull_dfc',
        'authorName': 'Red Bull x DFC',
        'content':
            '🐂 RED BULL x DATA FIGHT CENTRAL\n\nWe\'re proud to announce our partnership with Red Bull for the Air Strike FPV Racing Series!\n\n🏁 5 events across AU/NZ in 2026\n🏁 Brisbane, Melbourne, Auckland, Gold Coast, Sydney\n🏁 \$50K total prize pool\n🏁 Live on DFC YouTube + Twitch\n\nRed Bull gives you wings. DFC gives you the arena. 🏟️\n\n#RedBull #AirStrike #DFC #FPV #GivesYouWings',
        'type': 'announcement',
        'likes': 3420,
        'comments': 567,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 2)),
        ),
      },
      {
        'authorId': 'dfc_skytrack',
        'authorName': 'DFC SkyTrack — Autonomous Training Drone',
        'content':
            '🤖 SKYTRACK UPDATE: v2.0 RELEASED\n\nThe DFC SkyTrack autonomous training drone just got smarter:\n\n✅ Real-time strike tracking (punches, kicks, elbows)\n✅ Movement pattern analysis via AI\n✅ Auto-follow mode for pad work\n✅ FPV camera for coach remote viewing\n✅ Integration with DFC Performance Dashboard\n\nEvery DFC-partnered gym gets one SkyTrack unit FREE.\n\n#SkyTrack #FightTech #AI #DroneTraining',
        'type': 'announcement',
        'likes': 1234,
        'comments': 189,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 6)),
        ),
      },
      {
        'authorId': 'dfc_discord',
        'authorName': 'DFC Discord & Twitch',
        'content':
            '🎮 LIVE ON TWITCH TONIGHT!\n\nDFC Drone Racing Watch Party — 7pm AEST\n\n🏎️ Rebroadcast: Red Bull Air Strike Round 2\n🎙️ Commentary by SkyPilot #7 & PhantomX #3\n💬 Live chat on Discord\n🎁 Giveaway: DFC FPV Beginner Drone Kit\n\ntwitch.tv/datafightcentral\ndiscord.gg/datafightcentral\n\n#Twitch #Discord #DroneRacing #Giveaway',
        'type': 'announcement',
        'likes': 678,
        'comments': 234,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 3)),
        ),
      },
      {
        'authorId': 'dfc_snapchat',
        'authorName': 'DFC Snapchat @datafightcentral',
        'content':
            '👻 NEW AR LENS: "Fighter Vision"\n\nOur Snapchat AR lens lets you:\n✅ See the ring from a fighter\'s POV\n✅ Live stat overlay during events\n✅ Virtual walkout experience\n✅ Drone racing FPV simulation\n\n12K+ users this week alone!\n\nTry it: snapchat.com/add/datafightcentral\n\n#Snapchat #AR #FighterVision #Innovation',
        'type': 'text',
        'likes': 456,
        'comments': 67,
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(hours: 7)),
        ),
      },
    ];

    // Rotating PPV hero posters so every post gets a fight-specific visual
    const postImages = [
      'assets/ppv/ppv-ufc-perth-2026_hero.jpg',
      'assets/ppv/ppv-bkfc-72_hero.jpg',
      'assets/ppv/ppv-eternal88_hero.jpg',
      'assets/ppv/ppv-one-170_hero.jpg',
      'assets/ppv/ppv-ultimate-legends-apr-2026_hero.jpg',
      'assets/ppv/ppv-hex-25_hero.jpg',
      'assets/ppv/ppv-brisbane-bonanza_hero.jpg',
    ];

    for (var i = 0; i < posts.length; i++) {
      final post = Map<String, dynamic>.from(posts[i]);
      final sportType = _inferSeedSportType(post);
      final ctaRoute = _inferSeedRoute(post);
      final resolvedImage = _resolveSeedImage(post, i);
      final resolvedMediaUrls =
          (post['mediaUrls'] as List<dynamic>?)?.cast<String>() ??
          <String>[
            resolvedImage.isNotEmpty
                ? resolvedImage
                : postImages[i % postImages.length],
          ];
      // Normalize field names for feed compatibility
      post['userId'] = post['authorId'] ?? '';
      post['userDisplayName'] = post['authorName'] ?? '';
      post['commentCount'] = post['comments'] ?? 0;
      post['shareCount'] = post['shareCount'] ?? 0;
      post['likedBy'] = <String>[];
      post['bookmarkedBy'] = <String>[];
      // Auto-assign a branded image if none provided
      post['mediaUrls'] = resolvedMediaUrls;
      if (resolvedMediaUrls.isNotEmpty) {
        post['thumbnailUrl'] = post['thumbnailUrl'] ?? resolvedMediaUrls.first;
        post['imageUrl'] = post['imageUrl'] ?? resolvedMediaUrls.first;
      }
      final normalizedMedia = SocialPostMediaAdapter.normalizeFields(
        mediaUrls: resolvedMediaUrls,
        mediaTypes: List<String>.from(
          post['mediaTypes'] as List<dynamic>? ?? const <String>[],
        ),
        externalVideoUrl:
            post['externalVideoUrl'] as String? ?? post['videoUrl'] as String?,
        thumbnailUrl:
            post['thumbnailUrl'] as String? ?? post['imageUrl'] as String?,
      );
      post['mediaUrls'] = normalizedMedia.mediaUrls;
      post['mediaTypes'] = normalizedMedia.mediaTypes;
      if (normalizedMedia.thumbnailUrl != null &&
          normalizedMedia.thumbnailUrl!.isNotEmpty) {
        post['thumbnailUrl'] = normalizedMedia.thumbnailUrl;
      }
      if (normalizedMedia.externalVideoUrl != null &&
          normalizedMedia.externalVideoUrl!.isNotEmpty) {
        post['externalVideoUrl'] = normalizedMedia.externalVideoUrl;
        post['videoUrl'] = normalizedMedia.externalVideoUrl;
      }
      post['postType'] = post['type'] ?? 'text';
      post['sportType'] = post['sportType'] ?? sportType;
      post['ctaRoute'] = post['ctaRoute'] ?? ctaRoute;
      post['linkUrl'] = post['linkUrl'] ?? ctaRoute;
      post['ctaLabel'] = post['ctaLabel'] ?? _inferSeedCtaLabel(post, ctaRoute);
      post['isAd'] = post['isAd'] ?? (post['type'] == 'announcement');
      post['adMetadata'] =
          post['adMetadata'] ??
          {
            'placement': 'feed',
            'format': post['type'] == 'announcement' ? 'campaign' : 'organic',
            'ctaRoute': ctaRoute,
          };
      post['isVerified'] = post['isVerified'] ?? false;
      post['visibility'] = 'public';

      // Infer userRole from authorId prefix
      final authorId = (post['authorId'] as String?) ?? '';
      if (authorId.startsWith('dfc_') || authorId == 'datafightcentral') {
        post['userRole'] = 'admin';
      } else if (authorId.startsWith('promoter_') ||
          authorId.startsWith('bkfc_') ||
          authorId == 'ultimate_legends' ||
          authorId == 'redbull_dfc') {
        post['userRole'] = 'promoter';
      } else if (authorId.startsWith('coach_')) {
        post['userRole'] = 'coach';
      } else if (authorId.startsWith('gym_') ||
          authorId.contains('_gym') ||
          authorId.contains('_combat_gym') ||
          authorId.contains('fight_academy')) {
        post['userRole'] = 'gym';
      } else if (authorId.startsWith('fighter_') ||
          authorId == 'current_user') {
        post['userRole'] = 'fighter';
      } else if (authorId.contains('nutrition') ||
          authorId.contains('news') ||
          authorId.contains('magazine')) {
        post['userRole'] = 'media';
      } else {
        post['userRole'] = post['userRole'] ?? 'community';
      }

      await _firestore.collection('posts').add(post);
    }
    debugPrint('Seeded ${posts.length} posts');
  }

  Future<void> _seedEvents() async {
    final events = [
      // ══════════════════════════════════════════════════════════════
      // AUSTRALIA — Real Promotions & Events
      // ══════════════════════════════════════════════════════════════
      {
        'title': 'Hex Fight Series 27: War on the Shore',
        'promoter': 'Hex Fight Series',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 6))),
        'venue': 'Melbourne Pavilion, Kensington VIC',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl': 'https://hexfs.com.au/events/hfs27',
        'streamUrl': 'https://ufcfightpass.com/hex27',
        'weightClasses': [
          'Flyweight',
          'Bantamweight',
          'Featherweight',
          'Lightweight',
          'Welterweight',
        ],
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'description':
            'Australia\'s leading MMA promotion. 12-bout card showcasing the best Australian and regional MMA talent. Live on UFC Fight Pass.',
      },
      {
        'title': 'Eternal MMA 83: Gold Coast Warfare',
        'promoter': 'Eternal MMA',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 14)),
        ),
        'venue': 'Gold Coast Convention Centre',
        'city': 'Gold Coast',
        'country': 'Australia',
        'ticketsUrl': 'https://eternalmma.com/events/83',
        'streamUrl': 'https://ufcfightpass.com/eternal83',
        'weightClasses': ['All MMA Classes'],
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/dfc2_image.png',
        'description':
            'Eternal MMA is one of Australia\'s top regional promotions. 14 fights featuring Queensland, NSW, and international talent. Live on UFC Fight Pass.',
      },
      {
        'title': 'Brace MMA 73: Collision Course',
        'promoter': 'Brace MMA',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 20)),
        ),
        'venue': 'Hordern Pavilion',
        'city': 'Sydney',
        'country': 'Australia',
        'ticketsUrl': 'https://bracemma.com.au/events/73',
        'streamUrl': 'https://bracemma.com.au/live',
        'weightClasses': [
          'Bantamweight',
          'Featherweight',
          'Lightweight',
          'Welterweight',
          'Middleweight',
        ],
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/dfc2_image_.png',
        'description':
            'Sydney\'s premier MMA promotion. Brace has produced UFC-calibre fighters and continues to be a major pathway for Australian MMA talent.',
      },
      {
        'title': 'No Scorecards Needed 14: Brisbane Brawl',
        'promoter': 'No Scorecards Needed',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 9))),
        'venue': 'Brisbane Convention Centre',
        'city': 'Brisbane',
        'country': 'Australia',
        'ticketsUrl': 'https://noscorecardsneeded.com.au/events/14',
        'streamUrl': 'https://kayosports.com.au/nscn14',
        'weightClasses': ['All Boxing Classes'],
        'tag': 'Local Pro',
        'sportType': 'Boxing',
        'posterUrl': 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        'description':
            'Queensland\'s popular professional boxing series. Action-packed cards known for finishes — "No Scorecards Needed" lives up to its name. Broadcast on Kayo Sports.',
      },
      {
        'title': 'Yokkao Australia: Perth Muay Thai Grand Prix',
        'promoter': 'Yokkao',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 17)),
        ),
        'venue': 'RAC Arena',
        'city': 'Perth',
        'country': 'Australia',
        'ticketsUrl': 'https://yokkao.com/australia-gp',
        'streamUrl': 'https://youtube.com/yokkao',
        'weightClasses': ['All Muay Thai Classes'],
        'tag': 'Local Pro',
        'sportType': 'Kickboxing',
        'posterUrl': 'assets/dfc_backgrounds/dfc_and_back_ground.png',
        'description':
            'Yokkao brings world-class Muay Thai to Perth. International and Australian nak muay compete in tournament-format bouts. The biggest Muay Thai event in Western Australia.',
      },
      {
        'title': 'Cage Titans Australia 1: Melbourne Debut',
        'promoter': 'Cage Titans',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 35)),
        ),
        'venue': 'John Cain Arena',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl': 'https://cagewarriors.com/australia-1',
        'streamUrl': 'https://ufcfightpass.com/cw-aus-1',
        'weightClasses': ['All MMA Classes'],
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/datafightlogo.png',
        'description':
            'Europe\'s premier MMA promotion expands to Australia. Cage Titans has produced UFC champions Conor McGregor, James Hargrove, and more. This inaugural Australian card features local and international talent.',
      },
      {
        'title': 'Boxing Australia National Championships 2026',
        'promoter': 'Boxing Australia',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 40)),
        ),
        'venue': 'Adelaide Entertainment Centre',
        'city': 'Adelaide',
        'country': 'Australia',
        'ticketsUrl': 'https://boxing.org.au/nationals-2026',
        'streamUrl': 'https://boxing.org.au/live',
        'weightClasses': ['All Olympic Boxing Classes'],
        'tag': 'National',
        'sportType': 'Boxing',
        'posterUrl': 'assets/dfc_backgrounds/dfc2_image_.png',
        'description':
            'Official Boxing Australia national titles. The pathway to Commonwealth Games and Olympics representation. Australia\'s best amateur boxers compete for national honours.',
      },
      {
        'title': 'WKF Australian Muay Thai Titles 2026',
        'promoter': 'World Kickboxing Federation Australia',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 25)),
        ),
        'venue': 'Melbourne Showgrounds',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl': 'https://wkfaustralia.com/titles-2026',
        'streamUrl': 'https://wkfaustralia.com/live',
        'weightClasses': ['All Muay Thai / Kickboxing Classes'],
        'tag': 'National',
        'sportType': 'Kickboxing',
        'posterUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'description':
            'The WKF Australian Muay Thai and Kickboxing national championships. Fighters from all states compete for Australian titles and WKF world ranking points.',
      },
      // ══════════════════════════════════════════════════════════════
      // INTERNATIONAL — Real Promotions & Events
      // ══════════════════════════════════════════════════════════════
      {
        'title': 'ONE Friday Fights 151: Lumpinee',
        'promoter': 'ONE Championship',
        'date': Timestamp.fromDate(DateTime(2026, 4, 24)),
        'venue': 'Lumpinee Boxing Stadium',
        'city': 'Bangkok',
        'country': 'Thailand',
        'ticketsUrl': 'https://onefc.com/tickets',
        'streamUrl': 'https://watch.onefc.com',
        'weightClasses': ['All Muay Thai & Kickboxing Classes'],
        'tag': 'International',
        'sportType': 'Kickboxing',
        'posterUrl': 'assets/ppv/ppv-one-170_hero.jpg',
        'description':
            'ONE Championship weekly Friday Fights live from the legendary Lumpinee Boxing Stadium in Bangkok. Apr 24 2026. Muay Thai and kickboxing action featuring world-ranked contenders.',
      },
      {
        'title': 'ONE Samurai 1: Tokyo',
        'promoter': 'ONE Championship',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 50)),
        ),
        'venue': 'Ryogoku Kokugikan',
        'city': 'Tokyo',
        'country': 'Japan',
        'ticketsUrl': 'https://onefc.com/samurai-1',
        'streamUrl': 'https://unext.jp/one-samurai',
        'weightClasses': ['MMA', 'Muay Thai', 'Submission Grappling'],
        'tag': 'International',
        'sportType': 'MMA',
        'posterUrl': 'assets/ppv/ppv-one-170_hero.jpg',
        'description':
            'ONE Championship launches its inaugural Japan series — ONE Samurai 1 at the iconic Ryogoku Kokugikan in Tokyo. MMA, Muay Thai, and submission grappling. Live on U-NEXT.',
      },
      {
        'title': 'UFC 328: Chimaev vs Strickland',
        'promoter': 'UFC',
        'date': Timestamp.fromDate(DateTime(2026, 5, 10)),
        'venue': 'Prudential Center',
        'city': 'Newark',
        'country': 'USA',
        'ticketsUrl':
            'https://www.ticketmaster.com/ufc-328-chimaev-vs-strickland-newark-new-jersey-05-09-2026/event/0200646A126DA604',
        'streamUrl': 'https://espnplus.com/ufc-328',
        'weightClasses': [
          'Middleweight',
          'Light Heavyweight',
          'Welterweight',
          'Heavyweight',
        ],
        'tag': 'International',
        'sportType': 'MMA',
        'posterUrl': 'assets/ppv/ppv-ufc-328_hero.jpg',
        'description':
            'Khamzat Chimaev vs Sean Strickland headlines UFC 328 at the Prudential Center, Newark NJ. May 10 2026. One of MMA\'s biggest rivalries — 5 rounds of absolute chaos. Kayo Sports PPV for AU/NZ fans.',
      },
      {
        'title': 'UFC Fight Night: Perth — Della Maddalena vs Prates',
        'promoter': 'UFC',
        'date': Timestamp.fromDate(DateTime(2026, 5, 2)),
        'venue': 'RAC Arena',
        'city': 'Perth',
        'country': 'Australia',
        'ticketsUrl':
            'https://premier.ticketek.com.au/shows/show.aspx?sh=UFCFNPER26',
        'streamUrl': 'https://kayosports.com.au/ufc-perth-2026',
        'weightClasses': ['Welterweight', 'Lightweight', 'Middleweight'],
        'tag': 'International',
        'sportType': 'MMA',
        'posterUrl': 'assets/ppv/ppv-ufc-perth-2026_hero.jpg',
        'description':
            'Jack Della Maddalena finally fights in his home city. The Perth welterweight takes on Carlos Prates at the sold-out RAC Arena. May 2 2026. Live on Kayo Sports.',
      },
      {
        'title': 'PFL 4: 2026 Regular Season',
        'promoter': 'Professional Fighters League',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 18)),
        ),
        'venue': 'The Theater at MSG',
        'city': 'New York',
        'country': 'USA',
        'ticketsUrl': 'https://pflmma.com/events/pfl-4-2026',
        'streamUrl': 'https://espn.com/pfl',
        'weightClasses': [
          'Featherweight',
          'Lightweight',
          'Welterweight',
          'Light Heavyweight',
        ],
        'tag': 'International',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/dfc2_image_.png',
        'description':
            'PFL regular season continues. Fighters compete for playoff spots and the chance at a \$1 million championship prize. Live on ESPN.',
      },
      {
        'title': 'GLORY 94: Collision — Rotterdam',
        'promoter': 'GLORY Kickboxing',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'venue': 'Rotterdam Ahoy',
        'city': 'Rotterdam',
        'country': 'Netherlands',
        'ticketsUrl': 'https://glorykickboxing.com/events/glory-94',
        'streamUrl': 'https://glorykickboxing.com/live',
        'weightClasses': [
          'Heavyweight',
          'Light Heavyweight',
          'Welterweight',
          'Featherweight',
        ],
        'tag': 'International',
        'sportType': 'Kickboxing',
        'posterUrl': 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        'description':
            'The world\'s premier kickboxing promotion. GLORY 94 features three world championship bouts. Heavyweight, light heavyweight, and welterweight titles on the line.',
      },
      {
        'title': 'K-1 World Grand Prix 2026: Quarter Finals',
        'promoter': 'K-1 Global',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 52)),
        ),
        'venue': 'Saitama Super Arena',
        'city': 'Saitama',
        'country': 'Japan',
        'ticketsUrl': 'https://k-1.co.jp/events/wgp-qf-2026',
        'streamUrl': 'https://abema.tv/k1',
        'weightClasses': [
          'Super Heavyweight',
          'Heavyweight',
          'Super Welterweight',
        ],
        'tag': 'International',
        'sportType': 'Kickboxing',
        'posterUrl': 'assets/dfc_backgrounds/dfc_and_back_ground.png',
        'description':
            'K-1 World Grand Prix quarter-final round. 16 of the world\'s best kickboxers compete in tournament format at the iconic Saitama Super Arena.',
      },
      {
        'title': 'BKFC 72: Knucklemania V',
        'promoter': 'Bare Knuckle Fighting Championship',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 15)),
        ),
        'venue': 'Seminole Hard Rock Hotel',
        'city': 'Hollywood, FL',
        'country': 'USA',
        'ticketsUrl': 'https://bareknuckle.tv/events/bkfc-72',
        'streamUrl': 'https://bareknuckle.tv/live',
        'weightClasses': ['All Bare Knuckle Classes'],
        'tag': 'International',
        'sportType': 'BKFC',
        'posterUrl': 'assets/dfc_backgrounds/dfc2_image.png',
        'description':
            'Bare Knuckle Fighting Championship\'s signature event returns. Raw, ungloved fighting at the highest level. BKFC is the fastest-growing combat sports promotion in the world.',
      },
      {
        'title': 'Matchroom Boxing: Joshua vs Dubois 2',
        'promoter': 'Matchroom Boxing',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 60)),
        ),
        'venue': 'Wembley Stadium',
        'city': 'London',
        'country': 'UK',
        'ticketsUrl': 'https://matchroomboxing.com/events/joshua-dubois-2',
        'streamUrl': 'https://dazn.com/joshua-dubois-2',
        'weightClasses': ['Heavyweight Boxing'],
        'tag': 'International',
        'sportType': 'Boxing',
        'posterUrl': 'assets/dfc_backgrounds/datafightlogo.png',
        'description':
            'Anthony Joshua vs Daniel Dubois rematch at Wembley Stadium. IBF Heavyweight title on the line. 90,000 capacity. DAZN PPV worldwide.',
      },
      {
        'title': 'Rajadamnern World Series: Grand Prix Finals',
        'promoter': 'Rajadamnern Stadium',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 38)),
        ),
        'venue': 'Rajadamnern Boxing Stadium',
        'city': 'Bangkok',
        'country': 'Thailand',
        'ticketsUrl': 'https://rajadamnern.com/world-series',
        'streamUrl': 'https://youtube.com/rajadamnern',
        'weightClasses': ['All Muay Thai Weight Classes'],
        'tag': 'International',
        'sportType': 'Kickboxing',
        'posterUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'description':
            'The historic Rajadamnern Boxing Stadium hosts its World Series Grand Prix finals. The most prestigious Muay Thai venue in the world, operating since 1945.',
      },
      {
        'title': 'ULTIMATE LEGENDS - Boxing, K1, Muay Thai & MMA Spectacular',
        'promoter': 'Ultimate Legends Promotions (John Scida & Joey Demicoli)',
        'date': Timestamp.fromDate(DateTime(2025, 12, 13)),
        'venue': 'Melbourne Pavilion, Kensington VIC',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl': 'https://facebook.com/ultimatelegendsau',
        'instagramUrl': 'https://www.instagram.com/ultimatelegendspromotions/',
        'streamUrl':
            'https://www.livecombatsports.com.au/ultimate-legends-dec-2025',
        'weightClasses': ['Boxing', 'K1', 'Muay Thai', 'Kickboxing', 'MMA'],
        'bouts': 12,
        'fighters': 'Elias Khouri, Mikeydwcuz, bscerri34, + 9 more',
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/dfc_and_back_ground.png',
        'description':
            'Action-packed 12+ bout card featuring local Australian talent competing in boxing, K1, Muay Thai, kickboxing and MMA. In partnership with Team Ultimate. Broadcast via Live Combat Sports. Corner team: John Scida, Joey Demicoli, James Roesler.',
      },
      {
        'title': 'ULTIMATE LEGENDS - Summer 2026 Championship Series',
        'promoter': 'Ultimate Legends Promotions (John Scida & Joey Demicoli)',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 145)),
        ),
        'venue': 'Melbourne Pavilion, Kensington VIC',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl': 'https://facebook.com/ultimatelegendsau',
        'instagramUrl': 'https://www.instagram.com/ultimatelegendspromotions/',
        'streamUrl': null,
        'weightClasses': ['Boxing', 'K1', 'Muay Thai', 'Kickboxing', 'MMA'],
        'bouts': 14,
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        'description':
            'Ultimate Legends Summer Championship Series. 14+ bouts showcasing elite Australian combat sports talent. Main Event: Jordan Roesler — WBC Silver Australian Title. Corner: John Scida, Joey Demicoli & James Roesler. Father-and-son legacy. Live updates on Facebook & Instagram. Partnership with Team Ultimate - Muay Thai, Kickboxing, Boxing & MMA.',
      },
      // NEW ZEALAND EVENTS
      {
        'title': 'King of the Ring 98: Wellington Thunder',
        'promoter': 'King of the Ring NZ',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 21)),
        ),
        'venue': 'TSB Arena',
        'city': 'Wellington',
        'country': 'New Zealand',
        'ticketsUrl': 'https://kotr.nz/tickets',
        'streamUrl': 'https://skysportnz.co.nz/kotr-live',
        'weightClasses': ['Kickboxing', 'Muay Thai', 'K-1'],
        'tag': 'International',
        'sportType': 'Kickboxing',
        'posterUrl': 'assets/dfc_backgrounds/dfc2_image_.png',
        'description':
            'New Zealand\'s premier kickboxing promotion returns with a stacked 10-fight card featuring NZ and Australian talent.',
      },
      {
        'title': 'Duco Events: Parker vs Fa — Rematch',
        'promoter': 'Duco Events NZ',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 28)),
        ),
        'venue': 'Eden Park',
        'city': 'Auckland',
        'country': 'New Zealand',
        'ticketsUrl': 'https://ducoevents.co.nz/parker-fa-2',
        'streamUrl': 'https://skyarena.co.nz/ppv/parker-fa-2',
        'weightClasses': ['Heavyweight Boxing'],
        'tag': 'International',
        'sportType': 'Boxing',
        'posterUrl': 'assets/dfc_backgrounds/dfc2_image.png',
        'description':
            'New Zealand heavyweight rivalry renewed. Joseph Parker faces Junior Fa in a blockbuster rematch at Eden Park in front of 40,000+ fans.',
      },
      {
        'title': 'CKB Open: MMA & Kickboxing Showcase',
        'promoter': 'City Kickboxing',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 14)),
        ),
        'venue': 'Spark Arena',
        'city': 'Auckland',
        'country': 'New Zealand',
        'ticketsUrl': 'https://ckb.co.nz/open-2026',
        'streamUrl': 'https://skysportnz.co.nz/ckb-live',
        'weightClasses': ['All Classes'],
        'tag': 'International',
        'sportType': 'MMA',
        'posterUrl': 'assets/dfc_backgrounds/datafightlogo.png',
        'description':
            'Auckland\'s famed City Kickboxing gym hosts an open showcase featuring top NZ MMA and kickboxing talent, plus international guest fighters.',
      },
      // ══════════════════════════════════════════════════════════════
      // REAL 2026 EVENTS — Verified from promoter websites
      // ══════════════════════════════════════════════════════════════
      {
        'title': 'Eternal MMA 105: Perth',
        'promoter': 'Eternal MMA',
        'date': Timestamp.fromDate(DateTime(2026, 5)),
        'venue': 'Perth HPC',
        'city': 'Perth',
        'country': 'Australia',
        'ticketsUrl': 'https://eternalmma.com/events/eternal-mma-105-perth/',
        'streamUrl': 'https://ufcfightpass.com/eternal-105',
        'weightClasses': ['All MMA Classes'],
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/ppv/ppv-eternal88_hero.jpg',
        'description':
            'Eternal MMA heads west for the first time — 105 live from Perth HPC on May 1 2026. Australia\'s most consistent MMA promotion brings elite talent to Western Australia. Live on UFC Fight Pass.',
      },
      {
        'title': 'Eternal MMA 106: Gold Coast',
        'promoter': 'Eternal MMA',
        'date': Timestamp.fromDate(DateTime(2026, 6, 5)),
        'venue': 'Southport Sharks',
        'city': 'Gold Coast',
        'country': 'Australia',
        'ticketsUrl':
            'https://eternalmma.com/events/eternal-mma-106-gold-coast/',
        'streamUrl': 'https://ufcfightpass.com/eternal-106',
        'weightClasses': ['All MMA Classes'],
        'tag': 'Local Pro',
        'sportType': 'MMA',
        'posterUrl': 'assets/ppv/ppv-eternal88_hero.jpg',
        'description':
            'Eternal MMA 106 rolls into the Gold Coast on June 5 2026 at Southport Sharks. Queensland MMA at its finest. Live on UFC Fight Pass.',
      },
      {
        'title': 'Tszyu vs Diaz: The Butcher and The Bull',
        'promoter': 'Main Event / Fox Sports',
        'date': Timestamp.fromDate(DateTime(2026, 5, 22)),
        'venue': 'Newcastle Entertainment Centre',
        'city': 'Newcastle',
        'country': 'Australia',
        'ticketsUrl': 'https://www.mainevent.com.au',
        'streamUrl': 'https://foxsports.com.au/tszyu-diaz',
        'weightClasses': ['Super Welterweight Boxing'],
        'tag': 'Local Pro',
        'sportType': 'Boxing',
        'posterUrl': 'assets/ppv/ppv-bkfc-newcastle_hero.jpg',
        'description':
            'Nikita "The Butcher" Tszyu returns to Newcastle to face Oscar "The Bull" Diaz. The undefeated son of Kostya Tszyu fights for his future in a must-win showdown. Live on Main Event and Fox Sports AU.',
      },
      {
        'title': 'Zuffa Boxing: Dana White\'s New Promotion',
        'promoter': 'Zuffa Boxing',
        'date': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'venue': 'TBA',
        'city': 'Las Vegas',
        'country': 'USA',
        'ticketsUrl': 'https://www.paramountplus.com',
        'streamUrl': 'https://www.paramountplus.com',
        'weightClasses': ['All Boxing Classes'],
        'tag': 'International',
        'sportType': 'Boxing',
        'posterUrl': 'assets/ppv/ppv-ufc-327_hero.jpg',
        'description':
            'Dana White launches Zuffa Boxing exclusively on Paramount+. The UFC boss brings his fight-making machine to the boxing world. Live and exclusive on Paramount+.',
      },
      {
        'title': 'ULTIMATE LEGENDS Fight Night — Apr 2026',
        'promoter': 'Ultimate Legends Promotions (John Scida & Joey Demicoli)',
        'date': Timestamp.fromDate(DateTime(2026, 4, 24)),
        'venue': 'Melbourne Pavilion, Kensington VIC',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl': 'https://facebook.com/ultimatelegendsau',
        'instagramUrl': 'https://www.instagram.com/ultimatelegendspromotions/',
        'streamUrl': 'https://www.livecombatsports.com.au',
        'weightClasses': ['Boxing', 'K1', 'Muay Thai', 'Kickboxing', 'MMA'],
        'bouts': 12,
        'fighters': 'Sam Howe vs Daniel Best (Pro Middleweight Boxing)',
        'tag': 'Local Pro',
        'sportType': 'Boxing',
        'posterUrl': 'assets/ppv/ppv-ultimate-legends-apr-2026_hero.jpg',
        'description':
            'Ultimate Legends Fight Night at Melbourne Pavilion on April 24 2026. Main event: Sam Howe vs Daniel Best — Pro Middleweight Boxing. Doors 5pm, fights 6pm. Promoted by John Scida & Joey Demicoli. Broadcast via Live Combat Sports.',
      },
      {
        'title': 'UFC Fight Night: Burns vs Malott',
        'promoter': 'UFC',
        'date': Timestamp.fromDate(DateTime(2026, 4, 19)),
        'venue': 'Canada Life Centre',
        'city': 'Winnipeg',
        'country': 'Canada',
        'ticketsUrl': 'https://www.ticketmaster.ca/event/1100645487D0876E',
        'streamUrl': 'https://espnplus.com/ufc-burns-malott',
        'weightClasses': ['Welterweight', 'Lightweight', 'Featherweight'],
        'tag': 'International',
        'sportType': 'MMA',
        'posterUrl': 'assets/ppv/ppv-ufc-paramount-fightnight_hero.jpg',
        'description':
            'UFC Fight Night from Winnipeg, Canada. Gilbert Burns meets Mike Malott in a welterweight showdown. Apr 19 2026 at Canada Life Centre. Live on ESPN+.',
      },
    ];

    for (final e in events) {
      // Deterministic ID from title so we can overwrite, never duplicate
      final slug = (e['title'] as String)
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');

      // Derive human-readable broadcast name from streamUrl if broadcastInfo
      // is not already present.
      final broadcastInfo =
          e['broadcastInfo'] ?? _broadcastFromUrl(e['streamUrl'] as String?);

      // Enrich with query-compatible field names:
      // EventService.getUpcomingEvents() queries on 'eventDate' + 'status'
      final explicitPoster = e['posterUrl']?.toString();
      final resolvedPoster = !ImageAssets.isGenericPosterAsset(explicitPoster)
          ? explicitPoster
          : ImageAssets.posterAssetForEventMetadata(
              eventId: slug,
              title: e['title']?.toString(),
              promoter: e['promoter']?.toString(),
              eventDate: e['date'] as DateTime?,
              streamUrl: e['streamUrl']?.toString(),
              ticketUrl: e['ticketUrl']?.toString(),
            );
      final enriched = {
        ...e,
        'eventDate': e['date'], // query field
        'status': 'upcoming', // query field
        'broadcastInfo': broadcastInfo, // human-readable channel name
        if (resolvedPoster != null)
          'posterUrl': resolvedPoster
        else
          'posterUrl': FieldValue.delete(),
      };
      await _firestore
          .collection('events')
          .doc(slug)
          .set(enriched, SetOptions(merge: true));
    }
    debugPrint('Seeded/updated ${events.length} events (merge: true)');
  }

  /// Re-seed events using merge — overwrites posterUrl/sportType on existing
  /// docs without needing delete permission. Safe to call repeatedly.
  Future<void> reseedPriorityPageProfiles() async {
    debugPrint('Re-seeding priority page profiles (merge overwrite)...');
    await _seedPriorityPageProfiles();
    debugPrint('Priority page profile re-seed complete.');
  }

  /// Re-seed events using merge — overwrites posterUrl/sportType on existing
  /// docs without needing delete permission. Safe to call repeatedly.
  Future<void> reseedEvents() async {
    debugPrint('Re-seeding events (merge overwrite)...');
    await _seedEvents();
    debugPrint('Event re-seed complete — all posterUrls written.');
  }

  /// Re-seed posts with mediaUrls so every feed card has an image.
  Future<void> reseedPosts() async {
    debugPrint('Re-seeding posts (clearing + re-writing with images)...');
    // Delete existing seeded posts in two batches (Firestore whereIn max = 30)
    final seedAuthors1 = [
      'dfc_combat_news',
      'bkfc_official',
      'dfc_official',
      'dfc_wellness',
      'brisbane_gym_coalition',
      'auckland_boxing',
      'promoter_transparency',
      'coach_marcus_brisbane',
      'dfc_community_fund',
      'northside_combat_gym',
      'wellington_fighter_collective',
      'coach_mike',
      'gym_absolute_mma',
      'promoter_hex_fs',
      'fighter_torres',
    ];
    final seedAuthors2 = [
      'gym_brace_mma',
      'promoter_eternal',
      'nutrition_expert',
      'ultimate_legends',
      'dfc_instagram',
      'dfc_tiktok',
      'dfc_youtube',
      'dfc_twitter',
      'dfc_facebook',
      'dfc_linkedin',
      'dfc_drone_racing',
      'dfc_fpv_league',
      'redbull_dfc',
      'dfc_skytrack',
      'dfc_discord',
      'dfc_snapchat',
    ];
    for (final authors in [seedAuthors1, seedAuthors2]) {
      final existing = await _firestore
          .collection('posts')
          .where('userId', whereIn: authors)
          .get();
      final batch = _firestore.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await _seedPosts();
    debugPrint('Post re-seed complete — all posts now have mediaUrls.');
  }

  /// Derive human-readable broadcast channel name from a streaming URL.
  static String _broadcastFromUrl(String? url) {
    if (url == null || url.isEmpty) return 'TBA';
    final u = url.toLowerCase();
    if (u.contains('espnplus') || u.contains('espn.com')) return 'ESPN+';
    if (u.contains('ufcfightpass')) return 'UFC Fight Pass';
    if (u.contains('kayo')) return 'Kayo Sports';
    if (u.contains('dazn')) return 'DAZN';
    if (u.contains('bareknuckle.tv')) return 'BKFC App';
    if (u.contains('paramount')) return 'Paramount+';
    if (u.contains('abema')) return 'FITE';
    if (u.contains('glorykickboxing')) return 'FITE';
    if (u.contains('onefc') || u.contains('watch.onefc')) return 'Prime Video';
    if (u.contains('skysport')) return 'Sky Sports';
    if (u.contains('skyarena')) return 'Sky Sports';
    if (u.contains('youtube') || u.contains('youtu.be')) return 'YouTube';
    if (u.contains('boxing.org.au')) return 'Stan Sport';
    if (u.contains('wkfaustralia')) return 'WKF';
    if (u.contains('livecombatsports')) return 'Live Combat Sports';
    if (u.contains('unext')) return 'Prime Video';
    return 'TBA';
  }

  Future<void> _seedPromotions() async {
    final promos = [
      {
        'title':
            'HEX FIGHT SERIES — Australia\'s Premier MMA on UFC Fight Pass',
        'promoter': 'Hex Fight Series',
        'date': Timestamp.now(),
        'venue': 'Melbourne Pavilion, Kensington VIC',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl': 'https://hexfs.com.au',
        'streamUrl': 'https://ufcfightpass.com',
        'weightClasses': ['All MMA Classes'],
        'tag': 'Featured Promotion',
        'posterUrl': 'assets/ppv/ppv-hex-25_hero.jpg',
        'description':
            'Australia\'s leading MMA promotion. 12+ bout cards live on UFC Fight Pass. Pathway to the UFC for Australian fighters.',
        'isFeatured': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'ETERNAL MMA — Gold Coast & Queensland\'s Best MMA',
        'promoter': 'Eternal MMA',
        'date': Timestamp.now(),
        'venue': 'Gold Coast Convention Centre',
        'city': 'Gold Coast',
        'country': 'Australia',
        'ticketsUrl': 'https://eternalmma.com',
        'streamUrl': 'https://ufcfightpass.com',
        'weightClasses': ['All MMA Classes'],
        'tag': 'Featured Promotion',
        'posterUrl': 'assets/ppv/ppv-eternal88_hero.jpg',
        'description':
            'One of Australia\'s top regional MMA promotions. Regular events on the Gold Coast and across Queensland. Live on UFC Fight Pass.',
        'isFeatured': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'BRACE MMA — Sydney\'s Premier MMA Promotion',
        'promoter': 'Brace MMA',
        'date': Timestamp.now(),
        'venue': 'Hordern Pavilion, Sydney',
        'city': 'Sydney',
        'country': 'Australia',
        'ticketsUrl': 'https://bracemma.com.au',
        'streamUrl': 'https://bracemma.com.au/live',
        'weightClasses': ['All MMA Classes'],
        'tag': 'Featured Promotion',
        'posterUrl': 'assets/ppv/ppv-brisbane-bonanza_hero.jpg',
        'description':
            'Sydney\'s premier MMA promotion. Has produced UFC-calibre fighters and continues to develop Australian combat sports talent.',
        'isFeatured': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'KING OF THE RING — New Zealand\'s Legendary Kickboxing',
        'promoter': 'King of the Ring NZ',
        'date': Timestamp.now(),
        'venue': 'TSB Arena, Wellington',
        'city': 'Wellington',
        'country': 'New Zealand',
        'ticketsUrl': 'https://kotr.nz',
        'streamUrl': 'https://skysportnz.co.nz',
        'weightClasses': ['Kickboxing', 'Muay Thai', 'K-1'],
        'tag': 'Featured Promotion',
        'posterUrl': 'assets/ppv/ppv-westcoast-warriors33_hero.jpg',
        'description':
            'New Zealand\'s premier kickboxing and Muay Thai promotion. Long-running series featuring NZ and international talent. Broadcast on Sky Sport NZ.',
        'isFeatured': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Women in Combat Sports Workshop - FREE',
        'promoter': 'DFC Community',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'venue': 'Various DFC Partner Gyms',
        'city': 'Brisbane / Auckland',
        'country': 'AU / NZ',
        'ticketsUrl': 'https://datafightcentral.com/women-workshop',
        'streamUrl': null,
        'weightClasses': [],
        'tag': 'Workshop',
        'posterUrl': 'assets/ppv/ppv-legends45_hero.jpg',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'ULTIMATE LEGENDS PROMOTIONS — Melbourne Pavilion Series',
        'promoter': 'Ultimate Legends Promotions',
        'date': Timestamp.now(),
        'venue': 'Melbourne Pavilion, Kensington VIC',
        'city': 'Melbourne',
        'country': 'Australia',
        'ticketsUrl':
            'https://facebook.com/pages/Ultimate-Legends-Promotions/ultimatelegendsau',
        'instagramUrl': 'https://www.instagram.com/ultimatelegendspromotions/',
        'streamUrl': 'https://www.livecombatsports.com.au',
        'weightClasses': ['Boxing', 'K1', 'Muay Thai', 'Kickboxing', 'MMA'],
        'tag': 'Featured Promotion',
        'posterUrl': 'assets/ppv/ppv-ultimate-legends-apr-2026_hero.jpg',
        'description':
            'Ultimate Legends Promotions - Founded by John Scida & Joey Demicoli. Melbourne\'s longest-running combat sports promotion (est. 1992). Premium monthly events featuring professional Boxing, K1, Muay Thai, Kickboxing & MMA at Melbourne Pavilion. 12-14+ high-energy bouts per card. Main Event: Jordan Roesler — WBC Silver Australian Title. Father James Roesler in the corner. Partnership with Team Ultimate. Broadcast via Live Combat Sports. Follow on Facebook & Instagram.',
        'founder': 'John Scida & Joey Demicoli',
        'venue_location': 'Melbourne Pavilion, Kensington VIC',
        'headliner': 'Jordan Roesler',
        'cornerTeam': 'John Scida, Joey Demicoli, James Roesler',
        'isFeatured': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final p in promos) {
      await _firestore.collection('promotions').add(p);
    }
    debugPrint('Seeded ${promos.length} promotions');
  }

  Future<void> _seedSubscriptionPlans() async {
    final plans = [
      // Fighter
      {
        'tier': 'fighter',
        'name': 'Fighter',
        'description': 'Performance dashboard, training analytics, AI coach',
        'cycle': 'weekly',
        'priceCents': 349,
        'active': true,
        'providerPriceIds': {
          'stripe': 'price_fighter_weekly',
          'googlePay': 'gpay_fighter_weekly',
          'paypal': 'paypal_fighter_weekly',
          'applePay': 'apple_fighter_weekly',
        },
        'features': [
          'performance_dashboard',
          'training_analytics',
          'ai_training_insights',
          'work_opportunities',
          'mental_health_resources',
        ],
      },
      {
        'tier': 'fighter',
        'name': 'Fighter',
        'description': 'Performance dashboard, training analytics, AI coach',
        'cycle': 'fortnightly',
        'priceCents': 649,
        'active': true,
        'providerPriceIds': {
          'stripe': 'price_fighter_fortnightly',
          'googlePay': 'gpay_fighter_fortnightly',
          'paypal': 'paypal_fighter_fortnightly',
          'applePay': 'apple_fighter_fortnightly',
        },
        'features': [
          'performance_dashboard',
          'training_analytics',
          'ai_training_insights',
          'work_opportunities',
          'mental_health_resources',
        ],
      },
      {
        'tier': 'fighter',
        'name': 'Fighter',
        'description': 'Performance dashboard, training analytics, AI coach',
        'cycle': 'monthly',
        'priceCents': 999,
        'active': true,
        'providerPriceIds': {
          'stripe': 'price_fighter_monthly',
          'googlePay': 'gpay_fighter_monthly',
          'paypal': 'paypal_fighter_monthly',
          'applePay': 'apple_fighter_monthly',
        },
        'features': [
          'performance_dashboard',
          'training_analytics',
          'ai_training_insights',
          'work_opportunities',
          'mental_health_resources',
        ],
      },
      // Promoter
      {
        'tier': 'promoter',
        'name': 'Promoter',
        'description': 'Event management, fighter DB, analytics',
        'cycle': 'weekly',
        'priceCents': 899,
        'active': true,
        'providerPriceIds': {
          'stripe': 'price_promoter_weekly',
          'googlePay': 'gpay_promoter_weekly',
          'paypal': 'paypal_promoter_weekly',
          'applePay': 'apple_promoter_weekly',
        },
        'features': [
          'event_management',
          'fighter_database',
          'analytics_dashboard',
          'priority_support',
        ],
      },
      {
        'tier': 'promoter',
        'name': 'Promoter',
        'description': 'Event management, fighter DB, analytics',
        'cycle': 'monthly',
        'priceCents': 2999,
        'active': true,
        'providerPriceIds': {
          'stripe': 'price_promoter_monthly',
          'googlePay': 'gpay_promoter_monthly',
          'paypal': 'paypal_promoter_monthly',
          'applePay': 'apple_promoter_monthly',
        },
        'features': [
          'event_management',
          'fighter_database',
          'analytics_dashboard',
          'priority_support',
        ],
      },
      // Supporter
      {
        'tier': 'supporter',
        'name': 'Supporter',
        'description': 'Ad-free, exclusive content, early access',
        'cycle': 'monthly',
        'priceCents': 499,
        'active': true,
        'providerPriceIds': {
          'stripe': 'price_supporter_monthly',
          'googlePay': 'gpay_supporter_monthly',
          'paypal': 'paypal_supporter_monthly',
          'applePay': 'apple_supporter_monthly',
        },
        'features': ['ad_free', 'exclusive_content', 'early_event_access'],
      },
      // Fan (free)
      {
        'tier': 'fan',
        'name': 'Fan',
        'description': 'Browse events, profiles, and community',
        'cycle': 'monthly',
        'priceCents': 0,
        'active': true,
        'providerPriceIds': {},
        'features': [
          'browse_events',
          'view_profiles',
          'basic_feed',
          'community_access',
        ],
      },
    ];

    for (final plan in plans) {
      await _firestore.collection('subscription_plans').add(plan);
    }
    debugPrint('Seeded ${plans.length} subscription plans');
  }

  Future<void> _seedDemoEntitlements({required String userId}) async {
    final snapshot = await _firestore
        .collection('subscription_plans')
        .where('tier', isEqualTo: 'fighter')
        .where('cycle', isEqualTo: 'monthly')
        .limit(1)
        .get();

    final planId = snapshot.docs.isNotEmpty
        ? snapshot.docs.first.id
        : 'fighter-monthly';

    await _firestore.collection('subscriptions').add({
      'userId': userId,
      'planId': planId,
      'tier': 'fighter',
      'cycle': 'monthly',
      'active': true,
      'startDate': Timestamp.now(),
      'currentPeriodEnd': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 30)),
      ),
      'provider': 'stripe',
      'providerCustomerId': 'demo_customer',
      'providerSubscriptionId': 'demo_subscription',
      'entitlements': [
        'performance_dashboard',
        'training_analytics',
        'ai_training_insights',
        'work_opportunities',
        'mental_health_resources',
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });
    debugPrint('Seeded demo subscription entitlement for $userId');
  }

  Future<void> _seedHelpResources() async {
    final resources = [
      // MENTAL HEALTH & WELLNESS (BRISBANE)
      {
        'type': 'mental_health',
        'name': 'Brisbane Fighter Mental Health Clinic',
        'description':
            'Specialized mental health support for combative sport athletes. Services include trauma processing, burnout prevention, pre-fight anxiety management, post-fight decompression.',
        'region': 'Brisbane',
        'city': 'Brisbane, QLD',
        'phone': '+61 7 3369 1111',
        'email': 'support@bfmhc.com.au',
        'website': 'www.brisbane-fighter-mental-health.com.au',
        'availability': '24/7 Crisis Line + Appointment Based',
        'services': [
          'Trauma counseling',
          'Burnout prevention',
          'Anxiety management',
          'Career transition',
          'Crisis support',
          'Peer support groups',
        ],
        'cost': 'Free for DFC members, \$50-100 sliding scale for others',
        'verified': true,
      },
      {
        'type': 'injury_support',
        'name': 'Brisbane Advanced Rehab Sports Medicine',
        'description':
            'Sports rehabilitation specialists focused on fighter injuries. Concussion protocol, ACL recovery, spinal health, performance return pathways.',
        'region': 'Brisbane',
        'city': 'Brisbane, QLD',
        'phone': '+61 7 3832 9922',
        'email': 'rehab@barsm.com.au',
        'website': 'www.brisbanerehabsports.com.au',
        'availability': 'Mon-Fri 8am-6pm, Sat 9am-2pm',
        'services': [
          'Concussion assessment',
          'ACL rehabilitation',
          'Spinal health',
          'Return-to-fighting protocols',
          'Performance testing',
          'Injury prevention planning',
        ],
        'cost': 'Medicare rebate eligible, Private \$150-200 per session',
        'verified': true,
      },
      {
        'type': 'helpline',
        'name': 'Fortitude Valley Combat Athlete Support Line',
        'description':
            'Anonymous support line for fighters facing career challenges, financial hardship, health crises, or safety concerns. Trained peer counselors.',
        'region': 'Brisbane',
        'city': 'Brisbane, QLD',
        'phone': '1800-FIGHTER (1800-344-8837)',
        'email': 'support@fvcas.org.au',
        'website': 'www.fortitudevalleysos.com.au',
        'availability': '24/7 Phone Support',
        'services': [
          'Career guidance',
          'Financial hardship support',
          'Injury support networks',
          'Safety concerns reporting',
          'Peer mentoring',
          'Emergency referrals',
        ],
        'cost': 'FREE - Fully funded assistance',
        'verified': true,
      },
      {
        'type': 'nutrition_wellness',
        'name': 'Champion Nutrition Brisbane',
        'description':
            'Sports nutrition specialists for weight management, performance optimization, recovery protocols. Evidence-based, fighter-focused guidance.',
        'region': 'Brisbane',
        'city': 'Brisbane, QLD',
        'phone': '+61 7 3877 5544',
        'email': 'nutrition@championnutrition.com.au',
        'website': 'www.championnutrition.com.au',
        'availability': 'Mon-Fri 7am-7pm, Sat 8am-2pm',
        'services': [
          'Weight management',
          'Performance nutrition',
          'Recovery protocols',
          'Supplement guidance',
          'Online coaching',
          'Group workshops',
        ],
        'cost': 'Consultation \$80, Packages \$500-2000',
        'verified': true,
      },
      // VIOLENCE PREVENTION & CHILD SAFETY (AUSTRALIA)
      {
        'type': 'violence_prevention',
        'name': 'DFC - Zero Tolerance Violence Policy & Reporting',
        'description':
            'Data Fight Central maintains absolute zero tolerance for violence against women and children. Confidential reporting, investigation, and support for survivors.',
        'region': 'Oceania',
        'city': 'Virtual',
        'phone': '1800-DFC-SAFE (1800-332-7233)',
        'email': 'safeguarding@datafightcentral.com',
        'website': 'www.datafightcentral.com/safety',
        'availability': '24/7 Confidential Reporting',
        'services': [
          'Anonymous violence reporting',
          'Immediate survivor support',
          'Investigation coordination',
          'Legal referrals',
          'Safe housing assistance',
          'Restraining order support',
          'Gym safety audits',
          'Staff training on abuse protocols',
        ],
        'cost': 'FREE - All support services',
        'verified': true,
      },
      {
        'type': 'womens_safety',
        'name': 'Australian Domestic Violence Hotline - Brisbane/AU',
        'description':
            '24/7 national support for women experiencing domestic violence, family violence, or abuse. Trained counselors, safety planning, emergency support.',
        'region': 'Brisbane',
        'city': 'Brisbane, QLD',
        'phone': '1800-015-188',
        'email': 'support@defensiblespace.com.au',
        'website': 'www.1800respect.org.au',
        'availability': '24/7 Phone Support (Interpreter Services Available)',
        'services': [
          'Crisis counseling',
          'Safety planning',
          'Referrals to shelters',
          'Legal advice connections',
          'Stalking support',
          'Post-separation safety',
          'Financial abuse support',
          'Religious/cultural support',
        ],
        'cost': 'FREE - Government funded',
        'verified': true,
      },
      {
        'type': 'child_protection',
        'name': 'Australian Child Safety Commission - Combative Sports',
        'description':
            'Child protection oversight for combat sports. Screening protocols, incident reporting, trainer accreditation, safe environments.',
        'region': 'Brisbane',
        'city': 'Brisbane, QLD',
        'phone': '+61 7 3019 7701',
        'email': 'safeguarding@childsafety.gov.au',
        'website': 'www.child.gov.au/combat-sports-guidelines',
        'availability': 'Mon-Fri 9am-5pm + Emergency Hotline 24/7',
        'services': [
          'Child safety risk assessments',
          'Trainer background screening',
          'Abuse reporting procedures',
          'Safe training protocols',
          'Parental notification systems',
          'Incident investigation',
          'Coach accreditation programs',
          'Gym safety certifications',
        ],
        'cost': 'FREE - Part of federal protection service',
        'verified': true,
      },
      // MENTAL HEALTH & WELLNESS (AUCKLAND)
      {
        'type': 'mental_health',
        'name': 'Auckland Combat Sports Wellness Centre',
        'description':
            'Premier mental health and wellness hub for NZ combat athletes. Psychology, counseling, performance optimization, wellbeing programs.',
        'region': 'Auckland',
        'city': 'Auckland, NZ',
        'phone': '+64 9 521 4455',
        'email': 'wellness@aucklandcombat.co.nz',
        'website': 'www.auckland-combat-wellness.co.nz',
        'availability': '24/7 Crisis + Mon-Fri 8am-6pm Appointments',
        'services': [
          'Sport psychology',
          'Trauma-informed care',
          'Anxiety & stress management',
          'Substance abuse support',
          'Recovery counseling',
          'Family therapy for athletes',
        ],
        'cost': 'Free DHB referrals, \$60-120 private sessions',
        'verified': true,
      },
      {
        'type': 'injury_support',
        'name': 'City Kickboxing + Physiotherapy Alliance',
        'description':
            'Integrated rehab services at City Kickboxing. On-site physios, sports doctors, return-to-training specialists.',
        'region': 'Auckland',
        'city': 'Auckland, NZ',
        'phone': '+64 9 308 4129',
        'email': 'physio@citykickboxing.co.nz',
        'website': 'www.citykickboxing-physio.co.nz',
        'availability': 'Daily 6am-9pm (staffed 8am-5pm)',
        'services': [
          'On-gym physiotherapy',
          'Injury assessment',
          'Concussion management',
          'Return-to-sparring protocols',
          'Performance enhancement',
          'Career longevity planning',
        ],
        'cost': 'ACC covered injuries, Private \$120-160/session',
        'verified': true,
      },
      {
        'type': 'helpline',
        'name': 'SBG Auckland Fighter Support Network',
        'description':
            'Peer support and crisis line for NZ combat athletes. Mental health, career challenges, safety concerns, community connection.',
        'region': 'Auckland',
        'city': 'Auckland, NZ',
        'phone': '1800-AUCKLAND-FIGHTER (instant chat available)',
        'email': 'support@sbgaucklandsupport.co.nz',
        'website': 'www.sbgauckland-support.co.nz',
        'availability': '24/7 Chat + Phone Support',
        'services': [
          'Career transition support',
          'Mental health crisis response',
          'Mentorship matching',
          'Financial assistance pathways',
          'Safe training environment reporting',
          'Community peer groups',
        ],
        'cost': 'FREE - All services included',
        'verified': true,
      },
      // VIOLENCE PREVENTION & WOMEN'S SAFETY (NEW ZEALAND)
      {
        'type': 'womens_safety',
        'name': 'NZ Domestic Violence - 1800 RESPECT',
        'description':
            'National New Zealand support for women experiencing domestic violence or family violence. 24/7 crisis support, safety planning, emergency assistance.',
        'region': 'Auckland',
        'city': 'Auckland, NZ',
        'phone': '0800-456-450',
        'email': 'support@dvnz.org.nz',
        'website': 'www.nzfamilyviolence.org.nz',
        'availability': '24/7 Phone Support (All Languages)',
        'services': [
          'Crisis counseling',
          'Safety planning',
          'Emergency shelter referrals',
          'Legal advice pathways',
          'Restraining order assistance',
          'Stalking protection',
          'Cultural-specific support',
          'Interpreter services',
        ],
        'cost': 'FREE - Government funded service',
        'verified': true,
      },
      {
        'type': 'child_protection',
        'name': 'NZ Child Safety - Combat Sports Safeguarding',
        'description':
            'Child protection and safeguarding for NZ combat sports. Safe coaching practices, trainer vetting, abuse prevention, incident reporting.',
        'region': 'New Zealand',
        'city': 'Wellington, NZ',
        'phone': '+64 4 817 7000',
        'email': 'safeguarding@childyouthwelfare.govt.nz',
        'website': 'www.childrensrights.org.nz/combat-sports',
        'availability': 'Mon-Fri 8am-5pm + 24/7 Emergency',
        'services': [
          'Child safety assessments',
          'Trainer background checks',
          'Safe practice guidelines',
          'Abuse reporting hotline',
          'Investigation support',
          'Gym accreditation',
          'Coach training programs',
          'Parent/guardian notifications',
        ],
        'cost': 'FREE - Part of national child protection',
        'verified': true,
      },
      // WELLINGTON
      {
        'type': 'mental_health',
        'name': 'Southern Cross Combat Wellbeing',
        'description':
            'Wellington mental health partners for combat athletes. Specialist in post-career transitions, injury trauma, community support.',
        'region': 'Wellington',
        'city': 'Wellington, NZ',
        'phone': '+64 4 499 2020',
        'email': 'wellness@wellcombat.co.nz',
        'website': 'www.wellington-combat-wellness.co.nz',
        'availability': 'Mon-Fri 9am-5pm, Crisis 24/7',
        'services': [
          'Individual counseling',
          'Group therapy for fighters',
          'Career counseling',
          'Substance abuse recovery',
          'PTSD support',
          'Family counseling',
        ],
        'cost': 'ACC funded or \$70-100/session',
        'verified': true,
      },
      // CHRISTCHURCH
      {
        'type': 'injury_support',
        'name': 'Christchurch Combat Health Clinic',
        'description':
            'South Island rehabilitation hub. Sports medicine doctors, physios, injury prevention specialists trained in combat sports.',
        'region': 'Christchurch',
        'city': 'Christchurch, NZ',
        'phone': '+64 3 366 5566',
        'email': 'health@christchurchcombat.co.nz',
        'website': 'www.christchurchcombat-health.co.nz',
        'availability': 'Mon-Fri 8am-5pm, Sat 9am-1pm',
        'services': [
          'Sports medicine assessment',
          'Joint rehabilitation',
          'Concussion protocols',
          'Return-to-activity planning',
          'Performance optimization',
          'Medical clearances',
        ],
        'cost': 'ACC eligible, Private \$130-170/session',
        'verified': true,
      },
      // HAMILTON (REGIONAL)
      {
        'type': 'helpline',
        'name': 'Waikato Combat Athlete Support Hotline',
        'description':
            'Regional support for Waikato fighters. Connects to larger networks, crisis support, peer mentoring, resource matching.',
        'region': 'Hamilton',
        'city': 'Hamilton, NZ',
        'phone': '+64 7 838 5555',
        'email': 'support@waikatoFighters.co.nz',
        'website': 'www.waikato-fighter-support.co.nz',
        'availability': '24/7 Phone + Email Support',
        'services': [
          'Local resource matching',
          'Crisis support',
          'Mentorship setup',
          'Network building',
          'Emergency contacts',
          'Telehealth counseling connections',
        ],
        'cost': 'FREE - Community service',
        'verified': true,
      },
      // DUNEDIN (REGIONAL)
      {
        'type': 'mental_health',
        'name': 'Dunedin University Combat Athlete Program',
        'description':
            'Academic psychology program + practical support. Specialized in athlete mental health, research partnerships, free services for students.',
        'region': 'Dunedin',
        'city': 'Dunedin, NZ',
        'phone': '+64 3 479 7000',
        'email': 'combat-mental-health@otago.ac.nz',
        'website': 'www.otago.ac.nz/combat-wellness',
        'availability': 'Mon-Fri 9am-4pm + After-hours Crisis',
        'services': [
          'Free counseling (student athletes)',
          'Sport psychology coaching',
          'Research-based interventions',
          'Community workshops',
          'Peer support programs',
          'Crisis support 24/7',
        ],
        'cost': 'Free for students, Donation-based for community',
        'verified': true,
      },
      // CROSS-REGION RESOURCES
      {
        'type': 'helpline',
        'name': 'DFC Fighter Care Hotline (AU/NZ)',
        'description':
            'Central Data Fight Central help line. Coordinates all resources, emergency support, fighter welfare escalations, cross-border assistance.',
        'region': 'Oceania',
        'city': 'Virtual',
        'phone': '1800-DFC-CARE (1800-332-2273)',
        'email': 'care@datafightcentral.com',
        'website': 'www.datafightcentral.com/support',
        'availability': '24/7 Every Day',
        'services': [
          'Resource directory & matching',
          'Crisis triage & response',
          'Welfare escalation',
          'Emergency fund coordination',
          'Legal referrals',
          'Cross-border support routing',
          'Peer mentorship matching',
          'Long-term support planning',
        ],
        'cost': 'FREE - Fully funded by DFC',
        'verified': true,
      },
      {
        'type': 'violence_prevention',
        'name': 'DFC - Women & Children Protection Initiative',
        'description':
            'NO SILENCE FOR VIOLENCE. Comprehensive protection program against violence towards women and children in combat sports. Mandatory reporting, gym monitoring, survivor support.',
        'region': 'Oceania',
        'city': 'Virtual',
        'phone': '1800-DFC-SAFE (1800-332-7233)',
        'email': 'protect@datafightcentral.com',
        'website': 'www.datafightcentral.com/women-children-safety',
        'availability': '24/7 Reporting & Support',
        'services': [
          'Confidential violence reporting',
          'Survivor emergency support (housing, counseling, legal)',
          'Mandatory investigation protocols',
          'Gym compliance audits',
          'Trainer background screening',
          'Children safety certifications',
          'Coach accountability programs',
          'Community awareness campaigns',
          'Support groups for survivors',
          'Emergency fund for survivors',
          'Legal representation referrals',
          'Cross-national coordination for trafficking',
        ],
        'cost': 'FREE - DFC funded protection',
        'verified': true,
      },
      {
        'type': 'nutrition_wellness',
        'name': 'Oceania Combat Sports Nutrition Network',
        'description':
            'Virtual nutrition platform connecting AU/NZ fighters to specialists. Weight management, performance, recovery, evidence-based guidance.',
        'region': 'Oceania',
        'city': 'Virtual',
        'phone': '+64 9 446 0606',
        'email': 'nutrition@oceania-combat.co',
        'website': 'www.oceania-combat-nutrition.co',
        'availability': 'Mon-Fri 7am-7pm NZDT (Virtual)',
        'services': [
          'Online consultations',
          'Nutrition planning',
          'Weight management protocols',
          'Recovery meal prep',
          'Group webinars',
          'Mobile app tracking',
        ],
        'cost': 'Free guides, \$50-150/session consultations',
        'verified': true,
      },
    ];

    for (var resource in resources) {
      await _firestore.collection('help_resources').add(resource);
    }

    debugPrint(
      'Seeded ${resources.length} fighter care, safety & support resources',
    );
  }

  Future<void> _seedPinkDiamondNetwork() async {
    final pinkDiamondResources = [
      // PINK DIAMOND - BRISBANE MENTOR NETWORK
      {
        'type': 'pink_diamond',
        'name': 'Pink Diamond Brisbane - Women & Girls Mentor Circle',
        'description':
            'Highly respected Diamond-tier mentors providing trauma-informed support, healing spaces, and hope-focused recovery for women and girls who have experienced harm, violence, or abuse. Diamond mentors are community leaders who have paid to support and protect vulnerable members.',
        'region': 'Brisbane',
        'city': 'Brisbane, QLD, Australia',
        'phone': '+61 7 3000 1313',
        'email': 'pinkdiamond.brisbane@dfc.local',
        'website': 'www.dfc.local/pink-diamond',
        'availability':
            '24/7 crisis support, mentor availability M-F 9am-6pm, weekends flexible',
        'services': [
          'Trauma-informed mentorship',
          'Individual healing consultations',
          'Safe space peer support groups',
          'One-on-one support for survivors',
          'Crisis intervention and emergency support',
          'Community rebuilding programs',
          'Hope-focused recovery coaching',
          'Dignity-centered healing',
          'Mentor matching based on experience',
          'Family reconnection support',
        ],
        'cost': 'Free for members, mentors donate time and expertise',
        'verified': true,
      },
      // PINK DIAMOND - AUCKLAND MENTOR NETWORK
      {
        'type': 'pink_diamond',
        'name': 'Pink Diamond Auckland - Women & Girls Support Network',
        'description':
            'Auckland-based Diamond mentors offering compassion-centered healing for women and girls emerging from trauma and harm. Led by respected community members committed to protection, healing, and hope restoration.',
        'region': 'Auckland',
        'city': 'Auckland, NZ',
        'phone': '+64 9 000 1313',
        'email': 'pinkdiamond.auckland@dfc.local',
        'website': 'www.dfc.local/pink-diamond',
        'availability':
            '24/7 crisis support, mentor meetings M-F 10am-5pm + weekend groups',
        'services': [
          'Trauma healing circles',
          'Mentor-to-mentor peer support',
          'Safe spaces for vulnerable women/girls',
          'Confidence rebuilding programs',
          'Mental health first aid',
          'Societal reintegration support',
          'Education and skills development',
          'Legal and housing referrals',
          'Celebration of resilience milestones',
          'Cross-cultural healing support',
        ],
        'cost': 'Free for community members, mentors contribute resources',
        'verified': true,
      },
      // PINK DIAMOND - WELLINGTON MENTOR NETWORK
      {
        'type': 'pink_diamond',
        'name': 'Pink Diamond Wellington - Healing & Hope Initiative',
        'description':
            'Wellington-based Diamond mentor collective providing compassionate, trauma-informed support for women and girls who have been harmed. Mentors are highly respected, paid community members dedicated to protection and healing.',
        'region': 'Wellington',
        'city': 'Wellington, NZ',
        'phone': '+64 4 000 1313',
        'email': 'pinkdiamond.wellington@dfc.local',
        'website': 'www.dfc.local/pink-diamond',
        'availability':
            '24/7 crisis line, mentor availability by appointment + drop-in circles',
        'services': [
          'Individual healing mentorship',
          'Group support circles',
          'Safe housing facilitation',
          'Healing arts and wellness activities',
          'Professional counseling coordination',
          'Community connection programs',
          'Self-defense and empowerment training',
          'Employment support',
          'Educational pathways',
          'Hope and future planning sessions',
        ],
        'cost':
            'Free for survivors, mentor contributions valued and recognized',
        'verified': true,
      },
      // PINK DIAMOND - VIRTUAL COORDINATION
      {
        'type': 'pink_diamond',
        'name': 'Pink Diamond Virtual - Oceania Mentor Coordination Hub',
        'description':
            'Central coordination hub connecting Diamond-tier mentors across Brisbane, Auckland, Wellington, and regional areas. Virtual mentorship, online healing circles, and cross-boundary support for women and girls emerging from harm.',
        'region': 'Oceania',
        'city': 'Online/Virtual',
        'phone': '1800-DIAMOND (1800-342-6663)',
        'email': 'coordination@pinkdiamond.dfc.local',
        'website': 'www.dfc.local/pink-diamond',
        'availability':
            '24/7 crisis support, virtual mentoring M-F 8am-10pm AEDT, weekend groups scheduled',
        'services': [
          'Virtual one-on-one mentoring',
          'Online healing circles (video, text, voice)',
          'Crisis hotline coordination',
          'Mentor training and certification',
          'Resource library and guides',
          'Peer mentor matching system',
          'Cross-regional support networks',
          'Emergency response coordination',
          'Community celebration events (virtual)',
          'Impact tracking and healing milestones',
        ],
        'cost': 'All services free for members and survivors',
        'verified': true,
      },
      // PINK DIAMOND - MENTOR TRAINING & DEVELOPMENT
      {
        'type': 'pink_diamond',
        'name': 'Pink Diamond Mentor Academy - Diamond Tier Training',
        'description':
            'Training and certification program for Diamond-tier mentors. Equips highly respected community members with trauma-informed support skills, compassion coaching, and protective protocols to support women and girls healing from harm.',
        'region': 'Oceania',
        'city': 'Brisbane, Auckland, Wellington, Online',
        'phone': '+61 7 3000 1414',
        'email': 'mentors@pinkdiamond.dfc.local',
        'website': 'www.dfc.local/pink-diamond/mentors',
        'availability':
            'Quarterly training cohorts, online modules available anytime',
        'services': [
          'Trauma-informed care certification',
          'Compassionate communication training',
          'Crisis intervention protocols',
          'Boundary setting for mentors',
          'Self-care and mentor burnout prevention',
          'Healing justice frameworks',
          'Cultural competency training',
          'Legal and safety protocols',
          'Mentor peer supervision groups',
          'Certification and recognition programs',
        ],
        'cost':
            'Free for Diamond-tier mentors, subsidized for aspiring mentors',
        'verified': true,
      },
    ];

    for (var resource in pinkDiamondResources) {
      await _firestore.collection('help_resources').add(resource);
    }

    debugPrint(
      'Seeded ${pinkDiamondResources.length} Pink Diamond mentor network resources',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. FIGHTER DATABANK — Rankings & Public Profiles
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedFighterDatabank() async {
    final fighters = [
      {
        'name': 'Robert Whittaker',
        'nickname': 'The Reaper',
        'country': 'Australia',
        'city': 'Sydney',
        'weightClass': 'Middleweight',
        'record': '25-7-0',
        'wins': 25,
        'losses': 7,
        'draws': 0,
        'koWins': 10,
        'subWins': 3,
        'decWins': 12,
        'ranking': 1,
        'gym': 'Southern Cross BJJ Smeaton Grange',
        'style': 'Striking / Karate',
        'age': 35,
        'height': '180cm',
        'reach': '185cm',
        'status': 'active',
        'bio':
            'Former UFC Middleweight Champion. One of the most skilled strikers in MMA history with devastating karate-based attacks.',
      },
      {
        'name': 'Tyler Reid',
        'nickname': 'The Great',
        'country': 'Australia',
        'city': 'Wollongong',
        'weightClass': 'Featherweight',
        'record': '26-4-0',
        'wins': 26,
        'losses': 4,
        'draws': 0,
        'koWins': 13,
        'subWins': 3,
        'decWins': 10,
        'ranking': 2,
        'gym': 'City Kickboxing / Freestyle Fighting',
        'style': 'Wrestling / Boxing',
        'age': 37,
        'height': '168cm',
        'reach': '182cm',
        'status': 'active',
        'bio':
            'Former UFC Featherweight Champion. Pound-for-pound elite. Transformed from rugby league to MMA greatness.',
      },
      {
        'name': 'Israel Adesanya',
        'nickname': 'The Last Stylebender',
        'country': 'New Zealand',
        'city': 'Auckland',
        'weightClass': 'Middleweight',
        'record': '24-4-0',
        'wins': 24,
        'losses': 4,
        'draws': 0,
        'koWins': 16,
        'subWins': 0,
        'decWins': 8,
        'ranking': 3,
        'gym': 'City Kickboxing',
        'style': 'Kickboxing / Counter-striker',
        'age': 36,
        'height': '193cm',
        'reach': '203cm',
        'status': 'active',
        'bio':
            'Former UFC Middleweight Champion. Elite kickboxer turned MMA sensation with anime-inspired walkouts and devastating precision striking.',
      },
      {
        'name': 'Mako Tua',
        'nickname': 'The Wave',
        'country': 'Australia',
        'city': 'Western Sydney',
        'weightClass': 'Heavyweight',
        'record': '15-8-0',
        'wins': 15,
        'losses': 8,
        'draws': 0,
        'koWins': 13,
        'subWins': 0,
        'decWins': 2,
        'ranking': 4,
        'gym': 'Team Pacific / Island MMA',
        'style': 'Brawler / Heavyweight Power',
        'age': 31,
        'height': '188cm',
        'reach': '193cm',
        'status': 'active',
        'bio':
            'Fan-favourite Samoan-Australian heavyweight. The Shoey King. Raw knockout power with a heart of gold for the local community.',
      },
      {
        'name': 'Tama Rawiri',
        'nickname': 'Don\'t Blink',
        'country': 'New Zealand',
        'city': 'Auckland',
        'weightClass': 'Flyweight',
        'record': '24-11-0',
        'wins': 24,
        'losses': 11,
        'draws': 0,
        'koWins': 14,
        'subWins': 2,
        'decWins': 8,
        'ranking': 5,
        'gym': 'City Kickboxing',
        'style': 'Muay Thai / Boxing',
        'age': 31,
        'height': '165cm',
        'reach': '170cm',
        'status': 'active',
        'bio':
            'Former UFC Flyweight title challenger. One of New Zealand\'s most explosive fighters with devastating power at 57 kg / 125 lbs.',
      },
      {
        'name': 'Nathan Cross',
        'nickname': 'The Hangman',
        'country': 'New Zealand',
        'city': 'Auckland',
        'weightClass': 'Lightweight',
        'record': '24-12-0',
        'wins': 24,
        'losses': 12,
        'draws': 0,
        'koWins': 11,
        'subWins': 7,
        'decWins': 6,
        'ranking': 6,
        'gym': 'City Kickboxing',
        'style': 'All-rounder / Muay Thai',
        'age': 34,
        'height': '183cm',
        'reach': '195cm',
        'status': 'active',
        'bio':
            'One of the most exciting fighters in MMA. Known for wars with Stone, Lawson. True Warrior mentality.',
      },
      {
        'name': 'Tyson Pedro',
        'nickname': 'The Tongan',
        'country': 'Australia',
        'city': 'Sydney',
        'weightClass': 'Light Heavyweight',
        'record': '10-4-0',
        'wins': 10,
        'losses': 4,
        'draws': 0,
        'koWins': 7,
        'subWins': 2,
        'decWins': 1,
        'ranking': 7,
        'gym': 'Golden Dragon Muay Thai / UFG',
        'style': 'Striking / Ground & Pound',
        'age': 32,
        'height': '190cm',
        'reach': '196cm',
        'status': 'active',
        'bio':
            'Rising Australian LHW contender. Explosive finisher with Tongan warrior spirit and devastating knockout power.',
      },
      {
        'name': 'Casey O\'Neill',
        'nickname': 'King Casey',
        'country': 'Australia',
        'city': 'Gold Coast',
        'weightClass': 'Flyweight (W)',
        'record': '10-2-0',
        'wins': 10,
        'losses': 2,
        'draws': 0,
        'koWins': 3,
        'subWins': 4,
        'decWins': 3,
        'ranking': 8,
        'gym': 'Xtreme Couture / AKA',
        'style': 'Wrestling / Submission',
        'age': 27,
        'height': '165cm',
        'reach': '168cm',
        'status': 'active',
        'bio':
            'Scottish-Australian UFC flyweight. Pink Diamond ambassador. Combines wrestling dominance with highlight-reel submissions.',
      },
      {
        'name': 'Jack Jenkins',
        'nickname': 'J.J.',
        'country': 'Australia',
        'city': 'Brisbane',
        'weightClass': 'Featherweight',
        'record': '14-3-0',
        'wins': 14,
        'losses': 3,
        'draws': 0,
        'koWins': 6,
        'subWins': 5,
        'decWins': 3,
        'ranking': 9,
        'gym': 'Scrappy MMA',
        'style': 'Grappling / BJJ',
        'age': 25,
        'height': '175cm',
        'reach': '180cm',
        'status': 'active',
        'bio':
            'Brisbane\'s own. Young prospect tearing through the featherweight division. One of Queensland\'s brightest MMA talents.',
      },
      {
        'name': 'Megan Anderson',
        'nickname': 'The Lionheart',
        'country': 'Australia',
        'city': 'Gold Coast',
        'weightClass': 'Featherweight (W)',
        'record': '12-7-0',
        'wins': 12,
        'losses': 7,
        'draws': 0,
        'koWins': 6,
        'subWins': 4,
        'decWins': 2,
        'ranking': 10,
        'gym': 'Glory MMA',
        'style': 'Striking / Power',
        'age': 34,
        'height': '183cm',
        'reach': '178cm',
        'status': 'active',
        'bio':
            'Former Invicta champ. One of the tallest women in MMA. A powerful presence representing Australian women in combat sports.',
      },
      {
        'name': 'Mark Hunt',
        'nickname': 'The Super Samoan',
        'country': 'New Zealand',
        'city': 'Auckland',
        'weightClass': 'Heavyweight',
        'record': '13-14-1',
        'wins': 13,
        'losses': 14,
        'draws': 1,
        'koWins': 11,
        'subWins': 0,
        'decWins': 2,
        'ranking': 11,
        'gym': 'Auckland MMA',
        'style': 'Kickboxing / K-1 Champion',
        'age': 51,
        'height': '178cm',
        'reach': '175cm',
        'status': 'retired',
        'bio':
            'K-1 Grand Prix Champion turned UFC icon. The Walk Off KO king. A legend of Oceania combat sports and cultural hero.',
      },
      {
        'name': 'Jimmy Crute',
        'nickname': 'The Brute',
        'country': 'Australia',
        'city': 'Melbourne',
        'weightClass': 'Light Heavyweight',
        'record': '14-4-0',
        'wins': 14,
        'losses': 4,
        'draws': 0,
        'koWins': 5,
        'subWins': 7,
        'decWins': 2,
        'ranking': 12,
        'gym': 'Absolute MMA Melbourne',
        'style': 'BJJ / Submission Specialist',
        'age': 28,
        'height': '188cm',
        'reach': '193cm',
        'status': 'active',
        'bio':
            'Melbourne\'s submission machine. Rising through the LHW ranks with relentless grappling and unshakeable Aussie grit.',
      },
      {
        'name': 'Shane Young',
        'nickname': 'Shaolin',
        'country': 'New Zealand',
        'city': 'Auckland',
        'weightClass': 'Featherweight',
        'record': '15-7-0',
        'wins': 15,
        'losses': 7,
        'draws': 0,
        'koWins': 8,
        'subWins': 4,
        'decWins': 3,
        'ranking': 13,
        'gym': 'City Kickboxing',
        'style': 'Muay Thai / Kickboxing',
        'age': 31,
        'height': '175cm',
        'reach': '180cm',
        'status': 'active',
        'bio':
            'Exciting Kiwi featherweight. An electric Muay Thai stylist representing Maori culture and NZ\'s finest fighting tradition.',
      },
      {
        'name': 'Zane Kohere',
        'nickname': 'Black Jag',
        'country': 'New Zealand',
        'city': 'Auckland',
        'weightClass': 'Light Heavyweight',
        'record': '11-1-0',
        'wins': 11,
        'losses': 1,
        'draws': 0,
        'koWins': 9,
        'subWins': 0,
        'decWins': 2,
        'ranking': 14,
        'gym': 'City Kickboxing',
        'style': 'Striking / Kickboxing',
        'age': 32,
        'height': '190cm',
        'reach': '196cm',
        'status': 'active',
        'bio':
            'Former Glory kickboxer. Now one of the UFC\'s most dangerous LHWs. Athleticism and knockout power from CKB\'s elite factory.',
      },
      {
        'name': 'Steve Erceg',
        'nickname': 'Astro Boy',
        'country': 'Australia',
        'city': 'Perth',
        'weightClass': 'Flyweight',
        'record': '13-2-0',
        'wins': 13,
        'losses': 2,
        'draws': 0,
        'koWins': 2,
        'subWins': 6,
        'decWins': 5,
        'ranking': 15,
        'gym': 'Scrappy MMA / Bushido',
        'style': 'BJJ / Grappling',
        'age': 29,
        'height': '170cm',
        'reach': '175cm',
        'status': 'active',
        'bio':
            'Perth grappling sensation who challenged for the UFC Flyweight title. Australia\'s submission specialist at 57 kg / 125 lbs.',
      },
    ];

    for (var f in fighters) {
      await _firestore.collection('fighter_databank').add({
        ...f,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'verified': true,
      });
    }
    debugPrint('Seeded ${fighters.length} fighters to databank');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. FIGHTS — Bout Data for Events
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedFights() async {
    final now = DateTime.now();
    final fights = [
      {
        'eventName': 'Hex Fight Series 22',
        'redCorner': {'name': 'Jake Matthews', 'record': '20-5'},
        'blueCorner': {'name': 'Carlos Silva', 'record': '14-6'},
        'weightClass': 'Welterweight',
        'rounds': 3,
        'result': 'Red corner TKO R2 3:41',
        'isTitleFight': false,
        'isMainEvent': false,
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 14))),
      },
      {
        'eventName': 'Hex Fight Series 22',
        'redCorner': {'name': 'Tyson Pedro', 'record': '10-4'},
        'blueCorner': {'name': 'Anton Turkalj', 'record': '9-2'},
        'weightClass': 'Light Heavyweight',
        'rounds': 5,
        'result': 'Red corner KO R1 2:08',
        'isTitleFight': true,
        'isMainEvent': true,
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 14))),
      },
      {
        'eventName': 'Eternal MMA 80',
        'redCorner': {'name': 'Shannon Ross', 'record': '12-2'},
        'blueCorner': {'name': 'Abdallah Abdallah', 'record': '10-4'},
        'weightClass': 'Featherweight',
        'rounds': 5,
        'result': 'Red corner Decision (Split)',
        'isTitleFight': true,
        'isMainEvent': true,
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'eventName': 'Eternal MMA 80',
        'redCorner': {'name': 'Billy Makaveli', 'record': '8-1'},
        'blueCorner': {'name': 'Logan Martin', 'record': '6-3'},
        'weightClass': 'Lightweight',
        'rounds': 3,
        'result': 'Blue corner SUB R3 4:12',
        'isTitleFight': false,
        'isMainEvent': false,
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
      },
      {
        'eventName': 'BRACE 80',
        'redCorner': {'name': 'Callan Potter', 'record': '18-8'},
        'blueCorner': {'name': 'Alexander Murray', 'record': '11-3'},
        'weightClass': 'Welterweight',
        'rounds': 5,
        'result': 'Red corner Decision (Unanimous)',
        'isTitleFight': true,
        'isMainEvent': true,
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 21))),
      },
      {
        'eventName': 'Ultimate Legends 1 — Brisbane',
        'redCorner': {'name': 'Tai Tuivasa', 'record': '14-8'},
        'blueCorner': {'name': 'Justin Willis', 'record': '10-4'},
        'weightClass': 'Heavyweight',
        'rounds': 5,
        'result': 'Upcoming',
        'isTitleFight': true,
        'isMainEvent': true,
        'date': Timestamp.fromDate(now.add(const Duration(days: 30))),
      },
      {
        'eventName': 'DFC FPV Drone Racing — Red Bull Air Strike',
        'redCorner': {'name': 'SkyPilot (Drone #7)', 'record': 'Season 2-0'},
        'blueCorner': {'name': 'NeonBlade (Drone #12)', 'record': 'Season 1-1'},
        'weightClass': 'Open Class FPV',
        'rounds': 5,
        'result': 'Red corner wins — 3 laps to 2',
        'isTitleFight': false,
        'isMainEvent': true,
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'eventName': 'DFC FPV Drone Racing — Red Bull Air Strike',
        'redCorner': {'name': 'PhantomX (Drone #3)', 'record': 'Season 3-0'},
        'blueCorner': {
          'name': 'ThunderHawk (Drone #9)',
          'record': 'Season 2-1',
        },
        'weightClass': 'Micro Class FPV',
        'rounds': 3,
        'result': 'Blue corner wins — 2 laps to 1',
        'isTitleFight': false,
        'isMainEvent': false,
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
    ];

    for (var fight in fights) {
      await _firestore.collection('fights').add({
        ...fight,
        'createdAt': Timestamp.now(),
      });
    }
    debugPrint('Seeded ${fights.length} fights');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PPV EVENTS (for FightCampService)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedPPVEvents() async {
    final ppvRef = _firestore.collection('ppv_events');
    final existing = await ppvRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    // Delegate to PPVService's rich demo data (20+ events with posters,
    // fight cards, streaming platforms incl. Thrillx/Kayo/Main Event).
    try {
      final batch = _firestore.batch();
      for (final ppv in PPVService.demoPPVEvents) {
        batch.set(
          ppvRef.doc(ppv.id),
          ppv.toFirestore(),
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      debugPrint(
        'Seeded ${PPVService.demoPPVEvents.length} PPV events (from PPVService)',
      );
    } catch (e) {
      debugPrint('DatabaseSeeder._seedPPVEvents error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. FIGHT CARD TEMPLATES
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedFightCardTemplates() async {
    final now = DateTime.now();
    final templates = [
      {
        'name': 'Hex Fight Series 22 — Melbourne',
        'eventDate': Timestamp.fromDate(now.subtract(const Duration(days: 14))),
        'venue': 'Melbourne Pavilion',
        'city': 'Melbourne',
        'country': 'Australia',
        'status': 'completed',
        'bouts': [
          {
            'red': 'Tyson Pedro',
            'blue': 'Anton Turkalj',
            'weight': 'LHW',
            'rounds': 5,
            'titleFight': true,
          },
          {
            'red': 'Jake Matthews',
            'blue': 'Carlos Silva',
            'weight': 'WW',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'Suman Mokhtarian',
            'blue': 'Victor Henry',
            'weight': 'BW',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'Kit Elliot',
            'blue': 'JJ Okanovich',
            'weight': 'FW',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'Danielle Taylor',
            'blue': 'Zoe-Mai Brooks',
            'weight': 'SW(W)',
            'rounds': 3,
            'titleFight': false,
          },
        ],
        'createdBy': 'dfc_system',
      },
      {
        'name': 'Ultimate Legends 1 — Brisbane Showcase',
        'eventDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
        'venue': 'Brisbane Convention Centre',
        'city': 'Brisbane',
        'country': 'Australia',
        'status': 'upcoming',
        'bouts': [
          {
            'red': 'Tai Tuivasa',
            'blue': 'Justin Willis',
            'weight': 'HW',
            'rounds': 5,
            'titleFight': true,
          },
          {
            'red': 'Robert Whittaker',
            'blue': 'Dricus Du Plessis',
            'weight': 'MW',
            'rounds': 5,
            'titleFight': true,
          },
          {
            'red': 'Jamie Mullarkey',
            'blue': 'Mateusz Gamrot',
            'weight': 'LW',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'Jack Jenkins',
            'blue': 'Joshua Culibao',
            'weight': 'FW',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'Steve Erceg',
            'blue': 'Kai Kara-France',
            'weight': 'FLW',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'Casey O\'Neill',
            'blue': 'Luana Santos',
            'weight': 'BW(W)',
            'rounds': 3,
            'titleFight': false,
          },
        ],
        'createdBy': 'dfc_system',
      },
      {
        'name': 'DFC FPV Drone Grand Prix — Red Bull Air Strike',
        'eventDate': Timestamp.fromDate(now.add(const Duration(days: 45))),
        'venue': 'Southbank Parklands',
        'city': 'Brisbane',
        'country': 'Australia',
        'status': 'upcoming',
        'bouts': [
          {
            'red': 'SkyPilot #7',
            'blue': 'NeonBlade #12',
            'weight': 'Open FPV',
            'rounds': 5,
            'titleFight': true,
          },
          {
            'red': 'PhantomX #3',
            'blue': 'ThunderHawk #9',
            'weight': 'Micro FPV',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'VortexKing #1',
            'blue': 'IronEagle #5',
            'weight': 'Open FPV',
            'rounds': 3,
            'titleFight': false,
          },
          {
            'red': 'GhostRider #15',
            'blue': 'AcePilot #8',
            'weight': 'Freestyle FPV',
            'rounds': 3,
            'titleFight': false,
          },
        ],
        'createdBy': 'dfc_system',
      },
    ];

    for (var template in templates) {
      await _firestore.collection('fight_card_templates').add({
        ...template,
        'createdAt': Timestamp.now(),
      });
    }
    debugPrint('Seeded ${templates.length} fight card templates');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. NOTIFICATIONS — Welcome & Activity
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedNotifications() async {
    final now = DateTime.now();
    final notifications = [
      {
        'title': 'Welcome to Data Fight Central! 🥊',
        'body':
            'Your Command Centre is live. Explore your dashboard, connect with fighters, and check out upcoming events.',
        'type': 'welcome',
        'read': false,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 5)),
        ),
      },
      {
        'title': 'Pink Diamond Network Active 💎',
        'body':
            'The Pink Diamond mentorship program is now available. Supporting women & girls in combat sports across Oceania.',
        'type': 'feature',
        'read': false,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(minutes: 10)),
        ),
      },
      {
        'title': 'Hex Fight Series 22 — Results In',
        'body':
            'Tyson Pedro with a devastating R1 KO! Full results and highlights now available in Events.',
        'type': 'event',
        'read': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      },
      {
        'title': 'FightWire: Breaking News 📰',
        'body':
            'Reid hints at super-fight with Navarro. Full story on FightWire.',
        'type': 'news',
        'read': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 4))),
      },
      {
        'title': 'New Gym Partner: Iron Born MMA',
        'body':
            'Iron Born MMA in Brisbane CBD has joined the DFC network. Check them out in Gym Finder.',
        'type': 'gym',
        'read': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
      },
      {
        'title': 'Ultimate Legends 1 — Tickets On Sale 🎟️',
        'body':
            'Brisbane Convention Centre, April 2026. Early bird tickets available NOW.',
        'type': 'event',
        'read': false,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 8))),
      },
      {
        'title': 'Safety Update: Concussion Protocols',
        'body':
            'All DFC-partnered events now require mandatory concussion screening. Fighter welfare comes first.',
        'type': 'safety',
        'read': false,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 12)),
        ),
      },
      {
        'title': 'DFC Social — You\'re Connected! 🌐',
        'body':
            'Follow us: @datafightcentral on Instagram, TikTok, YouTube, X, Facebook, LinkedIn, Snapchat & WhatsApp.',
        'type': 'social',
        'read': false,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 14)),
        ),
      },
      {
        'title': 'DFC FPV Drone Racing — Season 1 🏎️',
        'body':
            'Red Bull Air Strike drone racing is LIVE on DFC! Watch FPV pilots battle through neon-lit obstacle courses.',
        'type': 'event',
        'read': false,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 16)),
        ),
      },
      {
        'title': 'Your Fight Stock Portfolio',
        'body':
            'The DFC Fight Stock market is open. Track fighter values, invest in talent, watch the ticker.',
        'type': 'feature',
        'read': false,
        'createdAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 18)),
        ),
      },
    ];

    // Write to global notifications (no userId path needed for broadcast)
    for (var notif in notifications) {
      await _firestore.collection('notifications').add(notif);
    }
    debugPrint('Seeded ${notifications.length} notifications');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 13. NEWS ARTICLES — FightWire Content
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedNewsArticles() async {
    final now = DateTime.now();
    final articles = [
      {
        'title': 'Reid Eyes Super-Fight With Navarro After Featherweight Clash',
        'summary':
            'Former champion Tyler Reid has signaled interest in a rematch with Alexander Volkanovski, suggesting a massive crossover event could happen in 2026.',
        'source': 'DFC FightWire',
        'category': 'MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 2)),
        ),
      },
      {
        'title': 'Hex Fight Series Announces Melbourne Return — HFS 23',
        'summary':
            'Australia\'s premier MMA promotion confirms Hex 23 at Melbourne Pavilion for April 2026. Card features 3 title fights.',
        'source': 'DFC FightWire',
        'category': 'Local MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 5)),
        ),
      },
      {
        'title': 'Casey O\'Neill Returns — Gold Coast Card Confirmed',
        'summary':
            'Pink Diamond ambassador Casey O\'Neill returns to action at Eternal MMA 82, Gold Coast. Full card announced.',
        'source': 'DFC FightWire',
        'category': 'Women\'s MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 8)),
        ),
      },
      {
        'title': 'Red Bull Air Strike: FPV Drone Racing Comes to Combat Sports',
        'summary':
            'DFC partners with Red Bull for FPV drone racing at fight events. Neon-lit obstacle courses, first-person piloting, and a full racing season announced for 2026.',
        'source': 'DFC FightWire',
        'category': 'Drone Racing',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 3)),
        ),
      },
      {
        'title': 'DFC FPV League: Season 1 Standings After Round 2',
        'summary':
            'PhantomX leads the Micro Class, SkyPilot dominates Open Class. Next round at Brisbane Showgrounds with Red Bull sponsorship.',
        'source': 'DFC Drone Racing',
        'category': 'Drone Racing',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/dfc2_image_.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 6)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // DRONE RACING — FPV Content, Videos & Racing News
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'FPV Drone Racing 101: What You Need to Know',
        'summary':
            'First-person view racing explained. Goggles, quads, frequencies, and why pilots call it "the most exhilarating sport you\'ve never heard of."',
        'source': 'DFC Drone Racing',
        'category': 'Drone Racing',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/datafightlogo.png',
        'videoUrl': 'https://youtube.com/watch?v=fpv-intro-2026',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 2)),
        ),
      },
      {
        'title': 'WATCH: Insane FPV Footage from DFC Brisbane Grand Prix',
        'summary':
            'Full race replay from Round 3. Neon gates, 180km/h speeds, and a photo finish that left crowds screaming. Warning: motion sickness possible.',
        'source': 'DFC Video',
        'category': 'Drone Racing',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=dfc-brisbane-fpv-gp',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 4)),
        ),
      },
      {
        'title': 'DJI FPV 3 Review: The Best Entry-Level Race Drone?',
        'summary':
            'We tested DJI\'s latest FPV drone against the competition. Spoiler: it\'s fast, it\'s smooth, but purists might prefer custom builds.',
        'source': 'DFC Tech',
        'category': 'Drone Racing',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=dji-fpv3-review',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 8)),
        ),
      },
      {
        'title': 'Melbourne Drone Racing League: 2026 Season Kicks Off',
        'summary':
            '32 pilots, 8 venues, \$50,000 prize pool. The Melbourne Drone Racing League returns bigger than ever. Full schedule inside.',
        'source': 'DFC Drone Racing',
        'category': 'Drone Racing',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/dfc_and_back_ground.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 9)),
        ),
      },
      {
        'title': 'LIVE: Sydney Harbour FPV Night Race — Full Broadcast',
        'summary':
            'Drones racing through neon gates with the Opera House backdrop. The most cinematic FPV event ever held. 2-hour full broadcast.',
        'source': 'DFC Video',
        'category': 'Drone Racing',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=sydney-harbour-fpv-live',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 5)),
        ),
      },
      {
        'title': 'How to Build Your First FPV Racing Drone — Complete Guide',
        'summary':
            'Frame selection, motors, flight controllers, ESCs, and camera setup. Build a competitive racer for under \$400 AUD.',
        'source': 'DFC Tech',
        'category': 'Drone Racing',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=build-fpv-drone-guide',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 11)),
        ),
      },
      {
        'title': 'Red Bull Air Strike: Top 10 Crashes of Season 1',
        'summary':
            'When drones hit gates at 200km/h, things get dramatic. The most spectacular crashes from Red Bull Air Strike — nobody was hurt, just carbon fiber.',
        'source': 'DFC Video',
        'category': 'Drone Racing',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=redbull-airstrike-crashes',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 7)),
        ),
      },
      {
        'title': 'NZ Drone Racing Championship: Auckland Showdown',
        'summary':
            'New Zealand\'s fastest pilots compete at Eden Park. Full results, interviews, and next-gen drone tech on display.',
        'source': 'DFC Drone Racing',
        'category': 'Drone Racing',
        'region': 'New Zealand',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 13)),
        ),
      },
      {
        'title': 'Analog vs Digital FPV: Which System Wins in 2026?',
        'summary':
            'DJI O4, HDZero, Walksnail — we compare latency, image quality, and range. The definitive guide for serious racers.',
        'source': 'DFC Tech',
        'category': 'Drone Racing',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=analog-vs-digital-fpv-2026',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 14)),
        ),
      },
      {
        'title': 'Women in FPV: Meet Australia\'s Fastest Female Drone Pilot',
        'summary':
            'From RC cars to FPV racing, Sarah "VelocityQueen" Chen is breaking records and stereotypes. Exclusive interview and cockpit footage.',
        'source': 'DFC Drone Racing',
        'category': 'Drone Racing',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=velocityqueen-interview',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 15)),
        ),
      },
      {
        'title': 'WATCH: POV Helmet Cam — What It\'s Like to Pilot at 180km/h',
        'summary':
            'Strap on your goggles. This first-person footage shows exactly what FPV pilots see during a race. Prepare for sensory overload.',
        'source': 'DFC Video',
        'category': 'Drone Racing',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=fpv-pov-180kmh-race',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 10)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // TECH & INNOVATION — Products, Gear & Fight Tech News
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title':
            'Hayabusa T4 Boxing Gloves: The Most Advanced Gloves Ever Made?',
        'summary':
            'Dual-X closure, Deltra-EGTM padding, wrist-lock technology. We tested Hayabusa\'s flagship gloves. Full review inside.',
        'source': 'DFC Gear',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 16)),
        ),
      },
      {
        'title':
            'AI Corner Coaching: The App That Analyzes Your Technique in Real-Time',
        'summary':
            'Point your phone at the bag, throw combos, get instant feedback. "FightIQ" app uses computer vision to coach you like a pro.',
        'source': 'DFC Tech',
        'category': 'Innovation',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 17)),
        ),
      },
      {
        'title': 'Smart Mouth Guards: Tracking Concussion Impact in Real-Time',
        'summary':
            'Prevent Sports startup launches mouthguard with accelerometers. Coaches get alerts when impact exceeds safe thresholds.',
        'source': 'DFC Safety',
        'category': 'Innovation',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 18)),
        ),
      },
      {
        'title': 'Venum UFC Gloves 2.0: What\'s Changed and Is It Worth It?',
        'summary':
            'The official UFC glove gets an update. Knuckle protection, thumb placement, and wrist support analyzed by pro fighters.',
        'source': 'DFC Gear',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 19)),
        ),
      },
      {
        'title':
            'Apple Vision Pro for Fight Analysis: Game Changer or Gimmick?',
        'summary':
            'Coaches are using spatial computing to analyze fights in 3D. We visited a Sydney gym using Vision Pro for corner work.',
        'source': 'DFC Tech',
        'category': 'Innovation',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 20)),
        ),
      },
      {
        'title': 'Best Budget Boxing Gloves 2026: Under \$50 Picks',
        'summary':
            'You don\'t need to spend \$200 to train. Our top 5 budget gloves that won\'t destroy your wrists or wallet.',
        'source': 'DFC Gear',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 21)),
        ),
      },
      {
        'title':
            'Whoop 5.0 vs Oura Ring 4: Which Recovery Tracker Wins for Fighters?',
        'summary':
            'HRV, sleep stages, strain scores — we compare the two most popular recovery wearables for combat athletes.',
        'source': 'DFC Tech',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 22)),
        ),
      },
      {
        'title': 'The Rise of Smart Heavy Bags: Train Smarter, Hit Harder',
        'summary':
            'FightCamp, Liteboxer, and new AI-powered bags that track punch speed, power, and accuracy. The future of home training.',
        'source': 'DFC Tech',
        'category': 'Innovation',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 23)),
        ),
      },
      {
        'title': 'Garmin Instinct 3 Solar: The Ultimate Fighter\'s Watch?',
        'summary':
            'GPS, heart rate, sleep tracking, and solar charging. Plus it survives being thrown across the gym. Full review.',
        'source': 'DFC Gear',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 24)),
        ),
      },
      {
        'title': 'VR Boxing Training: Does It Actually Improve Your Skills?',
        'summary':
            'We spent 30 days training with Thrill of the Fight and BoxVR. Here\'s whether virtual boxing translates to real skills.',
        'source': 'DFC Tech',
        'category': 'Innovation',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=vr-boxing-30day-test',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 25)),
        ),
      },
      {
        'title': 'BJJ Gi vs No-Gi Rash Guards: Best Brands of 2026',
        'summary':
            'Shoyoroll, Origin, Sanabul, Tatami — we rank the top brands for gi and no-gi grappling apparel.',
        'source': 'DFC Gear',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 26)),
        ),
      },
      {
        'title': 'AI Sparring Robots: The Future or Just a Fancy Bag?',
        'summary':
            'Chinese startup unveils humanoid robot that can spar and adapt. We visited the lab to see if it\'s real or hype.',
        'source': 'DFC Tech',
        'category': 'Innovation',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=ai-sparring-robot-demo',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 27)),
        ),
      },
      {
        'title':
            'Custom 3D-Printed Mouthguards: Perfect Fit, Maximum Protection',
        'summary':
            'Scan your teeth with your phone, receive a custom mouthguard in 7 days. We tested 3 services.',
        'source': 'DFC Gear',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 28)),
        ),
      },
      {
        'title': 'Drone Delivery for Fight Gear: Same-Day Gloves in Sydney',
        'summary':
            'Wing drone delivery now includes combat sports gear in Sydney metro. Order gloves at 10am, get them by 2pm.',
        'source': 'DFC Tech',
        'category': 'Innovation',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 29)),
        ),
      },
      {
        'title': 'The Science of Shin Conditioning: Myth vs Reality',
        'summary':
            'Does kicking trees actually work? Sports scientists explain what really hardens shins — and what just causes injury.',
        'source': 'DFC Training',
        'category': 'Training',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 30)),
        ),
      },
      {
        'title': 'DFC x GoPro: Action Cameras for Fight Recording',
        'summary':
            'GoPro Hero 13 and the new chest/head mounts designed for cornermen. Capture every angle of training and competition.',
        'source': 'DFC Gear',
        'category': 'Products',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 31)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // BEHIND THE MIC — The Voices, Refs, Judges & Unsung Heroes
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Bruce Buffer: The Voice of the Octagon',
        'summary':
            '"IIIIIIT\'S TIIIIIIME!" How Bruce Buffer became the most iconic announcer in combat sports. His journey from struggling actor to UFC legend.',
        'source': 'DFC Legends',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 60)),
        ),
      },
      {
        'title': 'Michael Buffer: The Original "Let\'s Get Ready to Rumble"',
        'summary':
            'He trademarked six words and made \$400 million. Michael Buffer\'s legendary career and how he invented the modern ring announcement.',
        'source': 'DFC Legends',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 62)),
        ),
      },
      {
        'title': 'The Buffer Brothers: A Tale of Two Voices',
        'summary':
            'Michael does boxing, Bruce does UFC. They\'re half-brothers who found each other in their 30s. The incredible story of the Buffer family.',
        'source': 'DFC Feature',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 64)),
        ),
      },
      {
        'title': 'Big John McCarthy: The Godfather of MMA Refereeing',
        'summary':
            '"Are you ready? Are you ready? Let\'s get it on!" How Big John McCarthy created the rules of modern MMA and saved countless lives.',
        'source': 'DFC Legends',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 66)),
        ),
      },
      {
        'title': 'Herb Dean: The Silent Guardian',
        'summary':
            'He\'s refereed more UFC title fights than anyone. Herb Dean on split-second decisions, the weight of responsibility, and life as MMA\'s top ref.',
        'source': 'DFC FightWire',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 68)),
        ),
      },
      {
        'title': 'Marc Goddard: From Fighter to Referee',
        'summary':
            'The British ref who fought professionally before becoming one of MMA\'s most respected officials. Inside Marc Goddard\'s journey.',
        'source': 'DFC FightWire',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 70)),
        ),
      },
      {
        'title': 'The Judges Nobody Knows: Inside MMA Scoring',
        'summary':
            'They decide careers with scorecards. We spoke to three anonymous MMA judges about pressure, death threats, and controversial decisions.',
        'source': 'DFC Investigation',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 72)),
        ),
      },
      {
        'title': 'Boxing\'s Third Man: The Art of Refereeing',
        'summary':
            'Mills Lane, Steve Smoger, Kenny Bayless — the referees who protected champions and stopped fights at the right moment. Their untold stories.',
        'source': 'DFC Legends',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 74)),
        ),
      },
      {
        'title': 'Stitch Duran: The Cutman Who Saved Hundreds of Fights',
        'summary':
            'Blood, swelling, broken bones — Stitch Duran has seen it all. The legendary cutman on 30 years of keeping fighters in the game.',
        'source': 'DFC Legends',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 76)),
        ),
      },
      {
        'title': 'The Corner: Where Fights Are Won and Lost',
        'summary':
            'They wipe the blood, close the cuts, and whisper the words that change everything. Inside the life of cornermen and women.',
        'source': 'DFC Feature',
        'category': 'Behind the Scenes',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 78)),
        ),
      },
      {
        'title': 'Ringside Physicians: The Doctors Who Step Into Danger',
        'summary':
            'They check pupils between rounds and stop fights to save lives. Meeting the ringside doctors who carry the weight of fighter safety.',
        'source': 'DFC Safety',
        'category': 'Behind the Scenes',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 80)),
        ),
      },
      {
        'title': 'Jimmy Lennon Jr: Boxing\'s Smoothest Voice',
        'summary':
            '"And the new..." Jimmy Lennon Jr carries on his father\'s legacy as boxing\'s premier announcer. Elegance, tradition, and class at ringside.',
        'source': 'DFC Legends',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 82)),
        ),
      },
      {
        'title': 'Joe Martinez: The Bilingual Voice of Boxing',
        'summary':
            'From Spanish radio to Showtime, Joe Martinez brings Latino heritage and passion to every ring announcement. His inspiring journey.',
        'source': 'DFC FightWire',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 84)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // BEAUTY BEHIND THE BLOOD — Ring Card Girls & The Women Who Make It Shine
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Arianny Celeste: 15 Years as the Face of the UFC',
        'summary':
            'She walked into the Octagon at UFC 66 and never left. Arianny Celeste on modeling, motherhood, and being combat sports\' longest-serving ring girl.',
        'source': 'DFC Feature',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 86)),
        ),
      },
      {
        'title': 'Brittney Palmer: From the Octagon to the Art Gallery',
        'summary':
            'She\'s held round cards for a decade and sold paintings for six figures. Brittney Palmer on building two careers in parallel.',
        'source': 'DFC Feature',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 88)),
        ),
      },
      {
        'title': 'The Business of Being a Ring Card Girl',
        'summary':
            'Contracts, travel schedules, social media deals — we spoke to five current ring card girls about what the job really involves.',
        'source': 'DFC Business',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 90)),
        ),
      },
      {
        'title': 'Beyond the Cards: Ring Girls Who Became Fighters',
        'summary':
            'Some walked with round cards before walking into the cage. Meet the women who went from ring girl to competitor.',
        'source': 'DFC Feature',
        'category': 'Behind the Scenes',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 92)),
        ),
      },
      {
        'title': 'Australia\'s Ring Girls: The Sydney to Vegas Pipeline',
        'summary':
            'From local boxing shows to UFC events — how Australian women are breaking into the international ring card circuit.',
        'source': 'DFC FightWire',
        'category': 'Behind the Scenes',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 94)),
        ),
      },
      {
        'title': 'The Debate: Should Ring Card Girls Still Exist?',
        'summary':
            'Some say it\'s tradition, others call it outdated. We present both sides of the most divisive topic in combat sports presentation.',
        'source': 'DFC Opinion',
        'category': 'Behind the Scenes',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 96)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // THE RING BUILDERS — Lighting, Rigging, Production Crews
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Building the Octagon: 72 Hours Before Fight Night',
        'summary':
            'It takes 12 people and 18 hours to build a UFC Octagon. We followed the crew setting up for UFC Sydney.',
        'source': 'DFC Behind the Scenes',
        'category': 'Behind the Scenes',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 98)),
        ),
      },
      {
        'title': 'The Canvas Artists: Designing Fight Night Graphics',
        'summary':
            'From the canvas logos to the LED displays — meet the graphic designers who create the visual identity of fight events.',
        'source': 'DFC Creative',
        'category': 'Behind the Scenes',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 100)),
        ),
      },
      {
        'title': 'The Sound of Combat: Audio Engineers at Ringside',
        'summary':
            'Punches, crowd roars, corner advice — capturing the sounds of fighting requires incredible skill. Inside the audio truck.',
        'source': 'DFC Tech',
        'category': 'Behind the Scenes',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 102)),
        ),
      },
      {
        'title': '50 Cameras, One Fight: The Broadcast Revolution',
        'summary':
            'How modern fight broadcasts use 50+ cameras, instant replay systems, and AI-assisted editing to capture every angle.',
        'source': 'DFC Tech',
        'category': 'Behind the Scenes',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=fight-broadcast-tech',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 104)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // MENTAL HEALTH & IDENTITY LOSS — Life After Fighting
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Identity Loss: The Hardest Fight Happens After Retirement',
        'summary':
            'When fighting IS your identity, who are you without it? Champions and journeymen share their struggles with post-career depression.',
        'source': 'DFC Mind & Body',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 106)),
        ),
      },
      {
        'title': '"I Didn\'t Know Who I Was Anymore": Fighters on Retirement',
        'summary':
            'Six fighters tell their stories of leaving the sport. The silence after the last bell. Finding purpose when the gloves come off.',
        'source': 'DFC Feature',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 108)),
        ),
      },
      {
        'title':
            'The Psychology of Fighter Identity: Why Retirement Breaks Hearts',
        'summary':
            'Sports psychologists explain why fighters struggle more than other athletes with retirement. It\'s not just a job — it\'s who you are.',
        'source': 'DFC Mind & Body',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 110)),
        ),
      },
      {
        'title': 'Diego Sanchez: "I Lost Myself in the Fight Game"',
        'summary':
            'The TUF pioneer on brain trauma, toxic relationships, finding spirituality, and rebuilding after decades in the Octagon.',
        'source': 'DFC Feature',
        'category': 'Mental Health',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 112)),
        ),
      },
      {
        'title': 'CTE and the Conversation Nobody Wants to Have',
        'summary':
            'Brain trauma in combat sports is real. We speak to neurologists, former fighters, and families about the elephant in the room.',
        'source': 'DFC Safety',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 114)),
        ),
      },
      {
        'title': 'Connor McKinnon: "Depression Nearly Killed Me"',
        'summary':
            'The Gypsy King\'s battles outside the ring. How Connor McKinnon went from 181 kg (400 pounds) and suicidal to heavyweight champion of the world.',
        'source': 'DFC Feature',
        'category': 'Mental Health',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 116)),
        ),
      },
      {
        'title': 'From Warrior to What? Building a Second Career',
        'summary':
            'Coaching, commentary, business — how fighters successfully transition to post-competition life. Practical advice from those who made it.',
        'source': 'DFC Career',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 118)),
        ),
      },
      {
        'title': 'The Quiet Crisis: Fighter Suicide and What We Can Do',
        'summary':
            'Too many warriors have taken their own lives. Understanding the warning signs and the resources available. You are not alone.',
        'source': 'DFC Mind & Body',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 120)),
        ),
      },
      {
        'title': 'Therapy for Fighters: Breaking the Stigma',
        'summary':
            '"Real men don\'t talk about feelings." Wrong. Champions like Jean-Luc Moreau and Jessica Palmer prove that mental health care is strength.',
        'source': 'DFC Mind & Body',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 122)),
        ),
      },
      {
        'title': 'Australia\'s Fighter Support Network: You\'re Not Alone',
        'summary':
            'DFC partners with Beyond Blue and Headspace to provide free mental health support for Australian combat athletes. Resources inside.',
        'source': 'DFC Community',
        'category': 'Mental Health',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 124)),
        ),
      },
      {
        'title': 'The Long Walk Back: Returning to Civilian Life',
        'summary':
            'No more training camps. No more weigh-ins. Just... normal life. Fighters share how they adjusted — and how some never did.',
        'source': 'DFC Feature',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 126)),
        ),
      },
      {
        'title': 'Kevin Lee: "Losing Fights Destroyed My Mental Health"',
        'summary':
            'The Motown Phenom opens up about the pressure of being a prospect, the pain of falling short, and finding peace after the UFC.',
        'source': 'DFC Feature',
        'category': 'Mental Health',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 128)),
        ),
      },
      {
        'title': 'Meditation and Mindfulness: The New Fighter\'s Edge',
        'summary':
            'From Master Kenzo Yamamoto to Israel Adesanya — how meditation became a secret weapon in combat sports. Techniques you can use.',
        'source': 'DFC Training',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 130)),
        ),
      },
      {
        'title': 'The Cornerman\'s Burden: Watching Your Fighter Get Hurt',
        'summary':
            'Coaches and cornermen carry trauma too. The emotional weight of watching someone you trained get knocked out.',
        'source': 'DFC Feature',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 132)),
        ),
      },
      {
        'title': 'Life After Loss: Coping When Your Record Ends',
        'summary':
            'Undefeated no more. How fighters psychologically recover from their first loss — and come back stronger.',
        'source': 'DFC Mind & Body',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 134)),
        ),
      },
      {
        'title': 'Finding Family: Building Community After Competition',
        'summary':
            'Gyms aren\'t just for training — they\'re support networks. How retired fighters stay connected and help the next generation.',
        'source': 'DFC Community',
        'category': 'Mental Health',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 136)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // PREVENTION & NUTRITION — Food as Medicine, Injury Prevention
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Prevention Over Cure: The Fighter\'s Wellness Revolution',
        'summary':
            'Elite fighters are shifting from treating injuries to preventing them. How nutrition, sleep, and recovery are replacing painkillers and surgery.',
        'source': 'DFC Mind & Body',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 138)),
        ),
      },
      {
        'title': 'Food as Medicine: How Diet Heals Fighters',
        'summary':
            'Anti-inflammatory foods, gut health, and nutrient timing. Sports nutritionists reveal how food can repair damage faster than drugs.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 140)),
        ),
      },
      {
        'title': 'Nate Diaz: The Plant-Based Warrior',
        'summary':
            'The Stockton slapper on his plant-based diet, recovery, and why he believes meat-free living made him a better fighter.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 142)),
        ),
      },
      {
        'title':
            'Mike Tyson\'s Transformation: From 181 kg (400 Pounds) to Fit at 59',
        'summary':
            'Iron Mike went vegan, lost 64 kg (140 pounds), and found peace. His diet, his routine, and how food changed his life after boxing.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 144)),
        ),
      },
      {
        'title': 'The Anti-Inflammation Diet for Fighters',
        'summary':
            'Turmeric, omega-3s, berries, leafy greens — the foods that reduce swelling, speed recovery, and keep joints healthy longer.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 146)),
        ),
      },
      {
        'title': 'Gut Health and Performance: The Second Brain',
        'summary':
            'Your gut controls your mood, energy, and recovery. How fighters are using probiotics and fermented foods to gain an edge.',
        'source': 'DFC Mind & Body',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 148)),
        ),
      },
      {
        'title': 'Injury Prevention: Prehab is Better Than Rehab',
        'summary':
            'Mobility work, strength training, and movement screening. How smart fighters prevent injuries before they happen.',
        'source': 'DFC Training',
        'category': 'Prevention',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 150)),
        ),
      },
      {
        'title': 'The Weight Cut Crisis: Why Fighters Are Dying',
        'summary':
            'Extreme dehydration kills. We investigate the weight cutting culture and the fighters pushing for change.',
        'source': 'DFC Safety',
        'category': 'Prevention',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 152)),
        ),
      },
      {
        'title': 'Hydration Science: Beyond Just Drinking Water',
        'summary':
            'Electrolytes, timing, and the science of optimal hydration. What fighters get wrong about water — and how to fix it.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 154)),
        ),
      },
      {
        'title': 'Sleep: The Free Performance Enhancer',
        'summary':
            '8 hours minimum. Why elite fighters prioritize sleep over extra training, and how to optimize your rest.',
        'source': 'DFC Mind & Body',
        'category': 'Prevention',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 156)),
        ),
      },
      {
        'title': 'Bone Broth, Collagen, and Connective Tissue Health',
        'summary':
            'The ancient remedy that modern science is validating. How collagen and bone broth help fighters heal faster.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 158)),
        ),
      },
      {
        'title': 'GSP\'s Longevity Secrets: How He Stayed Injury-Free',
        'summary':
            'Jean-Luc Moreau trained for 15+ years with minimal injuries. His mobility routine, diet, and philosophy on prevention.',
        'source': 'DFC Feature',
        'category': 'Prevention',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 160)),
        ),
      },
      {
        'title': 'Meal Prep for Fighters: A Week of Champion Fuel',
        'summary':
            'What does a UFC contender eat for 7 days? Complete meal plan with recipes, macros, and shopping list.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 162)),
        ),
      },
      {
        'title': 'The Supplement Truth: What Actually Works',
        'summary':
            'Creatine, protein, vitamins — which supplements are worth your money? Sports scientists cut through the marketing.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 164)),
        ),
      },
      {
        'title': 'Cold Therapy and Heat: Recovery Without Drugs',
        'summary':
            'Ice baths, saunas, contrast therapy — the science behind temperature-based recovery and how fighters use it.',
        'source': 'DFC Training',
        'category': 'Prevention',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 166)),
        ),
      },
      {
        'title': 'Sugar: The Hidden Enemy of Fighter Performance',
        'summary':
            'Inflammation, energy crashes, weight gain — how cutting sugar transformed these fighters\' careers.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 168)),
        ),
      },
      {
        'title': 'Stretching vs Mobility: What Fighters Need to Know',
        'summary':
            'Static stretching is old school. Dynamic mobility is the new standard. How to bulletproof your body for combat.',
        'source': 'DFC Training',
        'category': 'Prevention',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 170)),
        ),
      },
      {
        'title': 'Fasting for Fighters: Benefits and Risks',
        'summary':
            'Intermittent fasting, prolonged fasts, and autophagy. When fasting helps and when it hurts performance.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 172)),
        ),
      },
      {
        'title': 'Natural Painkillers: Alternatives to NSAIDs',
        'summary':
            'Ibuprofen damages your gut. Try turmeric, CBD, ginger, and other natural anti-inflammatories instead.',
        'source': 'DFC Mind & Body',
        'category': 'Prevention',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 174)),
        ),
      },
      {
        'title': 'The Fighter\'s Kitchen: Cooking Skills for Champions',
        'summary':
            'Stop eating out. Learn to cook like a nutritionist. Simple recipes that fuel performance and save money.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 176)),
        ),
      },
      {
        'title': 'Overtraining: When More Training Makes You Weaker',
        'summary':
            'Rest is part of training. How to recognize overtraining syndrome and why the best fighters know when to stop.',
        'source': 'DFC Training',
        'category': 'Prevention',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 178)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // REAL FOOD, NOT PACKETS — Whole Foods Philosophy
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Ditch the Shakes: Why Whole Foods Beat Powders Every Time',
        'summary':
            'Protein powder is no substitute for real food. The science behind why whole eggs, fish, and meat outperform supplements.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 180)),
        ),
      },
      {
        'title': 'If It Comes in a Packet, It\'s Probably Not Food',
        'summary':
            'Processed supplements, meal replacements, and "superfoods" in boxes are marketing, not nutrition. What to eat instead.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 182)),
        ),
      },
      {
        'title': 'The Original Pre-Workout: Eggs, Oats, and Real Coffee',
        'summary':
            'Before neon-colored powders, fighters fueled on whole foods. Why traditional pre-fight meals still work better.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 184)),
        ),
      },
      {
        'title':
            'Your Grandparents Ate Better Than You: Lessons from Traditional Diets',
        'summary':
            'Before packaged foods, people ate meat, vegetables, fruit, and whole grains. The forgotten wisdom of ancestral nutrition.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 186)),
        ),
      },
      {
        'title': 'Eat the Rainbow: How Coloured Vegetables Heal Fighters',
        'summary':
            'Red capsicum, purple cabbage, orange carrots — each colour provides different phytonutrients. Nature\'s pharmacy is free.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 188)),
        ),
      },
      {
        'title': 'Why UFC Nutritionists Are Ditching Supplements',
        'summary':
            'Top fight dietitians explain why they\'re moving clients to 100% whole food diets. The performance gains are real.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 190)),
        ),
      },
      {
        'title': 'Shop the Perimeter: A Fighter\'s Guide to the Supermarket',
        'summary':
            'Fresh produce, meat, dairy — the good stuff lives on the edges. Avoid the aisles of processed garbage.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 192)),
        ),
      },
      {
        'title': 'Liver, Heart, Kidney: Organ Meats — The Original Superfood',
        'summary':
            'Before açaí berries had marketing budgets, fighters ate organs. More vitamins per gram than any supplement.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 194)),
        ),
      },
      {
        'title':
            'Fermented Foods: Kimchi, Sauerkraut, and Yoghurt for Gut Health',
        'summary':
            'Probiotics from real food beat capsules. How traditional fermented foods build a champion\'s gut microbiome.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 196)),
        ),
      },
      {
        'title':
            'Cooking with Fat: The Return of Butter, Tallow, and Olive Oil',
        'summary':
            'Seed oils are inflammatory. Traditional fats are back. How real cooking fats support fighter recovery.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 198)),
        ),
      },
      {
        'title':
            'Fruit is Medicine: Berries, Citrus, and Nature\'s Antioxidants',
        'summary':
            'Vitamin C capsules can\'t replicate an orange. Phytonutrients, fiber, and synergy — why whole fruit heals.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 200)),
        ),
      },
      {
        'title': 'The Problem with Protein Bars: Sugar in Disguise',
        'summary':
            'Most "health" bars are candy with branding. How to read labels and why real food is always better.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 202)),
        ),
      },
      {
        'title': 'Fish, Seafood, and Omega-3s: From the Ocean, Not a Capsule',
        'summary':
            'Salmon, sardines, oysters — whole seafood provides omega-3s with protein and minerals. Skip the fish oil pills.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 204)),
        ),
      },
      {
        'title': 'Local Farmers Markets: Where Champions Shop',
        'summary':
            'Fresh, seasonal, local — how buying from farmers markets supports health, community, and peak performance.',
        'source': 'DFC Community',
        'category': 'Nutrition',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 206)),
        ),
      },
      {
        'title': 'The Mediterranean Diet for Fighters',
        'summary':
            'Olive oil, fish, vegetables, legumes — why the world\'s healthiest diet works perfectly for combat athletes.',
        'source': 'DFC Nutrition',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 208)),
        ),
      },
      {
        'title': 'Grow Your Own: Backyard Vegetables for Fighters',
        'summary':
            'Nothing beats homegrown. Simple guide to growing spinach, tomatoes, and herbs that fuel your training.',
        'source': 'DFC Community',
        'category': 'Nutrition',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 210)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // SUPPLEMENTS & PERFORMANCE — Latest Products & Legal Enhancers
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': '2026 Supplement Guide: What\'s New and What Actually Works',
        'summary':
            'From beta-alanine to turkesterone — the latest supplements reviewed. Science-backed analysis of what\'s worth your money.',
        'source': 'DFC Gear',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 212)),
        ),
      },
      {
        'title': 'Creatine: Still the King of Legal Performance Enhancers',
        'summary':
            'Decades of research confirm it works. How creatine monohydrate improves power, recovery, and even brain function.',
        'source': 'DFC Supplements',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 214)),
        ),
      },
      {
        'title': 'Caffeine: The World\'s Most Popular Performance Drug',
        'summary':
            'Timing, dosage, and tolerance. How to use caffeine strategically for training and competition.',
        'source': 'DFC Supplements',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 216)),
        ),
      },
      {
        'title': 'Beta-Alanine: The Tingle That Boosts Endurance',
        'summary':
            'That itchy skin means it\'s working. How beta-alanine buffers lactic acid and extends your gas tank.',
        'source': 'DFC Supplements',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 218)),
        ),
      },
      {
        'title': 'Ashwagandha: The Adaptogen Fighters Are Using for Recovery',
        'summary':
            'Stress reduction, testosterone support, and better sleep. The ancient herb gaining modern scientific backing.',
        'source': 'DFC Supplements',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 220)),
        ),
      },
      {
        'title': 'Electrolyte Supplements: Beyond Gatorade',
        'summary':
            'Sodium, potassium, magnesium — premium electrolyte products reviewed for fighters who sweat heavily.',
        'source': 'DFC Gear',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 222)),
        ),
      },
      {
        'title': 'Turkesterone and Ecdysterone: Hype or Hope?',
        'summary':
            'The "natural anabolic" supplements everyone\'s talking about. We review the evidence — and it\'s mixed.',
        'source': 'DFC Supplements',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 224)),
        ),
      },
      {
        'title': 'Nitric Oxide Boosters: Better Pumps, Better Performance?',
        'summary':
            'L-citrulline, beetroot extract, and arginine — do vasodilators actually improve training? The science.',
        'source': 'DFC Supplements',
        'category': 'Supplements',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 226)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // NATURAL PAIN RELIEF — Alternatives to Pharmaceuticals
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'CBD for Fighters: Pain Relief Without the High',
        'summary':
            'Nate Diaz vapes it post-fight. The science behind CBD oil for inflammation, anxiety, and recovery.',
        'source': 'DFC Mind & Body',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 228)),
        ),
      },
      {
        'title': 'Turmeric and Curcumin: Nature\'s Anti-Inflammatory',
        'summary':
            'Golden milk isn\'t just trendy. How curcumin reduces joint pain and speeds recovery naturally.',
        'source': 'DFC Supplements',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 230)),
        ),
      },
      {
        'title': 'Arnica, Magnesium, and Epsom Salts: The Recovery Bath',
        'summary':
            'Old school but effective. How topical remedies and mineral soaks help fighters recover faster.',
        'source': 'DFC Mind & Body',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 232)),
        ),
      },
      {
        'title': 'Ginger: The Natural Painkiller in Your Kitchen',
        'summary':
            'Anti-inflammatory, anti-nausea, and delicious. How fighters are using ginger for natural pain management.',
        'source': 'DFC Nutrition',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 234)),
        ),
      },
      {
        'title': 'Acupuncture and Dry Needling for Fight Recovery',
        'summary':
            'Needles that heal, not hurt. How ancient Chinese medicine is helping modern fighters manage pain.',
        'source': 'DFC Mind & Body',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 236)),
        ),
      },
      {
        'title': 'Massage Guns, Percussion Therapy, and Myofascial Release',
        'summary':
            'Theragun, Hypervolt, and budget options compared. Do percussion devices actually speed recovery?',
        'source': 'DFC Gear',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 238)),
        ),
      },
      {
        'title': 'Tart Cherry Juice: The Natural Recovery Drink',
        'summary':
            'Anthocyanins reduce muscle soreness and improve sleep. Why tart cherry juice is a fighter\'s secret weapon.',
        'source': 'DFC Nutrition',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 240)),
        ),
      },
      {
        'title': 'TENS Units and EMS: Electrical Pain Relief at Home',
        'summary':
            'Transcutaneous electrical nerve stimulation explained. How fighters use electrical therapy for pain management.',
        'source': 'DFC Tech',
        'category': 'Pain Relief',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 242)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // TRAINING TECH — Latest Gadgets & Performance Equipment
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Best Training Tech of 2026: Gadgets That Actually Help',
        'summary':
            'Wearables, sensors, apps, and equipment. Our picks for the tech that makes a real difference in training.',
        'source': 'DFC Tech',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 244)),
        ),
      },
      {
        'title': 'Smart Training Sensors: Punch Trackers and Force Plates',
        'summary':
            'Hykso, PowerKube, and new punch tracking tech. Measure your power, speed, and volume precisely.',
        'source': 'DFC Tech',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 246)),
        ),
      },
      {
        'title':
            'Heart Rate Monitors for Combat Athletes: Chest Straps vs Watches',
        'summary':
            'Polar, Garmin, Whoop — which HRM works best for high-intensity combat training? Accuracy tested.',
        'source': 'DFC Gear',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 248)),
        ),
      },
      {
        'title': 'Altitude Training Masks: Do They Actually Work?',
        'summary':
            'The science behind hypoxic training devices. Spoiler: they don\'t simulate altitude, but they might still help.',
        'source': 'DFC Tech',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 250)),
        ),
      },
      {
        'title':
            'Blood Flow Restriction (BFR) Training: Build Muscle with Light Weights',
        'summary':
            'Occlude blood flow, grow muscle faster. The science and safety of BFR bands for fighters.',
        'source': 'DFC Training',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 252)),
        ),
      },
      {
        'title': 'Red Light Therapy: The Recovery Tool Going Mainstream',
        'summary':
            'Joovv, Mito Red, and DIY setups. Does photobiomodulation actually speed healing? The evidence.',
        'source': 'DFC Tech',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 254)),
        ),
      },
      {
        'title': 'Compression Boots: NormaTec, Hyperice, and Recovery Pants',
        'summary':
            'Pneumatic compression for leg recovery. Which boots are worth the investment? Full comparison.',
        'source': 'DFC Gear',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 256)),
        ),
      },
      {
        'title': 'Sleep Trackers: Oura, Whoop, and Eight Sleep Reviewed',
        'summary':
            'Recovery starts with sleep. Which trackers give the most actionable data for optimizing rest?',
        'source': 'DFC Tech',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 258)),
        ),
      },
      {
        'title': 'Video Analysis Apps: Film Your Training Like a Pro',
        'summary':
            'Dartfish, CoachNow, and free alternatives. How to record and analyse your technique for rapid improvement.',
        'source': 'DFC Tech',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=video-analysis-apps-fighters',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 260)),
        ),
      },
      {
        'title': 'Underwater Treadmills and Anti-Gravity Training',
        'summary':
            'Alter-G and aquatic training for injured fighters. How to maintain fitness while recovering from injury.',
        'source': 'DFC Tech',
        'category': 'Training Tech',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 262)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // SPORTS SCIENCE — Energy Systems for Fighters
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'The Three Energy Systems Every Fighter Must Understand',
        'summary':
            'ATP-PC, anaerobic glycolysis, and aerobic systems explained. How your body fuels explosive power vs sustained cardio in combat.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 264)),
        ),
      },
      {
        'title': 'ATP-PC System: The First 10 Seconds of Explosive Power',
        'summary':
            'Phosphocreatine fuels your knockout punch. How to train the ATP-PC system for maximum explosive output in the cage.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 266)),
        ),
      },
      {
        'title': 'Anaerobic Glycolysis: Surviving the Middle Rounds',
        'summary':
            'When creatine runs out, glycolysis kicks in. Understanding lactate, hydrogen ions, and why your arms burn during scrambles.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 268)),
        ),
      },
      {
        'title': 'Aerobic System: The Engine That Never Stops',
        'summary':
            'Oxidative metabolism powers championship rounds. Building an aerobic base without sacrificing power — the science of fighter cardio.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 270)),
        ),
      },
      {
        'title': 'Energy System Training: Programming for Combat Athletes',
        'summary':
            'Interval ratios, work-to-rest, and periodization. How to structure training to develop all three energy pathways for fight readiness.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl':
            'https://youtube.com/watch?v=energy-system-training-fighters',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 272)),
        ),
      },
      {
        'title': 'Lactate Threshold Training for Fighters',
        'summary':
            'Push the burn further. How to raise your lactate threshold so you can sustain high intensity longer without gassing out.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 274)),
        ),
      },
      {
        'title':
            'VO2 Max for Combat Sports: How Much Cardio Do Fighters Really Need?',
        'summary':
            'The science of maximum oxygen uptake. Testing, training, and improving VO2 max while maintaining fight-specific conditioning.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 276)),
        ),
      },
      {
        'title':
            'Creatine and the ATP-PC System: The Science Behind the Supplement',
        'summary':
            'Why creatine works for explosive athletes. Saturation, loading, timing, and how it directly fuels your phosphagen system.',
        'source': 'DFC Sports Science',
        'category': 'Sports Science',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 278)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // BIOMECHANICS — Movement Science for Fighters
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Biomechanics 101: How Physics Powers Your Punch',
        'summary':
            'Force, velocity, momentum, and kinetic chains. Understanding the mechanics behind striking power and efficient movement.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 280)),
        ),
      },
      {
        'title': 'The Kinetic Chain: From Ground to Fist',
        'summary':
            'Power starts in your feet. How to link ankle, knee, hip, core, shoulder, and wrist for maximum force transfer in strikes.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=kinetic-chain-striking',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 282)),
        ),
      },
      {
        'title': 'Hip Rotation and Torque: The Engine of Power Punching',
        'summary':
            'Why the best strikers rotate, not push. Biomechanical analysis of hip drive in boxing, Muay Thai, and karate.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 284)),
        ),
      },
      {
        'title': 'Leverage in Grappling: Why Technique Beats Strength',
        'summary':
            'Torque, fulcrums, and mechanical advantage. The physics behind arm bars, sweeps, and escapes explained.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 286)),
        ),
      },
      {
        'title': 'Stance Width and Base of Support: Stability vs Mobility',
        'summary':
            'Wide vs narrow stance, high vs low posture. Finding the optimal balance point for your fighting style and body type.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 288)),
        ),
      },
      {
        'title': 'Foot Placement and Weight Distribution in Combat',
        'summary':
            'Where you put your feet determines everything. Analysis of optimal weight distribution for striking, defending, and transitioning.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 290)),
        ),
      },
      {
        'title': 'The Biomechanics of Head Movement',
        'summary':
            'Slips, rolls, and pulls analyzed. Minimal movement for maximum evasion — how elite boxers make you miss by millimeters.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'videoUrl': 'https://youtube.com/watch?v=head-movement-biomechanics',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 292)),
        ),
      },
      {
        'title': 'Kick Biomechanics: Roundhouse, Teep, and Spinning Attacks',
        'summary':
            'Pivot angles, hip extension, and rotational velocity. Breaking down kick technique through movement science.',
        'source': 'DFC Sports Science',
        'category': 'Biomechanics',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 294)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // MOTOR LEARNING — Skill Acquisition for Combat Athletes
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Motor Learning: How Fighters Build Automatic Skills',
        'summary':
            'From conscious effort to unconscious competence. The neuroscience of repetition, practice, and skill automation.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 296)),
        ),
      },
      {
        'title': 'Blocked vs Random Practice: Which Builds Better Fighters?',
        'summary':
            'Drilling one technique repeatedly vs mixing it up. Research on contextual interference and long-term skill retention.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 298)),
        ),
      },
      {
        'title': 'The 10,000 Hour Myth: Quality Over Quantity in Training',
        'summary':
            'Anders Ericsson\'s deliberate practice research applied to combat sports. Not all hours are created equal.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 300)),
        ),
      },
      {
        'title': 'Mental Rehearsal: Visualization as a Training Tool',
        'summary':
            'Your brain can\'t tell the difference. How mental practice creates real neural pathways for technique improvement.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 302)),
        ),
      },
      {
        'title': 'Reaction Time and Anticipation: Reading Your Opponent',
        'summary':
            'You can\'t react to everything — you have to predict. How elite fighters use pattern recognition to seem faster.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 304)),
        ),
      },
      {
        'title': 'Attentional Focus: Internal vs External Cues in Combat',
        'summary':
            'Think about your fist or the target? Research shows external focus produces better performance. How to cue technique.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 306)),
        ),
      },
      {
        'title': 'Implicit vs Explicit Learning: Coaching Styles That Work',
        'summary':
            'Tell them what to do or let them figure it out? The science of guided discovery and constraints-led coaching in combat.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 308)),
        ),
      },
      {
        'title':
            'Transfer of Training: Does Strength Training Make You Punch Harder?',
        'summary':
            'The tricky science of skill transfer. When gym gains translate to fight performance — and when they don\'t.',
        'source': 'DFC Sports Science',
        'category': 'Motor Learning',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 310)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // COMEBACK STORIES — Finding the Way Back After Being Broken
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Coming Back at 50+: It\'s Never Too Late to Fight Again',
        'summary':
            'Age is just a number. Fighters sharing their journeys back to training after decades, surgeries, and life getting in the way.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 312)),
        ),
      },
      {
        'title': 'Multiple Surgeries, Multiple Comebacks: The Road Back',
        'summary':
            'Knee reconstructions, shoulder repairs, back surgeries. Fighters who refused to stay down share their recovery journeys.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 314)),
        ),
      },
      {
        'title':
            'From Street Fighter to Martial Artist: Channeling the Warrior',
        'summary':
            'Many fighters started on the streets. Transforming raw aggression into disciplined martial arts — stories of redemption.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 316)),
        ),
      },
      {
        'title': 'Lost and Found: Rediscovering Purpose Through Combat Sports',
        'summary':
            'Depression, addiction, divorce, career collapse. How returning to the gym helped fighters find themselves again.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 318)),
        ),
      },
      {
        'title':
            'Thai Fight Veterans: The Scars We Carry, The Spirit That Remains',
        'summary':
            'Muay Thai legends who fought hundreds of times share wisdom for younger fighters. Longevity lessons from the stadium circuits.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Thailand',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 320)),
        ),
      },
      {
        'title': 'Training Smart at 40, 50, 60+: Adapting Your Approach',
        'summary':
            'Recovery takes longer, but wisdom cuts faster. How veteran fighters modify training to extend their martial arts journey.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 322)),
        ),
      },
      {
        'title': 'Body Broken, Spirit Unbreakable: Chronic Pain and Training',
        'summary':
            'Arthritis, old injuries, nerve damage. Fighters managing chronic conditions who refuse to give up their passion.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 324)),
        ),
      },
      {
        'title': 'From Patient to Coach: When Injuries Change Your Role',
        'summary':
            'Some comebacks aren\'t about fighting again. Veterans who transitioned to coaching and found new purpose in teaching.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 326)),
        ),
      },
      {
        'title': 'The Masters Division: Competition for Fighters 40+',
        'summary':
            'BJJ, boxing, kickboxing — organized masters competition is growing. Age-appropriate rulesets and the joy of competing again.',
        'source': 'DFC Lifestyle',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 328)),
        ),
      },
      {
        'title':
            'Randy Couture\'s Last Stand: Fighting Into His 40s at the Highest Level',
        'summary':
            'The Natural defied age, winning UFC titles at 43 and 44. His approach to training, recovery, and mental fortitude.',
        'source': 'DFC Legends',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 330)),
        ),
      },
      {
        'title':
            'George Foreman: The Greatest Comeback in Combat Sports History',
        'summary':
            'Knocked out Ali, retired, got fat, became a preacher, then won the heavyweight title at 45. The ultimate redemption story.',
        'source': 'DFC Legends',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 332)),
        ),
      },
      {
        'title': 'Bernard Hopkins: The Execution at Executive Age',
        'summary':
            'Unified middleweight at 49, light heavyweight champion at 48. Hopkins trained smarter, not just harder.',
        'source': 'DFC Legends',
        'category': 'Comeback Stories',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 334)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // LONGEVITY & LIFESTYLE — The Path to a Healthier, Longer Life
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Longevity 101: What Science Says About Living Longer, Better',
        'summary':
            'Dr. Peter Attia, David Sinclair, and longevity research applied to athletes. The pillars of healthspan for fighters.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 336)),
        ),
      },
      {
        'title': 'Zone 2 Cardio: The Unsexy Secret to a Long Fighting Life',
        'summary':
            'Low-intensity training builds mitochondria. Why easy cardio is essential for recovery and long-term athletic health.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 338)),
        ),
      },
      {
        'title': 'Sleep as a Performance Enhancing Drug',
        'summary':
            'Dr. Matthew Walker\'s research on sleep and athletic performance. Why 7-9 hours is non-negotiable for fighters.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 340)),
        ),
      },
      {
        'title': 'Stress, Cortisol, and Overtraining: When More Isn\'t Better',
        'summary':
            'Chronic stress kills gains and shortens careers. Recognizing overtraining and building recovery into your lifestyle.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 342)),
        ),
      },
      {
        'title':
            'Cold Exposure and Heat Therapy: Sauna, Ice Baths, and Longevity',
        'summary':
            'Hormesis and adaption. The evidence for cold plunges and sauna use in recovery and long-term health.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 344)),
        ),
      },
      {
        'title': 'Mobility for Life: Maintaining Range of Motion Into Old Age',
        'summary':
            'Use it or lose it. Daily mobility work that keeps fighters supple and injury-free for decades.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 346)),
        ),
      },
      {
        'title':
            'The Anti-Inflammatory Lifestyle: Reducing Chronic Inflammation',
        'summary':
            'Inflammation ages you faster. Dietary and lifestyle interventions to lower systemic inflammation for fighters.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 348)),
        ),
      },
      {
        'title': 'Fasting and Time-Restricted Eating for Athletes',
        'summary':
            'Intermittent fasting, autophagy, and athletic performance. When to eat, when to train, and when to fast.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 350)),
        ),
      },
      {
        'title':
            'Strength Training for Longevity: Maintaining Muscle Into Your 60s, 70s, 80s',
        'summary':
            'Sarcopenia is the enemy of aging. Why resistance training is the most powerful anti-aging intervention we have.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 352)),
        ),
      },
      {
        'title':
            'Community and Purpose: The Psychological Pillars of Long Life',
        'summary':
            'Blue Zones research shows it\'s not just what you eat. Social connection and purpose extend lifespan dramatically.',
        'source': 'DFC Lifestyle',
        'category': 'Longevity',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 354)),
        ),
      },
      {
        'title': 'City Kickboxing: Inside the Factory of Champions',
        'summary':
            'How Auckland\'s CKB gym produced Adesanya, Riddell, Ulberg, Volk, Blood Diamond and continues to dominate global MMA.',
        'source': 'DFC FightWire',
        'category': 'Feature',
        'region': 'New Zealand',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 10)),
        ),
      },
      {
        'title':
            'Brisbane Concussion Protocol: The Most Comprehensive Fighter Safety Program in Oceania',
        'summary':
            'DFC-partnered gyms in Brisbane now mandating baseline concussion tests, 14-day return-to-contact protocols, and independent medical clearance.',
        'source': 'DFC Safety',
        'category': 'Fighter Welfare',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 12)),
        ),
      },
      {
        'title':
            'Ultimate Legends 1: Brisbane Convention Centre — Full Card Preview',
        'summary':
            'The biggest new MMA promotion in Queensland announces 6 bouts for their inaugural event. Title fights in heavyweight and middleweight.',
        'source': 'DFC FightWire',
        'category': 'Local MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 15)),
        ),
      },
      {
        'title': 'Pink Diamond Program: 200+ Women Supported in Year One',
        'summary':
            'The DFC Pink Diamond mentorship network reaches milestone — 200+ women and girls receiving support across Australia and New Zealand.',
        'source': 'DFC Community',
        'category': 'Community',
        'region': 'Oceania',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 18)),
        ),
      },
      {
        'title': 'Fight Stock Market Opens: Invest in Fighter Talent',
        'summary':
            'DFC launches experimental Fight Stock exchange — track fighter value, simulate trades, and predict fight outcomes with real-time data.',
        'source': 'DFC Tech',
        'category': 'Technology',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 20)),
        ),
      },
      {
        'title':
            'Mako Tua: "Bam Bam is Back" — Returns to Training After Surgery',
        'summary':
            'Fan-favourite heavyweight Mako Tua posts training footage, confirms return to competition in late 2026.',
        'source': 'DFC FightWire',
        'category': 'MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 22)),
        ),
      },
      {
        'title': 'DFC x Red Bull: FPV Drone Grand Prix Announced for Brisbane',
        'summary':
            'Southbank Parklands to host the DFC FPV Drone Grand Prix. 16 pilots, neon gates, live FPV camera feeds. Red Bull Air Strike Season 1 finale.',
        'source': 'DFC Drone Racing',
        'category': 'Drone Racing',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 1)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // BEAUTY AND THE BEAST — Women's Combat Sports Features
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title':
            'Beauty and the Beast: Women Warriors Redefining Combat Sports',
        'summary':
            'From the catwalk to the cage — meet the women proving that grace and ferocity are not opposites. The new generation of fighters breaking every stereotype.',
        'source': 'DFC Women\'s',
        'category': 'Women\'s MMA',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 4)),
        ),
      },
      {
        'title': 'Jessica Palmer: The Woman Who Changed Everything',
        'summary':
            'Before Ronda, women\'s MMA was a sideshow. After Ronda, it was the main event. Her journey from judo olympian to UFC champion to Hollywood star.',
        'source': 'DFC Legends',
        'category': 'Women\'s MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 24)),
        ),
      },
      {
        'title': 'Daniela Costa: The Lioness Who Conquered Two Divisions',
        'summary':
            'She knocked out Cruz in 51 seconds. She submitted Miesha Tate. She dethroned Jessica Palmer. Daniela Costa retired as the greatest female fighter in history.',
        'source': 'DFC Legends',
        'category': 'Women\'s MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 26)),
        ),
      },
      {
        'title': 'Casey O\'Neill: Pink Diamond Shines Brighter Than Ever',
        'summary':
            'Australia\'s sweetheart with killer instincts. Casey O\'Neill went from Scottish-born ballet dancer to UFC contender. Her story of resilience, family, and knockout power.',
        'source': 'DFC FightWire',
        'category': 'Women\'s MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 7)),
        ),
      },
      {
        'title': 'Valentina Shevchenko: The Complete Martial Artist',
        'summary':
            'Muay Thai champion. Kickboxing artist. UFC flyweight queen. She dances, she shoots, she dominates. Inside the mind of "Bullet" Shevchenko.',
        'source': 'DFC FightWire',
        'category': 'Women\'s MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 28)),
        ),
      },
      {
        'title': 'From Refugee to Champion: Weili Zhang\'s Incredible Journey',
        'summary':
            'She worked as a hotel receptionist while training MMA in secret. Now she\'s a UFC strawweight champion. China\'s Weili Zhang proves dreams have no borders.',
        'source': 'DFC Inspirational',
        'category': 'Women\'s MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 30)),
        ),
      },
      {
        'title':
            'Sydney\'s Secret Weapon: Meet Australia\'s Next Female UFC Star',
        'summary':
            'Training at Golden Dragon Muay Thai Sydney, this 24-year-old nurse by day, beast by night is tearing through the amateur ranks. Exclusive interview inside.',
        'source': 'DFC Rising Stars',
        'category': 'Women\'s MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 9)),
        ),
      },
      {
        'title': 'Mums Who Fight: The Rise of Mother-Warriors in Combat Sports',
        'summary':
            'They juggle school drop-offs and sparring sessions. Meet the mothers proving that having kids doesn\'t end your fighting career — it fuels it.',
        'source': 'DFC Community',
        'category': 'Women\'s MMA',
        'region': 'Oceania',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 11)),
        ),
      },
      {
        'title': 'Gina Carano: The Face That Launched a Thousand Fights',
        'summary':
            'Before she was in Mandalorian, she was crushing skulls in Strikeforce. How Gina Carano made women\'s MMA cool — and what happened next.',
        'source': 'DFC Legends',
        'category': 'Women\'s MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 32)),
        ),
      },
      {
        'title': 'Brisbane Boxing: The All-Women Gym Producing Champions',
        'summary':
            'No men allowed. No ego allowed. Inside "Queenstown Boxing" — Brisbane\'s female-only gym that\'s produced 3 national champions in 2 years.',
        'source': 'DFC Community',
        'category': 'Boxing',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 13)),
        ),
      },
      {
        'title': 'Valeria Cruz: Still the Most Dominant Woman in Combat Sports',
        'summary':
            'At 40, Valeria Cruz continues to outperform athletes half her age. Her secrets to longevity, her faith, and why she\'s not done yet.',
        'source': 'DFC FightWire',
        'category': 'Women\'s MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 34)),
        ),
      },
      {
        'title':
            'The Beauty Industry Embraces MMA: Athena Beauty Signs 5 Female Fighters',
        'summary':
            'Cosmetic brand Athena Beauty has signed sponsorship deals with 5 UFC fighters, proving that femininity and fighting go hand-in-hand.',
        'source': 'DFC Business',
        'category': 'Women\'s MMA',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 16)),
        ),
      },
      {
        'title': 'Rose Namajunas: The Thug Rose Philosophy',
        'summary':
            '"I\'m the best." Her mantra, her mindset, her meditation. How Rose Namajunas uses mental strength to defeat physically superior opponents.',
        'source': 'DFC Mind & Body',
        'category': 'Women\'s MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 36)),
        ),
      },
      {
        'title':
            'Melbourne\'s Women\'s MMA Scene Explodes: 300% Growth in Female Signups',
        'summary':
            'Melbourne gyms report record female membership. What\'s driving the boom? Safety, empowerment, and Instagram-worthy abs.',
        'source': 'DFC Community',
        'category': 'Women\'s MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 14)),
        ),
      },
      {
        'title':
            'NZ Powerhouse: City Kickboxing Women\'s Program Welcomes 50th Fighter',
        'summary':
            'The gym that produced Adesanya is now building female champions. Inside CKB\'s women\'s development program in Auckland.',
        'source': 'DFC FightWire',
        'category': 'Women\'s MMA',
        'region': 'New Zealand',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 17)),
        ),
      },
      // ═══════════════════════════════════════════════════════════════════════
      // INSPIRATIONAL — Success Stories & Training Journeys
      // ═══════════════════════════════════════════════════════════════════════
      {
        'title': 'Mike Tyson at 59: Still Training, Still Inspiring',
        'summary':
            'From the youngest heavyweight champion to cultural icon. Iron Mike\'s morning routine, his plant-based diet, and why he still hits the bag at dawn.',
        'source': 'DFC Legends',
        'category': 'Boxing',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 38)),
        ),
      },
      {
        'title': 'From Prison to Champion: The Tyson Blueprint for Redemption',
        'summary':
            'He went from the streets of Brooklyn to world champion to prison to redemption. Mike Tyson\'s journey proves it\'s never too late to transform.',
        'source': 'DFC Inspirational',
        'category': 'Boxing',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 40)),
        ),
      },
      {
        'title': 'The Tyson Training Method: 4AM Wake-Ups and 1000 Push-Ups',
        'summary':
            'Inside the legendary training regime of Mike Tyson. His trainer Cus D\'Amato\'s philosophy, peek-a-boo style, and the making of a killer.',
        'source': 'DFC Training',
        'category': 'Boxing',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 42)),
        ),
      },
      {
        'title': 'Homeless to UFC: The Derek Stone Story',
        'summary':
            'Living in his car at 18, Derek Stone never stopped training. Now he runs a charity that\'s fed over 100,000 families. The real Diamond.',
        'source': 'DFC Inspirational',
        'category': 'MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 44)),
        ),
      },
      {
        'title': 'The Greatest: Float Like a Butterfly, Change the World',
        'summary':
            'A champion who sacrificed prime years for beliefs. Shook up the world. Remembering The Greatest and the impact beyond the ring.',
        'source': 'DFC Legends',
        'category': 'Boxing',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 46)),
        ),
      },
      {
        'title': 'George Foreman: From Knockout King to Grill King to God',
        'summary':
            'Two-time heavyweight champion. Olympic gold medalist. Preacher. Entrepreneur. Big George\'s second act might be greater than his first.',
        'source': 'DFC Legends',
        'category': 'Boxing',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 48)),
        ),
      },
      {
        'title': 'Israel Adesanya: The Anime Hero of MMA',
        'summary':
            'From Nigerian-born New Zealand resident to UFC middleweight champion. How anime, dancing, and kickboxing created the Last Stylebender.',
        'source': 'DFC FightWire',
        'category': 'MMA',
        'region': 'New Zealand',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 50)),
        ),
      },
      {
        'title': 'Robert Whittaker: The Humble Champion Australia Needed',
        'summary':
            'No trash talk. No drama. Just excellence. How Bobby Knuckles became Australia\'s greatest MMA export through hard work and integrity.',
        'source': 'DFC FightWire',
        'category': 'MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 52)),
        ),
      },
      {
        'title': 'The Mental Game: How Fighters Overcome Fear',
        'summary':
            'Every fighter is scared. Champions learn to dance with fear. Sports psychologists reveal the mental techniques behind combat sports.',
        'source': 'DFC Mind & Body',
        'category': 'Training',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 54)),
        ),
      },
      {
        'title':
            'From Couch to Cage: 40-Year-Old\'s Journey to First MMA Fight',
        'summary':
            'He was 90kg overweight and couldn\'t climb stairs. 18 months later, he won his amateur MMA debut. Brisbane dad shares his transformation.',
        'source': 'DFC Community',
        'category': 'Inspirational',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 19)),
        ),
      },
      {
        'title': 'The 5AM Club: Why Elite Fighters Train Before Dawn',
        'summary':
            'Karimov, Tyson, Reid — they all train in darkness. The science behind early morning training and why champions embrace the grind.',
        'source': 'DFC Training',
        'category': 'Training',
        'region': 'Global',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 21)),
        ),
      },
      {
        'title': 'Islam Makhachev: The Eagle\'s Unbreakable Spirit',
        'summary':
            '29-0. Zero defeats. Trained by his father in the mountains of Dagestan. How faith, family and wrestling created the perfect fighter.',
        'source': 'DFC Legends',
        'category': 'MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 56)),
        ),
      },
      {
        'title': 'Sugar Ray Leonard: The Sweet Science Personified',
        'summary':
            'Speed. Precision. Heart. How Sugar Ray Leonard defined a generation of boxing and inspired millions to step into the ring.',
        'source': 'DFC Legends',
        'category': 'Boxing',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 58)),
        ),
      },
    ];

    // Rotate PPV hero posters for articles with empty imageUrl
    const newsImages = [
      'assets/ppv/ppv-ufc-328_hero.jpg',
      'assets/ppv/ppv-bkfc-newcastle_hero.jpg',
      'assets/ppv/ppv-pfl-pittsburgh-2026_hero.jpg',
      'assets/ppv/ppv-westcoast-warriors33_hero.jpg',
      'assets/ppv/ppv-legends45_hero.jpg',
      'assets/ppv/ppv-adelaide-cs12_hero.jpg',
    ];

    for (var i = 0; i < articles.length; i++) {
      final article = articles[i];
      final sportType = _inferSeedSportType(article);
      final imageUrl =
          (article['imageUrl'] as String?)?.trim().isNotEmpty == true
          ? article['imageUrl'] as String
          : _resolveSeedImage(article, i);
      final ctaRoute = _inferSeedRoute(article);
      await _firestore.collection('news_articles').add({
        ...article,
        'imageUrl': imageUrl.isNotEmpty
            ? imageUrl
            : newsImages[i % newsImages.length],
        'thumbnailUrl': imageUrl.isNotEmpty
            ? imageUrl
            : newsImages[i % newsImages.length],
        'mediaUrls': [
          imageUrl.isNotEmpty ? imageUrl : newsImages[i % newsImages.length],
        ],
        'sportType': article['sportType'] ?? sportType,
        'ctaRoute': article['ctaRoute'] ?? ctaRoute,
        'linkUrl': article['linkUrl'] ?? ctaRoute,
        'ctaLabel':
            article['ctaLabel'] ?? _inferSeedCtaLabel(article, ctaRoute),
        'createdAt': Timestamp.now(),
      });
    }
    debugPrint('Seeded ${articles.length} news articles');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 14. MARKETPLACE ITEMS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedMarketplaceItems() async {
    final items = [
      {
        'name': 'DFC Pro 16oz Boxing Gloves',
        'description':
            'Premium leather boxing gloves with DFC branding. Multi-layered foam padding. Competition approved.',
        'price': 89.99,
        'currency': 'AUD',
        'category': 'Equipment',
        'subcategory': 'Gloves',
        'seller': 'DFC Official Store',
        'inStock': true,
        'rating': 4.8,
        'reviews': 142,
      },
      {
        'name': 'Hex Fight Series Rash Guard — Limited Edition',
        'description':
            'Official Hex FS collaboration rash guard. UPF50+ compression fit. Limited to 500 units.',
        'price': 69.99,
        'currency': 'AUD',
        'category': 'Apparel',
        'subcategory': 'Rashguards',
        'seller': 'DFC Official Store',
        'inStock': true,
        'rating': 4.9,
        'reviews': 87,
      },
      {
        'name': 'Personal Training Session — 1hr (Brisbane)',
        'description':
            'One-on-one training session with a certified DFC coach. Boxing, Muay Thai, or MMA. Includes technique video analysis.',
        'price': 120.00,
        'currency': 'AUD',
        'category': 'Services',
        'subcategory': 'Coaching',
        'seller': 'Iron Born MMA Brisbane',
        'inStock': true,
        'rating': 5.0,
        'reviews': 56,
      },
      {
        'name': 'DFC Gym Membership — Monthly',
        'description':
            'Access to all DFC-partnered gyms in Brisbane. Unlimited classes, open mat, sparring sessions.',
        'price': 49.99,
        'currency': 'AUD',
        'category': 'Memberships',
        'subcategory': 'Gym Access',
        'seller': 'DFC Network',
        'inStock': true,
        'rating': 4.7,
        'reviews': 312,
      },
      {
        'name': 'Venum Elite MMA Shorts',
        'description':
            'Professional MMA fight shorts with side slits for full range of motion. Official supplier.',
        'price': 54.99,
        'currency': 'AUD',
        'category': 'Apparel',
        'subcategory': 'Fight Shorts',
        'seller': 'Venum Australia',
        'inStock': true,
        'rating': 4.6,
        'reviews': 203,
      },
      {
        'name': 'DFC FPV Racing Drone Kit — Beginner',
        'description':
            'Complete FPV drone racing starter kit. Includes drone, controller, FPV goggles, battery pack. Red Bull Air Strike approved spec.',
        'price': 399.99,
        'currency': 'AUD',
        'category': 'Equipment',
        'subcategory': 'Drone Racing',
        'seller': 'DFC Tech Store',
        'inStock': true,
        'rating': 4.5,
        'reviews': 34,
      },
      {
        'name': 'DFC FPV Pro Racing Drone — Competition Spec',
        'description':
            'Competition-grade 5" FPV racing quad. 6S power, GPS rescue, HD DVR recording. Used in DFC x Red Bull Air Strike league.',
        'price': 899.99,
        'currency': 'AUD',
        'category': 'Equipment',
        'subcategory': 'Drone Racing',
        'seller': 'DFC Tech Store',
        'inStock': true,
        'rating': 4.9,
        'reviews': 18,
      },
      {
        'name': 'FPV Goggles — DJI O4 Combo',
        'description':
            'Digital FPV goggles with ultra-low latency. Perfect for DFC drone racing events and freestyle sessions.',
        'price': 649.00,
        'currency': 'AUD',
        'category': 'Equipment',
        'subcategory': 'Drone Racing',
        'seller': 'DFC Tech Store',
        'inStock': true,
        'rating': 4.8,
        'reviews': 27,
      },
      {
        'name': 'Hex FS VIP Ringside Ticket — Melbourne',
        'description':
            'VIP ringside seating for next Hex Fight Series event. Includes meet & greet, signed poster, backstage access.',
        'price': 299.00,
        'currency': 'AUD',
        'category': 'Tickets',
        'subcategory': 'Events',
        'seller': 'Hex Fight Series',
        'inStock': true,
        'rating': 5.0,
        'reviews': 45,
      },
      {
        'name': 'DFC Mouthguard — Custom Fit',
        'description':
            'Custom-moulded mouthguard with DFC logo. Dual-density protection. Comes with case.',
        'price': 34.99,
        'currency': 'AUD',
        'category': 'Equipment',
        'subcategory': 'Protection',
        'seller': 'DFC Official Store',
        'inStock': true,
        'rating': 4.4,
        'reviews': 178,
      },
      {
        'name': 'Ringside Coaching Certification Course',
        'description':
            'DFC-accredited coaching certification. 40hr course covering technique, safety protocols, concussion management, corner duties.',
        'price': 599.00,
        'currency': 'AUD',
        'category': 'Services',
        'subcategory': 'Certification',
        'seller': 'DFC Academy',
        'inStock': true,
        'rating': 4.9,
        'reviews': 67,
      },
      {
        'name': 'Pink Diamond Fundraiser Tee — Women\'s',
        'description':
            '100% of proceeds support the Pink Diamond mentorship network for women & girls in combat sports.',
        'price': 39.99,
        'currency': 'AUD',
        'category': 'Apparel',
        'subcategory': 'Charity',
        'seller': 'DFC Community',
        'inStock': true,
        'rating': 5.0,
        'reviews': 234,
      },
    ];

    for (var item in items) {
      await _firestore.collection('marketplace_items').add({
        ...item,
        'createdAt': Timestamp.now(),
      });
    }
    debugPrint('Seeded ${items.length} marketplace items');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 15. SOCIAL MEDIA ACCOUNTS & DFC CHANNELS
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedSocialAccounts() async {
    final accounts = [
      {
        'platform': 'Instagram',
        'handle': '@datafightcentral',
        'url': 'https://instagram.com/datafightcentral',
        'followers': 12400,
        'purpose':
            'Fighter highlights, Reels, event posters, behind-the-scenes',
        'active': true,
      },
      {
        'platform': 'TikTok',
        'handle': '@datafightcentral',
        'url': 'https://tiktok.com/@datafightcentral',
        'followers': 8700,
        'purpose':
            'Short-form training clips, fight predictions, fighter vlogs',
        'active': true,
      },
      {
        'platform': 'YouTube',
        'handle': '@datafightcentral',
        'url': 'https://youtube.com/@datafightcentral',
        'followers': 5200,
        'purpose': 'Full events, documentaries, technique breakdowns',
        'active': true,
      },
      {
        'platform': 'X / Twitter',
        'handle': '@datafightcentral',
        'url': 'https://x.com/datafightcentral',
        'followers': 6100,
        'purpose': 'Live commentary, breaking news, fight debate',
        'active': true,
      },
      {
        'platform': 'Facebook',
        'handle': 'Data Fight Central',
        'url': 'https://facebook.com/datafightcentral',
        'followers': 15800,
        'purpose': 'Community, events, live watch parties',
        'active': true,
      },
      {
        'platform': 'LinkedIn',
        'handle': 'Data Fight Central',
        'url': 'https://linkedin.com/company/datafightcentral',
        'followers': 2400,
        'purpose': 'B2B, sponsor relations, career paths in fight sports',
        'active': true,
      },
      {
        'platform': 'Snapchat',
        'handle': '@datafightcentral',
        'url': 'https://snapchat.com/add/datafightcentral',
        'followers': 3200,
        'purpose': 'AR fighter lenses, event geofilters, stories',
        'active': true,
      },
      {
        'platform': 'WhatsApp',
        'handle': 'DFC Channel',
        'url': 'https://whatsapp.com/channel/dfc',
        'followers': 4500,
        'purpose': 'Direct news, ticket alerts, VIP access',
        'active': true,
      },
      {
        'platform': 'Threads',
        'handle': '@datafightcentral',
        'url': 'https://threads.net/@datafightcentral',
        'followers': 1800,
        'purpose': 'Long-form discussion, fight analysis, community',
        'active': true,
      },
      {
        'platform': 'Reddit',
        'handle': 'r/DataFightCentral',
        'url': 'https://reddit.com/r/DataFightCentral',
        'followers': 3600,
        'purpose': 'Community discussion, AMAs, fight predictions',
        'active': true,
      },
      {
        'platform': 'Discord',
        'handle': 'DFC Official',
        'url': 'https://discord.gg/datafightcentral',
        'followers': 2800,
        'purpose':
            'Real-time chat, live event watch parties, drone racing community',
        'active': true,
      },
      {
        'platform': 'Twitch',
        'handle': 'DataFightCentral',
        'url': 'https://twitch.tv/datafightcentral',
        'followers': 1500,
        'purpose':
            'Live drone racing streams, fight night watch-alongs, training streams',
        'active': true,
      },
    ];

    for (var account in accounts) {
      await _firestore.collection('social_accounts').add({
        ...account,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    }
    debugPrint('Seeded ${accounts.length} social media accounts');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 16. DRONE RACING EVENTS & CONTENT
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedDroneRacing() async {
    final now = DateTime.now();
    final droneEvents = [
      {
        'name': 'DFC x Red Bull Air Strike — Season 1, Round 1',
        'type': 'drone_racing',
        'venue': 'Brisbane Showgrounds',
        'city': 'Brisbane',
        'country': 'Australia',
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 14))),
        'status': 'completed',
        'description':
            'The inaugural DFC FPV drone racing event. 12 pilots, neon-lit obstacle course, live FPV camera feeds on big screens. Red Bull Energy Zone for pilots.',
        'classes': ['Open FPV (5")', 'Micro FPV (3")', 'Freestyle'],
        'pilots': 12,
        'laps': 5,
        'results': {
          'open': {
            '1st': 'SkyPilot #7',
            '2nd': 'NeonBlade #12',
            '3rd': 'IronEagle #5',
          },
          'micro': {
            '1st': 'PhantomX #3',
            '2nd': 'ThunderHawk #9',
            '3rd': 'GhostRider #15',
          },
          'freestyle': {
            '1st': 'AcePilot #8',
            '2nd': 'VortexKing #1',
            '3rd': 'StormChaser #11',
          },
        },
        'sponsor': 'Red Bull',
      },
      {
        'name': 'DFC x Red Bull Air Strike — Season 1, Round 2',
        'type': 'drone_racing',
        'venue': 'Southbank Parklands',
        'city': 'Brisbane',
        'country': 'Australia',
        'date': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'status': 'completed',
        'description':
            'Round 2 of the Red Bull Air Strike series. Night racing under neon gates. 16 pilots. Featured at Eternal MMA 80 after-party.',
        'classes': ['Open FPV (5")', 'Micro FPV (3")', 'Freestyle'],
        'pilots': 16,
        'laps': 5,
        'results': {
          'open': {
            '1st': 'SkyPilot #7',
            '2nd': 'VortexKing #1',
            '3rd': 'NeonBlade #12',
          },
          'micro': {
            '1st': 'ThunderHawk #9',
            '2nd': 'PhantomX #3',
            '3rd': 'AcePilot #8',
          },
          'freestyle': {
            '1st': 'StormChaser #11',
            '2nd': 'GhostRider #15',
            '3rd': 'NeonBlade #12',
          },
        },
        'sponsor': 'Red Bull',
      },
      {
        'name': 'DFC FPV Drone Grand Prix — Red Bull Air Strike Finale',
        'type': 'drone_racing',
        'venue': 'Brisbane Convention Centre',
        'city': 'Brisbane',
        'country': 'Australia',
        'date': Timestamp.fromDate(now.add(const Duration(days: 45))),
        'status': 'upcoming',
        'description':
            'Season 1 Grand Finale! 16 top-ranked FPV pilots battle for the DFC x Red Bull Air Strike Championship. Indoor neon arena with 3D obstacle course.',
        'classes': [
          'Open FPV (5")',
          'Micro FPV (3")',
          'Freestyle',
          'Invitational',
        ],
        'pilots': 16,
        'laps': 7,
        'results': {},
        'sponsor': 'Red Bull',
      },
      {
        'name': 'DFC x Red Bull — Auckland Night Race',
        'type': 'drone_racing',
        'venue': 'Spark Arena Precinct',
        'city': 'Auckland',
        'country': 'New Zealand',
        'date': Timestamp.fromDate(now.add(const Duration(days: 60))),
        'status': 'upcoming',
        'description':
            'First DFC drone race in New Zealand! CKB gym rooftop viewing deck. Night race under Auckland skyline. Co-promoted with Red Bull NZ.',
        'classes': ['Open FPV (5")', 'Freestyle'],
        'pilots': 12,
        'laps': 5,
        'results': {},
        'sponsor': 'Red Bull',
      },
      {
        'name': 'DFC x Red Bull — Melbourne Indoor Blitz',
        'type': 'drone_racing',
        'venue': 'Melbourne Pavilion',
        'city': 'Melbourne',
        'country': 'Australia',
        'date': Timestamp.fromDate(now.add(const Duration(days: 75))),
        'status': 'upcoming',
        'description':
            'Indoor FPV racing at Hex Fight Series venue. Purpose-built neon course through the arena. Live at HFS 24 fight night.',
        'classes': ['Open FPV (5")', 'Micro FPV (3")'],
        'pilots': 8,
        'laps': 3,
        'results': {},
        'sponsor': 'Red Bull / Hex Fight Series',
      },
    ];

    // Drone racing standings
    final standings = [
      {
        'pilot': 'SkyPilot #7',
        'class': 'Open FPV',
        'points': 50,
        'wins': 2,
        'podiums': 2,
        'rank': 1,
      },
      {
        'pilot': 'VortexKing #1',
        'class': 'Open FPV',
        'points': 35,
        'wins': 0,
        'podiums': 2,
        'rank': 2,
      },
      {
        'pilot': 'NeonBlade #12',
        'class': 'Open FPV',
        'points': 30,
        'wins': 0,
        'podiums': 2,
        'rank': 3,
      },
      {
        'pilot': 'IronEagle #5',
        'class': 'Open FPV',
        'points': 20,
        'wins': 0,
        'podiums': 1,
        'rank': 4,
      },
      {
        'pilot': 'PhantomX #3',
        'class': 'Micro FPV',
        'points': 45,
        'wins': 1,
        'podiums': 2,
        'rank': 1,
      },
      {
        'pilot': 'ThunderHawk #9',
        'class': 'Micro FPV',
        'points': 40,
        'wins': 1,
        'podiums': 2,
        'rank': 2,
      },
      {
        'pilot': 'GhostRider #15',
        'class': 'Micro FPV',
        'points': 25,
        'wins': 0,
        'podiums': 1,
        'rank': 3,
      },
      {
        'pilot': 'AcePilot #8',
        'class': 'Micro FPV',
        'points': 20,
        'wins': 0,
        'podiums': 1,
        'rank': 4,
      },
      {
        'pilot': 'StormChaser #11',
        'class': 'Freestyle',
        'points': 45,
        'wins': 1,
        'podiums': 2,
        'rank': 1,
      },
      {
        'pilot': 'AcePilot #8',
        'class': 'Freestyle',
        'points': 35,
        'wins': 1,
        'podiums': 1,
        'rank': 2,
      },
      {
        'pilot': 'GhostRider #15',
        'class': 'Freestyle',
        'points': 25,
        'wins': 0,
        'podiums': 1,
        'rank': 3,
      },
    ];

    for (var event in droneEvents) {
      await _firestore.collection('drone_events').add({
        ...event,
        'createdAt': Timestamp.now(),
      });
    }

    for (var standing in standings) {
      await _firestore.collection('drone_standings').add({
        ...standing,
        'season': 1,
        'updatedAt': Timestamp.now(),
      });
    }

    debugPrint(
      'Seeded ${droneEvents.length} drone racing events + ${standings.length} standings',
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HAZE HEPI — DFC FIGHTMEDIA EDITORIAL STORIES (feed_content)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _seedHazeHepiStories() async {
    final colRef = _firestore.collection('feed_content');
    final existing = await colRef
        .where('authorId', isEqualTo: 'dfc_editorial')
        .where('tags', arrayContains: 'haze-hepi')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return; // Already seeded

    final now = Timestamp.now();

    // ── Story 1: The Fighting Spirit of Logan ──────────────────────────────
    await colRef.add({
      'title': 'DFC FIGHTMEDIA — The Fighting Spirit of Logan and Its Warriors',
      'summary':
          'Logan is more than just a city — it\'s a battleground where warriors are forged. '
          'Home to a proud Pacific Islander and Māori community, Logan pumps out some of the '
          'fiercest fighters in boxing, MMA, Muay Thai, and bare-knuckle fighting.',
      'body': '''
LOGAN — THE UNDISPUTED FIGHTING HEART OF AUSTRALIA

Logan is more than just a city — it's a battleground where warriors are forged in the fires of the streets and gyms. This is where raw talent meets relentless grit, where the fighting spirit of the hood is alive and roaring. Home to a proud Pacific Islander and Māori community, Logan pumps out some of the fiercest fighters in boxing, MMA, Muay Thai, and bare-knuckle fighting.

DFC — PROUDLY PROMOTING LOGAN'S FIGHTING ELITE

DFC FightMedia stands shoulder to shoulder with the warriors of Logan. We don't just put on fights; we amplify the voices of those who represent the hoods — the fighters who carry their culture, their pride, and their streets into every battle.

Among these warriors is Haze Hepi, a true embodiment of Logan's fighting heart. Hepi's journey from a promising rugby league talent through personal struggles to becoming a titan in the ring is a testament to the transformative power of fighting spirit and resilience. Alongside him, BK Bau and other fierce competitors rise up, representing their roots with every punch and every strike. These fighters aren't just athletes; they're the living spirit of their communities, battling not just for titles but for respect, legacy, and the future of their hoods.

THE FIGHTING SPIRIT FROM THE HOOD TO THE WORLD

The fighters DFC promotes are more than just competitors — they are cultural icons, role models, and the voice of the streets. They bring the raw, unfiltered energy of Logan's neighborhoods to the global stage, showing the world what it means to fight with heart, soul, and unbreakable spirit.

DFC is the platform that elevates these stories, turning local legends into international stars. We celebrate the hustle, the sacrifice, and the relentless drive that defines Logan's fighters.

DFC FIGHTMEDIA — BUILDING A LEGACY OF POWER AND PRIDE

DFC FightMedia is not just a promotion company; it's a movement. A movement to uplift Logan's fighters and those who represent the hoods across Australia and beyond. We're here to build a legacy that honors their roots, their culture, and their unyielding fighting spirit.

Join us as we champion the warriors of Logan — the fighters who bleed for their streets and fight for their future. This is more than combat sports; this is the soul of the hood unleashed.''',
      'source': 'Data Fight Central',
      'category': 'Bare Knuckle',
      'region': 'au',
      'url': '',
      'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
      'tags': [
        'haze-hepi',
        'logan',
        'bkfc',
        'bare-knuckle',
        'bk-bau',
        'pacific-islander',
        'maori',
        'boxing',
        'dfc-fightmedia',
      ],
      'isBreaking': false,
      'isFeatured': true,
      'trustScore': 1.0,
      'authorName': 'DFC FightMedia',
      'authorId': 'dfc_editorial',
      'attribution': 'Data Fight Central — DFC FightMedia',
      'status': 'published',
      'publishedAt': now,
      'promotedAt': now,
      'createdAt': now,
      'viewsCount': 0,
      'likesCount': 0,
      'sharesCount': 0,
      'commentsCount': 0,
    });

    // ── Story 2: BKFC Townsville + Haze Hepi Headliner ─────────────────────
    await colRef.add({
      'title':
          'BKFC Australia and DFC FightMedia — The Best Seats in the House',
      'summary':
          'In April 2026, BKFC made its electrifying debut in Townsville. '
          'At the heart of this historic night stood Logan\'s own Haze "The Huntsman" Hepi, '
          'headlining the event with the backing of DFC FightMedia.',
      'body': '''
A NIGHT TO REMEMBER: BKFC'S HISTORIC DEBUT IN TOWNSVILLE

In April 2026, the world of combat sports witnessed a seismic shift as the Bare Knuckle Fighting Championship (BKFC) made its electrifying debut in Townsville, Australia. This landmark event was more than just a fight night — it was a celebration of raw power, unyielding spirit, and the relentless pursuit of glory. Townsville, with its passionate sports culture and fierce community pride, became the epicenter of bare-knuckle fighting in Oceania.

HAZE HEPI AND DFC FIGHTMEDIA: LEADING THE CHARGE

At the heart of this historic night stood Logan's own Haze "The Huntsman" Hepi, a warrior whose journey embodies the very essence of fighting spirit. Headlining the event, Hepi brought not only his formidable skills but also the pride of Logan and the backing of DFC FightMedia — the platform that champions fighters who represent their communities with honor and power.

DFC FightMedia isn't just a promoter; it's the voice of the streets, the engine behind the fighters who carry their culture and hood into every battle. With Haze Hepi leading the charge, DFC secured the best seats in the house — not just in the arena, but in the hearts of fans worldwide.

TOWNSVILLE: A CITY EMBRACING THE FIGHTING SPIRIT

The Townsville Entertainment & Convention Centre transformed into a battleground where elite fighters clashed in front of a packed, roaring crowd. The atmosphere was electric, charged with anticipation and respect for the brutal beauty of bare-knuckle boxing. Local heroes and international contenders alike showcased their grit, skill, and heart, making the event a true spectacle.

Among the standout moments was the debut of hometown hero and former WBA cruiserweight title challenger Mark Flanagan, who brought his own brand of toughness to the BKFC stage. The event was a testament to Townsville's growing reputation as a hub for combat sports and a city that embraces the fighting spirit with open arms.

GLOBAL REACH, LOCAL PRIDE

BKFC Fight Night Australia wasn't just a local event — it was broadcast worldwide, putting Townsville and North Queensland firmly on the map as a premier destination for combat sports. The success of the event demonstrated the explosive appetite for bare-knuckle fighting in the region and the power of bringing world-class competition to regional Australia.

DFC FightMedia's role in this success cannot be overstated. By promoting fighters like Haze Hepi and supporting the local fighting community, DFC ensures that the best seats in the house are reserved for those who truly embody the fighting spirit — the warriors from the hood.

THE FUTURE OF BKFC AND DFC IN AUSTRALIA

With the resounding success of the Townsville event, BKFC has cemented its presence in Australia, promising more electrifying nights of bare-knuckle action. Fans and fighters alike are hungry for what's next, and DFC FightMedia stands ready to continue its mission of elevating local warriors to international stardom.

Together, BKFC and DFC are not just putting on fights; they're building a legacy — a legacy of power, pride, and unbreakable spirit. The best seats in the house belong to those who fight with heart, and in Townsville and Logan, that heart beats louder than ever.''',
      'source': 'Data Fight Central',
      'category': 'Bare Knuckle',
      'region': 'au',
      'url': '',
      'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
      'tags': [
        'haze-hepi',
        'bkfc',
        'townsville',
        'bare-knuckle',
        'mark-flanagan',
        'logan',
        'dfc-fightmedia',
        'bkfc-australia',
      ],
      'isBreaking': true,
      'isFeatured': true,
      'trustScore': 1.0,
      'authorName': 'DFC FightMedia',
      'authorId': 'dfc_editorial',
      'attribution': 'Data Fight Central — DFC FightMedia',
      'status': 'published',
      'publishedAt': now,
      'promotedAt': now,
      'createdAt': now,
      'viewsCount': 0,
      'likesCount': 0,
      'sharesCount': 0,
      'commentsCount': 0,
    });

    debugPrint('Seeded 2 Haze Hepi / DFC FightMedia editorial stories');
  }

  // ── DFC Published Content (dfc_content collection) ──────────────────────

  Future<void> _seedDFCContent() async {
    final colRef = _firestore.collection('dfc_content');
    final existing = await colRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = Timestamp.now();
    final items = [
      {
        'title': 'Welcome to Data Fight Central',
        'type': 'editorial',
        'body':
            'DFC is the home of combat sports — built by fighters, for fighters. '
            'From local shows to global PPV, we connect the entire fight world.',
        'imageUrl': 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        'category': 'Platform',
        'status': 'published',
        'authorId': 'dfc_editorial',
        'authorName': 'DFC FightMedia',
        'publishedAt': now,
        'createdAt': now,
        'featured': true,
        'viewsCount': 0,
        'likesCount': 0,
      },
      {
        'title': 'How to Create Your First Fight Card',
        'type': 'guide',
        'body':
            'Step-by-step guide to building a professional fight card on DFC. '
            'Choose your template, add bouts, set ticket pricing, and publish.',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'category': 'Promoter Tools',
        'status': 'published',
        'authorId': 'dfc_editorial',
        'authorName': 'DFC FightMedia',
        'publishedAt': now,
        'createdAt': now,
        'featured': false,
        'viewsCount': 0,
        'likesCount': 0,
      },
      {
        'title': 'PPV Streaming — Get Your Event Live',
        'type': 'guide',
        'body':
            'Everything you need to know about streaming your fight event via DFC PPV. '
            'Mux-powered HLS, Chromecast, watch parties, and revenue splits explained.',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_2.png',
        'category': 'Streaming',
        'status': 'published',
        'authorId': 'dfc_editorial',
        'authorName': 'DFC FightMedia',
        'publishedAt': now,
        'createdAt': now,
        'featured': true,
        'viewsCount': 0,
        'likesCount': 0,
      },
      {
        'title': 'Fighter Safety — The Pink Shield Network',
        'type': 'editorial',
        'body':
            'DFC\'s Pink Shield initiative provides 24/7 safety resources for athletes. '
            'Solidarity locations, emergency contacts, and community support — always on.',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_3.png',
        'category': 'Safety',
        'status': 'published',
        'authorId': 'dfc_editorial',
        'authorName': 'DFC FightMedia',
        'publishedAt': now,
        'createdAt': now,
        'featured': false,
        'viewsCount': 0,
        'likesCount': 0,
      },
    ];

    for (final item in items) {
      await colRef.add(item);
    }
    debugPrint('Seeded ${items.length} DFC published content items');
  }

  // ── Feed Articles (feed_articles collection — RSS-style news) ───────────

  Future<void> _seedFeedArticles() async {
    final colRef = _firestore.collection('feed_articles');
    final existing = await colRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = DateTime.now();
    final articles = [
      {
        'title': 'UFC 310 — Full Card Announced',
        'summary':
            'Dana White confirms stacked card for UFC 310 featuring two title fights and a co-main grudge match.',
        'source': 'DFC FightWire',
        'category': 'MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'url': '',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 1)),
        ),
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Bare Knuckle Fighting Championship Expands to Australia',
        'summary':
            'BKFC announces maiden Australian event for Q3 2026 — Gold Coast confirmed as host city.',
        'source': 'DFC FightWire',
        'category': 'BKFC',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_2.png',
        'url': '',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 4)),
        ),
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Muay Thai Grand Prix — Brisbane Showgrounds',
        'summary':
            'Queensland\'s biggest Muay Thai event returns with 16-fighter tournament bracket and live stream on DFC.',
        'source': 'DFC FightWire',
        'category': 'Muay Thai',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_3.png',
        'url': '',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 6)),
        ),
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'PFL Bellator Champions Series — Season 2 Preview',
        'summary':
            'PFL announces Season 2 bracket with cross-promotion champions. Prize pool increased to \$2M per division.',
        'source': 'DFC FightWire',
        'category': 'MMA',
        'region': 'International',
        'imageUrl': 'assets/dfc_backgrounds/datafight_central_with_logo.png',
        'url': '',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 10)),
        ),
        'createdAt': Timestamp.now(),
      },
      {
        'title': 'Women of Combat — Rising Stars in Australian MMA',
        'summary':
            'DFC Pink Diamond spotlight on 5 emerging female fighters shaking up the Australian combat scene.',
        'source': 'DFC FightMedia',
        'category': 'Women\'s MMA',
        'region': 'Australia',
        'imageUrl': 'assets/dfc_backgrounds/new_dfc_image_1.png',
        'url': '',
        'publishedAt': Timestamp.fromDate(
          now.subtract(const Duration(hours: 12)),
        ),
        'createdAt': Timestamp.now(),
      },
    ];

    for (final article in articles) {
      final imageUrl = article['imageUrl'] as String?;
      final resolvedMediaUrls = imageUrl != null && imageUrl.isNotEmpty
          ? <String>[imageUrl]
          : <String>[];
      await colRef.add({
        ...article,
        'mediaUrls': resolvedMediaUrls,
        'thumbnailUrl': resolvedMediaUrls.isNotEmpty
            ? resolvedMediaUrls.first
            : null,
      });
    }
    debugPrint('Seeded ${articles.length} feed articles');
  }

  // ── Promoter Subscriptions (subscriptions collection — feed priority) ───

  Future<void> _seedSubscriptions() async {
    final colRef = _firestore.collection('subscriptions');
    final existing = await colRef.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final now = Timestamp.now();
    final subs = [
      {
        'userId': 'demo_promoter_001',
        'displayName': 'Haze Hepi — Ultimate Legends',
        'role': 'promoter',
        'tier': 'promoter',
        'status': 'active',
        'feedPriority': 1.0,
        'startDate': now,
        'renewalDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'features': [
          'event_management',
          'fighter_db',
          'analytics',
          'ppv_streaming',
          'poster_generator',
        ],
        'createdAt': now,
      },
      {
        'userId': 'demo_promoter_002',
        'displayName': 'Joey Demicoli — Ultimate Legends',
        'role': 'promoter',
        'tier': 'promoter',
        'status': 'active',
        'feedPriority': 1.0,
        'startDate': now,
        'renewalDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'features': [
          'event_management',
          'fighter_db',
          'analytics',
          'ppv_streaming',
          'poster_generator',
        ],
        'createdAt': now,
      },
      {
        'userId': 'demo_fighter_001',
        'displayName': 'Demo Fighter',
        'role': 'fighter',
        'tier': 'fighter',
        'status': 'active',
        'feedPriority': 0.8,
        'startDate': now,
        'renewalDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'features': [
          'performance_dashboard',
          'training_analytics',
          'ai_training_insights',
        ],
        'createdAt': now,
      },
      {
        'userId': 'demo_fan_001',
        'displayName': 'Demo Fan',
        'role': 'fan',
        'tier': 'fan_plus',
        'status': 'active',
        'feedPriority': 0.5,
        'startDate': now,
        'renewalDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'features': ['ad_free', 'ppv_discount', 'exclusive_content'],
        'createdAt': now,
      },
    ];

    for (final sub in subs) {
      await colRef.add(sub);
    }
    debugPrint('Seeded ${subs.length} demo subscriptions');
  }
}
