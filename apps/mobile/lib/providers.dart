import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/config_provider.dart';
import '../services/http_client_service.dart';
import '../services/secure_storage_service.dart';

/// Provider for tracking the current selected index in the bottom navigation bar.
/// This is now enhanced to work with our configuration system
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Example of how to use configuration values in providers
final exampleConfigProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return 'Running ${config.appName} v${config.appVersion} in ${config.environment} mode';
});

/// Provider for the HTTP client service
final httpClientServiceProvider = Provider<HttpClientService>((ref) {
  return HttpClientService(ref);
});

/// Provider for the secure token storage service
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});