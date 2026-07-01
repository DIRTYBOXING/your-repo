import 'failure.dart';

/// DFC Core Result Monad
/// Ensures the UI always knows if an action succeeded or failed.
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
