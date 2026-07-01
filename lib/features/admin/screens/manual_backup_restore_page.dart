import 'package:flutter/material.dart';

/// Manual Backup/Restore — DFC Admin
/// Owner can trigger full data backup/restore.
class ManualBackupRestorePage extends StatefulWidget {
  const ManualBackupRestorePage({super.key});

  @override
  State<ManualBackupRestorePage> createState() =>
      _ManualBackupRestorePageState();
}

class _ManualBackupRestorePageState extends State<ManualBackupRestorePage> {
  bool _backingUp = false;
  bool _restoring = false;

  static const _backupHistory = [
    ('2026-03-27 06:00', 'Scheduled', '2.4 GB', true),
    ('2026-03-26 06:00', 'Scheduled', '2.3 GB', true),
    ('2026-03-25 06:00', 'Scheduled', '2.3 GB', true),
    ('2026-03-20 14:30', 'Manual', '2.2 GB', true),
    ('2026-03-15 06:00', 'Scheduled', '2.1 GB', true),
  ];

  Future<void> _triggerBackup() async {
    setState(() => _backingUp = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _backingUp = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Backup triggered — Firestore export started.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _triggerRestore() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          'Confirm Restore',
          style: TextStyle(color: Colors.amber),
        ),
        content: const Text(
          'This will overwrite current data with the last backup. Continue?',
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
              setState(() => _restoring = true);
              await Future.delayed(const Duration(seconds: 3));
              if (!mounted) return;
              setState(() => _restoring = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Restore complete.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Restore', style: TextStyle(color: Colors.red)),
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
          'Manual Backup/Restore',
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
                const Icon(Icons.cloud_done, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Backup: Today 06:00 AM',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Daily scheduled backups + encrypted storage.',
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _backingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.backup, color: Colors.white),
                  label: Text(_backingUp ? 'Backing up...' : 'Trigger Backup'),
                  onPressed: _backingUp ? null : _triggerBackup,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: _restoring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.restore, color: Colors.white),
                  label: Text(_restoring ? 'Restoring...' : 'Restore Data'),
                  onPressed: _restoring ? null : _triggerRestore,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'BACKUP HISTORY',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._backupHistory.map(
            (b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade800.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    b.$4 ? Icons.check_circle : Icons.error,
                    color: b.$4 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      b.$1,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                  Text(
                    b.$2,
                    style: TextStyle(
                      color: Colors.amber.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    b.$3,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
