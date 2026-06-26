import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/design_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC APP REVIEW SERVICE — Smart review prompts (like real apps)
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Conditions to trigger (ALL must be true):
///   • User has opened the app 5+ times
///   • At least 7 days since install
///   • Has NOT already reviewed or dismissed 3 times
///   • Not shown in the last 30 days
///
/// Usage:
///   // Call on every app launch (HomeScreen initState):
///   DFCAppReviewService.trackLaunch();
///
///   // Check + show prompt (after a positive moment):
///   DFCAppReviewService.maybeShowPrompt(context);
/// ═══════════════════════════════════════════════════════════════════════════

class DFCAppReviewService {
  static const _keyLaunchCount = 'dfc_launch_count';
  static const _keyFirstLaunch = 'dfc_first_launch';
  static const _keyLastPrompt = 'dfc_last_review_prompt';
  static const _keyDismissCount = 'dfc_review_dismiss_count';
  static const _keyReviewed = 'dfc_has_reviewed';

  static const int _minLaunches = 5;
  static const int _minDaysSinceInstall = 7;
  static const int _maxDismissals = 3;
  static const int _cooldownDays = 30;

  /// Call on every app launch
  static Future<void> trackLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyLaunchCount) ?? 0) + 1;
    await prefs.setInt(_keyLaunchCount, count);

    if (!prefs.containsKey(_keyFirstLaunch)) {
      await prefs.setString(_keyFirstLaunch, DateTime.now().toIso8601String());
    }
  }

  /// Check conditions and show prompt if eligible
  static Future<void> maybeShowPrompt(BuildContext context) async {
    if (!context.mounted) return;
    final prefs = await SharedPreferences.getInstance();

    // Already reviewed? Never ask again.
    if (prefs.getBool(_keyReviewed) ?? false) return;

    // Too many dismissals?
    final dismissals = prefs.getInt(_keyDismissCount) ?? 0;
    if (dismissals >= _maxDismissals) return;

    // Not enough launches?
    final launches = prefs.getInt(_keyLaunchCount) ?? 0;
    if (launches < _minLaunches) return;

    // Not enough days since install?
    final firstLaunchStr = prefs.getString(_keyFirstLaunch);
    if (firstLaunchStr != null) {
      final firstLaunch = DateTime.tryParse(firstLaunchStr);
      if (firstLaunch != null &&
          DateTime.now().difference(firstLaunch).inDays <
              _minDaysSinceInstall) {
        return;
      }
    }

    // Cooldown since last prompt?
    final lastPromptStr = prefs.getString(_keyLastPrompt);
    if (lastPromptStr != null) {
      final lastPrompt = DateTime.tryParse(lastPromptStr);
      if (lastPrompt != null &&
          DateTime.now().difference(lastPrompt).inDays < _cooldownDays) {
        return;
      }
    }

    // All conditions met — show prompt
    if (!context.mounted) return;
    await prefs.setString(_keyLastPrompt, DateTime.now().toIso8601String());
    if (!context.mounted) return;
    _showReviewDialog(context, prefs);
  }

  static void _showReviewDialog(BuildContext context, SharedPreferences prefs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DesignTokens.neonCyan.withValues(alpha: 0.2)),
        ),
        title: const Text(
          'Enjoying DFC?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_mma,
              size: 48,
              color: DesignTokens.neonCyan.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your rating helps combat sports fans find DFC. '
              'Would you take a moment to rate us?',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              prefs.setInt(
                _keyDismissCount,
                (prefs.getInt(_keyDismissCount) ?? 0) + 1,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Not Now',
              style: TextStyle(
                color: DesignTokens.textMuted.withValues(alpha: 0.7),
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              prefs.setBool(_keyReviewed, true);
              Navigator.of(ctx).pop();
              // In production: use in_app_review or URL launch to store page
              // For now: mark as reviewed and show thank you
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thanks for your support! 🥊'),
                  backgroundColor: Color(0xFF00F5FF),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: DesignTokens.neonCyan,
              foregroundColor: DesignTokens.bgPrimary,
            ),
            child: const Text('Rate DFC'),
          ),
        ],
      ),
    );
  }
}
