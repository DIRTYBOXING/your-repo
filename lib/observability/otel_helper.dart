import 'dart:async';
import 'dart:developer' as developer;

// Dependency-safe observability shim.
// The previous OpenTelemetry packages referenced here are not present in this
// workspace, so this file provides a small compatible surface until the real
// OTel SDK is wired back in intentionally.

class Level {
  const Level._(this.name);

  final String name;

  static const info = Level._('INFO');
}

class LogRecord {
  const LogRecord({
    required this.time,
    required this.level,
    required this.loggerName,
    required this.message,
    required this.sequenceNumber,
  });

  final DateTime time;
  final Level level;
  final String loggerName;
  final String message;
  final int sequenceNumber;
}

class Logger {
  Logger(this.name);

  Logger._root() : name = 'root';

  final String name;

  static final Logger root = Logger._root();
  static final StreamController<LogRecord> _records =
      StreamController<LogRecord>.broadcast();
  static int _sequenceNumber = 0;

  Level level = Level.info;

  Stream<LogRecord> get onRecord => _records.stream;

  void info(String message) {
    _records.add(
      LogRecord(
        time: DateTime.now(),
        level: Level.info,
        loggerName: name,
        message: message,
        sequenceNumber: ++_sequenceNumber,
      ),
    );
  }
}

class SpanContext {
  SpanContext()
    : traceId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);

  final String traceId;
}

class Span {
  Span(this.name) : context = SpanContext();

  final String name;
  final SpanContext context;

  void end() {}
}

class Counter {
  const Counter();

  void add(int value, {Map<String, Object?>? attributes}) {}
}

class Histogram {
  const Histogram();

  void record(double value, {Map<String, Object?>? attributes}) {}
}

class Meter {
  const Meter();

  Counter getCounter(String name) => const Counter();

  Histogram getHistogram(String name) => const Histogram();
}

class Tracer {
  const Tracer();

  Span startSpan(String name, {Map<String, Object?> attributes = const {}}) {
    return Span(name);
  }
}

class OTelHelper {
  static Tracer? _tracer;
  static Meter? _meter;
  static Logger? _logger;

  static Future<void> init({
    required String serviceName,
    String otlpEndpoint = 'http://localhost:4318/v1/traces',
    bool isCanary = false,
  }) async {
    _tracer = const Tracer();
    _meter = const Meter();
    _logger = Logger(serviceName);
    Logger.root.level = Level.info;
    Logger.root.onRecord.listen((record) {
      final log = {
        'ts': record.time.toIso8601String(),
        'level': record.level.name,
        'logger': record.loggerName,
        'msg': record.message,
        'trace_id': '',
        'job_id': record.sequenceNumber.toString(),
        'otlp_endpoint': otlpEndpoint,
        'canary': isCanary,
      };
      developer.log(log.toString(), name: serviceName);
    });
  }

  static Tracer get tracer => _tracer!;
  static Meter get meter => _meter!;
  static Logger get logger => _logger!;

  static Span startSpan(String name, {Map<String, Object?>? attributes}) {
    return tracer.startSpan(name, attributes: attributes ?? {});
  }

  static void recordProcessed({required String stage, String? sourceId}) {
    final attributes = <String, Object?>{'pipeline_stage': stage};
    if (sourceId != null) {
      attributes['sourceId'] = sourceId;
    }

    meter
        .getCounter('feed_ingestion_processed_total')
        .add(1, attributes: attributes);
  }

  static void recordError({
    required String stage,
    String? sourceId,
    Object? error,
  }) {
    final attributes = <String, Object?>{'pipeline_stage': stage};
    if (sourceId != null) {
      attributes['sourceId'] = sourceId;
    }
    if (error != null) {
      attributes['error'] = error.toString();
    }

    meter
        .getCounter('feed_ingestion_errors_total')
        .add(1, attributes: attributes);
  }

  static void recordLatency({required String stage, required double seconds}) {
    meter
        .getHistogram('feed_processing_latency_seconds')
        .record(seconds, attributes: {'pipeline_stage': stage});
  }
}
