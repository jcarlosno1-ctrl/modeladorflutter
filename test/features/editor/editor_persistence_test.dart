import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
import 'package:modeladorflutter/features/editor/presentation/editor_screen.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../../helpers/fake_project_screen_repository.dart';

final _project = Project(
  id: 'p-1',
  name: 'Mi app',
  createdAt: DateTime.utc(2026, 11, 7),
);

/// Monta el editor con el repositorio de pantallas inyectado.
Future<void> _pumpEditor(
  WidgetTester tester,
  FakeProjectScreenRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: EditorScreen(project: _project)),
    ),
  );
  await tester.pumpAndSettle();
}

ProjectScreen _screenWith(CanvasNode root) => ProjectScreen(
  id: 's-1',
  projectId: _project.id,
  name: 'Pantalla 1',
  position: 0,
  canvas: root,
);

/// Doble clic sobre un componente de la paleta.
Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sin pantallas, crea una por defecto y la dibuja', (
    tester,
  ) async {
    final repository = FakeProjectScreenRepository();
    await _pumpEditor(tester, repository);

    expect(repository.createCalls, 1);
    expect(find.byKey(EditorKeys.canvas), findsOneWidget);
    expect(find.text('Tu pantalla está vacía'), findsOneWidget);
  });

  testWidgets('con una pantalla existente dibuja su árbol guardado', (
    tester,
  ) async {
    final repository = FakeProjectScreenRepository(
      screens: [
        _screenWith(
          const CanvasNode(
            id: 'n1',
            type: 'column',
            children: [
              CanvasNode(
                id: 'n2',
                type: 'text',
                properties: {'text': 'Diseño previo'},
              ),
            ],
          ),
        ),
      ],
    );

    await _pumpEditor(tester, repository);

    expect(find.text('Diseño previo'), findsOneWidget);
    expect(repository.createCalls, 0);
  });

  testWidgets('agregar un texto lo persiste en el backend', (tester) async {
    final repository = FakeProjectScreenRepository();
    await _pumpEditor(tester, repository);

    await _doubleTap(tester, find.byKey(EditorKeys.paletteItem('text')));

    expect(repository.saveCalls, 1);
    expect(repository.lastSavedScreenId, 's-1');
    expect(repository.lastSaved!.children, hasLength(1));
    expect(find.text('Texto de ejemplo'), findsOneWidget);
    expect(find.text('Guardado'), findsOneWidget);
  });

  testWidgets('un fallo al guardar se muestra sin perder el árbol', (
    tester,
  ) async {
    final repository = FakeProjectScreenRepository()
      ..saveError = const NetworkFailure('No se pudo guardar el lienzo.');
    await _pumpEditor(tester, repository);

    await _doubleTap(tester, find.byKey(EditorKeys.paletteItem('text')));

    expect(find.byKey(EditorKeys.error), findsOneWidget);
    expect(find.text('No se pudo guardar el lienzo.'), findsOneWidget);
    expect(find.text('Texto de ejemplo'), findsOneWidget);
  });
}
