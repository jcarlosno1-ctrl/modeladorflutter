import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/project_export.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';

ProjectScreen _screen(String id, String name, int position) {
  return ProjectScreen(
    id: id,
    projectId: 'p-1',
    name: name,
    position: position,
    canvas: const CanvasNode(
      id: 'root',
      type: 'screen',
      children: [CanvasNode(id: 't', type: 'text')],
    ),
  );
}

void main() {
  test('genera main.dart y los archivos de screens', () {
    final files = buildProjectFiles(
      screens: [
        _screen('s-1', 'main.dart', 0),
        _screen('s-2', 'detalle.dart', 1),
      ],
      entryScreenId: 's-1',
    );

    expect(files, hasLength(2));
    expect(files[0].path, 'lib/main.dart');
    expect(files[0].content, contains('void main()'));
    expect(files[1].path, 'lib/screens/detalle.dart');
    expect(files[1].content, contains('class DetalleScreen'));
  });

  test('el ZIP contiene los archivos y una firma válida', () {
    final files = buildProjectFiles(
      screens: [
        _screen('s-1', 'main.dart', 0),
        _screen('s-2', 'detalle.dart', 1),
      ],
      entryScreenId: 's-1',
    );
    final bytes = buildZipBytes(files);

    expect(bytes.take(4).toList(), [0x50, 0x4B, 0x03, 0x04]);

    final content = latin1.decode(bytes);
    expect(content, contains('lib/main.dart'));
    expect(content, contains('lib/screens/detalle.dart'));
    expect(content, contains('void main()'));
  });
}
