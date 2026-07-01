import 'dart:async';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT PASS & TICKETS SERVICE — DFC Access, Events, Charity, Community
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Powers:
///  - Fight Passes:  VIP, Backstage, Meet-the-Fighter, Kids, Charity
///  - Show Tickets:  General admission, ringside, VIP, streaming
///  - Campaigns:     Sick kids, awareness, charity, community fundraising
///  - Donations:     One-time or recurring to campaigns
///  - Discounts:     Promo codes, group, military/first-responder, student
///
/// "We all got some fight" — DFC makes passes accessible for everyone.
/// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────

enum PassType {
  general,
  vip,
  backstage,
  meetAndGreet,
  kidsPass,
  familyPack,
  charity,
  streaming,
  pressMedia,
}

enum TicketTier {
  generalAdmission,
  ringside,
  vipFloor,
  vipSuite,
  backstageAllAccess,
  streamingOnly,
}

enum CampaignType {
  sickKids,
  mentalHealthAwareness,
  veteranSupport,
  communityGym,
  youthTraining,
  disabilityInclusion,
  antibullying,
  womenInCombatSports,
  homelessOutreach,
  custom,
}

enum DiscountType {
  promoCode,
  earlyBird,
  groupDiscount,
  military,
  firstResponder,
  student,
  seniorCitizen,
  dfcMember,
  charityDonor,
  loyalty,
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

/// A fight pass granting access to events / experiences
class FightPass {
  final String id;
  final String name;
  final String description;
  final PassType type;
  final double price;
  final String currency;
  final String? eventId;
  final String? eventName;
  final DateTime? eventDate;
  final String? venue;
  final List<String> includes;
  final int? maxQuantity;
  final int soldCount;
  final bool isLimited;
  final bool isCharity;
  final double? charityPercentage; // % of price going to campaign
  final String? campaignId;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  const FightPass({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.price,
    this.currency = 'USD',
    this.eventId,
    this.eventName,
    this.eventDate,
    this.venue,
    required this.includes,
    this.maxQuantity,
    this.soldCount = 0,
    this.isLimited = false,
    this.isCharity = false,
    this.charityPercentage,
    this.campaignId,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  double get percentSold =>
      maxQuantity != null && maxQuantity! > 0 ? soldCount / maxQuantity! : 0;
  bool get isSoldOut => maxQuantity != null && soldCount >= maxQuantity!;
}

/// A ticket for a specific show/event
class ShowTicket {
  final String id;
  final String eventId;
  final String eventName;
  final DateTime eventDate;
  final String venue;
  final TicketTier tier;
  final double price;
  final double? originalPrice; // Before discount
  final String currency;
  final String? seatSection;
  final String? seatRow;
  final String? seatNumber;
  final bool isTransferable;
  final String? qrCode;
  final String buyerId;
  final DateTime purchasedAt;

  const ShowTicket({
    required this.id,
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.venue,
    required this.tier,
    required this.price,
    this.originalPrice,
    this.currency = 'USD',
    this.seatSection,
    this.seatRow,
    this.seatNumber,
    this.isTransferable = true,
    this.qrCode,
    required this.buyerId,
    required this.purchasedAt,
  });

  bool get isDiscounted => originalPrice != null && originalPrice! > price;
  double get savingsPercent =>
      isDiscounted ? ((originalPrice! - price) / originalPrice! * 100) : 0;
}

/// A charity or awareness campaign
class FightCampaign {
  final String id;
  final String title;
  final String description;
  final CampaignType type;
  final String organizer;
  final double goalAmount;
  final double raisedAmount;
  final String currency;
  final int donorCount;
  final int passesContributed; // Passes sold for this campaign
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final String? imageUrl;
  final String? website;
  final List<String> tags;
  final String impactStatement; // "Every $10 gives a kid a day at the gym"

  const FightCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.organizer,
    required this.goalAmount,
    this.raisedAmount = 0,
    this.currency = 'USD',
    this.donorCount = 0,
    this.passesContributed = 0,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.imageUrl,
    this.website,
    this.tags = const [],
    required this.impactStatement,
  });

  double get percentFunded =>
      goalAmount > 0 ? (raisedAmount / goalAmount).clamp(0, 1) : 0;
  bool get isFullyFunded => raisedAmount >= goalAmount;
}

/// A donation
class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String campaignId;
  final double amount;
  final String currency;
  final bool isAnonymous;
  final bool isRecurring;
  final String? message;
  final DateTime createdAt;

  const Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.campaignId,
    required this.amount,
    this.currency = 'USD',
    this.isAnonymous = false,
    this.isRecurring = false,
    this.message,
    required this.createdAt,
  });
}

/// A discount / promo code
class FightDiscount {
  final String id;
  final String code;
  final DiscountType type;
  final double discountPercent; // 0-100
  final double? maxDiscount; // Cap
  final int? maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final bool isActive;
  final String? description;

  const FightDiscount({
    required this.id,
    required this.code,
    required this.type,
    required this.discountPercent,
    this.maxDiscount,
    this.maxUses,
    this.usedCount = 0,
    this.expiresAt,
    this.isActive = true,
    this.description,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isUsedUp => maxUses != null && usedCount >= maxUses!;
  bool get isValid => isActive && !isExpired && !isUsedUp;
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICE
// ─────────────────────────────────────────────────────────────────────────────

class FightPassService {
  static final FightPassService _instance = FightPassService._internal();
  factory FightPassService() => _instance;
  FightPassService._internal();

  final List<FightPass> _passes = [];
  final List<ShowTicket> _tickets = [];
  final List<FightCampaign> _campaigns = [];
  final List<Donation> _donations = [];
  final List<FightDiscount> _discounts = [];
  bool _seeded = false;

  final _passController = StreamController<List<FightPass>>.broadcast();
  Stream<List<FightPass>> get passStream => _passController.stream;

  final _campaignController = StreamController<List<FightCampaign>>.broadcast();
  Stream<List<FightCampaign>> get campaignStream => _campaignController.stream;

  /// Initialize with seed data
  Future<void> initialize() async {
    if (_seeded) return;
    await Future.delayed(const Duration(milliseconds: 200));
    _seedPasses();
    _seedCampaigns();
    _seedDiscounts();
    _seeded = true;
  }

  // ── PASSES ──

  List<FightPass> getPasses({PassType? type, bool activeOnly = true}) {
    var results = List<FightPass>.from(_passes);
    if (activeOnly) results = results.where((p) => p.isActive).toList();
    if (type != null) results = results.where((p) => p.type == type).toList();
    return results;
  }

  List<FightPass> getCharityPasses() =>
      _passes.where((p) => p.isCharity && p.isActive).toList();

  List<FightPass> getKidsPasses() =>
      _passes.where((p) => p.type == PassType.kidsPass && p.isActive).toList();

  // ── CAMPAIGNS ──

  List<FightCampaign> getCampaigns({
    CampaignType? type,
    bool activeOnly = true,
  }) {
    var results = List<FightCampaign>.from(_campaigns);
    if (activeOnly) results = results.where((c) => c.isActive).toList();
    if (type != null) results = results.where((c) => c.type == type).toList();
    return results;
  }

  FightCampaign? getCampaign(String id) {
    try {
      return _campaigns.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Record a donation
  Donation makeDonation({
    required String donorId,
    required String donorName,
    required String campaignId,
    required double amount,
    bool isAnonymous = false,
    bool isRecurring = false,
    String? message,
  }) {
    final donation = Donation(
      id: 'don_${DateTime.now().millisecondsSinceEpoch}',
      donorId: donorId,
      donorName: donorName,
      campaignId: campaignId,
      amount: amount,
      isAnonymous: isAnonymous,
      isRecurring: isRecurring,
      message: message,
      createdAt: DateTime.now(),
    );
    _donations.add(donation);

    // Update campaign raised amount
    final idx = _campaigns.indexWhere((c) => c.id == campaignId);
    if (idx >= 0) {
      final old = _campaigns[idx];
      _campaigns[idx] = FightCampaign(
        id: old.id,
        title: old.title,
        description: old.description,
        type: old.type,
        organizer: old.organizer,
        goalAmount: old.goalAmount,
        raisedAmount: old.raisedAmount + amount,
        donorCount: old.donorCount + 1,
        passesContributed: old.passesContributed,
        startDate: old.startDate,
        endDate: old.endDate,
        isActive: old.isActive,
        imageUrl: old.imageUrl,
        website: old.website,
        tags: old.tags,
        impactStatement: old.impactStatement,
      );
      _campaignController.add(_campaigns);
    }

    return donation;
  }

  // ── DISCOUNTS ──

  List<FightDiscount> getValidDiscounts() =>
      _discounts.where((d) => d.isValid).toList();

  FightDiscount? applyPromoCode(String code) {
    try {
      final discount = _discounts.firstWhere(
        (d) => d.code.toUpperCase() == code.toUpperCase() && d.isValid,
      );
      return discount;
    } catch (_) {
      return null;
    }
  }

  // ── TICKETS ──

  List<ShowTicket> getUserTickets(String userId) =>
      _tickets.where((t) => t.buyerId == userId).toList();

  ShowTicket purchaseTicket({
    required String eventId,
    required String eventName,
    required DateTime eventDate,
    required String venue,
    required TicketTier tier,
    required double price,
    double? originalPrice,
    required String buyerId,
    String? seatSection,
  }) {
    final ticket = ShowTicket(
      id: 'tkt_${DateTime.now().millisecondsSinceEpoch}',
      eventId: eventId,
      eventName: eventName,
      eventDate: eventDate,
      venue: venue,
      tier: tier,
      price: price,
      originalPrice: originalPrice,
      buyerId: buyerId,
      seatSection: seatSection,
      qrCode:
          'DFC-${eventId.hashCode.abs()}-${DateTime.now().millisecondsSinceEpoch}',
      purchasedAt: DateTime.now(),
    );
    _tickets.add(ticket);
    return ticket;
  }

  // ── STATS ──

  Map<String, dynamic> get stats => {
    'totalPasses': _passes.where((p) => p.isActive).length,
    'activeCampaigns': _campaigns.where((c) => c.isActive).length,
    'totalRaised': _campaigns.fold<double>(0, (s, c) => s + c.raisedAmount),
    'totalDonors': _donations.map((d) => d.donorId).toSet().length,
    'ticketsSold': _tickets.length,
    'activeDiscounts': _discounts.where((d) => d.isValid).length,
  };

  // ── SEED DATA ──

  void _seedPasses() {
    final now = DateTime.now();
    _passes.addAll([
      FightPass(
        id: 'pass_vip_1',
        name: 'VIP Ringside Experience',
        description:
            'Front row seats, premium bar access, and exclusive fighter walkout viewing area. The closest you\'ll get without gloves on.',
        type: PassType.vip,
        price: 349.99,
        eventId: 'evt_main_001',
        eventName: 'DFC Fight Night: Clash of Champions',
        eventDate: now.add(const Duration(days: 30)),
        venue: 'Brisbane Entertainment Centre, Brisbane',
        includes: [
          'Ringside seating (first 2 rows)',
          'Premium open bar',
          'Fighter walkout tunnel access',
          'Official event programme',
          'DFC merch pack',
          'Photo opportunities',
        ],
        maxQuantity: 50,
        soldCount: 38,
        isLimited: true,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      FightPass(
        id: 'pass_backstage_1',
        name: 'Backstage All-Access Pass',
        description:
            'Full backstage access. Watch fighters warm up, meet the teams, see the action behind the scenes. Limited to 20 per event.',
        type: PassType.backstage,
        price: 599.99,
        eventId: 'evt_main_001',
        eventName: 'DFC Fight Night: Clash of Champions',
        eventDate: now.add(const Duration(days: 30)),
        venue: 'Brisbane Entertainment Centre, Brisbane',
        includes: [
          'Full backstage access',
          'Warm-up area viewing',
          'Meet fighters & their teams',
          'Professional photo session',
          'Signed gloves from main event fighters',
          'VIP seating included',
          'Exclusive backstage-only merch',
        ],
        maxQuantity: 20,
        soldCount: 14,
        isLimited: true,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      FightPass(
        id: 'pass_mag_1',
        name: 'Meet & Greet: Champion\'s Circle',
        description:
            'Intimate 45-minute session with headline fighters. Autographs, photos, Q&A. Maximum 30 fans per session.',
        type: PassType.meetAndGreet,
        price: 199.99,
        eventId: 'evt_main_001',
        eventName: 'DFC Fight Night: Clash of Champions',
        eventDate: now.add(const Duration(days: 30)),
        venue: 'Brisbane Entertainment Centre, Brisbane',
        includes: [
          '45-minute group session with headliners',
          'Autograph signing',
          'Individual photo with fighters',
          'Q&A session',
          'General admission ticket included',
        ],
        maxQuantity: 30,
        soldCount: 22,
        isLimited: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      FightPass(
        id: 'pass_kids_1',
        name: 'Kids Fight Pass',
        description:
            'Special fight-night experience for young fans (ages 6-15). Safe, supervised, and unforgettable. We all got some fight.',
        type: PassType.kidsPass,
        price: 44.99,
        eventId: 'evt_main_001',
        eventName: 'DFC Fight Night: Clash of Champions',
        eventDate: now.add(const Duration(days: 30)),
        venue: 'Brisbane Entertainment Centre, Brisbane',
        includes: [
          'Supervised kids zone with activities',
          'Fighter meet & greet (family-friendly)',
          'Mini training session with coaches',
          'DFC kids merch pack (t-shirt + headband)',
          'Healthy snack pack',
          '1 adult companion ticket included',
        ],
        maxQuantity: 100,
        soldCount: 67,
        createdAt: now.subtract(const Duration(days: 21)),
      ),
      FightPass(
        id: 'pass_kids_charity_1',
        name: 'Champions for Kids Pass',
        description:
            'Buy a pass and DFC sends a sick kid to fight night FOR FREE. 100% of proceeds go to our Fighters for Kids campaign. Give the gift of an unforgettable experience.',
        type: PassType.charity,
        price: 75.00,
        eventName: 'DFC Fighters for Kids',
        includes: [
          'Sends 1 sick child + guardian to a fight night',
          'Includes kids zone access + meet & greet',
          'DFC care package for the child',
          'Thank you card from the child',
          'Tax-deductible donation receipt',
          'Your name on the DFC Champions Wall',
        ],
        isCharity: true,
        charityPercentage: 100,
        campaignId: 'camp_sick_kids',
        soldCount: 234,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
      FightPass(
        id: 'pass_family_1',
        name: 'Family Fight Night Pack',
        description:
            '2 adults + up to 3 kids. Complete family experience with dedicated seating area, family-friendly food, and supervised activities.',
        type: PassType.familyPack,
        price: 179.99,
        eventId: 'evt_main_001',
        eventName: 'DFC Fight Night: Clash of Champions',
        eventDate: now.add(const Duration(days: 30)),
        venue: 'DFC Arena, Las Vegas',
        includes: [
          '2 adult general admission tickets',
          'Up to 3 kids passes (ages 6-15)',
          'Family seating section',
          'Kids activity pack',
          'Family photo opportunity',
          'Healthy meal vouchers for kids',
        ],
        maxQuantity: 40,
        soldCount: 28,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      FightPass(
        id: 'pass_stream_1',
        name: 'DFC Stream Pass',
        description:
            'Watch the entire card live from home. Multi-camera, corner cam, real-time stats overlay. The couch ringside experience.',
        type: PassType.streaming,
        price: 19.99,
        eventId: 'evt_main_001',
        eventName: 'DFC Fight Night: Clash of Champions',
        eventDate: now.add(const Duration(days: 30)),
        includes: [
          'Full live stream (main card + prelims)',
          'Multi-camera angles',
          'Corner cam access',
          'Real-time stats overlay',
          'Post-fight replay access (30 days)',
          'Live chat with DFC community',
        ],
        soldCount: 1420,
        createdAt: now.subtract(const Duration(days: 28)),
      ),
    ]);
  }

  void _seedCampaigns() {
    final now = DateTime.now();
    _campaigns.addAll([
      FightCampaign(
        id: 'camp_sick_kids',
        title: 'Fighters for Kids',
        description:
            'Bringing fight night magic to sick children. Every donation sends a kid from hospital to the arena for a night they\'ll never forget. We partner with children\'s hospitals nationwide.',
        type: CampaignType.sickKids,
        organizer: 'DFC Foundation',
        goalAmount: 50000,
        raisedAmount: 28750,
        donorCount: 412,
        passesContributed: 234,
        startDate: now.subtract(const Duration(days: 90)),
        tags: ['kids', 'charity', 'hospitals', 'make-a-wish', 'fight night'],
        impactStatement:
            'Every \$50 sends a child + guardian to a live DFC event with VIP treatment',
      ),
      FightCampaign(
        id: 'camp_mental_health',
        title: 'Fight Your Demons',
        description:
            'Mental health awareness through combat sports. Funding free gym memberships, counseling partnerships, and community programs for those fighting their toughest battles inside.',
        type: CampaignType.mentalHealthAwareness,
        organizer: 'DFC Wellness Initiative',
        goalAmount: 30000,
        raisedAmount: 18200,
        donorCount: 287,
        startDate: now.subtract(const Duration(days: 60)),
        tags: ['mental health', 'awareness', 'gym access', 'counseling'],
        impactStatement:
            'Every \$25 funds a week of free gym access + one counseling session',
      ),
      FightCampaign(
        id: 'camp_veteran',
        title: 'Warriors Welcome Home',
        description:
            'Veterans have fought for us — now we fight for them. Free DFC gym access, fight passes, and peer support groups for veterans transitioning back to civilian life.',
        type: CampaignType.veteranSupport,
        organizer: 'DFC Veterans Program',
        goalAmount: 25000,
        raisedAmount: 12400,
        donorCount: 198,
        startDate: now.subtract(const Duration(days: 45)),
        tags: ['veterans', 'military', 'support', 'peer groups'],
        impactStatement:
            'Every \$30 gives a veteran a month of free training + community',
      ),
      FightCampaign(
        id: 'camp_youth',
        title: 'Young Fighters, Big Dreams',
        description:
            'Keeping kids off the streets and in the gym. Funding youth boxing programs, after-school training, and tournament entry fees for underprivileged young fighters.',
        type: CampaignType.youthTraining,
        organizer: 'DFC Youth Boxing',
        goalAmount: 20000,
        raisedAmount: 9800,
        donorCount: 156,
        startDate: now.subtract(const Duration(days: 30)),
        tags: ['youth', 'boxing', 'after-school', 'community'],
        impactStatement:
            'Every \$15 gives a young fighter a week of coaching + equipment',
      ),
      FightCampaign(
        id: 'camp_women',
        title: 'She Fights',
        description:
            'Breaking barriers for women in combat sports. Funding women-only training sessions, self-defense workshops, and tournament sponsorships. From survivors to champions.',
        type: CampaignType.womenInCombatSports,
        organizer: 'DFC Women\'s Initiative',
        goalAmount: 15000,
        raisedAmount: 7200,
        donorCount: 134,
        startDate: now.subtract(const Duration(days: 30)),
        tags: ['women', 'empowerment', 'self-defense', 'training'],
        impactStatement:
            'Every \$20 funds a women\'s self-defense workshop for 1 participant',
      ),
    ]);
  }

  void _seedDiscounts() {
    _discounts.addAll([
      FightDiscount(
        id: 'disc_1',
        code: 'DFC2026',
        type: DiscountType.promoCode,
        discountPercent: 15,
        maxUses: 500,
        usedCount: 123,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        description: 'DFC 2026 launch promo — 15% off all passes',
      ),
      FightDiscount(
        id: 'disc_2',
        code: 'EARLYBIRD',
        type: DiscountType.earlyBird,
        discountPercent: 20,
        maxUses: 200,
        usedCount: 89,
        expiresAt: DateTime.now().add(const Duration(days: 14)),
        description: 'Early bird special — 20% off when you book 2+ weeks out',
      ),
      const FightDiscount(
        id: 'disc_3',
        code: 'SQUAD5',
        type: DiscountType.groupDiscount,
        discountPercent: 25,
        description: 'Group discount — 25% off when buying 5+ tickets',
      ),
      const FightDiscount(
        id: 'disc_4',
        code: 'THANKYOU',
        type: DiscountType.military,
        discountPercent: 30,
        description:
            '30% off for active military & veterans — thank you for your service',
      ),
      const FightDiscount(
        id: 'disc_5',
        code: 'FIRSTRESPONDER',
        type: DiscountType.firstResponder,
        discountPercent: 25,
        description: '25% off for first responders — police, fire, EMS',
      ),
      const FightDiscount(
        id: 'disc_6',
        code: 'STUDENT',
        type: DiscountType.student,
        discountPercent: 20,
        description: '20% student discount with valid ID',
      ),
      const FightDiscount(
        id: 'disc_7',
        code: 'DFCMEMBER',
        type: DiscountType.dfcMember,
        discountPercent: 10,
        description: 'DFC Access Pass members always save 10%',
      ),
    ]);
  }

  void dispose() {
    _passController.close();
    _campaignController.close();
  }
}
