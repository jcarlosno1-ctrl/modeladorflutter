import 'package:flutter/foundation.dart';

/// Carga útil de un arrastre dentro del editor.
///
/// Distingue entre "arrastro un componente nuevo desde la paleta" y
/// "arrastro un nodo existente para reordenarlo".
@immutable
class EditorDragData {
  const EditorDragData._({this.componentType, this.nodeId});

  /// Arrastre desde la paleta (tipo de componente del catálogo).
  const EditorDragData.component(String type) : this._(componentType: type);

  /// Arrastre de un nodo del lienzo (id del nodo).
  const EditorDragData.node(String id) : this._(nodeId: id);

  /// Tipo de componente, si viene de la paleta.
  final String? componentType;

  /// Id del nodo, si viene del lienzo.
  final String? nodeId;

  @override
  bool operator ==(Object other) =>
      other is EditorDragData &&
      other.componentType == componentType &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash(componentType, nodeId);
}
