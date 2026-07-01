import 'package:flutter/material.dart';

/// Multi-Factor Authentication (MFA) — DFC Admin
/// Require MFA for all admin logins.
class MFASettingsPage extends StatefulWidget {
  const MFASettingsPage({super.key});

  @override
  State<MFASettingsPage> createState() => _MFASettingsPageState();
}

class _MFASettingsPageState extends State<MFASettingsPage> {
  bool _mfaRequired = true;
  bool _smsEnabled = true;
  bool _totpEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Multi-Factor Authentication',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (_mfaRequired ? Colors.green : Colors.orange).withValues(
                    alpha: 0.15,
                  ),
                  Colors.deepPurple.shade900.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (_mfaRequired ? Colors.green : Colors.orange).withValues(
                  alpha: 0.3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _mfaRequired ? Icons.verified_user : Icons.warning,
                  color: _mfaRequired ? Colors.green : Colors.orange,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mfaRequired
                            ? 'MFA Active — Admin Protected'
                            : 'MFA Disabled — Admin at Risk',
                        style: TextStyle(
                          color: _mfaRequired ? Colors.green : Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All admin logins require a second factor when enabled.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _toggle(
            'Require MFA for Admin',
            'All admin logins must verify via SMS or authenticator.',
            Icons.admin_panel_settings,
            _mfaRequired,
            (v) => setState(() => _mfaRequired = v),
          ),
          _toggle(
            'SMS Verification',
            'Send OTP to registered phone number on login.',
            Icons.sms,
            _smsEnabled,
            (v) => setState(() => _smsEnabled = v),
          ),
          _toggle(
            'TOTP Authenticator',
            'Google Authenticator or Authy time-based codes.',
            Icons.qr_code,
            _totpEnabled,
            (v) => setState(() => _totpEnabled = v),
          ),
          const SizedBox(height: 28),
          const Text(
            'MFA STATUS',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _statusRow(
            'Owner (ausstrainsnetwork@gmail.com)',
            'SMS verified',
            true,
          ),
          _statusRow('Last MFA challenge', '2026-03-27 09:15', true),
          _statusRow('Failed attempts (24h)', '0', true),
        ],
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      color: Colors.deepPurple.shade800.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.amber),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        value: value,
        activeThumbColor: Colors.green,
        onChanged: onChanged,
      ),
    );
  }

  Widget _statusRow(String label, String value, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.error,
            color: ok ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
