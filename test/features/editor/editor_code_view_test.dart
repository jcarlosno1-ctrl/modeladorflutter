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

CanvasNode _screen([String text = 'Contenido']) => CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(id: 't', type: 'text', properties: {'text': text}),
  ],
);

FakeProjectScreenRepository _twoScreens() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'main.dart',
      position: 0,
      canvas: _screen('Inicio'),
    ),
    ProjectScreen(
      id: 's-2',
      projectId: _project.id,
      name: 'pantalla_2.dart',
      position: 1,
      canvas: _screen('Segunda'),
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
  testWidgets('la vista Código muestra la nota de ruta y el código', (
    tester,
  ) async {
    await _pumpEditor(tester, _twoScreens());

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Pega este código en lib/main.dart'),
      findsOneWidget,
    );
    expect(find.textContaining('class MyApp'), findsOneWidget);
    expect(find.byKey(EditorKeys.copyCode), findsOneWidget);
  });

  testWidgets('una pantalla secundaria apunta a lib/screens', (tester) async {
    await _pumpEditor(tester, _twoScreens());

    await tester.tap(find.byKey(EditorKeys.screenTab('s-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Pega este código en lib/screens/pantalla_2.dart'),
      findsOneWidget,
    );
    expect(find.textContaining('class Pantalla2Screen'), findsOneWidget);
    expect(find.textContaining('void main()'), findsNothing);
  });

  testWidgets('renombrar la pestaña actualiza ruta y clase', (tester) async {
    final repository = _twoScreens();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.screenTab('s-2')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EditorKeys.screenTab('s-2')));
    await tester.pumpAndSettle();

    // Botón de lápiz en la pestaña activa.
    await tester.tap(find.byKey(EditorKeys.renameScreen('s-2')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(EditorKeys.renameField), 'login.dart');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(repository.renameCalls, 1);
    expect(find.text('login.dart'), findsWidgets);

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Pega este código en lib/screens/login.dart'),
      findsOneWidget,
    );
    expect(find.textContaining('class LoginScreen'), findsOneWidget);
  });
}
