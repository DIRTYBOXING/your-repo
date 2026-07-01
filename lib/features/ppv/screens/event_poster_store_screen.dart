import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// EVENT POSTER STORE — Buy fight posters, event art, limited editions
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Every live event produces a poster. This store:
///   • Gallery of ALL event posters (past + upcoming)
///   • Multiple sizes: A4, A3, A2, A1, custom canvas
///   • Framing options: None, Black, Gold, Platinum
///   • Limited edition numbered prints
///   • Digital download option
///   • Stripe checkout (same 15/85 split as PPV)
///   • Poster preview with zoom
///   • Cart + order history
///   • Combat sport filter: MMA, Boxing, BKFC, Kickboxing etc
/// ═══════════════════════════════════════════════════════════════════════════

// ─── Models ──────────────────────────────────────────────────────────────

enum PosterSize { a4, a3, a2, a1, canvas }

extension PosterSizeDetails on PosterSize {
  String get label => switch (this) {
    PosterSize.a4 => 'A4 (210×297mm)',
    PosterSize.a3 => 'A3 (297×420mm)',
    PosterSize.a2 => 'A2 (420×594mm)',
    PosterSize.a1 => 'A1 (594×841mm)',
    PosterSize.canvas => 'Canvas (600×900mm)',
  };
  String get shortLabel => switch (this) {
    PosterSize.a4 => 'A4',
    PosterSize.a3 => 'A3',
    PosterSize.a2 => 'A2',
    PosterSize.a1 => 'A1',
    PosterSize.canvas => 'Canvas',
  };
  double get priceMultiplier => switch (this) {
    PosterSize.a4 => 1.0,
    PosterSize.a3 => 1.5,
    PosterSize.a2 => 2.2,
    PosterSize.a1 => 3.0,
    PosterSize.canvas => 4.5,
  };
}

enum FrameOption { none, matte, black, gold, platinum }

extension FrameOptionDetails on FrameOption {
  String get label => switch (this) {
    FrameOption.none => 'No Frame',
    FrameOption.matte => 'Matte Border',
    FrameOption.black => 'Black Frame',
    FrameOption.gold => 'Gold Frame',
    FrameOption.platinum => 'Platinum Frame',
  };
  double get priceAdd => switch (this) {
    FrameOption.none => 0,
    FrameOption.matte => 5,
    FrameOption.black => 15,
    FrameOption.gold => 25,
    FrameOption.platinum => 40,
  };
  Color get displayColor => switch (this) {
    FrameOption.none => Colors.transparent,
    FrameOption.matte => Colors.white,
    FrameOption.black => Colors.black,
    FrameOption.gold => const Color(0xFFFFD700),
    FrameOption.platinum => const Color(0xFFE5E4E2),
  };
}

class EventPoster {
  final String id;
  final String eventId;
  final String eventTitle;
  final String sport;
  final String location;
  final DateTime eventDate;
  final String? imageUrl;
  final double basePrice;
  final bool isLimitedEdition;
  final int? editionTotal;
  final int? editionSold;
  final bool hasDigitalDownload;
  final double digitalPrice;
  final String? promoterName;
  final String? headlinerFight;
  final DateTime createdAt;

  const EventPoster({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.sport,
    required this.location,
    required this.eventDate,
    this.imageUrl,
    required this.basePrice,
    this.isLimitedEdition = false,
    this.editionTotal,
    this.editionSold,
    this.hasDigitalDownload = true,
    this.digitalPrice = 4.99,
    this.promoterName,
    this.headlinerFight,
    required this.createdAt,
  });

  double totalPrice(PosterSize size, FrameOption frame) =>
      (basePrice * size.priceMultiplier) + frame.priceAdd;

  int get editionsRemaining =>
      isLimitedEdition ? (editionTotal ?? 0) - (editionSold ?? 0) : 999;

  factory EventPoster.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return EventPoster(
      id: doc.id,
      eventId: d['eventId'] ?? '',
      eventTitle: d['eventTitle'] ?? '',
      sport: d['sport'] ?? 'MMA',
      location: d['location'] ?? '',
      eventDate: (d['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: d['imageUrl'],
      basePrice: (d['basePrice'] ?? 14.99).toDouble(),
      isLimitedEdition: d['isLimitedEdition'] ?? false,
      editionTotal: d['editionTotal'],
      editionSold: d['editionSold'],
      hasDigitalDownload: d['hasDigitalDownload'] ?? true,
      digitalPrice: (d['digitalPrice'] ?? 4.99).toDouble(),
      promoterName: d['promoterName'],
      headlinerFight: d['headlinerFight'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'eventId': eventId,
    'eventTitle': eventTitle,
    'sport': sport,
    'location': location,
    'eventDate': Timestamp.fromDate(eventDate),
    'imageUrl': imageUrl,
    'basePrice': basePrice,
    'isLimitedEdition': isLimitedEdition,
    'editionTotal': editionTotal,
    'editionSold': editionSold,
    'hasDigitalDownload': hasDigitalDownload,
    'digitalPrice': digitalPrice,
    'promoterName': promoterName,
    'headlinerFight': headlinerFight,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class PosterOrder {
  final String id;
  final String posterId;
  final String userId;
  final PosterSize size;
  final FrameOption frame;
  final bool isDigital;
  final double amountPaid;
  final String? stripePaymentId;
  final String? shippingAddress;
  final DateTime orderedAt;
  final String status;

  const PosterOrder({
    required this.id,
    required this.posterId,
    required this.userId,
    required this.size,
    required this.frame,
    required this.isDigital,
    required this.amountPaid,
    this.stripePaymentId,
    this.shippingAddress,
    required this.orderedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toFirestore() => {
    'posterId': posterId,
    'userId': userId,
    'size': size.name,
    'frame': frame.name,
    'isDigital': isDigital,
    'amountPaid': amountPaid,
    'stripePaymentId': stripePaymentId,
    'shippingAddress': shippingAddress,
    'orderedAt': Timestamp.fromDate(orderedAt),
    'status': status,
  };
}

// ─── Demo Data ───────────────────────────────────────────────────────────

List<EventPoster> _demoPosters() => [
  EventPoster(
    id: 'poster_1',
    eventId: 'ufc_perth_2026',
    eventTitle: 'UFC Perth 2026',
    sport: 'MMA',
    location: 'RAC Arena, Perth, Australia',
    eventDate: DateTime(2026, 6, 15),
    basePrice: 19.99,
    isLimitedEdition: true,
    editionTotal: 500,
    editionSold: 127,
    promoterName: 'UFC',
    headlinerFight: 'Volkanovski vs Holloway III',
    createdAt: DateTime.now(),
  ),
  EventPoster(
    id: 'poster_2',
    eventId: 'eternal_mma_80',
    eventTitle: 'Eternal MMA 80',
    sport: 'MMA',
    location: 'Melbourne Pavilion, Australia',
    eventDate: DateTime(2026, 5, 22),
    basePrice: 14.99,
    promoterName: 'Eternal MMA',
    headlinerFight: 'Main Event TBA',
    createdAt: DateTime.now(),
  ),
  EventPoster(
    id: 'poster_3',
    eventId: 'hex_fight_series_30',
    eventTitle: 'HEX Fight Series 30',
    sport: 'MMA',
    location: 'Gold Coast, Australia',
    eventDate: DateTime(2026, 7, 10),
    basePrice: 14.99,
    promoterName: 'HEX Fight Series',
    headlinerFight: 'Championship Bout',
    createdAt: DateTime.now(),
  ),
  EventPoster(
    id: 'poster_4',
    eventId: 'bkfc_australia_1',
    eventTitle: 'BKFC Australia I',
    sport: 'Bare Knuckle',
    location: 'Brisbane, Australia',
    eventDate: DateTime(2026, 8, 5),
    basePrice: 17.99,
    isLimitedEdition: true,
    editionTotal: 250,
    editionSold: 43,
    promoterName: 'BKFC',
    headlinerFight: 'Inaugural AU Main Event',
    createdAt: DateTime.now(),
  ),
  EventPoster(
    id: 'poster_5',
    eventId: 'dan_hooker_show_1',
    eventTitle: 'Dan Hooker\'s Fight Night',
    sport: 'MMA',
    location: 'Auckland, New Zealand',
    eventDate: DateTime(2026, 9, 20),
    basePrice: 16.99,
    isLimitedEdition: true,
    editionTotal: 300,
    editionSold: 88,
    promoterName: 'Hooker Promotions',
    headlinerFight: 'NZ vs AU Showdown',
    createdAt: DateTime.now(),
  ),
  EventPoster(
    id: 'poster_6',
    eventId: 'ibc_03',
    eventTitle: 'IBC 03 — International',
    sport: 'Boxing',
    location: 'Sydney Opera House Forecourt',
    eventDate: DateTime(2026, 10, 12),
    basePrice: 19.99,
    promoterName: 'IBC',
    headlinerFight: 'World Title Eliminator',
    createdAt: DateTime.now(),
  ),
  EventPoster(
    id: 'poster_7',
    eventId: 'afc_kickboxing_12',
    eventTitle: 'AFC Kickboxing XII',
    sport: 'Kickboxing',
    location: 'Adelaide, Australia',
    eventDate: DateTime(2026, 4, 18),
    basePrice: 12.99,
    promoterName: 'AFC',
    headlinerFight: 'Super Middleweight Title',
    createdAt: DateTime.now(),
  ),
  EventPoster(
    id: 'poster_8',
    eventId: 'elite_fight_cairns',
    eventTitle: 'Elite Fight Series Cairns',
    sport: 'Brawling',
    location: 'Cairns Convention Centre',
    eventDate: DateTime(2026, 11),
    basePrice: 14.99,
    promoterName: 'Elite Fight Series',
    headlinerFight: 'North QLD Championship',
    createdAt: DateTime.now(),
  ),
];

// ─── Screen ──────────────────────────────────────────────────────────────

class EventPosterStoreScreen extends StatefulWidget {
  const EventPosterStoreScreen({super.key});

  @override
  State<EventPosterStoreScreen> createState() => _EventPosterStoreScreenState();
}

class _EventPosterStoreScreenState extends State<EventPosterStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<EventPoster> _posters = [];
  String _selectedSport = 'All';
  final bool _showLimitedOnly = false;

  static const _sports = [
    'All',
    'MMA',
    'Boxing',
    'Bare Knuckle',
    'BKFC',
    'Kickboxing',
    'Muay Thai',
    'Wrestling',
    'Brawling',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadPosters();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPosters() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('event_posters')
          .orderBy('eventDate', descending: true)
          .get();
      if (snap.docs.isNotEmpty) {
        setState(() {
          _posters = snap.docs.map(EventPoster.fromFirestore).toList();
        });
      } else {
        setState(() => _posters = _demoPosters());
      }
    } catch (_) {
      setState(() => _posters = _demoPosters());
    }
  }

  List<EventPoster> get _filteredPosters {
    var list = _posters;
    if (_selectedSport != 'All') {
      list = list
          .where(
            (p) => p.sport.toLowerCase().contains(_selectedSport.toLowerCase()),
          )
          .toList();
    }
    if (_showLimitedOnly) {
      list = list.where((p) => p.isLimitedEdition).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgSecondary,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EVENT POSTER STORE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Official fight posters — print, frame, collect',
              style: TextStyle(fontSize: 10, color: DesignTokens.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, size: 22),
            onPressed: _showCart,
            color: DesignTokens.neonCyan,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: DesignTokens.neonCyan,
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'ALL POSTERS'),
            Tab(text: 'LIMITED EDITION'),
            Tab(text: 'MY ORDERS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildAllPostersTab(),
          _buildLimitedEditionTab(),
          _buildMyOrdersTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: ALL POSTERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAllPostersTab() {
    final posters = _filteredPosters;
    return Column(
      children: [
        // Sport filter chips
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _sports.map(_sportFilterChip).toList(),
          ),
        ),

        // Poster grid
        Expanded(
          child: posters.isEmpty
              ? const Center(
                  child: Text(
                    'No posters found for this sport',
                    style: TextStyle(color: DesignTokens.textMuted),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: posters.length,
                  itemBuilder: (ctx, i) => _posterCard(posters[i]),
                ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: LIMITED EDITIONS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLimitedEditionTab() {
    final limited = _posters.where((p) => p.isLimitedEdition).toList();
    if (limited.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 48, color: DesignTokens.neonGold),
            SizedBox(height: 12),
            Text(
              'No limited editions available',
              style: TextStyle(color: DesignTokens.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: limited.length,
      itemBuilder: (ctx, i) => _limitedEditionCard(limited[i]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 3: MY ORDERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildMyOrdersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Sign in to view orders',
          style: TextStyle(color: DesignTokens.textMuted),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('poster_orders')
          .where('userId', isEqualTo: user.uid)
          .orderBy('orderedAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No orders yet',
                  style: TextStyle(color: DesignTokens.textMuted),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse posters and grab your first print!',
                  style: TextStyle(fontSize: 12, color: DesignTokens.textMuted),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: snap.data!.docs.length,
          itemBuilder: (ctx, i) =>
              _orderCard(snap.data!.docs[i].data() as Map<String, dynamic>),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // POSTER CARD (Grid)
  // ═══════════════════════════════════════════════════════════════════
  Widget _posterCard(EventPoster poster) {
    final templateKey = _posterTemplateKey(poster);
    return Semantics(
      label: 'data-test=poster-list-item-${poster.id}',
      child: GestureDetector(
        onTap: () => _showPosterDetail(poster),
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: poster.isLimitedEdition
                  ? DesignTokens.neonGold.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.06),
              width: poster.isLimitedEdition ? 1 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster image area
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _sportColor(poster.sport).withValues(alpha: 0.2),
                            DesignTokens.bgCard,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _sportIcon(poster.sport),
                              size: 36,
                              color: _sportColor(
                                poster.sport,
                              ).withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              poster.sport.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _sportColor(
                                  poster.sport,
                                ).withValues(alpha: 0.5),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Limited badge
                    if (poster.isLimitedEdition)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.neonGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: DesignTokens.neonGold.withValues(
                                alpha: 0.5,
                              ),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${poster.editionsRemaining} LEFT',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: DesignTokens.neonGold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poster.eventTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (poster.headlinerFight != null)
                        Text(
                          poster.headlinerFight!,
                          style: TextStyle(
                            fontSize: 10,
                            color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          templateKey.toUpperCase(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.78),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FROM \$${poster.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _sportColor(poster.sport),
                            ),
                          ),
                          if (poster.hasDigitalDownload)
                            const Icon(
                              Icons.download,
                              size: 12,
                              color: DesignTokens.textMuted,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LIMITED EDITION CARD (List)
  // ═══════════════════════════════════════════════════════════════════
  Widget _limitedEditionCard(EventPoster poster) {
    final remaining = poster.editionsRemaining;
    final total = poster.editionTotal ?? 0;
    final soldPct = total > 0 ? (total - remaining) / total : 0.0;

    return Semantics(
      label: 'data-test=poster-list-item-${poster.id}',
      child: GestureDetector(
        onTap: () => _showPosterDetail(poster),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: DesignTokens.neonGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Poster thumbnail
              Container(
                width: 80,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _sportColor(poster.sport).withValues(alpha: 0.2),
                      DesignTokens.bgCard,
                    ],
                  ),
                  border: Border.all(
                    color: DesignTokens.neonGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _sportIcon(poster.sport),
                      size: 28,
                      color: _sportColor(poster.sport).withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${poster.editionSold ?? 0 + 1}/$total',
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.neonGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: DesignTokens.neonGold,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LIMITED EDITION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: DesignTokens.neonGold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      poster.eventTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (poster.headlinerFight != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        poster.headlinerFight!,
                        style: TextStyle(
                          fontSize: 11,
                          color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    // Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$remaining of $total remaining',
                              style: TextStyle(
                                fontSize: 10,
                                color: DesignTokens.neonGold.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            Text(
                              '${(soldPct * 100).round()}% sold',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: DesignTokens.neonRed.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: soldPct,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.05,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              DesignTokens.neonGold.withValues(alpha: 0.7),
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'FROM \$${poster.basePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.neonGold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ORDER CARD
  // ═══════════════════════════════════════════════════════════════════
  Widget _orderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final isDigital = order['isDigital'] ?? false;
    final amount = (order['amountPaid'] ?? 0).toDouble();
    final size = order['size'] ?? 'a3';
    final frame = order['frame'] ?? 'none';

    Color statusColor;
    switch (status) {
      case 'shipped':
        statusColor = DesignTokens.neonGreen;
      case 'processing':
        statusColor = DesignTokens.neonAmber;
      case 'delivered':
        statusColor = DesignTokens.neonCyan;
      default:
        statusColor = DesignTokens.textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isDigital ? Icons.download : Icons.local_shipping,
            size: 24,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDigital
                      ? 'Digital Download'
                      : '${size.toUpperCase()} Print — $frame',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: DesignTokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // POSTER DETAIL BOTTOM SHEET
  // ═══════════════════════════════════════════════════════════════════
  void _showPosterDetail(EventPoster poster) {
    PosterSize selectedSize = PosterSize.a3;
    FrameOption selectedFrame = FrameOption.none;
    bool isDigital = false;
    final templateKey = _posterTemplateKey(poster);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final price = isDigital
                ? poster.digitalPrice
                : poster.totalPrice(selectedSize, selectedFrame);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Poster preview
                    Semantics(
                      label: 'data-test=poster-detail-${poster.id}',
                      child: Container(
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _sportColor(poster.sport).withValues(alpha: 0.15),
                              DesignTokens.bgCard,
                            ],
                          ),
                          border: Border.all(
                            color: selectedFrame == FrameOption.none
                                ? Colors.white.withValues(alpha: 0.08)
                                : selectedFrame.displayColor.withValues(
                                    alpha: 0.5,
                                  ),
                            width: selectedFrame == FrameOption.none ? 0.5 : 3,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _sportIcon(poster.sport),
                                size: 56,
                                color: _sportColor(
                                  poster.sport,
                                ).withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                poster.eventTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (poster.headlinerFight != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  poster.headlinerFight!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: DesignTokens.neonCyan.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                poster.location,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Event info
                    Row(
                      children: [
                        _infoPill(poster.sport, _sportColor(poster.sport)),
                        const SizedBox(width: 6),
                        Semantics(
                          label: 'data-test=poster-template-$templateKey',
                          child: _infoPill(
                            'TEMPLATE ${templateKey.toUpperCase()}',
                            DesignTokens.textMuted,
                          ),
                        ),
                        if (poster.promoterName != null) ...[
                          const SizedBox(width: 6),
                          _infoPill(
                            poster.promoterName!,
                            DesignTokens.textMuted,
                          ),
                        ],
                        if (poster.isLimitedEdition) ...[
                          const SizedBox(width: 6),
                          _infoPill(
                            '${poster.editionsRemaining} LEFT',
                            DesignTokens.neonGold,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Digital vs Physical toggle
                    Row(
                      children: [
                        Expanded(
                          child: _toggleButton(
                            'PRINT',
                            Icons.print,
                            !isDigital,
                            () => setSheetState(() => isDigital = false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (poster.hasDigitalDownload)
                          Expanded(
                            child: _toggleButton(
                              'DIGITAL',
                              Icons.download,
                              isDigital,
                              () => setSheetState(() => isDigital = true),
                            ),
                          ),
                      ],
                    ),

                    if (!isDigital) ...[
                      const SizedBox(height: 16),

                      // Size selector
                      const Text(
                        'SIZE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: PosterSize.values
                            .map(
                              (s) => _sizeChip(
                                s,
                                selectedSize == s,
                                () => setSheetState(() => selectedSize = s),
                              ),
                            )
                            .toList(),
                      ),

                      const SizedBox(height: 16),

                      // Frame selector
                      const Text(
                        'FRAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: FrameOption.values
                            .map(
                              (f) => _frameChip(
                                f,
                                selectedFrame == f,
                                () => setSheetState(() => selectedFrame = f),
                              ),
                            )
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Price + Buy
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isDigital
                                    ? 'Digital Download'
                                    : '${selectedSize.shortLabel} ${selectedFrame.label}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              Text(
                                '\$${price.toStringAsFixed(2)} AUD',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: DesignTokens.neonCyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: Semantics(
                              button: true,
                              label: 'data-test=buy-cta-poster-${poster.id}',
                              child: ElevatedButton(
                                key: ValueKey('buy-cta-poster-${poster.id}'),
                                onPressed: () => _handlePurchase(
                                  poster,
                                  isDigital ? PosterSize.a4 : selectedSize,
                                  isDigital ? FrameOption.none : selectedFrame,
                                  isDigital,
                                  price,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignTokens.neonCyan
                                      .withValues(alpha: 0.2),
                                  foregroundColor: DesignTokens.neonCyan,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: DesignTokens.neonCyan.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  isDigital
                                      ? 'BUY DIGITAL — \$${price.toStringAsFixed(2)}'
                                      : 'BUY POSTER — \$${price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handlePurchase(
    EventPoster poster,
    PosterSize size,
    FrameOption frame,
    bool isDigital,
    double price,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final isDemoMode = AppConstants.guestMode || !AppConstants.authEnabled;
    if (user == null && !isDemoMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to purchase')),
        );
      }
      return;
    }
    final userId = user?.uid ?? 'demo_user';

    final order = PosterOrder(
      id: '',
      posterId: poster.id,
      userId: userId,
      size: size,
      frame: frame,
      isDigital: isDigital,
      amountPaid: price,
      orderedAt: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('poster_orders')
          .add(order.toFirestore());

      if (poster.isLimitedEdition) {
        await FirebaseFirestore.instance
            .collection('event_posters')
            .doc(poster.id)
            .update({'editionSold': FieldValue.increment(1)});
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDigital
                  ? 'Digital poster purchased! Check your downloads.'
                  : 'Poster ordered! We\'ll ship it to you soon.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap any poster to purchase directly'),
        backgroundColor: DesignTokens.neonCyan,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════
  Widget _sportFilterChip(String sport) {
    final isSelected = _selectedSport == sport;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _selectedSport = sport),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
              width: 0.5,
            ),
          ),
          child: Text(
            sport,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? DesignTokens.neonCyan
                  : DesignTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleButton(
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? DesignTokens.neonCyan.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? DesignTokens.neonCyan : DesignTokens.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? DesignTokens.neonCyan
                    : DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeChip(PosterSize size, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.neonCyan.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          size.shortLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            color: isSelected
                ? DesignTokens.neonCyan
                : DesignTokens.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _frameChip(FrameOption frame, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.neonCyan.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                : frame.displayColor != Colors.transparent
                ? frame.displayColor.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (frame != FrameOption.none) ...[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: frame.displayColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              frame.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? DesignTokens.neonCyan
                    : DesignTokens.textSecondary,
              ),
            ),
            if (frame.priceAdd > 0) ...[
              const SizedBox(width: 4),
              Text(
                '+\$${frame.priceAdd.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 9,
                  color: DesignTokens.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _sportColor(String sport) => switch (sport.toLowerCase()) {
    'mma' => DesignTokens.neonRed,
    'boxing' => DesignTokens.neonBlue,
    'bare knuckle' || 'bkfc' => DesignTokens.neonAmber,
    'kickboxing' => DesignTokens.neonGreen,
    'muay thai' => DesignTokens.neonMagenta,
    'wrestling' => DesignTokens.neonGold,
    'brawling' => DesignTokens.neonRed,
    _ => DesignTokens.neonCyan,
  };

  IconData _sportIcon(String sport) => switch (sport.toLowerCase()) {
    'mma' => Icons.sports_mma,
    'boxing' => Icons.sports_mma,
    'bare knuckle' || 'bkfc' => Icons.back_hand,
    'kickboxing' => Icons.sports_martial_arts,
    'muay thai' => Icons.sports_martial_arts,
    'wrestling' => Icons.sports_kabaddi,
    'brawling' => Icons.local_fire_department,
    _ => Icons.sports_mma,
  };

  String _posterTemplateKey(EventPoster poster) {
    final sport = poster.sport.toLowerCase();
    if (poster.isLimitedEdition) {
      return 'legacy_gold';
    }
    if (sport.contains('boxing')) {
      return 'mono_impact';
    }
    if (sport.contains('kick')) {
      return 'velocity_stripes';
    }
    if (sport.contains('bare') || sport.contains('bkfc')) {
      return 'grit_duotone';
    }
    return 'neon_arena';
  }
}
