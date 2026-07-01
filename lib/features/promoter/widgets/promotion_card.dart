import 'package:flutter/material.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/promotion_model.dart';

class PromotionCard extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback? onTap;

  const PromotionCard({super.key, required this.promotion, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = promotion.status == PromotionStatus.active;
    final statusColor = isActive ? AppTheme.neonGreen : AppTheme.textMuted;

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Promotion hero image
            if (promotion.mediaUrl != null && promotion.mediaUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildPromotionImage(promotion.mediaUrl!),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  ImageAssets.eventPlaceholder,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 120,
                    color: AppTheme.cardBackground,
                    child: const Center(
                      child: Icon(
                        Icons.campaign,
                        color: AppTheme.neonCyan,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          promotion.status
                              .toString()
                              .split('.')
                              .last
                              .toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        promotion.type.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    promotion.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    promotion.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Metric(
                        label: 'IMPRESSIONS',
                        value: promotion.impressions.toString(),
                      ),
                      _Metric(
                        label: 'CLICKS',
                        value: promotion.clicks.toString(),
                      ),
                      _Metric(
                        label: 'CTR',
                        value:
                            '${(promotion.clicks / (promotion.impressions == 0 ? 1 : promotion.impressions) * 100).toStringAsFixed(1)}%',
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

  Widget _buildPromotionImage(String url) {
    if (url.startsWith('assets/') || url.startsWith('asset/')) {
      return Image.asset(
        url,
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          height: 140,
          color: AppTheme.cardBackground,
          child: const Center(
            child: Icon(Icons.campaign, color: AppTheme.neonCyan, size: 40),
          ),
        ),
      );
    }
    return Image.network(
      url,
      height: 140,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 140,
          color: AppTheme.cardBackground,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.neonCyan),
          ),
        );
      },
      errorBuilder: (_, _, _) => Container(
        height: 140,
        color: AppTheme.cardBackground,
        child: const Center(
          child: Icon(Icons.campaign, color: AppTheme.neonCyan, size: 40),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.neonCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
