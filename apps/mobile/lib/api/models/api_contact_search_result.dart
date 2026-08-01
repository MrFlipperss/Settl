/// Wire-format contact search result from `GET /contacts/search`.
class ApiContactSearchResult {
  const ApiContactSearchResult({
    required this.participantId,
    required this.displayName,
    required this.phoneNumber,
  });

  final String participantId;
  final String displayName;
  final String phoneNumber;

  factory ApiContactSearchResult.fromJson(Map<String, dynamic> json) =>
      ApiContactSearchResult(
        participantId: json['participant_id'] as String,
        displayName: json['display_name'] as String,
        phoneNumber: json['phone_number'] as String,
      );

  Map<String, dynamic> toJson() => {
        'participant_id': participantId,
        'display_name': displayName,
        'phone_number': phoneNumber,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiContactSearchResult &&
          other.participantId == participantId &&
          other.displayName == displayName &&
          other.phoneNumber == phoneNumber;

  @override
  int get hashCode => Object.hash(participantId, displayName, phoneNumber);

  @override
  String toString() => 'ApiContactSearchResult(participantId: $participantId, '
      'displayName: $displayName, phoneNumber: $phoneNumber)';
}
