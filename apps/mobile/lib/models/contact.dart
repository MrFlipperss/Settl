class Contact {
  final String participantId;
  final String phoneNumber;
  final String displayName;
  final String createdBy;
  final String? claimedByParticipantId;
  final DateTime createdAt;

  const Contact({
    required this.participantId,
    required this.phoneNumber,
    required this.displayName,
    required this.createdBy,
    this.claimedByParticipantId,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        participantId: json['participant_id'] as String,
        phoneNumber: json['phone_number'] as String,
        displayName: json['display_name'] as String,
        createdBy: json['created_by'] as String,
        claimedByParticipantId: json['claimed_by_participant_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'participant_id': participantId,
        'phone_number': phoneNumber,
        'display_name': displayName,
        'created_by': createdBy,
        'claimed_by_participant_id': claimedByParticipantId,
        'created_at': createdAt.toIso8601String(),
      };
}
