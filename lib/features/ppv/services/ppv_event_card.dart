import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_panel.dart';
import '../../../shared/widgets/dfc_network_image.dart';

class PpvEventCard extends StatelessWidget {
  final String eventId;
  final String title;
  final String posterUrl;

  const PpvEventCard({
    super.key,
    required this.eventId,
    required this.title,
    required this.posterUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: GestureDetector(
        onTap: () => context.push('/ppv-detail/$eventId'),
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: DfcNetworkImage(url: posterUrl, width: 140),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.neonCyan,
                    fontSize: 12,
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
}
