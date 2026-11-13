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
  testWidgets('la barra inferior usa NavigationBar (M3) real', (tester) async {
    await _pump(tester, _screen);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));

    expect(bar.selectedIndex, 2);
    expect(bar.destinations, hasLength(3));
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

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(2));
    expect(bar.selectedIndex, 1);
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

    expect(code, contains('bottomNavigationBar: NavigationBarTheme('));
    expect(code, contains('NavigationBar('));
    expect(code, contains('WidgetState.selected'));
    expect(code, contains('selectedIndex: 2'));
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

    expect(code, contains('NavigationBar('));
    expect(code, contains('selectedIndex: 1'));
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

  test('agregar y quitar destinos respeta el límite 2..6', () async {
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
              CanvasNode(
                id: 'nav',
                type: 'bottomNav',
                children: [
                  CanvasNode(id: 'i1', type: 'icon'),
                  CanvasNode(id: 'i2', type: 'icon'),
                ],
              ),
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

    for (var index = 0; index < 6; index++) {
      await notifier.addDestination();
    }
    var bar = container
        .read(editorSessionProvider)
        .root!
        .findNode('nav')!;
    expect(bar.children, hasLength(6));

    for (var index = 0; index < 8; index++) {
      await notifier.removeLastDestination();
    }
    bar = container.read(editorSessionProvider).root!.findNode('nav')!;
    expect(bar.children, hasLength(2));
  });

  testWidgets('una barra sin destinos muestra el mínimo por defecto', (
    tester,
  ) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [CanvasNode(id: 'nav', type: 'bottomNav')],
    );

    await _pump(tester, screen);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, greaterThanOrEqualTo(2));
  });

  test('agregar destino a una barra vacía siembra dos', () async {
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
            children: [CanvasNode(id: 'nav', type: 'bottomNav')],
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
    await notifier.addDestination();

    var bar = container.read(editorSessionProvider).root!.findNode('nav')!;
    expect(bar.children, hasLength(2));

    await notifier.addDestination();
    bar = container.read(editorSessionProvider).root!.findNode('nav')!;
    expect(bar.children, hasLength(3));
  });

  testWidgets('el panel agrega y quita destinos', (tester) async {
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
              CanvasNode(
                id: 'nav',
                type: 'bottomNav',
                children: [
                  CanvasNode(id: 'i1', type: 'icon'),
                  CanvasNode(id: 'i2', type: 'icon'),
                ],
              ),
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

    await tester.tap(find.byKey(EditorKeys.nodeTile('nav')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(EditorKeys.addDestination),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(EditorKeys.propertiesList),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('DESTINOS (2)'), findsOneWidget);

    await tester.tap(find.byKey(EditorKeys.addDestination));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    expect(
      container.read(editorSessionProvider).root!.findNode('nav')!.children,
      hasLength(3),
    );

    await tester.tap(find.byKey(EditorKeys.nodeTile('nav')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(EditorKeys.removeDestination),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(EditorKeys.propertiesList),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.removeDestination));
    await tester.pumpAndSettle();

    expect(
      container.read(editorSessionProvider).root!.findNode('nav')!.children,
      hasLength(2),
    );
  });

  testWidgets('al tocar un destino se selecciona ese ícono', (tester) async {
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
              CanvasNode(
                id: 'nav',
                type: 'bottomNav',
                children: [
                  CanvasNode(
                    id: 'i1',
                    type: 'icon',
                    properties: {'icon': 'home', 'label': 'Inicio1'},
                  ),
                  CanvasNode(
                    id: 'i2',
                    type: 'icon',
                    properties: {'icon': 'search', 'label': 'Buscar'},
                  ),
                ],
              ),
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

    await tester.tap(find.byIcon(Icons.home).first);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    expect(container.read(editorSessionProvider).selectedNodeId, 'i1');
    expect(find.text('Inicio1'), findsWidgets);
  });

  testWidgets('el selector de destino usa los nombres', (tester) async {
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
              CanvasNode(
                id: 'nav',
                type: 'bottomNav',
                children: [
                  CanvasNode(
                    id: 'i1',
                    type: 'icon',
                    properties: {'icon': 'home', 'label': 'Inicio1'},
                  ),
                  CanvasNode(
                    id: 'i2',
                    type: 'icon',
                    properties: {'icon': 'search', 'label': 'Buscar'},
                  ),
                ],
              ),
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

    await tester.tap(find.byKey(EditorKeys.nodeTile('nav')));
    await tester.pumpAndSettle();

    final selector = find.byKey(EditorKeys.propertyField('selected'));
    await tester.ensureVisible(selector);
    await tester.pumpAndSettle();
    await tester.tap(selector);
    await tester.pumpAndSettle();

    expect(find.text('Inicio1'), findsWidgets);
    await tester.tap(find.text('Buscar').last);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    final nav = container.read(editorSessionProvider).root!.findNode('nav')!;
    expect(nav.properties['selected'], 1);
  });

  testWidgets('ocultar la etiqueta deja solo el ícono', (tester) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'nav',
          type: 'bottomNav',
          children: [
            CanvasNode(
              id: 'i1',
              type: 'icon',
              properties: {
                'icon': 'home',
                'label': 'Inicio',
                'showLabel': false,
              },
            ),
            CanvasNode(
              id: 'i2',
              type: 'icon',
              properties: {'icon': 'search', 'label': 'Buscar'},
            ),
          ],
        ),
      ],
    );

    await _pump(tester, screen);

    expect(find.text('Inicio'), findsNothing);
    expect(find.text('Buscar'), findsOneWidget);
  });

  testWidgets('una forma de indicador vieja no rompe el panel', (tester) async {
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
              CanvasNode(
                id: 'nav',
                type: 'bottomNav',
                properties: {'indicatorShape': 'rounded'},
              ),
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
    await tester.tap(find.byKey(EditorKeys.nodeTile('nav')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('los colores globales se usan como respaldo', (tester) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'nav',
          type: 'bottomNav',
          properties: {
            'selectedIconColor': '#FF0000',
            'unselectedIconColor': '#00FF00',
            'selectedLabelColor': '#0000FF',
            'unselectedLabelColor': '#333333',
          },
          children: [
            CanvasNode(id: 'i1', type: 'icon', properties: {'icon': 'home'}),
            CanvasNode(id: 'i2', type: 'icon', properties: {'icon': 'search'}),
          ],
        ),
      ],
    );

    await _pump(tester, screen);

    final theme = tester.widget<NavigationBarTheme>(
      find.byType(NavigationBarTheme),
    );
    final selected = theme.data.iconTheme!.resolve({WidgetState.selected})!;
    final unselected = theme.data.iconTheme!.resolve(<WidgetState>{})!;
    expect(selected.color, const Color(0xFFFF0000));
    expect(unselected.color, const Color(0xFF00FF00));
    expect(
      theme.data.labelTextStyle!
          .resolve({WidgetState.selected})!
          .color,
      const Color(0xFF0000FF),
    );
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
