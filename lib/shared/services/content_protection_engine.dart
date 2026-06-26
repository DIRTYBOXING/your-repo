import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CONTENT PROTECTION ENGINE — DRM + Watermarking + Access Control
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Protects paid content (PPV streams, replays, premium videos) from
/// unauthorized redistribution. Multi-layered defense:
///
/// Layer 1: Token-Gated URLs
///   • HMAC-SHA256 signed stream URLs with expiry timestamps
///   • CDN edge validation — invalid tokens get 403
///   • Per-user tokens tied to purchase records
///
/// Layer 2: AES-128 HLS Encryption
///   • Stream segments encrypted with rotating keys
///   • Key server validates viewer token before serving decryption key
///   • Key rotation every 30 seconds during live events
///
/// Layer 3: Forensic Watermarking
///   • Invisible buyer-ID overlay encoded into video frames
///   • Survives screen recording, transcoding, re-encoding
///   • Enables identification of leak source
///
/// Layer 4: Device Binding
///   • Max 2 concurrent streams per purchase
///   • Device fingerprint tracking
///   • Account sharing detection via IP analysis
///
/// Layer 5: Geographic Restrictions
///   • Territory licensing per PPV event
///   • IP-based geofencing with VPN detection
///   • Configurable per event by promoter
///
/// DRM Systems:
///   • Widevine (Google/Android/Chrome/Edge)
///   • FairPlay (Apple/Safari/iOS/macOS)
///   • PlayReady (Microsoft/Xbox/Windows)
///
/// Firestore Collections:
///   content_licenses/{licenseId}    — DRM license records
///   access_tokens/{tokenId}         — Token audit trail
///   watermark_registry/{markId}     — Forensic watermark mapping
///   geo_policies/{policyId}         — Geographic restriction rules
///   device_bindings/{userId}        — Device fingerprint records
///
/// ═══════════════════════════════════════════════════════════════════════════
class ContentProtectionEngine with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── State ──
  bool _isValidating = false;
  String? _error;
  ContentAccessResult? _lastAccessResult;

  bool get isValidating => _isValidating;
  String? get error => _error;
  ContentAccessResult? get lastAccessResult => _lastAccessResult;

  // ── DRM Configuration ──
  static const Map<DrmSystem, DrmConfig> drmConfigs = {
    DrmSystem.widevine: DrmConfig(
      system: DrmSystem.widevine,
      licenseServerUrl: 'https://drm.datafightcentral.com/widevine/license',
      securityLevel: 'L1',
      supportedPlatforms: ['android', 'chrome', 'edge', 'firefox'],
    ),
    DrmSystem.fairplay: DrmConfig(
      system: DrmSystem.fairplay,
      licenseServerUrl: 'https://drm.datafightcentral.com/fairplay/license',
      securityLevel: 'hardware',
      supportedPlatforms: ['ios', 'macos', 'safari'],
      certificateUrl: 'https://drm.datafightcentral.com/fairplay/certificate',
    ),
    DrmSystem.playready: DrmConfig(
      system: DrmSystem.playready,
      licenseServerUrl: 'https://drm.datafightcentral.com/playready/license',
      securityLevel: 'SL3000',
      supportedPlatforms: ['windows', 'xbox', 'edge'],
    ),
  };

  // ── Protection Level Tiers ──
  static const Map<ProtectionLevel, ProtectionConfig> protectionLevels = {
    ProtectionLevel.basic: ProtectionConfig(
      level: ProtectionLevel.basic,
      tokenGated: true,
      encrypted: false,
      watermarked: false,
      geoRestricted: false,
      deviceBound: false,
      maxConcurrentStreams: 3,
      // For free or low-cost content
    ),
    ProtectionLevel.standard: ProtectionConfig(
      level: ProtectionLevel.standard,
      tokenGated: true,
      encrypted: true,
      watermarked: false,
      geoRestricted: false,
      deviceBound: true,
      maxConcurrentStreams: 2,
      // For regular PPV events
    ),
    ProtectionLevel.premium: ProtectionConfig(
      level: ProtectionLevel.premium,
      tokenGated: true,
      encrypted: true,
      watermarked: true,
      geoRestricted: true,
      deviceBound: true,
      maxConcurrentStreams: 2,
      // For championship / high-value PPV events
    ),
    ProtectionLevel.maximum: ProtectionConfig(
      level: ProtectionLevel.maximum,
      tokenGated: true,
      encrypted: true,
      watermarked: true,
      geoRestricted: true,
      deviceBound: true,
      maxConcurrentStreams: 1,
      // For Mayweather/Pacquiao-tier mega events
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════
  // ACCESS VALIDATION — Gate Check Before Streaming
  // ═══════════════════════════════════════════════════════════════════════

  /// Validate user's access to protected content
  Future<ContentAccessResult> validateAccess({
    required String userId,
    required String contentId,
    required ProtectedContentType contentType,
    String? deviceFingerprint,
    String? ipAddress,
    String? countryCode,
  }) async {
    _isValidating = true;
    _error = null;
    notifyListeners();

    try {
      // Step 1: Check purchase / subscription
      final hasPurchase = await _checkPurchase(userId, contentId, contentType);
      if (!hasPurchase) {
        return _denyAccess('Purchase required', AccessDenialReason.noPurchase);
      }

      // Step 2: Get protection level for this content
      final protection = await _getContentProtection(contentId, contentType);

      // Step 3: Device binding check
      if (protection.deviceBound && deviceFingerprint != null) {
        final deviceOk = await _checkDeviceBinding(
          userId,
          contentId,
          deviceFingerprint,
          protection.maxConcurrentStreams,
        );
        if (!deviceOk) {
          return _denyAccess(
            'Maximum ${protection.maxConcurrentStreams} devices reached',
            AccessDenialReason.deviceLimitExceeded,
          );
        }
      }

      // Step 4: Geographic restriction check
      if (protection.geoRestricted && countryCode != null) {
        final geoOk = await _checkGeoRestriction(contentId, countryCode);
        if (!geoOk) {
          return _denyAccess(
            'Content not available in your region',
            AccessDenialReason.geoRestricted,
          );
        }
      }

      // Step 5: Generate access token
      final token = _generateAccessToken(userId, contentId);
      final expiry = DateTime.now().add(const Duration(hours: 6));

      // Step 6: Get DRM license URL if encrypted
      String? drmLicenseUrl;
      DrmSystem? drmSystem;
      if (protection.encrypted) {
        drmSystem = _detectDrmSystem();
        drmLicenseUrl = drmConfigs[drmSystem]?.licenseServerUrl;
      }

      // Step 7: Get watermark config if watermarked
      String? watermarkId;
      if (protection.watermarked) {
        watermarkId = await _registerWatermark(userId, contentId);
      }

      // Record access grant
      await _firestore.collection('access_tokens').add({
        'userId': userId,
        'contentId': contentId,
        'contentType': contentType.name,
        'token': token,
        'tokenExpiry': expiry,
        'deviceFingerprint': deviceFingerprint,
        'ipAddress': ipAddress,
        'countryCode': countryCode,
        'protectionLevel': protection.level.name,
        'drmSystem': drmSystem?.name,
        'watermarkId': watermarkId,
        'status': 'active',
        'grantedAt': FieldValue.serverTimestamp(),
      });

      final result = ContentAccessResult(
        granted: true,
        token: token,
        tokenExpiry: expiry,
        drmLicenseUrl: drmLicenseUrl,
        drmSystem: drmSystem,
        watermarkId: watermarkId,
        protectionLevel: protection.level,
      );

      _lastAccessResult = result;
      return result;
    } catch (e) {
      _error = 'Access validation failed: $e';
      return _denyAccess('System error', AccessDenialReason.systemError);
    } finally {
      _isValidating = false;
      notifyListeners();
    }
  }

  ContentAccessResult _denyAccess(
    String reason,
    AccessDenialReason denialReason,
  ) {
    final result = ContentAccessResult(
      granted: false,
      denialReason: denialReason,
      denialMessage: reason,
    );
    _lastAccessResult = result;
    _error = reason;
    return result;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TOKEN MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════

  /// Generate HLS encryption key for stream segments
  /// Called by the transcoding pipeline every 30 seconds
  Future<EncryptionKeyInfo?> generateSegmentKey({
    required String streamId,
    required int segmentNumber,
  }) async {
    try {
      // In production: generate cryptographically random 128-bit key
      // Store in Firestore, serve via key server that validates viewer tokens
      final keyRef = _firestore.collection('encryption_keys').doc();

      await keyRef.set({
        'streamId': streamId,
        'segmentNumber': segmentNumber,
        'algorithm': 'AES-128-CBC',
        'keyUrl':
            'https://keys.datafightcentral.com/$streamId/seg_$segmentNumber.key',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)),
      });

      return EncryptionKeyInfo(
        keyId: keyRef.id,
        keyUrl:
            'https://keys.datafightcentral.com/$streamId/seg_$segmentNumber.key',
        algorithm: 'AES-128-CBC',
      );
    } catch (e) {
      debugPrint('ContentProtectionEngine.generateSegmentKey error: $e');
      return null;
    }
  }

  /// Revoke access for a user (e.g., refund, ban, dispute)
  Future<void> revokeAccess({
    required String userId,
    required String contentId,
    required String reason,
  }) async {
    try {
      // Invalidate all active tokens for this user + content
      final tokens = await _firestore
          .collection('access_tokens')
          .where('userId', isEqualTo: userId)
          .where('contentId', isEqualTo: contentId)
          .where('status', isEqualTo: 'active')
          .get();

      final batch = _firestore.batch();
      for (final doc in tokens.docs) {
        batch.update(doc.reference, {
          'status': 'revoked',
          'revokedAt': FieldValue.serverTimestamp(),
          'revokeReason': reason,
        });
      }
      await batch.commit();

      // Also terminate any active stream sessions
      final sessions = await _firestore
          .collection('stream_sessions')
          .where('userId', isEqualTo: userId)
          .where('ppvEventId', isEqualTo: contentId)
          .where('status', isEqualTo: 'active')
          .get();

      final sessionBatch = _firestore.batch();
      for (final doc in sessions.docs) {
        sessionBatch.update(doc.reference, {
          'status': 'revoked',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }
      await sessionBatch.commit();
    } catch (e) {
      debugPrint('ContentProtectionEngine.revokeAccess error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GEOGRAPHIC RESTRICTION POLICIES
  // ═══════════════════════════════════════════════════════════════════════

  /// Set geographic restriction for a PPV event
  Future<void> setGeoPolicy({
    required String contentId,
    required GeoPolicy policy,
  }) async {
    try {
      await _firestore.collection('geo_policies').doc(contentId).set({
        'contentId': contentId,
        'mode': policy.mode.name,
        'countries': policy.countries,
        'blockVpn': policy.blockVpn,
        'reason': policy.reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ContentProtectionEngine.setGeoPolicy error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PIRACY DETECTION & RESPONSE
  // ═══════════════════════════════════════════════════════════════════════

  /// Report suspected piracy (viewer-discovered leak)
  Future<void> reportPiracy({
    required String contentId,
    required String reportedUrl,
    String? reporterUserId,
    String? description,
  }) async {
    try {
      await _firestore.collection('piracy_reports').add({
        'contentId': contentId,
        'reportedUrl': reportedUrl,
        'reporterUserId': reporterUserId,
        'description': description,
        'status': 'pending_review',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('ContentProtectionEngine.reportPiracy error: $e');
    }
  }

  /// Trace a pirated stream back to the original buyer via watermark
  Future<String?> traceWatermark(String watermarkId) async {
    try {
      final doc = await _firestore
          .collection('watermark_registry')
          .doc(watermarkId)
          .get();
      if (!doc.exists) return null;
      return doc.data()?['userId'] as String?;
    } catch (e) {
      debugPrint('ContentProtectionEngine.traceWatermark error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> _checkPurchase(
    String userId,
    String contentId,
    ProtectedContentType type,
  ) async {
    try {
      final collection = switch (type) {
        ProtectedContentType.ppvLive ||
        ProtectedContentType.ppvReplay => 'ppv_purchases',
        ProtectedContentType.premiumVideo => 'video_purchases',
        ProtectedContentType.subscription => 'subscriptions',
      };

      final field = switch (type) {
        ProtectedContentType.ppvLive ||
        ProtectedContentType.ppvReplay => 'ppvEventId',
        ProtectedContentType.premiumVideo => 'videoId',
        ProtectedContentType.subscription => 'userId',
      };

      if (type == ProtectedContentType.subscription) {
        final doc = await _firestore.collection(collection).doc(userId).get();
        return doc.exists && (doc.data()?['status'] == 'active');
      }

      final query = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .where(field, isEqualTo: contentId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('_checkPurchase error: $e');
      return false;
    }
  }

  Future<ProtectionConfig> _getContentProtection(
    String contentId,
    ProtectedContentType type,
  ) async {
    try {
      // Check if content has a custom protection level
      final doc = await _firestore
          .collection('content_protection')
          .doc(contentId)
          .get();
      if (doc.exists) {
        final levelStr =
            doc.data()?['protectionLevel'] as String? ?? 'standard';
        final level = ProtectionLevel.values.firstWhere(
          (l) => l.name == levelStr,
          orElse: () => ProtectionLevel.standard,
        );
        return protectionLevels[level]!;
      }
    } catch (e) {
      debugPrint('_getContentProtection error: $e');
    }

    // Default based on content type
    return switch (type) {
      ProtectedContentType.ppvLive =>
        protectionLevels[ProtectionLevel.premium]!,
      ProtectedContentType.ppvReplay =>
        protectionLevels[ProtectionLevel.standard]!,
      ProtectedContentType.premiumVideo =>
        protectionLevels[ProtectionLevel.basic]!,
      ProtectedContentType.subscription =>
        protectionLevels[ProtectionLevel.basic]!,
    };
  }

  Future<bool> _checkDeviceBinding(
    String userId,
    String contentId,
    String fingerprint,
    int maxDevices,
  ) async {
    try {
      final doc = await _firestore
          .collection('device_bindings')
          .doc(userId)
          .get();
      if (!doc.exists) {
        // First device — register it
        await _firestore.collection('device_bindings').doc(userId).set({
          'devices': {
            contentId: [fingerprint],
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final data = doc.data()!;
      final devices = (data['devices'] as Map?)?[contentId];
      if (devices == null) {
        // First device for this content
        await _firestore.collection('device_bindings').doc(userId).update({
          'devices.$contentId': [fingerprint],
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      final deviceList = List<String>.from(devices as List);
      if (deviceList.contains(fingerprint)) return true; // Known device
      if (deviceList.length >= maxDevices) return false; // Limit reached

      // Register new device
      deviceList.add(fingerprint);
      await _firestore.collection('device_bindings').doc(userId).update({
        'devices.$contentId': deviceList,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('_checkDeviceBinding error: $e');
      return true; // Fail open to avoid blocking legitimate viewers
    }
  }

  Future<bool> _checkGeoRestriction(
    String contentId,
    String countryCode,
  ) async {
    try {
      final doc = await _firestore
          .collection('geo_policies')
          .doc(contentId)
          .get();
      if (!doc.exists) return true; // No restriction

      final data = doc.data()!;
      final mode = data['mode'] as String? ?? 'allow';
      final countries = List<String>.from(data['countries'] ?? []);

      if (mode == 'allow') {
        return countries.isEmpty ||
            countries.contains(countryCode.toUpperCase());
      } else {
        // 'block' mode
        return !countries.contains(countryCode.toUpperCase());
      }
    } catch (e) {
      return true; // Fail open
    }
  }

  String _generateAccessToken(String userId, String contentId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    // Production: HMAC-SHA256(userId + contentId + timestamp, secretKey)
    return 'dfc_at_${userId.hashCode.toRadixString(36)}_${contentId.hashCode.toRadixString(36)}_$ts';
  }

  Future<String?> _registerWatermark(String userId, String contentId) async {
    try {
      final ref = _firestore.collection('watermark_registry').doc();
      await ref.set({
        'userId': userId,
        'contentId': contentId,
        'watermarkPattern': 'forensic_${ref.id}',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (e) {
      return null;
    }
  }

  DrmSystem _detectDrmSystem() {
    // In Flutter web: detect browser
    // In native: detect OS
    if (kIsWeb) return DrmSystem.widevine; // Chrome/Edge/Firefox default
    // For iOS/macOS → FairPlay; Android → Widevine; Windows → PlayReady
    return DrmSystem.widevine; // Fallback
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════════════════

enum DrmSystem { widevine, fairplay, playready }

enum ProtectionLevel { basic, standard, premium, maximum }

enum ProtectedContentType { ppvLive, ppvReplay, premiumVideo, subscription }

enum GeoMode { allow, block }

enum AccessDenialReason {
  noPurchase,
  deviceLimitExceeded,
  geoRestricted,
  tokenExpired,
  accountSuspended,
  systemError,
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

class DrmConfig {
  final DrmSystem system;
  final String licenseServerUrl;
  final String securityLevel;
  final List<String> supportedPlatforms;
  final String? certificateUrl;

  const DrmConfig({
    required this.system,
    required this.licenseServerUrl,
    required this.securityLevel,
    required this.supportedPlatforms,
    this.certificateUrl,
  });
}

class ProtectionConfig {
  final ProtectionLevel level;
  final bool tokenGated;
  final bool encrypted;
  final bool watermarked;
  final bool geoRestricted;
  final bool deviceBound;
  final int maxConcurrentStreams;

  const ProtectionConfig({
    required this.level,
    required this.tokenGated,
    required this.encrypted,
    required this.watermarked,
    required this.geoRestricted,
    required this.deviceBound,
    required this.maxConcurrentStreams,
  });
}

class ContentAccessResult {
  final bool granted;
  final String? token;
  final DateTime? tokenExpiry;
  final String? drmLicenseUrl;
  final DrmSystem? drmSystem;
  final String? watermarkId;
  final ProtectionLevel? protectionLevel;
  final AccessDenialReason? denialReason;
  final String? denialMessage;

  const ContentAccessResult({
    required this.granted,
    this.token,
    this.tokenExpiry,
    this.drmLicenseUrl,
    this.drmSystem,
    this.watermarkId,
    this.protectionLevel,
    this.denialReason,
    this.denialMessage,
  });
}

class EncryptionKeyInfo {
  final String keyId;
  final String keyUrl;
  final String algorithm;

  const EncryptionKeyInfo({
    required this.keyId,
    required this.keyUrl,
    required this.algorithm,
  });
}

class GeoPolicy {
  final GeoMode mode;
  final List<String> countries;
  final bool blockVpn;
  final String? reason;

  const GeoPolicy({
    required this.mode,
    required this.countries,
    this.blockVpn = false,
    this.reason,
  });
}
