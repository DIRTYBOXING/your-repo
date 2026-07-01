// lib/shared/services/share_service.dart
//
// Centralised helper for sharing DFC content via the OS share sheet.
// This powers the "share to social media" flow across FightWire posts,
// AI fight cards, FightLab insights, and more.
//
// Integration: the app already has `share_plus` in pubspec.yaml.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_constants.dart';

/// ShareService provides a friendly wrapper around share_plus with
/// DFC-specific caption templates.
class ShareService {
  ShareService._();
  static final instance = ShareService._();

  /// Base URL for deep-linking back into DFC web.
  static const String baseUrl = AppConstants.publicWebBaseUrl;

  // ─────────────────────────────────────────────────────────────────────────
  // POSTS
  // ─────────────────────────────────────────────────────────────────────────
  /// Share a FightWire/social post.
  Future<void> sharePost({
    required String postId,
    required String authorDisplayName,
    required String contentPreview,
  }) async {
    final url = '$baseUrl/post/$postId';
    final text =
        '$authorDisplayName on DataFightCentral:\n\n'
        '${_truncate(contentPreview, 200)}\n\n'
        '$url\n\n#DataFightCentral #FightWire';

    await _share(text, subject: 'Check out this post on DataFightCentral');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIGHT CARDS (promoter event cards)
  // ─────────────────────────────────────────────────────────────────────────
  /// Share an event fight card.
  Future<void> shareFightCard({
    required String cardId,
    required String eventName,
    String? dateStr,
    String? venue,
  }) async {
    final url = '$baseUrl/fightcard/$cardId';
    final datePart = dateStr != null ? '📅 $dateStr\n' : '';
    final venuePart = venue != null ? '📍 $venue\n' : '';
    final text =
        '🥊 FIGHT CARD: $eventName\n'
        '$datePart$venuePart\n'
        '$url\n\n#DataFightCentral #FightCard';

    await _share(text, subject: '$eventName – Fight Card');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // AI COLLECTIBLE CARDS
  // ─────────────────────────────────────────────────────────────────────────
  /// Share an AI-generated collectible card (from AI Card Producer).
  Future<void> shareCollectibleCard({
    required String fighterName,
    String? division,
    String? record,
  }) async {
    final divPart = division != null && division.isNotEmpty
        ? ' • $division'
        : '';
    final recPart = record != null && record.isNotEmpty ? ' ($record)' : '';

    final text =
        '🎴 $fighterName$divPart$recPart\n\n'
        'Collectible card created with DataFightCentral AI Card Producer.\n\n'
        '$baseUrl/cards\n\n#DataFightCentral #AICard #FighterCard';

    await _share(text, subject: '$fighterName – Collectible Card');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIGHTLAB INSIGHTS
  // ─────────────────────────────────────────────────────────────────────────
  /// Share a Shido FightLab insight or readiness snapshot.
  Future<void> shareFightLabInsight({
    required String insightText,
    int? readinessScore,
  }) async {
    final scorePart = readinessScore != null
        ? '⚡ Readiness: $readinessScore%\n'
        : '';
    final text =
        '🥋 Samurai Shido – FightLab\n\n'
        '$scorePart$insightText\n\n'
        '$baseUrl/fightlab\n\n#DataFightCentral #FightLab #AICoach';

    await _share(text, subject: 'FightLab Insight');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GENERIC URL SHARE
  // ─────────────────────────────────────────────────────────────────────────
  /// Share an arbitrary text + URL (fallback).
  Future<void> shareGeneric({required String text, String? subject}) async {
    await _share(text, subject: subject ?? 'DataFightCentral');
  }

  /// Share generated PNG bytes as an image file when the platform supports it.
  Future<void> shareImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    final fallbackText = text ?? subject ?? 'Shared from DataFightCentral';

    if (kIsWeb) {
      await _share(fallbackText, subject: subject ?? 'DataFightCentral');
      return;
    }

    try {
      final safeName = _sanitizeFileName(fileName);
      final tempDir = await Directory.systemTemp.createTemp('dfc_share_');
      final file = File(p.join(tempDir.path, safeName));

      await file.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
          files: [XFile(file.path, mimeType: 'image/png', name: safeName)],
        ),
      );
    } catch (e) {
      debugPrint(
        'ShareService: image share failed ($e), falling back to clipboard/text',
      );
      await _share(fallbackText, subject: subject ?? 'DataFightCentral');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen)}…';
  }

  String _sanitizeFileName(String fileName) {
    final normalized = fileName.trim().isEmpty ? 'dfc-share.png' : fileName;
    final cleaned = normalized.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.toLowerCase().endsWith('.png') ? cleaned : '$cleaned.png';
  }

  Future<void> _share(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
    } catch (e) {
      // Fallback: copy to clipboard
      debugPrint('ShareService: share_plus failed ($e), copying to clipboard');
      try {
        await Clipboard.setData(ClipboardData(text: text));
      } catch (_) {}
    }
  }
}
