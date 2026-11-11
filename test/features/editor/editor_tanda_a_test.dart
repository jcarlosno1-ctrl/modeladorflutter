import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/catalog/property_spec.dart';
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
          CanvasNode(id: 'txt', type: 'text', properties: {'text': 'Hola'}),
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

void main() {
  testWidgets('el panel de propiedades agrupa por secciones', (tester) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.nodeTile('root')));
    await tester.pumpAndSettle();

    expect(find.text('DISEÑO'), findsOneWidget);
    expect(find.text('COLORES'), findsOneWidget);

    await tester.drag(
      find.byKey(EditorKeys.propertiesList),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.text('COMPORTAMIENTO'), findsOneWidget);
  });

  testWidgets('el código muestra cabecera, líneas y estado', (tester) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    expect(find.textContaining('líneas'), findsOneWidget);
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.text('Dart 3 · Material 3'), findsOneWidget);
    expect(
      find.textContaining('Pega este código en lib/main.dart'),
      findsOneWidget,
    );
  });

  test('PropertySpec conserva grupo, ayuda y unidad', () {
    const spec = PropertySpec.number(
      'padding',
      'Relleno',
      defaultValue: 16,
      group: 'Diseño',
      hint: 'Espacio interior.',
      suffix: 'px',
      integer: true,
    );

    expect(spec.group, 'Diseño');
    expect(spec.hint, 'Espacio interior.');
    expect(spec.suffix, 'px');
    expect(spec.integer, isTrue);
  });

  test('PropertySpec usa valores por defecto sensatos', () {
    const spec = PropertySpec.text('title', 'Título');

    expect(spec.group, 'General');
    expect(spec.hint, isNull);
    expect(spec.suffix, isNull);
    expect(spec.integer, isFalse);
  });
}
