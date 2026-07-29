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
}
