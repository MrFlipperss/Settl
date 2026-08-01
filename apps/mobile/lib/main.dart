import 'dart:developer' as developer show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settl/config/environment.dart';
import 'package:settl/config/config_provider.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration
  await Environment.init();

  // Log the environment in debug mode
  if (kDebugMode) {
    developer.log('Application starting in ${Environment.currentEnvironment} mode',
        name: 'APP_STARTUP');
  }

  runApp(const ProviderScope(child: SettlApp()));
}