import 'package:flutter/material.dart';

import '../domain/project_theme.dart';

/// Construye el [ThemeData] del proyecto (modo claro, Material 3).
///
/// Se usa en la vista previa del lienzo y es la misma configuración que se
/// exporta en `lib/main.dart`.
ThemeData buildProjectThemeData(ProjectTheme theme) {
  final primary = _color(theme.primary, const Color(0xFF6750A4));
  final secondary = _color(theme.secondary, const Color(0xFF625B71));
  final tertiary = _color(theme.tertiary, const Color(0xFF7D5260));

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
    ),
  );

  final appBarForeground = theme.appBarForeground.isEmpty
      ? null
      : _color(theme.appBarForeground, base.colorScheme.onSurface);

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: theme.appBarBackground.isEmpty
          ? null
          : _color(theme.appBarBackground, primary),
      foregroundColor: appBarForeground,
      // Sin color explícito cuando el tema no define uno: así el
      // `foregroundColor` de cada AppBar sigue funcionando en la vista previa.
      titleTextStyle: TextStyle(
        fontSize: theme.appBarTitleSize,
        color: appBarForeground ?? base.colorScheme.onSurface,
      ),
    ),
    textTheme: base.textTheme.copyWith(
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: theme.bodySize,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: theme.inputSize),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontSize: theme.titleSize,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: theme.labelSize,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: theme.dividerColor.isEmpty
          ? null
          : _color(theme.dividerColor, base.colorScheme.outlineVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.buttonRadius),
        ),
      ),
    ),
  );
}

Color _color(String hex, Color fallback) {
  if (hex.startsWith('#') && hex.length == 7) {
    final parsed = int.tryParse(hex.substring(1), radix: 16);
    if (parsed != null) {
      return Color(0xFF000000 | parsed);
    }
  }
  return fallback;
}
