import 'package:settl/models/balance.dart';

/// Contract for reading pairwise balances.
///
/// Local implementations derive balances from expense splits (mirroring the
/// backend `pairwise_balances` view); a remote implementation will follow in
/// the API layer phase. The UI depends on this interface only.
abstract class BalanceRepository {
  /// Net balances between [participantId] and every other participant.
  Future<List<Balance>> getBalancesForParticipant(String participantId);

  /// All non-zero pairwise net balances.
  Future<List<Balance>> getAllBalances();
}
