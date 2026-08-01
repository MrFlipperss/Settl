const _unset = Object();

class ReceiptDetail {
  final String expenseId;
  final String createdBy;
  final String? merchant;
  final double? ocrTotal;
  final String? ocrDate;
  final List<String>? lineItems;
  final DateTime createdAt;

  const ReceiptDetail({
    required this.expenseId,
    required this.createdBy,
    this.merchant,
    this.ocrTotal,
    this.ocrDate,
    this.lineItems,
    required this.createdAt,
  });

  factory ReceiptDetail.fromJson(Map<String, dynamic> json) => ReceiptDetail(
        expenseId: json['expense_id'] as String,
        createdBy: json['created_by'] as String,
        merchant: json['merchant'] as String?,
        ocrTotal: json['ocr_total'] != null
            ? (json['ocr_total'] as num).toDouble()
            : null,
        ocrDate: json['ocr_date'] as String?,
        lineItems: json['line_items'] != null
            ? List<String>.from(json['line_items'] as List)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'expense_id': expenseId,
        'created_by': createdBy,
        'merchant': merchant,
        'ocr_total': ocrTotal,
        'ocr_date': ocrDate,
        'line_items': lineItems,
        'created_at': createdAt.toIso8601String(),
      };

  ReceiptDetail copyWith({
    String? expenseId,
    String? createdBy,
    Object? merchant = _unset,
    Object? ocrTotal = _unset,
    Object? ocrDate = _unset,
    Object? lineItems = _unset,
    DateTime? createdAt,
  }) =>
      ReceiptDetail(
        expenseId: expenseId ?? this.expenseId,
        createdBy: createdBy ?? this.createdBy,
        merchant: identical(merchant, _unset) ? this.merchant : merchant as String?,
        ocrTotal: identical(ocrTotal, _unset) ? this.ocrTotal : ocrTotal as double?,
        ocrDate: identical(ocrDate, _unset) ? this.ocrDate : ocrDate as String?,
        lineItems: identical(lineItems, _unset)
            ? this.lineItems
            : lineItems as List<String>?,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptDetail &&
          other.expenseId == expenseId &&
          other.createdBy == createdBy &&
          other.merchant == merchant &&
          other.ocrTotal == ocrTotal &&
          other.ocrDate == ocrDate &&
          _listEquals(other.lineItems, lineItems) &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(expenseId, createdBy, merchant, ocrTotal,
      ocrDate, Object.hashAll(lineItems ?? const []), createdAt);

  @override
  String toString() =>
      'ReceiptDetail(expenseId: $expenseId, createdBy: $createdBy, '
      'merchant: $merchant, ocrTotal: $ocrTotal, ocrDate: $ocrDate, '
      'lineItems: $lineItems)';

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
