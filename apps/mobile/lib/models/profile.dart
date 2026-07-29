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
}
