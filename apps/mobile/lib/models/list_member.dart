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

  ListMember copyWith({
    String? listId,
    String? participantId,
    DateTime? addedAt,
  }) =>
      ListMember(
        listId: listId ?? this.listId,
        participantId: participantId ?? this.participantId,
        addedAt: addedAt ?? this.addedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListMember &&
          other.listId == listId &&
          other.participantId == participantId &&
          other.addedAt == addedAt;

  @override
  int get hashCode => Object.hash(listId, participantId, addedAt);

  @override
  String toString() =>
      'ListMember(listId: $listId, participantId: $participantId)';
}
