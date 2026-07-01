import '../../core/constants/image_assets.dart';
import 'ppv_model.dart';

enum PosterRenderMode { fullArtwork, generatedCard, embeddedArtwork }

enum PosterAssetKind { finalPoster, backgroundArt, generatedFallback }

class PPVPresentationModel {
  final String eventId;
  final String eventName;
  final DateTime eventDate;
  final String? posterUrl;
  final PosterAssetKind posterKind;
  final PosterRenderMode posterMode;
  final bool allowOverlayText;
  final bool metadataInsideImage;
  final List<String> fighters;
  final double price;
  final String currency;

  const PPVPresentationModel({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    this.posterUrl,
    required this.posterKind,
    required this.posterMode,
    required this.allowOverlayText,
    required this.metadataInsideImage,
    required this.fighters,
    required this.price,
    required this.currency,
  });

  bool get hasPoster => posterUrl != null && posterUrl!.isNotEmpty;

  bool get usesGeneratedLayout => posterMode == PosterRenderMode.generatedCard;

  bool get usesBareArtwork => posterMode == PosterRenderMode.embeddedArtwork;

  static PosterAssetKind _posterKindFromEvent(PPVEvent event) {
    final explicitKind = switch (event.posterAssetKind) {
      'finalPoster' => PosterAssetKind.finalPoster,
      'backgroundArt' => PosterAssetKind.backgroundArt,
      'generatedFallback' => PosterAssetKind.generatedFallback,
      _ => null,
    };
    if (explicitKind != null) {
      return explicitKind;
    }

    // Compatibility fallback until all ingested events are tagged.
    final posterUrl = event.posterUrl;
    if (posterUrl == null || posterUrl.isEmpty) {
      return PosterAssetKind.generatedFallback;
    }
    if (event.isFinalPoster) {
      return PosterAssetKind.finalPoster;
    }
    if (ImageAssets.isLocalAsset(posterUrl)) {
      return PosterAssetKind.generatedFallback;
    }
    return PosterAssetKind.finalPoster;
  }

  factory PPVPresentationModel.fromEvent(PPVEvent event) {
    final posterKind = _posterKindFromEvent(event);
    final posterMode = switch (posterKind) {
      PosterAssetKind.finalPoster => PosterRenderMode.fullArtwork,
      PosterAssetKind.backgroundArt => PosterRenderMode.embeddedArtwork,
      PosterAssetKind.generatedFallback => PosterRenderMode.generatedCard,
    };

    return PPVPresentationModel(
      eventId: event.id,
      eventName: event.title,
      eventDate: event.eventDate,
      posterUrl: event.posterUrl,
      posterKind: posterKind,
      posterMode: posterMode,
      allowOverlayText: posterMode != PosterRenderMode.fullArtwork,
      metadataInsideImage: posterMode == PosterRenderMode.fullArtwork,
      fighters: event.fightersNormalized,
      price: event.standardPrice,
      currency: event.currency,
    );
  }
}
