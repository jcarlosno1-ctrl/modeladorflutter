import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

FakeProjectScreenRepository _repository() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'Pantalla 1',
      position: 0,
      canvas: const CanvasNode(
        id: 'root',
        type: 'column',
        children: [
          CanvasNode(id: 't1', type: 'text', properties: {'text': 'Hola'}),
        ],
      ),
    ),
  ],
);

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

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Desplaza la cuadrícula de la paleta hasta que aparezca el widget pedido.
Future<void> _scrollPaletteUntil(WidgetTester tester, String type) async {
  final grid = find.byType(GridView);
  await tester.scrollUntilVisible(
    find.byKey(EditorKeys.paletteItem(type)),
    80,
    scrollable: find
        .descendant(of: grid, matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('arrastrar un componente de la paleta al lienzo lo agrega', (
    tester,
  ) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    final source = tester.getCenter(
      find.byKey(EditorKeys.paletteItem('text')),
    );
    final target = tester.getCenter(find.byKey(EditorKeys.canvas));

    await tester.dragFrom(source, target - source);
    await tester.pumpAndSettle();

    expect(repository.saveCalls, greaterThanOrEqualTo(1));
    expect(repository.lastSaved!.children, hasLength(2));
  });

  testWidgets('soltar la paleta sobre un control lo inserta antes de él', (
    tester,
  ) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    final source = tester.getCenter(
      find.byKey(EditorKeys.paletteItem('text')),
    );
    final target = tester.getCenter(find.text('Hola'));

    await tester.dragFrom(source, target - source);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(repository.lastSaved!.children, hasLength(2));
    expect(repository.lastSaved!.children.first.type, 'text');
    expect(
      repository.lastSaved!.children.first.properties['text'],
      'Texto de ejemplo',
    );
  });

  testWidgets('soltar la paleta sobre un contenedor la inserta dentro', (
    tester,
  ) async {
    final repository = FakeProjectScreenRepository(
      screens: [
        ProjectScreen(
          id: 's-1',
          projectId: _project.id,
          name: 'Pantalla 1',
          position: 0,
          canvas: const CanvasNode(
            id: 'root',
            type: 'column',
            children: [CanvasNode(id: 'r1', type: 'row')],
          ),
        ),
      ],
    );
    await _pumpEditor(tester, repository);

    final source = tester.getCenter(
      find.byKey(EditorKeys.paletteItem('text')),
    );
    final target = tester.getCenter(find.text('Suelta widgets aquí'));

    await tester.dragFrom(source, target - source);
    await tester.pumpAndSettle();

    final root = repository.lastSaved!;
    expect(root.children, hasLength(1));
    expect(root.children.single.type, 'row');
    expect(root.children.single.children, hasLength(1));
  });

  testWidgets('cambiar de categoría cambia los componentes de la paleta', (
    tester,
  ) async {
    await _pumpEditor(tester, _repository());

    expect(find.byKey(EditorKeys.paletteItem('text')), findsOneWidget);

    await tester.tap(find.byKey(EditorKeys.category('layout')));
    await tester.pumpAndSettle();
    await _scrollPaletteUntil(tester, 'container');

    expect(find.byKey(EditorKeys.paletteItem('container')), findsOneWidget);
    expect(find.byKey(EditorKeys.paletteItem('text')), findsNothing);
  });

  testWidgets('la pantalla no se ofrece en la paleta', (tester) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.category('layout')));
    await tester.pumpAndSettle();
    await _scrollPaletteUntil(tester, 'container');

    expect(find.byKey(EditorKeys.paletteItem('screen')), findsNothing);
    expect(find.byKey(EditorKeys.paletteItem('container')), findsOneWidget);
  });

  testWidgets('la categoría Navegación inserta una barra superior', (
    tester,
  ) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.category('navigation')));
    await tester.pumpAndSettle();
    expect(find.byKey(EditorKeys.paletteItem('appBar')), findsOneWidget);

    await _doubleTap(tester, find.byKey(EditorKeys.paletteItem('appBar')));

    expect(repository.lastSaved!.children.last.type, 'appBar');
    expect(find.text('Mi pantalla'), findsOneWidget);
  });

  testWidgets('el doble clic en la paleta inserta', (tester) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await _doubleTap(tester, find.byKey(EditorKeys.paletteItem('button')));

    expect(repository.lastSaved!.children.last.type, 'button');
  });
}
