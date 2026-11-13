import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_theme.dart';
import '../../../core/result.dart';
import '../application/admin_providers.dart';
import '../domain/admin_repository.dart';

/// Panel de estadísticas agregadas para administradores.
class AdminScreen extends ConsumerStatefulWidget {
  /// Crea el panel.
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _loading = true;
  bool _authorized = true;
  String? _error;
  AdminStats? _stats;
  List<PlanUsage> _plans = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(adminRepositoryProvider);
    final admin = await repository.isAdmin();
    if (!mounted) {
      return;
    }
    final isAdmin = switch (admin) {
      Ok(:final value) => value,
      Err() => null,
    };
    if (isAdmin == null) {
      setState(() {
        _loading = false;
        _error = admin is Err<bool> ? admin.failure.message : null;
      });
      return;
    }
    if (!isAdmin) {
      setState(() {
        _loading = false;
        _authorized = false;
      });
      return;
    }
    final stats = await repository.stats();
    final plans = await repository.usageByPlan();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _authorized = true;
      _stats = stats is Ok<AdminStats> ? stats.value : null;
      _plans = plans is Ok<List<PlanUsage>> ? plans.value : const [];
      _error = switch (stats) {
        Err(:final failure) => failure.message,
        _ => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_authorized
          ? _NotAuthorized(message: _error)
          : _Dashboard(
              stats: _stats,
              plans: _plans,
              error: _error,
              onRefresh: _load,
            ),
    );
  }
}

class _NotAuthorized extends StatelessWidget {
  const _NotAuthorized({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 42, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No autorizado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textStrong,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message ?? 'Necesitás rol de administrador para ver estadísticas.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.stats,
    required this.plans,
    required this.error,
    required this.onRefresh,
  });

  final AdminStats? stats;
  final List<PlanUsage> plans;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_outlined,
                size: 18,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Estadísticas de uso',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                'Últimos 30 días',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Solo se muestran datos agregados. No se exponen correos, '
            'nombres ni contenido de las apps.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (data == null)
            const Text('No hay datos disponibles todavía.')
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  icon: Icons.people_outline,
                  label: 'Usuarios registrados',
                  value: '${data.totalUsers}',
                ),
                _StatCard(
                  icon: Icons.person_add_alt_outlined,
                  label: 'Nuevos usuarios',
                  value: '${data.newUsers}',
                ),
                _StatCard(
                  icon: Icons.folder_outlined,
                  label: 'Apps / proyectos',
                  value: '${data.totalProjects}',
                ),
                _StatCard(
                  icon: Icons.apps_outlined,
                  label: 'Apps por usuario',
                  value: data.avgProjectsPerUser.toStringAsFixed(2),
                ),
                _StatCard(
                  icon: Icons.schedule_outlined,
                  label: 'Horas de uso',
                  value: data.usageHours.toStringAsFixed(1),
                ),
                _StatCard(
                  icon: Icons.online_prediction_outlined,
                  label: 'Usuarios activos',
                  value: '${data.activeUsers}',
                ),
                _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Sesiones',
                  value: '${data.totalSessions}',
                ),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('Uso por plan', style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton(
                tooltip: 'Actualizar',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (plans.isEmpty)
            const Text('Sin datos por plan.')
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Plan')),
                    DataColumn(label: Text('Usuarios')),
                    DataColumn(label: Text('Proyectos')),
                    DataColumn(label: Text('Horas')),
                  ],
                  rows: [
                    for (final plan in plans)
                      DataRow(
                        cells: [
                          DataCell(Text(plan.planName)),
                          DataCell(Text('${plan.users}')),
                          DataCell(Text('${plan.projects}')),
                          DataCell(
                            Text(plan.usageHours.toStringAsFixed(1)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
