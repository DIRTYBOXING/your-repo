import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/design_tokens.dart';
import '../services/ppv_notification_service.dart';

/// PPV Notification Preferences Screen
/// Users can enable/disable specific alerts and save preferences
class PPVNotificationPreferencesScreen extends StatefulWidget {
  final String eventId;

  const PPVNotificationPreferencesScreen({super.key, required this.eventId});

  @override
  State<PPVNotificationPreferencesScreen> createState() =>
      _PPVNotificationPreferencesScreenState();
}

class _PPVNotificationPreferencesScreenState
    extends State<PPVNotificationPreferencesScreen> {
  final PPVNotificationService _notificationService = PPVNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _enableWalkoutAlerts = true;
  bool _enableMainEventAlerts = true;
  bool _enableRoundAlerts = true;
  bool _enableKOAlerts = true;
  bool _enableSubmissionAlerts = true;
  bool _enableDecisionAlerts = true;
  bool _useHapticFeedback = true;
  bool _useSoundAlerts = true;
  bool _fightModeEnabled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _requestNotificationPermission();
  }

  Future<void> _loadPreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await _firestore
          .collection('user_notification_prefs')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _enableWalkoutAlerts = doc.data()?['enableWalkoutAlerts'] ?? true;
          _enableMainEventAlerts = doc.data()?['enableMainEventAlerts'] ?? true;
          _enableRoundAlerts = doc.data()?['enableRoundAlerts'] ?? true;
          _enableKOAlerts = doc.data()?['enableKOAlerts'] ?? true;
          _enableSubmissionAlerts =
              doc.data()?['enableSubmissionAlerts'] ?? true;
          _enableDecisionAlerts = doc.data()?['enableDecisionAlerts'] ?? true;
          _useHapticFeedback = doc.data()?['useHapticFeedback'] ?? true;
          _useSoundAlerts = doc.data()?['useSoundAlerts'] ?? true;
          _fightModeEnabled = doc.data()?['fightModeEnabled'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await _notificationService.requestNotificationPermission();
    if (granted) {
      debugPrint('Notifications enabled');
    }
  }

  Future<void> _savePreferences() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final effectiveWalkoutAlerts = _fightModeEnabled
          ? true
          : _enableWalkoutAlerts;
      final effectiveMainEventAlerts = _fightModeEnabled
          ? true
          : _enableMainEventAlerts;
      final effectiveHaptics = _fightModeEnabled ? true : _useHapticFeedback;
      final effectiveSound = _fightModeEnabled ? true : _useSoundAlerts;

      await _firestore.collection('user_notification_prefs').doc(userId).set({
        'enableWalkoutAlerts': effectiveWalkoutAlerts,
        'enableMainEventAlerts': effectiveMainEventAlerts,
        'enableRoundAlerts': _enableRoundAlerts,
        'enableKOAlerts': _enableKOAlerts,
        'enableSubmissionAlerts': _enableSubmissionAlerts,
        'enableDecisionAlerts': _enableDecisionAlerts,
        'useHapticFeedback': effectiveHaptics,
        'useSoundAlerts': effectiveSound,
        'fightModeEnabled': _fightModeEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Subscribe to event alerts if any enabled
      if (effectiveWalkoutAlerts ||
          effectiveMainEventAlerts ||
          _enableRoundAlerts ||
          _enableKOAlerts ||
          _enableSubmissionAlerts ||
          _enableDecisionAlerts) {
        await _notificationService.subscribeToEventAlerts(widget.eventId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alerts saved! You\'re locked in!'),
            backgroundColor: Color(0xFF00FF88),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: const Color(0xFFFF3366),
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050A14),
        elevation: 0,
        title: const Text(
          '🔔 NEVER MISS ACTION',
          style: TextStyle(
            color: Color(0xFF00FF88),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF00F5FF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00FF88), width: 2),
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF050A14).withValues(alpha: 0.5),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚡ Adrenaline Mode',
                  style: TextStyle(
                    color: Color(0xFF00FF88),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Get vibration + sound alerts so you NEVER miss a walkout, main event, or finish. Your phone will shake when the action goes down.',
                  style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Alert Type Toggles
          const Text(
            'WHAT TO ALERT ME FOR:',
            style: TextStyle(
              color: Color(0xFF00F5FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Walkout Alerts
          _buildAlertToggle(
            icon: '🥊',
            title: 'Walkouts',
            subtitle: 'Fight is starting now',
            enabled: _enableWalkoutAlerts,
            onChanged: (value) {
              setState(() => _enableWalkoutAlerts = value);
            },
          ),
          const SizedBox(height: 12),

          // Main Event Alerts
          _buildAlertToggle(
            icon: '🔥',
            title: 'Main Event',
            subtitle: 'The headliner is live',
            enabled: _enableMainEventAlerts,
            onChanged: (value) {
              setState(() => _enableMainEventAlerts = value);
            },
          ),
          const SizedBox(height: 12),

          // Round Alerts
          _buildAlertToggle(
            icon: '🔔',
            title: 'Each Round',
            subtitle: 'Every round starts',
            enabled: _enableRoundAlerts,
            onChanged: (value) {
              setState(() => _enableRoundAlerts = value);
            },
          ),
          const SizedBox(height: 12),

          // KO Alerts
          _buildAlertToggle(
            icon: '💥',
            title: 'Knockouts',
            subtitle: 'Fight ends by KO/TKO',
            enabled: _enableKOAlerts,
            onChanged: (value) {
              setState(() => _enableKOAlerts = value);
            },
          ),
          const SizedBox(height: 12),

          // Submission Alerts
          _buildAlertToggle(
            icon: '🔒',
            title: 'Submissions',
            subtitle: 'Fight ends by tap',
            enabled: _enableSubmissionAlerts,
            onChanged: (value) {
              setState(() => _enableSubmissionAlerts = value);
            },
          ),
          const SizedBox(height: 12),

          // Decision Alerts
          _buildAlertToggle(
            icon: '🏆',
            title: 'Decisions',
            subtitle: 'Winner announced',
            enabled: _enableDecisionAlerts,
            onChanged: (value) {
              setState(() => _enableDecisionAlerts = value);
            },
          ),
          const SizedBox(height: 24),

          // Haptic & Sound Preferences
          const Text(
            'HOW TO ALERT ME:',
            style: TextStyle(
              color: Color(0xFF00F5FF),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          _buildAlertToggle(
            icon: '📳',
            title: 'Haptic Feedback',
            subtitle: 'Phone vibrates with intensity',
            enabled: _useHapticFeedback,
            onChanged: (value) {
              setState(() => _useHapticFeedback = value);
            },
          ),
          const SizedBox(height: 12),

          _buildAlertToggle(
            icon: '🔊',
            title: 'Sound Alerts',
            subtitle: 'Notification sounds',
            enabled: _useSoundAlerts,
            onChanged: (value) {
              setState(() => _useSoundAlerts = value);
            },
          ),
          const SizedBox(height: 12),

          _buildAlertToggle(
            icon: '⚡',
            title: 'Fight Mode',
            subtitle: 'Never miss walkout/main event with loud hype alerts',
            enabled: _fightModeEnabled,
            onChanged: (value) {
              setState(() {
                _fightModeEnabled = value;
                if (value) {
                  _enableWalkoutAlerts = true;
                  _enableMainEventAlerts = true;
                  _useHapticFeedback = true;
                  _useSoundAlerts = true;
                }
              });
            },
          ),
          if (_fightModeEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await _notificationService.triggerFightModeWalkoutPreview(
                        widget.eventId,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Walkout hype alert sent'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.campaign),
                    label: const Text('Test Walkout'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await _notificationService
                          .triggerFightModeMainEventPreview(widget.eventId);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Main event hype alert sent'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Test Main'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: _isSaving ? null : _savePreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF88),
              foregroundColor: const Color(0xFF050A14),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(_isSaving ? 'SAVING...' : '✅ SAVE & ACTIVATE'),
          ),
          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00F5FF)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF050A14).withValues(alpha: 0.3),
            ),
            child: const Text(
              'Your settings are saved to your account. These alerts will work even if you close the app. Turn your sound ON for critical fight alerts.',
              style: TextStyle(
                color: Color(0xFF00F5FF),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAlertToggle({
    required String icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: enabled ? const Color(0xFF00FF88) : const Color(0x80FFFFFF),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(8),
        color: enabled
            ? const Color(0xFF00FF88).withValues(alpha: 0.1)
            : const Color(0xFF050A14).withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: DesignTokens.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF00FF88),
            inactiveThumbColor: const Color(0x80FFFFFF),
            inactiveTrackColor: const Color(0xFF050A14).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
