import 'dart:async';

import 'connectivity_service.dart';
import 'pull_worker.dart';
import 'push_worker.dart';
import 'retry_policy.dart';

/// App-facing sync facade (T8.1).
///
/// Owns the [PushWorker] (queue drain), [PullWorker] (remote refresh) and
/// [ConnectivityGateway] lifecycle, exposes sync status and connectivity as
/// broadcast streams, and triggers a push + pull when the device comes online,
/// on [requestSync], or — after a failure — on the retry backoff schedule.
enum SyncStatus { idle, syncing, error }

class SyncService {
  SyncService({
    required PushWorker pushWorker,
    required PullWorker pullWorker,
    required ConnectivityGateway connectivity,
    required RetryPolicy retryPolicy,
  })  : _pushWorker = pushWorker,
        _pullWorker = pullWorker,
        _connectivity = connectivity,
        _retryPolicy = retryPolicy;

  final PushWorker _pushWorker;
  final PullWorker _pullWorker;
  final ConnectivityGateway _connectivity;
  final RetryPolicy _retryPolicy;

  SyncStatus _status = SyncStatus.idle;
  bool _online = false;
  bool _draining = false;
  Timer? _retryTimer;
  StreamSubscription<bool>? _connectivitySub;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  SyncStatus get status => _status;
  bool get isOnline => _online;
  Stream<SyncStatus> get statusStream => _statusController.stream;
  Stream<bool> get onlineStream => _onlineController.stream;

  void _setStatus(SyncStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Starts the service: seeds connectivity state, subscribes to changes
  /// (draining whenever the device comes online), and runs an initial sync.
  Future<void> start() async {
    await _connectivitySub?.cancel();
    _connectivitySub = _connectivity.onlineStream.listen((online) async {
      _online = online;
      _onlineController.add(online);
      if (online) unawaited(requestSync());
    });
    _online = await _connectivity.isOnline();
    _onlineController.add(_online);
    if (_online) await requestSync();
  }

  /// Drains the queue then pulls remote state. No-op while a sync is already
  /// running; re-attempts (with backoff) when the push or pull fails.
  Future<void> requestSync() async {
    if (_draining) return;
    _draining = true;
    _setStatus(SyncStatus.syncing);
    try {
      await _pushWorker.drainQueue();
      await _pullWorker.refresh();
      _setStatus(SyncStatus.idle);
    } catch (_) {
      _setStatus(SyncStatus.error);
      _scheduleRetry();
    } finally {
      _draining = false;
    }
  }

  /// Schedules a single retry using the backoff policy, only while online.
  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (!_online) return;
    _retryTimer = Timer(_retryPolicy.delayForAttempt(1), () {
      unawaited(requestSync());
    });
  }

  /// Tears down subscriptions and timers (wired via `ref.onDispose`).
  Future<void> stop() async {
    _retryTimer?.cancel();
    await _connectivitySub?.cancel();
    await _statusController.close();
    await _onlineController.close();
  }
}
