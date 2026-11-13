import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const _root = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(id: 'a', type: 'text', properties: {'text': 'A'}),
    CanvasNode(id: 'b', type: 'text', properties: {'text': 'B'}),
  ],
);

FakeProjectScreenRepository _repository() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'main.dart',
      position: 0,
      canvas: _root,
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

void main() {
  test('deshacer y rehacer restauran el árbol', () async {
    final container = ProviderContainer(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(_repository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorSessionProvider.notifier);
    await notifier.openProject(_project);
    notifier.updateProperty('a', 'text', 'Cambio');

    var root = container.read(editorSessionProvider).root!;
    expect(root.findNode('a')!.properties['text'], 'Cambio');

    await notifier.undo();
    root = container.read(editorSessionProvider).root!;
    expect(root.findNode('a')!.properties['text'], 'A');

    await notifier.redo();
    root = container.read(editorSessionProvider).root!;
    expect(root.findNode('a')!.properties['text'], 'Cambio');
  });

  testWidgets('Supr elimina el widget seleccionado', (tester) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('a')));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    final root = container.read(editorSessionProvider).root!;
    expect(root.findNode('a'), isNull);
    expect(root.findNode('b'), isNotNull);
    expect(repository.lastSaved!.children.map((child) => child.id), ['b']);
  });

  testWidgets('Supr no borra el widget mientras se edita texto', (
    tester,
  ) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('a')));
    await tester.pumpAndSettle();

    final field = find.byKey(EditorKeys.propertyField('text'));
    await tester.tap(field);
    await tester.enterText(field, 'Hola');
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    expect(container.read(editorSessionProvider).root!.findNode('a'), isNotNull);
  });
}
