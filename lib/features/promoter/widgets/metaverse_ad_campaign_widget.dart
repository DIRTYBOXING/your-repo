import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:datafightcentral/core/theme/app_theme.dart';
import 'package:datafightcentral/features/promoter/controllers/metaverse_rebroadcast_controller.dart';
import 'package:datafightcentral/shared/services/metaverse_ad_campaign_engine.dart';

/// Metaverse Ad Campaign Display Widget
/// Shows action-packed ads, highlights, and live broadcasts across platforms
class MetaverseAdCampaignWidget extends StatefulWidget {
  const MetaverseAdCampaignWidget({super.key});

  @override
  State<MetaverseAdCampaignWidget> createState() =>
      _MetaverseAdCampaignWidgetState();
}

class _MetaverseAdCampaignWidgetState extends State<MetaverseAdCampaignWidget>
    with TickerProviderStateMixin {
  late MetaverseContentRebroadcastController _rebroadcastController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _rebroadcastController = MetaverseContentRebroadcastController();

    // Pulse animation for live indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide animation for content entry
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _rebroadcastController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ChangeNotifierProvider.value(
        value: _rebroadcastController,
        child: Column(
          children: [
            // Header
            _buildActionPackedHeader(),
            const SizedBox(height: 16),
            // Live Broadcast status
            _buildLiveBroadcastStatus(),
            const SizedBox(height: 16),
            // Platform-specific campaigns
            _buildPlatformCampaigns(),
            const SizedBox(height: 16),
            // Re-Broadcast Button
            _buildRebroadcastButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPackedHeader() {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.neonPurple.withValues(alpha: 0.8),
              AppTheme.neonCyan.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.neonPurple, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.neonPurple.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🔥⚡💥 ACTION-PACKED ADS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Metaverse Platforms: Roblox • Fortnite • Decentraland • Sandbox • Horizon',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text(
              'Magnified Content → Edited → Re-Added with Highlights',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.neonCyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBroadcastStatus() {
    return Consumer<MetaverseContentRebroadcastController>(
      builder: (context, controller, _) {
        final status = controller.getLiveBroadcastStatus();
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.backgroundDark.withValues(alpha: 0.7),
            border: Border.all(color: AppTheme.neonCyan, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📡 LIVE BROADCAST STATUS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonCyan,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Active',
                      value: '${status['activeBroadcasts']}',
                      icon: '🔴',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Reach',
                      value: '${status['totalReach']}',
                      icon: '🌍',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Engagement',
                      value: '${status['expectedEngagement']}',
                      icon: '⚡',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (status['platforms'] as List<String>)
                      .map(
                        (platform) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _buildPlatformChip(platform),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(
          color: AppTheme.neonPurple.withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.neonCyan,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformChip(String platform) {
    final config = MetaverseAdCampaignEngine.getPlatformConfig(platform);
    if (config == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.neonPurple.withValues(alpha: 0.3),
        border: Border.all(color: AppTheme.neonCyan),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(config.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            config.platform,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCampaigns() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark.withValues(alpha: 0.5),
        border: Border.all(color: AppTheme.neonPurple),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 ACTIVE CAMPAIGNS BY PLATFORM',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.neonPurple,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              'roblox',
              'fortnite',
              'decentraland',
              'sandbox',
              'horizon',
            ].map(_buildPlatformCampaignRow).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCampaignRow(String platform) {
    final config = MetaverseAdCampaignEngine.getPlatformConfig(platform);
    if (config == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black26,
          border: Border.all(
            color: AppTheme.neonCyan.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(config.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.platform,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        config.format,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.2),
                    border: Border.all(color: AppTheme.neonGreen),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neonGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audience',
                        style: TextStyle(fontSize: 9, color: Colors.white54),
                      ),
                      Text(
                        config.audienceLimit,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(fontSize: 9, color: Colors.white54),
                      ),
                      Text(
                        config.maxDuration,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neonPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Magnifier',
                        style: TextStyle(fontSize: 9, color: Colors.white54),
                      ),
                      Text(
                        '2.5x - 4.0x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRebroadcastButton() {
    return Consumer<MetaverseContentRebroadcastController>(
      builder: (context, controller, _) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(
              parent: _slideController,
              curve: Curves.easeOutBack,
            ),
          ),
          child: GestureDetector(
            onTap: controller.isProcessing
                ? null
                : () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final result = await controller.executeCycle();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(result.summaryText),
                          duration: const Duration(seconds: 5),
                          backgroundColor: AppTheme.backgroundDark,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.neonGreen.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      );
                    }
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: controller.isProcessing
                      ? [
                          Colors.grey.withValues(alpha: 0.5),
                          Colors.grey.withValues(alpha: 0.3),
                        ]
                      : [
                          AppTheme.neonGreen.withValues(alpha: 0.8),
                          AppTheme.neonCyan.withValues(alpha: 0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: controller.isProcessing
                      ? Colors.grey
                      : AppTheme.neonGreen,
                  width: 2,
                ),
                boxShadow: !controller.isProcessing
                    ? [
                        BoxShadow(
                          color: AppTheme.neonGreen.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.isProcessing)
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    const Text('🚀', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(
                    controller.isProcessing
                        ? 'EXECUTING CYCLE...'
                        : 'EXECUTE RE-BROADCAST CYCLE',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
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
