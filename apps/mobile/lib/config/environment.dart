import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Environment configuration for the Settl app
class Environment {
  // Environment types
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  // Current environment
  static String? _currentEnvironment;

  // Backend URLs for different environments
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.production:
        return 'https://settl-kru1.onrender.com';
      case Environment.staging:
        return 'https://settl-staging.onrender.com'; // Example staging URL
      case Environment.development:
      default:
        return 'https://settl-kru1.onrender.com'; // Default to production for safety
    }
  }

  // Supabase configuration
  static String get supabaseUrl {
    // In a real app, these would come from secure storage or build flavors
    return 'https://rgrswhlyuvpicfbajhen.supabase.co';
  }

  static String get supabaseAnonKey {
    // This would normally be stored securely, not in code
    // For demo purposes, we're showing the concept
    return 'your-anon-key-here'; // Replace with actual key from secure source
  }

  // Feature flags
  static bool get enableAnalytics =>
      _currentEnvironment == Environment.production ||
      _currentEnvironment == Environment.staging;

  static bool get enableDebugFeatures =>
      _currentEnvironment == Environment.development;

  static bool get enableLogging =>
      _currentEnvironment != Environment.production;

  // App configuration
  static String get appName => 'Settl';
  static String get appVersion {
    // In a real app, this would come from package info
    return '1.0.0';
  }

  /// Initialize the environment configuration
  /// Detects the current environment and loads appropriate settings
  static Future<void> init() async {
    // In a production app, you might determine environment from:
    // - Build flavors (flutter run --dart-define=ENVIRONMENT=production)
    // - Remote config service
    // - Build-time constants

    // For now, we'll default to development in debug mode
    if (kDebugMode) {
      _currentEnvironment = Environment.development;
    } else if (kProfileMode) {
      _currentEnvironment = Environment.staging;
    } else {
      _currentEnvironment = Environment.production;
    }

    // Optionally load persisted preferences or overrides
    await _loadPreferences();

    // Log the environment in debug mode
    if (enableLogging) {
      debugPrint('Environment initialized: $_currentEnvironment');
      debugPrint('API Base URL: $apiBaseUrl');
    }
  }

  /// Load any environment-specific preferences
  static Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Could load environment overrides from shared preferences if needed
      // For example, allowing debug builds to point to staging environment
    } catch (e) {
      if (enableLogging) {
        debugPrint('Warning: Could not load environment preferences: $e');
      }
    }
  }

  /// Get the current environment
  static String get currentEnvironment =>
      _currentEnvironment ?? Environment.development;

  /// Check if we're running in a specific environment
  static bool isInEnvironment(String environment) =>
      _currentEnvironment == environment;

  /// Override the environment (useful for testing)
  static void setEnvironment(String environment) {
    _currentEnvironment = environment;
    if (kDebugMode) {
      debugPrint('Environment overridden to: $environment');
    }
  }
}