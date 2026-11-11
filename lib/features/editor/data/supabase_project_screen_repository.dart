import 'package:modeladorflutter/core/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/canvas_node.dart';
import '../domain/project_screen.dart';
import '../domain/project_screen_repository.dart';

/// Implementación de [ProjectScreenRepository] sobre PostgREST.
///
/// El cliente apunta al esquema `tenant_app` (ver `main.dart`), así que
/// `from('project_screens')` resuelve al esquema correcto.
class SupabaseProjectScreenRepository implements ProjectScreenRepository {
  /// Crea el repositorio sobre un cliente ya inicializado.
  const SupabaseProjectScreenRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<ProjectScreen>>> listForProject(String projectId) async {
    try {
      final rows = await _client
          .from('project_screens')
          .select()
          .eq('project_id', projectId)
          .order('position', ascending: true);

      return Ok(rows.map(ProjectScreen.fromJson).toList(growable: false));
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(
        NetworkFailure('No se pudieron cargar las pantallas del proyecto.'),
      );
    }
  }

  @override
  Future<Result<ProjectScreen>> create({
    required String projectId,
    required String name,
    required int position,
    required CanvasNode root,
  }) async {
    try {
      final row = await _client
          .from('project_screens')
          .insert({
            'project_id': projectId,
            'name': name.trim(),
            'position': position,
            'canvas': _document(root),
          })
          .select()
          .single();

      return Ok(ProjectScreen.fromJson(row));
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(
        NetworkFailure('No se pudo crear la pantalla. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<void>> saveCanvas({
    required String screenId,
    required CanvasNode root,
  }) async {
    try {
      final rows = await _client
          .from('project_screens')
          .update({'canvas': _document(root)})
          .eq('id', screenId)
          .select('id');

      // RLS puede devolver 0 filas sin error si la pantalla no es del usuario.
      if (rows.isEmpty) {
        return const Err(
          AuthFailure('No se pudo guardar: la pantalla no te pertenece.'),
        );
      }
      return const Ok(null);
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(
        NetworkFailure('No se pudo guardar el lienzo. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<void>> rename({
    required String screenId,
    required String name,
  }) async {
    try {
      final rows = await _client
          .from('project_screens')
          .update({'name': name.trim()})
          .eq('id', screenId)
          .select('id');

      if (rows.isEmpty) {
        return const Err(
          AuthFailure('No se pudo renombrar: la pantalla no te pertenece.'),
        );
      }
      return const Ok(null);
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(NetworkFailure('No se pudo renombrar la pantalla.'));
    }
  }

  /// Documento persistido en la columna `canvas` (jsonb).
  static Map<String, Object?> _document(CanvasNode root) => {
    'version': CanvasNode.schemaVersion,
    'root': root.toJson(),
  };

  /// Traduce errores de Postgres/PostgREST a fallos de dominio.
  static Failure _failureFor(PostgrestException error) {
    return switch (error.code) {
      '42501' => const AuthFailure('No tienes permiso para esta operación.'),
      '23514' => const UnexpectedFailure(
        'El contenido no es válido (revisa nombres y tamaño del lienzo).',
      ),
      '23503' => const AuthFailure(
        'Tu sesión ya no es válida. Vuelve a iniciar sesión.',
      ),
      '23505' => const UnexpectedFailure(
        'Ya existe una pantalla en esa posición.',
      ),
      'PGRST301' => const AuthFailure(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      ),
      _ => const UnexpectedFailure(
        'No se pudo completar la operación. Intenta de nuevo.',
      ),
    };
  }
}
