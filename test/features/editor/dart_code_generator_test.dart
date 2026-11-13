import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/projects/domain/project_theme.dart';

const _emptyScreen = CanvasNode(
  id: 'root',
  type: 'screen',
  properties: {'device': 'phone', 'scroll': true},
);

void main() {
  group('rutas y clases', () {
    test('la primera pantalla es lib/main.dart y MyApp', () {
      expect(
        DartCodeGenerator.pathFor(fileName: 'main.dart', isEntry: true),
        'lib/main.dart',
      );
      expect(
        DartCodeGenerator.classNameFor(fileName: 'main.dart', isEntry: true),
        'MyApp',
      );
    });

    test('las demás van a lib/screens con el nombre de la pestaña', () {
      expect(
        DartCodeGenerator.pathFor(fileName: 'login.dart', isEntry: false),
        'lib/screens/login.dart',
      );
      expect(
        DartCodeGenerator.classNameFor(fileName: 'login.dart', isEntry: false),
        'LoginScreen',
      );
      expect(
        DartCodeGenerator.classNameFor(
          fileName: 'mi pantalla.dart',
          isEntry: false,
        ),
        'MiPantallaScreen',
      );
    });
  });

  group('código generado', () {
    test('el entrypoint mínimo compila la estructura pedida', () {
      final code = DartCodeGenerator.generate(
        screen: _emptyScreen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(code, contains("import 'package:flutter/material.dart';"));
      expect(code, contains('void main() {'));
      expect(code, contains('runApp(const MyApp());'));
      expect(code, contains('class MyApp extends StatelessWidget'));
      expect(code, contains('return MaterialApp('));
      expect(code, contains('home: Builder('));
      expect(code, contains('Tu pantalla está vacía'));
      expect(code, contains('dashboard_customize_outlined'));
      expect(code, contains('Arrastra un widget'));
    });

    test('una pantalla secundaria no lleva main()', () {
      final code = DartCodeGenerator.generate(
        screen: _emptyScreen,
        fileName: 'login.dart',
        isEntry: false,
      );

      expect(code, contains('class LoginScreen extends StatelessWidget'));
      expect(code, isNot(contains('void main()')));
      expect(code, contains('return Scaffold('));
    });

    test('incluye appBar, body y barra inferior', () {
      const screen = CanvasNode(
        id: 'root',
        type: 'screen',
        children: [
          CanvasNode(
            id: 'bar',
            type: 'appBar',
            properties: {'title': 'Inicio'},
          ),
          CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
          CanvasNode(id: 'nav', type: 'bottomNav'),
        ],
      );

      final code = DartCodeGenerator.generate(
        screen: screen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(code, contains('appBar: AppBar('));
      expect(
        code,
        contains("FittedBox(fit: BoxFit.scaleDown, child: const Text('Inicio'))"),
      );
      expect(code, contains("Text('Hola')"));
      expect(code, contains('padding: const EdgeInsets.all(16)'));
      expect(code, contains('bottomNavigationBar: NavigationBarTheme('));
      expect(code, contains('NavigationBar('));
    });

    test('varios hijos generan Column con separación y relleno', () {
      const screen = CanvasNode(
        id: 'root',
        type: 'screen',
        children: [
          CanvasNode(id: 'a', type: 'text', properties: {'text': 'Uno'}),
          CanvasNode(id: 'b', type: 'text', properties: {'text': 'Dos'}),
        ],
      );

      final code = DartCodeGenerator.generate(
        screen: screen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(code, contains('spacing: 12'));
      expect(code, contains('crossAxisAlignment: CrossAxisAlignment.stretch'));
      expect(code, contains("Text('Uno')"));
      expect(code, contains("Text('Dos')"));
    });

    test('el color de fondo en hex se exporta como Color', () {
      const screen = CanvasNode(
        id: 'root',
        type: 'screen',
        properties: {'background': '#1E88E5'},
      );

      final code = DartCodeGenerator.generate(
        screen: screen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(code, contains('backgroundColor: const Color(0xFF1E88E5)'));
    });

    test('un token de color se exporta como Theme.of', () {
      const screen = CanvasNode(
        id: 'root',
        type: 'screen',
        properties: {'background': 'low'},
      );

      final code = DartCodeGenerator.generate(
        screen: screen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(
        code,
        contains(
          'backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow',
        ),
      );
    });

    test('escapa comillas simples en los textos', () {
      const screen = CanvasNode(
        id: 'root',
        type: 'screen',
        children: [
          CanvasNode(id: 'txt', type: 'text', properties: {'text': "D'Angelo"}),
        ],
      );

      final code = DartCodeGenerator.generate(
        screen: screen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(code, contains(r"D\'Angelo"));
    });

    test('el tema del proyecto se exporta en main.dart', () {
      const theme = ProjectTheme(
        primary: '#112233',
        secondary: '#445566',
        tertiary: '#778899',
        bodySize: 15,
        appBarTitleSize: 24,
        dividerColor: '#010203',
        buttonRadius: 12,
      );

      final code = DartCodeGenerator.generate(
        screen: _emptyScreen,
        fileName: 'main.dart',
        isEntry: true,
        theme: theme,
      );

      expect(code, contains('theme: ThemeData('));
      expect(code, contains('seedColor: const Color(0xFF112233)'));
      expect(code, contains('primary: const Color(0xFF112233)'));
      expect(code, contains('secondary: const Color(0xFF445566)'));
      expect(code, contains('tertiary: const Color(0xFF778899)'));
      expect(code, contains('bodyMedium: TextStyle(fontSize: 15)'));
      expect(code, contains('titleTextStyle: TextStyle(fontSize: 24)'));
      expect(
        code,
        contains(
          'dividerTheme: DividerThemeData(color: const Color(0xFF010203))',
        ),
      );
      expect(code, contains('borderRadius: BorderRadius.circular(12)'));
    });

    test('sin tema no se emite ThemeData', () {
      final code = DartCodeGenerator.generate(
        screen: _emptyScreen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(code, isNot(contains('ThemeData(')));
    });

    test('el campo de texto exporta referencia y máscara', () {
      const screen = CanvasNode(
        id: 'root',
        type: 'screen',
        children: [
          CanvasNode(
            id: 'f',
            type: 'textField',
            properties: {
              'label': 'Clave',
              'hint': 'Tu clave',
              'obscure': true,
            },
          ),
        ],
      );

      final code = DartCodeGenerator.generate(
        screen: screen,
        fileName: 'main.dart',
        isEntry: true,
      );

      expect(code, contains('obscureText: true'));
      expect(code, contains("labelText: 'Clave'"));
      expect(code, contains("hintText: 'Tu clave'"));
    });
  });
}
