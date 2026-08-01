/// Wire-format expense from the backend `expenses` table.
///
/// Money is integer paise on the wire (`amount_paise`); the created time is
/// carried in the `timestamp` JSON field (the backend tag differs from the
/// local model's `created_at`).
class ApiExpense {
  const ApiExpense({
    required this.id,
    this.groupId,
    required this.payerId,
    required this.amountPaise,
    required this.category,
    this.note,
    required this.splitType,
    required this.version,
    required this.timestamp,
    this.updatedAt,
    this.deletedAt,
    required this.splits,
  });

  final String id;
  final String? groupId;
  final String payerId;
  final int amountPaise;
  final String category;
  final String? note;
  final String splitType;
  final int version;
  final DateTime timestamp;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final List<ApiSplit> splits;

  factory ApiExpense.fromJson(Map<String, dynamic> json) => ApiExpense(
        id: json['id'] as String,
        groupId: json['group_id'] as String?,
        payerId: json['payer_id'] as String,
        amountPaise: (json['amount_paise'] as num).toInt(),
        category: json['category'] as String,
        note: json['note'] as String?,
        splitType: json['split_type'] as String,
        version: json['version'] as int? ?? 1,
        timestamp: DateTime.parse(json['timestamp'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
        splits: (json['splits'] as List? ?? const [])
            .map((e) => ApiSplit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'payer_id': payerId,
        'amount_paise': amountPaise,
        'category': category,
        'note': note,
        'split_type': splitType,
        'version': version,
        'timestamp': timestamp.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'splits': splits.map((s) => s.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiExpense &&
          other.id == id &&
          other.groupId == groupId &&
          other.payerId == payerId &&
          other.amountPaise == amountPaise &&
          other.category == category &&
          other.note == note &&
          other.splitType == splitType &&
          other.version == version &&
          other.timestamp == timestamp &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt &&
          _listEquals(other.splits, splits);

  @override
  int get hashCode => Object.hash(
      id,
      groupId,
      payerId,
      amountPaise,
      category,
      note,
      splitType,
      version,
      timestamp,
      updatedAt,
      deletedAt,
      Object.hashAll(splits));

  @override
  String toString() =>
      'ApiExpense(id: $id, groupId: $groupId, payerId: $payerId, '
      'amountPaise: $amountPaise, category: $category, splitType: $splitType, '
      'version: $version, splits: ${splits.length})';

  static bool _listEquals(List<ApiSplit> a, List<ApiSplit> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Wire-format expense split from the backend `expense_splits` table.
class ApiSplit {
  const ApiSplit({
    this.id,
    required this.userId,
    required this.shareAmountPaise,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  /// Split id; may be absent in some responses.
  final String? id;

  /// Participant id (the backend JSON key is `user_id`).
  final String userId;

  /// This participant's share in paise.
  final int shareAmountPaise;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory ApiSplit.fromJson(Map<String, dynamic> json) => ApiSplit(
        id: json['id'] as String?,
        userId: json['user_id'] as String,
        shareAmountPaise: (json['share_amount_paise'] as num).toInt(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'share_amount_paise': shareAmountPaise,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiSplit &&
          other.id == id &&
          other.userId == userId &&
          other.shareAmountPaise == shareAmountPaise &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
      id, userId, shareAmountPaise, createdAt, updatedAt, deletedAt);

  @override
  String toString() => 'ApiSplit(id: $id, userId: $userId, shareAmountPaise: '
      '$shareAmountPaise)';
}
