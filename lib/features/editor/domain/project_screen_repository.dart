import 'package:modeladorflutter/core/result.dart';

import 'canvas_node.dart';
import 'project_screen.dart';

/// Contrato de persistencia de pantallas.
///
/// RLS restringe todo a los proyectos del usuario; el repositorio no filtra.
abstract interface class ProjectScreenRepository {
  /// Pantallas del proyecto, ordenadas por `position`.
  Future<Result<List<ProjectScreen>>> listForProject(String projectId);

  /// Crea una pantalla con su árbol inicial.
  Future<Result<ProjectScreen>> create({
    required String projectId,
    required String name,
    required int position,
    required CanvasNode root,
  });

  /// Guarda el árbol de una pantalla existente.
  Future<Result<void>> saveCanvas({
    required String screenId,
    required CanvasNode root,
  });

  /// Cambia el nombre (archivo) de la pantalla.
  Future<Result<void>> rename({
    required String screenId,
    required String name,
  });
}
