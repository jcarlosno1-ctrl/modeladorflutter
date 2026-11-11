import 'package:flutter_test/flutter_test.dart';
import 'package:modeladorflutter/features/editor/codegen/dart_code_generator.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';

void main() {
  test('los widgets portados desde Flutter Studio generan código', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'stack',
          type: 'stack',
          properties: {'alignment': 'center'},
          children: [CanvasNode(id: 's1', type: 'text')],
        ),
        CanvasNode(
          id: 'wrap',
          type: 'wrap',
          properties: {'spacing': 6, 'runSpacing': 10},
          children: [CanvasNode(id: 'w1', type: 'text')],
        ),
        CanvasNode(
          id: 'align',
          type: 'align',
          properties: {'alignment': 'bottomRight'},
          children: [CanvasNode(id: 'a1', type: 'text')],
        ),
        CanvasNode(
          id: 'box',
          type: 'sizedBox',
          properties: {'width': 120, 'height': 40},
        ),
        CanvasNode(
          id: 'chip',
          type: 'chip',
          properties: {
            'label': 'Hola',
            'avatarIcon': 'person',
            'showDeleteIcon': true,
          },
        ),
        CanvasNode(
          id: 'avatar',
          type: 'avatar',
          properties: {'initials': 'AB', 'radius': 24},
        ),
        CanvasNode(
          id: 'seg',
          type: 'segmentedButton',
          properties: {
            'option1': 'A',
            'option2': 'B',
            'option3': 'C',
            'selectedIndex': '1',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('Stack('));
    expect(code, contains('Wrap('));
    expect(code, contains('Align('));
    expect(code, contains('SizedBox('));
    expect(code, contains('Chip('));
    expect(code, contains('CircleAvatar('));
    expect(code, contains('SegmentedButton<int>('));
    expect(code, contains('alignment: Alignment.center'));
    expect(code, contains('alignment: Alignment.bottomRight'));
    expect(code, contains('selected: {1}'));
    expect(code, isNot(contains('TODO: código pendiente')));
  });

  test('el lote de layout y formularios genera código', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'opacity',
          type: 'opacity',
          properties: {'opacity': 0.4},
          children: [CanvasNode(id: 'o1', type: 'text')],
        ),
        CanvasNode(
          id: 'aspect',
          type: 'aspectRatio',
          properties: {'ratio': 1.6},
          children: [CanvasNode(id: 'a1', type: 'text')],
        ),
        CanvasNode(
          id: 'visible',
          type: 'visibility',
          properties: {'isVisible': false},
          children: [CanvasNode(id: 'v1', type: 'text')],
        ),
        CanvasNode(
          id: 'safe',
          type: 'safeArea',
          children: [CanvasNode(id: 's1', type: 'text')],
        ),
        CanvasNode(id: 'vdiv', type: 'verticalDivider'),
        CanvasNode(
          id: 'radio',
          type: 'radioTile',
          properties: {'title': 'Opción A', 'selected': true},
        ),
        CanvasNode(
          id: 'dropdown',
          type: 'dropdownField',
          properties: {
            'label': 'Categoría',
            'options': 'Uno, Dos',
            'value': 'Dos',
          },
        ),
        CanvasNode(
          id: 'search',
          type: 'searchBar',
          properties: {'hint': 'Buscar algo'},
        ),
        CanvasNode(
          id: 'switch',
          type: 'switchTile',
          properties: {'title': 'Notificaciones', 'value': true},
        ),
        CanvasNode(
          id: 'iconButton',
          type: 'iconButton',
          properties: {
            'icon': 'favorite',
            'onTap': 'message',
            'eventMessage': 'Me gusta',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('Opacity('));
    expect(code, contains('AspectRatio('));
    expect(code, contains('Visibility('));
    expect(code, contains('SafeArea('));
    expect(code, contains('VerticalDivider('));
    expect(code, contains('RadioGroup<bool>('));
    expect(code, contains('DropdownButtonFormField<String>('));
    expect(code, contains('SearchBar('));
    expect(code, contains('SwitchListTile('));
    expect(code, contains('IconButton('));
    expect(code, contains("Text('Me gusta')"));
    expect(code, isNot(contains('TODO: código pendiente')));
  });

  test('el lote de visuales y listas genera código', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'tooltip',
          type: 'tooltip',
          properties: {'message': 'Ayuda'},
          children: [CanvasNode(id: 't1', type: 'text')],
        ),
        CanvasNode(
          id: 'selectable',
          type: 'selectableText',
          properties: {'text': 'Copiame', 'fontSize': 18},
        ),
        CanvasNode(
          id: 'list',
          type: 'listView',
          properties: {'gap': 6},
          children: [CanvasNode(id: 'l1', type: 'text')],
        ),
        CanvasNode(
          id: 'grid',
          type: 'gridView',
          properties: {'columns': 2, 'gap': 4},
          children: [CanvasNode(id: 'g1', type: 'text')],
        ),
        CanvasNode(
          id: 'clip',
          type: 'clipRRect',
          properties: {'radius': 20},
          children: [CanvasNode(id: 'c1', type: 'text')],
        ),
        CanvasNode(
          id: 'oval',
          type: 'clipOval',
          children: [CanvasNode(id: 'c2', type: 'text')],
        ),
        CanvasNode(
          id: 'colored',
          type: 'coloredBox',
          children: [CanvasNode(id: 'c3', type: 'text')],
        ),
        CanvasNode(
          id: 'decorated',
          type: 'decoratedBox',
          properties: {'radius': 10, 'borderWidth': 1},
          children: [CanvasNode(id: 'c4', type: 'text')],
        ),
        CanvasNode(
          id: 'offstage',
          type: 'offstage',
          properties: {'offstage': true},
          children: [CanvasNode(id: 'c5', type: 'text')],
        ),
        CanvasNode(
          id: 'badge',
          type: 'badge',
          properties: {'label': '9'},
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('Tooltip('));
    expect(code, contains('SelectableText('));
    expect(code, contains('ListView('));
    expect(code, contains('GridView.count('));
    expect(code, contains('ClipRRect('));
    expect(code, contains('ClipOval('));
    expect(code, contains('ColoredBox('));
    expect(code, contains('DecoratedBox('));
    expect(code, contains('Offstage('));
    expect(code, contains('Badge('));
    expect(code, isNot(contains('TODO: código pendiente')));
  });

  test('el lote de navegación y ajuste genera código', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'bottom',
          type: 'bottomAppBar',
          children: [
            CanvasNode(id: 'i1', type: 'icon', properties: {'icon': 'add'}),
          ],
        ),
        CanvasNode(
          id: 'expansion',
          type: 'expansionTile',
          properties: {'title': 'Detalles', 'initiallyExpanded': true},
          children: [CanvasNode(id: 'e1', type: 'text')],
        ),
        CanvasNode(
          id: 'banner',
          type: 'banner',
          properties: {'message': 'Aviso', 'actionLabel': 'Ok'},
        ),
        CanvasNode(
          id: 'toggle',
          type: 'toggleButtons',
          properties: {'option1': 'A', 'option2': 'B', 'option3': 'C'},
        ),
        CanvasNode(
          id: 'fitted',
          type: 'fittedBox',
          properties: {'fit': 'cover'},
          children: [CanvasNode(id: 'f1', type: 'text')],
        ),
        CanvasNode(
          id: 'fractional',
          type: 'fractionallySizedBox',
          children: [CanvasNode(id: 'fr1', type: 'text')],
        ),
        CanvasNode(
          id: 'constrained',
          type: 'constrainedBox',
          children: [CanvasNode(id: 'co1', type: 'text')],
        ),
        CanvasNode(
          id: 'limited',
          type: 'limitedBox',
          children: [CanvasNode(id: 'li1', type: 'text')],
        ),
        CanvasNode(
          id: 'rotated',
          type: 'rotatedBox',
          properties: {'quarterTurns': 1},
          children: [CanvasNode(id: 'ro1', type: 'text')],
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('bottomNavigationBar: BottomAppBar('));
    expect(code, contains('ExpansionTile('));
    expect(code, contains('MaterialBanner('));
    expect(code, contains('ToggleButtons('));
    expect(code, contains('FittedBox('));
    expect(code, contains('FractionallySizedBox('));
    expect(code, contains('ConstrainedBox('));
    expect(code, contains('LimitedBox('));
    expect(code, contains('RotatedBox('));
    expect(code, isNot(contains('TODO: código pendiente')));
  });

  test('las propiedades extra se exportan', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'text',
          type: 'text',
          properties: {
            'text': 'Hola',
            'fontSize': 20,
            'color': 'primary',
          },
        ),
        CanvasNode(
          id: 'container',
          type: 'container',
          properties: {
            'backgroundColor': 'low',
            'gradient': true,
            'gradientColor': 'tertiary',
          },
        ),
        CanvasNode(
          id: 'card',
          type: 'card',
          properties: {'elevation': 4},
          children: [CanvasNode(id: 'c1', type: 'text')],
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('fontSize: 20'));
    expect(
      code,
      contains('color: Theme.of(context).colorScheme.primaryContainer'),
    );
    expect(code, contains('gradient: LinearGradient('));
    expect(code, contains('elevation: 4'));
    expect(code, isNot(contains('TODO: código pendiente')));
  });

  test('el área táctil exporta la acción', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'ink',
          type: 'inkWell',
          properties: {'onTap': 'message', 'eventMessage': 'Tocado'},
          children: [CanvasNode(id: 't', type: 'text')],
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('InkWell('));
    expect(code, contains("Text('Tocado')"));
  });

  test('las propiedades P1 se exportan', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'text',
          type: 'text',
          properties: {
            'text': 'Hola',
            'fontWeight': 'bold',
            'maxLines': 2,
            'overflow': 'clip',
            'lineHeight': 1.6,
            'letterSpacing': 0.5,
            'fontStyle': 'italic',
            'decoration': 'underline',
            'semanticLabel': 'Saludo',
          },
        ),
        CanvasNode(
          id: 'image',
          type: 'image',
          properties: {
            'url': 'https://example.com/a.png',
            'width': 120,
            'fit': 'contain',
            'radius': 8,
            'opacity': 0.8,
          },
        ),
        CanvasNode(
          id: 'divider',
          type: 'divider',
          properties: {
            'height': 24,
            'color': 'primarySolid',
            'indent': 8,
            'endIndent': 8,
          },
        ),
        CanvasNode(
          id: 'card',
          type: 'card',
          properties: {
            'color': 'surface',
            'radius': 16,
            'margin': 8,
            'padding': 12,
            'borderWidth': 1,
          },
          children: [CanvasNode(id: 'c1', type: 'text')],
        ),
        CanvasNode(
          id: 'button',
          type: 'button',
          properties: {
            'label': 'Enviar',
            'backgroundColor': 'primarySolid',
            'borderRadius': 12,
            'padding': 12,
            'fontSize': 15,
            'icon': 'add',
            'fullWidth': true,
          },
        ),
        CanvasNode(
          id: 'field',
          type: 'textField',
          properties: {
            'label': 'Correo',
            'helperText': 'Tu correo',
            'keyboardType': 'email',
            'maxLines': 2,
            'prefixIcon': 'mail',
            'filled': false,
            'borderRadius': 14,
            'readOnly': true,
          },
        ),
        CanvasNode(
          id: 'tile',
          type: 'listTile',
          properties: {
            'title': 'Ajustes',
            'leadingIconColor': 'primarySolid',
            'trailingIcon': 'arrow_forward',
            'selected': true,
            'dense': true,
            'shapeRadius': 12,
            'tileColor': 'low',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('fontWeight: FontWeight.bold'));
    expect(code, contains('maxLines: 2'));
    expect(code, contains('overflow: TextOverflow.clip'));
    expect(code, contains('height: 1.6'));
    expect(code, contains('fontStyle: FontStyle.italic'));
    expect(code, contains('decoration: TextDecoration.underline'));
    expect(code, contains("semanticsLabel: 'Saludo'"));
    expect(code, contains('Image.network('));
    expect(code, contains('fit: BoxFit.contain'));
    expect(code, contains('endIndent: 8'));
    expect(code, contains('RoundedRectangleBorder'));
    expect(code, contains('Card('));
    expect(code, contains('TextInputType.emailAddress'));
    expect(code, contains('helperText:'));
    expect(code, contains("prefixIcon: const Icon(Icons.mail_outline)"));
    expect(code, contains('readOnly: true'));
    expect(code, contains('selected: true'));
    expect(code, contains('dense: true'));
    expect(code, contains('Icons.arrow_forward'));
    expect(code, isNot(contains('TODO: código pendiente')));
  });

  test('las propiedades P2 se exportan', () {
    const root = CanvasNode(
      id: 'root',
      type: 'screen',
      children: [
        CanvasNode(
          id: 'tooltip',
          type: 'tooltip',
          properties: {
            'message': 'Ayuda',
            'waitDuration': 300,
            'showDuration': 2000,
            'preferBelow': false,
            'verticalOffset': 6,
            'padding': 4,
          },
          children: [CanvasNode(id: 't1', type: 'text')],
        ),
        CanvasNode(
          id: 'progress',
          type: 'progress',
          properties: {
            'indeterminate': true,
            'color': 'primarySolid',
            'strokeWidth': 6,
            'borderRadius': 4,
          },
        ),
        CanvasNode(
          id: 'avatar',
          type: 'avatar',
          properties: {
            'initials': 'AB',
            'imageUrl': 'https://example.com/a.png',
            'borderWidth': 3,
            'borderColor': 'tertiary',
          },
        ),
        CanvasNode(
          id: 'selectable',
          type: 'selectableText',
          properties: {
            'text': 'Copia',
            'fontWeight': 'bold',
            'color': 'primarySolid',
            'maxLines': 3,
          },
        ),
        CanvasNode(
          id: 'fab',
          type: 'fab',
          properties: {
            'icon': 'save',
            'extendedLabel': 'Guardar',
            'mini': true,
            'elevation': 8,
            'tooltip': 'Guardar cambios',
          },
        ),
      ],
    );

    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: 'main.dart',
      isEntry: true,
    );

    expect(code, contains('Duration(milliseconds: 300)'));
    expect(code, contains('preferBelow: false'));
    expect(code, contains('verticalOffset: 6'));
    expect(code, contains('LinearProgressIndicator('));
    expect(code, contains('minHeight: 6'));
    expect(code, contains('borderRadius: BorderRadius.circular(4)'));
    expect(code, contains('NetworkImage('));
    expect(code, contains('fontWeight: FontWeight.bold'));
    expect(code, contains('maxLines: 3'));
    expect(code, contains('FloatingActionButton.extended('));
    expect(code, contains("label: const Text('Guardar')"));
    expect(code, isNot(contains('TODO: código pendiente')));
  });
}
