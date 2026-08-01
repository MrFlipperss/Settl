import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../api/api_exception.dart';

/// Retry policy for the offline-first sync queue (T8.4).
///
/// Classifies replay failures as transient (retry with exponential backoff)
/// or permanent (surface, stop retrying) and caps the number of attempts.
class RetryPolicy {
  const RetryPolicy({
    this.maxAttempts = 5,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 2),
  });

  /// Maximum replay attempts before an operation is considered permanently
  /// failed and surfaced via [PendingSyncDao.getFailed].
  final int maxAttempts;

  /// Delay before the first retry; doubled per subsequent attempt.
  final Duration baseDelay;

  /// Upper bound for the exponential backoff delay.
  final Duration maxDelay;

  /// Whether [attemptCount] (attempts already made) still leaves room for
  /// another replay.
  bool canRetry(int attemptCount) => attemptCount < maxAttempts;

  /// Exponential backoff before the attempt after [attemptCount] failures:
  /// `baseDelay * 2^(attemptCount - 1)`, capped at [maxDelay].
  Duration delayForAttempt(int attemptCount) {
    if (attemptCount <= 1) return baseDelay;
    var delay = baseDelay;
    for (var i = 1; i < attemptCount; i++) {
      delay *= 2;
      if (delay >= maxDelay) return maxDelay;
    }
    return delay;
  }

  /// Whether [error] warrants a retry.
  ///
  /// Transient: network-level failures ([SocketException], [TimeoutException],
  /// [http.ClientException]) and 408 / 429 / 5xx responses. Permanent: any
  /// other 4xx — including 409 conflicts, which are routed to the
  /// conflict resolver rather than retried.
  bool isTransient(Object error) {
    if (error is ApiException) {
      final code = error.statusCode;
      if (code == null) return true;
      if (code == 409) return false;
      return code >= 500 || code == 408 || code == 429;
    }
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException;
  }
}
