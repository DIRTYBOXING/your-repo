import 'package:flutter/foundation.dart';
import 'auto_feed_orchestrator_service.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// MetaService — Facebook & Instagram feed integration
///
/// Key rule:
///   Any content shared TO DFC by a promoter or account holder via
///   Facebook or Instagram is lawfully consented for promotional use.
///   Shared posters, event cards, and fight media are automatically
///   stamped as [sharedByOwner: true, promotionCleared: true] and
///   flow into the DFC auto feed for amplification.
/// ═══════════════════════════════════════════════════════════════════════
class MetaService {
  static final MetaService _instance = MetaService._internal();
  factory MetaService() => _instance;
  MetaService._internal();

  /// Ingest a piece of content that was voluntarily shared to DFC from
  /// a Facebook or Instagram account. The act of sharing constitutes
  /// the owner's consent for DFC to use the content for promotion.
  ///
  /// [platform] — 'facebook' or 'instagram'
  /// [sharedBy] — username or page name of the sharer
  /// [contentUrl] — URL of the original post
  /// [imageUrl] — poster/image URL (if available)
  /// [caption] — post caption or title
  /// [tags] — any hashtags or category tags
  AutoFeedItem ingestSharedContent({
    required String platform,
    required String sharedBy,
    required String contentUrl,
    String? imageUrl,
    String caption = '',
    List<String> tags = const [],
  }) {
    final id =
        '${platform}_${sharedBy}_${DateTime.now().millisecondsSinceEpoch}';
    final sourceLabel = platform == 'instagram'
        ? 'Instagram / $sharedBy'
        : 'Facebook / $sharedBy';

    debugPrint(
      '[MetaService] Ingesting shared content from $sourceLabel: $contentUrl',
    );

    return AutoFeedItem(
      id: id,
      title: caption.isNotEmpty ? caption : '$sharedBy shared on $platform',
      body: caption,
      source: sourceLabel,
      sourceType: FeedSourceType.partner,
      publishedAt: DateTime.now(),
      linkUrl: contentUrl,
      imageUrl: imageUrl,
      tags: [platform, 'shared', 'meta', ...tags],
      // Voluntarily shared to DFC — lawfully cleared for promotional use.
      sharedByOwner: true,
      promotionCleared: true,
      trustScore: 0.92,
      rankingWeight: 1.3,
      trustProfileKey: '${platform}_partner',
      commandSignals: ['shared_content', 'promotion_cleared', platform],
    );
  }

  /// Share a DFC achievement or event back out to Facebook/Instagram.
  /// This uses the device share sheet (share_plus) — no OAuth required.
  /// Pass the content to ShareService.shareGeneric() in the calling widget.
  String buildShareText({
    required String title,
    required String url,
    String hashtags = '#DataFightCentral #MMA #CombatSports',
  }) {
    return '$title\n$url\n$hashtags';
  }
}
