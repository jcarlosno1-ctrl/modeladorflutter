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

CanvasNode get _screen => CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    for (var index = 0; index < 14; index++)
      CanvasNode(
        id: 'txt$index',
        type: 'text',
        properties: {'text': 'Texto $index'},
      ),
  ],
);

void main() {
  testWidgets('al abrir el código se centra en el widget seleccionado', (
    tester,
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
          projectScreenRepositoryProvider.overrideWithValue(
            FakeProjectScreenRepository(
              screens: [
                ProjectScreen(
                  id: 's-1',
                  projectId: _project.id,
                  name: 'main.dart',
                  position: 0,
                  canvas: _screen,
                ),
              ],
            ),
          ),
        ],
        child: MaterialApp(home: EditorScreen(project: _project)),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    container.read(editorSessionProvider.notifier).selectNode('txt13');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Código').first);
    await tester.pumpAndSettle();

    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(EditorKeys.codeScroll),
    );
    expect(scroll.controller, isNotNull);
    expect(scroll.controller!.offset, greaterThan(0));
  });
}
