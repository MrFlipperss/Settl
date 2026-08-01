import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../config/config_provider.dart';

/// HTTP Client Service for making HTTP requests with environment-aware configuration
class HttpClientService {
  final Ref? _ref;
  late final http.Client _client;
  late final String _baseUrl;

  HttpClientService(this._ref)
      : _client = http.Client(),
        _baseUrl = _ref != null ? _ref!.read(apiBaseUrlProvider) : '';

  String _buildUrl(String endpoint) {
    // Remove leading slash if present to avoid double slashes
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return '$_baseUrl/$cleanEndpoint';
  }

  /// GET request
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint);
    final requestHeaders = Map<String, String>.from(headers ?? {});

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🔵 GET Request: $url');
        if (requestHeaders.isNotEmpty) {
          print('📋 Headers: $requestHeaders');
        }
      }
    }

    final response = await _client.get(
      Uri.parse(url),
      headers: requestHeaders,
    );

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟢 GET Response [${response.statusCode}]: $url');
        if (enableLogging && response.body.length < 1000) {
          // Only log small responses to avoid spam
          print('📄 Response Body: ${response.body}');
        } else if (enableLogging) {
          print('📄 Response Body: [${response.body.length} bytes]');
        }
        if (response.statusCode >= 400) {
          print('🔴 HTTP Error: ${response.statusCode}');
        }
      }
    }

    return response;
  }

  /// POST request
  Future<http.Response> post(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    Encoding? encoding,
  }) async {
    final url = _buildUrl(endpoint);
    final requestHeaders = Map<String, String>.from(headers ?? {});
    final requestBody = body;

    // Set content type if not provided and we have a body
    if (requestBody != null && !requestHeaders.containsKey('content-type')) {
      requestHeaders['content-type'] = 'application/json';
    }

    // Encode body if it's a map/list and we're sending JSON
    final encodedBody = requestBody is Map || requestBody is List
        ? jsonEncode(requestBody)
        : requestBody as String?;

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟠 POST Request: $url');
        if (requestHeaders.isNotEmpty) {
          print('📋 Headers: $requestHeaders');
        }
        if (encodedBody != null && encodedBody.length < 500) {
          print('📥 Request Body: $encodedBody');
        }
      }
    }

    final response = await _client.post(
      Uri.parse(url),
      headers: requestHeaders,
      body: encodedBody,
      encoding: encoding,
    );

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟢 POST Response [${response.statusCode}]: $url');
        if (enableLogging && response.body.length < 1000) {
          print('📄 Response Body: ${response.body}');
        } else if (enableLogging) {
          print('📄 Response Body: [${response.body.length} bytes]');
        }
        if (response.statusCode >= 400) {
          print('🔴 HTTP Error: ${response.statusCode}');
        }
      }
    }

    return response;
  }

  /// PUT request
  Future<http.Response> put(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    Encoding? encoding,
  }) async {
    final url = _buildUrl(endpoint);
    final requestHeaders = Map<String, String>.from(headers ?? {});
    final requestBody = body;

    // Set content type if not provided and we have a body
    if (requestBody != null && !requestHeaders.containsKey('content-type')) {
      requestHeaders['content-type'] = 'application/json';
    }

    // Encode body if it's a map/list and we're sending JSON
    final encodedBody = requestBody is Map || requestBody is List
        ? jsonEncode(requestBody)
        : requestBody as String?;

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟠 PUT Request: $url');
        if (requestHeaders.isNotEmpty) {
          print('📋 Headers: $requestHeaders');
        }
        if (encodedBody != null && encodedBody.length < 500) {
          print('📥 Request Body: $encodedBody');
        }
      }
    }

    final response = await _client.put(
      Uri.parse(url),
      headers: requestHeaders,
      body: encodedBody,
      encoding: encoding,
    );

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟢� PUT Response [${response.statusCode}]: $url');
        if (enableLogging && response.body.length < 1000) {
          print('📄 Response Body: ${response.body}');
        } else if (enableLogging) {
          print('📄 Response Body: [${response.body.length} bytes]');
        }
        if (response.statusCode >= 400) {
          print('🔴 HTTP Error: ${response.statusCode}');
        }
      }
    }

    return response;
  }

  /// PATCH request
  Future<http.Response> patch(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    Encoding? encoding,
  }) async {
    final url = _buildUrl(endpoint);
    final requestHeaders = Map<String, String>.from(headers ?? {});
    final requestBody = body;

    // Set content type if not provided and we have a body
    if (requestBody != null && !requestHeaders.containsKey('content-type')) {
      requestHeaders['content-type'] = 'application/json';
    }

    // Encode body if it's a map/list and we're sending JSON
    final encodedBody = requestBody is Map || requestBody is List
        ? jsonEncode(requestBody)
        : requestBody as String?;

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟠 PATCH Request: $url');
        if (requestHeaders.isNotEmpty) {
          print('📋 Headers: $requestHeaders');
        }
        if (encodedBody != null && encodedBody.length < 500) {
          print('📥 Request Body: $encodedBody');
        }
      }
    }

    final response = await _client.patch(
      Uri.parse(url),
      headers: requestHeaders,
      body: encodedBody,
      encoding: encoding,
    );

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟢 PATCH Response [${response.statusCode}]: $url');
        if (enableLogging && response.body.length < 1000) {
          print('📄 Response Body: ${response.body}');
        } else if (enableLogging) {
          print('📄 Response Body: [${response.body.length} bytes]');
        }
        if (response.statusCode >= 400) {
          print('🔴 HTTP Error: ${response.statusCode}');
        }
      }
    }

    return response;
  }

  /// DELETE request
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = _buildUrl(endpoint);
    final requestHeaders = Map<String, String>.from(headers ?? {});

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🔴 DELETE Request: $url');
        if (requestHeaders.isNotEmpty) {
          print('📋 Headers: $requestHeaders');
        }
      }
    }

    final response = await _client.delete(
      Uri.parse(url),
      headers: requestHeaders,
    );

    if (_ref != null) {
      final enableLogging = _ref!.read(enableLoggingProvider);
      if (enableLogging) {
        print('🟢 DELETE Response [${response.statusCode}]: $url');
        if (enableLogging && response.body.length < 1000) {
          print('📄 Response Body: ${response.body}');
        } else if (enableLogging) {
          print('📄 Response Body: [${response.body.length} bytes]');
        }
        if (response.statusCode >= 400) {
          print('🔴 HTTP Error: ${response.statusCode}');
        }
      }
    }

    return response;
  }

  /// Convenience method for getting JSON data
  Future<T> getJson<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await get(endpoint, headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return fromJson != null ? fromJson(json) : json as T;
    } else {
      throw HttpException('Failed to load data: ${response.statusCode}');
    }
  }

  /// Convenience method for posting JSON data
  Future<T> postJson<T>(
    String endpoint, {
    Object? body,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJson,
  }) async {
    final response = await post(
      endpoint,
      body: body,
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return fromJson != null ? fromJson(json) : json as T;
    } else {
      throw HttpException('Failed to create resource: ${response.statusCode}');
    }
  }

  /// Close the HTTP client
  Future<void> close() async {
    _client.close();
  }
}

/// Exception class for HTTP errors
class HttpException implements Exception {
  final String message;
  final int? statusCode;

  HttpException(this.message, [this.statusCode]);

  @override
  String toString() => 'HttpException: $message${statusCode != null ? ' (Status Code: $statusCode)' : ''}';
}

/// Provider for the HTTP client service
final httpClientServiceProvider = Provider<HttpClientService>((ref) {
  return HttpClientService(ref);
});

/// Provider for the raw HTTP client (for advanced use cases)
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});