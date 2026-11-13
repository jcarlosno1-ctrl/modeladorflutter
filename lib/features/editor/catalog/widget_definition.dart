import 'package:flutter/widgets.dart';

import 'property_spec.dart';

/// Acceso tipado a las propiedades ya coaccionadas de un nodo.
class Props {
  /// Crea el acceso a partir del mapa validado.
  const Props(this._values);

  final Map<String, Object?> _values;

  /// Texto, o cadena vacía.
  String text(String key) => (_values[key] as String?) ?? '';

  /// Número, o `0`.
  double number(String key) => (_values[key] as num?)?.toDouble() ?? 0;

  /// Booleano, o `false`.
  bool flag(String key) => (_values[key] as bool?) ?? false;

  /// Opción elegida, o cadena vacía.
  String choice(String key) => (_values[key] as String?) ?? '';
}

/// Ubicación estructural de un componente dentro de la pantalla.
///
/// El editor usa el slot para impedir que la barra superior se mueva del techo
/// o que la inferior deje de estar al pie.
enum ComponentSlot {
  /// Contenido normal (el cuerpo, con scroll).
  body,

  /// Fijo arriba (`AppBar`).
  top,

  /// Fijo abajo (`BottomNavigationBar`).
  bottom,

  /// Menú lateral izquierdo (`Drawer`).
  overlay,

  /// Menú lateral derecho (`EndDrawer`).
  drawerEnd,

  /// Botón flotante inferior derecho (`FloatingActionButton`).
  fab,
}

/// Categoría del componente (para agrupar en la paleta).
enum ComponentCategory {
  /// Marco de pantalla y contenedores.
  layout,

  /// Texto, botones, íconos.
  basic,

  /// Campos de entrada.
  input,

  /// Imágenes y medios.
  media,

  /// Navegación: barra superior, tabs, menú, barra inferior.
  navigation,

  /// Componentes Material con estilo propio: tarjeta, fila de lista…
  material,
}

/// Constructor de un widget a partir de propiedades e hijos.
typedef ComponentBuilder =
    Widget Function(BuildContext context, Props props, List<Widget> children);

/// Definición de un componente del catálogo.
///
/// Es la única puerta de entrada para agregar widgets al modelador: si no está
/// aquí, el lienzo lo rechaza. Así el usuario no puede inventar propiedades ni
/// inyectar código.
class WidgetDefinition {
  /// Crea la definición.
  const WidgetDefinition({
    required this.type,
    required this.label,
    required this.category,
    required this.icon,
    required this.properties,
    required this.builder,
    this.acceptsChildren = false,
    this.insertable = true,
    this.requiresFlexParent = false,
    this.slot = ComponentSlot.body,
    this.flutterClass,
  });

  /// Clave estable que se guarda en el JSON (`text`, `button`, …).
  final String type;

  /// Nombre visible en la paleta.
  final String label;

  /// Grupo en la paleta.
  final ComponentCategory category;

  /// Ícono de la paleta.
  final IconData icon;

  /// Esquema de propiedades.
  final List<PropertySpec> properties;

  /// Si acepta hijos en el árbol.
  final bool acceptsChildren;

  /// Si puede insertarse desde la paleta. La raíz `screen` se crea desde las
  /// pestañas, no arrastrándola al lienzo.
  final bool insertable;

  /// Si solo puede vivir dentro de una `Row` o `Column` (Expanded, Spacer…).
  final bool requiresFlexParent;

  /// Dónde vive dentro de la pantalla.
  final ComponentSlot slot;

  /// Nombre de la clase Flutter equivalente.
  ///
  /// Los `type` internos se mantienen cortos y estables; el nombre real se
  /// muestra en la UI para que la ficha coincida con la documentación.
  final String? flutterClass;

  /// Construye el widget.
  final ComponentBuilder builder;

  /// Propiedades por defecto de un nodo nuevo.
  Map<String, Object?> get defaultProperties => {
    for (final property in properties) property.key: property.defaultValue,
  };

  /// Copia la definición cambiando solo las propiedades.
  WidgetDefinition copyWith({List<PropertySpec>? properties}) {
    return WidgetDefinition(
      type: type,
      label: label,
      category: category,
      icon: icon,
      properties: properties ?? this.properties,
      builder: builder,
      acceptsChildren: acceptsChildren,
      insertable: insertable,
      requiresFlexParent: requiresFlexParent,
      slot: slot,
      flutterClass: flutterClass,
    );
  }

  /// Esquema de la propiedad [key], si existe.
  PropertySpec? propertyFor(String key) {
    for (final property in properties) {
      if (property.key == key) {
        return property;
      }
    }
    return null;
  }
}
