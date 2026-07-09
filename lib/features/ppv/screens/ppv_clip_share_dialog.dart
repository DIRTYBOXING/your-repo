import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../services/ppv_clip_export_service.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PPV CLIP SHARE DIALOG
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Multi-platform sharing for exported clips:
///   1. DFC Platform (internal feed/creator dashboard)
///   2. TikTok (native share with prefill)
///   3. Instagram (native share with prefill)
///   4. Twitter/X (native share with text + URL)
///   5. Generic share (iOS/Android share sheet)
///
/// ═══════════════════════════════════════════════════════════════════════════

class PPVClipShareDialog extends StatefulWidget {
  /// Exported clip to share
  final PPVClipExportService.ExportedClip clip;

  /// User ID (for tracking who shared what)
  final String userId;

  /// Event title (for share text)
  final String eventTitle;

  /// Optional callback when share completes
  final Function(String platform)? onShareComplete;

  const PPVClipShareDialog({
    super.key,
    required this.clip,
    required this.userId,
    required this.eventTitle,
    this.onShareComplete,
  });

  @override
  State<PPVClipShareDialog> createState() => _PPVClipShareDialogState();
}

class _PPVClipShareDialogState extends State<PPVClipShareDialog> {
  bool _isSharing = false;
  String? _lastError;

  /// Share to DFC (internal)
  Future<void> _shareToDataFightCentral() async {
    _setSharing(true);
    try {
      final selection = widget.clip.selection;
      final text =
          'Check out this ${selection.momentDescription ?? 'highlight'} from ${selection.fighter1Name} vs ${selection.fighter2Name} • ${widget.eventTitle}';

      // In production, this would:
      // 1. Upload clip to DFC storage
      // 2. Create post in feed
      // 3. Pin to creator dashboard
      // 4. Notify followers
      debugPrint('🎬 [SHARE] Sharing to DATA FIGHT CENTRAL\n$text');

      widget.clip.markSharedOn('DFC');
      widget.onShareComplete?.call('DFC');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Clip posted to your DFC profile!'),
            backgroundColor: DesignTokens.neonGreen,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.black,
              onPressed: () {
                // Navigate to creator dashboard
                debugPrint('📱 Navigate to creator dashboard');
              },
            ),
          ),
        );

        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _setError('Failed to share to DFC: $e');
    } finally {
      _setSharing(false);
    }
  }

  /// Share to TikTok
  Future<void> _shareToTikTok() async {
    _setSharing(true);
    try {
      final selection = widget.clip.selection;
      final text =
          '#${selection.fighter1Name?.replaceAll(' ', '')} #${selection.fighter2Name?.replaceAll(' ', '')} #MMA #Combat #UFC';

      // TikTok native share (intent on Android, universal link on iOS)
      // TODO: Implement TikTok SDK or deep link
      final tiktokDeepLink = 'tiktok://post/create?text=$text'; // Placeholder

      if (await canLaunchUrl(Uri.parse(tiktokDeepLink))) {
        await launchUrl(Uri.parse(tiktokDeepLink));
      } else {
        // Fallback to generic share
        await Share.shareXFiles(
          [XFile(widget.clip.filePath)],
          text: text,
          subject:
              '${selection.momentDescription ?? "Highlight"} from ${widget.eventTitle}',
        );
      }

      widget.clip.markSharedOn('TikTok');
      widget.onShareComplete?.call('TikTok');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _setError('Failed to share to TikTok: $e');
    } finally {
      _setSharing(false);
    }
  }

  /// Share to Instagram
  Future<void> _shareToInstagram() async {
    _setSharing(true);
    try {
      final selection = widget.clip.selection;
      final hashtags =
          '#MMA #Combat #${selection.fighter1Name?.replaceAll(' ', '')} #${selection.fighter2Name?.replaceAll(' ', '')}';

      // Instagram native share (Reels format)
      // TODO: Implement Instagram SDK or deep link
      final instagramDeepLink =
          'instagram://post/create?caption=$hashtags'; // Placeholder

      if (await canLaunchUrl(Uri.parse(instagramDeepLink))) {
        await launchUrl(Uri.parse(instagramDeepLink));
      } else {
        // Fallback to generic share
        await Share.shareXFiles([
          XFile(widget.clip.filePath),
        ], text: 'Check out this moment from $hashtags\n${widget.eventTitle}');
      }

      widget.clip.markSharedOn('Instagram');
      widget.onShareComplete?.call('Instagram');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _setError('Failed to share to Instagram: $e');
    } finally {
      _setSharing(false);
    }
  }

  /// Share to Twitter/X
  Future<void> _shareToTwitter() async {
    _setSharing(true);
    try {
      final selection = widget.clip.selection;
      final text =
          '${selection.momentDescription ?? "Highlight"} from ${selection.fighter1Name} vs ${selection.fighter2Name} 🥊 ${widget.eventTitle}';

      // Twitter native share
      // TODO: Implement Twitter API v2 for media upload
      final twitterShareUrl =
          'https://twitter.com/intent/tweet?text=$text&url=https://app.datafightcentral.com';

      if (await canLaunchUrl(Uri.parse(twitterShareUrl))) {
        await launchUrl(Uri.parse(twitterShareUrl));
      } else {
        // Fallback to generic share
        await Share.shareXFiles([XFile(widget.clip.filePath)], text: text);
      }

      widget.clip.markSharedOn('Twitter');
      widget.onShareComplete?.call('Twitter');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _setError('Failed to share to Twitter: $e');
    } finally {
      _setSharing(false);
    }
  }

  /// Generic share (iOS/Android share sheet)
  Future<void> _shareGeneric() async {
    _setSharing(true);
    try {
      final selection = widget.clip.selection;
      final text =
          'Check out this moment from ${selection.fighter1Name} vs ${selection.fighter2Name}\n${widget.eventTitle}';

      await Share.shareXFiles(
        [XFile(widget.clip.filePath)],
        text: text,
        subject:
            '${selection.momentDescription ?? "Highlight"} from ${widget.eventTitle}',
      );

      widget.clip.markSharedOn('Other');
      widget.onShareComplete?.call('Other');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _setError('Failed to share: $e');
    } finally {
      _setSharing(false);
    }
  }

  void _setSharing(bool value) {
    if (mounted) {
      setState(() => _isSharing = value);
    }
  }

  void _setError(String error) {
    if (mounted) {
      setState(() => _lastError = error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: DesignTokens.neonRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.clip.selection;

    return Dialog(
      backgroundColor: const Color(0xFF030810),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─ Header ─
            Text(
              'SHARE CLIP',
              style: TextStyle(
                color: DesignTokens.neonCyan,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${selection.durationSeconds}s • ${selection.fighter1Name} vs ${selection.fighter2Name}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // ─ Platform Grid ─
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildPlatformButton(
                  label: 'DFC PROFILE',
                  icon: Icons.people,
                  color: DesignTokens.neonCyan,
                  onPressed: _shareToDataFightCentral,
                ),
                _buildPlatformButton(
                  label: 'TIKTOK',
                  icon: Icons.music_note,
                  color: const Color(0xFF000000),
                  onPressed: _shareToTikTok,
                ),
                _buildPlatformButton(
                  label: 'INSTAGRAM',
                  icon: Icons.photo,
                  color: const Color(0xFFE1306C),
                  onPressed: _shareToInstagram,
                ),
                _buildPlatformButton(
                  label: 'TWITTER',
                  icon: Icons.close,
                  color: const Color(0xFF000000),
                  onPressed: _shareToTwitter,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─ Generic Share ─
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSharing ? null : _shareGeneric,
                icon: const Icon(Icons.share),
                label: const Text('MORE OPTIONS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─ Close Button ─
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isSharing ? null : () => Navigator.pop(context),
                child: const Text(
                  'CLOSE',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSharing ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            color: color.withValues(alpha: 0.08),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
