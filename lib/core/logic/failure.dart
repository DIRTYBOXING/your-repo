// ── Failure value object ─────────────────────────────────────────────────────

class Failure {
  final String message;
  final String? code;
  final Object? exception;

  const Failure(this.message, {this.code, this.exception});

  @override
  String toString() =>
      'Failure($message${code != null ? ', code: $code' : ''})';
}
