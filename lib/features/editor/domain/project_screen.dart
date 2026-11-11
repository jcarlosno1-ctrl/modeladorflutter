import 'canvas_node.dart';

/// Pantalla (artboard) dentro de un proyecto.
///
/// Se persiste en `tenant_app.project_screens`; `canvas` guarda el árbol de
/// componentes con `{version, root}`.
class ProjectScreen {
  /// Crea la pantalla.
  const ProjectScreen({
    required this.id,
    required this.projectId,
    required this.name,
    required this.position,
    required this.canvas,
  });

  /// Identificador.
  final String id;

  /// Proyecto al que pertenece.
  final String projectId;

  /// Nombre visible.
  final String name;

  /// Orden dentro del proyecto.
  final int position;

  /// Árbol guardado, si el JSON era válido.
  final CanvasNode? canvas;

  /// Construye el modelo desde una fila de PostgREST.
  factory ProjectScreen.fromJson(Map<String, dynamic> json) {
    return ProjectScreen(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      canvas: CanvasNode.tryParseDocument(json['canvas']),
    );
  }
}
