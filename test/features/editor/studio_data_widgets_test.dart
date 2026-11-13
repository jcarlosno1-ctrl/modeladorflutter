import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/presentation/widget_renderer.dart';

CanvasNode _screen(CanvasNode child) => CanvasNode(
  id: 'root',
  type: 'screen',
  children: [child],
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

String _code(CanvasNode node) => DartCodeGenerator.generate(
  screen: node,
  fileName: 'main.dart',
  isEntry: true,
);

void main() {
  testWidgets('IntrinsicWidth dibuja a su hijo', (tester) async {
    await _pump(
      tester,
      _screen(
        const CanvasNode(
          id: 'iw',
          type: 'intrinsicWidth',
          children: [CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'})],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(IntrinsicWidth), findsWidgets);
    expect(find.text('Hola'), findsOneWidget);
  });

  testWidgets('IntrinsicHeight dibuja a su hijo', (tester) async {
    await _pump(
      tester,
      _screen(
        const CanvasNode(
          id: 'ih',
          type: 'intrinsicHeight',
          children: [CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'})],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(IntrinsicHeight), findsWidgets);
  });

  testWidgets('DropdownMenu se dibuja', (tester) async {
    await _pump(
      tester,
      _screen(const CanvasNode(id: 'dm', type: 'dropdownMenu')),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(DropdownMenu<String>), findsOneWidget);
    expect(find.text('Seleccioná una opción'), findsWidgets);
  });

  testWidgets('DataTable se dibuja', (tester) async {
    await _pump(
      tester,
      _screen(const CanvasNode(id: 'dt', type: 'dataTable')),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Columna 1'), findsOneWidget);
  });

  testWidgets('Table se dibuja', (tester) async {
    await _pump(tester, _screen(const CanvasNode(id: 'tb', type: 'table')));
    expect(tester.takeException(), isNull);
    expect(find.byType(Table), findsOneWidget);
    expect(find.text('R1 C1'), findsOneWidget);
  });

  test('el código de los widgets nuevos usa las clases correctas', () {
    final code = _code(
      const CanvasNode(
        id: 'root',
        type: 'screen',
        children: [
          CanvasNode(
            id: 'iw',
            type: 'intrinsicWidth',
            children: [CanvasNode(id: 'txt', type: 'text')],
          ),
          CanvasNode(
            id: 'ih',
            type: 'intrinsicHeight',
            children: [CanvasNode(id: 'txt2', type: 'text')],
          ),
          CanvasNode(id: 'dm', type: 'dropdownMenu'),
          CanvasNode(id: 'dt', type: 'dataTable'),
          CanvasNode(id: 'tb', type: 'table'),
        ],
      ),
    );

    expect(code, contains('IntrinsicWidth('));
    expect(code, contains('IntrinsicHeight('));
    expect(code, contains('DropdownMenu<String>('));
    expect(code, contains('DataTable('));
    expect(code, contains('Table('));
    expect(code, contains('TableBorder.all'));
  });
}
