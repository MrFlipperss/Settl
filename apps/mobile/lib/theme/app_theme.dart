import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Material 3 theme definitions for Settl.
///
/// Themes include:
/// - Light and Dark (standard Material 3)
/// - Liquid Glass (Apple-inspired frosted glass effect)
///
/// All themes derive their color scheme from the brand seed color
/// ([AppColors.primary]) via [ColorScheme.fromSeed], then apply
/// theme-specific styling.
class AppTheme {
  AppTheme._();

  /// Light theme (standard Material 3)
  static ThemeData get light => _build(Brightness.light);

  /// Dark theme (standard Material 3)
  static ThemeData get dark => _build(Brightness.dark);

  /// Liquid Glass theme - Apple-inspired frosted glass effect
  static ThemeData get liquid => _buildLiquid(Brightness.light);

  /// Liquid Glass dark theme - Apple-inspired frosted glass effect in dark mode
  static ThemeData get liquidDark => _buildLiquid(Brightness.dark);

  static ThemeData build({
    required Color accent,
    required bool isDark,
    bool liquidGlass = false,
  }) {
    final brightness = isDark ? Brightness.dark : Brightness.light;

    return liquidGlass
        ? _buildLiquid(brightness, seedColor: accent)
        : _build(brightness, seedColor: accent);
  }

  static ThemeData _build(
    Brightness brightness, {
    Color? seedColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.primary,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
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

  static ThemeData _buildLiquid(
    Brightness brightness, {
    Color? seedColor,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? AppColors.primary,
      brightness: brightness,
    );

    // Liquid Glass effect: semi-transparent background with vibrant accent colors
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        // Semi-transparent backgrounds for glass effect
        surface: colorScheme.surface.withValues(alpha: 0.8),
        surfaceContainerLow:
            colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
        surfaceContainerHigh:
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent for glass effect
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        shadowColor: Colors.transparent, // No shadow for glass effect
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      ),
      // Input fields with glass effect
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      // Buttons with glass effect
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.7),
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.8),
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Navigation components
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
        indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.6),
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
        indicatorColor: colorScheme.secondaryContainer.withValues(alpha: 0.6),
      ),
      // Tab bars
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        secondarySelectedColor: colorScheme.secondaryContainer,
        disabledColor:
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      // Switch and toggle themes
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return colorScheme.onSurfaceVariant;
          },
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary.withValues(alpha: 0.3);
            }
            return colorScheme.outline.withValues(alpha: 0.3);
          },
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
  AccentPreset(name: 'Violet', hex: Color(0xFF7C4DFF)),
  AccentPreset(name: 'Blue', hex: Color(0xFF2979FF)),
  AccentPreset(name: 'Green', hex: Color(0xFF2E7D32)),
  AccentPreset(name: 'Orange', hex: Color(0xFFEF6C00)),
  AccentPreset(name: 'Rose', hex: Color(0xFFE53966)),
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
