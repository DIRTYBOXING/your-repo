import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../models/signal_model.dart';
import 'dfc_network_image.dart';

/// FightWireCard - The comprehensive signal card for FightWire feed
/// Works with the Signal model for all content types
/// Universal, alive, purposeful
class FightWireCard extends StatelessWidget {
  final Signal signal;
  final VoidCallback? onTap;
  final bool showFullBody;
  final bool animate;

  const FightWireCard({
    super.key,
    required this.signal,
    this.onTap,
    this.showFullBody = false,
    this.animate = true,
  });

  Color get _accentColor => Color(Signal.getAccentColorValue(signal.type));

  IconData get _typeIcon {
    switch (signal.type) {
      case SignalType.event:
        return Icons.event;
      case SignalType.opportunity:
        return Icons.flash_on;
      case SignalType.news:
        return Icons.article;
      case SignalType.camp:
        return Icons.fitness_center;
      case SignalType.mentor:
        return Icons.school;
      case SignalType.culture:
        return Icons.mic;
      case SignalType.honour:
        return Icons.emoji_events;
      case SignalType.aiInsight:
        return Icons.psychology;
      case SignalType.safety:
        return Icons.health_and_safety;
      case SignalType.community:
        return Icons.people;
    }
  }

  String get _typeLabel {
    switch (signal.type) {
      case SignalType.event:
        return 'EVENT';
      case SignalType.opportunity:
        return 'OPPORTUNITY';
      case SignalType.news:
        return 'NEWS';
      case SignalType.camp:
        return 'CAMP';
      case SignalType.mentor:
        return 'MENTOR';
      case SignalType.culture:
        return 'CULTURE';
      case SignalType.honour:
        return 'HONOUR';
      case SignalType.aiInsight:
        return 'AI INSIGHT';
      case SignalType.safety:
        return 'SUPPORT';
      case SignalType.community:
        return 'COMMUNITY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _accentColor.withValues(
              alpha: signal.state == SignalState.escalated ? 0.6 : 0.25,
            ),
            width: signal.state == SignalState.escalated ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _accentColor.withValues(
                alpha: signal.state == SignalState.escalated ? 0.3 : 0.1,
              ),
              blurRadius: signal.state == SignalState.escalated ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with accent bar
              _buildHeader(),

              // Poster image for event/news signals
              if (signal.imageUrl != null &&
                  signal.imageUrl!.isNotEmpty &&
                  (signal.type == SignalType.event ||
                      signal.type == SignalType.news))
                _buildPosterBanner(),

              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      signal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Summary
                    Text(
                      signal.summary,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: showFullBody ? null : 2,
                      overflow: showFullBody ? null : TextOverflow.ellipsis,
                    ),

                    // Body (if present and showing full)
                    if (signal.body != null && showFullBody) ...[
                      const SizedBox(height: 12),
                      Text(
                        signal.body!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],

                    // Footer with metadata and CTA
                    const SizedBox(height: 12),
                    _buildFooter(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPosterBanner() {
    final url = signal.imageUrl!;
    const bannerHeight = 180.0;
    Widget imageWidget;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = DfcNetworkImage(
        url: url,
        width: double.infinity,
        height: bannerHeight,
      );
    } else {
      imageWidget = Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: bannerHeight,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    }
    return Stack(
      children: [
        SizedBox(
          height: bannerHeight,
          width: double.infinity,
          child: imageWidget,
        ),
        // Bottom gradient for text bleed-in
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.cardBackground.withValues(alpha: 0.9),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: _accentColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          // Type indicator with glow
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Type icon
          Icon(_typeIcon, color: _accentColor, size: 18),
          const SizedBox(width: 8),

          // Type label
          Text(
            _typeLabel,
            style: TextStyle(
              color: _accentColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),

          const Spacer(),

          // Vertical badge (if present)
          if (signal.vertical != null) _buildVerticalBadge(),

          // Verified badge
          if (signal.verified)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.verified, color: AppTheme.neonGreen, size: 16),
            ),

          // Priority indicator for urgent/critical
          if (signal.priority == SignalPriority.urgent ||
              signal.priority == SignalPriority.critical)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildPriorityBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildVerticalBadge() {
    String label = '';
    switch (signal.vertical) {
      case CombatVertical.boxing:
        label = 'BOXING';
        break;
      case CombatVertical.mma:
        label = 'MMA';
        break;
      case CombatVertical.oneChampionship:
        label = 'ONE';
        break;
      case CombatVertical.kickboxing:
        label = 'KICKBOXING';
        break;
      case CombatVertical.muayThai:
        label = 'MUAY THAI';
        break;
      case CombatVertical.bareKnuckle:
        label = 'BARE KNUCKLE';
        break;
      case CombatVertical.dirtyBoxing:
        label = 'DBX';
        break;
      case CombatVertical.internationalBrawling:
        label = 'BRAWL';
        break;
      case CombatVertical.regional:
        label = 'REGIONAL';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge() {
    final isCritical = signal.priority == SignalPriority.critical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red : Colors.orange,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCritical ? Icons.warning : Icons.priority_high,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            isCritical ? 'CRITICAL' : 'URGENT',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Location (if present)
        if (signal.city != null || signal.region != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: AppTheme.textMuted,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                signal.city ?? signal.region ?? '',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(width: 12),
            ],
          ),

        // Time ago
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, color: AppTheme.textMuted, size: 14),
            const SizedBox(width: 4),
            Text(
              _formatTimeAgo(signal.createdAt),
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),

        const Spacer(),

        // CTA Button (if present)
        if (signal.ctaUrl != null && signal.ctaLabel != null)
          TextButton(
            onPressed: () => _launchUrl(signal.ctaUrl!),
            style: TextButton.styleFrom(
              backgroundColor: _accentColor.withValues(alpha: 0.2),
              foregroundColor: _accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              signal.ctaLabel!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Hero Signal Card - Featured/highlighted signals at top of feeds
class HeroSignalCard extends StatelessWidget {
  final Signal signal;
  final VoidCallback? onTap;

  const HeroSignalCard({super.key, required this.signal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(Signal.getAccentColorValue(signal.type));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.3),
              accentColor.withValues(alpha: 0.1),
              AppTheme.cardBackground,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  signal.type.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                signal.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Summary
              Text(
                signal.summary,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),

              if (signal.ctaLabel != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (signal.ctaUrl != null) {
                      final uri = Uri.parse(signal.ctaUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(signal.ctaLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
