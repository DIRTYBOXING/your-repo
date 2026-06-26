import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// PromotionContactsScreen — Manage promotional contacts and requests.
class PromotionContactsScreen extends StatefulWidget {
  const PromotionContactsScreen({super.key});

  @override
  State<PromotionContactsScreen> createState() =>
      _PromotionContactsScreenState();
}

class _PromotionContactsScreenState extends State<PromotionContactsScreen> {
  final List<_Contact> _contacts = [
    _Contact(
      name: 'Ultimate Legends Gym',
      type: 'Gym',
      email: 'info@ultimategym.com',
    ),
    _Contact(
      name: 'Fight Media Group',
      type: 'Media',
      email: 'media@fightgroup.com',
    ),
    _Contact(
      name: 'DFC Promotions',
      type: 'Promoter',
      email: 'promote@dfc.com',
    ),
  ];

  void _openRequestForm() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Partnership Request',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'To request an event partnership or promotion collaboration, '
          'email partners@datafightcentral.com with your event details, '
          'expected attendance, and preferred partnership tier.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
          ).createShader(b),
          child: const Text(
            'CONTACTS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: AppTheme.primaryBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment, color: AppTheme.neonCyan),
            onPressed: _openRequestForm,
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryBackground,
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _contacts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final c = _contacts[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.neonCyan, AppTheme.neonMagenta],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      c.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${c.type} · ${c.email}',
                        style: TextStyle(
                          color: AppTheme.neonCyan.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: AppTheme.neonCyan.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening chat with ${c.name}...'),
                        backgroundColor: Colors.deepPurple,
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Contact {
  final String name;
  final String type;
  final String email;
  _Contact({required this.name, required this.type, required this.email});
}
