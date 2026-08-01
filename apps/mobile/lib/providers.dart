import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/config_provider.dart';

/// Provider for tracking the current selected index in the bottom navigation bar.
/// This is now enhanced to work with our configuration system
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Example of how to use configuration values in providers
final exampleConfigProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return 'Running ${config.appName} v${config.appVersion} in ${config.environment} mode';
});