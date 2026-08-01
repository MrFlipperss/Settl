import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_environment.dart';

/// Provider for the app configuration
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig();
});

/// Provider for the current app environment
final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  return ref.watch(appConfigProvider).environment;
});

/// Provider for API base URL
final apiBaseUrlProvider = Provider<String>((ref) {
  return ref.watch(appConfigProvider).apiBaseUrl;
});

/// Provider for Supabase URL
final supabaseUrlProvider = Provider<String>((ref) {
  return ref.watch(appConfigProvider).supabaseUrl;
});

/// Provider for Supabase anon key
final supabaseAnonKeyProvider = Provider<String>((ref) {
  return ref.watch(appConfigProvider).supabaseAnonKey;
});

/// Provider for debug mode flag
final enableDebugProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).enableDebug;
});

/// Provider for logging enabled flag
final enableLoggingProvider = Provider<bool>((ref) {
  return ref.watch(appConfigProvider).enableLogging;
});