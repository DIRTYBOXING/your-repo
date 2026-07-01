import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/fight_marketplace_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MARKETPLACE CARDS - 2026 Glass Design System
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Cards for:
/// - Equipment listings (buy/sell gear)
/// - Trainer profiles (advertise yourself)
/// - Gym startup packages
/// - Jobs & sparring partner requests
/// - Featured promo cards (in-feed promoted)
/// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// EQUIPMENT / GENERAL LISTING CARD
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceListingCard extends StatelessWidget {
  final MarketplaceListing listing;
  final VoidCallback? onTap;
  final bool compact;

  const MarketplaceListingCard({
    super.key,
    required this.listing,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: DesignTokens.glassOpacity),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: _getCategoryColor().withValues(
              alpha: DesignTokens.glassBorderOpacity,
            ),
            width: DesignTokens.borderThin,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurLight,
              sigmaY: DesignTokens.glassBlurLight,
            ),
            child: Padding(
              padding: EdgeInsets.all(
                compact
                    ? DesignTokens.cardPaddingSmall
                    : DesignTokens.cardPaddingMedium,
              ),
              child: compact ? _buildCompactLayout() : _buildFullLayout(),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a branded DFC image path based on marketplace category.
  String _getCategoryImageUrl() {
    switch (listing.category) {
      case MarketplaceCategory.equipment:
      case MarketplaceCategory.apparel:
        return ImageAssets.bgAction;
      case MarketplaceCategory.personalTraining:
      case MarketplaceCategory.coaching:
      case MarketplaceCategory.nutrition:
      case MarketplaceCategory.supplements:
      case MarketplaceCategory.recovery:
        return ImageAssets.bgEvent;
      case MarketplaceCategory.gymServices:
      case MarketplaceCategory.gymStartup:
        return ImageAssets.bgCentral;
      case MarketplaceCategory.sparringPartners:
        return ImageAssets.bgPromo;
      case MarketplaceCategory.events:
      case MarketplaceCategory.jobs:
        return ImageAssets.bgHero;
    }
  }

  Widget _buildFullLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Product hero image
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          child: Image.asset(
            _getCategoryImageUrl(),
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getCategoryColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              ),
              child: Icon(
                _getCategoryIcon(),
                color: _getCategoryColor().withValues(alpha: 0.3),
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingM),
        // Header row: category pill + featured badge + price
        Row(
          children: [
            _CategoryPill(
              category: listing.category,
              color: _getCategoryColor(),
            ),
            if (listing.isFeatured) ...[
              const SizedBox(width: DesignTokens.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.neonGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                  border: Border.all(
                    color: DesignTokens.neonGold.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 10,
                      color: DesignTokens.neonGold,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'FEATURED',
                      style: TextStyle(
                        color: DesignTokens.neonGold,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            if (listing.price > 0)
              Text(
                '\$${listing.price.toStringAsFixed(listing.price % 1 == 0 ? 0 : 2)}',
                style: const TextStyle(
                  color: DesignTokens.neonCyan,
                  fontSize: DesignTokens.fontSizeStatSmall,
                  fontWeight: DesignTokens.fontWeightStat,
                ),
              )
            else
              Text(
                listing.category == MarketplaceCategory.jobs
                    ? 'HIRING'
                    : 'FREE',
                style: const TextStyle(
                  color: DesignTokens.success,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Title
        Text(
          listing.title,
          style: const TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: DesignTokens.fontSizeTitle,
            fontWeight: DesignTokens.fontWeightTitle,
            height: 1.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: DesignTokens.spacingXS),

        // Description
        Text(
          listing.description,
          style: const TextStyle(
            color: DesignTokens.textSecondary,
            fontSize: DesignTokens.fontSizeSubtitle,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: DesignTokens.spacingM),

        // Footer: seller + stats
        Row(
          children: [
            // Seller
            const Icon(Icons.person_outline, size: 14, color: DesignTokens.textMuted),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                listing.sellerName,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (listing.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified,
                size: 12,
                color: DesignTokens.neonCyan,
              ),
            ],
            const Spacer(),
            // Location
            if (listing.location != null) ...[
              const Icon(
                Icons.location_on_outlined,
                size: 12,
                color: DesignTokens.textMuted,
              ),
              const SizedBox(width: 2),
              Text(
                listing.location!,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeMicro,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: DesignTokens.spacingS),

        // Engagement stats
        Row(
          children: [
            _StatChip(icon: Icons.visibility_outlined, value: listing.views),
            const SizedBox(width: DesignTokens.spacingM),
            _StatChip(icon: Icons.bookmark_outline, value: listing.saves),
            const SizedBox(width: DesignTokens.spacingM),
            _StatChip(
              icon: Icons.chat_bubble_outline,
              value: listing.inquiries,
            ),
            const Spacer(),
            if (listing.isNegotiable)
              Text(
                'NEGOTIABLE',
                style: TextStyle(
                  color: DesignTokens.neonAmber.withValues(alpha: 0.7),
                  fontSize: DesignTokens.fontSizeMicro,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactLayout() {
    return Row(
      children: [
        // Category thumbnail image
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _getCategoryColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: Image.asset(
              _getCategoryImageUrl(),
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                _getCategoryIcon(),
                color: _getCategoryColor(),
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                listing.title,
                style: const TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                listing.sellerName,
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: DesignTokens.fontSizeCaption,
                ),
              ),
            ],
          ),
        ),
        if (listing.price > 0)
          Text(
            '\$${listing.price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: DesignTokens.neonCyan,
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (listing.category) {
      case MarketplaceCategory.equipment:
        return DesignTokens.neonCyan;
      case MarketplaceCategory.personalTraining:
        return DesignTokens.neonMagenta;
      case MarketplaceCategory.gymServices:
      case MarketplaceCategory.gymStartup:
        return DesignTokens.neonAmber;
      case MarketplaceCategory.nutrition:
      case MarketplaceCategory.supplements:
        return DesignTokens.neonGreen;
      case MarketplaceCategory.coaching:
        return DesignTokens.neonMagenta;
      case MarketplaceCategory.events:
        return DesignTokens.neonRed;
      case MarketplaceCategory.apparel:
        return DesignTokens.neonCyan;
      case MarketplaceCategory.recovery:
        return DesignTokens.success;
      case MarketplaceCategory.jobs:
        return DesignTokens.neonGold;
      case MarketplaceCategory.sparringPartners:
        return DesignTokens.neonRed;
    }
  }

  IconData _getCategoryIcon() {
    switch (listing.category) {
      case MarketplaceCategory.equipment:
        return Icons.sports_mma;
      case MarketplaceCategory.personalTraining:
        return Icons.fitness_center;
      case MarketplaceCategory.gymServices:
      case MarketplaceCategory.gymStartup:
        return Icons.store;
      case MarketplaceCategory.nutrition:
      case MarketplaceCategory.supplements:
        return Icons.restaurant;
      case MarketplaceCategory.coaching:
        return Icons.school;
      case MarketplaceCategory.events:
        return Icons.event;
      case MarketplaceCategory.apparel:
        return Icons.checkroom;
      case MarketplaceCategory.recovery:
        return Icons.spa;
      case MarketplaceCategory.jobs:
        return Icons.work;
      case MarketplaceCategory.sparringPartners:
        return Icons.people;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRAINER PROFILE CARD
// ─────────────────────────────────────────────────────────────────────────────

class TrainerProfileCard extends StatelessWidget {
  final TrainerProfile trainer;
  final VoidCallback? onTap;
  final VoidCallback? onContact;

  const TrainerProfileCard({
    super.key,
    required this.trainer,
    this.onTap,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: DesignTokens.glassOpacity),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.neonMagenta.withValues(
              alpha: DesignTokens.glassBorderOpacity,
            ),
            width: DesignTokens.borderThin,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurLight,
              sigmaY: DesignTokens.glassBlurLight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: Avatar + Name + Rating
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              DesignTokens.neonMagenta.withValues(alpha: 0.3),
                              DesignTokens.neonCyan.withValues(alpha: 0.3),
                            ],
                          ),
                          border: Border.all(
                            color: DesignTokens.neonMagenta.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            trainer.name.isNotEmpty ? trainer.name[0] : '?',
                            style: const TextStyle(
                              color: DesignTokens.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    trainer.name,
                                    style: const TextStyle(
                                      color: DesignTokens.textPrimary,
                                      fontSize: DesignTokens.fontSizeTitle,
                                      fontWeight: DesignTokens.fontWeightTitle,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (trainer.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: DesignTokens.neonCyan,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              trainer.specialties.join(' · '),
                              style: const TextStyle(
                                color: DesignTokens.textMuted,
                                fontSize: DesignTokens.fontSizeSubtitle,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Rating
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: DesignTokens.neonGold,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                trainer.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: DesignTokens.textPrimary,
                                  fontSize: DesignTokens.fontSizeBody,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${trainer.reviewCount} reviews',
                            style: const TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: DesignTokens.fontSizeMicro,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // Bio
                  Text(
                    trainer.bio,
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeSubtitleLarge,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // Service pills
                  Wrap(
                    spacing: DesignTokens.spacingXS,
                    runSpacing: DesignTokens.spacingXS,
                    children: trainer.services.take(4).map((service) {
                      return _ServicePill(service: service);
                    }).toList(),
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // Footer: Price + Location + Contact CTA
                  Row(
                    children: [
                      // Rate
                      Text(
                        '\$${trainer.hourlyRate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: DesignTokens.fontSizeStatSmall,
                          fontWeight: DesignTokens.fontWeightStat,
                        ),
                      ),
                      const Text(
                        '/hr',
                        style: TextStyle(
                          color: DesignTokens.textMuted,
                          fontSize: DesignTokens.fontSizeCaption,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingM),
                      if (trainer.location != null) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: DesignTokens.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            trainer.location!,
                            style: const TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: DesignTokens.fontSizeMicro,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      const Spacer(),
                      // Contact button
                      GestureDetector(
                        onTap: onContact,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.buttonPaddingH,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DesignTokens.neonCyan.withValues(alpha: 0.2),
                                DesignTokens.neonMagenta.withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusPill,
                            ),
                            border: Border.all(
                              color: DesignTokens.neonCyan.withValues(
                                alpha: 0.3,
                              ),
                              width: 0.5,
                            ),
                          ),
                          child: const Text(
                            'CONTACT',
                            style: TextStyle(
                              color: DesignTokens.neonCyan,
                              fontSize: DesignTokens.fontSizeCaption,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Trial session banner
                  if (trainer.offersTrialSession &&
                      trainer.trialDescription != null) ...[
                    const SizedBox(height: DesignTokens.spacingM),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DesignTokens.spacingS),
                      decoration: BoxDecoration(
                        color: DesignTokens.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusSmall,
                        ),
                        border: Border.all(
                          color: DesignTokens.success.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            size: 14,
                            color: DesignTokens.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              trainer.trialDescription!,
                              style: const TextStyle(
                                color: DesignTokens.success,
                                fontSize: DesignTokens.fontSizeCaption,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GYM STARTUP PACKAGE CARD
// ─────────────────────────────────────────────────────────────────────────────

class GymStartupPackageCard extends StatelessWidget {
  final GymStartupPackage package;
  final VoidCallback? onTap;

  const GymStartupPackageCard({super.key, required this.package, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacingM),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: DesignTokens.glassOpacity),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.neonAmber.withValues(
              alpha: DesignTokens.glassBorderOpacity,
            ),
            width: DesignTokens.borderThin,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: DesignTokens.glassBlurLight,
              sigmaY: DesignTokens.glassBlurLight,
            ),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.cardPaddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: DesignTokens.neonAmber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusSmall,
                          ),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: DesignTokens.neonAmber,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.title,
                              style: const TextStyle(
                                color: DesignTokens.textPrimary,
                                fontSize: DesignTokens.fontSizeTitle,
                                fontWeight: DesignTokens.fontWeightTitle,
                              ),
                            ),
                            Text(
                              'by ${package.vendorName}',
                              style: const TextStyle(
                                color: DesignTokens.textMuted,
                                fontSize: DesignTokens.fontSizeCaption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${package.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: DesignTokens.neonAmber,
                          fontSize: DesignTokens.fontSizeStatSmall,
                          fontWeight: DesignTokens.fontWeightStat,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // Description
                  Text(
                    package.description,
                    style: const TextStyle(
                      color: DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeSubtitleLarge,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingM),

                  // Includes list (first 4 items)
                  ...package.includes
                      .take(4)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 14,
                                color: DesignTokens.success,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    color: DesignTokens.textSecondary,
                                    fontSize: DesignTokens.fontSizeCaption,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (package.includes.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '+${package.includes.length - 4} more included',
                        style: TextStyle(
                          color: DesignTokens.neonAmber.withValues(alpha: 0.7),
                          fontSize: DesignTokens.fontSizeMicro,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKETPLACE CATEGORY FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────

class MarketplaceCategoryBar extends StatelessWidget {
  final MarketplaceCategory? selected;
  final ValueChanged<MarketplaceCategory?> onSelected;

  const MarketplaceCategoryBar({
    super.key,
    this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      (null, 'All', Icons.apps),
      (MarketplaceCategory.equipment, 'Gear', Icons.sports_mma),
      (MarketplaceCategory.personalTraining, 'Trainers', Icons.fitness_center),
      (MarketplaceCategory.apparel, 'Apparel', Icons.checkroom),
      (MarketplaceCategory.supplements, 'Supps', Icons.restaurant),
      (MarketplaceCategory.recovery, 'Recovery', Icons.spa),
      (MarketplaceCategory.jobs, 'Jobs', Icons.work),
      (MarketplaceCategory.events, 'Events', Icons.event),
      (MarketplaceCategory.gymStartup, 'Gym', Icons.store),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingL),
        itemCount: categories.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: DesignTokens.spacingS),
        itemBuilder: (context, index) {
          final (cat, label, icon) = categories[index];
          final isActive = selected == cat;

          return GestureDetector(
            onTap: () => onSelected(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? DesignTokens.neonCyan.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: DesignTokens.glassOpacity),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                border: Border.all(
                  color: isActive
                      ? DesignTokens.neonCyan.withValues(alpha: 0.4)
                      : DesignTokens.borderSubtle,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive
                        ? DesignTokens.neonCyan
                        : DesignTokens.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive
                          ? DesignTokens.neonCyan
                          : DesignTokens.textSecondary,
                      fontSize: DesignTokens.fontSizeCaption,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final MarketplaceCategory category;
  final Color color;

  const _CategoryPill({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        _categoryLabel(),
        style: TextStyle(
          color: color,
          fontSize: DesignTokens.fontSizeMicro,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _categoryLabel() {
    switch (category) {
      case MarketplaceCategory.equipment:
        return 'EQUIPMENT';
      case MarketplaceCategory.personalTraining:
        return 'PERSONAL TRAINING';
      case MarketplaceCategory.gymServices:
        return 'GYM SERVICES';
      case MarketplaceCategory.nutrition:
        return 'NUTRITION';
      case MarketplaceCategory.coaching:
        return 'COACHING';
      case MarketplaceCategory.events:
        return 'EVENTS';
      case MarketplaceCategory.apparel:
        return 'APPAREL';
      case MarketplaceCategory.supplements:
        return 'SUPPLEMENTS';
      case MarketplaceCategory.recovery:
        return 'RECOVERY';
      case MarketplaceCategory.jobs:
        return 'JOBS';
      case MarketplaceCategory.sparringPartners:
        return 'SPARRING PARTNERS';
      case MarketplaceCategory.gymStartup:
        return 'GYM STARTUP';
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;

  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: DesignTokens.textMuted),
        const SizedBox(width: 3),
        Text(
          _formatCount(value),
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: DesignTokens.fontSizeMicro,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

class _ServicePill extends StatelessWidget {
  final TrainerServiceType service;

  const _ServicePill({required this.service});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getServiceInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  (String, Color) _getServiceInfo() {
    switch (service) {
      case TrainerServiceType.oneOnOne:
        return ('1-ON-1', DesignTokens.neonCyan);
      case TrainerServiceType.groupClass:
        return ('GROUP', DesignTokens.neonGreen);
      case TrainerServiceType.onlineCoaching:
        return ('ONLINE', DesignTokens.neonAmber);
      case TrainerServiceType.seminar:
        return ('SEMINAR', DesignTokens.neonMagenta);
      case TrainerServiceType.fightCamp:
        return ('FIGHT CAMP', DesignTokens.neonRed);
      case TrainerServiceType.womenOnly:
        return ('WOMEN ONLY', DesignTokens.neonMagenta);
      case TrainerServiceType.kidsClass:
        return ('KIDS', DesignTokens.neonGreen);
      case TrainerServiceType.beginnerFriendly:
        return ('BEGINNER', DesignTokens.neonCyan);
      case TrainerServiceType.proLevel:
        return ('PRO LEVEL', DesignTokens.neonGold);
      case TrainerServiceType.traumaInformed:
        return ('TRAUMA-INFORMED', DesignTokens.neonMagenta);
      case TrainerServiceType.selfDefense:
        return ('SELF DEFENSE', DesignTokens.neonRed);
      case TrainerServiceType.fitnessBoxing:
        return ('FITNESS', DesignTokens.neonGreen);
    }
  }
}
