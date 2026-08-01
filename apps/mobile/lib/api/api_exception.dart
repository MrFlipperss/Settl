/// Exception thrown by the API layer when the backend responds with a
/// non-success status code.
///
/// When the backend returns a JSON error body (`{"error": "..."}`), the
/// parsed message is surfaced here; otherwise a generic message is used.
class ApiException implements Exception {
  const ApiException(this.message, [this.statusCode]);

  /// Human-readable error message, ideally from the backend's `error` field.
  final String message;

  /// HTTP status code that caused the failure, when known.
  final int? statusCode;

  @override
  String toString() => 'ApiException: $message'
      '${statusCode != null ? ' (status: $statusCode)' : ''}';
}
