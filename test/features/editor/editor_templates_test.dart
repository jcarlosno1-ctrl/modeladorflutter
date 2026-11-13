import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/application/editor_session.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
import 'package:modeladorflutter/features/editor/presentation/editor_screen.dart';
import 'package:modeladorflutter/features/editor/templates/screen_templates.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../../helpers/fake_project_screen_repository.dart';

final _project = Project(
  id: 'p-1',
  name: 'Mi app',
  createdAt: DateTime.utc(2026, 11, 7),
);

const _screen = CanvasNode(id: 'root', type: 'screen');

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

void main() {
  test('crear desde plantilla agrega la pantalla y la selecciona', () async {
    final container = ProviderContainer(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(_repository()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorSessionProvider.notifier);
    await notifier.openProject(_project);
    final template = screenTemplates.firstWhere(
      (item) => item.id == 'login',
    );
    await notifier.createScreenFromTemplate(
      name: template.fileName,
      root: template.canvas,
    );

    final state = container.read(editorSessionProvider);
    expect(state.screens, hasLength(2));
    expect(state.screenName, 'login.dart');
    expect(state.root!.findNode('login_title'), isNotNull);
  });

  test('la pantalla inicial se mueve al primer lugar y se mantiene', () async {
    final repository = FakeProjectScreenRepository(
      screens: const [
        ProjectScreen(
          id: 's1',
          projectId: 'p-1',
          name: 'main.dart',
          position: 0,
          canvas: CanvasNode(id: 'root1', type: 'screen'),
        ),
        ProjectScreen(
          id: 's2',
          projectId: 'p-1',
          name: 'splash.dart',
          position: 1,
          canvas: CanvasNode(id: 'root2', type: 'screen'),
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(editorSessionProvider.notifier);
    await notifier.openProject(_project);
    await notifier.selectScreen('s2');
    await notifier.setInitialScreen('s2', true);

    var state = container.read(editorSessionProvider);
    expect(state.screens.first.id, 's2');

    final reloaded = ProviderContainer(
      overrides: [
        projectScreenRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(reloaded.dispose);
    await reloaded.read(editorSessionProvider.notifier).openProject(_project);
    state = reloaded.read(editorSessionProvider);
    expect(state.screens.first.id, 's2');
    expect(state.screens.first.canvas!.properties['initial'], true);
  });

  testWidgets('la galería de plantillas crea una pantalla', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectScreenRepositoryProvider.overrideWithValue(_repository()),
        ],
        child: MaterialApp(home: EditorScreen(project: _project)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EditorKeys.templates));
    await tester.pumpAndSettle();

    expect(find.text('Plantillas'), findsOneWidget);
    expect(find.text('Splash Screen'), findsOneWidget);

    await tester.tap(find.byKey(EditorKeys.template('login')));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(EditorScreen)),
    );
    expect(container.read(editorSessionProvider).screenName, 'login.dart');
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
