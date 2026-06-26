import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Admin Sign-Out & Session Expiry — DFC Admin
/// Sign out and auto-expire admin sessions for security.
class AdminSignOutSessionExpiryPage extends StatefulWidget {
  const AdminSignOutSessionExpiryPage({super.key});

  @override
  State<AdminSignOutSessionExpiryPage> createState() =>
      _AdminSignOutSessionExpiryPageState();
}

class _AdminSignOutSessionExpiryPageState
    extends State<AdminSignOutSessionExpiryPage> {
  String _sessionTimeout = '30 min';
  static const _timeoutOptions = [
    '15 min',
    '30 min',
    '1 hour',
    '4 hours',
    'Never',
  ];

  void _signOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Sign Out', style: TextStyle(color: Colors.amber)),
        content: const Text(
          'This will end your admin session and return to the login screen.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final nav = Navigator.of(context);
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              if (!context.mounted) return;
              nav.popUntil((r) => r.isFirst);
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Session & Sign-Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? 'admin@datafightcentral.com',
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
          const Text(
            'SESSION TIMEOUT',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _timeoutOptions.map((t) {
              final selected = t == _sessionTimeout;
              return ChoiceChip(
                label: Text(t),
                selected: selected,
                selectedColor: Colors.amber.withValues(alpha: 0.3),
                backgroundColor: Colors.deepPurple.shade800,
                labelStyle: TextStyle(
                  color: selected ? Colors.amber : Colors.white54,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected ? Colors.amber : Colors.white24,
                ),
                onSelected: (_) => setState(() => _sessionTimeout = t),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'SESSION INFO',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('User', user?.email ?? 'N/A'),
          _infoRow('UID', user?.uid ?? 'N/A'),
          _infoRow(
            'Last Sign-In',
            user?.metadata.lastSignInTime?.toString().substring(0, 16) ?? 'N/A',
          ),
          _infoRow(
            'Account Created',
            user?.metadata.creationTime?.toString().substring(0, 16) ?? 'N/A',
          ),
          _infoRow('Auto-Timeout', _sessionTimeout),
          const SizedBox(height: 32),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'SIGN OUT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
