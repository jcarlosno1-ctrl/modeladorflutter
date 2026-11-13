import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/codegen/project_export.dart';
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

const _entry = CanvasNode(
  id: 'root1',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'btn',
      type: 'button',
      properties: {
        'label': 'Ir',
        'onTap': 'navigate',
        'targetScreen': 's2',
      },
    ),
  ],
);

const _target = CanvasNode(
  id: 'root2',
  type: 'screen',
  children: [CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Segunda'})],
);

FakeProjectScreenRepository _repository() => FakeProjectScreenRepository(
  screens: const [
    ProjectScreen(
      id: 's1',
      projectId: 'p-1',
      name: 'main.dart',
      position: 0,
      canvas: _entry,
    ),
    ProjectScreen(
      id: 's2',
      projectId: 'p-1',
      name: 'vista.dart',
      position: 1,
      canvas: _target,
    ),
  ],
);

void main() {
  testWidgets('en vivo, ir a pantalla cambia la pantalla del editor', (
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
          projectScreenRepositoryProvider.overrideWithValue(_repository()),
        ],
        child: MaterialApp(home: EditorScreen(project: _project)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EditorKeys.liveToggle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    expect(container.read(editorSessionProvider).screenId, 's2');
    expect(find.text('Segunda'), findsWidgets);
  });

  testWidgets('el selector de pantalla aparece con la acción navegar', (
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
          projectScreenRepositoryProvider.overrideWithValue(_repository()),
        ],
        child: MaterialApp(home: EditorScreen(project: _project)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EditorKeys.nodeTile('btn')));
    await tester.pumpAndSettle();

    final selector = find.byKey(EditorKeys.propertyField('targetScreen'));
    await tester.scrollUntilVisible(
      selector,
      250,
      scrollable: find
          .descendant(
            of: find.byKey(EditorKeys.propertiesList),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(selector, findsOneWidget);
    expect(find.text('vista'), findsWidgets);
  });

  test('el código usa rutas nombradas e imports de pantallas', () {
    final files = buildProjectFiles(
      screens: const [
        ProjectScreen(
          id: 's1',
          projectId: 'p-1',
          name: 'main.dart',
          position: 0,
          canvas: _entry,
        ),
        ProjectScreen(
          id: 's2',
          projectId: 'p-1',
          name: 'vista.dart',
          position: 1,
          canvas: _target,
        ),
      ],
      entryScreenId: 's1',
    );

    final main = files.firstWhere((file) => file.path == 'lib/main.dart');
    expect(
      files.map((file) => file.path),
      contains('lib/screens/vista.dart'),
    );

    expect(main.content, contains("import 'screens/vista.dart';"));
    expect(main.content, contains("'/screen/s2'"));
    expect(main.content, contains('Navigator.pushNamed'));
  });
}
