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
}
