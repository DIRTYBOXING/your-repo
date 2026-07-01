import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// MUX STREAMING SERVICE — Flutter ↔ Mux Cloud Function Bridge
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Connects the Flutter app to the Mux Cloud Functions:
///   • Create live streams (promoter flow)
///   • Get signed HLS playback URLs (viewer flow)
///   • Stream status monitoring (real-time via Firestore)
///   • VOD replay access (post-event)
///
/// Firestore Collections:
///   mux_streams/{docId}      — Live stream metadata + Mux IDs
///   mux_vod_assets/{assetId} — VOD assets auto-created from live
///
class MuxStreamingService {
  static final _functions = FirebaseFunctions.instanceFor(
    region: 'australia-southeast1',
  );
  static final _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════
  // CREATE LIVE STREAM (Promoter Flow)
  // ═══════════════════════════════════════════════════════════════════════

  /// Creates a Mux live stream for a PPV event.
  /// Returns connection details (RTMP URL + stream key) for OBS/vMix.
  static Future<MuxStreamConfig?> createLiveStream({
    required String ppvEventId,
    required String title,
    bool lowLatency = true,
    bool testMode = false,
  }) async {
    try {
      final muxResult = await _functions
          .httpsCallable('createMuxLiveStream')
          .call({
            'ppvEventId': ppvEventId,
            'title': title,
            'lowLatency': lowLatency,
            'testMode': testMode,
          });

      final muxData = muxResult.data as Map<String, dynamic>;
      if (muxData['error'] == null) {
        return MuxStreamConfig(
          streamDocId: muxData['streamDocId'] as String,
          muxStreamId: muxData['muxStreamId'] as String?,
          playbackId: muxData['playbackId'] as String?,
          streamKey: muxData['streamKey'] as String,
          rtmpIngestUrl: muxData['rtmpIngestUrl'] as String,
          srtIngestUrl: muxData['srtIngestUrl'] as String? ?? '',
          hlsPlaybackUrl: muxData['hlsPlaybackUrl'] as String? ?? '',
          latencyMode: muxData['latencyMode'] as String? ?? 'low',
          provider: 'mux',
          credentialDeliveryStatus:
              muxData['credentialDeliveryStatus'] as String? ?? 'not_attempted',
          credentialDeliveryRecipient:
              muxData['credentialDeliveryRecipient'] as String? ?? '',
          credentialDeliveryError:
              muxData['credentialDeliveryError'] as String?,
        );
      }

      debugPrint(
        'MuxStreamingService.createLiveStream error: ${muxData['error']}',
      );

      final allowFallback =
          AppConstants.webDemoMode || AppConstants.syntheticContentEnabled;
      if (!allowFallback) {
        // Real-mode: fail closed (no stub streams).
        return null;
      }

      final fallbackResult = await _functions
          .httpsCallable('createLiveStream')
          .call({
            'ppvEventId': ppvEventId,
            'title': title,
            'type': 'hls',
            'isPPV': true,
            'ppvPriceCents': 2999,
          });

      final fallbackData = fallbackResult.data as Map<String, dynamic>;
      if (fallbackData['error'] != null) {
        debugPrint(
          'MuxStreamingService.createLiveStream fallback failed: ${fallbackData['error']}',
        );
        return null;
      }

      return MuxStreamConfig(
        streamDocId: (fallbackData['streamId'] ?? '') as String,
        muxStreamId: null,
        playbackId: null,
        streamKey: fallbackData['streamKey'] as String,
        rtmpIngestUrl: fallbackData['rtmpIngestUrl'] as String,
        srtIngestUrl: '',
        hlsPlaybackUrl: fallbackData['hlsUrl'] as String? ?? '',
        latencyMode: 'rehearsal',
        provider: (fallbackData['provider'] as String?) ?? 'stub',
        credentialDeliveryStatus: 'not_attempted',
        credentialDeliveryRecipient: '',
        credentialDeliveryError: null,
      );
    } catch (e) {
      debugPrint('MuxStreamingService.createLiveStream error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GET SIGNED PLAYBACK URL (Viewer Flow)
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets a JWT-signed HLS playback URL for an authenticated viewer.
  /// Verifies PPV purchase on the server side before returning the URL.
  static Future<MuxPlaybackInfo?> getPlaybackUrl({
    String? streamDocId,
    String? ppvEventId,
  }) async {
    try {
      final result = await _functions.httpsCallable('getMuxPlaybackUrl').call({
        'streamDocId': ?streamDocId,
        'ppvEventId': ?ppvEventId,
      });

      final data = result.data as Map<String, dynamic>;
      if (data['error'] != null) {
        debugPrint('MuxStreamingService.getPlaybackUrl: ${data['error']}');
        return null;
      }

      return MuxPlaybackInfo(
        hlsUrl: data['hlsUrl'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
        status: data['status'] as String? ?? 'idle',
        latencyMode: data['latencyMode'] as String? ?? 'standard',
        expiresAt: data['expiresAt'] as String?,
      );
    } catch (e) {
      debugPrint('MuxStreamingService.getPlaybackUrl error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STREAM STATUS (Real-time via Firestore)
  // ═══════════════════════════════════════════════════════════════════════

  /// Streams real-time status updates for a Mux stream.
  /// Status values: 'idle' | 'active' | 'disabled'
  static Stream<MuxStreamStatus> watchStreamStatus(String streamDocId) {
    return _firestore
        .collection('mux_streams')
        .doc(streamDocId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return MuxStreamStatus.empty();
          final data = doc.data()!;
          return MuxStreamStatus(
            status: data['status'] as String? ?? 'idle',
            currentViewers: (data['currentViewers'] as num?)?.toInt() ?? 0,
            peakViewers: (data['peakViewers'] as num?)?.toInt() ?? 0,
            wentLiveAt: (data['wentLiveAt'] as Timestamp?)?.toDate(),
            endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
            vodStatus: data['vodStatus'] as String?,
            credentialDeliveryStatus:
                data['credentialDeliveryStatus'] as String? ?? 'not_attempted',
            credentialDeliveryRecipient:
                data['credentialDeliveryRecipient'] as String? ?? '',
            credentialDeliveryError: data['credentialDeliveryError'] as String?,
          );
        });
  }

  /// Find a Mux stream doc by PPV event ID.
  static Future<String?> findStreamDocId(String ppvEventId) async {
    final snap = await _firestore
        .collection('mux_streams')
        .where('ppvEventId', isEqualTo: ppvEventId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // VOD REPLAY
  // ═══════════════════════════════════════════════════════════════════════

  /// Gets a signed VOD replay URL (Mux auto-creates VOD from live streams).
  static Future<MuxPlaybackInfo?> getVodReplay(String ppvEventId) async {
    try {
      final result = await _functions.httpsCallable('getMuxVodReplay').call({
        'ppvEventId': ppvEventId,
      });

      final data = result.data as Map<String, dynamic>;
      if (data['error'] != null) {
        debugPrint('MuxStreamingService.getVodReplay: ${data['error']}');
        return null;
      }

      return MuxPlaybackInfo(
        hlsUrl: data['hlsUrl'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
        status: 'vod',
        latencyMode: 'standard',
        duration: (data['duration'] as num?)?.toDouble(),
      );
    } catch (e) {
      debugPrint('MuxStreamingService.getVodReplay error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DISABLE STREAM (Admin/Promoter)
  // ═══════════════════════════════════════════════════════════════════════

  static Future<bool> disableStream(String streamDocId) async {
    try {
      final result = await _functions.httpsCallable('disableMuxStream').call({
        'streamDocId': streamDocId,
      });
      final data = result.data as Map<String, dynamic>;
      return data['success'] == true;
    } catch (e) {
      debugPrint('MuxStreamingService.disableStream error: $e');
      return false;
    }
  }

  static Future<MuxCredentialDeliveryResult?> resendCredentialPack(
    String streamDocId,
  ) async {
    try {
      final result = await _functions
          .httpsCallable('resendMuxCredentialPack')
          .call({'streamDocId': streamDocId});
      final data = result.data as Map<String, dynamic>;
      if (data['error'] != null) {
        return MuxCredentialDeliveryResult(
          status: 'failed',
          recipient: data['credentialDeliveryRecipient'] as String? ?? '',
          error: data['error'] as String?,
        );
      }

      return MuxCredentialDeliveryResult(
        status: data['credentialDeliveryStatus'] as String? ?? 'not_attempted',
        recipient: data['credentialDeliveryRecipient'] as String? ?? '',
        error: data['credentialDeliveryError'] as String?,
      );
    } catch (e) {
      debugPrint('MuxStreamingService.resendCredentialPack error: $e');
      return MuxCredentialDeliveryResult(
        status: 'failed',
        recipient: '',
        error: e.toString(),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Connection config returned when a promoter creates a live stream.
/// Contains everything needed to configure OBS/vMix.
class MuxStreamConfig {
  final String streamDocId;
  final String? muxStreamId;
  final String? playbackId;
  final String streamKey;
  final String rtmpIngestUrl;
  final String srtIngestUrl;
  final String hlsPlaybackUrl;
  final String latencyMode;
  final String provider;
  final String credentialDeliveryStatus;
  final String credentialDeliveryRecipient;
  final String? credentialDeliveryError;

  const MuxStreamConfig({
    required this.streamDocId,
    required this.muxStreamId,
    required this.playbackId,
    required this.streamKey,
    required this.rtmpIngestUrl,
    required this.srtIngestUrl,
    required this.hlsPlaybackUrl,
    required this.latencyMode,
    required this.provider,
    required this.credentialDeliveryStatus,
    required this.credentialDeliveryRecipient,
    required this.credentialDeliveryError,
  });

  bool get isRehearsalMode => provider != 'mux';
  bool get credentialsSent => credentialDeliveryStatus == 'sent';

  String get credentialDeliveryLabel {
    switch (credentialDeliveryStatus) {
      case 'sent':
        return credentialDeliveryRecipient.isNotEmpty
            ? 'Sent to $credentialDeliveryRecipient'
            : 'Sent';
      case 'failed':
        return credentialDeliveryError?.isNotEmpty == true
            ? 'Delivery failed: $credentialDeliveryError'
            : 'Delivery failed';
      case 'skipped':
        return credentialDeliveryError?.isNotEmpty == true
            ? 'Delivery skipped: $credentialDeliveryError'
            : 'Delivery skipped';
      default:
        return 'Delivery pending';
    }
  }
}

/// Signed playback URL for a viewer.
class MuxPlaybackInfo {
  final String hlsUrl;
  final String thumbnailUrl;
  final String status;
  final String latencyMode;
  final String? expiresAt;
  final double? duration;

  const MuxPlaybackInfo({
    required this.hlsUrl,
    required this.thumbnailUrl,
    required this.status,
    required this.latencyMode,
    this.expiresAt,
    this.duration,
  });
}

class MuxCredentialDeliveryResult {
  final String status;
  final String recipient;
  final String? error;

  const MuxCredentialDeliveryResult({
    required this.status,
    required this.recipient,
    this.error,
  });

  bool get sent => status == 'sent';

  String get label {
    switch (status) {
      case 'sent':
        return recipient.isNotEmpty ? 'Sent to $recipient' : 'Sent';
      case 'failed':
        return error?.isNotEmpty == true
            ? 'Delivery failed: $error'
            : 'Delivery failed';
      case 'skipped':
        return error?.isNotEmpty == true
            ? 'Delivery skipped: $error'
            : 'Delivery skipped';
      default:
        return 'Delivery pending';
    }
  }
}

/// Real-time stream status from Firestore snapshots.
class MuxStreamStatus {
  final String status;
  final int currentViewers;
  final int peakViewers;
  final DateTime? wentLiveAt;
  final DateTime? endedAt;
  final String? vodStatus;
  final String credentialDeliveryStatus;
  final String credentialDeliveryRecipient;
  final String? credentialDeliveryError;

  const MuxStreamStatus({
    required this.status,
    required this.currentViewers,
    required this.peakViewers,
    this.wentLiveAt,
    this.endedAt,
    this.vodStatus,
    this.credentialDeliveryStatus = 'not_attempted',
    this.credentialDeliveryRecipient = '',
    this.credentialDeliveryError,
  });

  factory MuxStreamStatus.empty() => const MuxStreamStatus(
    status: 'unknown',
    currentViewers: 0,
    peakViewers: 0,
  );

  bool get isLive => status == 'active';
  bool get isIdle => status == 'idle';
  bool get hasVod => vodStatus == 'ready';

  String get credentialDeliveryLabel {
    switch (credentialDeliveryStatus) {
      case 'sent':
        return credentialDeliveryRecipient.isNotEmpty
            ? 'Sent to $credentialDeliveryRecipient'
            : 'Sent';
      case 'failed':
        return credentialDeliveryError?.isNotEmpty == true
            ? 'Delivery failed: $credentialDeliveryError'
            : 'Delivery failed';
      case 'skipped':
        return credentialDeliveryError?.isNotEmpty == true
            ? 'Delivery skipped: $credentialDeliveryError'
            : 'Delivery skipped';
      default:
        return 'Delivery pending';
    }
  }
}
