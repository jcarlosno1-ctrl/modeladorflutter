import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modeladorflutter/app/main_layout.dart';

/// Viewports usados por los escenarios de `layout_responsivo.feature`.
const Size _desktop = Size(1400, 900);
const Size _tablet = Size(800, 900);
const Size _mobile = Size(400, 800);

/// Monta [MainLayout] con un ancho lógico exacto.
///
/// `devicePixelRatio = 1.0` evita que el tamaño físico se divida y hace que
/// los umbrales (600 / 1024) se comparen contra píxeles lógicos predecibles.
Future<void> pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(const MaterialApp(home: MainLayout()));
  await tester.pump();
}

void main() {
  group('expandido (>1024)', () {
    testWidgets('muestra herramientas y propiedades fijos', (tester) async {
      await pumpAt(tester, _desktop);

      expect(find.byKey(MainLayoutKeys.toolsPanel), findsOneWidget);
      expect(find.byKey(MainLayoutKeys.propertiesPanel), findsOneWidget);
    });
  });

  group('medio (600–1024)', () {
    testWidgets('herramientas fijas y propiedades bajo EndDrawer', (
      tester,
    ) async {
      await pumpAt(tester, _tablet);

      expect(find.byKey(MainLayoutKeys.toolsPanel), findsOneWidget);
      expect(find.byKey(MainLayoutKeys.propertiesPanel), findsNothing);

      await tester.tap(find.byKey(MainLayoutKeys.openPropertiesButton));
      await tester.pumpAndSettle();

      expect(find.byKey(MainLayoutKeys.propertiesPanel), findsOneWidget);
    });
  });

  group('compacto (<600)', () {
    testWidgets('ambos paneles colapsados en cajones', (tester) async {
      await pumpAt(tester, _mobile);

      expect(find.byKey(MainLayoutKeys.toolsPanel), findsNothing);
      expect(find.byKey(MainLayoutKeys.propertiesPanel), findsNothing);

      await tester.tap(find.byKey(MainLayoutKeys.openToolsButton));
      await tester.pumpAndSettle();
      expect(find.byKey(MainLayoutKeys.toolsPanel), findsOneWidget);

      tester.state<ScaffoldState>(find.byType(Scaffold).first).closeDrawer();
      await tester.pumpAndSettle();
      expect(find.byKey(MainLayoutKeys.toolsPanel), findsNothing);

      await tester.tap(find.byKey(MainLayoutKeys.openPropertiesButton));
      await tester.pumpAndSettle();
      expect(find.byKey(MainLayoutKeys.propertiesPanel), findsOneWidget);
    });
  });

  group('umbrales', () {
    testWidgets('1024 sigue en modo medio', (tester) async {
      await pumpAt(tester, const Size(1024, 900));

      expect(find.byKey(MainLayoutKeys.toolsPanel), findsOneWidget);
      expect(find.byKey(MainLayoutKeys.propertiesPanel), findsNothing);
    });

    testWidgets('1025 entra en modo expandido', (tester) async {
      await pumpAt(tester, const Size(1025, 900));

      expect(find.byKey(MainLayoutKeys.propertiesPanel), findsOneWidget);
    });

    testWidgets('599 sigue en modo compacto', (tester) async {
      await pumpAt(tester, const Size(599, 900));

      expect(find.byKey(MainLayoutKeys.toolsPanel), findsNothing);
    });

    testWidgets('600 entra en modo medio', (tester) async {
      await pumpAt(tester, const Size(600, 900));

      expect(find.byKey(MainLayoutKeys.toolsPanel), findsOneWidget);
    });
  });

  group('paneles redimensionables', () {
    testWidgets('arrastrar los divisores cambia el ancho', (tester) async {
      await pumpAt(tester, _desktop);

      final tools = find.byKey(MainLayoutKeys.toolsPanel);
      final toolsBefore = tester.getSize(tools).width;

      await tester.drag(
        find.byKey(MainLayoutKeys.toolsResize),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(tools).width, greaterThan(toolsBefore));

      final properties = find.byKey(MainLayoutKeys.propertiesPanel);
      final propertiesBefore = tester.getSize(properties).width;

      await tester.drag(
        find.byKey(MainLayoutKeys.propertiesResize),
        const Offset(-50, 0),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(properties).width,
        greaterThan(propertiesBefore),
      );
    });
  });
}
