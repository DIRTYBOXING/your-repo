// ── Result / Success / Err types ────────────────────────────────────────────────────
// Lightweight functional Result type used by AuthService.

sealed class Result<T> {
  const Result();

  /// Transform result: [onSuccess] for Success, [onError] for Err.
  R fold<R>(R Function(T value) onSuccess, R Function(dynamic error) onError) {
    if (this is Success<T>) return onSuccess((this as Success<T>).value);
    return onError((this as Err<T>).error);
  }

  bool get isSuccess => this is Success<T>;
  bool get isError => this is Err<T>;
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Err<T> extends Result<T> {
  final dynamic error;
  const Err(this.error);
}
