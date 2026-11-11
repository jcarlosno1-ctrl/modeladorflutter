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

String _codeOf(WidgetTester tester) {
  final view = tester.widget<SelectableText>(find.byKey(EditorKeys.codeView));
  return view.textSpan?.toPlainText() ?? view.data ?? '';
}

void main() {
  testWidgets('el color elegido en la paleta aparece en el código', (
    tester,
  ) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.nodeTile('root')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EditorKeys.colorPalette('background')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(EditorKeys.dialogHex), '#112233');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(EditorKeys.applyColor));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    expect(_codeOf(tester), contains('backgroundColor: const Color(0xFF112233)'));
  });

  testWidgets('el hex escrito aparece en el código', (tester) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.nodeTile('root')));
    await tester.pumpAndSettle();

    final field = find.byKey(EditorKeys.propertyField('background.hex'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '#123456');
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    expect(_codeOf(tester), contains('backgroundColor: const Color(0xFF123456)'));
  });

  testWidgets('el código se actualiza en vivo mientras editás el color', (
    tester,
  ) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.byKey(EditorKeys.nodeTile('root')));
    await tester.pumpAndSettle();

    // Primero abrimos Código y luego cambiamos el color.
    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();
    expect(_codeOf(tester), isNot(contains('backgroundColor:')));

    final field = find.byKey(EditorKeys.propertyField('background.hex'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '#0F766E');
    await tester.pump(const Duration(milliseconds: 700));

    expect(_codeOf(tester), contains('backgroundColor: const Color(0xFF0F766E)'));
  });
}
