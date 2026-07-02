import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/adrenaline_theme.dart';
import '../../../shared/models/ppv_model.dart';
import '../../../shared/services/ppv_service.dart';
import '../../ppv/widgets/ppv_payment_sheet.dart';

/// Compact in-feed PPV buy card — zero-friction micro-monetisation
/// Shows upcoming/live PPV events inline with Buy Now CTA.
/// Animated pulsing glow when event is LIVE.
class FeedPPVCard extends StatefulWidget {
  final PPVEvent event;
  final VoidCallback? onPurchased;

  const FeedPPVCard({super.key, required this.event, this.onPurchased});

  @override
  State<FeedPPVCard> createState() => _FeedPPVCardState();
}

class _FeedPPVCardState extends State<FeedPPVCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseCtrl;
  late Animation<double> _pulseAnim;

  PPVEvent get event => widget.event;

  @override
  void initState() {
    super.initState();
    if (event.isLive) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(
        begin: 0.5,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _pulseCtrl!, curve: Curves.easeInOut));
    } else {
      _pulseAnim = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    _pulseCtrl?.dispose();
    super.dispose();
  }

  String get _priceLabel {
    final dollars = event.standardPrice;
    if (dollars <= 0) return 'FREE';
    return '\$${dollars.toStringAsFixed(2)} ${event.currency}';
  }

  /// Hype intensity based on event proximity [0.0 → 1.0].
  double get _hypeIntensity {
    if (event.isLive) return 0.9;
    final hoursUntil = event.eventDate.difference(DateTime.now()).inHours;
    if (hoursUntil <= 0) return 0.9;
    if (hoursUntil <= 1) return 0.8;
    if (hoursUntil <= 24) return 0.6;
    if (hoursUntil <= 72) return 0.45;
    if (hoursUntil <= 168) return 0.35;
    if (hoursUntil <= 336) return 0.25;
    return 0.0;
  }

  String get _singleFightLabel {
    final price = event.standardPrice * 0.28;
    final clamped = price.clamp(1.99, event.standardPrice);
    return 'From \$${clamped.toStringAsFixed(2)}';
  }

  String get _countdownLabel {
    if (event.isLive) return '🔴 LIVE NOW';
    final date = event.eventDate;
    final diff = date.difference(DateTime.now());
    if (diff.isNegative) return 'Event started';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  void _openPaymentSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PPVPaymentSheet(
        event: event,
        onPaymentConfirmed: (request) async {
          final messenger = ScaffoldMessenger.of(context);
          try {
            await PPVService().purchasePPV(
              ppvEventId: event.id,
              paymentIntentId: request.externalPaymentReference,
              paymentMethod: request.paymentMethod.key,
              tier: _mapTier(request.purchaseTier),
              pricePaidCents: (request.amount * 100).round(),
            );
            messenger.showSnackBar(
              SnackBar(
                content: Text('✅ ${request.purchaseTier.label} purchased!'),
              ),
            );
            widget.onPurchased?.call();
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(content: Text('Purchase failed: $e')),
            );
          }
        },
      ),
    );
  }

  PPVTier _mapTier(PurchaseTier tier) {
    switch (tier) {
      case PurchaseTier.singleFight:
        return PPVTier.standard;
      case PurchaseTier.mainEvent:
        return PPVTier.premium;
      case PurchaseTier.fullShow:
        return PPVTier.vip;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = _buildCardContent(context);

    // Wrap in animated builder for live pulsing
    if (event.isLive && _pulseCtrl != null) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, _) =>
            _buildCardContainer(context, cardContent, _pulseAnim.value),
      );
    }

    return _buildCardContainer(context, cardContent, 1.0);
  }

  Widget _buildCardContainer(BuildContext context, Widget child, double pulse) {
    final hype = _hypeIntensity;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DesignTokens.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.isLive
              ? Colors.redAccent.withValues(alpha: 0.3 + 0.3 * pulse)
              : hype > 0.2
              ? AdrenalineTheme.hypeColor(hype).withValues(alpha: 0.3)
              : DesignTokens.neonCyan.withValues(alpha: 0.2),
        ),
        boxShadow: [
          if (event.isLive)
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.08 + 0.15 * pulse),
              blurRadius: 12 + 8 * pulse,
              spreadRadius: 1 + 2 * pulse,
            )
          else if (hype > 0.2)
            ...AdrenalineTheme.hypeGlow(hype * 0.5)
          else
            BoxShadow(
              color: DesignTokens.neonCyan.withValues(alpha: 0.08),
              blurRadius: 8,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/ppv/event/${event.id}'),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Poster banner ──
        _buildPoster(),
        // ── Event info + buy CTA ──
        _buildInfo(context),
      ],
    );
  }

  Widget _buildPoster() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 16:9 aspect ratio, clamped 120-220px
          final h = (constraints.maxWidth * 9 / 16).clamp(120.0, 220.0);
          return SizedBox(
            height: h,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Poster image
                if (event.posterUrl != null && event.posterUrl!.isNotEmpty)
                  Image(
                    image: ImageAssets.safeProvider(event.posterUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholderGradient(),
                  )
                else
                  _placeholderGradient(),
                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                // Status badge (top-left) — pulses when LIVE
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: event.isLive
                          ? Colors.redAccent
                          : DesignTokens.neonCyan.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: event.isLive
                          ? [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (event.isLive) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          event.isLive ? 'LIVE' : event.statusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Countdown / sport tag (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _countdownLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // Sport pill (bottom-left)
                if (event.sport != null)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.neonMagenta.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.sport!.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholderGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A2E), Color(0xFF0D0416)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_mma, color: Colors.white24, size: 48),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Promotion tag
                if (event.promotion != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      event.promotion!,
                      style: TextStyle(
                        color: DesignTokens.neonCyan.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                // Title
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Price tiers
                Text(
                  _singleFightLabel,
                  style: TextStyle(
                    color: DesignTokens.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Buy button
          Column(
            children: [
              // Price
              Text(
                _priceLabel,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              // Buy CTA
              GestureDetector(
                onTap: () => _openPaymentSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF0080FF)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'BUY NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
