import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
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
  children: [
    CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
    CanvasNode(
      id: 'nav',
      type: 'bottomNav',
      properties: {'items': '3', 'selected': 2, 'showLabels': true},
    ),
  ],
);

Future<void> _pump(WidgetTester tester, CanvasNode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 640,
          child: WidgetRenderer(node: node),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('la barra inferior usa BottomNavigationBar real', (tester) async {
    await _pump(tester, _screen);

    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );

    expect(bar.currentIndex, 2);
    expect(bar.items, hasLength(3));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Favorito'), findsOneWidget);
  });

  testWidgets('los íconos definen la cantidad de ítems y sus etiquetas', (
    tester,
  ) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'nav',
          type: 'bottomNav',
          properties: {'selected': 1},
          children: [
            CanvasNode(
              id: 'i1',
              type: 'icon',
              properties: {'icon': 'search', 'label': 'Buscar'},
            ),
            CanvasNode(
              id: 'i2',
              type: 'icon',
              properties: {'icon': 'person', 'label': 'Perfil'},
            ),
          ],
        ),
      ],
    );

    await _pump(tester, screen);

    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.items, hasLength(2));
    expect(bar.currentIndex, 1);
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('el TabBar es un widget aparte con su controlador', (
    tester,
  ) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'tabs',
          type: 'tabs',
          properties: {'count': '3', 'selected': 1},
        ),
      ],
    );

    await _pump(tester, screen);

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.byType(DefaultTabController), findsOneWidget);
    expect(find.text('Dos'), findsOneWidget);
  });

  test('el código de la barra inferior incluye índice y etiquetas', () {
    final code = DartCodeGenerator.generate(
      screen: _screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('bottomNavigationBar: BottomNavigationBar('));
    expect(code, contains('currentIndex: 2'));
    expect(code, contains('type: BottomNavigationBarType.fixed'));
    expect(code, contains("label: 'Inicio'"));
    expect(code, contains("label: 'Favorito'"));
  });

  test('el código del TabBar usa DefaultTabController', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'tabs',
          type: 'tabs',
          properties: {'count': '3', 'selected': 1},
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('DefaultTabController('));
    expect(code, contains('length: 3'));
    expect(code, contains('initialIndex: 1'));
    expect(code, contains("Tab(text: 'Dos')"));
  });

  test('los ítems con íconos y etiquetas se exportan', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'nav',
          type: 'bottomNav',
          properties: {
            'selected': 1,
            'type': 'shifting',
            'backgroundColor': 'primary',
          },
          children: [
            CanvasNode(
              id: 'item1',
              type: 'icon',
              properties: {'icon': 'search', 'label': 'Buscar'},
            ),
            CanvasNode(
              id: 'item2',
              type: 'icon',
              properties: {'icon': 'person', 'label': 'Perfil'},
            ),
          ],
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('BottomNavigationBar('));
    expect(code, contains('currentIndex: 1'));
    expect(code, contains('BottomNavigationBarType.shifting'));
    expect(code, contains("label: 'Buscar'"));
    expect(code, contains("label: 'Perfil'"));
    expect(code, contains('Icons.person'));
  });

  test('los ítems solo entran en la barra inferior', () async {
    final repository = FakeProjectScreenRepository(
      screens: [
        ProjectScreen(
          id: 's-1',
          projectId: _project.id,
          name: 'main.dart',
          position: 0,
          canvas: const CanvasNode(
            id: 'root',
            type: 'screen',
            children: [
              CanvasNode(id: 'nav', type: 'bottomNav'),
              CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
            ],
          ),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorSessionProvider.notifier);
    await notifier.openProject(_project);

    await notifier.addComponentAt('icon', 'nav');
    await notifier.addComponentAt('icon', 'nav');
    await notifier.addComponentAt('text', 'nav');
    // Sin barra inferior, un ícono suelto va al cuerpo.
    await notifier.removeNode('nav');
    await notifier.addComponent('icon');

    final root = container.read(editorSessionProvider).root!;
    expect(root.children.where((node) => node.type == 'bottomNav'), isEmpty);
    expect(root.findNode('txt'), isNotNull);
  });

  testWidgets('el árbol ordena por slot y no por inserción', (tester) async {
    final repository = FakeProjectScreenRepository(
      screens: [
        ProjectScreen(
          id: 's-1',
          projectId: _project.id,
          name: 'main.dart',
          position: 0,
          canvas: const CanvasNode(
            id: 'root',
            type: 'screen',
            children: [
              CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
              CanvasNode(id: 'nav', type: 'bottomNav'),
              CanvasNode(id: 'bar', type: 'appBar'),
            ],
          ),
        ),
      ],
    );

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

    final barY = tester.getTopLeft(find.byKey(EditorKeys.nodeTile('bar'))).dy;
    final textY = tester.getTopLeft(find.byKey(EditorKeys.nodeTile('txt'))).dy;
    final navY = tester.getTopLeft(find.byKey(EditorKeys.nodeTile('nav'))).dy;

    expect(barY, lessThan(textY));
    expect(textY, lessThan(navY));
  });
}
