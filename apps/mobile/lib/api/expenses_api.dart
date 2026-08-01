import 'api_client.dart';
import 'models/api_expense.dart';
import 'models/api_receipt.dart';
import 'models/api_requests.dart';

/// T7.4 — Expenses API.
///
/// Full CRUD for expenses plus receipt attachment/retrieval. The backend
/// forces `payer_id` to the authenticated caller and resolves split shares
/// server-side from the split-type-specific fields in [ApiCreateSplitItem].
class ExpensesApi {
  ExpensesApi(this._client);

  final ApiClient _client;

  /// Creates an expense (201). Amounts are rupee doubles; the backend stores
  /// paise.
  Future<ApiExpense> createExpense(ApiCreateExpenseRequest request) async {
    final json = await _client.post('v1/expenses/', body: request.toJson());
    return ApiExpense.fromJson(json as Map<String, dynamic>);
  }

  /// Lists expenses visible to the user, optionally filtered by group and a
  /// date window (RFC3339).
  Future<List<ApiExpense>> listExpenses({
    String? groupId,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, String>{
      if (groupId != null) 'groupID': groupId,
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    };
    final json = await _client.get('v1/expenses/', query: query);
    return (json as List)
        .map((e) => ApiExpense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single expense by id (403 when the user is not a participant).
  Future<ApiExpense> getExpense(String expenseId) async {
    final json = await _client.get('v1/expenses/$expenseId');
    return ApiExpense.fromJson(json as Map<String, dynamic>);
  }

  /// Updates an existing expense (payer-only; 403 otherwise).
  Future<ApiExpense> updateExpense(
    String expenseId,
    ApiCreateExpenseRequest request,
  ) async {
    final json =
        await _client.put('v1/expenses/$expenseId', body: request.toJson());
    return ApiExpense.fromJson(json as Map<String, dynamic>);
  }

  /// Deletes an expense (payer-only; backend returns 204).
  Future<void> deleteExpense(String expenseId) async {
    await _client.delete('v1/expenses/$expenseId');
  }

  /// Upserts receipt detail for an expense (payer-only; returns 200).
  Future<ApiReceiptDetail> createReceipt(
    String expenseId,
    ApiCreateReceiptRequest request,
  ) async {
    final json = await _client.post(
      'v1/expenses/$expenseId/receipt',
      body: request.toJson(),
    );
    return ApiReceiptDetail.fromJson(json as Map<String, dynamic>);
  }

  /// Fetches the receipt detail for an expense (404 when none exists).
  Future<ApiReceiptDetail> getReceipt(String expenseId) async {
    final json = await _client.get('v1/expenses/$expenseId/receipt');
    return ApiReceiptDetail.fromJson(json as Map<String, dynamic>);
  }
}
