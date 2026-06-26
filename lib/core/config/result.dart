import 'failure.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// DFC CORE RESULT MONAD
/// Ensures the logic layer always knows if an action succeeded or failed.
/// ═══════════════════════════════════════════════════════════════════════════
abstract class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}
