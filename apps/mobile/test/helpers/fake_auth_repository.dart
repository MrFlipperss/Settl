// Configurable fake [AuthRepository] for widget tests.
//
// Mirrors gotrue's initial-session event by emitting the seeded session
// synchronously on the first listen, so [authStateProvider] (a StreamProvider)
// resolves immediately instead of hanging in [AsyncLoading] — the router auth
// gate depends on that to redirect signed-out users to /login.

import 'dart:async';

import 'package:settl/models/auth_session.dart';
import 'package:settl/repositories/interfaces/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? initialSession})
      : _initialSession = initialSession;

  final AuthSession? _initialSession;

  /// Broadcast controller used to push subsequent session changes.
  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();

  AuthSession? _currentSession;

  // Recorded call state for assertions.
  String? lastPhone;
  String? lastToken;
  String? lastEmail;
  String? lastPassword;
  bool signOutCalled = false;

  /// When true, [verifyOtp] throws — used to test the wrong-OTP error path.
  bool failVerify = false;

  @override
  AuthSession? get currentSession => _currentSession ?? _initialSession;

  @override
  Stream<AuthSession?> get onAuthStateChanged {
    // Emit the initial session synchronously on listen so the StreamProvider
    // does not sit in AsyncLoading forever (which would stall the redirect).
    return _InitialEmitStream(_controller.stream, _initialSession);
  }

  /// Pushes a new session (or null for signed-out) onto the auth stream.
  void pushSession(AuthSession? session) {
    _currentSession = session;
    _controller.add(session);
  }

  @override
  Future<void> sendOtp(String phone) async {
    lastPhone = phone;
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String token,
  }) async {
    lastToken = token;
    if (failVerify) {
      throw StateError('Invalid OTP.');
    }
    final session = _initialSession ??
        AuthSession(
          userId: 'test-user',
          phoneNumber: phone,
          accessToken: 'test-token',
        );
    _currentSession = session;
    _controller.add(session);
    return session;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    lastEmail = email;
    lastPassword = password;
    final session = _initialSession ??
        AuthSession(
          userId: 'test-user',
          email: email,
          accessToken: 'test-token',
        );
    _currentSession = session;
    _controller.add(session);
    return session;
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    lastEmail = email;
    lastPassword = password;
    final session = AuthSession(
      userId: 'test-user',
      email: email,
      accessToken: 'test-token',
    );
    _currentSession = session;
    _controller.add(session);
    return session;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    lastEmail = email;
  }

  @override
  Future<AuthSession?> restoreSession() async => _initialSession;

  @override
  Future<AuthSession> refreshSession() async {
    final session = _initialSession ??
        const AuthSession(
          userId: 'test-user',
          accessToken: 'test-token',
        );
    return session;
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
    _currentSession = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}

/// A wrapper [Stream] that synchronously emits [initialValue] on every listen
/// before forwarding events from [source]. This mimics gotrue's
/// `initialSession` auth-state event so a fresh [StreamProvider] resolves on
/// the first frame instead of hanging in [AsyncLoading].
class _InitialEmitStream extends Stream<AuthSession?> {
  _InitialEmitStream(this._source, this._initialValue);

  final Stream<AuthSession?> _source;
  final AuthSession? _initialValue;

  @override
  StreamSubscription<AuthSession?> listen(
    void Function(AuthSession? event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<AuthSession?>.broadcast();

    // Emit the initial value synchronously, then forward source events.
    controller.add(_initialValue);
    final sourceSubscription = _source.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );

    final listenerSubscription = controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    return _DelegatingSubscription(
      listenerSubscription,
      sourceSubscription,
    );
  }
}

class _DelegatingSubscription<T> implements StreamSubscription<T> {
  _DelegatingSubscription(this._primary, this._secondary);

  final StreamSubscription<T> _primary;
  final StreamSubscription<AuthSession?> _secondary;

  @override
  Future<void> cancel() async {
    await _primary.cancel();
    await _secondary.cancel();
  }

  @override
  void onData(void Function(T data)? handleData) =>
      _primary.onData(handleData);

  @override
  void onDone(void Function()? handleDone) => _primary.onDone(handleDone);

  @override
  void onError(Function? handleError) => _primary.onError(handleError);

  @override
  void pause([Future<void>? resumeSignal]) {
    _primary.pause(resumeSignal);
    _secondary.pause(resumeSignal);
  }

  @override
  void resume() {
    _primary.resume();
    _secondary.resume();
  }

  @override
  bool get isPaused => _primary.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _primary.asFuture(futureValue);
}
