import '../database/database.dart';
import '../models/expense.dart';
import '../models/expense_split.dart';

class ExpensesRepository {
  final Database _db;

  ExpensesRepository(this._db);

  Future<List<Expense>> getExpenses(String? listId) async {
    var query = _db.client.from('expenses').select();
    if (listId != null) query = query.eq('list_id', listId);
    final response = await query;
    return response.map((json) => Expense.fromJson(json)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await _db.client
        .from('expenses')
        .insert(expense.toJson())
        .select()
        .single();
    return Expense.fromJson(response);
  }

  Future<List<ExpenseSplit>> getSplits(String expenseId) async {
    final response = await _db.client
        .from('expense_splits')
        .select()
        .eq('expense_id', expenseId);
    return response.map((json) => ExpenseSplit.fromJson(json)).toList();
  }

  Future<void> createSplits(List<ExpenseSplit> splits) async {
    await _db.client
        .from('expense_splits')
        .insert(splits.map((s) => s.toJson()).toList());
  }
}
