class ListModel {
  final String id;
  final String name;
  final String accountNumber;
  final String createdBy;
  final DateTime createdAt;

  const ListModel({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.createdBy,
    required this.createdAt,
  });

  factory ListModel.fromJson(Map<String, dynamic> json) => ListModel(
        id: json['id'] as String,
        name: json['name'] as String,
        accountNumber: json['account_number'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'account_number': accountNumber,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  ListModel copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? createdBy,
    DateTime? createdAt,
  }) =>
      ListModel(
        id: id ?? this.id,
        name: name ?? this.name,
        accountNumber: accountNumber ?? this.accountNumber,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListModel &&
          other.id == id &&
          other.name == name &&
          other.accountNumber == accountNumber &&
          other.createdBy == createdBy &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, name, accountNumber, createdBy, createdAt);

  @override
  String toString() =>
      'ListModel(id: $id, name: $name, accountNumber: $accountNumber, '
      'createdBy: $createdBy)';
}
