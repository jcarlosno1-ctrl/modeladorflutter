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

/// Pantalla con raíz antigua (`column`) para probar la migración.
FakeProjectScreenRepository _legacyRepository() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'Pantalla 1',
      position: 0,
      canvas: const CanvasNode(
        id: 'root',
        type: 'column',
        properties: {'gap': 12},
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

Future<void> _doubleTap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el dispositivo define el tamaño del artboard', (tester) async {
    final repository = _legacyRepository();
    await _pumpEditor(tester, repository);

    final canvas = find.byKey(EditorKeys.canvas);
    expect(tester.getSize(canvas).width, 390);
    expect(tester.getSize(canvas).height, 844);

    // Cambiar el dispositivo desde la barra del lienzo.
    await tester.tap(find.byKey(EditorKeys.deviceOption('tablet')));
    await tester.pumpAndSettle();

    final tablet = tester.getSize(canvas);
    expect(tablet.width, 768);
    expect(tablet.height, 1024);
  });

  testWidgets('una pantalla antigua migra a nodo screen sin perder hijos', (
    tester,
  ) async {
    final repository = _legacyRepository();
    await _pumpEditor(tester, repository);

    // El contenido previo sigue visible tras la migración.
    expect(find.text('Hola'), findsOneWidget);

    await _doubleTap(tester, find.byKey(EditorKeys.paletteItem('text')));
    await tester.pumpAndSettle();

    final saved = repository.lastSaved!;
    expect(saved.type, 'screen');
    expect(saved.children, hasLength(2));
    expect(saved.children.first.properties['text'], 'Hola');
  });

  testWidgets('desactivar el scroll quita el desplazamiento interno', (
    tester,
  ) async {
    final repository = _legacyRepository();
    await _pumpEditor(tester, repository);

    final canvas = find.byKey(EditorKeys.canvas);
    expect(
      find.descendant(of: canvas, matching: find.byType(Scrollable)),
      findsOneWidget,
    );

    await tester.tap(find.byKey(EditorKeys.nodeTile('root')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(EditorKeys.propertiesList),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.propertyField('scroll')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: canvas, matching: find.byType(Scrollable)),
      findsNothing,
    );
  });
}
