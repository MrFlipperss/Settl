const _unset = Object();

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

  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    String? splitType,
    String? payerId,
    Object? listId = _unset,
    Object? note = _unset,
    Object? idempotencyKey = _unset,
    int? version,
    DateTime? createdAt,
  }) =>
      Expense(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        splitType: splitType ?? this.splitType,
        payerId: payerId ?? this.payerId,
        listId: identical(listId, _unset) ? this.listId : listId as String?,
        note: identical(note, _unset) ? this.note : note as String?,
        idempotencyKey: identical(idempotencyKey, _unset)
            ? this.idempotencyKey
            : idempotencyKey as String?,
        version: version ?? this.version,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          other.id == id &&
          other.amount == amount &&
          other.category == category &&
          other.splitType == splitType &&
          other.payerId == payerId &&
          other.listId == listId &&
          other.note == note &&
          other.idempotencyKey == idempotencyKey &&
          other.version == version &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, amount, category, splitType, payerId,
      listId, note, idempotencyKey, version, createdAt);

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, category: $category, '
      'splitType: $splitType, payerId: $payerId, listId: $listId, '
      'note: $note, version: $version, createdAt: $createdAt)';
}
