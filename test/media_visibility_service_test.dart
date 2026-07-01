import 'package:flutter_test/flutter_test.dart';

import 'package:datafightcentral/core/constants/image_assets.dart';
import 'package:datafightcentral/shared/models/media_asset_model.dart';
import 'package:datafightcentral/shared/services/media_visibility_service.dart';

void main() {
  MediaAssetModel buildAsset({
    bool approved = true,
    MediaApprovalStatus approvalStatus = MediaApprovalStatus.approved,
    MediaSafetyStatus safetyStatus = MediaSafetyStatus.cleared,
  }) {
    final now = DateTime(2026);
    return MediaAssetModel(
      id: 'asset_1',
      uploaderId: 'user_1',
      entityType: 'event',
      entityId: 'event_1',
      kind: MediaAssetKind.poster,
      mediaType: MediaAssetType.image,
      downloadUrl: 'https://cdn.datafightcentral.test/poster.jpg',
      storagePath: 'media/event_1/poster.jpg',
      fileName: 'poster.jpg',
      fileType: 'image/jpeg',
      fileSizeBytes: 1024,
      rightsOwner: 'DFC',
      rightsType: MediaRightsType.owned,
      rightsDeclaration: 'owned',
      hashMd5: 'md5',
      hashSha256: 'sha256',
      approved: approved,
      approvalStatus: approvalStatus,
      safetyStatus: safetyStatus,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('MediaVisibilityService', () {
    test('accepts assets that are approved and cleared', () {
      expect(
        MediaVisibilityService.isApprovedForPublicUse(buildAsset()),
        isTrue,
      );
    });

    test('rejects assets that are flagged or not formally approved', () {
      expect(
        MediaVisibilityService.isApprovedForPublicUse(
          buildAsset(safetyStatus: MediaSafetyStatus.flagged),
        ),
        isFalse,
      );
      expect(
        MediaVisibilityService.isApprovedForPublicUse(
          buildAsset(
            approved: false,
            approvalStatus: MediaApprovalStatus.pendingReview,
          ),
        ),
        isFalse,
      );
    });

    test('only treats bundled assets as safe fallback urls', () {
      expect(
        MediaVisibilityService.isLocalAssetUrl(ImageAssets.fightPlaceholder),
        isTrue,
      );
      expect(
        MediaVisibilityService.isLocalAssetUrl(
          'https://cdn.datafightcentral.test/poster.jpg',
        ),
        isFalse,
      );
      expect(MediaVisibilityService.isLocalAssetUrl(''), isFalse);
      expect(MediaVisibilityService.isLocalAssetUrl(null), isFalse);
    });
  });
}
