import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';

void main() {
  test('el ícono exporta sombra, relleno, dirección y semántica', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'ic',
          type: 'icon',
          properties: {
            'icon': 'arrow_back',
            'fill': 0.6,
            'shadow': true,
            'shadowBlur': 12,
            'textDirection': 'rtl',
            'semanticLabel': 'Abrir menú',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('fill: 0.6'));
    expect(code, contains('shadows: [BoxShadow('));
    expect(code, contains('blurRadius: 12'));
    expect(code, contains('textDirection: TextDirection.rtl'));
    expect(code, contains("semanticLabel: 'Abrir menú'"));
  });

  test('el ícono alinea igual en el lienzo y en el código', () {
    CanvasNode screenWith(String? alignment) => CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'ic',
          type: 'icon',
          properties: {
            'icon': 'star',
            'alignment': ?alignment,
          },
        ),
      ],
    );

    String codeFor(String? alignment) => DartCodeGenerator.generate(
      screen: screenWith(alignment),
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(codeFor(null), contains('alignment: Alignment.center'));
    expect(codeFor('start'), contains('alignment: Alignment.centerLeft'));
    expect(codeFor('end'), contains('alignment: Alignment.centerRight'));
  });

  test('ancho y alineación aplican a cualquier control del body', () {
    const expanded = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [CanvasNode(id: 'txt', type: 'text')],
    );
    const fitted = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'btn',
          type: 'button',
          properties: {
            'widthMode': 'fit',
            'bodyAlignment': 'center',
          },
        ),
      ],
    );

    final expandedCode = DartCodeGenerator.generate(
      screen: expanded,
      fileName: 'main.dart',
      isEntry: true,
    );
    final fittedCode = DartCodeGenerator.generate(
      screen: fitted,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(expandedCode, contains('SizedBox('));
    expect(expandedCode, contains('width: double.infinity'));
    expect(fittedCode, contains('Alignment.center'));
    expect(fittedCode, contains('IntrinsicWidth('));
  });

  test('las formas del indicador se exportan como en la referencia', () {
    const circle = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'nav',
          type: 'bottomNav',
          properties: {'indicatorShape': 'circle'},
        ),
      ],
    );
    const rectangle = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'nav',
          type: 'bottomNav',
          properties: {'indicatorShape': 'rectangle'},
        ),
      ],
    );

    final circleCode = DartCodeGenerator.generate(
      screen: circle,
      fileName: 'main.dart',
      isEntry: true,
    );
    final rectangleCode = DartCodeGenerator.generate(
      screen: rectangle,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(circleCode, contains('const CircleBorder()'));
    expect(rectangleCode, contains('BorderRadius.circular(8)'));
  });
}
