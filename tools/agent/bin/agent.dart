import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:args/args.dart';

final env = Platform.environment;

String resolveExampleEntrypoint() {
  const repoRelativePath = 'example/main.dart';
  final cwdRelative = File(repoRelativePath);
  if (cwdRelative.existsSync()) {
    return repoRelativePath;
  }

  const agentRelativePath = '../../example/main.dart';
  final agentRelative = File(agentRelativePath);
  if (agentRelative.existsSync()) {
    return agentRelativePath;
  }

  return repoRelativePath;
}

Future<int> runCmd(
  String cmd,
  List<String> args, {
  bool capture = false,
}) async {
  final proc = await Process.start(cmd, args);
  if (capture) {
    await proc.stdout.drain<void>();
    final err = await proc.stderr.transform(utf8.decoder).join();
    final code = await proc.exitCode;
    if (code != 0) {
      stderr.writeln('Command failed: $cmd ${args.join(' ')}');
      stderr.writeln(err);
    }
    return code;
  } else {
    proc.stdout.pipe(stdout);
    proc.stderr.pipe(stderr);
    return await proc.exitCode;
  }
}

Future<void> postAlert(String alertmanagerUrl) async {
  final uri = Uri.parse('http://$alertmanagerUrl/api/v1/alerts');
  final payload = [
    {
      'labels': {'alertname': 'CI_Smoke', 'sourceId': 'ci'},
      'annotations': {
        'summary': 'CI smoke',
        'description': 'CI smoke test alert',
      },
    },
  ];
  final resp = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );
  if (resp.statusCode != 200 && resp.statusCode != 202) {
    throw Exception('Failed to post alert ${resp.statusCode} ${resp.body}');
  }
}

Future<bool> pollAlert(String alertmanagerUrl, {int timeoutSec = 60}) async {
  final uri = Uri.parse('http://$alertmanagerUrl/api/v2/alerts');
  final maxAttempts = (timeoutSec / 5).ceil();
  try {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode != 200) {
        throw Exception('Alertmanager error ${resp.statusCode}');
      }
      final list = jsonDecode(resp.body) as List<dynamic>;
      final found = list.any(
        (a) =>
            a['labels'] != null &&
            a['labels']['alertname'] == 'CI_Smoke' &&
            a['labels']['sourceId'] == 'ci',
      );
      if (found) {
        return true;
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
    return false;
  } catch (_) {
    return false;
  }
}

Future<void> cleanupAlert(String alertmanagerUrl) async {
  final uri = Uri.parse('http://$alertmanagerUrl/api/v1/alerts');
  await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode([]),
  );
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'alertmanager',
      abbr: 'a',
      defaultsTo: env['ALERTMANAGER_URL'] ?? 'localhost:9093',
    )
    ..addFlag('run-example', abbr: 'r', defaultsTo: true)
    ..addFlag('cleanup', abbr: 'c', defaultsTo: true);
  final opts = parser.parse(args);
  final am = opts['alertmanager'] as String;

  print('Agent starting. Alertmanager: $am');

  if (opts['run-example'] as bool) {
    print('Running example to emit telemetry...');
    final code = await runCmd('dart', ['run', resolveExampleEntrypoint()]);
    if (code != 0) {
      stderr.writeln('Example failed with code $code');
    }
  }

  print('Posting CI test alert...');
  await postAlert(am);

  print('Polling Alertmanager for CI_Smoke...');
  final ok = await pollAlert(am);
  if (!ok) {
    stderr.writeln('Alert not found in Alertmanager within timeout');
    if (opts['cleanup'] as bool) {
      print('Attempting cleanup...');
      await cleanupAlert(am);
    }
    exit(2);
  }

  print('Alert verified. Optionally querying Prometheus for metrics...');
  // Example Prometheus check placeholder
  final prom = env['PROMETHEUS_URL'] ?? 'http://localhost:9090';
  try {
    final qUri = Uri.parse(
      '$prom/api/v1/query?query=feed_ingestion_processed_total',
    );
    final resp = await http.get(qUri).timeout(const Duration(seconds: 5));
    if (resp.statusCode == 200) {
      print('Prometheus query OK');
    } else {
      print('Prometheus query returned ${resp.statusCode}');
    }
  } catch (e) {
    print('Prometheus query failed: $e');
  }

  if (opts['cleanup'] as bool) {
    print('Cleaning up test alert...');
    await cleanupAlert(am);
  }

  print('Agent finished successfully.');
}
