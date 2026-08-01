import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settl/config/config_provider.dart';
import 'package:settl/theme/app_theme.dart';
import 'providers.dart';
import 'routing/app_router.dart';

class SettlApp extends ConsumerWidget {
  const SettlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: appConfig.appName,
      debugShowCheckedModeBanner: !appConfig.enableDebug, // Hide debug banner in production
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
