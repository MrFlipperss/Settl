/// A signed-in session for the current user.
///
/// Decouples the UI and services layer from the Supabase (gotrue) types so
/// that nothing outside the auth repository ever depends on Supabase
/// specifics.
class AuthSession {
  const AuthSession({
    required this.userId,
    this.phoneNumber,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  /// Supabase user id (UUID).
  final String userId;

  /// E.164 phone number used to sign in, when available.
  final String? phoneNumber;

  /// Bearer access token sent to the backend as `Authorization: Bearer`.
  final String accessToken;

  /// Refresh token used to obtain a new access token once it expires.
  final String? refreshToken;

  /// When [accessToken] expires (UTC).
  final DateTime? expiresAt;

  bool get isExpired =>
      expiresAt != null && !expiresAt!.isAfter(DateTime.now());

  AuthSession copyWith({
    String? userId,
    Object? phoneNumber = _unset,
    String? accessToken,
    Object? refreshToken = _unset,
    Object? expiresAt = _unset,
  }) {
    return AuthSession(
      userId: userId ?? this.userId,
      phoneNumber: identical(phoneNumber, _unset)
          ? this.phoneNumber
          : phoneNumber as String?,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: identical(refreshToken, _unset)
          ? this.refreshToken
          : refreshToken as String?,
      expiresAt: identical(expiresAt, _unset)
          ? this.expiresAt
          : expiresAt as DateTime?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          other.userId == userId &&
          other.phoneNumber == phoneNumber &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      Object.hash(userId, phoneNumber, accessToken, refreshToken, expiresAt);

  @override
  String toString() =>
      'AuthSession(userId: $userId, phoneNumber: $phoneNumber, '
      'accessToken: $accessToken, refreshToken: $refreshToken, '
      'expiresAt: $expiresAt)';
}

const _unset = Object();
