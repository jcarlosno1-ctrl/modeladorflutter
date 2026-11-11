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
  createdAt: DateTime.utc(2026, 11, 9),
);

CanvasNode _root(String id) => CanvasNode(
  id: 'root-$id',
  type: 'screen',
  properties: const {'device': 'phone', 'scroll': true, 'padding': 16},
);

ProjectScreen _screen(String id, String name, int position) => ProjectScreen(
  id: id,
  projectId: _project.id,
  name: name,
  position: position,
  canvas: _root(id),
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

void main() {
  testWidgets('el lienzo vacío muestra el estado de bienvenida', (
    tester,
  ) async {
    final repository = FakeProjectScreenRepository(
      screens: [_screen('s-1', 'main.dart', 0)],
    );
    await _pumpEditor(tester, repository);

    expect(
      find.byIcon(Icons.dashboard_customize_outlined),
      findsOneWidget,
    );
    expect(find.text('Tu pantalla está vacía'), findsOneWidget);
    expect(find.textContaining('Arrastra un widget'), findsOneWidget);
  });

  testWidgets('los cambios sobreviven al cambiar de pantalla', (tester) async {
    final repository = FakeProjectScreenRepository(
      screens: [
        _screen('s-1', 'main.dart', 0),
        _screen('s-2', 'pantalla_2.dart', 1),
      ],
    );
    await _pumpEditor(tester, repository);

    // Agrega un texto en la primera pantalla y espera el guardado.
    await _doubleTap(tester, find.byKey(EditorKeys.paletteItem('text')));
    await tester.pump(const Duration(milliseconds: 700));

    expect(repository.lastSavedScreenId, 's-1');

    // Cambia a la segunda pantalla y vuelve a la primera.
    await tester.tap(find.byKey(EditorKeys.screenTab('s-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.screenTab('s-1')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    final state = container.read(editorSessionProvider);

    expect(state.root!.children.map((child) => child.type), contains('text'));
    expect(find.text('Texto'), findsWidgets);
  });
}
