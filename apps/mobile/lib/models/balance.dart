/// A single pairwise balance between two participants.
///
/// Mirrors the backend `pairwise_balances` view: one row per
/// (from_participant, to_participant) with a signed net amount. A positive
/// [amountOwed] means [fromParticipantId] owes [toParticipantId].
class Balance {
  final String fromParticipantId;
  final String toParticipantId;
  final double amountOwed;

  const Balance({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amountOwed,
  });

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        fromParticipantId: json['from_participant'] as String,
        toParticipantId: json['to_participant'] as String,
        amountOwed: (json['amount_owed'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'from_participant': fromParticipantId,
        'to_participant': toParticipantId,
        'amount_owed': amountOwed,
      };

  Balance copyWith({
    String? fromParticipantId,
    String? toParticipantId,
    double? amountOwed,
  }) =>
      Balance(
        fromParticipantId: fromParticipantId ?? this.fromParticipantId,
        toParticipantId: toParticipantId ?? this.toParticipantId,
        amountOwed: amountOwed ?? this.amountOwed,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Balance &&
          other.fromParticipantId == fromParticipantId &&
          other.toParticipantId == toParticipantId &&
          other.amountOwed == amountOwed;

  @override
  int get hashCode =>
      Object.hash(fromParticipantId, toParticipantId, amountOwed);

  @override
  String toString() =>
      'Balance(from: $fromParticipantId, to: $toParticipantId, '
      'amount: $amountOwed)';
}
