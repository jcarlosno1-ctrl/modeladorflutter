import 'package:flutter/material.dart';

/// Paleta y tema del editor: claro, denso y con acento verde azulado.
///
/// Se inspira en herramientas de diseño (panel blanco, bordes suaves y
/// tipografía compacta) para que el lienzo sea el protagonista.
abstract final class AppTheme {
  static const Color primary = Color(0xFF0F766E);
  static const Color background = Color(0xFFF5F6F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFFAFAFB);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textStrong = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);

  /// Notas y ayudas: un gris más claro que el texto secundario.
  static const Color hint = Color(0xFFA3ABB8);

  /// Fondo de los campos de entrada.
  static const Color inputFill = Color(0xFFF8FAFC);

  /// Color del foco/acento suave.
  static const Color primarySoft = Color(0xFFE6F4F1);

  /// Color de selección del editor (visible sobre fondos claros y oscuros).
  static const Color selection = Color(0xFF7C3AED);

  /// Fondo suave para la fila seleccionada en Capas.
  static const Color selectionSoft = Color(0xFFF3E8FF);

  /// Tema completo de la app.
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      surface: surface,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: surfaceMuted,
      surfaceContainer: const Color(0xFFF3F4F6),
      surfaceContainerHigh: const Color(0xFFECEEF1),
      surfaceContainerHighest: const Color(0xFFE5E7EB),
      onSurface: textStrong,
      onSurfaceVariant: textMuted,
      outlineVariant: border,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textStrong,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textStrong,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 12.5,
          color: textStrong,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 12.5,
          color: textStrong,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          color: textMuted,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: base.textTheme.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textStrong,
        ),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          color: textMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textStrong,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 11,
        ),
        labelStyle: const TextStyle(fontSize: 11, color: textMuted),
        hintStyle: const TextStyle(fontSize: 11.5, color: hint),
        helperStyle: const TextStyle(fontSize: 9.5, color: hint),
        errorStyle: const TextStyle(fontSize: 10, color: Color(0xFFDC2626)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textMuted,
          textStyle: const TextStyle(fontSize: 11.5),
        ),
      ),
      iconTheme: const IconThemeData(size: 18, color: textMuted),
      dividerColor: border,
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        dense: true,
        minVerticalPadding: 4,
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
      ),
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        textStyle: TextStyle(fontSize: 10.5, color: Colors.white),
      ),
    );
  }
}
