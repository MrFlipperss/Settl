const _unset = Object();

class Profile {
  final String userId;
  final String participantId;
  final String displayName;
  final String phoneNumber;
  final String? upiId;
  final DateTime createdAt;

  const Profile({
    required this.userId,
    required this.participantId,
    required this.displayName,
    required this.phoneNumber,
    this.upiId,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: json['user_id'] as String,
        participantId: json['participant_id'] as String,
        displayName: json['display_name'] as String,
        phoneNumber: json['phone_number'] as String,
        upiId: json['upi_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'participant_id': participantId,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'upi_id': upiId,
        'created_at': createdAt.toIso8601String(),
      };

  Profile copyWith({
    String? userId,
    String? participantId,
    String? displayName,
    String? phoneNumber,
    Object? upiId = _unset,
    DateTime? createdAt,
  }) =>
      Profile(
        userId: userId ?? this.userId,
        participantId: participantId ?? this.participantId,
        displayName: displayName ?? this.displayName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        upiId: identical(upiId, _unset) ? this.upiId : upiId as String?,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          other.userId == userId &&
          other.participantId == participantId &&
          other.displayName == displayName &&
          other.phoneNumber == phoneNumber &&
          other.upiId == upiId &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(userId, participantId, displayName, phoneNumber, upiId,
          createdAt);

  @override
  String toString() =>
      'Profile(userId: $userId, participantId: $participantId, '
      'displayName: $displayName, phoneNumber: $phoneNumber, '
      'upiId: $upiId)';
}
