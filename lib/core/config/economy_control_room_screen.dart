import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC ECONOMY CONTROL ROOM
/// The master cockpit for PPV, Payouts, and System Integrity.
/// ═══════════════════════════════════════════════════════════════════════════
class EconomyControlRoomScreen extends StatefulWidget {
  const EconomyControlRoomScreen({super.key});

  @override
  State<EconomyControlRoomScreen> createState() =>
      _EconomyControlRoomScreenState();
}

class _EconomyControlRoomScreenState extends State<EconomyControlRoomScreen> {
  bool _runningSelfCheck = false;
  bool _runningAutoFix = false;

  Future<void> _runSelfCheck() async {
    setState(() => _runningSelfCheck = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'systemIntegrityCheck',
      );
      await callable.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Self-check triggered successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _runningSelfCheck = false);
    }
  }

  Future<void> _runAutoFix() async {
    setState(() => _runningAutoFix = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('autoFix');
      final res = await callable.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-fix: ${res.data['message']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _runningAutoFix = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF05060A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0D13),
        elevation: 0,
        title: const Text(
          'DFC ECONOMY CONTROL ROOM',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        actions: [
          const _StatusChip(
            label: 'ENV',
            value: 'PROD',
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _runningSelfCheck ? null : _runSelfCheck,
            icon: _runningSelfCheck
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent,
                    ),
                  )
                : const Icon(
                    Icons.health_and_safety,
                    size: 16,
                    color: Colors.greenAccent,
                  ),
            label: const Text(
              'Run Self-Check',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _runningAutoFix ? null : _runAutoFix,
            icon: _runningAutoFix
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orangeAccent,
                    ),
                  )
                : const Icon(Icons.build, size: 16, color: Colors.orangeAccent),
            label: const Text(
              'Run Auto-Fix',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: StreamBuilder(
        stream: fs
            .collection('selfCheckReports')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          final report = snap.hasData && snap.data!.docs.isNotEmpty
              ? snap.data!.docs.first.data()
              : null;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TopStatusRow(report: report),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      const _EconomyPulsePanel(),
                      _IntegrityPanel(report: report),
                      const _PayoutEnginePanel(),
                      _AlertsPanel(report: report),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const _EventDrilldownStrip(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopStatusRow extends StatelessWidget {
  final Map<String, dynamic>? report;
  const _TopStatusRow({this.report});

  @override
  Widget build(BuildContext context) {
    final ts = report?['timestamp'] != null
        ? (report!['timestamp'] as Timestamp).toDate().toString()
        : '—';
    final statusColor = report?['status'] == 'RED'
        ? Colors.redAccent
        : Colors.greenAccent;

    return Row(
      children: [
        _StatusChip(
          label: 'ECONOMY',
          value: report?['status'] ?? 'OK',
          color: statusColor,
        ),
        const SizedBox(width: 8),
        const _StatusChip(
          label: 'STRIPE',
          value: 'OK',
          color: Colors.greenAccent,
        ),
        const Spacer(),
        Text(
          'Last Self-Check: $ts',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EconomyPulsePanel extends StatelessWidget {
  const _EconomyPulsePanel();
  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'Economy Pulse',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(label: 'GMV (today)', value: '\$—'),
          _MetricRow(label: 'Platform Take', value: '\$—'),
          _MetricRow(label: 'Active PPV Events', value: '—'),
          _MetricRow(label: 'Purchases / min', value: '—'),
          _MetricRow(label: 'Refund Rate', value: '—'),
        ],
      ),
    );
  }
}

class _IntegrityPanel extends StatelessWidget {
  final Map<String, dynamic>? report;
  const _IntegrityPanel({this.report});

  @override
  Widget build(BuildContext context) {
    final orphanedEvents = (report?['orphanedEvents'] ?? []) as List;
    final orphanedPurchases = (report?['orphanedPurchases'] ?? []) as List;
    final invalidSplits = (report?['invalidSplits'] ?? []) as List;
    final missingOwners = (report?['missingOwners'] ?? []) as List;

    return _PanelShell(
      title: 'Integrity & Guardrails',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'Orphaned Events',
            value: orphanedEvents.length.toString(),
          ),
          _MetricRow(
            label: 'Orphaned Purchases',
            value: orphanedPurchases.length.toString(),
          ),
          _MetricRow(
            label: 'Invalid Splits',
            value: invalidSplits.length.toString(),
          ),
          _MetricRow(
            label: 'Missing Owners',
            value: missingOwners.length.toString(),
          ),
        ],
      ),
    );
  }
}

class _PayoutEnginePanel extends StatelessWidget {
  const _PayoutEnginePanel();
  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'Payout Engine',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(label: 'Outstanding Balances', value: '\$—'),
          _MetricRow(label: 'Next Payout Window', value: '—'),
        ],
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  final Map<String, dynamic>? report;
  const _AlertsPanel({this.report});

  @override
  Widget build(BuildContext context) {
    final missingOwners = (report?['missingOwners'] as List?)?.length ?? 0;
    final hasAlert = missingOwners > 0;

    return const _PanelShell(
      title: 'Alerts & Incidents',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAlert)
            Text(
              'No active alerts',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            )
          else
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.redAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CRITICAL: $missingOwners Payout Balance(s) missing an owner profile.',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EventDrilldownStrip extends StatelessWidget {
  const _EventDrilldownStrip();
  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'Event Drilldown',
      dense: true,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Select an event to inspect PPV → Revenue → Payout chain.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelShell extends StatelessWidget {
  final String title;
  final Widget child;
  final bool dense;
  const _PanelShell({
    required this.title,
    required this.child,
    this.dense = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0D13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
