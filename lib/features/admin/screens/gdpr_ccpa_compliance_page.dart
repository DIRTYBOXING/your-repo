import 'package:flutter/material.dart';

/// GDPR/CCPA Data Export/Delete — DFC Admin
/// Allow users to request data deletion/export for compliance.
class GDPRCCPACompliancePage extends StatelessWidget {
  const GDPRCCPACompliancePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample requests (replace with backend integration)
    final requests = [
      _Request('alice@dfc.com', 'Export', 'Pending'),
      _Request('bob@dfc.com', 'Delete', 'Completed'),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade900,
        title: const Text(
          'GDPR/CCPA Data Export/Delete',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Manage user data export and deletion requests for compliance.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ...requests.map(
            (r) => Card(
              color: r.status == 'Pending'
                  ? Colors.amber.shade900.withValues(alpha: 0.8)
                  : Colors.deepPurple.shade800.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(
                  r.type == 'Export' ? Icons.download : Icons.delete,
                  color: Colors.amber,
                  size: 28,
                ),
                title: Text(
                  '${r.type} for ${r.user}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Status: ${r.status}',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.check, color: Colors.white70),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${r.type} request for ${r.user} marked complete',
                        ),
                        backgroundColor: Colors.green.shade700,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Request {
  final String user;
  final String type;
  final String status;
  _Request(this.user, this.type, this.status);
}
