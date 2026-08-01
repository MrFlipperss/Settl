import 'package:flutter/foundation.dart';

/// Represents different environments the app can run in
enum AppEnvironment {
  development,
  staging,
  production;

  /// Returns true if the current environment is development
  bool get isDevelopment => this == AppEnvironment.development;

  /// Returns true if the current environment is staging
  bool get isStaging => this == AppEnvironment.staging;

  /// Returns true if the current environment is production
  bool get isProduction => this == AppEnvironment.production;

  /// Returns the base URL for the API based on the environment
  String get apiBaseUrl {
    switch (this) {
      case AppEnvironment.development:
        return 'http://localhost:3000/api';
      case AppEnvironment.staging:
        return 'https://staging-settl.onrender.com/api';
      case AppEnvironment.production:
        return 'https://settl-kru1.onrender.com/api';
    }
  }

  /// Returns the Supabase URL for the environment
  String get supabaseUrl {
    switch (this) {
      case AppEnvironment.development:
        return 'https://rgrswhlyuvpicfbajhen.supabase.co';
      case AppEnvironment.staging:
        return 'https://staging-settl.supabase.co';
      case AppEnvironment.production:
        return 'https://rgrswhlyuvpicfbajhen.supabase.co';
    }
  }

  /// Returns the Supabase anon key for the environment
  String get supabaseAnonKey {
    // In production, these should come from secure storage or build-time injection
    // For development, we can use hardcoded values or environment variables
    switch (this) {
      case AppEnvironment.development:
        return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';
      case AppEnvironment.staging:
        // Would come from secure build config
        return '';
      case AppEnvironment.production:
        // Would come from secure build config
        return '';
    }
  }

  /// Returns whether to enable debug features
  bool get enableDebug => !isProduction;

  /// Returns whether to enable logging
  bool get enableLogging => !kReleaseMode || isDevelopment;
}

/// Global configuration provider
class AppConfig {
  AppConfig._privateConstructor();

  static final AppConfig _instance = AppConfig._privateConstructor();
  factory AppConfig() => _instance;

  AppEnvironment _environment = AppEnvironment.development;
  late final String _appName;
  late final String _appVersion;
  late final String _buildNumber;

  /// Initialize the configuration
  /// Must be called before using the app
  Future<void> initialize({
    required AppEnvironment environment,
    String appName = 'Settl',
    String appVersion = '1.0.0',
    String buildNumber = '1',
  }) async {
    _environment = environment;
    _appName = appName;
    _appVersion = appVersion;
    _buildNumber = buildNumber;

    // Perform any async initialization here if needed
    await _loadEnvironmentSpecificConfig();
  }

  /// Load environment-specific configuration (could load from secure storage, etc.)
  Future<void> _loadEnvironmentSpecificConfig() async {
    // In a production app, this might load secure values from secure storage
    // or decrypt encrypted values baked into the binary
  }

  /// Get the current environment
  AppEnvironment get environment => _environment;

  /// Get the app name
  String get appName => _appName;

  /// Get the app version
  String get appVersion => _appVersion;

  /// Get the build number
  String get buildNumber => _buildNumber;

  /// Get the API base URL
  String get apiBaseUrl => _environment.apiBaseUrl;

  /// Get the Supabase URL
  String get supabaseUrl => _environment.supabaseUrl;

  /// Get the Supabase anon key
  String get supabaseAnonKey => _environment.supabaseAnonKey;

  /// Whether debug features are enabled
  bool get enableDebug => _environment.enableDebug;

  /// Whether logging is enabled
  bool get enableLogging => _environment.enableLogging;

  /// Check if running in debug mode
  bool get isDebugMode => kDebugMode;

  /// Check if running in profile mode
  bool get isProfileMode => kProfileMode;

  /// Check if running in release mode
  bool get isReleaseMode => kReleaseMode;
}

/// Helper extension to get the current config instance
extension ConfigExtension on Object? {
  AppConfig get config => AppConfig();
}