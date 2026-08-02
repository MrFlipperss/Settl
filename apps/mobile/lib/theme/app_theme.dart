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

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
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

  static ThemeData _build Liquid(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );

    // Liquid Glass effect: semi-transparent background with vibrant accent colors
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme.copyWith(
        // Semi-transparent backgrounds for glass effect
        surface: colorScheme.surface.withOpacity(0.8),
        surfaceContainerLow: colorScheme.surfaceContainerLow.withOpacity(0.7),
        surfaceContainerHigh: colorScheme.surfaceContainerHigh.withOpacity(0.9),
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
      cardTheme: CardTheme(
        color: colorScheme.surfaceContainerLow.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        shadowColor: Colors.transparent, // No shadow for glass effect
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surfaceContainerLow.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.4),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      // Input fields with glass effect
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      // Buttons with glass effect
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primaryContainer.withOpacity(0.7),
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary.withOpacity(0.8),
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Cards and containers
      cardTheme: CardTheme(
        color: colorScheme.surfaceContainerLow.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        shadowColor: Colors.transparent,
      ),
      // Navigation components
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.8),
        indicatorColor: colorScheme.secondaryContainer.withOpacity(0.6),
        height: 64,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.8),
        indicatorColor: colorScheme.secondaryContainer.withOpacity(0.6),
      ),
      // Dialogs and popups
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surfaceContainerLow.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.4),
            width: 1.5,
          ),
        ),
      ),
      // Bottom sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      // Tab bars
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
        ),
        indicatorSize: TabBarIndicatorSize.label,
      ),
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.inputDecorationTheme.fillColor,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
          ),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        secondarySelectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
              return colorScheme.primary.withOpacity(0.3);
            }
            return colorScheme.outline.withOpacity(0.3);
          },
        ),
      ),
    );
  }
}
