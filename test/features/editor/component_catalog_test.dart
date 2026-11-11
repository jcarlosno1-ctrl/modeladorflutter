import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/catalog/component_catalog.dart';
import 'package:modeladorflutter/features/editor/catalog/standard_catalog.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';

void main() {
  group('catálogo estándar', () {
    test('no hay tipos duplicados y todos los defaults son válidos', () {
      final types = standardCatalog.definitions.map((d) => d.type).toList();

      expect(types.toSet().length, types.length);
      expect(types, contains('text'));
      expect(types, contains('button'));

      for (final definition in standardCatalog.definitions) {
        for (final spec in definition.properties) {
          expect(
            spec.hasValidDefault,
            isTrue,
            reason: '${definition.type}.${spec.key} tiene default inválido',
          );
        }
      }
    });
  });

  group('validateCanvas', () {
    test('un documento correcto no reporta incidencias', () {
      const root = CanvasNode(
        id: 'n1',
        type: 'column',
        children: [CanvasNode(id: 'n2', type: 'text')],
      );

      expect(validateCanvas(root, standardCatalog), isEmpty);
    });

    test('detecta tipo desconocido', () {
      const root = CanvasNode(id: 'n1', type: 'webview');

      final issues = validateCanvas(root, standardCatalog);

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('desconocido'));
    });

    test('detecta propiedad no permitida', () {
      const root = CanvasNode(
        id: 'n1',
        type: 'text',
        properties: {'text': 'Hola', 'onPressed': 'hack'},
      );

      final issues = validateCanvas(root, standardCatalog);

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('onPressed'));
    });

    test('detecta valor fuera de rango', () {
      const root = CanvasNode(
        id: 'n1',
        type: 'icon',
        properties: {'size': 9999},
      );

      final issues = validateCanvas(root, standardCatalog);

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('size'));
    });

    test('detecta hijos en un componente hoja', () {
      const root = CanvasNode(
        id: 'n1',
        type: 'text',
        children: [CanvasNode(id: 'n2', type: 'text')],
      );

      final issues = validateCanvas(root, standardCatalog);

      expect(issues, hasLength(1));
      expect(issues.single.message, contains('no admite hijos'));
    });
  });

  group('CanvasNode', () {
    test('ida y vuelta a JSON conserva el árbol', () {
      const root = CanvasNode(
        id: 'n1',
        type: 'column',
        properties: {'gap': 12},
        children: [
          CanvasNode(id: 'n2', type: 'text', properties: {'text': 'Hola'}),
        ],
      );

      final json = root.toJson();
      final parsed = CanvasNode.fromJson(json);

      expect(parsed.id, 'n1');
      expect(parsed.type, 'column');
      expect(parsed.properties['gap'], 12);
      expect(parsed.children.single.properties['text'], 'Hola');
    });

    test('tryParseDocument devuelve null con documentos inválidos', () {
      expect(CanvasNode.tryParseDocument(null), isNull);
      expect(CanvasNode.tryParseDocument({'root': 'no'}), isNull);
      expect(
        CanvasNode.tryParseDocument({
          'root': {'id': 'n1'},
        }),
        isNull,
      );
    });

    test('fromJson rechaza un nodo sin id', () {
      expect(
        () => CanvasNode.fromJson({'type': 'text'}),
        throwsFormatException,
      );
    });
  });
}
