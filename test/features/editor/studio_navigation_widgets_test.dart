import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/presentation/widget_renderer.dart';

const _rail = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'rail',
      type: 'navigationRail',
      children: [
        CanvasNode(id: 'i1', type: 'icon', properties: {'icon': 'home'}),
        CanvasNode(id: 'i2', type: 'icon', properties: {'icon': 'search'}),
      ],
    ),
  ],
);

const _drawer = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'nd',
      type: 'navigationDrawer',
      children: [
        CanvasNode(
          id: 'lt',
          type: 'listTile',
          properties: {'title': 'Inicio'},
        ),
      ],
    ),
  ],
);

const _menu = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'pm',
      type: 'popupMenu',
      properties: {'icon': 'more_vert', 'item1': 'Editar'},
    ),
  ],
);

const _stepper = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'st',
      type: 'stepper',
      properties: {'steps': 3, 'current': 1},
    ),
  ],
);

const _transform = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'tr',
      type: 'transform',
      properties: {'rotation': 45, 'scale': 1.2},
      children: [CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'})],
    ),
  ],
);

Future<void> _pump(WidgetTester tester, CanvasNode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 780,
          child: WidgetRenderer(node: node),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el riel de navegación se dibuja', (tester) async {
    await _pump(tester, _rail);
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('el menú de navegación se dibuja', (tester) async {
    await _pump(tester, _drawer);
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('el menú emergente se dibuja', (tester) async {
    await _pump(tester, _menu);
    expect(tester.takeException(), isNull);
    expect(find.byType(PopupMenuButton<int>), findsOneWidget);
  });

  testWidgets('los pasos se dibujan', (tester) async {
    await _pump(tester, _stepper);
    expect(tester.takeException(), isNull);
    expect(find.byType(Stepper), findsOneWidget);
    expect(find.text('Paso 1'), findsOneWidget);
    expect(find.text('Paso 3'), findsOneWidget);
  });

  testWidgets('la transformación envuelve al hijo', (tester) async {
    await _pump(tester, _transform);
    expect(tester.takeException(), isNull);
    expect(find.byType(Transform), findsWidgets);
    expect(find.text('Hola'), findsOneWidget);
  });

  test('el código de los widgets nuevos usa las clases correctas', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'rail',
          type: 'navigationRail',
          children: [
            CanvasNode(id: 'i1', type: 'icon', properties: {'icon': 'home'}),
          ],
        ),
        CanvasNode(
          id: 'nd',
          type: 'navigationDrawer',
          children: [CanvasNode(id: 'lt', type: 'listTile')],
        ),
        CanvasNode(id: 'pm', type: 'popupMenu'),
        CanvasNode(id: 'st', type: 'stepper'),
        CanvasNode(
          id: 'tr',
          type: 'transform',
          children: [CanvasNode(id: 'txt', type: 'text')],
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('NavigationRail('));
    expect(code, contains('NavigationRailDestination('));
    expect(code, contains('NavigationDrawer('));
    expect(code, contains('PopupMenuButton<int>('));
    expect(code, contains('Stepper('));
    expect(code, contains('Transform.rotate('));
    expect(code, contains('Transform.scale('));
    expect(code, contains('Transform.translate('));
  });
}
