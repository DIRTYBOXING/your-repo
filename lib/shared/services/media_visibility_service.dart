import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/image_assets.dart';
import '../models/event_model.dart';
import '../models/media_asset_model.dart';

class MediaVisibilityService {
  MediaVisibilityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static bool isApprovedForPublicUse(MediaAssetModel asset) {
    return asset.approved &&
        asset.approvalStatus == MediaApprovalStatus.approved &&
        asset.safetyStatus != MediaSafetyStatus.blocked &&
        asset.safetyStatus != MediaSafetyStatus.flagged;
  }

  static bool isLocalAssetUrl(String? url) {
    return url != null && url.isNotEmpty && ImageAssets.isLocalAsset(url);
  }

  Future<List<MediaAssetModel>> getAssetsByIds(
    Iterable<String> assetIds,
  ) async {
    final normalizedIds = assetIds
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (normalizedIds.isEmpty) {
      return const <MediaAssetModel>[];
    }

    final assets = <MediaAssetModel>[];
    for (final assetId in normalizedIds) {
      final doc = await _firestore
          .collection('media_assets')
          .doc(assetId)
          .get();
      if (!doc.exists) {
        continue;
      }
      assets.add(MediaAssetModel.fromFirestore(doc));
    }
    return assets;
  }

  Future<List<String>> filterVisibleUrls({
    required List<String> assetIds,
    List<String> fallbackUrls = const [],
  }) async {
    final localFallbacks = fallbackUrls.where(isLocalAssetUrl).toList();
    if (assetIds.isEmpty) {
      return localFallbacks;
    }

    final assets = await getAssetsByIds(assetIds);
    final visibleUrls = assets
        .where(isApprovedForPublicUse)
        .map((asset) => asset.downloadUrl)
        .where((url) => url.isNotEmpty)
        .toList();

    if (visibleUrls.isNotEmpty) {
      return visibleUrls;
    }

    return localFallbacks;
  }

  Future<String?> resolvePrimaryVisibleUrl({
    String? preferredAssetId,
    List<String> assetIds = const [],
    String? fallbackUrl,
  }) async {
    if (preferredAssetId != null && preferredAssetId.isNotEmpty) {
      final assets = await getAssetsByIds([preferredAssetId]);
      if (assets.isNotEmpty && isApprovedForPublicUse(assets.first)) {
        return assets.first.downloadUrl;
      }
    }

    final visibleUrls = await filterVisibleUrls(
      assetIds: assetIds,
      fallbackUrls: fallbackUrl == null ? const <String>[] : [fallbackUrl],
    );

    return visibleUrls.isEmpty ? null : visibleUrls.first;
  }

  Future<bool> hasApprovedEventMedia(EventModel event) async {
    final posterMediaId = event.posterMediaId;
    if (posterMediaId == null || posterMediaId.isEmpty) {
      return false;
    }

    final assetIds = <String>{...event.mediaIds, posterMediaId}.toList();
    final assets = await getAssetsByIds(assetIds);
    if (assets.isEmpty) {
      return false;
    }

    MediaAssetModel? assetById(String assetId) {
      for (final asset in assets) {
        if (asset.id == assetId) {
          return asset;
        }
      }
      return null;
    }

    final posterAsset = assetById(posterMediaId);
    if (posterAsset == null || !isApprovedForPublicUse(posterAsset)) {
      return false;
    }

    final bannerUrl = event.primaryBannerUrl;
    if (bannerUrl == null || bannerUrl.isEmpty) {
      return false;
    }

    return assets.any(
      (asset) =>
          isApprovedForPublicUse(asset) && asset.downloadUrl == bannerUrl,
    );
  }

  Future<bool> hasApprovedEventMediaByEventId(String eventId) async {
    if (eventId.isEmpty) {
      return false;
    }

    final doc = await _firestore.collection('events').doc(eventId).get();
    if (!doc.exists) {
      return false;
    }

    return hasApprovedEventMedia(EventModel.fromFirestore(doc));
  }
}
