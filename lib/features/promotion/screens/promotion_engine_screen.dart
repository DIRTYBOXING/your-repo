import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/services/promotion_sequence_service.dart';

/// Promotion Engine Screen — shows active campaigns, countdown sequences, and funnel steps.
class PromotionEngineScreen extends StatelessWidget {
  const PromotionEngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = PromotionSequenceService();
    final campaigns = svc.getDemoCampaigns();

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBackground,
        title: const Text(
          'Promotion Engine',
          style: TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppTheme.neonCyan),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(campaigns.length),
          const SizedBox(height: 16),
          ...campaigns.map(_buildCampaignCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonGreen.withValues(alpha: 0.12),
            AppTheme.neonCyan.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppTheme.neonGreen, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACTIVE CAMPAIGNS',
                style: TextStyle(
                  color: AppTheme.neonGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.4,
                ),
              ),
              Text(
                '$count campaigns running',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(PromotionCampaign campaign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campaign header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        campaign.type,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _progressBadge(campaign),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Steps
          ...campaign.steps.map(_buildStepRow),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _progressBadge(PromotionCampaign campaign) {
    final total = campaign.steps.length;
    final sent = campaign.sentCount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.neonGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$sent / $total sent',
        style: const TextStyle(
          color: AppTheme.neonGreen,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepRow(PromotionStep step) {
    final statusColor = switch (step.status) {
      PromotionStepStatus.sent => AppTheme.neonGreen,
      PromotionStepStatus.pending => Colors.white38,
      PromotionStepStatus.failed => AppTheme.neonMagenta,
    };
    final statusIcon = switch (step.status) {
      PromotionStepStatus.sent => Icons.check_circle,
      PromotionStepStatus.pending => Icons.radio_button_unchecked,
      PromotionStepStatus.failed => Icons.error_outline,
    };
    final typeIcon = switch (step.type) {
      PromotionStepType.announcement => Icons.notifications_active,
      PromotionStepType.spotlight => Icons.person,
      PromotionStepType.cardReveal => Icons.style,
      PromotionStepType.hypeReel => Icons.videocam,
      PromotionStepType.finalPush => Icons.flash_on,
      PromotionStepType.liveAlert => Icons.live_tv,
      PromotionStepType.replay => Icons.replay,
    };

    final date = step.scheduledAt;
    final dateStr =
        '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:00';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 10),
          Icon(typeIcon, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.label,
                  style: TextStyle(
                    color: step.status == PromotionStepStatus.sent
                        ? Colors.white54
                        : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: step.status == PromotionStepStatus.sent
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: Colors.white38,
                  ),
                ),
                Text(
                  step.description,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: step.platform
                      .map(
                        (p) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            p,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
