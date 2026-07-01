import 'dart:async';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT MARKETPLACE SERVICE - DFC Commerce Engine
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Powers the marketplace where the fight community trades, hires, and grows:
/// - Equipment: Gloves, wraps, pads, bags, apparel, supplements
/// - Trainers: Advertising themselves, personal training services
/// - Gyms: Startup help, equipment sourcing, membership systems
/// - Services: Coaching, nutrition, physio, cornering, cut work
/// - Jobs: Trainer positions, gym staff, event crew, sparring partners
/// ═══════════════════════════════════════════════════════════════════════════

/// Marketplace listing category
enum MarketplaceCategory {
  equipment,
  personalTraining,
  gymServices,
  nutrition,
  coaching,
  events,
  apparel,
  supplements,
  recovery,
  jobs,
  sparringPartners,
  gymStartup,
}

/// Listing condition (for equipment)
enum ItemCondition { brandNew, likeNew, good, fair, wellUsed }

/// Service type for trainers
enum TrainerServiceType {
  oneOnOne,
  groupClass,
  onlineCoaching,
  seminar,
  fightCamp,
  womenOnly,
  kidsClass,
  beginnerFriendly,
  proLevel,
  traumaInformed,
  selfDefense,
  fitnessBoxing,
}

/// A marketplace listing
class MarketplaceListing {
  final String id;
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final String title;
  final String description;
  final MarketplaceCategory category;
  final double price;
  final String currency;
  final bool isNegotiable;
  final bool isFeatured;
  final bool isVerified;
  final List<String> images;
  final List<String> tags;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int views;
  final int saves;
  final int inquiries;
  final bool isActive;
  final Map<String, dynamic>? metadata; // Extra category-specific data

  const MarketplaceListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    this.sellerAvatar,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.currency = 'USD',
    this.isNegotiable = false,
    this.isFeatured = false,
    this.isVerified = false,
    this.images = const [],
    this.tags = const [],
    this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.expiresAt,
    this.views = 0,
    this.saves = 0,
    this.inquiries = 0,
    this.isActive = true,
    this.metadata,
  });
}

/// Trainer profile for marketplace
class TrainerProfile {
  final String userId;
  final String name;
  final String? avatar;
  final String bio;
  final List<String> specialties; // e.g., Boxing, Muay Thai
  final List<TrainerServiceType> services;
  final double hourlyRate;
  final String currency;
  final double rating; // 0-5
  final int reviewCount;
  final int clientsServed;
  final int yearsExperience;
  final List<String> certifications;
  final String? location;
  final bool isAvailable;
  final bool isVerified;
  final bool offersTrialSession;
  final String? trialDescription;
  final Map<String, List<String>>? schedule; // day -> time slots

  const TrainerProfile({
    required this.userId,
    required this.name,
    this.avatar,
    required this.bio,
    required this.specialties,
    required this.services,
    required this.hourlyRate,
    this.currency = 'USD',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.clientsServed = 0,
    this.yearsExperience = 0,
    this.certifications = const [],
    this.location,
    this.isAvailable = true,
    this.isVerified = false,
    this.offersTrialSession = false,
    this.trialDescription,
    this.schedule,
  });
}

/// Gym startup package
class GymStartupPackage {
  final String id;
  final String title;
  final String description;
  final List<String> includes;
  final double price;
  final String currency;
  final String? vendorId;
  final String vendorName;
  final double rating;
  final int reviewCount;

  const GymStartupPackage({
    required this.id,
    required this.title,
    required this.description,
    required this.includes,
    required this.price,
    this.currency = 'USD',
    this.vendorId,
    required this.vendorName,
    this.rating = 0.0,
    this.reviewCount = 0,
  });
}

/// Review model
class MarketplaceReview {
  final String id;
  final String listingId;
  final String reviewerId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const MarketplaceReview({
    required this.id,
    required this.listingId,
    required this.reviewerId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT MARKETPLACE SERVICE - Singleton
/// ═══════════════════════════════════════════════════════════════════════════
class FightMarketplaceService {
  static final FightMarketplaceService _instance =
      FightMarketplaceService._internal();
  factory FightMarketplaceService() => _instance;
  FightMarketplaceService._internal();

  // Data streams
  final _listingsController =
      StreamController<List<MarketplaceListing>>.broadcast();
  Stream<List<MarketplaceListing>> get listingsStream =>
      _listingsController.stream;

  final _trainersController =
      StreamController<List<TrainerProfile>>.broadcast();
  Stream<List<TrainerProfile>> get trainersStream => _trainersController.stream;

  // In-memory store (would be Firestore in production)
  final List<MarketplaceListing> _listings = [];
  final List<TrainerProfile> _trainers = [];
  final List<GymStartupPackage> _startupPackages = [];
  bool _seeded = false;

  /// Initialize with seed data
  Future<void> initialize() async {
    if (_seeded) return;
    await Future.delayed(const Duration(milliseconds: 200));
    _seedListings();
    _seedTrainers();
    _seedStartupPackages();
    _seeded = true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTINGS CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all active listings, optionally filtered
  List<MarketplaceListing> getListings({
    MarketplaceCategory? category,
    String? searchQuery,
    double? maxPrice,
    String? location,
    bool featuredOnly = false,
  }) {
    var results = _listings.where((l) => l.isActive).toList();

    if (category != null) {
      results = results.where((l) => l.category == category).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      results = results
          .where(
            (l) =>
                l.title.toLowerCase().contains(q) ||
                l.description.toLowerCase().contains(q) ||
                l.tags.any((t) => t.toLowerCase().contains(q)),
          )
          .toList();
    }
    if (maxPrice != null) {
      results = results.where((l) => l.price <= maxPrice).toList();
    }
    if (location != null) {
      results = results
          .where(
            (l) =>
                l.location?.toLowerCase().contains(location.toLowerCase()) ??
                false,
          )
          .toList();
    }
    if (featuredOnly) {
      results = results.where((l) => l.isFeatured).toList();
    }

    return results;
  }

  /// Get featured listings for homepage
  List<MarketplaceListing> getFeaturedListings({int limit = 5}) {
    return _listings
        .where((l) => l.isFeatured && l.isActive)
        .take(limit)
        .toList();
  }

  /// Get listings by seller
  List<MarketplaceListing> getSellerListings(String sellerId) {
    return _listings.where((l) => l.sellerId == sellerId).toList();
  }

  /// Create a new listing
  MarketplaceListing createListing({
    required String sellerId,
    required String sellerName,
    String? sellerAvatar,
    required String title,
    required String description,
    required MarketplaceCategory category,
    required double price,
    bool isNegotiable = false,
    List<String> images = const [],
    List<String> tags = const [],
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    final listing = MarketplaceListing(
      id: 'listing_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: sellerId,
      sellerName: sellerName,
      sellerAvatar: sellerAvatar,
      title: title,
      description: description,
      category: category,
      price: price,
      isNegotiable: isNegotiable,
      images: images,
      tags: tags,
      location: location,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      metadata: metadata,
    );

    _listings.insert(0, listing);
    _listingsController.add(_listings);
    return listing;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TRAINER DIRECTORY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all trainers, optionally filtered
  List<TrainerProfile> getTrainers({
    String? specialty,
    TrainerServiceType? serviceType,
    double? maxHourlyRate,
    String? location,
    bool availableOnly = true,
  }) {
    var results = List<TrainerProfile>.from(_trainers);

    if (specialty != null) {
      results = results
          .where(
            (t) => t.specialties.any(
              (s) => s.toLowerCase().contains(specialty.toLowerCase()),
            ),
          )
          .toList();
    }
    if (serviceType != null) {
      results = results.where((t) => t.services.contains(serviceType)).toList();
    }
    if (maxHourlyRate != null) {
      results = results.where((t) => t.hourlyRate <= maxHourlyRate).toList();
    }
    if (location != null) {
      results = results
          .where(
            (t) =>
                t.location?.toLowerCase().contains(location.toLowerCase()) ??
                false,
          )
          .toList();
    }
    if (availableOnly) {
      results = results.where((t) => t.isAvailable).toList();
    }

    return results;
  }

  /// Get top-rated trainers
  List<TrainerProfile> getTopTrainers({int limit = 5}) {
    final sorted = List<TrainerProfile>.from(_trainers)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return sorted.take(limit).toList();
  }

  /// Get women-specific trainers
  List<TrainerProfile> getWomenTrainers() {
    return _trainers
        .where(
          (t) =>
              t.services.contains(TrainerServiceType.womenOnly) ||
              t.services.contains(TrainerServiceType.traumaInformed) ||
              t.services.contains(TrainerServiceType.selfDefense),
        )
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GYM STARTUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get gym startup packages
  List<GymStartupPackage> getStartupPackages() =>
      List.unmodifiable(_startupPackages);

  // ═══════════════════════════════════════════════════════════════════════════
  // MARKETPLACE STATS
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> get marketplaceStats => {
    'totalListings': _listings.where((l) => l.isActive).length,
    'totalTrainers': _trainers.length,
    'categories': MarketplaceCategory.values.length,
    'featuredListings': _listings.where((l) => l.isFeatured).length,
    'totalViews': _listings.fold<int>(0, (sum, l) => sum + l.views),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // SEED DATA
  // ═══════════════════════════════════════════════════════════════════════════

  void _seedListings() {
    final now = DateTime.now();
    _listings.addAll([
      // Equipment listings
      MarketplaceListing(
        id: 'l1',
        sellerId: 'seller1',
        sellerName: 'Venum Official',
        title: 'Winning MS-600B Boxing Gloves 16oz',
        description:
            'Professional Winning boxing gloves. Lace-up, 16oz. Used for light sparring only. Original leather, perfect condition.',
        category: MarketplaceCategory.equipment,
        price: 280.00,
        isNegotiable: true,
        isFeatured: true,
        isVerified: true,
        tags: ['boxing', 'gloves', 'winning', 'sparring', 'professional'],
        location: 'Melbourne, VIC',
        createdAt: now.subtract(const Duration(hours: 6)),
        views: 234,
        saves: 45,
        inquiries: 12,
      ),
      MarketplaceListing(
        id: 'l2',
        sellerId: 'seller2',
        sellerName: 'Fairtex Australia',
        title: 'Fairtex Heavy Bag 6ft Banana Bag',
        description:
            'Fairtex HB6 banana bag. Perfect for kicks, knees, and full Muay Thai training. Unfilled — add your own filling for custom weight.',
        category: MarketplaceCategory.equipment,
        price: 189.99,
        isFeatured: true,
        isVerified: true,
        tags: ['muay thai', 'heavy bag', 'fairtex', 'training'],
        location: 'Sydney, NSW',
        createdAt: now.subtract(const Duration(hours: 12)),
        views: 156,
        saves: 28,
        inquiries: 8,
      ),
      MarketplaceListing(
        id: 'l3',
        sellerId: 'seller3',
        sellerName: 'SMAI Sports',
        title: 'SMAI Competition Boxing Ring 16x16ft',
        description:
            'Full competition-spec boxing ring. 16x16 foot. Includes ropes, turnbuckle pads, canvas, corner pads. Perfect for gym startup.',
        category: MarketplaceCategory.gymStartup,
        price: 4500.00,
        isNegotiable: true,
        tags: ['gym equipment', 'boxing ring', 'startup', 'competition'],
        location: 'Brisbane, QLD',
        createdAt: now.subtract(const Duration(days: 1)),
        views: 89,
        saves: 15,
        inquiries: 4,
      ),
      // Apparel
      MarketplaceListing(
        id: 'l4',
        sellerId: 'seller4',
        sellerName: 'DFC Official Store',
        title: 'DFC Data Fight Central Training Shorts',
        description:
            'Official DFC training shorts with neon detail. Lightweight, breathable, perfect for pad work and bag sessions.',
        category: MarketplaceCategory.apparel,
        price: 39.99,
        isFeatured: true,
        isVerified: true,
        tags: ['dfc', 'shorts', 'training', 'apparel', 'official'],
        createdAt: now.subtract(const Duration(hours: 3)),
        views: 520,
        saves: 98,
        inquiries: 32,
      ),
      // Supplements
      MarketplaceListing(
        id: 'l5',
        sellerId: 'seller5',
        sellerName: 'Bulk Nutrients Australia',
        title: 'Fighter\'s Recovery Stack - Protein + BCAAs + Electrolytes',
        description:
            'Complete recovery stack formulated for combat athletes. Whey isolate protein, BCAAs, and electrolyte mix. 30-day supply.',
        category: MarketplaceCategory.supplements,
        price: 74.99,
        tags: ['supplements', 'protein', 'recovery', 'nutrition', 'fighter'],
        location: 'Nationwide Shipping',
        createdAt: now.subtract(const Duration(hours: 18)),
        views: 310,
        saves: 67,
        inquiries: 19,
      ),
      // Recovery
      MarketplaceListing(
        id: 'l6',
        sellerId: 'seller6',
        sellerName: 'Hyperice Recovery',
        title: 'Therabody Theragun PRO - Fighter Bundle',
        description:
            'Pro-level percussive therapy gun with fighter accessories: jaw massager attachment, shin recovery guide, fight-camp recovery protocol included.',
        category: MarketplaceCategory.recovery,
        price: 349.00,
        isFeatured: true,
        tags: ['recovery', 'theragun', 'massage', 'therapy', 'pro'],
        createdAt: now.subtract(const Duration(days: 2)),
        views: 445,
        saves: 88,
        inquiries: 24,
      ),
      // Jobs
      MarketplaceListing(
        id: 'l7',
        sellerId: 'gym1',
        sellerName: 'UFC Gym Sydney',
        title: 'Boxing Coach Needed - Full Time',
        description:
            'Seeking experienced boxing coach for our growing gym. Must have coaching cert and at least 3 years experience. Competitive pay + benefits.',
        category: MarketplaceCategory.jobs,
        price: 0,
        tags: ['job', 'boxing coach', 'full time', 'coaching'],
        location: 'Gold Coast, QLD',
        createdAt: now.subtract(const Duration(hours: 36)),
        views: 178,
        saves: 22,
        inquiries: 9,
      ),
      MarketplaceListing(
        id: 'l8',
        sellerId: 'gym2',
        sellerName: 'Absolute MMA Melbourne',
        title: 'Sparring Partners Wanted - Welterweight',
        description:
            'Looking for quality welterweight sparring partners. 70-77 kg (155-170 lbs). Must have at least 1 year of training. Controlled sparring only.',
        category: MarketplaceCategory.sparringPartners,
        price: 0,
        tags: ['sparring', 'welterweight', 'mma', 'training partner'],
        location: 'Melbourne, VIC',
        createdAt: now.subtract(const Duration(hours: 8)),
        views: 267,
        saves: 41,
        inquiries: 15,
      ),
      // Events
      MarketplaceListing(
        id: 'l9',
        sellerId: 'promo1',
        sellerName: 'Hex Fight Series',
        title: 'Amateur Boxing Show - Fighters Wanted',
        description:
            'Seeking amateur boxers for our monthly show. All weight classes. USA Boxing card required. Great exposure + recorded bouts.',
        category: MarketplaceCategory.events,
        price: 0,
        tags: ['amateur', 'boxing show', 'event', 'competition'],
        location: 'Las Vegas, NV',
        createdAt: now.subtract(const Duration(days: 3)),
        views: 612,
        saves: 134,
        inquiries: 48,
      ),
      // ULTIMATE LEGENDS PROMOTIONS - Melbourne
      MarketplaceListing(
        id: 'l10',
        sellerId: 'ultimate_legends',
        sellerName: 'Ultimate Legends Promotions',
        title: 'ULTIMATE LEGENDS PRO FIGHT CARD - Melbourne Pavilion Dec 13',
        description:
            'PREMIUM COMBAT SPORTS EVENT\n\n12+ Bouts - Boxing | K1 | Muay Thai | Kickboxing | MMA\n\nVenue: Melbourne Pavilion, Kensington VIC\nFeaturing: Elias Khouri, Mikeydwcuz, bscerri34, and Australia\'s elite local talent\n\nFounded by: John Scida\nPartnership: Team Ultimate - Muay Thai, Kickboxing, Boxing & MMA\nBroadcast: Live Combat Sports\n\nAction-packed card with consistent 10+ high-energy bouts. Perfect venue, professional organization, and incredible fighter depth. Follow on Facebook & Instagram for event updates.',
        category: MarketplaceCategory.events,
        price: 45.00,
        isFeatured: true,
        isVerified: true,
        tags: [
          'boxing',
          'muay thai',
          'mma',
          'kickboxing',
          'k1',
          'melbourne',
          'australia',
          'professional',
          'elite',
          'ultimate legends',
        ],
        location: 'Melbourne Pavilion, Kensington VIC',
        latitude: -37.8044,
        longitude: 144.9568,
        createdAt: now.subtract(const Duration(days: 15)),
        views: 1240,
        saves: 289,
        inquiries: 124,
      ),
      MarketplaceListing(
        id: 'l11',
        sellerId: 'ultimate_legends',
        sellerName: 'Ultimate Legends Promotions',
        title:
            'ULTIMATE LEGENDS SUMMER 2026 - Championship Series Pre-Sale NOW OPEN',
        description:
            'ULTIMATE LEGENDS PROMOTIONS SUMMER CHAMPIONSHIP SERIES 2026\n\nFounded by: John Scida\n\nBe part of the biggest combat sports series in Australia this summer!\n\n✓ 14+ High-action bouts per card\n✓ Elite local Australian talent\n✓ Professional production quality\n✓ Multiple venues across Melbourne\n✓ Broadcast via Live Combat Sports\n✓ Partnership with Team Ultimate\n\nEarly bird tickets now available. Limited premium seating.\n\nFollow Ultimate Legends Promotions on Facebook & Instagram for:\n- Fighter announcements\n- Bout cards\n- Live updates  \n- Behind-the-scenes content\n\nVenue: Melbourne Pavilion, Kensington VIC (Primary)\nMultiple events throughout summer 2026',
        category: MarketplaceCategory.events,
        price: 35.00,
        isFeatured: true,
        isVerified: true,
        tags: [
          'ultimate legends',
          'championship',
          'boxing',
          'muay thai',
          'mma',
          'melbourne',
          'australia',
          'team ultimate',
          'summer 2026',
          'professional combat sports',
        ],
        location: 'Melbourne Pavilion & Partner Venues',
        createdAt: now,
        views: 890,
        saves: 176,
        inquiries: 67,
      ),
      MarketplaceListing(
        id: 'l12',
        sellerId: 'ultimate_legends',
        sellerName: 'Ultimate Legends Promotions',
        title: 'Fighter Opportunities - Ultimate Legends 2026 Roster',
        description:
            'ARE YOU READY FOR THE ULTIMATE LEGENDS STAGE?\n\nUltimate Legends Promotions is now accepting fighter applications for our 2026 season.\n\n📍 Location: Melbourne\n🎯 Styles: Boxing | K1 | Muay Thai | Kickboxing | MMA\n👥 Experience: Amateur to Pro\n\nWhy fight for Ultimate Legends?\n• Professional production & broadcasts\n• Live streaming via Live Combat Sports\n• Fighting opportunity every month\n• Real exposure & social media promotion\n• Fair fighter purses\n• Support from genuine combat sports community\n• Partnership with Team Ultimate ecosystem\n\nInterested? Follow us on Facebook or send inquiry through this listing.\n\nFounded by John Scida | Melbourne-based | 2025+ events | 10+ bouts per card | Real opportunities for real fighters',
        category: MarketplaceCategory.events,
        price: 0,
        isFeatured: true,
        isVerified: true,
        tags: [
          'fighter opportunities',
          'boxing',
          'muay thai',
          'mma',
          'kickboxing',
          'k1',
          'melbourne',
          'australia',
          'professional',
          'ultimate legends',
        ],
        location: 'Melbourne, Australia',
        createdAt: now.subtract(const Duration(hours: 24)),
        views: 1580,
        saves: 412,
        inquiries: 203,
      ),
      // Melbourne's Best Muay Thai Gyms - Featured Listings
      MarketplaceListing(
        id: 'l13',
        sellerId: 'honour_martial_arts',
        sellerName: 'Honour Martial Arts - Melbourne',
        title: 'Honour Martial Arts - Melbourne | 5.0⭐ Best Muay Thai Gym',
        description:
            'TOP-RATED MUAY THAI BOXING GYM - Melbourne\'s #1 Choice\n\n✅ PERFECT 5.0 RATING | 173 Reviews\n✅ Oakleigh Location | Modern Facility\n✅ Professional Welcoming Coaches\n✅ Classes for ALL Skill Levels\n✅ Strong Uplifting Community\n\nHonour Martial Arts delivers:\n• Expert technical instruction\n• Family-friendly environment\n• Flexible class schedules\n• Online classes available\n• Wheelchair-accessible\n\n"The best decision I\'ve ever made was signing up to Honour. The coaching staff are welcoming and knowledgeable, creating an uplifting community with no animosity."\n\nStart your journey today:\n📞 +61 451 496 008\n🌐 honourmartialarts.com.au\n📍 2/19 Edward St, Oakleigh VIC 3166',
        category: MarketplaceCategory.events,
        price: 0,
        isFeatured: true,
        isVerified: true,
        tags: [
          'muay thai',
          'boxing',
          'gym membership',
          'melbourne',
          'oakleigh',
          'classes',
          'all levels',
          'australia',
          'top rated',
        ],
        location: 'Oakleigh, Melbourne VIC',
        latitude: -37.9070,
        longitude: 145.1170,
        createdAt: now,
        views: 2340,
        saves: 534,
        inquiries: 298,
      ),
      MarketplaceListing(
        id: 'l14',
        sellerId: 'the_ring_gym',
        sellerName: 'The Ring Gym',
        title: 'The Ring Gym - Braybrook | 5.0⭐ Premier Muay Thai',
        description:
            'ELITE MUAY THAI BOXING GYM - Braybrook\'s Best\n\n✅ PERFECT 5.0 RATING | 68 Reviews\n✅ Expert Experienced Trainers\n✅ Vibrant Supportive Community\n✅ All Levels: Beginners to Fighters\n✅ Self-Defense + Competition Training\n\nWhat Members Love:\n• Dedicated high-quality instructors\n• Positive encouraging environment\n• Suitable for fitness and fighting\n• Strong member camaraderie\n• Professional coaching quality\n\n"The dedicated and experienced trainers provide top-notch training. The vibrant and supportive community at the gym fosters a positive environment where everyone helps each other achieve their goals."\n\nJoin The Ring Gym Family:\n📞 +61 438 797 477\n🌐 theringgym.com.au\n📍 Unit 4/75A Ashley St, Braybrook VIC 3019',
        category: MarketplaceCategory.events,
        price: 0,
        isFeatured: true,
        isVerified: true,
        tags: [
          'muay thai',
          'boxing',
          'gym',
          'braybrook',
          'melbourne',
          'self defense',
          'fitness',
          'professional',
          '5 star',
        ],
        location: 'Braybrook, Melbourne VIC',
        latitude: -37.8317,
        longitude: 144.8635,
        createdAt: now,
        views: 1890,
        saves: 412,
        inquiries: 201,
      ),
      MarketplaceListing(
        id: 'l15',
        sellerId: 'dynamite_muay_thai',
        sellerName: 'Dynamite Muay Thai',
        title:
            'Dynamite Muay Thai - Melbourne CBD | Expert Coaches & Community',
        description:
            'DYNAMITE MUAY THAI - Melbourne\'s Action Gym\n\n⭐ 4.7 RATING | 52 Reviews | CBD Location\n🥊 Expert Coaching Staff\n👥 Incredible Community Feel\n🎯 All Skill Levels Welcome\n💪 Personalized Training Plans\n\nCoaches: Kru Dennis, Lily, Zia (all expert fighters)\n\nMember Testimonials:\n"I\'ve joined Dynamite roughly 5 months ago and my experience here is nothing short of amazing. The love and respect that echo through the walls make it a special place."\n\n"Dynamite is leagues beyond a commercial martial arts gym. Coaches here will change you for the better."\n\n"Started looking for a place to get fit and ended up representing Dynamite in a fight. Found purpose, a family, and so much more. 10/10 would recommend."\n\nFocus: Teamwork, Respect, Growth\n📞 +61 3 9041 7241\n🌐 dynamitemuaythai.com\n📍 Level 1/388 Bourke St, Melbourne VIC 3000',
        category: MarketplaceCategory.events,
        price: 0,
        isFeatured: true,
        isVerified: true,
        tags: [
          'muay thai',
          'boxing',
          'cbd',
          'melbourne',
          'coaching',
          'community',
          'fighters',
          'professional',
          'gym',
        ],
        location: 'Melbourne CBD VIC',
        latitude: -37.8157,
        longitude: 144.9697,
        createdAt: now.subtract(const Duration(hours: 12)),
        views: 1650,
        saves: 389,
        inquiries: 176,
      ),
      MarketplaceListing(
        id: 'l16',
        sellerId: 'js_muay_thai',
        sellerName: 'JS Muay Thai',
        title: 'JS Muay Thai - Footscray | Women-Friendly 5.0⭐ Gym',
        description:
            'JS MUAY THAI - Footscray\'s Premier Women-Focused Gym\n\n✅ PERFECT 5.0 RATING | 52 Reviews\n✅ Women-Empowering Environment\n✅ Inclusive & Supportive Community\n✅ Knowledgeable Patient Coaches\n✅ Clean Well-Maintained Facility\n\nWhy Women Choose JS Muay Thai:\n• Safe, judgment-free space\n• Female-friendly class times\n• Expert instruction tailored to you\n• Easy accessible location\n• Supportive member community\n• Online classes available\n\n"Empowering and inclusive community for women of all skill levels. Highly recommended for females looking to start or continue their fitness journey!"\n\n📍 Footscray Location\n🎯 Beginner to Advanced Classes\n💪 Fitness + Competition Training\n👥 1000+ Female Members Happy\n\nStart Your Journey:\n📞 +61 481 591 917\n🌐 jsmuaythai.com.au\n📍 23 Ann St, Footscray VIC 3011',
        category: MarketplaceCategory.events,
        price: 0,
        isFeatured: true,
        isVerified: true,
        tags: [
          'muay thai',
          'women friendly',
          'boxing',
          'footscray',
          'melbourne',
          'self defense',
          'fitness',
          'inclusive',
          'community',
        ],
        location: 'Footscray, Melbourne VIC',
        latitude: -37.8067,
        longitude: 144.8903,
        createdAt: now.subtract(const Duration(hours: 6)),
        views: 1420,
        saves: 356,
        inquiries: 198,
      ),
    ]);
  }

  void _seedTrainers() {
    _trainers.addAll([
      const TrainerProfile(
        userId: 'trainer1',
        name: 'Rob Sobhani — Absolute MMA',
        bio:
            'Former professional boxer (18-3-1). 12 years coaching experience. Head trainer at Absolute MMA Melbourne. Specializing in technical boxing and fight preparation for amateurs turning pro.',
        specialties: ['Boxing', 'Strength & Conditioning'],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.fightCamp,
          TrainerServiceType.proLevel,
        ],
        hourlyRate: 85.00,
        rating: 4.9,
        reviewCount: 127,
        clientsServed: 340,
        yearsExperience: 12,
        certifications: ['USA Boxing Level 3', 'NSCA-CSCS', 'CPR/First Aid'],
        location: 'Las Vegas, NV',
        isVerified: true,
        offersTrialSession: true,
        trialDescription: 'Free 30-min assessment session',
      ),
      const TrainerProfile(
        userId: 'trainer2',
        name: 'Sylvie von Duuglas-Ittu',
        bio:
            'Muay Thai fighter & coach with 270+ fights in Thailand. Specializing in women\'s Muay Thai, authentic Thai training methods, and trauma-informed coaching. Creating safe spaces for women to train and build confidence through combat sports.',
        specialties: ['Muay Thai', 'Self-Defense', 'Women\'s Fitness Boxing'],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.groupClass,
          TrainerServiceType.womenOnly,
          TrainerServiceType.traumaInformed,
          TrainerServiceType.selfDefense,
          TrainerServiceType.beginnerFriendly,
        ],
        hourlyRate: 65.00,
        rating: 4.95,
        reviewCount: 89,
        clientsServed: 215,
        yearsExperience: 8,
        certifications: [
          'Certified Muay Thai Instructor',
          'Trauma-Informed Coaching',
          'Women\'s Self Defense Specialist',
          'CPR/First Aid',
        ],
        location: 'Melbourne, VIC',
        isVerified: true,
        offersTrialSession: true,
        trialDescription: 'Free intro session — safe, supportive, no pressure',
      ),
      const TrainerProfile(
        userId: 'trainer3',
        name: 'Lachlan Giles — Absolute MMA',
        bio:
            'BJJ black belt under Marcelo Garcia. Competition and self-defense focused. All levels welcome from white belt to brown belt prep.',
        specialties: ['Brazilian Jiu-Jitsu', 'No-Gi Grappling', 'Wrestling'],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.groupClass,
          TrainerServiceType.onlineCoaching,
          TrainerServiceType.beginnerFriendly,
          TrainerServiceType.proLevel,
        ],
        hourlyRate: 75.00,
        rating: 4.8,
        reviewCount: 203,
        clientsServed: 480,
        yearsExperience: 15,
        certifications: ['BJJ Black Belt', 'IBJJF Referee', 'First Aid'],
        location: 'Melbourne, VIC',
        isVerified: true,
        offersTrialSession: true,
        trialDescription: 'First class free — Gi or No-Gi',
      ),
      const TrainerProfile(
        userId: 'trainer4',
        name: 'Tayla Harris — Boxing & Empowerment',
        bio:
            'Professional boxer and advocate for women in sport. Personal training for women of all backgrounds — especially those looking for empowerment through boxing and fitness.',
        specialties: ['Boxing', 'Kickboxing', 'Womens Empowerment Training'],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.womenOnly,
          TrainerServiceType.traumaInformed,
          TrainerServiceType.selfDefense,
          TrainerServiceType.fitnessBoxing,
          TrainerServiceType.beginnerFriendly,
        ],
        hourlyRate: 50.00,
        rating: 4.92,
        reviewCount: 56,
        clientsServed: 95,
        yearsExperience: 4,
        certifications: [
          'Level 2 Boxing Coach',
          'Personal Trainer (NASM)',
          'Mental Health First Aid',
          'Trauma-Informed Practice',
        ],
        location: 'Manchester, UK',
        isVerified: true,
        offersTrialSession: true,
        trialDescription:
            'Free taster session — no experience needed, we all start somewhere ❤️',
      ),
      const TrainerProfile(
        userId: 'trainer5',
        name: 'Kru Somchai Petchrungruang',
        bio:
            'Thai-born Kru with 200+ Muay Thai fights. Authentic Muay Thai training — technique, clinch, traditional methods. Fight camps and seminars available worldwide.',
        specialties: ['Muay Thai', 'Clinch Work', 'Thai Pad Holding'],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.groupClass,
          TrainerServiceType.fightCamp,
          TrainerServiceType.seminar,
          TrainerServiceType.proLevel,
        ],
        hourlyRate: 95.00,
        rating: 5.0,
        reviewCount: 312,
        clientsServed: 820,
        yearsExperience: 22,
        certifications: [
          'Kru Level 5',
          'WMC Registered Coach',
          'Sports Science Diploma (Thailand)',
        ],
        location: 'Bangkok / Travel Available',
        isVerified: true,
      ),
      const TrainerProfile(
        userId: 'trainer6',
        name: 'Jake Morrison \u2014 Morrison Performance',
        bio:
            'Elite S&C coach working with UFC, PFL, and Bellator fighters. Gym startup consultant. Helped launch 15+ combat sports gyms. Equipment sourcing, layout design, membership systems, and business mentoring.',
        specialties: [
          'Gym Startup Consulting',
          'Strength & Conditioning',
          'Business Development',
        ],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.onlineCoaching,
          TrainerServiceType.seminar,
        ],
        hourlyRate: 120.00,
        rating: 4.85,
        reviewCount: 67,
        clientsServed: 42,
        yearsExperience: 10,
        certifications: [
          'NSCA-CSCS',
          'Business Management Degree',
          'Gym Design Certificate',
        ],
        location: 'Remote / Nationwide',
        isVerified: true,
        offersTrialSession: true,
        trialDescription: 'Free 20-min gym startup discovery call',
      ),
      const TrainerProfile(
        userId: 'trainer_hex_fs',
        name: 'Hex Fight Series Academy',
        bio:
            '🏆 HEX FIGHT SERIES ACADEMY 🏆\nAustralia\'s premier MMA promotion now offers fighter development. Train under fight-tested coaches at Melbourne Pavilion. From grassroots to UFC Fight Pass.\n\nSpecializes in: Complete fighter development • Personalized training plans • Nutrition & recovery protocols • Mental resilience coaching • Competition preparation • Career pathway guidance\n\n✅ FREE ACCESS: Community training, live technique sessions, and career mentoring.',
        specialties: [
          'Complete Fighter Development',
          'Technique & Conditioning',
          'Mental Coaching',
          'Career Guidance',
          'Team Building',
        ],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.groupClass,
          TrainerServiceType.fightCamp,
          TrainerServiceType.onlineCoaching,
          TrainerServiceType.seminar,
          TrainerServiceType.proLevel,
        ],
        hourlyRate: 0.00,
        rating: 4.97,
        reviewCount: 412,
        clientsServed: 1200,
        yearsExperience: 18,
        certifications: [
          'Head Coach - International MMA',
          'Sports Psychology Diploma',
          'Elite Conditioning Specialist',
          'IBJJF Certified',
          'Boxing Federation Level 5',
        ],
        location: 'Melbourne, Australia',
        isVerified: true,
        offersTrialSession: true,
        trialDescription:
            'FREE - Join the Hex FS Academy community tier instantly. No credit card needed!',
      ),
      const TrainerProfile(
        userId: 'trainer7',
        name: 'John Wayne Parr',
        bio:
            'Former professional kickboxer (24-5-0) with devastating striking technique. Specializes in conditioning and striking fundamentals for all combat sports.',
        specialties: ['Kickboxing', 'Muay Thai', 'Boxing Conditioning'],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.groupClass,
          TrainerServiceType.fightCamp,
          TrainerServiceType.proLevel,
        ],
        hourlyRate: 80.00,
        rating: 4.91,
        reviewCount: 178,
        clientsServed: 520,
        yearsExperience: 14,
        certifications: [
          'Pro Kickboxer',
          'WAKO Certified Coach',
          'Strength Coach CSCS',
        ],
        location: 'Amsterdam / Sydney',
        isVerified: true,
        offersTrialSession: true,
        trialDescription: 'First striking session — bring energy!',
      ),
      const TrainerProfile(
        userId: 'trainer8',
        name: 'Anthony "The Technician" Park',
        bio:
            'Former boxer turned grappling specialist. Unique blend of footwork and wrestling. Love coaching fighters who want to add wrestling to their arsenal.',
        specialties: ['Wrestling', 'Boxing', 'Takedown Defense'],
        services: [
          TrainerServiceType.oneOnOne,
          TrainerServiceType.groupClass,
          TrainerServiceType.fightCamp,
          TrainerServiceType.proLevel,
        ],
        hourlyRate: 70.00,
        rating: 4.88,
        reviewCount: 142,
        clientsServed: 380,
        yearsExperience: 11,
        certifications: [
          'Collegiate Wrestling Coach',
          'Amateur Boxing Trainer',
          'MMA Level 3',
        ],
        location: 'Portland, OR',
        isVerified: true,
        offersTrialSession: true,
        trialDescription: 'Free wrestling fundamentals session',
      ),
    ]);
  }

  void _seedStartupPackages() {
    _startupPackages.addAll([
      const GymStartupPackage(
        id: 'pkg1',
        title: 'Boxing Gym Starter Kit',
        description:
            'Everything you need to open a boxing gym from scratch. Ring, bags, equipment, and setup guide included.',
        includes: [
          '16ft Competition Boxing Ring',
          '6x Heavy Bags (various weights)',
          '2x Speed Bags with platforms',
          '10x Pairs of Gym Gloves',
          '20x Hand Wraps',
          'Round Timer System',
          'Mirror wall kit (8x4ft)',
          'Gym layout design consultation',
          'Business startup guide',
        ],
        price: 12500.00,
        vendorName: 'SMAI Sports',
        rating: 4.7,
        reviewCount: 23,
      ),
      const GymStartupPackage(
        id: 'pkg2',
        title: 'MMA Studio Complete Package',
        description:
            'Full MMA training facility setup. Cage, mats, bags, grappling equipment, and more.',
        includes: [
          '20ft MMA Cage (competition spec)',
          '800 sqft Wrestling/BJJ Mats',
          '8x Heavy Bags',
          '4x Grappling Dummies',
          'Full pad set (Thai, Focus, Kick)',
          'Resistance band station',
          'Round timer + interval system',
          'Facility design consultation',
          'Equipment maintenance guide',
        ],
        price: 22000.00,
        vendorName: 'Combat Gym Solutions',
        rating: 4.9,
        reviewCount: 15,
      ),
      const GymStartupPackage(
        id: 'pkg3',
        title: 'Home Garage Gym Kit',
        description:
            'Convert your garage into a fight training space. All the essentials for serious home training.',
        includes: [
          '1x 100lb Heavy Bag + mount',
          '1x Double-end Bag',
          '1x Speed Bag + platform',
          '3x Pairs of Gloves (12, 14, 16oz)',
          'Focus Mitts + Thai Pads',
          'Floor mats (100 sqft)',
          'Round timer',
          'Jump rope + resistance bands',
        ],
        price: 1800.00,
        vendorName: 'Venum Official',
        rating: 4.8,
        reviewCount: 89,
      ),
      const GymStartupPackage(
        id: 'pkg4',
        title: 'Hex Fight Series Academy - Complete Fighter Program',
        description:
            'Join the Hex Fight Series Academy. Complete fighter development with access to elite coaching, training programs, nutrition protocols, and career mentoring. FREE community tier included!',
        includes: [
          'FREE Community Training Access',
          'Weekly Technique Sessions (Live)',
          'Training Program Templates',
          'Nutrition & Recovery Guidelines',
          'Mental Resilience Coaching Sessions',
          'Career Pathway Guidance',
          'Community Discord Access',
          'Monthly Performance Reviews',
          'Access to Fighter Network',
          'Optional Premium 1-on-1 Sessions (paid add-on)',
        ],
        price: 0.00,
        vendorName: 'Hex Fight Series',
        rating: 4.97,
        reviewCount: 412,
      ),
      const GymStartupPackage(
        id: 'pkg5',
        title: 'Striking Specialist Studio',
        description:
            'Complete setup for a dedicated striking gym. Heavy bags, speed bags, pads, and professional striking equipment for serious training.',
        includes: [
          '12x Heavy Bags (50, 70, 100lb)',
          '4x Speed Bags + stands',
          '6x Double-end Bags',
          '20x Professional Pair Gloves',
          'Complete pad set (Thai, Focus, Kick)',
          'Floor mats (200 sqft)',
          'Mirror walls and sound system',
          'Professional Round Timer',
          'Shadowbox reflection wall',
          'Video recording station',
        ],
        price: 8500.00,
        vendorName: 'Hayabusa',
        rating: 4.86,
        reviewCount: 34,
      ),
    ]);
  }

  void dispose() {
    _listingsController.close();
    _trainersController.close();
  }
}
