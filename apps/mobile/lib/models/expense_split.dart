const _unset = Object();

class ExpenseSplit {
  final String id;
  final String expenseId;
  final String participantId;
  final double shareAmount;
  final double? rawInput;

  const ExpenseSplit({
    required this.id,
    required this.expenseId,
    required this.participantId,
    required this.shareAmount,
    this.rawInput,
  });

  factory ExpenseSplit.fromJson(Map<String, dynamic> json) => ExpenseSplit(
        id: json['id'] as String,
        expenseId: json['expense_id'] as String,
        participantId: json['participant_id'] as String,
        shareAmount: (json['share_amount'] as num).toDouble(),
        rawInput: json['raw_input'] != null
            ? (json['raw_input'] as num).toDouble()
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'expense_id': expenseId,
        'participant_id': participantId,
        'share_amount': shareAmount,
        'raw_input': rawInput,
      };

  ExpenseSplit copyWith({
    String? id,
    String? expenseId,
    String? participantId,
    double? shareAmount,
    Object? rawInput = _unset,
  }) =>
      ExpenseSplit(
        id: id ?? this.id,
        expenseId: expenseId ?? this.expenseId,
        participantId: participantId ?? this.participantId,
        shareAmount: shareAmount ?? this.shareAmount,
        rawInput: identical(rawInput, _unset)
            ? this.rawInput
            : rawInput as double?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseSplit &&
          other.id == id &&
          other.expenseId == expenseId &&
          other.participantId == participantId &&
          other.shareAmount == shareAmount &&
          other.rawInput == rawInput;

  @override
  int get hashCode =>
      Object.hash(id, expenseId, participantId, shareAmount, rawInput);

  @override
  String toString() =>
      'ExpenseSplit(id: $id, expenseId: $expenseId, '
      'participantId: $participantId, shareAmount: $shareAmount, '
      'rawInput: $rawInput)';
}
