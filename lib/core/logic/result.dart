// ── Result / Success / Error types ───────────────────────────────────────────
// Lightweight functional Result type used by AuthService.

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Err<T> extends Result<T> {
  final dynamic error;
  const Err(this.error);
}
