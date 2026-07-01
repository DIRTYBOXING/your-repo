import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/dfc_poster_frame.dart';

/// Renders server-populated OG metadata (from the fetchOgMetadata Cloud Function).
/// Falls back gracefully when individual OG fields are missing.
class OgPreviewCard extends StatelessWidget {
  final Map<String, dynamic> ogData;
  final VoidCallback? onTap;

  const OgPreviewCard({super.key, required this.ogData, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = ogData['og:title'] as String? ?? '';
    final description = ogData['og:description'] as String? ?? '';
    final imageUrl = ogData['og:image'] as String? ?? '';
    final siteName = ogData['og:site_name'] as String? ?? '';
    final url = ogData['og:url'] as String? ?? '';
    final domain = _extractDomain(url);

    if (title.isEmpty && description.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        decoration: BoxDecoration(
          color: DesignTokens.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OG Image
            if (imageUrl.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: DFCPosterFrame(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  borderRadius: BorderRadius.zero,
                  overlayGradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.12),
                    ],
                  ),
                  errorWidget: const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Domain / site name badge
                  if (domain.isNotEmpty || siteName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        siteName.isNotEmpty ? siteName : domain,
                        style: const TextStyle(
                          color: DesignTokens.neonCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Title
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDomain(String url) {
    if (url.isEmpty) return '';
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return '';
    }
  }
}
