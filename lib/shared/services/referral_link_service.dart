// ═══════════════════════════════════════════════════════════════════════════
// DFC REFERRAL LINK SERVICE
// ═══════════════════════════════════════════════════════════════════════════
// Generates UTM-tagged shareable links for events, the PPV store, and
// general DFC landing pages.  Every link embeds the promoter's referral
// code so clicks can be attributed and points can be awarded.
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'analytics_service.dart';

class ReferralLinkService {
  static const _baseUrl = 'https://datafightcentral.com';

  // ── Link generators ────────────────────────────────────────────────────

  /// Shareable link for a specific PPV / live event.
  String generateEventLink({
    required String eventId,
    required String refCode,
    String medium = 'promoter_share',
  }) {
    final encoded = Uri.encodeQueryComponent(refCode);
    return '$_baseUrl/ppv/store'
        '?utm_source=dfc'
        '&utm_medium=$medium'
        '&utm_campaign=event_share'
        '&ref=$encoded'
        '&eventId=${Uri.encodeQueryComponent(eventId)}';
  }

  /// Generic DFC store link (no specific event).
  String generateStoreLink({
    required String refCode,
    String medium = 'referral',
  }) {
    final encoded = Uri.encodeQueryComponent(refCode);
    return '$_baseUrl/ppv/store'
        '?utm_source=dfc'
        '&utm_medium=$medium'
        '&utm_campaign=promoter'
        '&ref=$encoded';
  }

  /// App-download / landing page link.
  String generateLandingLink({
    required String refCode,
    String medium = 'promoter_share',
  }) {
    final encoded = Uri.encodeQueryComponent(refCode);
    return '$_baseUrl'
        '?utm_source=dfc'
        '&utm_medium=$medium'
        '&utm_campaign=app_invite'
        '&ref=$encoded';
  }

  // ── Copy + track ───────────────────────────────────────────────────────

  /// Copies [url] to the clipboard, fires a [referral_click] analytics
  /// event, and shows a brief confirmation snackbar.
  Future<void> copyAndTrack({
    required BuildContext context,
    required String url,
    required String refCode,
    required AnalyticsService analytics,
    String? eventId,
    String medium = 'promoter_share',
  }) async {
    await Clipboard.setData(ClipboardData(text: url));
    await analytics.trackReferralClick(
      refCode: refCode,
      eventId: eventId,
      medium: medium,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UTM link copied to clipboard!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
