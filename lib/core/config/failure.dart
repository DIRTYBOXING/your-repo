/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CORE FAILURE MODEL
/// Wraps raw exceptions into safe, readable objects.
/// ═══════════════════════════════════════════════════════════════════════════
class Failure {
  final String message;
  final String? code;
  final dynamic exception;

  const Failure(this.message, {this.code, this.exception});

  @override
  String toString() {
    final base = 'Failure: $message';
    final codePart = code != null ? ' (Code: $code)' : '';
    return '$base$codePart';
  }
}
