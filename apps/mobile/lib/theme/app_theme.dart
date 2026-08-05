import 'package:flutter/material.dart';

/// A selectable accent colour for the app, with tuned light/dark variants.
class AccentPreset {
  const AccentPreset({
    required this.name,
    required this.hex,
    required this.light,
    required this.dark,
  });

  final String name;

  /// Display swatch colour.
  final Color hex;

  final AccentPalette light;
  final AccentPalette dark;
}

class AccentPalette {
  const AccentPalette({
    required this.primary,
    required this.container,
    required this.onContainer,
  });

  final Color primary;
  final Color container;
  final Color onContainer;
}

/// The seven accent options — all perceptually muted, pleasant.
const List<AccentPreset> accentPresets = [
  AccentPreset(
    name: 'Violet',
    hex: Color(0xFF8B5CF6),
    light: AccentPalette(
      primary: Color(0xFF7B5EA7),
      container: Color(0xFFEDE9FE),
      onContainer: Color(0xFF2E1065),
    ),
    dark: AccentPalette(
      primary: Color(0xFFC4B5FD),
      container: Color(0xFF3D2570),
      onContainer: Color(0xFFEDE9FE),
    ),
  ),
  AccentPreset(
    name: 'Blue',
    hex: Color(0xFF60A5FA),
    light: AccentPalette(
      primary: Color(0xFF4A7AB5),
      container: Color(0xFFDBEAFE),
      onContainer: Color(0xFF1E3A5F),
    ),
    dark: AccentPalette(
      primary: Color(0xFF93C5FD),
      container: Color(0xFF1A3A6E),
      onContainer: Color(0xFFDBEAFE),
    ),
  ),
  AccentPreset(
    name: 'Teal',
    hex: Color(0xFF2DD4BF),
    light: AccentPalette(
      primary: Color(0xFF3A8E8A),
      container: Color(0xFFCCFBF1),
      onContainer: Color(0xFF134E4A),
    ),
    dark: AccentPalette(
      primary: Color(0xFF5EEAD4),
      container: Color(0xFF0E4A48),
      onContainer: Color(0xFFCCFBF1),
    ),
  ),
  AccentPreset(
    name: 'Emerald',
    hex: Color(0xFF34D399),
    light: AccentPalette(
      primary: Color(0xFF3A8C65),
      container: Color(0xFFD1FAE5),
      onContainer: Color(0xFF064E3B),
    ),
    dark: AccentPalette(
      primary: Color(0xFF6EE7B7),
      container: Color(0xFF0A4A30),
      onContainer: Color(0xFFD1FAE5),
    ),
  ),
  AccentPreset(
    name: 'Indigo',
    hex: Color(0xFF818CF8),
    light: AccentPalette(
      primary: Color(0xFF5B68C0),
      container: Color(0xFFE0E7FF),
      onContainer: Color(0xFF1E1B4B),
    ),
    dark: AccentPalette(
      primary: Color(0xFFC7D2FE),
      container: Color(0xFF252D75),
      onContainer: Color(0xFFE0E7FF),
    ),
  ),
  AccentPreset(
    name: 'Orange',
    hex: Color(0xFFF97316),
    light: AccentPalette(
      primary: Color(0xFFC4673A),
      container: Color(0xFFFFEDD5),
      onContainer: Color(0xFF431407),
    ),
    dark: AccentPalette(
      primary: Color(0xFFFCA87A),
      container: Color(0xFF5C2510),
      onContainer: Color(0xFFFFEDD5),
    ),
  ),
  AccentPreset(
    name: 'Rose',
    hex: Color(0xFFFB7185),
    light: AccentPalette(
      primary: Color(0xFFA8455E),
      container: Color(0xFFFFDAD6),
      onContainer: Color(0xFF410001),
    ),
    dark: AccentPalette(
      primary: Color(0xFFFCA5A5),
      container: Color(0xFF5C1828),
      onContainer: Color(0xFFFFE4E6),
    ),
  ),
];

/// Design tokens used across every screen — the single source of truth for
/// the SplitKaro-style surfaces.
@immutable
class DesignTokens extends ThemeExtension<DesignTokens> {
  const DesignTokens({
    required this.bg,
    required this.cardBg,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVar,
    required this.primary,
    required this.container,
    required this.onContainer,
    required this.border,
    required this.navBg,
    required this.navBorder,
    required this.shadow,
    required this.glassInner,
    required this.headerBg,
    required this.isDark,
  });

  final Color bg;
  final Color cardBg;
  final Color surfaceVariant;
  final Color onSurface;
  final Color onSurfaceVar;
  final Color primary;
  final Color container;
  final Color onContainer;
  final Color border;
  final Color navBg;
  final Color navBorder;
  final Color shadow;
  final Color glassInner;

  /// Muted tint of the accent used for page headers.
  final Color headerBg;
  final bool isDark;

  static DesignTokens of(BuildContext context) =>
      Theme.of(context).extension<DesignTokens>()!;

  @override
  DesignTokens copyWith({
    Color? bg,
    Color? cardBg,
    Color? surfaceVariant,
    Color? onSurface,
    Color? onSurfaceVar,
    Color? primary,
    Color? container,
    Color? onContainer,
    Color? border,
    Color? navBg,
    Color? navBorder,
    Color? shadow,
    Color? glassInner,
    Color? headerBg,
    bool? isDark,
  }) {
    return DesignTokens(
      bg: bg ?? this.bg,
      cardBg: cardBg ?? this.cardBg,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVar: onSurfaceVar ?? this.onSurfaceVar,
      primary: primary ?? this.primary,
      container: container ?? this.container,
      onContainer: onContainer ?? this.onContainer,
      border: border ?? this.border,
      navBg: navBg ?? this.navBg,
      navBorder: navBorder ?? this.navBorder,
      shadow: shadow ?? this.shadow,
      glassInner: glassInner ?? this.glassInner,
      headerBg: headerBg ?? this.headerBg,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  DesignTokens lerp(DesignTokens? other, double t) {
    if (other == null) return this;
    return DesignTokens(
      bg: Color.lerp(bg, other.bg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVar: Color.lerp(onSurfaceVar, other.onSurfaceVar, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      container: Color.lerp(container, other.container, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
      border: Color.lerp(border, other.border, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      glassInner: Color.lerp(glassInner, other.glassInner, t)!,
      headerBg: Color.lerp(headerBg, other.headerBg, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const Color positive = Color(0xFF4A9060);
  static const Color negative = Color(0xFFC0504A);

  /// Builds the theme for a given accent preset and brightness.
  static ThemeData build({required AccentPreset accent, required bool isDark}) {
    final a = isDark ? accent.dark : accent.light;
    final tokens = DesignTokens(
      bg: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF0EEF6),
      cardBg: isDark ? const Color(0xFF1C1B20) : const Color(0xFFFFFFFF),
      surfaceVariant: isDark ? const Color(0xFF25232C) : const Color(0xFFE8E4F0),
      onSurface: isDark ? const Color(0xFFE2DDE8) : const Color(0xFF1C1A24),
      onSurfaceVar: isDark ? const Color(0xFF8A8494) : const Color(0xFF7A7488),
      primary: a.primary,
      container: a.container,
      onContainer: a.onContainer,
      border: isDark ? const Color(0xFF2A2832) : const Color(0xFFE2DDF0),
      navBg: isDark
          ? const Color(0xC714131A)
          : const Color(0xADFCFAFF),
      navBorder: isDark
          ? const Color(0x17FFFFFF)
          : const Color(0x99FFFFFF),
      shadow: isDark
          ? const Color(0x80000000)
          : const Color(0x1F503C8C),
      glassInner: isDark
          ? const Color(0x0DFFFFFF)
          : const Color(0x8CFFFFFF),
      headerBg: isDark ? a.container : a.primary,
      isDark: isDark,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: a.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: a.primary,
      onPrimary: isDark ? const Color(0xFF1C1A24) : Colors.white,
      primaryContainer: a.container,
      onPrimaryContainer: a.onContainer,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: tokens.bg,
      colorScheme: colorScheme,
      extensions: [tokens],
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: tokens.onSurface,
        displayColor: tokens.onSurface,
      ),
    );
  }
}
