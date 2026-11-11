import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
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

const _canvas = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'bar',
      type: 'appBar',
      properties: {'title': 'Mi app'},
    ),
    CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
  ],
);

FakeProjectScreenRepository _repository() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'main.dart',
      position: 0,
      canvas: _canvas,
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
  testWidgets('la barra superior muestra estado y copiar', (tester) async {
    await _pumpEditor(tester, _repository());

    expect(find.byKey(EditorKeys.status), findsOneWidget);
    expect(find.byKey(EditorKeys.copyFromTop), findsOneWidget);
  });

  testWidgets('el buscador filtra la biblioteca', (tester) async {
    await _pumpEditor(tester, _repository());

    await tester.enterText(find.byKey(EditorKeys.librarySearch), 'imagen');
    await tester.pumpAndSettle();

    expect(find.byKey(EditorKeys.paletteItem('image')), findsOneWidget);
    expect(find.byKey(EditorKeys.paletteItem('button')), findsNothing);
  });

  testWidgets('el contador de capas refleja el árbol', (tester) async {
    await _pumpEditor(tester, _repository());

    expect(find.byKey(EditorKeys.layersCount), findsOneWidget);
    // La pantalla no cuenta: barra + texto.
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('el toolbar cambia el dispositivo de la pantalla', (
    tester,
  ) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.deviceOption('tablet')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 700));

    expect(repository.lastSaved!.properties['device'], 'tablet');
  });

  testWidgets('un AppBar oculto no se dibuja', (tester) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.nodeTile('bar')));
    await tester.pumpAndSettle();

    final barInCanvas = find.descendant(
      of: find.byKey(EditorKeys.canvas),
      matching: find.byType(AppBar),
    );
    expect(barInCanvas, findsOneWidget);

    final toggle = find.byKey(EditorKeys.propertyField('visible'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(barInCanvas, findsNothing);
  });

  test('un AppBar oculto no se exporta', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {'title': 'X', 'visible': false},
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, isNot(contains('appBar:')));
  });

  testWidgets('la categoría Material agrupa tarjeta y fila de lista', (
    tester,
  ) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.category('material')));
    await tester.pumpAndSettle();

    expect(find.byKey(EditorKeys.paletteItem('card')), findsOneWidget);
    expect(find.byKey(EditorKeys.paletteItem('listTile')), findsOneWidget);
  });

  testWidgets('el zoom se puede cambiar y restablecer', (tester) async {
    await _pumpEditor(tester, _repository());

    final label = find.byKey(EditorKeys.zoomLabel);
    final initial = tester.widget<Text>(label).data;

    await tester.tap(find.byKey(EditorKeys.zoomIn));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(label).data, isNot(initial));

    await tester.tap(find.byKey(EditorKeys.zoomReset));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(label).data, initial);
  });
}
