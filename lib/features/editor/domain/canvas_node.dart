/// Nodo del lienzo: un componente con sus propiedades y sus hijos.
///
/// Es el formato que se persiste en `tenant_app.project_screens.canvas`:
///
/// ```json
/// {
///   "version": 1,
///   "root": {
///     "id": "n1",
///     "type": "column",
///     "properties": {"gap": 8},
///     "children": [{"id": "n2", "type": "text", "properties": {"text": "Hola"}}]
///   }
/// }
/// ```
///
/// El JSON es **no confiable** (lo escribe un cliente): el renderizador valida
/// tipo, propiedades y profundidad antes de construir widgets.
class CanvasNode {
  /// Crea un nodo.
  const CanvasNode({
    required this.id,
    required this.type,
    this.properties = const {},
    this.children = const [],
  });

  /// Identificador único dentro del documento.
  final String id;

  /// Tipo de componente (clave del catálogo).
  final String type;

  /// Valores de las propiedades; se validan contra el catálogo.
  final Map<String, Object?> properties;

  /// Hijos, para componentes contenedores.
  final List<CanvasNode> children;

  /// Documento completo de un lienzo.
  static const int schemaVersion = 1;

  /// Convierte el nodo a JSON apto para persistir.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    if (properties.isNotEmpty) 'properties': properties,
    if (children.isNotEmpty)
      'children': children.map((child) => child.toJson()).toList(),
  };

  /// Reconstruye un nodo desde JSON, con validación de forma.
  ///
  /// Lanza [FormatException] si falta `id`/`type` o si `children` no es lista.
  factory CanvasNode.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Nodo sin id');
    }
    if (type is! String || type.isEmpty) {
      throw const FormatException('Nodo sin type');
    }

    final properties = json['properties'];
    final rawChildren = json['children'];

    var props = properties is Map<String, dynamic>
        ? Map<String, Object?>.unmodifiable(properties)
        : const <String, Object?>{};

    var parsedChildren = rawChildren is List
        ? List<CanvasNode>.unmodifiable(
            rawChildren.map((child) {
              if (child is! Map<String, dynamic>) {
                throw const FormatException('Hijo con forma inválida');
              }
              return CanvasNode.fromJson(child);
            }),
          )
        : const <CanvasNode>[];

    // Migraciones del AppBar:
    //   showBack (muy viejo) ┐
    //   automaticallyImplyLeading (viejo) ├→ `automaticallyImplyLeading`
    //   leading (versión previa) ┘  + ícono de leading sintetizado si aplica.
    if (type == 'appBar') {
      final rawLeading = props['leading'];
      final oldAuto = props['automaticallyImplyLeading'] ?? props['showBack'];
      if (rawLeading != null || oldAuto != null) {
        final migrated = Map<String, Object?>.from(props)
          ..remove('showBack')
          ..remove('leading');

        var automatically = oldAuto != false;
        if (rawLeading == 'none') {
          automatically = false;
        } else if (rawLeading is String &&
            const ['back', 'menu', 'search', 'close'].contains(rawLeading)) {
          automatically = false;
          final leadingId = '$id-leading';
          final already = parsedChildren.any((child) => child.id == leadingId);
          if (!already) {
            parsedChildren = List<CanvasNode>.unmodifiable([
              ...parsedChildren,
              CanvasNode(
                id: leadingId,
                type: 'icon',
                properties: Map<String, Object?>.unmodifiable({
                  'icon': rawLeading == 'back' ? 'arrow_back' : rawLeading,
                  'position': 'leading',
                }),
              ),
            ]);
          }
        }

        migrated['automaticallyImplyLeading'] = automatically;
        props = Map<String, Object?>.unmodifiable(migrated);
      }
    }

    return CanvasNode(
      id: id,
      type: type,
      properties: props,
      children: parsedChildren,
    );
  }

  /// Documento raíz a partir del JSON guardado.
  ///
  /// Devuelve `null` si el documento no es válido; nunca lanza.
  static CanvasNode? tryParseDocument(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final root = json['root'];
    if (root is! Map<String, dynamic>) {
      return null;
    }
    try {
      return CanvasNode.fromJson(root);
    } on FormatException {
      return null;
    }
  }

  /// Busca un nodo por id en todo el subárbol.
  CanvasNode? findNode(String nodeId) {
    if (id == nodeId) {
      return this;
    }
    for (final child in children) {
      final found = child.findNode(nodeId);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// Copia con la propiedad [key] del nodo [nodeId] reemplazada.
  ///
  /// Si el nodo no existe, devuelve `this` (misma instancia) para que el
  /// llamador pueda detectar que no hubo cambios.
  CanvasNode withProperty(String nodeId, String key, Object? value) {
    if (id == nodeId) {
      return CanvasNode(
        id: id,
        type: type,
        properties: {...properties, key: value},
        children: children,
      );
    }

    var changed = false;
    final updated = <CanvasNode>[];
    for (final child in children) {
      final next = child.withProperty(nodeId, key, value);
      if (!identical(next, child)) {
        changed = true;
      }
      updated.add(next);
    }

    if (!changed) {
      return this;
    }
    return CanvasNode(
      id: id,
      type: type,
      properties: properties,
      children: updated,
    );
  }

  /// Copia sin el nodo [nodeId].
  ///
  /// Devuelve `null` si el nodo no existe o si es la raíz (no se puede quitar).
  CanvasNode? removeById(String nodeId) {
    if (id == nodeId) {
      return null;
    }

    var removed = false;
    final updated = <CanvasNode>[];
    for (final child in children) {
      if (child.id == nodeId) {
        removed = true;
        continue;
      }
      final next = child.removeById(nodeId);
      if (next != null) {
        removed = true;
        updated.add(next);
      } else {
        updated.add(child);
      }
    }

    if (!removed) {
      return null;
    }
    return CanvasNode(
      id: id,
      type: type,
      properties: properties,
      children: updated,
    );
  }

  /// Copia con [node] insertado justo antes del nodo [targetId].
  ///
  /// Devuelve `null` si [targetId] no existe.
  CanvasNode? insertBefore(String targetId, CanvasNode node) {
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      if (child.id == targetId) {
        final updated = [...children]..insert(index, node);
        return CanvasNode(
          id: id,
          type: type,
          properties: properties,
          children: updated,
        );
      }
      final nested = child.insertBefore(targetId, node);
      if (nested != null) {
        final updated = [...children]..[index] = nested;
        return CanvasNode(
          id: id,
          type: type,
          properties: properties,
          children: updated,
        );
      }
    }
    return null;
  }

  /// Copia con [node] agregado al final de los hijos de [parentId].
  ///
  /// Devuelve `null` si [parentId] no existe.
  CanvasNode? appendChild(String parentId, CanvasNode node) {
    if (id == parentId) {
      return CanvasNode(
        id: id,
        type: type,
        properties: properties,
        children: [...children, node],
      );
    }

    for (var index = 0; index < children.length; index++) {
      final nested = children[index].appendChild(parentId, node);
      if (nested != null) {
        final updated = [...children]..[index] = nested;
        return CanvasNode(
          id: id,
          type: type,
          properties: properties,
          children: updated,
        );
      }
    }
    return null;
  }

  /// Posición de [nodeId] entre sus hermanos.
  ///
  /// Devuelve `(index, count, parentId)` o `null` si no existe. La raíz no
  /// tiene posición porque no tiene padre.
  ({int index, int count, String parentId})? siblingPositionOf(String nodeId) {
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      if (child.id == nodeId) {
        return (index: index, count: children.length, parentId: id);
      }
      final nested = child.siblingPositionOf(nodeId);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }

  /// Mueve el nodo [nodeId] ±1 posiciones dentro de su padre.
  ///
  /// Al mover un contenedor, su subárbol se mueve completo (es el mismo nodo).
  /// [canMoveNextTo] permite vetar el destino (por ejemplo, para no cruzar una
  /// barra superior). Devuelve `this` si el movimiento no aplica.
  CanvasNode moveWithinParent(
    String nodeId,
    int delta, {
    bool Function(CanvasNode node)? canMoveNextTo,
  }) {
    for (var index = 0; index < children.length; index++) {
      final child = children[index];
      if (child.id == nodeId) {
        final target = index + delta;
        if (target < 0 || target >= children.length) {
          return this;
        }
        if (canMoveNextTo != null && !canMoveNextTo(children[target])) {
          return this;
        }
        final updated = [...children];
        updated.removeAt(index);
        updated.insert(target, child);
        return CanvasNode(
          id: id,
          type: type,
          properties: properties,
          children: updated,
        );
      }

      final nested = child.moveWithinParent(
        nodeId,
        delta,
        canMoveNextTo: canMoveNextTo,
      );
      if (!identical(nested, child)) {
        final updated = [...children]..[index] = nested;
        return CanvasNode(
          id: id,
          type: type,
          properties: properties,
          children: updated,
        );
      }
    }
    return this;
  }

  @override
  String toString() => 'CanvasNode($id, $type, ${children.length} hijos)';
}
