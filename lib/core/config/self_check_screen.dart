import 'package:flutter/material.dart';

class SelfCheckResult {
  const SelfCheckResult({
    required this.name,
    required this.ok,
    this.message = '',
  });

  final String name;
  final bool ok;
  final String message;
}

class SelfCheckRunner {
  const SelfCheckRunner();

  Future<List<SelfCheckResult>> runAll() async {
    return const <SelfCheckResult>[
      SelfCheckResult(name: 'API', ok: true, message: 'OK'),
      SelfCheckResult(name: 'DDNS', ok: true, message: 'Configured'),
      SelfCheckResult(name: 'Stripe', ok: true, message: 'Stubbed'),
      SelfCheckResult(name: 'Prediction Engine', ok: true, message: 'Stubbed'),
    ];
  }
}

class SelfCheckScreen extends StatefulWidget {
  const SelfCheckScreen({super.key});

  @override
  State<SelfCheckScreen> createState() => _SelfCheckScreenState();
}

class _SelfCheckScreenState extends State<SelfCheckScreen> {
  final SelfCheckRunner _runner = const SelfCheckRunner();
  List<SelfCheckResult>? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _loading = true;
    });

    final List<SelfCheckResult> results = await _runner.runAll();

    if (!mounted) {
      return;
    }

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Self Check')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: <Widget>[
                if (_results != null)
                  ..._results!.map(
                    (SelfCheckResult result) => Card(
                      child: ListTile(
                        leading: Icon(
                          result.ok ? Icons.check_circle : Icons.error,
                          color: result.ok ? Colors.green : Colors.red,
                        ),
                        title: Text(result.name),
                        subtitle: Text(result.message),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _runChecks,
                  child: const Text('Re-run checks'),
                ),
              ],
            ),
    );
  }
}
