import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/services/fight_pass_service.dart';
import '../../../shared/widgets/dfc_card.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// FIGHT PASS CARDS — Visual UI for passes, tickets, campaigns, donations
/// ═══════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// FIGHT PASS CARD
// ─────────────────────────────────────────────────────────────────────────────

class FightPassCard extends StatelessWidget {
  final FightPass pass;
  final VoidCallback? onBuy;
  final bool compact;

  const FightPassCard({
    super.key,
    required this.pass,
    this.onBuy,
    this.compact = false,
  });

  Color get _accentColor {
    switch (pass.type) {
      case PassType.vip:
        return DesignTokens.neonGold;
      case PassType.backstage:
        return DesignTokens.neonMagenta;
      case PassType.meetAndGreet:
        return DesignTokens.neonCyan;
      case PassType.kidsPass:
        return DesignTokens.neonGreen;
      case PassType.familyPack:
        return DesignTokens.neonAmber;
      case PassType.charity:
        return const Color(0xFFFF6B9D); // Warm pink
      case PassType.streaming:
        return DesignTokens.neonCyan;
      case PassType.pressMedia:
        return Colors.white;
      case PassType.general:
        return DesignTokens.neonCyan;
    }
  }

  IconData get _icon {
    switch (pass.type) {
      case PassType.vip:
        return Icons.diamond_outlined;
      case PassType.backstage:
        return Icons.meeting_room_outlined;
      case PassType.meetAndGreet:
        return Icons.handshake_outlined;
      case PassType.kidsPass:
        return Icons.child_care;
      case PassType.familyPack:
        return Icons.family_restroom;
      case PassType.charity:
        return Icons.volunteer_activism;
      case PassType.streaming:
        return Icons.live_tv_outlined;
      case PassType.pressMedia:
        return Icons.camera_alt_outlined;
      case PassType.general:
        return Icons.confirmation_number_outlined;
    }
  }

  String get _typeLabel {
    switch (pass.type) {
      case PassType.vip:
        return 'VIP';
      case PassType.backstage:
        return 'BACKSTAGE';
      case PassType.meetAndGreet:
        return 'MEET & GREET';
      case PassType.kidsPass:
        return 'KIDS PASS';
      case PassType.familyPack:
        return 'FAMILY PACK';
      case PassType.charity:
        return 'CHARITY';
      case PassType.streaming:
        return 'STREAM';
      case PassType.pressMedia:
        return 'PRESS';
      case PassType.general:
        return 'GENERAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildFull() {
    return DFCCard.pass(
      accent: _accentColor,
      isFeatured: pass.isCharity || pass.type == PassType.vip,
      onTap: onBuy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Type badge + price
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _accentColor.withValues(alpha: 0.4),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_icon, color: _accentColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _typeLabel,
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (pass.isCharity)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B9D).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${pass.charityPercentage?.toInt() ?? 100}% TO CHARITY',
                    style: const TextStyle(
                      color: Color(0xFFFF6B9D),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (pass.isLimited && !pass.isSoldOut)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.neonAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIMITED · ${pass.maxQuantity! - pass.soldCount} LEFT',
                    style: const TextStyle(
                      color: DesignTokens.neonAmber,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Title
          Text(
            pass.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),

          // Description
          Text(
            pass.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Includes list
          if (pass.includes.isNotEmpty) ...[
            ...pass.includes
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: _accentColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            if (pass.includes.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${pass.includes.length - 4} more included',
                  style: TextStyle(
                    color: _accentColor.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],

          const SizedBox(height: 14),

          // Sold progress (if limited)
          if (pass.isLimited && pass.maxQuantity != null) ...[
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pass.percentSold,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pass.isSoldOut ? DesignTokens.neonRed : _accentColor,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${pass.soldCount}/${pass.maxQuantity}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Price + CTA
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${pass.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _accentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (pass.eventDate != null)
                    Text(
                      '${pass.eventDate!.day}/${pass.eventDate!.month}/${pass.eventDate!.year}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              _BuyButton(
                label: pass.isSoldOut
                    ? 'SOLD OUT'
                    : pass.isCharity
                    ? 'DONATE'
                    : 'GET PASS',
                color: _accentColor,
                enabled: !pass.isSoldOut,
                onTap: pass.isSoldOut ? null : onBuy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompact() {
    return DFCCard.glass(
      accent: _accentColor,
      onTap: onBuy,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: _accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pass.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _typeLabel,
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${pass.price.toStringAsFixed(2)}',
            style: TextStyle(
              color: _accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMPAIGN CARD
// ─────────────────────────────────────────────────────────────────────────────

class CampaignCard extends StatelessWidget {
  final FightCampaign campaign;
  final VoidCallback? onDonate;
  final bool compact;

  const CampaignCard({
    super.key,
    required this.campaign,
    this.onDonate,
    this.compact = false,
  });

  Color get _typeColor {
    switch (campaign.type) {
      case CampaignType.sickKids:
        return const Color(0xFFFF6B9D);
      case CampaignType.mentalHealthAwareness:
        return DesignTokens.neonGreen;
      case CampaignType.veteranSupport:
        return DesignTokens.neonAmber;
      case CampaignType.communityGym:
        return DesignTokens.neonCyan;
      case CampaignType.youthTraining:
        return DesignTokens.neonGreen;
      case CampaignType.disabilityInclusion:
        return const Color(0xFF9B59B6);
      case CampaignType.antibullying:
        return DesignTokens.neonAmber;
      case CampaignType.womenInCombatSports:
        return DesignTokens.neonMagenta;
      case CampaignType.homelessOutreach:
        return DesignTokens.neonCyan;
      case CampaignType.custom:
        return DesignTokens.neonCyan;
    }
  }

  IconData get _icon {
    switch (campaign.type) {
      case CampaignType.sickKids:
        return Icons.favorite;
      case CampaignType.mentalHealthAwareness:
        return Icons.psychology_outlined;
      case CampaignType.veteranSupport:
        return Icons.military_tech;
      case CampaignType.communityGym:
        return Icons.fitness_center;
      case CampaignType.youthTraining:
        return Icons.sports_martial_arts;
      case CampaignType.disabilityInclusion:
        return Icons.accessibility_new;
      case CampaignType.antibullying:
        return Icons.shield_outlined;
      case CampaignType.womenInCombatSports:
        return Icons.woman;
      case CampaignType.homelessOutreach:
        return Icons.home_outlined;
      case CampaignType.custom:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return DFCCard.pass(
      accent: _typeColor,
      isFeatured: true,
      onTap: onDonate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: _typeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      campaign.organizer,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            campaign.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Impact statement
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _typeColor.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: _typeColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    campaign.impactStatement,
                    style: TextStyle(
                      color: _typeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${campaign.raisedAmount.toStringAsFixed(0)} raised',
                    style: TextStyle(
                      color: _typeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'of \$${campaign.goalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: campaign.percentFunded,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(_typeColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${campaign.donorCount} donors',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${(campaign.percentFunded * 100).toStringAsFixed(0)}% funded',
                    style: TextStyle(
                      color: _typeColor.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Donate CTA
          SizedBox(
            width: double.infinity,
            child: _BuyButton(
              label: campaign.isFullyFunded ? 'FULLY FUNDED 🎉' : 'DONATE NOW',
              color: _typeColor,
              enabled: !campaign.isFullyFunded,
              onTap: campaign.isFullyFunded ? null : onDonate,
              expanded: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact() {
    return DFCCard.glass(
      accent: _typeColor,
      onTap: onDonate,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: _typeColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  campaign.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: campaign.percentFunded,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(_typeColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(campaign.percentFunded * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: _typeColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DISCOUNT BADGE
// ─────────────────────────────────────────────────────────────────────────────

class DiscountBadge extends StatelessWidget {
  final FightDiscount discount;
  final VoidCallback? onApply;

  const DiscountBadge({super.key, required this.discount, this.onApply});

  @override
  Widget build(BuildContext context) {
    return DFCCard.glass(
      accent: DesignTokens.neonGreen,
      onTap: onApply,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.neonGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${discount.discountPercent.toInt()}% OFF',
              style: const TextStyle(
                color: DesignTokens.neonGreen,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  discount.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                if (discount.description != null)
                  Text(
                    discount.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (onApply != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(
                  color: DesignTokens.neonGreen.withValues(alpha: 0.4),
                  width: 0.6,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'APPLY',
                style: TextStyle(
                  color: DesignTokens.neonGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED BUY BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _BuyButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;
  final bool expanded;

  const _BuyButton({
    required this.label,
    required this.color,
    this.enabled = true,
    this.onTap,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: expanded ? 0 : 20,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? color.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            width: 0.6,
          ),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? color : Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
