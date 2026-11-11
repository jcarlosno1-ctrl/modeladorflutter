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

CanvasNode _screenWithText(String id, String text) => CanvasNode(
  id: 'screen-$id',
  type: 'screen',
  properties: const {'device': 'phone', 'scroll': true},
  children: [
    CanvasNode(id: 'text-$id', type: 'text', properties: {'text': text}),
  ],
);

FakeProjectScreenRepository _twoScreens() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'Pantalla 1',
      position: 0,
      canvas: _screenWithText('1', 'Contenido uno'),
    ),
    ProjectScreen(
      id: 's-2',
      projectId: _project.id,
      name: 'Pantalla 2',
      position: 1,
      canvas: _screenWithText('2', 'Contenido dos'),
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
  testWidgets('las pantallas se muestran como pestañas y se cambia entre ellas', (
    tester,
  ) async {
    await _pumpEditor(tester, _twoScreens());

    expect(find.byKey(EditorKeys.screenTab('s-1')), findsOneWidget);
    expect(find.byKey(EditorKeys.screenTab('s-2')), findsOneWidget);
    expect(find.text('Contenido uno'), findsOneWidget);
    expect(find.text('Contenido dos'), findsNothing);

    await tester.tap(find.byKey(EditorKeys.screenTab('s-2')));
    await tester.pumpAndSettle();

    expect(find.text('Contenido dos'), findsOneWidget);
    expect(find.text('Contenido uno'), findsNothing);
  });

  testWidgets('el botón + crea una pantalla nueva y la activa', (tester) async {
    final repository = FakeProjectScreenRepository(
      screens: [
        ProjectScreen(
          id: 's-1',
          projectId: _project.id,
          name: 'Pantalla 1',
          position: 0,
          canvas: _screenWithText('1', 'Contenido uno'),
        ),
      ],
    );
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.addScreen));
    await tester.pumpAndSettle();

    expect(repository.createCalls, 1);
    expect(find.byKey(EditorKeys.screenTab('s-2')), findsOneWidget);
    expect(find.text('Tu pantalla está vacía'), findsOneWidget);
    expect(repository.screens.last.name, 'pantalla_2.dart');
  });
}
