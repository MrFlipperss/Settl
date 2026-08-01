import 'api_client.dart';
import 'models/api_health.dart';

/// T7.6 — Health endpoint.
///
/// Lives at the origin root (`/health`), outside the `/api/v1` prefix, so the
/// backing [ApiClient] must be constructed with [apiRootUrlProvider] and is
/// unauthenticated.
class HealthApi {
  HealthApi(this._client);

  final ApiClient _client;

  /// Probes backend liveness. Throws [ApiException] when unhealthy.
  Future<ApiHealth> checkHealth() async {
    final json = await _client.get('health');
    return ApiHealth.fromJson(json as Map<String, dynamic>);
  }
}
