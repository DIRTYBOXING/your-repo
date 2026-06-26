/// DFC Core Failure Model
/// Wraps exceptions into safe, readable objects for the UI.
class Failure {
  final String message;
  final String? code;
  final dynamic exception;

  const Failure(this.message, {this.code, this.exception});

  @override
  String toString() {
    return 'Failure: $message ${code != null ? '($code)' : ''}';
  }
}
