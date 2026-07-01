import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import '../services/ppv_service.dart';
import '../services/fight_item_service.dart';
import '../models/fight_item_model.dart';
import '../widgets/ppv_payment_sheet.dart';

/// PPV Store Screen - Browse and purchase PPV events
class PPVStoreScreen extends StatefulWidget {
  const PPVStoreScreen({super.key});

  @override
  State<PPVStoreScreen> createState() => _PPVStoreScreenState();
}

class _PPVStoreScreenState extends State<PPVStoreScreen>
    with SingleTickerProviderStateMixin {
  final PPVService _ppvService = PPVService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgPrimary,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textPrimary,
            size: 18,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignTokens.neonRed, DesignTokens.neonMagenta],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PPV STORE',
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: DesignTokens.fontSizeTitle,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DesignTokens.neonCyan,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          labelColor: DesignTokens.neonCyan,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.sensors, size: 16), text: 'Live'),
            Tab(icon: Icon(Icons.schedule, size: 16), text: 'Upcoming'),
            Tab(icon: Icon(Icons.video_library, size: 16), text: 'Available'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveEvents(),
          _buildUpcomingEvents(),
          _buildAvailableEvents(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: DesignTokens.neonCyan.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              icon,
              color: DesignTokens.neonCyan.withValues(alpha: 0.4),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveEvents() {
    return StreamBuilder<List<PPVEvent>>(
      stream: _ppvService.getLivePPVEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No live events right now', Icons.sensors);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildPPVCard(snapshot.data![index], isLive: true);
          },
        );
      },
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<List<PPVEvent>>(
      stream: _ppvService.getUpcomingPPVEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No upcoming events', Icons.event_busy);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLegendsComingUpCard(),
            const SizedBox(height: 12),
            ...snapshot.data!.map(_buildPPVCard),
          ],
        );
      },
    );
  }

  Widget _buildLegendsComingUpCard() {
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFF0E1728),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: DesignTokens.neonCyan, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ULTIMATE LEGENDS - COMING UP',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fri 24 Apr 2026  |  Fight Night  |  Boxing & K1 Kickboxing',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 10),
            const Text(
              'Jordan Roesler vs Conor Wallace',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'WBC Silver Australian Title — 10 Rounds',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tribute: TEAM ULTIMATE, John Scida and Lyn. Real mentorship, real opportunity, real fight-family leadership.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Legends campaign queued in Social Command.',
                        ),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.neonCyan,
                      side: const BorderSide(color: DesignTokens.neonCyan),
                    ),
                    child: const Text('Push Campaign'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Set PPV pricing split: singles + main event + full card.',
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.neonCyan,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Set Pricing'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('USA relay launch queued for this event.'),
                  ),
                ),
                icon: const Icon(Icons.public, size: 16),
                label: const Text('Launch USA Relay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A2237),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DesignTokens.neonCyan),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOWN UNDER DOMINO EFFECT',
                    style: TextStyle(
                      color: DesignTokens.neonCyan,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Step 1: U.S. audience watches Australian fights.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    'Step 2: Shares increase global social proof.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  Text(
                    'Step 3: Bigger buys, sponsors and fighter earnings.',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _DominoMetricChip(label: 'US Watch Parties', value: '180'),
                _DominoMetricChip(label: 'Cross-Ocean Shares', value: '3.4K'),
                _DominoMetricChip(label: 'PPV Uplift', value: '+28%'),
                _DominoMetricChip(label: 'Sponsor Interest', value: 'High'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableEvents() {
    return StreamBuilder<List<PPVEvent>>(
      stream: _ppvService.getAvailablePPVEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: DesignTokens.neonCyan),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No past events available',
            Icons.inventory_2_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildPPVCard(snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildPPVCard(PPVEvent event, {bool isLive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        border: Border.all(
          color: isLive
              ? DesignTokens.neonRed.withValues(alpha: 0.6)
              : DesignTokens.neonCyan.withValues(alpha: 0.12),
        ),
        boxShadow: isLive
            ? [
                BoxShadow(
                  color: DesignTokens.neonRed.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () => _showPPVDetails(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                event.posterUrl != null
                    ? Image(
                        image: ImageAssets.resolveImage(event.posterUrl!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }

                          return Container(
                            height: 200,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFF1A0A2E), Colors.black],
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: DesignTokens.neonCyan,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPosterFallback(),
                      )
                    : _buildPosterFallback(),
                // Gradient overlay for text legibility
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                if (isLive)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonRed,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.neonRed.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: DesignTokens.neonCyan.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.eventDate),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '\$${event.standardPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: DesignTokens.neonCyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.purchaseCount} purchases',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosterFallback() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0A2E), Colors.black],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.3,
          child: Image.asset(
            ImageAssets.dfcBrandedPlaceholder,
            width: 64,
            height: 64,
          ),
        ),
      ),
    );
  }

  void _showPPVDetails(PPVEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PPVDetailsSheet(event: event),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

/// PPV Details Bottom Sheet
class PPVDetailsSheet extends StatefulWidget {
  final PPVEvent event;

  const PPVDetailsSheet({super.key, required this.event});

  @override
  State<PPVDetailsSheet> createState() => _PPVDetailsSheetState();
}

class _PPVDetailsSheetState extends State<PPVDetailsSheet> {
  final PPVService _ppvService = PPVService();
  final FightItemService _fightItemService = FightItemService();
  bool _isLoading = false;
  bool _hasAccess = false;
  String? _purchasingFightId;

  bool get _checkoutSandboxEnabled =>
      AppConstants.webDemoMode ||
      AppConstants.syntheticContentEnabled ||
      AppConstants.guestMode;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final hasAccess = await _ppvService.hasAccess(userId, widget.event.id);
    setState(() {
      _hasAccess = hasAccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: DesignTokens.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: DesignTokens.neonCyan.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: DesignTokens.neonCyan.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by ${widget.event.promotion ?? ''}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 24),

                  _buildPromoterSpotlight(),
                  const SizedBox(height: 18),

                  // Event details
                  _buildDetailRow(
                    Icons.calendar_today,
                    _formatDate(widget.event.eventDate),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.people,
                    '${widget.event.purchaseCount} purchases',
                  ),
                  const SizedBox(height: 24),

                  // Description
                  Text(
                    widget.event.description ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[300],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Price and purchase button
                  if (!_hasAccess) ...[
                    _buildIndiaGatewayPricing(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Price:', style: TextStyle(fontSize: 18)),
                        const Spacer(),
                        Text(
                          '\$${widget.event.standardPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: DesignTokens.neonCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Approx India full-card: ${_formatInr(widget.event.standardPrice)}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _purchaseEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.neonCyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Purchase PPV',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/ppv/notifications/${widget.event.id}',
                        ),
                        icon: const Icon(Icons.notifications),
                        label: const Text('🔔 Never Miss Action'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: DesignTokens.neonCyan,
                          side: const BorderSide(
                            color: DesignTokens.neonCyan,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text(
                            'You own this event',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _watchEvent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.neonCyan,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Watch Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSingleFightOffers(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '/ppv/notifications/${widget.event.id}',
                        ),
                        icon: const Icon(Icons.notifications_active),
                        label: const Text('Alert Preferences'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: DesignTokens.neonCyan.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPromoterSpotlight() {
    final name = widget.event.title.toLowerCase();
    final promoter = (widget.event.promotion ?? '').toLowerCase();
    final isShowLegends =
        name.contains('legend') ||
        name.contains('show') ||
        name.contains('ultimate legends');
    final isJoseph =
        promoter.contains('joseph') ||
        name.contains('joseph') ||
        promoter.contains('joe');

    if (!isShowLegends && !isJoseph) {
      return const SizedBox.shrink();
    }

    final label = isJoseph
        ? 'ULTIMATE LEGENDS SPOTLIGHT'
        : 'SHOW LEGENDS SPOTLIGHT';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFF12243A), Color(0xFF1B1429)],
        ),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Launch angle: legacy + discipline + healthy community values. Push singles first, then upsell main event and full card.',
            style: TextStyle(
              color: Colors.grey[200],
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndiaGatewayPricing() {
    final mainEventUsd = (widget.event.standardPrice * 0.45).clamp(
      2.49,
      widget.event.standardPrice,
    );
    final singleFightUsd = (widget.event.standardPrice * 0.22).clamp(
      1.29,
      mainEventUsd,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2230),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'India Gateway Pricing',
            style: TextStyle(
              color: DesignTokens.neonCyan,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Singles + Main Event split keeps entry affordable and lifts total conversions.',
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          _priceLine('Single Fight', singleFightUsd),
          _priceLine('Main Event Only', mainEventUsd),
          _priceLine('Full Card', widget.event.standardPrice),
        ],
      ),
    );
  }

  Widget _priceLine(String label, double usdPrice) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[200], fontSize: 12)),
          const Spacer(),
          Text(
            '\$${usdPrice.toStringAsFixed(2)} / ${_formatInr(usdPrice)}',
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleFightOffers() {
    return StreamBuilder<List<FightItem>>(
      stream: _fightItemService.getEventFights(widget.event.id),
      builder: (context, snapshot) {
        final fights = snapshot.data ?? const <FightItem>[];
        if (fights.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              'Singles will appear here once promoter publishes fight-level offers.',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          );
        }

        final topFights = fights.take(4).toList();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Single-Fight Secure Access',
                style: TextStyle(
                  color: DesignTokens.neonCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hosted checkout with automatic entitlement unlock after confirmation.',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              const SizedBox(height: 10),
              ...topFights.map(_buildFightOfferTile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFightOfferTile(FightItem fight) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FutureBuilder<bool>(
        future: userId == null
            ? Future<bool>.value(false)
            : _fightItemService.hasFightAccess(userId, fight.id),
        builder: (context, accessSnap) {
          final hasFightAccess = accessSnap.data ?? false;
          final purchasing = _purchasingFightId == fight.id;
          final singleFightCheckoutEnabled = _checkoutSandboxEnabled;

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fight.fightNumber}: ${fight.fighter1Name} vs ${fight.fighter2Name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${fight.price.toStringAsFixed(2)} / ${_formatInr(fight.price)}',
                      style: const TextStyle(
                        color: DesignTokens.neonCyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed:
                      (hasFightAccess ||
                          purchasing ||
                          !singleFightCheckoutEnabled)
                      ? null
                      : () => _purchaseFight(fight.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: purchasing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          hasFightAccess
                              ? 'Owned'
                              : singleFightCheckoutEnabled
                              ? 'Secure Checkout'
                              : 'Event Checkout',
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _purchaseEvent() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PPVPaymentSheet(
          event: widget.event,
          onPaymentConfirmed: (request) async {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }

            final messenger = ScaffoldMessenger.of(context);
            try {
              if (mounted) {
                if (_checkoutSandboxEnabled &&
                    request.externalPaymentReference.startsWith('demo_')) {
                  setState(() {
                    _hasAccess = true;
                  });
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Demo access unlocked: ${request.purchaseTier.label}',
                      ),
                    ),
                  );
                } else {
                  await _checkAccess();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Checkout opened. Access unlocks automatically after payment confirmation.',
                      ),
                    ),
                  );
                }
              }
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Purchase failed: $e')),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            }
          },
        );
      },
    );
  }

  Future<void> _purchaseFight(String fightId) async {
    if (!_checkoutSandboxEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Single-fight secure checkout is being finalized. Use the event checkout for now.',
          ),
        ),
      );
      return;
    }

    setState(() => _purchasingFightId = fightId);
    try {
      await Future.delayed(const Duration(seconds: 1));
      await _fightItemService.purchaseFight(
        fightItemId: fightId,
        stripePaymentId: 'demo_fight_payment_id',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Single fight purchased successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fight purchase failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _purchasingFightId = null);
      }
    }
  }

  String _formatInr(double usdPrice) {
    const inrRate = 83.0;
    final inr = (usdPrice * inrRate).round();
    return 'INR $inr';
  }

  void _watchEvent() {
    // Navigate to video player
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening video player...')));
  }
}

class _DominoMetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _DominoMetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: DesignTokens.neonCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: DesignTokens.neonCyan,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
