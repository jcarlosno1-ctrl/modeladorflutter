import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';

void main() {
  test('el diseño no adaptable centra con ancho máximo', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      properties: {
        'responsive': false,
        'contentWidth': 420,
        'padding': 16,
      },
      children: [
        CanvasNode(id: 't', type: 'text', properties: {'text': 'Hola'}),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('Center('));
    expect(code, contains('ConstrainedBox('));
    expect(code, contains('maxWidth: 420'));
  });

  test('el botón exporta la acción al tocar', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'b',
          type: 'button',
          properties: {
            'label': 'Enviar',
            'onTap': 'message',
            'eventMessage': 'Guardado',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('ScaffoldMessenger.of(context)'));
    expect(code, contains("Text('Guardado')"));
  });

  test('el campo de texto exporta foco y desenfoque', () {
    const screen = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'f',
          type: 'textField',
          properties: {
            'label': 'Nombre',
            'onFocus': 'message',
            'onBlur': 'back',
            'eventMessage': 'Enfocado',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: screen,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('Focus('));
    expect(code, contains('onFocusChange: (hasFocus)'));
    expect(code, contains("Text('Enfocado')"));
    expect(code, contains('Navigator.of(context).maybePop()'));
  });
}
