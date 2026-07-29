import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../models/expense_split.dart';
import '../repositories/expenses_repository.dart';

class ExpenseService {
  final ExpensesRepository _repo;
  final _uuid = const Uuid();

  ExpenseService(this._repo);

  Future<Expense> createExpense({
    required double amount,
    required String category,
    required String splitType,
    required String payerId,
    String? listId,
    String? note,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      amount: amount,
      category: category,
      splitType: splitType,
      payerId: payerId,
      listId: listId,
      note: note,
      idempotencyKey: _uuid.v4(),
      createdAt: DateTime.now(),
    );
    return _repo.createExpense(expense);
  }

  List<ExpenseSplit> calculateEqualSplits({
    required double amount,
    required List<String> participantIds,
  }) {
    final share = (amount / participantIds.length);
    return participantIds.map((pid) {
      return ExpenseSplit(
        id: _uuid.v4(),
        expenseId: '',
        participantId: pid,
        shareAmount: double.parse(share.toStringAsFixed(2)),
      );
    }).toList();
  }

  List<ExpenseSplit> calculateCustomSplits({
    required double amount,
    required Map<String, double> shares,
  }) {
    final totalShare = shares.values.fold(0.0, (a, b) => a + b);
    return shares.entries.map((e) {
      final shareAmount = (amount * e.value / totalShare);
      return ExpenseSplit(
        id: _uuid.v4(),
        expenseId: '',
        participantId: e.key,
        shareAmount: double.parse(shareAmount.toStringAsFixed(2)),
        rawInput: e.value,
      );
    }).toList();
  }

  Future<List<Expense>> getExpenses({String? listId}) {
    return _repo.getExpenses(listId);
  }
}
