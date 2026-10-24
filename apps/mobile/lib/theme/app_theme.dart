import 'package:flutter/material.dart';

/// Material 3 theme definitions for Settl.
///
/// Light and dark Material 3 themes generated from the selected accent color.
class AppTheme {
  AppTheme._();

  static ThemeData build({required Color accent, required bool isDark}) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      cardTheme: const CardThemeData(clipBehavior: Clip.antiAlias),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          side: BorderSide(color: colorScheme.outline),
        ),
      ),
    );
  }
}

class AccentPreset {
  const AccentPreset({
    required this.name,
    required this.hex,
  });

  final String name;
  final Color hex;
}

const List<AccentPreset> accentPresets = [
  AccentPreset(name: 'Teal', hex: Color(0xFF00796B)),
  AccentPreset(name: 'Blue', hex: Color(0xFF2979FF)),
  AccentPreset(name: 'Green', hex: Color(0xFF2E7D32)),
  AccentPreset(name: 'Orange', hex: Color(0xFFEF6C00)),
  AccentPreset(name: 'Rose', hex: Color(0xFFE53966)),
  AccentPreset(name: 'Indigo', hex: Color(0xFF3949AB)),
  AccentPreset(name: 'Amber', hex: Color(0xFFFF8F00)),
  AccentPreset(name: 'Cyan', hex: Color(0xFF00838F)),
];

class DesignTokens {
  const DesignTokens({
    required this.primary,
    required this.onSurface,
    required this.onSurfaceVar,
    required this.surfaceVariant,
    required this.container,
    required this.onContainer,
    required this.cardBg,
    required this.border,
    required this.headerBg,
  });

  final Color primary;
  final Color onSurface;
  final Color onSurfaceVar;
  final Color surfaceVariant;
  final Color container;
  final Color onContainer;
  final Color cardBg;
  final Color border;
  final Color headerBg;

  factory DesignTokens.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DesignTokens(
      primary: scheme.primary,
      onSurface: scheme.onSurface,
      onSurfaceVar: scheme.onSurfaceVariant,
      surfaceVariant: scheme.surfaceContainerHighest,
      container: scheme.secondaryContainer,
      onContainer: scheme.onSecondaryContainer,
      cardBg: scheme.surfaceContainerLow,
      border: scheme.outlineVariant,
      headerBg: scheme.surface,
    );
  }
}
