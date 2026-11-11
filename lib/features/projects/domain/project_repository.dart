import 'package:modeladorflutter/core/result.dart';

import 'project.dart';
import 'project_theme.dart';

/// Contrato de persistencia de proyectos.
///
/// La implementación real habla con Supabase; los tests usan un doble. El
/// aislamiento entre usuarios no se implementa aquí: lo impone RLS en la base
/// (`owner_id = auth.uid()`).
abstract interface class ProjectRepository {
  /// Lista los proyectos visibles para la sesión actual (los propios).
  Future<Result<List<Project>>> list();

  /// Crea un proyecto a nombre del usuario autenticado.
  Future<Result<Project>> create({required String name});

  /// Guarda el tema visual del proyecto.
  Future<Result<void>> saveTheme({
    required String projectId,
    required ProjectTheme theme,
  });

  /// Elimina un proyecto y sus pantallas.
  Future<Result<void>> delete(String projectId);
}
