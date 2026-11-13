import 'package:flutter/widgets.dart';

/// Acciones que el lienzo puede ejecutar en la vista previa.
class EditorActions extends InheritedWidget {
  /// Crea el contexto de acciones del editor.
  const EditorActions({
    required this.onNavigateScreen,
    required this.onBack,
    required super.child,
    super.key,
  });

  /// Cambia a otra pantalla del proyecto.
  final ValueChanged<String> onNavigateScreen;

  /// Vuelve a la pantalla anterior de la vista previa.
  final VoidCallback onBack;

  /// Acciones disponibles, o `null` fuera del editor.
  static EditorActions? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EditorActions>();
  }

  @override
  bool updateShouldNotify(EditorActions oldWidget) => false;
}
