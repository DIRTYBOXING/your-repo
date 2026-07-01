import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin IP Whitelisting — DFC Admin
/// Restrict admin access to trusted networks only.
class AdminIPWhitelistPage extends StatefulWidget {
  const AdminIPWhitelistPage({super.key});

  @override
  State<AdminIPWhitelistPage> createState() => _AdminIPWhitelistPageState();
}

class _AdminIPWhitelistPageState extends State<AdminIPWhitelistPage> {
  final _firestore = FirebaseFirestore.instance;
  final _ipController = TextEditingController();
  final _labelController = TextEditingController();

  CollectionReference get _whitelistRef => _firestore
      .collection('admin_config')
      .doc('ip_whitelist')
      .collection('ips');

  @override
  void dispose() {
    _ipController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _removeIP(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text('Remove IP?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This IP will no longer have admin access.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _whitelistRef.doc(docId).delete();
    }
  }

  void _showAddIPDialog() {
    _ipController.clear();
    _labelController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Add IP Address',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. 203.0.113.50',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                labelText: 'IP Address',
                labelStyle: const TextStyle(color: Colors.amber),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Office Brisbane',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                labelText: 'Label (optional)',
                labelStyle: const TextStyle(color: Colors.amber),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              final ip = _ipController.text.trim();
              if (ip.isEmpty) return;
              // Basic IP format validation
              final ipPattern = RegExp(r'^(\d{1,3}\.){3}\d{1,3}(\/\d{1,2})?$');
              if (!ipPattern.hasMatch(ip)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid IP format'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              await _whitelistRef.add({
                'ip': ip,
                'label': _labelController.text.trim(),
                'addedAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'Admin IP Whitelisting',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _whitelistRef.orderBy('addedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Only the following IP addresses/networks can access admin features. Add or remove as needed.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No IPs whitelisted yet.\nAdd your first trusted IP below.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ip = data['ip'] ?? '';
                final label = data['label'] ?? '';
                return Card(
                  color: Colors.deepPurple.shade800.withValues(alpha: 0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.lan,
                      color: Colors.amber,
                      size: 28,
                    ),
                    title: Text(
                      ip,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: label.isNotEmpty
                        ? Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _removeIP(doc.id),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade700,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add IP Address'),
                onPressed: _showAddIPDialog,
              ),
            ],
          );
        },
      ),
    );
  }
}
