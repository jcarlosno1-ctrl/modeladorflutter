import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/admin/application/admin_providers.dart';
import 'package:modeladorflutter/features/admin/domain/admin_repository.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';
import 'package:modeladorflutter/features/projects/presentation/projects_screen.dart';
import 'package:modeladorflutter/main.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_project_repository.dart';

/// Monta la app con sesión iniciada y el repositorio de proyectos inyectado.
Future<void> _pumpSignedIn(
  WidgetTester tester,
  FakeProjectRepository projects, {
  AdminRepository? admin,
}) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  await auth.signIn(email: 'ana@example.com', password: 'secreta123');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        projectRepositoryProvider.overrideWithValue(projects),
        if (admin != null) adminRepositoryProvider.overrideWithValue(admin),
      ],
      child: const ModeladorApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Abre el diálogo de creación, escribe [name] y confirma.
Future<void> _createProject(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(ProjectsKeys.newProject));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(ProjectsKeys.dialogName), name);
  await tester.tap(find.byKey(ProjectsKeys.dialogCreate));
  await tester.pumpAndSettle();
}

class _FakeAdmin implements AdminRepository {
  _FakeAdmin(this.admin);

  final bool admin;

  @override
  Future<Result<bool>> isAdmin() async => Ok(admin);

  @override
  Future<Result<AdminStats>> stats({DateTime? from, DateTime? to}) async {
    return const Err(UnexpectedFailure('sin datos'));
  }

  @override
  Future<Result<List<PlanUsage>>> usageByPlan({
    DateTime? from,
    DateTime? to,
  }) async {
    return const Err(UnexpectedFailure('sin datos'));
  }
}

void main() {
  testWidgets('sin proyectos muestra el estado vacío', (tester) async {
    await _pumpSignedIn(tester, FakeProjectRepository());

    expect(find.text('Aún no tienes proyectos'), findsOneWidget);
    expect(find.byKey(ProjectsKeys.newProjectEmpty), findsOneWidget);
    expect(find.byKey(ProjectsKeys.list), findsNothing);
  });

  testWidgets('lista los proyectos del usuario', (tester) async {
    await _pumpSignedIn(
      tester,
      FakeProjectRepository(
        initial: [
          Project(
            id: 'p-1',
            name: 'Mi app',
            createdAt: DateTime.utc(2026, 11, 7),
          ),
        ],
      ),
    );

    expect(find.byKey(ProjectsKeys.list), findsOneWidget);
    expect(find.text('Mi app'), findsOneWidget);
    expect(find.text('Aún no tienes proyectos'), findsNothing);
  });

  testWidgets('crear un proyecto lo agrega a la lista', (tester) async {
    final projects = FakeProjectRepository();
    await _pumpSignedIn(tester, projects);

    await _createProject(tester, 'Proyecto nuevo');

    expect(projects.createCalls, 1);
    expect(find.text('Proyecto nuevo'), findsOneWidget);
    expect(find.byKey(ProjectsKeys.list), findsOneWidget);
  });

  testWidgets('un error al cargar muestra reintento y recarga', (
    tester,
  ) async {
    final projects = FakeProjectRepository(
      listError: const AuthFailure('No tienes permiso para esta operación.'),
    );
    await _pumpSignedIn(tester, projects);

    expect(find.byKey(ProjectsKeys.error), findsOneWidget);
    expect(find.text('No tienes permiso para esta operación.'), findsOneWidget);

    projects.listError = null;
    await tester.tap(find.byKey(ProjectsKeys.retry));
    await tester.pumpAndSettle();

    expect(find.byKey(ProjectsKeys.error), findsNothing);
    expect(find.text('Aún no tienes proyectos'), findsOneWidget);
  });

  testWidgets('un error al crear avisa sin romper la lista', (tester) async {
    final projects = FakeProjectRepository(
      createError: const UnexpectedFailure(
        'El nombre no es válido (entre 1 y 120 caracteres).',
      ),
    );
    await _pumpSignedIn(tester, projects);

    await _createProject(tester, 'X');

    expect(
      find.text('El nombre no es válido (entre 1 y 120 caracteres).'),
      findsOneWidget,
    );
    expect(find.text('Aún no tienes proyectos'), findsOneWidget);
  });

  testWidgets('eliminar un proyecto pide confirmación y lo quita', (
    tester,
  ) async {
    final projects = FakeProjectRepository(
      initial: [
        Project(
          id: 'p-1',
          name: 'Mi app',
          createdAt: DateTime.utc(2026, 11, 7),
        ),
      ],
    );
    await _pumpSignedIn(tester, projects);

    await tester.tap(find.byKey(ProjectsKeys.deleteFor('p-1')));
    await tester.pumpAndSettle();

    // Cancelar no elimina.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(projects.deleteCalls, 0);
    expect(find.text('Mi app'), findsOneWidget);

    // Confirmar elimina.
    await tester.tap(find.byKey(ProjectsKeys.deleteFor('p-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ProjectsKeys.dialogDelete));
    await tester.pumpAndSettle();

    expect(projects.deleteCalls, 1);
    expect(find.text('Mi app'), findsNothing);
    expect(find.text('Aún no tienes proyectos'), findsOneWidget);
  });

  testWidgets('oculta Administración a los usuarios normales', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _pumpSignedIn(
      tester,
      FakeProjectRepository(),
      admin: _FakeAdmin(false),
    );

    expect(find.text('Administración'), findsNothing);
  });

  testWidgets('muestra Administración a los administradores', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await _pumpSignedIn(
      tester,
      FakeProjectRepository(),
      admin: _FakeAdmin(true),
    );

    expect(find.text('Administración'), findsOneWidget);
  });
}
