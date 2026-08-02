class Collection {
  final String id;
  final String name;
  final String accountNumber;
  final String createdBy;
  final DateTime createdAt;

  const Collection({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.createdBy,
    required this.createdAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) => Collection(
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

  Collection copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? createdBy,
    DateTime? createdAt,
  }) =>
      Collection(
        id: id ?? this.id,
        name: name ?? this.name,
        accountNumber: accountNumber ?? this.accountNumber,
        createdBy: createdBy ?? this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Collection &&
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
      'Collection(id: $id, name: $name, accountNumber: $accountNumber, '
      'createdBy: $createdBy)';
}
