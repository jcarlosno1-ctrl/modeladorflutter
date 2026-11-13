import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
import 'package:modeladorflutter/features/editor/presentation/widget_renderer.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../../helpers/fake_project_screen_repository.dart';

final _project = Project(
  id: 'p-1',
  name: 'Mi app',
  createdAt: DateTime.utc(2026, 11, 7),
);

const _screen = CanvasNode(
  id: 'root',
  type: 'screen',
  children: [
    CanvasNode(
      id: 'row',
      type: 'row',
      children: [CanvasNode(id: 'txt', type: 'text')],
    ),
  ],
);

FakeProjectScreenRepository _repository() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'main.dart',
      position: 0,
      canvas: _screen,
    ),
  ],
);

Future<ProviderContainer> _open() async {
  final container = ProviderContainer(
    overrides: [
      projectScreenRepositoryProvider.overrideWithValue(_repository()),
    ],
  );
  await container.read(editorSessionProvider.notifier).openProject(_project);
  return container;
}

void main() {
  test('Expanded entra dentro de una fila', () async {
    final container = await _open();
    addTearDown(container.dispose);

    await container
        .read(editorSessionProvider.notifier)
        .addComponentAt('expanded', 'row');

    final row = container.read(editorSessionProvider).root!.findNode('row')!;
    expect(row.children, hasLength(2));
    expect(row.children.last.type, 'expanded');
  });

  test('Expanded se rechaza fuera de una fila o columna', () async {
    final container = await _open();
    addTearDown(container.dispose);

    await container
        .read(editorSessionProvider.notifier)
        .addComponentAt('expanded', 'root');

    final root = container.read(editorSessionProvider).root!;
    expect(root.children, hasLength(1));
    expect(root.findNode('expanded'), isNull);
  });

  test('Expanded se inserta junto a un hijo de fila', () async {
    final container = await _open();
    addTearDown(container.dispose);

    await container
        .read(editorSessionProvider.notifier)
        .addComponentAt('expanded', 'txt');

    final row = container.read(editorSessionProvider).root!.findNode('row')!;
    expect(row.children.map((child) => child.type), ['expanded', 'text']);
  });

  test('el código de Expanded/Flexible/Spacer compila dentro de la fila', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'row',
          type: 'row',
          children: [
            CanvasNode(
              id: 'exp',
              type: 'expanded',
              properties: {'flex': 2},
              children: [CanvasNode(id: 'txt', type: 'text')],
            ),
            CanvasNode(id: 'sp', type: 'spacer'),
            CanvasNode(
              id: 'fx',
              type: 'flexible',
              properties: {'fit': 'tight'},
            ),
          ],
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('Expanded('));
    expect(code, contains('flex: 2'));
    expect(code, contains('Spacer(flex: 1)'));
    expect(code, contains('Flexible('));
    expect(code, contains('FlexFit.tight'));
  });

  testWidgets('la fila no envuelve a Expanded en otro Expanded', (tester) async {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'row',
          type: 'row',
          children: [
            CanvasNode(
              id: 'exp',
              type: 'expanded',
              children: [CanvasNode(id: 'txt', type: 'text')],
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: WidgetRenderer(node: root),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Expanded), findsWidgets);
  });
}
