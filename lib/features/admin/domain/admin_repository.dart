import 'package:modeladorflutter/core/result.dart';

/// Métricas agregadas del panel de administración.
class AdminStats {
  /// Crea las métricas.
  const AdminStats({
    required this.totalUsers,
    required this.newUsers,
    required this.totalProjects,
    required this.avgProjectsPerUser,
    required this.usageHours,
    required this.activeUsers,
    required this.totalSessions,
  });

  /// Usuarios registrados totales.
  final int totalUsers;

  /// Usuarios nuevos en el período.
  final int newUsers;

  /// Proyectos totales.
  final int totalProjects;

  /// Promedio de apps por usuario.
  final double avgProjectsPerUser;

  /// Horas de uso en el período.
  final double usageHours;

  /// Usuarios activos en el período.
  final int activeUsers;

  /// Sesiones iniciadas en el período.
  final int totalSessions;

  /// Construye desde la respuesta JSON de `admin_stats`.
  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      newUsers: (json['new_users'] as num?)?.toInt() ?? 0,
      totalProjects: (json['total_projects'] as num?)?.toInt() ?? 0,
      avgProjectsPerUser:
          (json['avg_projects_per_user'] as num?)?.toDouble() ?? 0,
      usageHours: (json['usage_hours'] as num?)?.toDouble() ?? 0,
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
      totalSessions: (json['total_sessions'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Métricas por plan.
class PlanUsage {
  /// Crea la fila.
  const PlanUsage({
    required this.planId,
    required this.planName,
    required this.users,
    required this.projects,
    required this.usageHours,
  });

  /// Id del plan.
  final String planId;

  /// Nombre visible.
  final String planName;

  /// Usuarios en el plan.
  final int users;

  /// Proyectos del plan.
  final int projects;

  /// Horas acumuladas.
  final double usageHours;

  /// Construye desde PostgREST.
  factory PlanUsage.fromJson(Map<String, dynamic> json) {
    return PlanUsage(
      planId: json['plan_id'] as String? ?? '',
      planName: json['plan_name'] as String? ?? '',
      users: (json['users'] as num?)?.toInt() ?? 0,
      projects: (json['projects'] as num?)?.toInt() ?? 0,
      usageHours: (json['usage_hours'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Acceso a las métricas de administración.
abstract interface class AdminRepository {
  /// `true` si el usuario actual tiene rol admin.
  Future<Result<bool>> isAdmin();

  /// Métricas agregadas del período.
  Future<Result<AdminStats>> stats({DateTime? from, DateTime? to});

  /// Distribución por plan.
  Future<Result<List<PlanUsage>>> usageByPlan({
    DateTime? from,
    DateTime? to,
  });
}
