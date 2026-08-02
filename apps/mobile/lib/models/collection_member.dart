class CollectionMember {
  final String collectionId;
  final String participantId;
  final DateTime addedAt;

  const CollectionMember({
    required this.collectionId,
    required this.participantId,
    required this.addedAt,
  });

  factory CollectionMember.fromJson(Map<String, dynamic> json) =>
      CollectionMember(
        collectionId: json['list_id'] as String,
        participantId: json['participant_id'] as String,
        addedAt: DateTime.parse(json['added_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'list_id': collectionId,
        'participant_id': participantId,
        'added_at': addedAt.toIso8601String(),
      };

  CollectionMember copyWith({
    String? collectionId,
    String? participantId,
    DateTime? addedAt,
  }) =>
      CollectionMember(
        collectionId: collectionId ?? this.collectionId,
        participantId: participantId ?? this.participantId,
        addedAt: addedAt ?? this.addedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CollectionMember &&
          other.collectionId == collectionId &&
          other.participantId == participantId &&
          other.addedAt == addedAt;

  @override
  int get hashCode => Object.hash(collectionId, participantId, addedAt);

  @override
  String toString() =>
      'CollectionMember(collectionId: $collectionId, participantId: '
      '$participantId)';
}
