import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AD COMPONENTS - 2026 Design System
/// Micro, Small, and Large Bubble Ads + Subscription Prompts
/// ═══════════════════════════════════════════════════════════════════════════

enum AdSize { micro, small, medium, large, bubble }

/// Base Ad Card - Glass morphism with neon accents
class AdCard extends StatefulWidget {
  final AdSize size;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final String? ctaText;
  final Color accent;
  final VoidCallback? onTap;
  final bool isSponsored;
  final String? source;

  const AdCard({
    super.key,
    this.size = AdSize.small,
    this.title,
    this.subtitle,
    this.imageUrl,
    this.ctaText,
    this.accent = DesignTokens.neonCyan,
    this.onTap,
    this.isSponsored = false,
    this.source,
  });

  @override
  State<AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<AdCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.size) {
      case AdSize.micro:
        return _buildMicroAd();
      case AdSize.small:
        return _buildSmallAd();
      case AdSize.medium:
        return _buildMediumAd();
      case AdSize.large:
        return _buildLargeAd();
      case AdSize.bubble:
        return _buildBubbleAd();
    }
  }

  /// Micro Ad - Inline text with subtle highlight
  Widget _buildMicroAd() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: _isHovered ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
            border: Border.all(
              color: widget.accent.withValues(alpha: _isHovered ? 0.4 : 0.2),
              width: DesignTokens.borderThin,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isSponsored)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AD',
                    style: TextStyle(
                      color: widget.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Flexible(
                child: Text(
                  widget.title ?? 'Upgrade to Pro',
                  style: TextStyle(
                    color: widget.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, color: widget.accent, size: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// Small Ad - Compact card with icon
  Widget _buildSmallAd() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          height: 70,
          padding: const EdgeInsets.all(DesignTokens.cardPaddingSmall),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: _isHovered ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: widget.accent.withValues(alpha: _isHovered ? 0.35 : 0.15),
              width: DesignTokens.borderThin,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.15),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accent.withValues(alpha: 0.3),
                      widget.accent.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Icon(Icons.flash_on, color: widget.accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isSponsored)
                      Text(
                        'SPONSORED',
                        style: TextStyle(
                          color: widget.accent.withValues(alpha: 0.6),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    Text(
                      widget.title ?? 'Fighter Pro',
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.subtitle ?? 'Unlock all features',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.accent,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                ),
                child: Text(
                  widget.ctaText ?? 'GO',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Medium Ad - Standard card with more content
  Widget _buildMediumAd() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          height: 100,
          padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.accent.withValues(alpha: _isHovered ? 0.12 : 0.06),
                widget.accent.withValues(alpha: _isHovered ? 0.06 : 0.02),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: widget.accent.withValues(alpha: _isHovered ? 0.4 : 0.2),
              width: DesignTokens.borderThin,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.2),
                      blurRadius: 16,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Image/Icon area
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      widget.accent.withValues(alpha: 0.4),
                      widget.accent.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  border: Border.all(
                    color: widget.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(Icons.sports_mma, color: widget.accent, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (widget.isSponsored)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'AD',
                              style: TextStyle(
                                color: widget.accent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (widget.source != null)
                          Text(
                            widget.source!,
                            style: TextStyle(
                              color: widget.accent.withValues(alpha: 0.7),
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.title ?? 'Premium Feature',
                      style: const TextStyle(
                        color: DesignTokens.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle ?? 'Tap to learn more',
                      style: const TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: widget.accent, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Large Ad - Full width with gradient background
  Widget _buildLargeAd() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: DesignTokens.animFast,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.accent.withValues(alpha: 0.2),
                DesignTokens.neonMagenta.withValues(alpha: 0.1),
                DesignTokens.bgSecondary,
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: widget.accent.withValues(alpha: _isHovered ? 0.5 : 0.25),
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.25),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        widget.accent.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(DesignTokens.cardPaddingLarge),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isSponsored)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: widget.accent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusPill,
                                ),
                                border: Border.all(
                                  color: widget.accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'SPONSORED',
                                style: TextStyle(
                                  color: widget.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Text(
                            widget.title ?? 'Upgrade to Fighter Pro',
                            style: const TextStyle(
                              color: DesignTokens.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subtitle ??
                                'Unlock unlimited AI coaching, analytics, and more',
                            style: const TextStyle(
                              color: DesignTokens.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: widget.accent,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusPill,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.accent.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              widget.ctaText ?? 'Start Free Trial',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            widget.accent,
                            widget.accent.withValues(alpha: 0.5),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accent.withValues(alpha: 0.4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.black,
                        size: 40,
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

  /// Bubble Ad - Floating orb style
  Widget _buildBubbleAd() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: DesignTokens.animFast,
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.accent.withValues(alpha: _isHovered ? 0.4 : 0.25),
                    widget.accent.withValues(alpha: _isHovered ? 0.2 : 0.1),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: widget.accent.withValues(
                    alpha: _isHovered ? 0.6 : 0.35,
                  ),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(
                      alpha: _isHovered ? 0.4 : 0.2,
                    ),
                    blurRadius: _isHovered ? 30 : 20,
                    spreadRadius: _isHovered ? 5 : 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isSponsored)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: widget.accent.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusPill,
                        ),
                      ),
                      child: Text(
                        'AD',
                        style: TextStyle(
                          color: widget.accent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(Icons.sports_mma, color: widget.accent, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    widget.title ?? 'Pro',
                    style: const TextStyle(
                      color: DesignTokens.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Subscription Prompt Banner
class SubscriptionBanner extends StatelessWidget {
  final String tier;
  final String? message;
  final VoidCallback? onUpgrade;

  const SubscriptionBanner({
    super.key,
    this.tier = 'Pro',
    this.message,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignTokens.neonCyan.withValues(alpha: 0.15),
            DesignTokens.neonMagenta.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.neonCyan.withValues(alpha: 0.3),
          width: DesignTokens.borderThin,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade to $tier',
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  message ?? 'Unlock all features',
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onUpgrade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [DesignTokens.neonCyan, DesignTokens.neonMagenta],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Revolving Ad Carousel - Auto-scrolling ads
class RevolvingAdCarousel extends StatefulWidget {
  final List<AdCard> ads;
  final Duration interval;

  const RevolvingAdCarousel({
    super.key,
    required this.ads,
    this.interval = const Duration(seconds: 5),
  });

  @override
  State<RevolvingAdCarousel> createState() => _RevolvingAdCarouselState();
}

class _RevolvingAdCarouselState extends State<RevolvingAdCarousel> {
  late PageController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(widget.interval, () {
      if (mounted && widget.ads.isNotEmpty) {
        _currentPage = (_currentPage + 1) % widget.ads.length;
        _controller.animateToPage(
          _currentPage,
          duration: DesignTokens.animNormal,
          curve: DesignTokens.animCurve,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ads.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 100,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.ads.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: widget.ads[index],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.ads.length, (index) {
            return AnimatedContainer(
              duration: DesignTokens.animFast,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? DesignTokens.neonCyan
                    : DesignTokens.neonCyan.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}
