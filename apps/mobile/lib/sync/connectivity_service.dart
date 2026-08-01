import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over device connectivity so the sync layer stays testable
/// (T8.6). Production implementation is [ConnectivityGatewayImpl]; tests
/// substitute a fake.
abstract class ConnectivityGateway {
  /// Emits the current connectivity state whenever it changes. Does NOT emit
  /// the initial state — call [isOnline] once to seed it.
  Stream<bool> get onlineStream;

  /// Current reachability; true when at least one interface is connected.
  Future<bool> isOnline();
}

/// [connectivity_plus]-backed implementation (v7 API: results are lists).
class ConnectivityGatewayImpl implements ConnectivityGateway {
  ConnectivityGatewayImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  @override
  Future<bool> isOnline() async =>
      _isOnline(await _connectivity.checkConnectivity());
}
