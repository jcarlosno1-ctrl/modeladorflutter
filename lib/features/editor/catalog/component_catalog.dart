import '../domain/canvas_node.dart';
import 'property_spec.dart';
import 'widget_definition.dart';

/// Registro de componentes permitidos en el lienzo.
///
/// El renderizador solo construye lo que está aquí; cualquier `type` que no
/// exista se muestra como "desconocido" y se reporta como incidencia.
class ComponentCatalog {
  /// Crea el catálogo a partir de las definiciones.
  ComponentCatalog(Iterable<WidgetDefinition> definitions)
    : _byType = {
        for (final definition in definitions) definition.type: definition,
      };

  final Map<String, WidgetDefinition> _byType;

  /// Definición de [type], o `null` si no existe.
  WidgetDefinition? operator [](String type) => _byType[type];

  /// Todas las definiciones.
  Iterable<WidgetDefinition> get definitions => _byType.values;

  /// Definiciones insertables de una categoría, ordenadas por etiqueta.
  List<WidgetDefinition> byCategory(ComponentCategory category) {
    final items = _byType.values
        .where(
          (definition) =>
              definition.category == category && definition.insertable,
        )
        .toList();
    items.sort((a, b) => a.label.compareTo(b.label));
    return items;
  }
}

/// Incidencia detectada al validar un documento del lienzo.
class CanvasIssue {
  /// Crea la incidencia.
  const CanvasIssue(this.nodeId, this.message);

  /// Nodo afectado.
  final String nodeId;

  /// Descripción para el editor.
  final String message;

  @override
  String toString() => '$nodeId: $message';
}

/// Valida el árbol completo contra el catálogo.
///
/// No lanza: devuelve la lista de problemas para mostrarlos en el editor. El
/// renderizador además se protege por su cuenta (profundidad y cantidad de
/// hijos), porque el JSON viene de un cliente y no es confiable.
List<CanvasIssue> validateCanvas(
  CanvasNode root,
  ComponentCatalog catalog, {
  int maxDepth = 40,
  int maxNodes = 500,
}) {
  final issues = <CanvasIssue>[];
  var visited = 0;

  void walk(CanvasNode node, int depth) {
    visited++;
    if (visited > maxNodes) {
      issues.add(
        CanvasIssue(node.id, 'El documento supera $maxNodes componentes.'),
      );
      return;
    }
    if (depth > maxDepth) {
      issues.add(
        CanvasIssue(node.id, 'El árbol supera $maxDepth niveles.'),
      );
      return;
    }

    final definition = catalog[node.type];
    if (definition == null) {
      issues.add(
        CanvasIssue(node.id, 'Tipo de componente desconocido: ${node.type}.'),
      );
      return;
    }

    for (final entry in node.properties.entries) {
      final spec = definition.propertyFor(entry.key);
      if (spec == null) {
        issues.add(
          CanvasIssue(
            node.id,
            'Propiedad no permitida "${entry.key}" en ${node.type}.',
          ),
        );
      } else if (!spec.accepts(entry.value)) {
        issues.add(
          CanvasIssue(
            node.id,
            'Valor inválido para "${entry.key}" en ${node.type}.',
          ),
        );
      }
    }

    if (node.children.isNotEmpty && !definition.acceptsChildren) {
      issues.add(
        CanvasIssue(node.id, '${node.type} no admite hijos.'),
      );
    }

    for (final child in node.children) {
      walk(child, depth + 1);
    }
  }

  walk(root, 0);
  return issues;
}

/// Helper: descripción de la propiedad para tooltips del panel.
String describeProperty(PropertySpec spec) {
  return switch (spec.type) {
    PropertyType.text || PropertyType.multilineText => 'Texto',
    PropertyType.number =>
      'Número${spec.min != null ? ' ≥ ${spec.min}' : ''}'
          '${spec.max != null ? ' ≤ ${spec.max}' : ''}',
    PropertyType.boolean => 'Sí/No',
    PropertyType.choice => 'Opción',
    PropertyType.destinationIndex => 'Destino (por nombre)',
    PropertyType.screenTarget => 'Pantalla destino',
    PropertyType.color => 'Color (token o #RRGGBB)',
  };
}
