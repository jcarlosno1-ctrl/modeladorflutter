import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:modeladorflutter/core/result.dart';
import '../domain/admin_repository.dart';

/// Implementación de [AdminRepository] sobre RPC de Supabase.
class SupabaseAdminRepository implements AdminRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<Result<bool>> isAdmin() async {
    try {
      final value = await _client
          .schema('tenant_app')
          .rpc<dynamic>('is_admin');
      return Ok(value == true);
    } on PostgrestException catch (error) {
      return Err(
        AuthFailure(
          error.code == '42501'
              ? 'No tenés permisos de administración.'
              : 'No se pudo verificar el rol de administrador.',
        ),
      );
    } on Object {
      return const Err(
        NetworkFailure('No se pudo verificar el rol de administrador.'),
      );
    }
  }

  @override
  Future<Result<AdminStats>> stats({DateTime? from, DateTime? to}) async {
    try {
      final value = await _client.schema('tenant_app').rpc<dynamic>(
        'admin_stats',
        params: {
          if (from != null) 'from_date': from.toUtc().toIso8601String(),
          if (to != null) 'to_date': to.toUtc().toIso8601String(),
        },
      );
      if (value is! Map<String, dynamic>) {
        return const Err(
          NetworkFailure('Respuesta inesperada del servidor.'),
        );
      }
      return Ok(AdminStats.fromJson(value));
    } on PostgrestException catch (error) {
      return Err(
        AuthFailure(
          error.message.contains('No autorizado')
              ? 'No autorizado para ver estadísticas.'
              : 'No se pudieron cargar las estadísticas.',
        ),
      );
    } on Object {
      return const Err(
        NetworkFailure('No se pudieron cargar las estadísticas.'),
      );
    }
  }

  @override
  Future<Result<List<PlanUsage>>> usageByPlan({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final value = await _client.schema('tenant_app').rpc<dynamic>(
        'admin_usage_by_plan',
        params: {
          if (from != null) 'from_date': from.toUtc().toIso8601String(),
          if (to != null) 'to_date': to.toUtc().toIso8601String(),
        },
      );
      if (value is! List) {
        return const Err(NetworkFailure('Respuesta inesperada del servidor.'));
      }
      return Ok([
        for (final item in value)
          if (item is Map<String, dynamic>) PlanUsage.fromJson(item),
      ]);
    } on Object {
      return const Err(
        NetworkFailure('No se pudieron cargar los datos por plan.'),
      );
    }
  }
}
