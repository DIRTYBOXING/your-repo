import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// APP LOGGER - Centralized logging utility for DataFightCentral
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Use this instead of debugPrint() or debugPrint() for consistent logging.
/// Only logs in debug mode - silently ignores in release builds.
///
/// Usage:
///   AppLogger.debug('Some debug info');
///   AppLogger.info('User logged in');
///   AppLogger.warning('Low battery');
///   AppLogger.error('Failed to fetch', error: e, stackTrace: stack);
///
/// ═══════════════════════════════════════════════════════════════════════════
class AppLogger {
  static const String _name = 'DataFightCentral';

  /// Debug level - detailed technical info
  static void debug(String message, {String? tag}) {
    _log(message, level: 500, tag: tag ?? 'DEBUG');
  }

  /// Info level - general operational info
  static void info(String message, {String? tag}) {
    _log(message, level: 800, tag: tag ?? 'INFO');
  }

  /// Warning level - potential issues
  static void warning(String message, {String? tag}) {
    _log(message, level: 900, tag: tag ?? 'WARNING');
  }

  /// Error level - failures and exceptions
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log(
      message,
      level: 1000,
      tag: tag ?? 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Internal logging method
  static void _log(
    String message, {
    required int level,
    required String tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Only log in debug mode
    if (!kDebugMode) return;

    final formattedMessage = '[$tag] $message';

    developer.log(
      formattedMessage,
      name: _name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a service operation (for tracking data flow)
  static void service(String serviceName, String operation, {String? details}) {
    if (!kDebugMode) return;
    final msg = details != null ? '$operation - $details' : operation;
    _log(msg, level: 700, tag: serviceName);
  }

  /// Log a Firebase operation
  static void firebase(String operation, {String? collection, String? docId}) {
    if (!kDebugMode) return;
    final details = [
      if (collection != null) 'collection: $collection',
      if (docId != null) 'doc: $docId',
    ].join(', ');
    _log(
      '$operation${details.isNotEmpty ? ' ($details)' : ''}',
      level: 600,
      tag: 'Firebase',
    );
  }
}
