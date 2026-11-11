import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
import 'package:modeladorflutter/features/editor/presentation/editor_screen.dart';
import 'package:modeladorflutter/features/editor/presentation/widget_renderer.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../../helpers/fake_project_screen_repository.dart';

final _project = Project(
  id: 'p-1',
  name: 'Mi app',
  createdAt: DateTime.utc(2026, 11, 7),
);

const _screen = CanvasNode(
  id: 'root',
  type: 'screen',
  properties: {'device': 'phone', 'scroll': true},
  children: [
    CanvasNode(
      id: 'bar',
      type: 'appBar',
      properties: {'title': 'Título'},
    ),
    CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Cuerpo'}),
    CanvasNode(id: 'nav', type: 'bottomNav', properties: {'items': '3'}),
    CanvasNode(id: 'fab', type: 'fab'),
  ],
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

void main() {
  testWidgets('Scaffold coloca appBar arriba, body al centro y nav al pie', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: WidgetRenderer(node: _screen),
          ),
        ),
      ),
    );

    expect(find.text('Título'), findsOneWidget);
    expect(find.text('Cuerpo'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    final barY = tester.getTopLeft(find.text('Título')).dy;
    final bodyY = tester.getTopLeft(find.text('Cuerpo')).dy;
    final navY = tester.getTopLeft(find.byIcon(Icons.home).first).dy;

    expect(barY, lessThan(bodyY));
    expect(bodyY, lessThan(navY));
  });

  testWidgets('solo puede haber una appBar y no se inserta antes de ella', (
    tester,
  ) async {
    final repository = _repositoryWith(_screen);
    final container = ProviderContainer(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorSessionProvider.notifier);
    await notifier.openProject(_project);

    await notifier.addComponent('appBar');
    await notifier.addComponent('bottomNav');

    var root = container.read(editorSessionProvider).root!;
    expect(root.children.where((c) => c.type == 'appBar'), hasLength(1));
    expect(root.children.where((c) => c.type == 'bottomNav'), hasLength(1));

    final bar = root.children.firstWhere((c) => c.type == 'appBar');
    final before = root.children.length;
    await notifier.addComponentAt('text', bar.id);

    root = container.read(editorSessionProvider).root!;
    expect(root.children, hasLength(before));
  });

  testWidgets('el menú lateral está oculto y se muestra con el botón', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      _repositoryWith(
        const CanvasNode(
          id: 'root',
          type: 'screen',
          children: [CanvasNode(id: 'drawer', type: 'drawer')],
        ),
      ),
    );

    expect(find.byKey(EditorKeys.toggleDrawer), findsOneWidget);
    expect(find.text('Elemento 1'), findsNothing);

    await tester.tap(find.byKey(EditorKeys.toggleDrawer));
    await tester.pumpAndSettle();

    expect(find.text('Elemento 1'), findsOneWidget);
  });

  testWidgets('el panel muestra el nombre Flutter del nodo', (tester) async {
    await _pumpEditor(tester, _repositoryWith(_screen));

    await tester.tap(find.byKey(EditorKeys.nodeTile('root')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Flutter · Scaffold'), findsOneWidget);
  });
}
