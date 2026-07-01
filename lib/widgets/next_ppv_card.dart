import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/image_assets.dart';
import '../shared/widgets/dfc_network_image.dart';

class NextPpvCard extends StatelessWidget {
  final String title, location, broadcaster, posterUrl;
  final DateTime startTime;
  final VoidCallback onOpenDetails, onBuy;

  const NextPpvCard({
    super.key,
    required this.title,
    required this.startTime,
    required this.location,
    required this.broadcaster,
    required this.posterUrl,
    required this.onOpenDetails,
    required this.onBuy,
  });

  // Smart Parser: Extracts fighters if "vs" is in the title.
  // Otherwise, returns the whole title cleanly without "VS".
  List<String> get _parsedFighters {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains(' vs ')) {
      final parts = lowerTitle.split(' vs ');
      if (parts.length == 2) {
        return [parts[0].trim().toUpperCase(), parts[1].trim().toUpperCase()];
      }
    }
    return [title.toUpperCase(), ''];
  }

  @override
  Widget build(BuildContext context) {
    final fighters = _parsedFighters;
    final allowSyntheticPosters = AppConstants.syntheticContentEnabled;
    final trimmedPosterUrl = posterUrl.trim();
    final hasRealPosterUrl =
        trimmedPosterUrl.startsWith('http://') ||
        trimmedPosterUrl.startsWith('https://');

    final displayPosterUrl =
        (trimmedPosterUrl.isNotEmpty &&
            (allowSyntheticPosters || hasRealPosterUrl))
        ? ImageAssets.posterVariantFromUrl(trimmedPosterUrl, variant: 'banner')
        : '';

    return Card(
      color: const Color(0xFF1A1A1A),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (displayPosterUrl.isNotEmpty) // Event Poster
            SizedBox(
              height: 250,
              width: double.infinity,
              child: DfcNetworkImage(
                url: displayPosterUrl,
                errorWidget: Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'Poster Unavailable',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ),
            )
          else if (allowSyntheticPosters)
            // Demo-only generated fallback poster.
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade900,
                    Colors.black,
                    Colors.blue.shade900,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      fighters[0],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  if (fighters[1].isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        fighters[1],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black,
              child: const Center(
                child: Text(
                  'Poster Unavailable',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),

          // Bottom Details & Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${startTime.toLocal().toString().split('.')[0]} • $location',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: onBuy,
                      child: const Text('Secure Checkout'),
                    ),
                    ElevatedButton(
                      onPressed: onOpenDetails,
                      child: const Text('View Event'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
