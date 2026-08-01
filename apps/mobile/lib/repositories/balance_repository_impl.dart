import 'package:settl/database/daos/expenses_dao.dart';
import 'package:settl/models/balance.dart';
import 'package:settl/models/expense.dart';
import 'package:settl/models/expense_split.dart';
import 'package:settl/repositories/interfaces/balance_repository.dart';

/// Local [BalanceRepository].
///
/// Derives pairwise net balances from locally stored expense splits, mirroring
/// the backend `pairwise_balances` view:
/// - for every split, the participant owes [ExpenseSplit.shareAmount] to the
///   expense's [Expense.payerId];
/// - opposing edges are netted per ordered participant pair;
/// - only non-zero balances are returned (a positive [Balance.amountOwed]
///   means [Balance.fromParticipantId] owes [Balance.toParticipantId]).
class BalanceRepositoryImpl implements BalanceRepository {
  final ExpensesDao _expensesDao;

  BalanceRepositoryImpl(this._expensesDao);

  @override
  Future<List<Balance>> getBalancesForParticipant(String participantId) async {
    final all = await getAllBalances();
    return all
        .where((b) =>
            b.fromParticipantId == participantId ||
            b.toParticipantId == participantId)
        .toList();
  }

  @override
  Future<List<Balance>> getAllBalances() async {
    final expenses = await _expensesDao.getAllExpenses();
    final owed = <String, double>{};

    for (final expense in expenses) {
      final splits = await _expensesDao.getSplitsForExpense(expense.id);
      for (final split in splits) {
        // A participant never owes the payer their own share of a bill
        // they paid, and a payer's split is owed to the payer itself.
        if (split.participantId == expense.payerId) continue;
        final key = _pairKey(split.participantId, expense.payerId);
        owed[key] = (owed[key] ?? 0) + split.shareAmount;
      }
    }

    final balances = <Balance>[];
    final netted = <String>{};

    for (final MapEntry(key: key, value: amount) in owed.entries) {
      if (netted.contains(key)) continue;
      final from = key.split('|')[0];
      final to = key.split('|')[1];
      final reverseKey = _pairKey(to, from);
      final net = amount - (owed[reverseKey] ?? 0);
      netted.add(key);
      netted.add(reverseKey);

      if (net.abs() < 0.005) continue; // rounded away to zero
      balances.add(Balance(
        fromParticipantId: net > 0 ? from : to,
        toParticipantId: net > 0 ? to : from,
        amountOwed: _round2(net.abs()),
      ));
    }

    return balances;
  }

  static String _pairKey(String a, String b) => '$a|$b';

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}
