import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/presentation/widget_renderer.dart';

Future<void> _pumpNode(WidgetTester tester, CanvasNode node) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: WidgetRenderer(node: node))),
    ),
  );
}

void main() {
  testWidgets('los controles de formulario se dibujan', (tester) async {
    await _pumpNode(
      tester,
      const CanvasNode(
        id: 'c',
        type: 'checkbox',
        properties: {'label': 'Acepto'},
      ),
    );
    expect(find.text('Acepto'), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);

    await _pumpNode(
      tester,
      const CanvasNode(
        id: 's',
        type: 'switch',
        properties: {'label': 'Notificaciones'},
      ),
    );
    expect(find.byType(Switch), findsOneWidget);

    await _pumpNode(tester, const CanvasNode(id: 'sl', type: 'slider'));
    expect(find.byType(Slider), findsOneWidget);

    await _pumpNode(
      tester,
      const CanvasNode(
        id: 'p',
        type: 'progress',
        properties: {'style': 'circular'},
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pumpNode(
      tester,
      const CanvasNode(
        id: 'lt',
        type: 'listTile',
        properties: {'title': 'Perfil'},
      ),
    );
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('el botón respeta su variante', (tester) async {
    await _pumpNode(
      tester,
      const CanvasNode(
        id: 'b',
        type: 'button',
        properties: {'variant': 'outlined'},
      ),
    );

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('un contenedor vacío muestra una zona para soltar', (
    tester,
  ) async {
    await _pumpNode(tester, const CanvasNode(id: 'c1', type: 'column'));

    expect(find.text('Suelta widgets aquí'), findsOneWidget);
  });

  testWidgets('una fila pone a sus hijos a la misma altura', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: WidgetRenderer(
              node: const CanvasNode(
                id: 'r1',
                type: 'row',
                children: [
                  CanvasNode(id: 'a', type: 'text', properties: {'text': 'A'}),
                  CanvasNode(id: 'b', type: 'text', properties: {'text': 'B'}),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final a = tester.getCenter(find.text('A'));
    final b = tester.getCenter(find.text('B'));

    expect(a.dy, closeTo(b.dy, 0.5));
    expect(a.dx, lessThan(b.dx));
  });

  testWidgets('dibuja un texto con su contenido', (tester) async {
    await _pumpNode(
      tester,
      const CanvasNode(
        id: 't1',
        type: 'text',
        properties: {'text': 'Hola mundo'},
      ),
    );

    expect(find.text('Hola mundo'), findsOneWidget);
  });

  testWidgets('una columna dibuja sus hijos', (tester) async {
    await _pumpNode(
      tester,
      const CanvasNode(
        id: 'c1',
        type: 'column',
        children: [
          CanvasNode(id: 't1', type: 'text', properties: {'text': 'Uno'}),
          CanvasNode(id: 't2', type: 'text', properties: {'text': 'Dos'}),
        ],
      ),
    );

    expect(find.text('Uno'), findsOneWidget);
    expect(find.text('Dos'), findsOneWidget);
  });

  testWidgets('un tipo desconocido muestra marcador en vez de romper', (
    tester,
  ) async {
    await _pumpNode(
      tester,
      const CanvasNode(id: 'x1', type: 'webview'),
    );

    expect(find.textContaining('Componente desconocido'), findsOneWidget);
    expect(find.textContaining('webview'), findsOneWidget);
  });

  testWidgets('una propiedad inválida cae al valor por defecto', (
    tester,
  ) async {
    await _pumpNode(
      tester,
      const CanvasNode(
        id: 'i1',
        type: 'icon',
        properties: {'size': 9999},
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, 24);
  });

  testWidgets('un nodo hoja ignora hijos inyectados', (tester) async {
    await _pumpNode(
      tester,
      const CanvasNode(
        id: 't1',
        type: 'text',
        properties: {'text': 'Sin hijos'},
        children: [
          CanvasNode(
            id: 't2',
            type: 'text',
            properties: {'text': 'No debería verse'},
          ),
        ],
      ),
    );

    expect(find.text('Sin hijos'), findsOneWidget);
    expect(find.text('No debería verse'), findsNothing);
  });
}
