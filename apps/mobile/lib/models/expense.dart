class Expense {
  final String id;
  final double amount;
  final String category;
  final String splitType;
  final String payerId;
  final String? listId;
  final String? note;
  final String? idempotencyKey;
  final int version;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.splitType,
    required this.payerId,
    this.listId,
    this.note,
    this.idempotencyKey,
    this.version = 1,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        splitType: json['split_type'] as String,
        payerId: json['payer_id'] as String,
        listId: json['list_id'] as String?,
        note: json['note'] as String?,
        idempotencyKey: json['idempotency_key'] as String?,
        version: json['version'] as int? ?? 1,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'split_type': splitType,
        'payer_id': payerId,
        'list_id': listId,
        'note': note,
        'idempotency_key': idempotencyKey,
        'version': version,
        'created_at': createdAt.toIso8601String(),
      };
}
