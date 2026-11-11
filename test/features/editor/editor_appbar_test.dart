import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
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
    CanvasNode(
      id: 'bar',
      type: 'appBar',
      properties: {
        'title': 'Inicio',
        'centerTitle': true,
        'elevation': 4,
        'toolbarHeight': 64,
        'backgroundColor': 'primary',
      },
      children: [
        CanvasNode(
          id: 'lead',
          type: 'icon',
          properties: {'icon': 'menu', 'position': 'leading'},
        ),
        CanvasNode(
          id: 'act',
          type: 'icon',
          properties: {'icon': 'settings', 'size': 20},
        ),
      ],
    ),
    CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Cuerpo'}),
  ],
);

void main() {
  testWidgets('la barra dibuja las esquinas inferiores redondeadas', (
    tester,
  ) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {'title': 'X', 'bottomRadius': 16},
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: WidgetRenderer(node: screen),
          ),
        ),
      ),
    );

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final shape = appBar.shape as RoundedRectangleBorder;
    expect(
      shape.borderRadius,
      BorderRadius.vertical(bottom: Radius.circular(16)),
    );
  });

  test('las esquinas se exportan como shape y ocultar usa SliverAppBar', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {
            'title': 'X',
            'bottomRadius': 16,
            'hideOnScroll': true,
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(
      code,
      contains(
        'shape: RoundedRectangleBorder(borderRadius: '
        'BorderRadius.vertical(bottom: Radius.circular(16)))',
      ),
    );
    expect(code, contains('body: NestedScrollView('));
    expect(code, contains('SliverAppBar('));
    expect(code, contains('floating: true'));
    expect(code, contains('snap: true'));
    expect(code, contains('SingleChildScrollView('));
    expect(code, isNot(contains('appBar: AppBar(')));
  });

  testWidgets('una barra alta no rompe el lienzo', (tester) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {'title': 'X', 'toolbarHeight': 96},
        ),
        CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: WidgetRenderer(node: screen),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hola'), findsOneWidget);
  });

  testWidgets('la config real de Sanpabloexpress renderiza el cuerpo', (
    tester,
  ) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      properties: {'device': 'phone', 'scroll': true, 'padding': 16, 'gap': 12},
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {
            'title': 'San Pablo Express',
            'bottom': true,
            'elevation': 24,
            'bottomColor': 'primary',
            'bottomTitle': 'prueba',
            'centerTitle': false,
            'bottomHeight': 72,
            'bottomRadius': 32,
            'hideOnScroll': true,
            'toolbarHeight': 96,
            'backgroundColor': '#138DBD',
            'foregroundColor': 'onPrimary',
            'scrolledUnderElevation': 24,
            'automaticallyImplyLeading': true,
          },
        ),
        CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: WidgetRenderer(node: screen),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Hola'), findsOneWidget);
  });

  testWidgets('un ícono con color heredar toma el color de la barra', (
    tester,
  ) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {'title': 'X', 'foregroundColor': 'onPrimary'},
          children: [
            CanvasNode(
              id: 'act',
              type: 'icon',
              properties: {'icon': 'settings', 'color': 'inherit'},
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: WidgetRenderer(node: screen),
          ),
        ),
      ),
    );

    final scheme = Theme.of(
      tester.element(find.byType(AppBar)),
    ).colorScheme;
    final icon = tester.widget<Icon>(find.byIcon(Icons.settings));

    expect(icon.color, scheme.onPrimary);
  });

  testWidgets('la barra dibuja las propiedades de AppBar', (tester) async {
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

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final scheme = Theme.of(
      tester.element(find.byType(AppBar)),
    ).colorScheme;

    expect(appBar.centerTitle, isTrue);
    expect(appBar.elevation, 4);
    expect(appBar.toolbarHeight, 64);
    expect(appBar.backgroundColor, scheme.primaryContainer);
    expect(appBar.leading, isA<Row>());
    expect(appBar.leadingWidth, 56);
    expect(appBar.actions, hasLength(1));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.byType(FittedBox), findsWidgets);
  });

  testWidgets('el color de texto de la barra llega al título del lienzo', (
    tester,
  ) async {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {'title': 'Color', 'foregroundColor': 'onPrimary'},
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: WidgetRenderer(node: screen),
          ),
        ),
      ),
    );

    final scheme = Theme.of(
      tester.element(find.byType(AppBar)),
    ).colorScheme;
    final title = tester.widget<Text>(find.text('Color'));

    expect(title.style?.color, scheme.onPrimary);
  });

  test('el código de AppBar incluye todas sus propiedades y acciones', () {
    final code = DartCodeGenerator.generate(
      screen: _screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains("title: FittedBox(fit: BoxFit.scaleDown, child: const Text('Inicio'))"));
    expect(code, contains('centerTitle: true'));
    expect(code, contains('elevation: 4'));
    expect(code, contains('toolbarHeight: 64'));
    expect(
      code,
      contains('backgroundColor: Theme.of(context).colorScheme.primaryContainer'),
    );
    expect(code, contains('leading: Row('));
    expect(code, contains('leadingWidth: 56'));
    expect(code, contains('actions: ['));
    expect(
      code,
      contains(
        'IconButton(onPressed: () {}, icon: '
        'Icon(Icons.settings, size: 20, '
        'color: Theme.of(context).colorScheme.primary))',
      ),
    );
  });

  test('el código emite automáticamente las props no default', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {
            'title': 'X',
            'scrolledUnderElevation': 8,
            'foregroundColor': 'onSurface',
            'automaticallyImplyLeading': false,
            'backgroundColor': '#112233',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('scrolledUnderElevation: 8'));
    expect(
      code,
      contains('foregroundColor: Theme.of(context).colorScheme.onSurface'),
    );
    expect(code, contains('automaticallyImplyLeading: false'));
    expect(code, contains('backgroundColor: const Color(0xFF112233)'));
  });

  test('showBack viejo se migra a automaticallyImplyLeading', () {
    final node = CanvasNode.fromJson({
      'id': 'bar',
      'type': 'appBar',
      'properties': {'title': 'Vieja', 'showBack': false},
    });

    expect(node.properties['automaticallyImplyLeading'], false);
  });

  test('leading viejo se convierte en ícono de leading', () {
    final node = CanvasNode.fromJson({
      'id': 'bar',
      'type': 'appBar',
      'properties': {'title': 'Vieja', 'leading': 'menu'},
    });

    expect(node.properties['automaticallyImplyLeading'], false);
    expect(node.children.single.type, 'icon');
    expect(node.children.single.properties['icon'], 'menu');
    expect(node.children.single.properties['position'], 'leading');
  });

  test('el gradiente de la barra se exporta', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {
            'title': 'X',
            'gradient': true,
            'gradientColor': 'tertiary',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('backgroundColor: Colors.transparent'));
    expect(code, contains('flexibleSpace: Container('));
    expect(code, contains('LinearGradient('));
    expect(code, contains('Theme.of(context).colorScheme.primary'));
    expect(
      code,
      contains('Theme.of(context).colorScheme.tertiaryContainer'),
    );
  });

  test('los íconos de leading se generan', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {
            'title': 'X',
            'automaticallyImplyLeading': false,
          },
          children: [
            CanvasNode(
              id: 'lead',
              type: 'icon',
              properties: {'icon': 'menu', 'position': 'leading'},
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

    expect(code, contains('leading: Row('));
    expect(code, contains('leadingWidth: 56'));
    expect(code, contains('Icons.menu'));
    expect(code, isNot(contains('bottom:')));
  });

  test('solo entran íconos en la AppBar (acciones)', () async {
    final repository = FakeProjectScreenRepository(
      screens: [
        ProjectScreen(
          id: 's-1',
          projectId: _project.id,
          name: 'main.dart',
          position: 0,
          canvas: _screen,
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

    await notifier.addComponentAt('icon', 'bar');
    await notifier.addComponentAt('text', 'bar');

    final root = container.read(editorSessionProvider).root!;
    final bar = root.findNode('bar')!;
    // Ya había dos íconos (leading + acción) y se agregó otro; el texto fue
    // rechazado.
    expect(bar.children, hasLength(3));
    expect(bar.children.every((child) => child.type == 'icon'), isTrue);
  });
}
