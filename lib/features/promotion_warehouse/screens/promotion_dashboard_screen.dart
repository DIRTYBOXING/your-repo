import 'package:flutter/material.dart';
import '../promotion_warehouse_orchestrator.dart';

/// PromotionDashboardScreen: Unified control and monitoring for all modules.
class PromotionDashboardScreen extends StatefulWidget {
  final PromotionWarehouseOrchestrator orchestrator;
  const PromotionDashboardScreen({super.key, required this.orchestrator});

  @override
  State<PromotionDashboardScreen> createState() =>
      _PromotionDashboardScreenState();
}

class _PromotionDashboardScreenState extends State<PromotionDashboardScreen> {
  late List<PromotionContent> _content;
  late List<Map<String, String>> _metaTags;
  late List<String> _hashes;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _content = widget.orchestrator.runAll();
    _metaTags = widget.orchestrator.generateAllMetaTags(
      owner: 'DFC Team',
    );
    _hashes = widget.orchestrator.generateAllContentHashes();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promotion Warehouse Dashboard'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Refresh Data'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Owner: DFC Team',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Module Output:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ..._content.map(
              (c) => Card(
                color: Colors.grey[900],
                child: ListTile(
                  title: Text(c.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    c.body,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Text(
                    c.tags.join(', '),
                    style: const TextStyle(color: Colors.cyanAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Meta Tags:', style: Theme.of(context).textTheme.titleMedium),
            ..._metaTags.map(
              (tags) => Card(
                color: Colors.grey[800],
                child: ListTile(
                  title: Text(
                    tags['title'] ?? '',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    tags['description'] ?? '',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Text(
                    tags['keywords'] ?? '',
                    style: const TextStyle(color: Colors.amber),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Content Hashes:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ..._hashes.map(
              (h) => Card(
                color: Colors.grey[700],
                child: ListTile(
                  title: Text(h, style: const TextStyle(color: Colors.greenAccent)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
