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

const _root = CanvasNode(
  id: 'root',
  type: 'column',
  properties: {'gap': 8},
  children: [
    CanvasNode(id: 't1', type: 'text', properties: {'text': 'Hola'}),
    CanvasNode(id: 'b1', type: 'button', properties: {'label': 'Continuar'}),
  ],
);

FakeProjectScreenRepository _repository() => FakeProjectScreenRepository(
  screens: [
    ProjectScreen(
      id: 's-1',
      projectId: _project.id,
      name: 'Pantalla 1',
      position: 0,
      canvas: _root,
    ),
  ],
);

/// Monta el editor en modo expandido (panel de propiedades visible).
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
  testWidgets('tocar un componente lo selecciona y muestra sus propiedades', (
    tester,
  ) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.text('Hola'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(EditorKeys.propertiesTitle), findsOneWidget);
    expect(find.byKey(EditorKeys.propertyField('text')), findsOneWidget);
    expect(find.byKey(EditorKeys.propertyField('style')), findsOneWidget);
  });

  testWidgets('editar el texto actualiza el lienzo y se guarda', (
    tester,
  ) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.text('Hola'), warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(EditorKeys.propertyField('text')),
      'Título nuevo',
    );
    await tester.pump();
    expect(find.text('Título nuevo'), findsWidgets);

    // Debounce de 500 ms antes de persistir.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(repository.saveCalls, greaterThanOrEqualTo(1));
    expect(
      repository.lastSaved!.children.first.properties['text'],
      'Título nuevo',
    );
  });

  testWidgets('cambiar un booleano se refleja y se persiste', (tester) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('b1')));
    await tester.pumpAndSettle();
    expect(find.byKey(EditorKeys.propertiesTitle), findsOneWidget);

    await tester.tap(find.byKey(EditorKeys.propertyField('enabled')));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final button = repository.lastSaved!.children[1];
    expect(button.properties['enabled'], isFalse);
  });

  testWidgets('un botón del lienzo se selecciona al tocarlo', (tester) async {
    await _pumpEditor(tester, _repository());

    // El botón no debe consumir el toque: el editor lo absorbe para
    // seleccionar en lugar de ejecutar su acción. `warnIfMissed` se desactiva
    // porque justamente el texto interno ya no recibe el hit test.
    await tester.tap(find.text('Continuar'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byKey(EditorKeys.propertiesTitle), findsOneWidget);
    expect(find.byKey(EditorKeys.propertyField('label')), findsOneWidget);
  });

  testWidgets('cambiar una opción del desplegable se persiste', (tester) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('t1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EditorKeys.propertyField('style')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Título').last);
    await tester.pumpAndSettle();

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(
      repository.lastSaved!.children.first.properties['style'],
      'title',
    );
  });

  testWidgets('un valor inválido no modifica el árbol', (tester) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.text('Hola'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // El máximo es 120: se escribe más y no debe persistirse.
    await tester.enterText(
      find.byKey(EditorKeys.propertyField('text')),
      'x' * 200,
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    final text = repository.lastSaved?.children.first.properties['text'];
    expect(text, isNot('x' * 200));
  });

  testWidgets('eliminar el nodo seleccionado lo quita y persiste', (
    tester,
  ) async {
    final repository = _repository();
    await _pumpEditor(tester, repository);

    await tester.tap(find.byKey(EditorKeys.nodeTile('t1')));
    await tester.pumpAndSettle();
    expect(find.byKey(EditorKeys.propertiesTitle), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(EditorKeys.deleteNode),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(EditorKeys.propertiesList),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(EditorKeys.deleteNode));
    await tester.pumpAndSettle();

    expect(find.text('Hola'), findsNothing);
    expect(find.text('Sin selección'), findsOneWidget);
    expect(
      repository.lastSaved!.children.map((child) => child.type).toList(),
      ['button'],
    );
  });

  testWidgets('el artboard mantiene tamaño fijo y hace scroll interno', (
    tester,
  ) async {
    final children = List<CanvasNode>.generate(
      40,
      (index) => CanvasNode(
        id: 't$index',
        type: 'text',
        properties: {'text': 'Texto $index'},
      ),
    );
    await _pumpEditor(
      tester,
      FakeProjectScreenRepository(
        screens: [
          ProjectScreen(
            id: 's-1',
            projectId: _project.id,
            name: 'Pantalla 1',
            position: 0,
            canvas: CanvasNode(id: 'root', type: 'column', children: children),
          ),
        ],
      ),
    );

    final canvas = find.byKey(EditorKeys.canvas);
    expect(tester.getSize(canvas).height, 844);

    final scrollable = find.descendant(
      of: canvas,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('tocar el fondo deselecciona', (tester) async {
    await _pumpEditor(tester, _repository());

    await tester.tap(find.text('Hola'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byKey(EditorKeys.propertiesTitle), findsOneWidget);

    // Toca la zona gris fuera del artboard (el fondo del lienzo).
    final rect = tester.getRect(find.byKey(EditorKeys.canvas));
    await tester.tapAt(Offset(rect.left - 40, rect.center.dy));
    await tester.pumpAndSettle();

    expect(find.text('Sin selección'), findsOneWidget);
    expect(find.byKey(EditorKeys.propertiesTitle), findsNothing);
  });
}
