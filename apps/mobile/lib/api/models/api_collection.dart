/// Wire-format collection (group) from the backend `lists` table.
///
/// The backend calls these "lists"; the app domain term is "collections".
class ApiCollection {
  const ApiCollection({
    required this.id,
    required this.accountNumber,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.version,
    required this.memberCount,
  });

  final String id;
  final String accountNumber;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int version;
  final int memberCount;

  factory ApiCollection.fromJson(Map<String, dynamic> json) => ApiCollection(
        id: json['id'] as String,
        accountNumber: json['account_number'] as String,
        name: json['name'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        version: json['version'] as int? ?? 1,
        memberCount: json['member_count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_number': accountNumber,
        'name': name,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'version': version,
        'member_count': memberCount,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCollection &&
          other.id == id &&
          other.accountNumber == accountNumber &&
          other.name == name &&
          other.createdBy == createdBy &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt &&
          other.version == version &&
          other.memberCount == memberCount;

  @override
  int get hashCode => Object.hash(id, accountNumber, name, createdBy, createdAt,
      updatedAt, deletedAt, version, memberCount);

  @override
  String toString() =>
      'ApiCollection(id: $id, accountNumber: $accountNumber, name: $name, '
      'createdBy: $createdBy, memberCount: $memberCount, version: $version)';
}
