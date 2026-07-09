import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/models/ppv_model.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/dfc_poster_frame.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC PPV EVENT CARD — Kayo / DAZN / ESPN+ Quality Event Card
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Premium card widget for PPV events. Two variants:
///   • DFCPPVEventCard.featured() — Large hero card (for carousel top slot)
///   • DFCPPVEventCard.standard() — Compact list card
///
/// Matches Kayo Sports event cards:
///   • Large poster image with gradient overlay
///   • LIVE badge (pulsing red)
///   • Sport category pill
///   • Event title + subtitle (fighter matchup)
///   • Price + tier display
///   • Countdown timer
///   • Platform logos (DFC, Kayo, ESPN+)
/// ═══════════════════════════════════════════════════════════════════════════
class DFCPPVEventCard extends StatefulWidget {
  final PPVEvent event;
  final bool isFeatured;
  final VoidCallback? onTap;
  final int entranceIndex;

  const DFCPPVEventCard._({
    super.key,
    required this.event,
    required this.isFeatured,
    this.onTap,
    this.entranceIndex = 0,
  });

  factory DFCPPVEventCard.featured({
    Key? key,
    required PPVEvent event,
    VoidCallback? onTap,
    int entranceIndex = 0,
  }) => DFCPPVEventCard._(
    key: key,
    event: event,
    isFeatured: true,
    onTap: onTap,
    entranceIndex: entranceIndex,
  );

  factory DFCPPVEventCard.standard({
    Key? key,
    required PPVEvent event,
    VoidCallback? onTap,
    int entranceIndex = 0,
  }) => DFCPPVEventCard._(
    key: key,
    event: event,
    isFeatured: false,
    onTap: onTap,
    entranceIndex: entranceIndex,
  );

  @override
  State<DFCPPVEventCard> createState() => _DFCPPVEventCardState();
}

class _DFCPPVEventCardState extends State<DFCPPVEventCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  AnimationController? _liveCtrl;
  Animation<double>? _livePulse;

  PPVEvent get event => widget.event;
  bool get isFeatured => widget.isFeatured;

  @override
  void initState() {
    super.initState();
    // Staggered entrance: each card delayed by index * 80ms
    final delay = Duration(milliseconds: widget.entranceIndex * 80);
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeIn = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    Future.delayed(delay, () {
      if (mounted) _entranceCtrl.forward();
    });

    // Live badge pulse
    if (event.isLive) {
      _liveCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..repeat(reverse: true);
      _livePulse = Tween<double>(
        begin: 0.6,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _liveCtrl!, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _liveCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: isFeatured
            ? _buildFeaturedCard(context)
            : _buildStandardCard(context),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURED CARD — Large hero carousel card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFeaturedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          context.push('/ppv/event/${event.id}');
        }
      },
      child: Container(
        height: 320,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: event.isLive
                ? Colors.red.withValues(alpha: 0.6)
                : DesignTokens.neonCyan.withValues(alpha: 0.15),
            width: event.isLive ? 2 : 1,
          ),
          boxShadow: event.isLive
              ? [
                  // Outer glow
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.25),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  // Inner depth
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient (no external images)
              _buildPosterBackground(),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
              // Live glow animation overlay
              if (event.isLive)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 0.6),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeInOut,
                  onEnd: () {
                    // Loop animation
                    setState(() {});
                  },
                  builder: (context, value, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: value * 0.4),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: badges
                    Row(
                      children: [
                        if (event.isLive) _buildLiveBadge(),
                        if (event.isLive) const SizedBox(width: 8),
                        _buildStatusBadge(),
                        const Spacer(),
                        _buildPlatformLogos(),
                      ],
                    ),
                    const Spacer(),
                    // Bottom: event details
                    if (event.subtitle != null)
                      Text(
                        event.subtitle!,
                        style: const TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    if (event.subtitle != null) const SizedBox(height: 6),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // Social proof row: purchase count, trending, promoter
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPurchaseCountBadge(),
                        _buildTrendingBadge(),
                        _buildPromoterBadge(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Meta row: date, price, fight count
                    Row(
                      children: [
                        _buildMetaPill(
                          icon: Icons.calendar_today,
                          label: _formatDate(event.eventDate),
                        ),
                        const SizedBox(width: 8),
                        _buildMetaPill(
                          icon: Icons.sports_mma,
                          label: '${event.fightCard.length} Fights',
                        ),
                        const Spacer(),
                        _buildPriceTag(),
                      ],
                    ),
                    // Sponsors
                    if (event.sponsors.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildSponsorStrip(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STANDARD CARD — Compact list card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStandardCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (widget.onTap != null) {
          widget.onTap!();
        } else {
          context.push('/ppv/event/${event.id}');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: event.isLive
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: event.isLive ? 1.5 : 1,
          ),
          boxShadow: event.isLive
              ? [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Row(
          children: [
            // Left: poster thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
              child: SizedBox(
                width: 120,
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPosterBackground(),
                    // Live badge
                    if (event.isLive)
                      Positioned(top: 8, left: 8, child: _buildLiveBadge()),
                  ],
                ),
              ),
            ),
            // Right: details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status + Sport
                    Row(
                      children: [
                        _buildStatusBadge(compact: true),
                        const Spacer(),
                        _buildPlatformLogos(compact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (event.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.subtitle!,
                        style: TextStyle(
                          color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Social proof badges: compact row
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _buildPurchaseCountBadge(compact: true),
                        _buildTrendingBadge(compact: true),
                        _buildPromoterBadge(compact: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Bottom: date + price
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(event.eventDate),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.sports_mma,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.fightCard.length} Fights',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        _buildPriceTag(compact: true),
                      ],
                    ),
                    // Sponsors
                    if (event.sponsors.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildSponsorStrip(compact: true),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPosterBackground() {
    final palette = _eventPalette();
    final allowSyntheticPosters =
        AppConstants.webDemoMode || AppConstants.syntheticContentEnabled;

    final mappedPoster = allowSyntheticPosters
        ? ImageAssets.posterAssetForEventMetadata(
            eventId: event.eventId,
            title: event.title,
            promoter: event.promotion,
            eventDate: event.eventDate,
            streamUrl: event.streamUrl,
            ticketUrl: event.ticketUrl,
            preferThumb: !isFeatured,
          )
        : null;

    final eventPoster = event.posterUrl?.trim();
    final isRemotePoster =
        eventPoster != null &&
        (eventPoster.startsWith('http://') ||
            eventPoster.startsWith('https://'));

    final String? posterUrl;
    if (isRemotePoster) {
      posterUrl = eventPoster;
    } else if (allowSyntheticPosters &&
        ImageAssets.isGenericPosterAsset(eventPoster)) {
      posterUrl = mappedPoster;
    } else if (allowSyntheticPosters) {
      posterUrl = eventPoster;
    } else {
      posterUrl = null;
    }

    return DFCPosterFrame(
      imageUrl: posterUrl,
      borderRadius: BorderRadius.zero,
      fit: isFeatured ? BoxFit.cover : BoxFit.contain,
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.bg1, palette.bg2],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 34,
                  color: Colors.white.withValues(alpha: 0.42),
                ),
                const SizedBox(height: 10),
                Text(
                  'Official poster pending',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: isFeatured ? 15 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      loadingWidget: _buildPosterShimmer(),
      errorWidget: const SizedBox.shrink(),
    );
  }

  _EventPalette _eventPalette() {
    final haystack = [
      event.title,
      event.subtitle,
      event.promotion,
      event.sport,
    ].whereType<String>().join(' ').toLowerCase();

    if (haystack.contains('ufc')) {
      return const _EventPalette(
        bg1: Color(0xFF2D0A0A),
        bg2: Color(0xFF0A0E1A),
        accent: Color(0xFFD4AF37),
        icon: Icons.sports_mma,
      );
    }
    if (haystack.contains('bkfc') ||
        haystack.contains('bare knuckle') ||
        haystack.contains('brawl')) {
      return const _EventPalette(
        bg1: Color(0xFF1A0A0A),
        bg2: Color(0xFF0A0A1A),
        accent: Color(0xFFE53935),
        icon: Icons.sports_mma,
      );
    }
    if (haystack.contains('boxing') || haystack.contains('matchroom')) {
      return const _EventPalette(
        bg1: Color(0xFF1A1408),
        bg2: Color(0xFF090D14),
        accent: Color(0xFFFFB300),
        icon: Icons.workspace_premium,
      );
    }
    if (haystack.contains('one') ||
        haystack.contains('kickboxing') ||
        haystack.contains('muay thai')) {
      return const _EventPalette(
        bg1: Color(0xFF0B1220),
        bg2: Color(0xFF091018),
        accent: Color(0xFF00D1FF),
        icon: Icons.flash_on,
      );
    }
    return const _EventPalette(
      bg1: Color(0xFF0A1A2D),
      bg2: Color(0xFF0A0E1A),
      accent: DesignTokens.neonCyan,
      icon: Icons.sports_mma,
    );
  }

  Widget _buildLiveBadge() {
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.red.withValues(alpha: 0.8)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
          SizedBox(width: 6),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );

    if (_livePulse == null) {
      return badge;
    }

    return FadeTransition(opacity: _livePulse!, child: badge);
  }

  Widget _buildStatusBadge({bool compact = false}) {
    final (label, color) = switch (event.status) {
      PPVStatus.announced => ('ANNOUNCED', Colors.blueGrey),
      PPVStatus.presale => ('PRESALE', DesignTokens.neonAmber),
      PPVStatus.onSale => ('ON SALE', DesignTokens.neonGreen),
      PPVStatus.live => ('STREAMING', Colors.red),
      PPVStatus.replay => ('REPLAY', DesignTokens.neonCyan),
      PPVStatus.expired => ('ENDED', Colors.grey),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(compact ? 8 : 999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 9 : 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildPlatformLogos({bool compact = false}) {
    final platforms = event.streamPlatforms.isNotEmpty
        ? event.streamPlatforms.take(compact ? 2 : 3).toList()
        : <String>['DFC'];

    return Wrap(
      spacing: compact ? 4 : 6,
      runSpacing: 4,
      children: platforms.map((platform) {
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 5 : 8,
            vertical: compact ? 2 : 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            platform.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetaPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceTag({bool compact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonGreen.withValues(alpha: 0.2),
            DesignTokens.neonCyan.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        event.priceDisplay,
        style: TextStyle(
          color: DesignTokens.neonGreen,
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ── Sponsors Strip ──
  Widget _buildSponsorStrip({bool compact = false}) {
    final sponsors = event.sponsors.take(4).toList();
    return Row(
      children: [
        Text(
          'PRESENTED BY',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: compact ? 7 : 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        ...sponsors.map((s) {
          return Container(
            margin: const EdgeInsets.only(right: 6),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 8,
              vertical: compact ? 2 : 3,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              (s['name'] ?? '').toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: compact ? 7 : 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Social Proof Badges ──
  Widget _buildPurchaseCountBadge({bool compact = false}) {
    if (event.purchaseCount == null || event.purchaseCount == 0) {
      return const SizedBox.shrink();
    }

    final count = event.purchaseCount!;
    String label;
    if (count >= 1000) {
      label = '${(count / 1000).toStringAsFixed(1)}K bought';
    } else if (count >= 100) {
      label = '${count ~/ 100 * 100}+ bought';
    } else {
      label = '$count bought';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.neonGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: DesignTokens.neonGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people,
            size: compact ? 9 : 11,
            color: DesignTokens.neonGreen,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: DesignTokens.neonGreen,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingBadge({bool compact = false}) {
    // Event is trending if: live, high purchase count, or recent presale
    final isTrending =
        event.isLive ||
        (event.purchaseCount ?? 0) > 1000 ||
        (event.status == PPVStatus.presale &&
            DateTime.now().difference(event.presaleStart).inDays < 2);

    if (!isTrending) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.neonAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: DesignTokens.neonAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.trending_up,
            size: compact ? 9 : 11,
            color: DesignTokens.neonAmber,
          ),
          const SizedBox(width: 3),
          Text(
            'TRENDING',
            style: TextStyle(
              color: DesignTokens.neonAmber,
              fontSize: compact ? 8 : 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoterBadge({bool compact = false}) {
    final promoter = event.promotion.toUpperCase();
    if (promoter.isEmpty || promoter == 'DFC') return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: compact ? 9 : 11,
            color: Colors.purple.shade300,
          ),
          const SizedBox(width: 3),
          Text(
            promoter,
            style: TextStyle(
              color: Colors.purple.shade300,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) return DateFormat('MMM d').format(date);
    if (diff.inDays == 0) return 'TODAY';
    if (diff.inDays == 1) return 'TOMORROW';
    if (diff.inDays < 7) return DateFormat('EEEE').format(date).toUpperCase();
    return DateFormat('MMM d').format(date);
  }

  /// Shimmer placeholder while poster image loads
  Widget _buildPosterShimmer() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base shimmer sweep
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -1.0, end: 2.0),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.03),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                  stops: [
                    (value - 0.3).clamp(0.0, 1.0),
                    value.clamp(0.0, 1.0),
                    (value + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds),
                child: Container(color: Colors.white),
              );
            },
            onEnd: () {
              // Loop by rebuilding
              if (mounted) setState(() {});
            },
          ),
          // Content skeleton
          Center(
            child: Icon(
              Icons.sports_mma,
              size: isFeatured ? 48 : 28,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV EVENT CAROUSEL — Kayo-style horizontal scrolling featured events
/// ═══════════════════════════════════════════════════════════════════════════
class DFCPPVEventCarousel extends StatefulWidget {
  final List<PPVEvent> events;
  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAll;

  const DFCPPVEventCarousel({
    super.key,
    required this.events,
    this.title = 'Live & Upcoming',
    this.showSeeAll = true,
    this.onSeeAll,
  });

  @override
  State<DFCPPVEventCarousel> createState() => _DFCPPVEventCarouselState();
}

class _DFCPPVEventCarouselState extends State<DFCPPVEventCarousel> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              if (widget.showSeeAll)
                GestureDetector(
                  onTap: widget.onSeeAll,
                  child: const Row(
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: DesignTokens.neonCyan,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Carousel
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              return AnimatedScale(
                scale: index == _currentPage ? 1.0 : 0.95,
                duration: const Duration(milliseconds: 200),
                child: DFCPPVEventCard.featured(
                  event: widget.events[index],
                  entranceIndex: index,
                ),
              );
            },
          ),
        ),
        // Page indicators
        if (widget.events.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.events.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? DesignTokens.neonCyan
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class _EventPalette {
  final Color bg1;
  final Color bg2;
  final Color accent;
  final IconData icon;
  const _EventPalette({
    required this.bg1,
    required this.bg2,
    required this.accent,
    required this.icon,
  });
}
