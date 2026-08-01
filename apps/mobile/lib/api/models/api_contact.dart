/// Wire-format contact from the backend `contacts` table.
class ApiContact {
  const ApiContact({
    required this.participantId,
    required this.displayName,
    required this.phoneNumber,
    required this.createdBy,
    this.claimedByParticipantId,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.version,
  });

  final String participantId;
  final String displayName;
  final String phoneNumber;
  final String createdBy;
  final String? claimedByParticipantId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int version;

  factory ApiContact.fromJson(Map<String, dynamic> json) => ApiContact(
        participantId: json['participant_id'] as String,
        displayName: json['display_name'] as String,
        phoneNumber: json['phone_number'] as String,
        createdBy: json['created_by'] as String,
        claimedByParticipantId: json['claimed_by_participant_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        version: json['version'] as int? ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'participant_id': participantId,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'created_by': createdBy,
        'claimed_by_participant_id': claimedByParticipantId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'version': version,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiContact &&
          other.participantId == participantId &&
          other.displayName == displayName &&
          other.phoneNumber == phoneNumber &&
          other.createdBy == createdBy &&
          other.claimedByParticipantId == claimedByParticipantId &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt &&
          other.version == version;

  @override
  int get hashCode => Object.hash(
      participantId,
      displayName,
      phoneNumber,
      createdBy,
      claimedByParticipantId,
      createdAt,
      updatedAt,
      deletedAt,
      version);

  @override
  String toString() =>
      'ApiContact(participantId: $participantId, displayName: $displayName, '
      'phoneNumber: $phoneNumber, createdBy: $createdBy, '
      'claimedByParticipantId: $claimedByParticipantId, version: $version)';
}
