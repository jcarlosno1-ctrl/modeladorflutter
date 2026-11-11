import 'package:modeladorflutter/core/result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/project.dart';
import '../domain/project_repository.dart';
import '../domain/project_theme.dart';

/// Implementación de [ProjectRepository] sobre PostgREST.
///
/// El cliente se inicializa con `schema: 'tenant_app'`, así que `from('projects')`
/// resuelve a `tenant_app.projects`.
class SupabaseProjectRepository implements ProjectRepository {
  /// Crea el repositorio sobre un cliente ya inicializado.
  const SupabaseProjectRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Result<List<Project>>> list() async {
    try {
      final rows = await _client
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      return Ok(
        rows.map(Project.fromJson).toList(growable: false),
      );
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(
        NetworkFailure('No se pudieron cargar tus proyectos. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<Project>> create({required String name}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Err(
        AuthFailure('Tu sesión expiró. Vuelve a iniciar sesión.'),
      );
    }

    try {
      final row = await _client
          .from('projects')
          .insert({'owner_id': user.id, 'name': name.trim()})
          .select()
          .single();

      return Ok(Project.fromJson(row));
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(
        NetworkFailure('No se pudo crear el proyecto. Intenta de nuevo.'),
      );
    }
  }

  @override
  Future<Result<void>> saveTheme({
    required String projectId,
    required ProjectTheme theme,
  }) async {
    try {
      final rows = await _client
          .from('projects')
          .update({'theme': theme.toJson()})
          .eq('id', projectId)
          .select('id');

      if (rows.isEmpty) {
        return const Err(
          AuthFailure('No se pudo guardar el tema: el proyecto no es tuyo.'),
        );
      }
      return const Ok(null);
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(NetworkFailure('No se pudo guardar el tema.'));
    }
  }

  @override
  Future<Result<void>> delete(String projectId) async {
    try {
      final rows = await _client
          .from('projects')
          .delete()
          .eq('id', projectId)
          .select('id');

      if (rows.isEmpty) {
        return const Err(
          AuthFailure('No se pudo eliminar: el proyecto no es tuyo.'),
        );
      }
      return const Ok(null);
    } on PostgrestException catch (error) {
      return Err(_failureFor(error));
    } on Exception {
      return const Err(NetworkFailure('No se pudo eliminar el proyecto.'));
    }
  }

  /// Traduce errores de Postgres/PostgREST a fallos de dominio.
  ///
  /// Los códigos son de PostgreSQL: 42501 sin permiso (RLS), 23514 CHECK,
  /// 23503 llave foránea, 23505 único. No se propaga el mensaje crudo.
  static Failure _failureFor(PostgrestException error) {
    return switch (error.code) {
      '42501' => const AuthFailure(
        'No tienes permiso para esta operación.',
      ),
      '23514' => const UnexpectedFailure(
        'El nombre no es válido (entre 1 y 120 caracteres).',
      ),
      '23503' => const AuthFailure(
        'Tu sesión ya no es válida. Vuelve a iniciar sesión.',
      ),
      '23505' => const UnexpectedFailure(
        'Ya existe un proyecto con esos datos.',
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
