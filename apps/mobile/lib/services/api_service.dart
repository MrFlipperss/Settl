import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'http_client_service.dart';

/// Example API service showing how to use the HTTP client
class ApiService {
  final HttpClientService _http;

  ApiService(this._http);

  // Example: Health check endpoint
  Future<bool> checkHealth() async {
    try {
      final response = await _http.get('health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Example: Get some data
  Future<Map<String, dynamic>> getData() async {
    return _http.getJson('api/data');
  }

  // Example: Post some data
  Future<Map<String, dynamic>> createData(Map<String, dynamic> data) async {
    return _http.postJson('api/data', body: data);
  }

  // Example: Update some data
  Future<Map<String, dynamic>> updateData(String id, Map<String, String> data) async {
    return _http.putJson('api/data/$id', body: data);
  }

  // Example: Delete some data
  Future<bool> deleteData(String id) async {
    final response = await _http.delete('api/data/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }
}