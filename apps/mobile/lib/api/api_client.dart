import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Minimal HTTP client for the Settl backend.
///
/// Wraps a plain [http.Client] (injectable for tests via `MockClient`),
/// resolves paths against [baseUrl], and attaches the current Supabase
/// access token as `Authorization: Bearer` when [tokenProvider] yields one.
///
/// Every method decodes JSON responses and throws [ApiException] on
/// non-success status codes, preferring the backend's `{"error": "..."}`
/// message when present.
class ApiClient {
  ApiClient({
    required http.Client client,
    required String baseUrl,
    String? Function()? tokenProvider,
  })  : _client = client,
        _baseUrl = baseUrl,
        _tokenProvider = tokenProvider;

  final http.Client _client;
  final String _baseUrl;
  final String? Function()? _tokenProvider;

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$_baseUrl/$cleanPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{
      'accept': 'application/json',
      if (jsonBody) 'content-type': 'application/json',
    };
    final token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Decodes a response body, throwing [ApiException] on failure.
  ///
  /// [expected] lists status codes treated as success; defaults to {200}.
  /// A 204/empty body decodes to `null`.
  dynamic _decode(http.Response response, {Set<int>? expected}) {
    final ok = expected ?? const {200};
    if (ok.contains(response.statusCode)) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw _errorFrom(response);
  }

  ApiException _errorFrom(http.Response response) {
    var message = 'Request failed with status ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) {
        message = body['error'] as String;
      }
    } on FormatException {
      // Non-JSON error body — keep the generic message.
    }
    return ApiException(message, response.statusCode);
  }

  /// Sends a GET request to [path] with optional [query] parameters.
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query), headers: _headers());
    return _decode(response);
  }

  /// Sends a POST request to [path] with a JSON-encoded [body].
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final response = await _client.post(
      _uri(path, query),
      headers: _headers(jsonBody: body != null),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response, expected: const {200, 201});
  }

  /// Sends a PUT request to [path] with a JSON-encoded [body].
  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _client.put(
      _uri(path),
      headers: _headers(jsonBody: body != null),
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  /// Sends a DELETE request to [path]; treats 2xx as success.
  Future<void> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers());
    _decode(response, expected: const {200, 201, 204});
  }
}
