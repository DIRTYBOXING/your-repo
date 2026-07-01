import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ppv_operator_dashboard_view_model.dart';
import 'ppv_live_stats_model.dart';
import 'ppv_incident_model.dart';
import 'ppv_entitlement_log_model.dart';

class PpvOperatorDashboardScreen extends StatelessWidget {
  final String eventId;

  const PpvOperatorDashboardScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PpvOperatorDashboardViewModel(eventId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('PPV Operator Dashboard (Event: $eventId)'),
        ),
        body: const DashboardBody(),
      ),
    );
  }
}

class DashboardBody extends StatelessWidget {
  const DashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return const WideLayout();
        } else {
          return const NarrowLayout();
        }
      },
    );
  }
}

class WideLayout extends StatelessWidget {
  const WideLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(child: LiveStatusPanel()),
              Expanded(child: IncidentPanel()),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(child: EntitlementPanel()),
              Expanded(child: OperatorActionsPanel()),
            ],
          ),
        ),
      ],
    );
  }
}

class NarrowLayout extends StatelessWidget {
  const NarrowLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          LiveStatusPanel(),
          EntitlementPanel(),
          IncidentPanel(),
          OperatorActionsPanel(),
        ],
      ),
    );
  }
}

class LiveStatusPanel extends StatelessWidget {
  const LiveStatusPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PpvOperatorDashboardViewModel>(context);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<PpvLiveStats>(
          stream: viewModel.liveStatsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No live data available.'));
            }

            final stats = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      MetricChip(label: 'Live Viewers', value: stats.liveViewers.toString()),
                      MetricChip(label: 'Unique Viewers', value: stats.uniqueViewers.toString()),
                      MetricChip(label: 'Purchases', value: stats.purchases.toString()),
                      MetricChip(label: 'Revenue', value: '\$${stats.revenue.toStringAsFixed(2)}'),
                      MetricChip(label: 'Stream Health', value: stats.streamHealthStatus, color: _getHealthColor(stats.streamHealthStatus)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Stream Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: Row(
                      children: [
                        Expanded(child: _buildHealthChart('Bitrate (kbps)', [FlSpot(0, stats.streamBitrateKbps.toDouble())])),
                        Expanded(child: _buildHealthChart('Rebuffer Rate (%)', [FlSpot(0, stats.streamRebufferRate)])),
                        Expanded(child: _buildHealthChart('Error Rate (%)', [FlSpot(0, stats.streamErrorRate)])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                   const Text('Device Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                   SizedBox(
                     height: 150,
                     child: PieChart(
                       PieChartData(
                         sections: stats.deviceBreakdown.entries.map((entry) {
                           return PieChartSectionData(
                             value: entry.value.toDouble(),
                             title: '${entry.key}
(${entry.value})',
                             radius: 50,
                           );
                         }).toList(),
                       ),
                     ),
                   )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getHealthColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'degraded':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHealthChart(String title, List<FlSpot> spots) {
    return Column(
      children: [
        Text(title),
        Expanded(
          child: LineChart(
            LineChartData(
              lineBarsData: [LineChartBarData(spots: spots)],
              titlesData: const FlTitlesData(show: false),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
      ],
    );
  }
}

class EntitlementPanel extends StatelessWidget {
  const EntitlementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PpvOperatorDashboardViewModel>(context);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Entitlement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<PpvLiveStats>(
              stream: viewModel.liveStatsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = snapshot.data!;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    MetricChip(label: 'Total Entitlements', value: stats.totalEntitlements.toString()),
                    const MetricChip(label: 'New Entitlements/Min', value: 'N/A'),
                    MetricChip(label: 'Failed Entitlements', value: stats.failedEntitlementsCount.toString()),
                    MetricChip(label: 'Suspicious Activity', value: stats.suspiciousActivityCount.toString()),
                    MetricChip(label: 'Refunds', value: stats.refundsCount.toString()),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Recent Entitlement Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<PpvEntitlementLog>>(
                stream: viewModel.entitlementLogsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No entitlement logs available.'));
                  }
                  final logs = snapshot.data!;
                  return ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return ListTile(
                        title: Text('${log.action.toUpperCase()} - ${log.userId}'),
                        subtitle: Text('${log.source} - ${log.ipAddress}'),
                        trailing: Text(log.status, style: TextStyle(color: log.status == 'success' ? Colors.green : Colors.red)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IncidentPanel extends StatelessWidget {
  const IncidentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PpvOperatorDashboardViewModel>(context, listen: false);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Incidents', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<PpvIncident>>(
                stream: viewModel.incidentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No active incidents.'));
                  }
                  final incidents = snapshot.data!;
                  return ListView.builder(
                    itemCount: incidents.length,
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      return ListTile(
                        title: Text(incident.description),
                        subtitle: Text('Severity: ${incident.severity.toUpperCase()}'),
                        trailing: incident.status == 'open'
                            ? ElevatedButton(
                                onPressed: () {
                                  // Assuming a default operatorId for now
                                  viewModel.resolveIncident(incident.incidentId, 'operator_1');
                                },
                                child: const Text('Resolve'),
                              )
                            : Text(incident.status.toUpperCase()),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OperatorActionsPanel extends StatelessWidget {
  const OperatorActionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<PpvOperatorDashboardViewModel>(context, listen: false);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Operator Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton(
                  onPressed: () => _showInputDialog(context, 'Force Entitlement', 'User ID', viewModel.forceEntitlement),
                  child: const Text('Force Entitlement'),
                ),
                ElevatedButton(
                  onPressed: () => _showInputDialog(context, 'Revoke Entitlement', 'User ID', viewModel.revokeEntitlement),
                  child: const Text('Revoke Entitlement'),
                ),
                ElevatedButton(
                  onPressed: () => _showInputDialog(context, 'Resend Webhook', 'Transaction ID', viewModel.resendWebhook),
                  child: const Text('Resend Webhook'),
                ),
                ElevatedButton(
                  onPressed: () => _showInputDialog(context, 'Push Emergency Banner', 'Message', (message) {
                    viewModel.pushEmergencyBanner(message, 300); // Default 5 mins duration
                  }),
                  child: const Text('Push Emergency Banner'),
                ),
                ElevatedButton(
                  onPressed: () => _showInputDialog(context, 'Enable Backup Stream', 'Stream URL', viewModel.enableBackupStream),
                  child: const Text('Enable Backup Stream'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInputDialog(BuildContext context, String title, String hint, Function(String) onSubmit) {
    final controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                onSubmit(controller.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const MetricChip({super.key, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: color,
      label: Text('$label: $value', style: TextStyle(color: color != null ? Colors.white : null)),
    );
  }
}
