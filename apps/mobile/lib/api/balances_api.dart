import 'api_client.dart';
import 'models/api_balance.dart';

/// T7.5 — Balances API.
///
/// Returns netted pairwise balances for the authenticated user (or an
/// arbitrary participant when [getBalances] is given a [personId]).
class BalancesApi {
  BalancesApi(this._client);

  final ApiClient _client;

  /// Fetches the balance summary for the authenticated user, optionally
  /// scoped to a specific participant via [personId].
  Future<ApiBalancesResponse> getBalances({String? personId}) async {
    final json = await _client.get(
      'v1/balances',
      query: {if (personId != null) 'personID': personId},
    );
    return ApiBalancesResponse.fromJson(json as Map<String, dynamic>);
  }
}
