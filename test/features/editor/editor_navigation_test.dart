import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/app/main_layout.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';
import 'package:modeladorflutter/features/projects/presentation/projects_screen.dart';
import 'package:modeladorflutter/main.dart';

import '../../helpers/fake_auth_repository.dart';
import '../../helpers/fake_project_repository.dart';
import '../../helpers/fake_project_screen_repository.dart';

/// Monta la app con sesión y un proyecto existente.
Future<void> _pump(
  WidgetTester tester,
  FakeProjectRepository projects,
) async {
  final auth = FakeAuthRepository();
  addTearDown(auth.dispose);
  await auth.signIn(email: 'ana@example.com', password: 'secreta123');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        projectRepositoryProvider.overrideWithValue(projects),
        // El editor carga pantallas al abrirse: sin esto usaría Supabase.
        projectScreenRepositoryProvider.overrideWithValue(
          FakeProjectScreenRepository(),
        ),
      ],
      child: const ModeladorApp(),
    ),
  );
  await tester.pumpAndSettle();
}

FakeProjectRepository _oneProject() => FakeProjectRepository(
  initial: [
    Project(
      id: 'p-1',
      name: 'Mi app',
      createdAt: DateTime.utc(2026, 11, 7),
    ),
  ],
);

void main() {
  testWidgets('abrir un proyecto entra al editor y atrás vuelve a la lista', (
    tester,
  ) async {
    await _pump(tester, _oneProject());

    await tester.tap(find.byKey(ProjectsKeys.tileFor('p-1')));
    await tester.pumpAndSettle();

    expect(find.byType(MainLayout), findsOneWidget);
    expect(find.text('Mi app'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectsScreen), findsOneWidget);
    expect(find.byType(MainLayout), findsNothing);
  });

  testWidgets('en móvil el editor conserva atrás y el cajón de herramientas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pump(tester, _oneProject());

    await tester.tap(find.byKey(ProjectsKeys.tileFor('p-1')));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byKey(MainLayoutKeys.openToolsButton), findsOneWidget);

    await tester.tap(find.byKey(MainLayoutKeys.openToolsButton));
    await tester.pumpAndSettle();

    expect(find.byKey(MainLayoutKeys.toolsPanel), findsOneWidget);
  });
}
