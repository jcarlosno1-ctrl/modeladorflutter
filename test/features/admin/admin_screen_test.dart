import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/admin/application/admin_providers.dart';
import 'package:modeladorflutter/features/admin/domain/admin_repository.dart';
import 'package:modeladorflutter/features/admin/presentation/admin_screen.dart';

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository({required this.admin});

  final bool admin;

  @override
  Future<Result<bool>> isAdmin() async => Ok(admin);

  @override
  Future<Result<AdminStats>> stats({DateTime? from, DateTime? to}) async {
    return const Ok(
      AdminStats(
        totalUsers: 42,
        newUsers: 7,
        totalProjects: 84,
        avgProjectsPerUser: 2,
        usageHours: 12.5,
        activeUsers: 9,
        totalSessions: 15,
      ),
    );
  }

  @override
  Future<Result<List<PlanUsage>>> usageByPlan({
    DateTime? from,
    DateTime? to,
  }) async {
    return const Ok([
      PlanUsage(
        planId: 'free',
        planName: 'Gratis',
        users: 30,
        projects: 50,
        usageHours: 8,
      ),
    ]);
  }
}

Widget _app(AdminRepository repository) => ProviderScope(
  overrides: [adminRepositoryProvider.overrideWithValue(repository)],
  child: const MaterialApp(home: AdminScreen()),
);

void main() {
  testWidgets('sin rol admin muestra No autorizado', (tester) async {
    await tester.pumpWidget(
      _app(_FakeAdminRepository(admin: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No autorizado'), findsOneWidget);
    expect(find.text('42'), findsNothing);
  });

  testWidgets('con rol admin muestra estadísticas agregadas', (tester) async {
    await tester.pumpWidget(
      _app(_FakeAdminRepository(admin: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Administración'), findsOneWidget);
    expect(find.text('42'), findsWidgets);
    expect(find.text('2.00'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);
    expect(find.text('Gratis'), findsOneWidget);
  });
}
