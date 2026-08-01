class Participant {
  final String id;
  final String kind;

  const Participant({required this.id, required this.kind});

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        kind: json['kind'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind};

  Participant copyWith({String? id, String? kind}) =>
      Participant(id: id ?? this.id, kind: kind ?? this.kind);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Participant && other.id == id && other.kind == kind;

  @override
  int get hashCode => Object.hash(id, kind);

  @override
  String toString() => 'Participant(id: $id, kind: $kind)';
}
