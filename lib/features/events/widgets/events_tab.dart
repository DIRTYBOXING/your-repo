import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/image_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/neon_card.dart';
import '../../../shared/widgets/dfc_network_image.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _ev(
            context,
            'Hex Fight Series 27',
            'Mar 15, 2026',
            'Melbourne Pavilion',
            12,
            AppColors.neonRed,
            'demo-hex-27',
            ImageAssets.fightPlaceholder,
          ),
          const SizedBox(height: 12),
          _ev(
            context,
            'Eternal MMA 83',
            'Mar 28, 2026',
            'Gold Coast Convention Centre',
            8,
            AppColors.neonBlue,
            'demo-eternal-83',
            ImageAssets.ufcPlaceholder,
          ),
          const SizedBox(height: 12),
          _ev(
            context,
            'Brace MMA 73',
            'Apr 5, 2026',
            'Hordern Pavilion, Sydney',
            10,
            AppColors.neonOrange,
            'demo-brace-73',
            ImageAssets.kickboxingPlaceholder,
          ),
          const SizedBox(height: 12),
          _ev(
            context,
            'BKFC Fight Night Gold Coast',
            'Apr 19, 2026',
            'Gold Coast Sports Centre',
            6,
            AppColors.neonPurple,
            'demo-bkfc-gc',
            ImageAssets.bkfcPlaceholder,
          ),
        ],
      ),
    );
  }

  Widget _ev(
    BuildContext context,
    String t,
    String d,
    String loc,
    int f,
    Color c,
    String eventId,
    String posterAsset,
  ) {
    final resolvedPoster =
        ImageAssets.posterAssetForEventMetadataVariant(
          title: t,
          variant: 'preview',
        ) ??
        ImageAssets.posterVariantFromUrl(posterAsset, variant: 'preview');

    return NeonCard(
      glow: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: DfcNetworkImage(
              url: resolvedPoster,
              height: 120,
              width: double.infinity,
              errorWidget: Container(
                height: 120,
                color: c.withValues(alpha: 0.12),
                child: Center(child: Icon(Icons.event, size: 40, color: c)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.event, size: 24, color: c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(d, style: TextStyle(fontSize: 12, color: c)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$f fights',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: c,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                loc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/event/$eventId');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c,
                    side: BorderSide(color: c),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'View Card',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/event/$eventId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Tickets',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
