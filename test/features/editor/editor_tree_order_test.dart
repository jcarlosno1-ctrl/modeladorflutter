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

FakeProjectScreenRepository _repositoryWith(CanvasNode root) =>
    FakeProjectScreenRepository(
      screens: [
        ProjectScreen(
          id: 's-1',
          projectId: _project.id,
          name: 'Pantalla 1',
          position: 0,
          canvas: root,
        ),
      ],
    );

Future<void> _pumpEditor(
  WidgetTester tester,
  FakeProjectScreenRepository repository,
) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

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

CanvasNode _threeTexts() => const CanvasNode(
  id: 'root',
  type: 'screen',
  properties: {'device': 'phone', 'scroll': true},
  children: [
    CanvasNode(id: 'a', type: 'text', properties: {'text': 'A'}),
    CanvasNode(id: 'b', type: 'text', properties: {'text': 'B'}),
    CanvasNode(id: 'c', type: 'text', properties: {'text': 'C'}),
  ],
);

List<String> _ids(FakeProjectScreenRepository repository) =>
    repository.lastSaved!.children.map((child) => child.id).toList();

void main() {
  testWidgets('bajar un componente cambia el orden y se persiste', (
    tester,
  ) async {
    final repository = _repositoryWith(_threeTexts());
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.moveDown('a')));
    await tester.pumpAndSettle();

    expect(_ids(repository), ['b', 'a', 'c']);
  });

  testWidgets('subir un componente cambia el orden y se persiste', (
    tester,
  ) async {
    final repository = _repositoryWith(_threeTexts());
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('c')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.moveUp('c')));
    await tester.pumpAndSettle();

    expect(_ids(repository), ['a', 'c', 'b']);
  });

  testWidgets('mover un contenedor mueve también a sus hijos', (tester) async {
    final repository = _repositoryWith(
      const CanvasNode(
        id: 'root',
        type: 'screen',
        children: [
          CanvasNode(
            id: 'box',
            type: 'container',
            children: [
              CanvasNode(id: 'inner', type: 'text', properties: {'text': 'X'}),
            ],
          ),
          CanvasNode(id: 'b', type: 'text', properties: {'text': 'B'}),
        ],
      ),
    );
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('box')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.moveDown('box')));
    await tester.pumpAndSettle();

    final saved = repository.lastSaved!;
    expect(saved.children.map((child) => child.id).toList(), ['b', 'box']);
    expect(saved.children.last.children.single.id, 'inner');
  });

  testWidgets('el primero no puede subir y el último no puede bajar', (
    tester,
  ) async {
    final repository = _repositoryWith(_threeTexts());
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('a')));
    await tester.pumpAndSettle();
    final up = tester.widget<IconButton>(find.byKey(EditorKeys.moveUp('a')));

    await tester.tap(find.byKey(EditorKeys.nodeTile('c')));
    await tester.pumpAndSettle();
    final down = tester.widget<IconButton>(
      find.byKey(EditorKeys.moveDown('c')),
    );

    expect(up.onPressed, isNull);
    expect(down.onPressed, isNull);
  });
}
