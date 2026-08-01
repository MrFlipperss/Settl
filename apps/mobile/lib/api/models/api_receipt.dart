/// Wire-format receipt detail from the backend `receipt_details` table.
class ApiReceiptDetail {
  const ApiReceiptDetail({
    required this.expenseId,
    this.merchant,
    this.ocrTotalPaise,
    this.ocrDate,
    required this.lineItems,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String expenseId;
  final String? merchant;

  /// OCR-extracted total in paise, when available.
  final int? ocrTotalPaise;

  /// OCR-extracted date, as a raw string (e.g. `"2026-07-01"`).
  final String? ocrDate;

  final List<String> lineItems;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  factory ApiReceiptDetail.fromJson(Map<String, dynamic> json) =>
      ApiReceiptDetail(
        expenseId: json['expense_id'] as String,
        merchant: json['merchant'] as String?,
        ocrTotalPaise: (json['ocr_total_paise'] as num?)?.toInt(),
        ocrDate: json['ocr_date'] as String?,
        lineItems: (json['line_items'] as List? ?? const []).cast<String>(),
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        deletedAt: json['deleted_at'] != null
            ? DateTime.parse(json['deleted_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'expense_id': expenseId,
        'merchant': merchant,
        'ocr_total_paise': ocrTotalPaise,
        'ocr_date': ocrDate,
        'line_items': lineItems,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiReceiptDetail &&
          other.expenseId == expenseId &&
          other.merchant == merchant &&
          other.ocrTotalPaise == ocrTotalPaise &&
          other.ocrDate == ocrDate &&
          _listEquals(other.lineItems, lineItems) &&
          other.createdBy == createdBy &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(expenseId, merchant, ocrTotalPaise, ocrDate,
      Object.hashAll(lineItems), createdBy, createdAt, updatedAt, deletedAt);

  @override
  String toString() =>
      'ApiReceiptDetail(expenseId: $expenseId, merchant: $merchant, '
      'ocrTotalPaise: $ocrTotalPaise, lineItems: ${lineItems.length})';

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
