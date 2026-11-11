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
          CanvasNode(id: 'a', type: 'text', properties: {'text': 'A'}),
          CanvasNode(id: 'b', type: 'text', properties: {'text': 'B'}),
          CanvasNode(id: 'c', type: 'text', properties: {'text': 'C'}),
        ],
      ),
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

/// Espera el debounce de guardado.
Future<void> _flushSave(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('arrastrar un nodo sobre otro lo reordena', (tester) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    final from = tester.getCenter(find.text('C'));
    final to = tester.getCenter(find.text('A'));
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    await _flushSave(tester);

    final saved = repository.lastSaved!;
    expect(
      saved.children.map((child) => child.properties['text']).toList(),
      ['C', 'A', 'B'],
    );
  });

  testWidgets('soltar un nodo en el fondo lo manda al final', (tester) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    final from = tester.getCenter(find.text('A'));
    final canvas = tester.getRect(find.byKey(EditorKeys.canvas));
    final to = Offset(canvas.center.dx, canvas.bottom - 24);

    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    await _flushSave(tester);

    final saved = repository.lastSaved!;
    expect(
      saved.children.map((child) => child.properties['text']).toList(),
      ['B', 'C', 'A'],
    );
  });
}
