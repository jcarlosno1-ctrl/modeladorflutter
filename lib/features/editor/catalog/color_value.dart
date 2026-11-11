import 'package:flutter/material.dart';

/// Resuelve un valor de color del catálogo a un [Color].
///
/// Acepta tokens del theme (`surface`, `low`, `high`, `primary`, `secondary`,
/// `tertiary`) y hex `#RRGGBB`. Cualquier otra cosa cae al color base.
Color colorForValue(String? value, ColorScheme scheme) {
  if (value == null || value.isEmpty) {
    return scheme.surface;
  }
  if (value.startsWith('#') && value.length == 7) {
    final parsed = int.tryParse(value.substring(1), radix: 16);
    if (parsed != null) {
      return Color(0xFF000000 | parsed);
    }
  }
  return switch (value) {
    'low' => scheme.surfaceContainerLow,
    'high' => scheme.surfaceContainerHighest,
    'primary' => scheme.primaryContainer,
    'secondary' => scheme.secondaryContainer,
    'tertiary' => scheme.tertiaryContainer,
    'onSurface' => scheme.onSurface,
    'onPrimary' => scheme.onPrimary,
    'onPrimaryContainer' => scheme.onPrimaryContainer,
    'onSurfaceVariant' => scheme.onSurfaceVariant,
    'surface' => scheme.surface,
    'outline' => scheme.outlineVariant,
    'primarySolid' => scheme.primary,
    'onPrimarySolid' => scheme.onPrimary,
    _ => scheme.surface,
  };
}

/// Expresión Dart equivalente, o `null` si no hay color explícito.
String? colorExpressionFor(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  if (value.startsWith('#') && value.length == 7) {
    return 'const Color(0xFF${value.substring(1).toUpperCase()})';
  }
  return switch (value) {
    'low' => 'Theme.of(context).colorScheme.surfaceContainerLow',
    'high' => 'Theme.of(context).colorScheme.surfaceContainerHighest',
    'primary' => 'Theme.of(context).colorScheme.primaryContainer',
    'secondary' => 'Theme.of(context).colorScheme.secondaryContainer',
    'tertiary' => 'Theme.of(context).colorScheme.tertiaryContainer',
    'surface' => 'Theme.of(context).colorScheme.surface',
    'onSurface' => 'Theme.of(context).colorScheme.onSurface',
    'onPrimary' => 'Theme.of(context).colorScheme.onPrimary',
    'onPrimaryContainer' => 'Theme.of(context).colorScheme.onPrimaryContainer',
    'onSurfaceVariant' => 'Theme.of(context).colorScheme.onSurfaceVariant',
    'outline' => 'Theme.of(context).colorScheme.outlineVariant',
    'primarySolid' => 'Theme.of(context).colorScheme.primary',
    'onPrimarySolid' => 'Theme.of(context).colorScheme.onPrimary',
    _ => null,
  };
}
