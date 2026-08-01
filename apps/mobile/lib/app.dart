import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settl/config/config_provider.dart';
import 'routing/app_router.dart';

class SettlApp extends ConsumerWidget {
  const SettlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfig = ref.watch(appConfigProvider);

    return MaterialApp.router(
      title: appConfig.appName,
      debugShowCheckedModeBanner: !appConfig.enableDebug, // Hide debug banner in production
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: appConfig.enableDebug
          ? ThemeMode.system
          : ThemeMode.light, // Force light mode in production
      routerConfig: appRouter,
    );
  }
}
