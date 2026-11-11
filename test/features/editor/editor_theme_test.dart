import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
import 'package:modeladorflutter/features/editor/presentation/editor_screen.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../../helpers/fake_project_repository.dart';
import '../../helpers/fake_project_screen_repository.dart';

final _project = Project(
  id: 'p-1',
  name: 'Mi app',
  createdAt: DateTime.utc(2026, 11, 7),
);

FakeProjectScreenRepository _screens() => FakeProjectScreenRepository(
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
  WidgetTester tester, {
  required FakeProjectRepository projects,
  required FakeProjectScreenRepository screens,
}) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        projectRepositoryProvider.overrideWithValue(projects),
        projectScreenRepositoryProvider.overrideWithValue(screens),
      ],
      child: MaterialApp(home: EditorScreen(project: _project)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guardar el tema lo persiste y se refleja en el código', (
    tester,
  ) async {
    final projects = FakeProjectRepository(initial: [_project]);
    await _pumpEditor(
      tester,
      projects: projects,
      screens: _screens(),
    );

    await tester.tap(find.byKey(EditorKeys.theme));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(EditorKeys.themeHex('primary')),
      '#112233',
    );
    await tester.tap(find.byKey(EditorKeys.themeSave));
    await tester.pumpAndSettle();

    expect(projects.saveThemeCalls, 1);
    expect(projects.lastTheme!.primary, '#112233');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    expect(container.read(editorSessionProvider).theme.primary, '#112233');

    await tester.tap(find.text('Código'));
    await tester.pumpAndSettle();

    final view = tester.widget<SelectableText>(
      find.byKey(EditorKeys.codeView),
    );
    final code = view.textSpan?.toPlainText() ?? view.data ?? '';
    expect(code, contains('seedColor: const Color(0xFF112233)'));
  });
}
