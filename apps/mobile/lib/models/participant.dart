class Participant {
  final String id;
  final String kind;

  const Participant({required this.id, required this.kind});

  factory Participant.fromJson(Map<String, dynamic> json) => Participant(
        id: json['id'] as String,
        kind: json['kind'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind};
}
