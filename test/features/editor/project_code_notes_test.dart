import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';

void main() {
  test('las notas envuelven widgets del body y los inline', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'txt',
          type: 'text',
          properties: {'text': 'Hola'},
        ),
        CanvasNode(
          id: 'bar',
          type: 'appBar',
          properties: {'title': 'Inicio'},
        ),
        CanvasNode(
          id: 'nav',
          type: 'bottomNav',
          children: [
            CanvasNode(
              id: 'dest',
              type: 'icon',
              properties: {'icon': 'home', 'label': 'Inicio'},
            ),
          ],
        ),
        CanvasNode(
          id: 'fab',
          type: 'fab',
          properties: {'icon': 'add'},
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('/* inicio de Scaffold */'));
    expect(code, contains('/* fin de Scaffold */'));
    expect(code, contains('inicio de Texto'));
    expect(code, contains('fin de Texto'));
    expect(code, contains('/* inicio de Barra superior */'));
    expect(code, contains('/* fin de Barra superior */'));
    expect(code, isNot(contains('// fin de Barra superior,')));
    expect(code, contains('/* fin de Barra superior */,'));
    expect(code, contains('/* inicio de Barra inferior */'));
    expect(code, contains('/* fin de Barra inferior */'));
    expect(code, contains('// inicio de Ícono'));
    expect(code, contains('// fin de Ícono'));
    expect(code, contains('/* inicio de Botón flotante */'));
    expect(code, contains('/* fin de Botón flotante */'));
  });
}
