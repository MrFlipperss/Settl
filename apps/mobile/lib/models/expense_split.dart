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
}
