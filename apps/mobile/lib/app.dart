import 'package:flutter/material.dart';
import 'features/navigation/shell.dart';

class SettlApp extends StatelessWidget {
  const SettlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B5E20),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const AppShell(),
    );
  }
}
