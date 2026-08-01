/// Wire-format profile from the backend `profiles` table.
class ApiProfile {
  const ApiProfile({
    required this.participantId,
    required this.userId,
    required this.displayName,
    required this.phoneNumber,
    this.upiId,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String participantId;
  final String userId;
  final String displayName;
  final String phoneNumber;
  final String? upiId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory ApiProfile.fromJson(Map<String, dynamic> json) => ApiProfile(
        participantId: json['participant_id'] as String,
        userId: json['user_id'] as String,
        displayName: json['display_name'] as String,
        phoneNumber: json['phone_number'] as String,
        upiId: json['upi_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'participant_id': participantId,
        'user_id': userId,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'upi_id': upiId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiProfile &&
          other.participantId == participantId &&
          other.userId == userId &&
          other.displayName == displayName &&
          other.phoneNumber == phoneNumber &&
          other.upiId == upiId &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(participantId, userId, displayName,
      phoneNumber, upiId, createdAt, updatedAt, deletedAt);

  @override
  String toString() =>
      'ApiProfile(participantId: $participantId, userId: $userId, '
      'displayName: $displayName, phoneNumber: $phoneNumber, '
      'upiId: $upiId, createdAt: $createdAt)';
}
