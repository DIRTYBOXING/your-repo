import 'package:flutter/material.dart';

/// Encryption Settings — DFC Admin
/// Manage encryption for sensitive data at rest and in transit.
class EncryptionSettingsPage extends StatefulWidget {
  const EncryptionSettingsPage({super.key});

  @override
  State<EncryptionSettingsPage> createState() => _EncryptionSettingsPageState();
}

class _EncryptionSettingsPageState extends State<EncryptionSettingsPage> {
  bool _atRestEnabled = true;
  bool _inTransitEnabled = true;
  bool _backupEncryption = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Encryption Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _statusCard(),
          const SizedBox(height: 20),
          _toggle(
            'Data at Rest (Firestore)',
            'AES-256 encryption for stored user data, media, and credentials.',
            Icons.storage,
            _atRestEnabled,
            (v) => setState(() => _atRestEnabled = v),
          ),
          _toggle(
            'Data in Transit (TLS)',
            'All API calls and storage transfers use TLS 1.3.',
            Icons.lock_outline,
            _inTransitEnabled,
            (v) => setState(() => _inTransitEnabled = v),
          ),
          _toggle(
            'Backup Encryption',
            'Automated backups are encrypted before storage.',
            Icons.backup,
            _backupEncryption,
            (v) => setState(() => _backupEncryption = v),
          ),
          const SizedBox(height: 24),
          const Text(
            'ENCRYPTION DETAILS',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _detailRow('Algorithm', 'AES-256-GCM'),
          _detailRow('Key Management', 'Google Cloud KMS'),
          _detailRow('TLS Version', '1.3 (minimum 1.2)'),
          _detailRow('Certificate', 'Firebase managed SSL'),
          _detailRow('Last Key Rotation', '2026-03-15'),
        ],
      ),
    );
  }

  Widget _statusCard() {
    final allEnabled = _atRestEnabled && _inTransitEnabled && _backupEncryption;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (allEnabled ? Colors.green : Colors.orange).withValues(alpha: 0.15),
            Colors.deepPurple.shade900.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (allEnabled ? Colors.green : Colors.orange).withValues(
            alpha: 0.3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allEnabled ? Icons.verified_user : Icons.warning,
            color: allEnabled ? Colors.green : Colors.orange,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allEnabled
                      ? 'All Encryption Active'
                      : 'Encryption Partially Disabled',
                  style: TextStyle(
                    color: allEnabled ? Colors.green : Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allEnabled
                      ? 'User data, transfers, and backups are fully encrypted.'
                      : 'One or more encryption layers are disabled.',
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
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
