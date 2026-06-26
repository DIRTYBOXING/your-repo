import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class DfcPpvEventCard extends StatelessWidget {
  final String title;
  final String date;
  final String posterUrl;
  final VoidCallback onTap;

  const DfcPpvEventCard({
    super.key,
    required this.title,
    required this.date,
    required this.posterUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final allowAssetPosters =
        AppConstants.webDemoMode || AppConstants.syntheticContentEnabled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            // Poster thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: posterUrl.isNotEmpty
                  ? posterUrl.startsWith('assets/')
                        ? (allowAssetPosters
                              ? Image.asset(
                                  posterUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _placeholder(),
                                )
                              : _placeholder())
                        : Image.network(
                            posterUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(),
                          )
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            // Title + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.sports_mma, color: Colors.white38, size: 28),
    );
  }
}
