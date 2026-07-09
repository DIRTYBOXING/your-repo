import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../shared/models/ppv_model.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV CLIP EXPORT SERVICE
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Handles video clip export, trimming, watermarking, and metadata for sharing.
///
/// Flow:
///   1. User selects clip range in editor (start_ms → end_ms)
///   2. Service generates watermarked MP4 with fighter names + round + event
///   3. Saves to app cache/documents
///   4. Passes file path to share handler
///   5. Metadata logged to Firestore for trending/recommendations
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVClipExportService {
  // ── Clip Export Models ──
  static const int defaultClipDurationSeconds = 15;
  static const int maxClipDurationSeconds = 60;
  static const String watermarkText = 'DATA FIGHT CENTRAL';

  /// Represents a clip selection from the playback
  class ClipSelection {
    /// Start position in milliseconds
    final int startMs;

    /// End position in milliseconds
    final int endMs;

    /// Associated PPV event
    final PPVEvent event;

    /// Fighter 1 name
    final String? fighter1Name;

    /// Fighter 2 name
    final String? fighter2Name;

    /// Current round (for context)
    final int round;

    /// Moment description (e.g., "KNOCKOUT", "TAKEDOWN", "SUBMISSION")
    final String? momentDescription;

    ClipSelection({
      required this.startMs,
      required this.endMs,
      required this.event,
      this.fighter1Name,
      this.fighter2Name,
      required this.round,
      this.momentDescription,
    });

    int get durationSeconds => (endMs - startMs) ~/ 1000;

    bool get isValidLength =>
        durationSeconds > 0 && durationSeconds <= maxClipDurationSeconds;

    String get formattedDuration {
      final seconds = durationSeconds;
      return '${seconds}s';
    }

    String get filename {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fighters =
          '${fighter1Name ?? "Fighter1"}_vs_${fighter2Name ?? "Fighter2"}'
              .replaceAll(' ', '_')
              .toLowerCase();
      return 'dfc_clip_${fighters}_r${round}_$timestamp.mp4';
    }

    /// Generate watermark text for clip overlay
    String get watermarkContent {
      final parts = [
        watermarkText,
        if (momentDescription != null) ' • $momentDescription',
        if (fighter1Name != null && fighter2Name != null)
          ' • $fighter1Name vs $fighter2Name',
        ' • Round $round',
      ];
      return parts.join();
    }
  }

  /// Represents the exported clip file with metadata
  class ExportedClip {
    /// Local file path to the MP4
    final String filePath;

    /// File size in bytes
    final int fileSizeBytes;

    /// Duration in seconds
    final int durationSeconds;

    /// Original clip selection data
    final ClipSelection selection;

    /// Timestamp when exported
    final DateTime exportedAt;

    /// Whether the clip has been shared
    bool isShared = false;

    /// Social platforms this clip has been shared to
    final List<String> sharedOn = [];

    ExportedClip({
      required this.filePath,
      required this.fileSizeBytes,
      required this.durationSeconds,
      required this.selection,
      required this.exportedAt,
    });

    /// Get file URL for local sharing
    File get file => File(filePath);

    /// Format file size for display
    String get formattedFileSize {
      final mb = fileSizeBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }

    /// Mark clip as shared on platform
    void markSharedOn(String platform) {
      isShared = true;
      if (!sharedOn.contains(platform)) {
        sharedOn.add(platform);
      }
    }
  }

  /// Create a clip from video controller
  /// NOTE: This is a placeholder — actual FFmpeg/video_trimmer integration needed
  Future<ExportedClip?> exportClip(
    ClipSelection clip, {
    VideoPlayerController? videoController,
    VoidCallback? onProgress,
  }) async {
    try {
      // Validate clip length
      if (!clip.isValidLength) {
        throw Exception(
          'Clip duration must be 1–60 seconds (got ${clip.durationSeconds}s)',
        );
      }

      // Step 1: Get output directory
      final outputDir = await getApplicationDocumentsDirectory();
      final clipFilePath = '${outputDir.path}/clips/${clip.filename}';

      // Create clips directory if it doesn't exist
      final clipsDir = Directory('${outputDir.path}/clips');
      if (!await clipsDir.exists()) {
        await clipsDir.create(recursive: true);
      }

      // Step 2: Use FFmpeg (or video_trimmer) to extract clip
      // TODO: Integrate ffmpeg_kit_flutter or similar
      // For now, this is a placeholder that logs the intended export
      debugPrint(
        '📹 [CLIP EXPORT] Exporting clip: ${clip.filename}\n'
        '  ├─ Duration: ${clip.formattedDuration}\n'
        '  ├─ Start: ${_formatMs(clip.startMs)}\n'
        '  ├─ End: ${_formatMs(clip.endMs)}\n'
        '  ├─ Watermark: ${clip.watermarkContent}\n'
        '  ├─ Event: ${clip.event.title}\n'
        '  └─ Output: $clipFilePath',
      );

      // Step 3: Create placeholder file (in production, FFmpeg would write here)
      final clipFile = File(clipFilePath);
      await clipFile.create(recursive: true);
      // Simulate file content
      await clipFile.writeAsBytes(Uint8List(0));

      // Step 4: Return exported clip metadata
      final exported = ExportedClip(
        filePath: clipFilePath,
        fileSizeBytes: await clipFile.length(),
        durationSeconds: clip.durationSeconds,
        selection: clip,
        exportedAt: DateTime.now(),
      );

      debugPrint('✅ [CLIP EXPORT] Export complete: ${exported.formattedFileSize}');

      return exported;
    } catch (e) {
      debugPrint('❌ [CLIP EXPORT] Error exporting clip: $e');
      return null;
    }
  }

  /// Log clip export to Firestore for trending/analytics
  Future<void> logClipExport(ExportedClip clip, String userId) async {
    try {
      // TODO: Integrate with Firestore
      // firestore.collection('clips').add({
      //   'userId': userId,
      //   'eventId': clip.selection.event.id,
      //   'momentType': clip.selection.momentDescription,
      //   'duration': clip.durationSeconds,
      //   'timestamp': FieldValue.serverTimestamp(),
      //   'fighters': {
      //     'fighter1': clip.selection.fighter1Name,
      //     'fighter2': clip.selection.fighter2Name,
      //   },
      // })

      debugPrint(
        '📊 [CLIP ANALYTICS] Logged clip export\n'
        '  ├─ Event: ${clip.selection.event.title}\n'
        '  ├─ Moment: ${clip.selection.momentDescription}\n'
        '  └─ Duration: ${clip.durationSeconds}s',
      );
    } catch (e) {
      debugPrint('❌ [CLIP EXPORT] Error logging to Firestore: $e');
    }
  }

  /// Delete cached clip file
  Future<void> deleteClip(ExportedClip clip) async {
    try {
      if (await clip.file.exists()) {
        await clip.file.delete();
        debugPrint('🗑️ [CLIP EXPORT] Deleted: ${clip.selection.filename}');
      }
    } catch (e) {
      debugPrint('❌ [CLIP EXPORT] Error deleting clip: $e');
    }
  }

  String _formatMs(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
