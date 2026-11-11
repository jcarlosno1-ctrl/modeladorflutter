import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
import 'package:modeladorflutter/features/editor/presentation/editor_screen.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../../helpers/fake_project_screen_repository.dart';

final _project = Project(
  id: 'p-1',
  name: 'Mi app',
  createdAt: DateTime.utc(2026, 11, 7),
);

FakeProjectScreenRepository _repository() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'main.dart',
      position: 0,
      canvas: const CanvasNode(
        id: 'root',
        type: 'screen',
        children: [
          CanvasNode(id: 't', type: 'text', properties: {'text': 'Hola'}),
        ],
      ),
    ),
  ],
);

Future<void> _pumpEditor(
  WidgetTester tester,
  FakeProjectScreenRepository repository,
) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(home: EditorScreen(project: _project)),
    ),
  );
  await tester.pumpAndSettle();
}

String _hexOf(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  testWidgets('el hex muestra el color actual y la paleta lo actualiza', (
    tester,
  ) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.nodeTile('root')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    final scheme = Theme.of(
      tester.element(find.byType(EditorScreen)),
    ).colorScheme;
    final field = find.byKey(EditorKeys.propertyField('background.hex'));

    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller!.text,
      _hexOf(scheme.surface),
    );

    // Elegir un color desde la paleta rápida del diálogo.
    await tester.tap(find.byKey(EditorKeys.colorPalette('background')));
    await tester.pumpAndSettle();
    expect(find.text('Elegir color'), findsOneWidget);

    await tester.enterText(find.byKey(EditorKeys.dialogHex), '#112233');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.applyColor));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(field).controller!.text.toUpperCase(),
      '#112233',
    );
    expect(
      container.read(editorSessionProvider).root!.properties['background'],
      '#112233',
    );

    // Escribir un hex manual cambia el fondo.
    await tester.ensureVisible(field);
    await tester.enterText(field, '#123456');
    await tester.pump(const Duration(milliseconds: 700));

    expect(
      container.read(editorSessionProvider).root!.properties['background'],
      '#123456',
    );
    expect(
      tester.widget<TextField>(field).controller!.text.toUpperCase(),
      '#123456',
    );
  });
}
