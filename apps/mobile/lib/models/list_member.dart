class ListMember {
  final String listId;
  final String participantId;
  final DateTime addedAt;

  const ListMember({
    required this.listId,
    required this.participantId,
    required this.addedAt,
  });

  factory ListMember.fromJson(Map<String, dynamic> json) => ListMember(
        listId: json['list_id'] as String,
        participantId: json['participant_id'] as String,
        addedAt: DateTime.parse(json['added_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'list_id': listId,
        'participant_id': participantId,
        'added_at': addedAt.toIso8601String(),
      };
}
