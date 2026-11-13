import '../catalog/color_value.dart';
import '../catalog/standard_catalog.dart';
import '../catalog/widget_definition.dart';
import '../../projects/domain/project_theme.dart';
import '../domain/canvas_node.dart';

/// Genera código Dart exportable a partir del árbol del lienzo.
///
/// Solo cubre el catálogo actual; lo que no sabe generar queda marcado con un
/// `TODO` explícito en vez de inventar código.
abstract final class DartCodeGenerator {
  /// Ruta del archivo según la posición de la pantalla.
  ///
  /// La primera es el entrypoint (`lib/main.dart`); las demás viven en
  /// `lib/screens/` con el nombre de la pestaña.
  static String pathFor({required String fileName, required bool isEntry}) {
    if (isEntry) {
      return 'lib/main.dart';
    }
    return 'lib/screens/${_baseName(fileName)}.dart';
  }

  /// Nombre de la clase del widget.
  static String classNameFor({required String fileName, required bool isEntry}) {
    if (isEntry) {
      return 'MyApp';
    }
    return '${_pascalCase(_baseName(fileName))}Screen';
  }

  /// Código completo de una pantalla.
  static String generate({
    required CanvasNode screen,
    required String fileName,
    required bool isEntry,
    ProjectTheme theme = const ProjectTheme(),
    Map<String, ({String className, String path})> routes = const {},
    String? initialRoute,
  }) {
    final scaffold = _scaffold(screen);
    final className = classNameFor(fileName: fileName, isEntry: isEntry);
    final themeCode = isEntry ? _themeData(theme) : null;
    final homeCode = isEntry
        ? 'Builder(\n'
              '  builder: (context) => ${_inline('', scaffold, '  ')},\n'
              ')'
        : scaffold;
    final routeEntries = <String>[
      if (isEntry)
        for (final route in routes.entries)
          if (route.value.className != className)
            "        '/screen/${route.key}': (context) => "
                'const ${route.value.className}(),',
    ];
    final routeImports = <String>[
      if (isEntry)
        for (final route in routes.values)
          if (route.className != className)
            "import '${_relativeImport('lib/main.dart', route.path)}';",
    ];

    final build = isEntry
        ? '  @override\n'
              '  Widget build(BuildContext context) {\n'
              '    return MaterialApp(\n'
              '${themeCode == null ? '' : '      theme: ${_inline('', themeCode, '      ')},\n'}'
              '${routeEntries.isEmpty ? '' : '      routes: {\n${routeEntries.join('\n')}\n      },\n'}'
              '${initialRoute == null ? '' : "      initialRoute: '$initialRoute',\n"}'
              '      ${_inline('home: ', homeCode, '      ')},\n'
              '    );\n'
              '  }\n'
        : '  @override\n'
              '  Widget build(BuildContext context) {\n'
              '    ${_inline('return ', scaffold, '    ')};\n'
              '  }\n';

    return "import 'package:flutter/material.dart';\n"
        '${routeImports.isEmpty ? '' : '\n${routeImports.join('\n')}\n'}\n'
        "${isEntry ? 'void main() {\n  runApp(const $className());\n}\n\n' : ''}"
        'class $className extends StatelessWidget {\n'
        '  const $className({super.key});\n\n'
        '$build'
        '}\n';
  }

  /// Ruta relativa entre dos archivos `lib/...`.
  static String _relativeImport(String from, String to) {
    final fromParts = from.split('/');
    final toParts = to.split('/');
    var same = 0;
    while (same < fromParts.length - 1 &&
        same < toParts.length - 1 &&
        fromParts[same] == toParts[same]) {
      same++;
    }
    final ups = (fromParts.length - 1) - same;
    return [
      for (var index = 0; index < ups; index++) '..',
      ...toParts.sublist(same),
    ].join('/');
  }

  /// `ThemeData` del proyecto, o `null` si se usa el tema por defecto.
  static String? _themeData(ProjectTheme theme) {
    if (theme.isDefault) {
      return null;
    }

    final lines = <String>[
      'ThemeData(',
      '  useMaterial3: true,',
      '  colorScheme: ColorScheme.fromSeed(',
      '    seedColor: const Color(0xFF${_hexDigits(theme.primary)}),',
      '  ).copyWith(',
      '    primary: const Color(0xFF${_hexDigits(theme.primary)}),',
      '    secondary: const Color(0xFF${_hexDigits(theme.secondary)}),',
      '    tertiary: const Color(0xFF${_hexDigits(theme.tertiary)}),',
      '  ),',
    ];

    final appBarArgs = <String>[
      if (theme.appBarBackground.isNotEmpty)
        'backgroundColor: const Color(0xFF${_hexDigits(theme.appBarBackground)}),',
      if (theme.appBarForeground.isNotEmpty)
        'foregroundColor: const Color(0xFF${_hexDigits(theme.appBarForeground)}),',
      'titleTextStyle: TextStyle(fontSize: ${_number(theme.appBarTitleSize)}),',
    ];
    lines.add(
      '  appBarTheme: AppBarTheme(\n'
      '${appBarArgs.map((arg) => '    $arg').join('\n')}\n'
      '  ),',
    );

    lines.add(
      '  textTheme: TextTheme(\n'
      '    bodyMedium: TextStyle(fontSize: ${_number(theme.bodySize)}),\n'
      '    bodyLarge: TextStyle(fontSize: ${_number(theme.inputSize)}),\n'
      '    titleLarge: TextStyle(fontSize: ${_number(theme.titleSize)}),\n'
      '    labelLarge: TextStyle(fontSize: ${_number(theme.labelSize)}),\n'
      '  ),',
    );

    if (theme.dividerColor.isNotEmpty) {
      lines.add(
        '  dividerTheme: DividerThemeData('
        'color: const Color(0xFF${_hexDigits(theme.dividerColor)})),',
      );
    }

    lines.add(
      '  filledButtonTheme: FilledButtonThemeData(\n'
      '    style: FilledButton.styleFrom(\n'
      '      shape: RoundedRectangleBorder(\n'
      '        borderRadius: BorderRadius.circular(${_number(theme.buttonRadius)}),\n'
      '      ),\n'
      '    ),\n'
      '  ),',
    );
    lines.add(')');
    return lines.join('\n');
  }

  static String _hexDigits(String value) =>
      value.replaceFirst('#', '').toUpperCase();

  /// Une un prefijo con un bloque multilínea, indentando sus continuaciones.
  static String _inline(String prefix, String code, String continuationIndent) {
    final lines = code.split('\n');
    final buffer = StringBuffer('$prefix${lines.first}');
    for (final line in lines.skip(1)) {
      buffer.write('\n');
      if (line.isNotEmpty) {
        buffer.write(continuationIndent);
      }
      buffer.write(line);
    }
    return buffer.toString();
  }

  /// Bloque `Scaffold(...)` con los slots de la pantalla.
  static String _withNote(CanvasNode? node, String code) {
    final label = node == null ? null : standardCatalog[node.type]?.label;
    if (label == null || label.isEmpty) {
      return code;
    }
    // Comentarios de bloque: la coma del argumento queda fuera del comentario.
    return '/* inicio de $label */\n$code\n/* fin de $label */';
  }

  static String _scaffold(CanvasNode screen) {
    final catalog = standardCatalog;
    final definition = catalog['screen']!;
    final values = <String, Object?>{
      for (final spec in definition.properties)
        spec.key: spec.coerce(screen.properties[spec.key]),
    };

    CanvasNode? top;
    CanvasNode? bottom;
    CanvasNode? drawer;
    CanvasNode? endDrawer;
    CanvasNode? fab;
    final body = <CanvasNode>[];

    for (final child in screen.children) {
      if (child.properties['visible'] == false) {
        continue;
      }
      switch (catalog[child.type]?.slot ?? ComponentSlot.body) {
        case ComponentSlot.top:
          top ??= child;
        case ComponentSlot.bottom:
          bottom ??= child;
        case ComponentSlot.overlay:
          drawer ??= child;
        case ComponentSlot.drawerEnd:
          endDrawer ??= child;
        case ComponentSlot.fab:
          fab ??= child;
        case ComponentSlot.body:
          body.add(child);
      }
    }

    final hideOnScroll =
        top != null && top.properties['hideOnScroll'] == true;

    final args = <String>[];
    if (top != null && !hideOnScroll) {
      args.add(_withNote(top, 'appBar: ${_widgetInline(top)}'));
    }

    final bodyCode = body.isEmpty
        ? _emptyStateCode
        : _bodyCode(body, gap: values['gap'], padding: values['padding']);

    // Diseño no adaptable: centra el contenido con un ancho máximo.
    final responsive = screen.properties['responsive'] != false;
    final contentWidth =
        (screen.properties['contentWidth'] as num?)?.toDouble() ?? 480;
    final wrappedBody = responsive
        ? bodyCode
        : 'Center(\n'
              '  child: ConstrainedBox(\n'
              '    constraints: const BoxConstraints('
              'maxWidth: ${_number(contentWidth)}),\n'
              '    child: ${_inline('', bodyCode, '    ')},\n'
              '  ),\n'
              ')';

    if (hideOnScroll) {
      final sliver = _appBarWidget(
        'SliverAppBar',
        _appBarArgs(top),
        extra: const ['floating: true', 'snap: true'],
      );
      args.add(
        'body: NestedScrollView(\n'
        '  headerSliverBuilder: (context, innerBoxIsScrolled) {\n'
        '    return [\n'
        '      ${_inline('', sliver, '      ')},\n'
        '    ];\n'
        '  },\n'
        '  body: SingleChildScrollView(\n'
        '    child: ${_inline('', wrappedBody, '    ')},\n'
        '  ),\n'
        ')',
      );
    } else {
      args.add('body: $wrappedBody');
    }

    if (bottom != null) {
      args.add(
        _withNote(bottom, 'bottomNavigationBar: ${_widgetInline(bottom)}'),
      );
    }
    if (fab != null) {
      args.add(
        _withNote(fab, 'floatingActionButton: ${_widgetInline(fab)}'),
      );
    }
    if (drawer != null) {
      args.add(_withNote(drawer, 'drawer: ${_widgetInline(drawer)}'));
    }
    if (endDrawer != null) {
      args.add(_withNote(endDrawer, 'endDrawer: ${_widgetInline(endDrawer)}'));
    }

    if (values['background'] != null) {
      final background = colorExpressionFor(values['background'] as String?);
      if (background != null) {
        args.add('backgroundColor: $background');
      }
    }
    if (values['resizeToAvoidBottomInset'] == false) {
      args.add('resizeToAvoidBottomInset: false');
    }

    final buffer = StringBuffer('Scaffold(\n  /* inicio de Scaffold */');
    for (final arg in args) {
      buffer.write('\n${_indent('$arg,', '  ')}');
    }
    buffer.write('\n  /* fin de Scaffold */\n)');
    return buffer.toString();
  }

  /// Código de un componente (sin indentación inicial).
  static String _widgetInline(CanvasNode node) => _widgetRaw(node);

  static String _widget(CanvasNode node) {
    final raw = _widgetRaw(node);
    final definition = standardCatalog[node.type];
    if (definition == null || node.type == 'screen') {
      return raw;
    }
    return '// inicio de ${definition.label}\n$raw\n// fin de ${definition.label}';
  }

  /// Notas con comentarios de bloque (válidas dentro de expresiones).
  static String _widgetBlock(CanvasNode node) {
    final raw = _widgetRaw(node);
    final definition = standardCatalog[node.type];
    if (definition == null || node.type == 'screen') {
      return raw;
    }
    return '/* inicio de ${definition.label} */\n'
        '$raw\n'
        '/* fin de ${definition.label} */';
  }

  static String _widgetRaw(CanvasNode node) {
    final definition = standardCatalog[node.type];
    if (definition == null) {
      return '// TODO: componente desconocido (${node.type})\nPlaceholder()';
    }
    final props = <String, Object?>{
      for (final spec in definition.properties)
        spec.key: spec.coerce(node.properties[spec.key]),
    };
    final children = node.children.map(_widget).toList();

    switch (node.type) {
      case 'text':
        final args = <String>["'${_escape(props['text'] as String? ?? '')}'"];
        final align = props['align'] as String?;
        if (align == 'center') {
          args.add('textAlign: TextAlign.center');
        } else if (align == 'right') {
          args.add('textAlign: TextAlign.right');
        }
        final style = props['style'] as String?;
        String? baseStyle;
        if (style == 'title') {
          baseStyle = 'Theme.of(context).textTheme.titleLarge';
        } else if (style == 'headline') {
          baseStyle = 'Theme.of(context).textTheme.headlineSmall';
        }
        final fontSize = (props['fontSize'] as num?)?.toDouble() ?? 0;
        final color = colorExpressionFor(props['color'] as String?);
        final weight = switch (props['fontWeight']) {
          'normal' => 'FontWeight.w400',
          'w500' => 'FontWeight.w500',
          'w600' => 'FontWeight.w600',
          'bold' => 'FontWeight.bold',
          'w800' => 'FontWeight.w800',
          _ => null,
        };
        final height = (props['lineHeight'] as num?)?.toDouble() ?? 0;
        final letter = (props['letterSpacing'] as num?)?.toDouble() ?? 0;
        final fontStyle = switch (props['fontStyle']) {
          'italic' => 'FontStyle.italic',
          'normal' => 'FontStyle.normal',
          _ => null,
        };
        final decoration = switch (props['decoration']) {
          'underline' => 'TextDecoration.underline',
          'lineThrough' => 'TextDecoration.lineThrough',
          'overline' => 'TextDecoration.overline',
          _ => null,
        };
        final overrides = <String>[
          if (fontSize > 0) 'fontSize: ${_number(fontSize)}',
          if (color != null && props['color'] != 'onSurface') 'color: $color',
          if (weight != null) 'fontWeight: $weight',
          if (height > 0) 'height: ${_number(height)}',
          if (letter != 0) 'letterSpacing: ${_number(letter)}',
          if (fontStyle != null) 'fontStyle: $fontStyle',
          if (decoration != null) 'decoration: $decoration',
        ];
        if (overrides.isNotEmpty) {
          args.add(
            'style: ${baseStyle ?? 'const TextStyle()'}.copyWith(${overrides.join(', ')})',
          );
        }
        final maxLines = (props['maxLines'] as num?)?.toInt() ?? 0;
        if (maxLines > 0) {
          args.add('maxLines: $maxLines');
        }
        final overflow = props['overflow'] as String?;
        if (maxLines > 0 && overflow != null && overflow != 'ellipsis') {
          final value = switch (overflow) {
            'clip' => 'TextOverflow.clip',
            'fade' => 'TextOverflow.fade',
            'visible' => 'TextOverflow.visible',
            _ => 'TextOverflow.ellipsis',
          };
          args.add('overflow: $value');
        }
        final semantic = props['semanticLabel'] as String? ?? '';
        if (semantic.isNotEmpty) {
          args.add("semanticsLabel: '${_escape(semantic)}'");
        }
        return 'Text(${args.join(', ')})';

      case 'button':
        final label = _escape(props['label'] as String? ?? '');
        final event = _eventBody(
          props['onTap'] as String?,
          props['eventMessage'] as String? ?? '',
          targetScreen: props['targetScreen'] as String?,
        );
        final callback = props['enabled'] == false
            ? 'null'
            : event == null
            ? '() {}'
            : '() {\n    $event\n  }';
        final widget = switch (props['variant']) {
          'outlined' => 'OutlinedButton',
          'text' => 'TextButton',
          _ => 'FilledButton',
        };
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final foreground = colorExpressionFor(
          props['foregroundColor'] as String?,
        );
        final radius = (props['borderRadius'] as num?)?.toDouble() ?? 0;
        final padding = (props['padding'] as num?)?.toDouble() ?? 0;
        final fontSize = (props['fontSize'] as num?)?.toDouble() ?? 0;
        final icon = props['icon'] as String? ?? '';
        final styles = <String>[
          if (background != null) 'backgroundColor: $background',
          if (foreground != null) 'foregroundColor: $foreground',
          if (radius > 0)
            'shape: RoundedRectangleBorder('
                'borderRadius: BorderRadius.circular(${_number(radius)}))',
          if (padding > 0)
            'padding: const EdgeInsets.all(${_number(padding)})',
          if (fontSize > 0)
            'textStyle: const TextStyle(fontSize: ${_number(fontSize)})',
        ];
        final child = icon.isEmpty
            ? "Text('$label')"
            : 'Row(\n'
                  '  mainAxisSize: MainAxisSize.min,\n'
                  '  children: [\n'
                  '    const Icon(${_iconName(icon)}, size: 18),\n'
                  '    const SizedBox(width: 8),\n'
                  "    Text('$label'),\n"
                  '  ],\n'
                  ')';
        final styleArg = styles.isEmpty
            ? ''
            : 'style: $widget.styleFrom(${styles.join(', ')}), ';
        final button =
            '$widget(onPressed: $callback, ${styleArg}child: $child)';
        return props['fullWidth'] == true
            ? 'SizedBox(width: double.infinity, child: $button)'
            : button;

      case 'icon':
        final size = (props['size'] as num?)?.toDouble() ?? 24;
        final color = switch (props['color'] as String?) {
          'onSurface' => 'Theme.of(context).colorScheme.onSurface',
          'onSurfaceVariant' =>
            'Theme.of(context).colorScheme.onSurfaceVariant',
          'primarySolid' => 'Theme.of(context).colorScheme.primary',
          'onPrimary' => 'Theme.of(context).colorScheme.onPrimary',
          'inherit' => null,
          _ => colorExpressionFor(props['color'] as String?),
        };
        final colorArg = color == null ? '' : ', color: $color';
        final fill = (props['fill'] as num?)?.toDouble() ?? 0;
        final semantic = _escape(props['semanticLabel'] as String? ?? '');
        final shadow = props['shadow'] == true;
        final shadowColor =
            colorExpressionFor(props['shadowColor'] as String?) ??
            'Theme.of(context).colorScheme.onSurface';
        final extras = <String>[
          if (fill > 0) 'fill: ${_number(fill)}',
          if (props['textDirection'] == 'rtl')
            'textDirection: TextDirection.rtl',
          if (semantic.isNotEmpty) "semanticLabel: '$semantic'",
          if (shadow)
            'shadows: [BoxShadow(color: $shadowColor, '
                'blurRadius: ${_number((props['shadowBlur'] as num?)?.toDouble() ?? 8)}, '
                'offset: Offset(${_number((props['shadowOffsetX'] as num?)?.toDouble() ?? 4)}, '
                '${_number((props['shadowOffsetY'] as num?)?.toDouble() ?? 4)}))]',
        ];
        final extraArg = extras.isEmpty ? '' : ', ${extras.join(', ')}';
        return 'Icon(${_iconName(props['icon'] as String?)}, '
            'size: ${_number(size)}$colorArg$extraArg)';

      case 'divider':
        return 'Divider('
            'thickness: ${_number((props['thickness'] as num?)?.toDouble() ?? 1)}, '
            'height: ${_number((props['height'] as num?)?.toDouble() ?? 16)}, '
            '${colorExpressionFor(props['color'] as String?) == null ? '' : 'color: ${colorExpressionFor(props['color'] as String?)}, '}'
            'indent: ${_number((props['indent'] as num?)?.toDouble() ?? 0)}, '
            'endIndent: ${_number((props['endIndent'] as num?)?.toDouble() ?? 0)})';

      case 'column':
        return _flexBox(
          'Column',
          children,
          gap: props['gap'] as num?,
          mainAxisAlignment: props['align'] as String?,
          crossAxisAlignment: props['crossAlign'] as String?,
        );

      case 'row':
        return _flexBox(
          'Row',
          children,
          gap: props['gap'] as num?,
          mainAxisAlignment: props['align'] as String?,
          crossAxisAlignment: props['crossAlign'] as String?,
        );

      case 'container':
        final radius = (props['radius'] as num?)?.toDouble() ?? 0;
        final padding = (props['padding'] as num?)?.toDouble() ?? 0;
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final gradient = props['gradient'] == true;
        final gradientEnd =
            colorExpressionFor(props['gradientColor'] as String?) ??
            'Theme.of(context).colorScheme.secondaryContainer';
        final decoration = <String>[
          if (radius > 0)
            '    borderRadius: BorderRadius.circular(${_number(radius)}),',
          if (!gradient && background != null) '    color: $background,',
          if (gradient)
            '    gradient: LinearGradient(\n'
                '      colors: [\n'
                '        ${background ?? 'Theme.of(context).colorScheme.surfaceContainerLow'},\n'
                '        $gradientEnd,\n'
                '      ],\n'
                '    ),',
        ];
        final decor = decoration.isEmpty
            ? ''
            : '\n  decoration: BoxDecoration(\n'
                  '${decoration.join('\n')}\n'
                  '  ),';
        return 'Container(\n'
            '  padding: EdgeInsets.all(${_number(padding)}),$decor\n'
            '${children.isEmpty ? '' : '  child: ${_inline('', children.first, '    ')},\n'}'
            ')';

      case 'center':
        final width = (props['widthFactor'] as num?)?.toDouble() ?? 0;
        final height = (props['heightFactor'] as num?)?.toDouble() ?? 0;
        final centerChild = children.isEmpty
            ? 'const SizedBox.shrink()'
            : _inline('', children.first, '  ');
        return 'Center(\n'
            '${width == 0 ? '' : '  widthFactor: ${_number(width)},\n'}'
            '${height == 0 ? '' : '  heightFactor: ${_number(height)},\n'}'
            '  child: $centerChild,\n'
            ')';

      case 'padding':
        final padding = (props['padding'] as num?)?.toDouble() ?? 0;
        return 'Padding(\n'
            '  padding: EdgeInsets.all(${_number(padding)}),\n'
            '${children.isEmpty ? '' : '  child: ${_inline('', children.first, '    ')},\n'}'
            ')';

      case 'card':
        final elevation =
            (props['elevation'] as num?)?.toDouble() ?? 0;
        final radius = (props['radius'] as num?)?.toDouble() ?? 12;
        final margin = (props['margin'] as num?)?.toDouble() ?? 4;
        final padding = (props['padding'] as num?)?.toDouble() ?? 8;
        final borderWidth = (props['borderWidth'] as num?)?.toDouble() ?? 0;
        final color = colorExpressionFor(props['color'] as String?);
        final borderColor = colorExpressionFor(
          props['borderColor'] as String?,
        );
        final args = <String>[
          'elevation: ${_number(elevation)}',
          if (color != null) 'color: $color',
          'margin: const EdgeInsets.all(${_number(margin)})',
          if (borderWidth > 0)
            'shape: RoundedRectangleBorder(\n'
                '    borderRadius: BorderRadius.circular(${_number(radius)}),\n'
                '    side: BorderSide(\n'
                '      width: ${_number(borderWidth)},\n'
                '${borderColor == null ? '' : '      color: $borderColor,\n'}'
                '    ),\n'
                '  )',
        ];
        if (children.isEmpty) {
          return 'Card(${args.join(', ')})';
        }
        return 'Card(\n'
            '  ${args.map((arg) => arg.replaceAll('\n', '\n  ')).join(',\n  ')},\n'
            '  child: Padding(\n'
            '    padding: const EdgeInsets.all(${_number(padding)}),\n'
            '    child: ${_inline('', children.first, '    ')},\n'
            '  ),\n'
            ')';

      case 'textField':
        final label = _escape(props['label'] as String? ?? '');
        final hint = _escape(props['hint'] as String? ?? '');
        final helper = _escape(props['helperText'] as String? ?? '');
        final obscure = props['obscure'] == true ? 'true' : 'false';
        final prefix = props['prefixIcon'] as String? ?? '';
        final suffix = props['suffixIcon'] as String? ?? '';
        final fillColor = colorExpressionFor(props['fillColor'] as String?);
        final radius = (props['borderRadius'] as num?)?.toDouble() ?? 0;
        final maxLines = (props['maxLines'] as num?)?.toInt() ?? 1;
        final keyboard = props['keyboardType'] as String? ?? 'text';
        final readOnly = props['readOnly'] == true;
        final decoration = <String>["    labelText: '$label',"];
        if (hint.isNotEmpty) {
          decoration.add("    hintText: '$hint',");
        }
        if (helper.isNotEmpty) {
          decoration.add("    helperText: '$helper',");
        }
        if (prefix.isNotEmpty) {
          decoration.add('    prefixIcon: const Icon(${_iconName(prefix)}),');
        }
        if (suffix.isNotEmpty) {
          decoration.add('    suffixIcon: const Icon(${_iconName(suffix)}),');
        }
        if (props['filled'] == false) {
          decoration.add('    filled: false,');
        }
        if (fillColor != null) {
          decoration.add('    fillColor: $fillColor,');
        }
        if (radius > 0) {
          decoration.add(
            '    border: OutlineInputBorder('
            'borderRadius: BorderRadius.circular(${_number(radius)})),',
          );
        }
        final args = <String>[
          '  obscureText: $obscure,',
          if (keyboard != 'text')
            '  keyboardType: ${switch (keyboard) {
              'number' => 'TextInputType.number',
              'email' => 'TextInputType.emailAddress',
              'phone' => 'TextInputType.phone',
              'multiline' => 'TextInputType.multiline',
              _ => 'TextInputType.text',
            }},',
          if (maxLines > 1) '  maxLines: $maxLines,',
          if (readOnly) '  readOnly: true,',
          '  decoration: InputDecoration(',
          ...decoration,
          '  ),',
        ];
        final field = 'TextField(\n${args.join('\n')}\n)';

        final focusBody = _eventBody(
          props['onFocus'] as String?,
          props['eventMessage'] as String? ?? '',
          targetScreen: props['targetScreen'] as String?,
        );
        final blurBody = _eventBody(
          props['onBlur'] as String?,
          props['eventMessage'] as String? ?? '',
          targetScreen: props['targetScreen'] as String?,
        );
        if (focusBody == null && blurBody == null) {
          return field;
        }
        return 'Focus(\n'
            '  onFocusChange: (hasFocus) {\n'
            '    if (hasFocus) {\n'
            '      ${focusBody ?? ''}\n'
            '    } else {\n'
            '      ${blurBody ?? ''}\n'
            '    }\n'
            '  },\n'
            '  child: ${_inline('', field, '    ')},\n'
            ')';

      case 'checkbox':
        final label = _escape(props['label'] as String? ?? '');
        final checked = props['checked'] == true ? 'true' : 'false';
        final size = _number((props['fontSize'] as num?)?.toDouble() ?? 13);
        return 'CheckboxListTile(\n'
            '  value: $checked,\n'
            '  onChanged: (_) {},\n'
            '  dense: true,\n'
            '  contentPadding: EdgeInsets.zero,\n'
            "  title: Text('$label', style: TextStyle(fontSize: $size)),\n"
            ')';

      case 'switch':
        final label = _escape(props['label'] as String? ?? '');
        final value = props['value'] == true ? 'true' : 'false';
        final size = _number((props['fontSize'] as num?)?.toDouble() ?? 13);
        return 'SwitchListTile(\n'
            '  value: $value,\n'
            '  onChanged: (_) {},\n'
            '  dense: true,\n'
            '  contentPadding: EdgeInsets.zero,\n'
            "  title: Text('$label', style: TextStyle(fontSize: $size)),\n"
            ')';

      case 'slider':
        final value = (props['value'] as num?)?.toDouble() ?? 0.5;
        return 'Slider(value: ${_number(value)}, onChanged: (_) {})';

      case 'progress':
        final value = (props['value'] as num?)?.toDouble() ?? 0.5;
        final indeterminate = props['indeterminate'] == true;
        final color = colorExpressionFor(props['color'] as String?);
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final stroke = (props['strokeWidth'] as num?)?.toDouble() ?? 4;
        final radius = (props['borderRadius'] as num?)?.toDouble() ?? 0;
        if (props['style'] == 'circular') {
          return 'CircularProgressIndicator(\n'
              '${indeterminate ? '' : '  value: ${_number(value)},\n'}'
              '  strokeWidth: ${_number(stroke)},\n'
              '${color == null ? '' : '  color: $color,\n'}'
              '${background == null ? '' : '  backgroundColor: $background,\n'}'
              ')';
        }
        return 'LinearProgressIndicator(\n'
            '${indeterminate ? '' : '  value: ${_number(value)},\n'}'
            '  minHeight: ${_number(stroke)},\n'
            '${color == null ? '' : '  color: $color,\n'}'
            '${background == null ? '' : '  backgroundColor: $background,\n'}'
            '${radius <= 0 ? '' : '  borderRadius: BorderRadius.circular(${_number(radius)}),\n'}'
            ')';

      case 'listTile':
        final title = _escape(props['title'] as String? ?? '');
        final subtitle = _escape(props['subtitle'] as String? ?? '');
        final leadingColor = colorExpressionFor(
          props['leadingIconColor'] as String?,
        );
        final trailing = props['trailingIcon'] as String? ?? '';
        final radius = (props['shapeRadius'] as num?)?.toDouble() ?? 0;
        final tileColor = colorExpressionFor(props['tileColor'] as String?);
        final trailingCode = trailing.isNotEmpty
            ? '  trailing: const Icon(${_iconName(trailing)}, size: 20),\n'
            : props['showChevron'] == false
            ? ''
            : '  trailing: const Icon(Icons.chevron_right, size: 20),\n';
        return 'ListTile(\n'
            '  leading: Icon(\n'
            '    ${_iconName(props['icon'] as String?)},\n'
            '${leadingColor == null ? '' : '    color: $leadingColor,\n'}'
            '  ),\n'
            "  title: Text('$title'),\n"
            "  subtitle: Text('$subtitle'),\n"
            '$trailingCode'
            '${props['selected'] == true ? '  selected: true,\n' : ''}'
            '${props['dense'] == true ? '  dense: true,\n' : ''}'
            '${tileColor == null ? '' : '  tileColor: $tileColor,\n'}'
            '${radius <= 0 ? '' : '  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(${_number(radius)})),\n'}'
            ')';

      case 'appBar':
        return _appBarWidget('AppBar', _appBarArgs(node));

      case 'expanded':
        final flex = (props['flex'] as num?)?.round() ?? 1;
        final child = node.children.isEmpty
            ? 'const SizedBox.shrink()'
            : _widgetBlock(node.children.first);
        return 'Expanded(\n'
            '  flex: $flex,\n'
            '  child: ${_inline('', child, '  ')},\n'
            ')';

      case 'flexible':
        final flex = (props['flex'] as num?)?.round() ?? 1;
        final fit = props['fit'] == 'tight' ? 'FlexFit.tight' : 'FlexFit.loose';
        final child = node.children.isEmpty
            ? 'const SizedBox.shrink()'
            : _widgetBlock(node.children.first);
        return 'Flexible(\n'
            '  flex: $flex,\n'
            '  fit: $fit,\n'
            '  child: ${_inline('', child, '  ')},\n'
            ')';

      case 'spacer':
        final flex = (props['flex'] as num?)?.round() ?? 1;
        return 'Spacer(flex: $flex)';

      case 'navigationRail':
        final selected = (props['selected'] as num?)?.round() ?? 0;
        final destinations = <String>[
          for (var index = 0; index < node.children.length; index++)
            '  NavigationRailDestination(\n'
                '    icon: ${_inline('', _widgetBlock(node.children[index]), '    ')},\n'
                "    label: Text('Destino ${index + 1}'),\n"
                '  ),',
        ];
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final labelType = switch (props['labelType']) {
          'none' => 'NavigationRailLabelType.none',
          'all' => 'NavigationRailLabelType.all',
          _ => 'NavigationRailLabelType.selected',
        };
        return 'SizedBox(\n'
            '  height: 400,\n'
            '  child: NavigationRail(\n'
            '    selectedIndex: $selected,\n'
            '    labelType: $labelType,\n'
            '${background == null ? '' : '    backgroundColor: $background,\n'}'
            '    onDestinationSelected: (index) {},\n'
            '    destinations: [\n${_indent(destinations.join('\n'), '      ')}\n    ],\n'
            '  ),\n'
            ')';

      case 'navigationDrawer':
        final drawerChildren = node.children
            .map((child) => _indent('${_widget(child)},', '    '))
            .join('\n');
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        return 'SizedBox(\n'
            '  width: 300,\n'
            '  height: 600,\n'
            '  child: NavigationDrawer(\n'
            '${background == null ? '' : '    backgroundColor: $background,\n'}'
            '    children: [\n${_indent(drawerChildren, '      ')}\n    ],\n'
            '  ),\n'
            ')';

      case 'popupMenu':
        final icon = _iconName(props['icon'] as String?);
        final tooltip = _escape(props['tooltip'] as String? ?? '');
        final item1 = _escape(props['item1'] as String? ?? '');
        final item2 = _escape(props['item2'] as String? ?? '');
        final item3 = _escape(props['item3'] as String? ?? '');
        final message = _escape(props['eventMessage'] as String? ?? '');
        return 'PopupMenuButton<int>(\n'
            '  icon: const Icon($icon),\n'
            '${tooltip.isEmpty ? '' : "  tooltip: '$tooltip',\n"}'
            '  onSelected: (value) {\n'
            '${message.isEmpty ? '' : "    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('$message')));\n"}'
            '  },\n'
            '  itemBuilder: (context) => [\n'
            "    PopupMenuItem(value: 0, child: Text('$item1')),\n"
            "    PopupMenuItem(value: 1, child: Text('$item2')),\n"
            "    PopupMenuItem(value: 2, child: Text('$item3')),\n"
            '  ],\n'
            ')';

      case 'stepper':
        final count = ((props['steps'] as num?)?.round() ?? 3).clamp(2, 6);
        final current = ((props['current'] as num?)?.round() ?? 0).clamp(
          0,
          count - 1,
        );
        final vertical = props['vertical'] != false;
        final showControls = props['showControls'] == true;
        final steps = <String>[
          for (var index = 0; index < count; index++)
            '  Step(\n'
                "    title: Text('Paso ${index + 1}'),\n"
                "    content: Text('Contenido del paso ${index + 1}'),\n"
                '    isActive: ${index <= current},\n'
                '  ),',
        ];
        return 'Stepper(\n'
            '  currentStep: $current,\n'
            '  type: ${vertical ? 'StepperType.vertical' : 'StepperType.horizontal'},\n'
            '  controlsBuilder: (context, details) => '
            '${showControls ? 'Row(children: [TextButton(onPressed: details.onStepContinue, child: const Text(\'Continuar\')), TextButton(onPressed: details.onStepCancel, child: const Text(\'Atrás\'))])' : 'const SizedBox.shrink()'},\n'
            '  steps: [\n${steps.join('\n')}\n  ],\n'
            ')';

      case 'transform':
        final rotation =
            (props['rotation'] as num?)?.toDouble() ?? 0;
        final scale = (props['scale'] as num?)?.toDouble() ?? 1;
        final translateX =
            (props['translateX'] as num?)?.toDouble() ?? 0;
        final translateY =
            (props['translateY'] as num?)?.toDouble() ?? 0;
        final child = node.children.isEmpty
            ? 'const SizedBox.shrink()'
            : _widgetBlock(node.children.first);
        return 'Transform.rotate(\n'
            '  angle: ${_number(rotation)} * 0.017453292519943295,\n'
            '  child: Transform.scale(\n'
            '    scale: ${_number(scale)},\n'
            '    child: Transform.translate(\n'
            '      offset: Offset(${_number(translateX)}, ${_number(translateY)}),\n'
            '      child: ${_inline('', child, '      ')},\n'
            '    ),\n'
            '  ),\n'
            ')';

      case 'intrinsicWidth':
        final step = (props['stepWidth'] as num?)?.toDouble() ?? 0;
        final child = node.children.isEmpty
            ? 'const SizedBox.shrink()'
            : _widgetBlock(node.children.first);
        return 'IntrinsicWidth(\n'
            '${step > 0 ? '  stepWidth: ${_number(step)},\n' : ''}'
            '  child: ${_inline('', child, '  ')},\n'
            ')';

      case 'intrinsicHeight':
        final child = node.children.isEmpty
            ? 'const SizedBox.shrink()'
            : _widgetBlock(node.children.first);
        return 'IntrinsicHeight(\n'
            '  child: ${_inline('', child, '  ')},\n'
            ')';

      case 'dropdownMenu':
        final label = _escape(props['label'] as String? ?? '');
        final options = [
          _escape(props['option1'] as String? ?? ''),
          _escape(props['option2'] as String? ?? ''),
          _escape(props['option3'] as String? ?? ''),
        ];
        final selected =
            ((props['selected'] as num?)?.round() ?? 0).clamp(0, 2);
        return 'DropdownMenu<String>(\n'
            "  initialSelection: '${options[selected]}',\n"
            "  label: const Text('$label'),\n"
            '  onSelected: (value) {},\n'
            '  dropdownMenuEntries: [\n'
            '${options.map((option) => "    DropdownMenuEntry(value: '$option', label: '$option'),").join('\n')}\n'
            '  ],\n'
            ')';

      case 'dataTable':
        final columns = ((props['columns'] as num?)?.round() ?? 3).clamp(
          2,
          5,
        );
        final rows = ((props['rows'] as num?)?.round() ?? 3).clamp(1, 10);
        final checkbox = props['showCheckbox'] == true;
        final columnCode = [
          for (var column = 0; column < columns; column++)
            "    DataColumn(label: Text('Columna ${column + 1}')),",
        ].join('\n');
        final rowCode = [
          for (var row = 0; row < rows; row++)
            '    DataRow(\n'
                '${checkbox ? '      selected: ${row == 0},\n      onSelectChanged: (value) {},\n' : ''}'
                '      cells: [\n'
                '${[for (var column = 0; column < columns; column++) "        DataCell(Text('Fila ${row + 1}')),"].join('\n')}\n'
                '      ],\n'
                '    ),',
        ].join('\n');
        return 'SingleChildScrollView(\n'
            '  scrollDirection: Axis.horizontal,\n'
            '  child: DataTable(\n'
            '    columns: [\n$columnCode\n    ],\n'
            '    rows: [\n$rowCode\n    ],\n'
            '  ),\n'
            ')';

      case 'table':
        final columns = ((props['columns'] as num?)?.round() ?? 2).clamp(1, 5);
        final rows = ((props['rows'] as num?)?.round() ?? 2).clamp(1, 8);
        final border = props['border'] != false;
        final rowCode = [
          for (var row = 0; row < rows; row++)
            '    TableRow(\n'
                '      children: [\n'
                '${[for (var column = 0; column < columns; column++) "        Padding(padding: const EdgeInsets.all(8), child: Text('R${row + 1} C${column + 1}')),"].join('\n')}\n'
                '      ],\n'
                '    ),',
        ].join('\n');
        return 'Table(\n'
            '${border ? '  border: TableBorder.all(color: Theme.of(context).dividerColor),\n' : ''}'
            '  children: [\n$rowCode\n  ],\n'
            ')';

      case 'bottomNav':
        final destinations = <String>[];
        for (final child in node.children) {
          if (child.type != 'icon' && child.type != 'navItem') {
            continue;
          }
          final definition = standardCatalog[child.type]!;
          final childValues = <String, Object?>{
            for (final spec in definition.properties)
              spec.key: spec.coerce(child.properties[spec.key]),
          };
          final icon = childValues['icon'] as String? ?? 'home';
          final selectedIcon = childValues['selectedIcon'] as String? ?? '';
          final label = _escape(childValues['label'] as String? ?? '');
          final showLabel = childValues['showLabel'] != false;
          final tooltip = _escape(childValues['tooltip'] as String? ?? '');
          final semantic = _escape(
            childValues['semanticLabel'] as String? ?? '',
          );
          final enabled = childValues['enabled'] != false;
          final size =
              (childValues['size'] as num?)?.toDouble() ?? 24;
          final fill = (childValues['fill'] as num?)?.toDouble() ?? 0;
          final shadow = childValues['shadow'] == true;
          final shadowColor =
              colorExpressionFor(childValues['shadowColor'] as String?) ??
              'Theme.of(context).colorScheme.onSurface';

          String iconCode(String name, String? colorValue) {
            final color = colorExpressionFor(colorValue);
            final args = <String>['size: ${_number(size)}'];
            if (color != null) {
              args.add('color: $color');
            }
            if (fill > 0) {
              args.add('fill: ${_number(fill)}');
            }
            if (childValues['textDirection'] == 'rtl') {
              args.add('textDirection: TextDirection.rtl');
            }
            if (semantic.isNotEmpty) {
              args.add("semanticLabel: '$semantic'");
            }
            if (shadow) {
              args.add(
                'shadows: [BoxShadow(color: $shadowColor, '
                'blurRadius: ${_number((childValues['shadowBlur'] as num?)?.toDouble() ?? 8)}, '
                'offset: Offset(${_number((childValues['shadowOffsetX'] as num?)?.toDouble() ?? 4)}, '
                '${_number((childValues['shadowOffsetY'] as num?)?.toDouble() ?? 4)}))]',
              );
            }
            return 'Icon(${_iconName(name)}, ${args.join(', ')})';
          }

          final normalColor = childValues['color'] as String?;
          final rawSelectedColor = childValues['selectedColor'] as String?;
          final selectedColor =
              rawSelectedColor == null ||
                  rawSelectedColor.isEmpty ||
                  rawSelectedColor == 'inherit'
              ? normalColor
              : rawSelectedColor;
          destinations.add(
            '  // inicio de ${definition.label}\n'
            '  NavigationDestination(\n'
            '    icon: ${iconCode(icon, normalColor)},\n'
            '    selectedIcon: ${iconCode(selectedIcon.isEmpty ? icon : selectedIcon, selectedColor)},\n'
            "    label: '${showLabel ? label : ''}',\n"
            '${tooltip.isEmpty ? '' : "    tooltip: '$tooltip',\n"}'
            '${enabled ? '' : '    enabled: false,\n'}'
            '  ),\n'
            '  // fin de ${definition.label}',
          );
        }

        if (destinations.isEmpty) {
          // Compatibilidad con pantallas viejas (solo guardaban la cantidad).
          final count =
              int.tryParse(node.properties['items']?.toString() ?? '3') ?? 3;
          const labels = ['Inicio', 'Buscar', 'Favorito', 'Ajustes', 'Perfil'];
          const icons = ['home', 'search', 'favorite', 'settings', 'person'];
          for (var index = 0; index < count; index++) {
            destinations.add(
              '  NavigationDestination('
              'icon: const Icon(${_iconName(icons[index])}), '
              "label: '${labels[index]}'),",
            );
          }
        }
        // NavigationBar requiere al menos dos destinos.
        const minLabels = ['Inicio', 'Buscar'];
        const minIcons = ['home', 'search'];
        while (destinations.length < 2) {
          final index = destinations.length;
          destinations.add(
            '  NavigationDestination('
            'icon: const Icon(${_iconName(minIcons[index])}), '
            "label: '${minLabels[index]}'),",
          );
        }

        final selected = ((props['selected'] as num?)?.round() ?? 0)
            .clamp(0, destinations.length - 1)
            .toInt();
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final indicator = colorExpressionFor(
          props['indicatorColor'] as String?,
        );
        final shadow = colorExpressionFor(
          props['shadowColor'] as String?,
        );
        final height = (props['height'] as num?)?.toDouble() ?? 80;
        final elevation = (props['elevation'] as num?)?.toDouble() ?? 8;
        final duration =
            (props['animationDuration'] as num?)?.round() ?? 500;
        final labelBehavior = switch (props['labelBehavior']) {
          'onlyShowSelected' =>
            'NavigationDestinationLabelBehavior.onlyShowSelected',
          'alwaysHide' => 'NavigationDestinationLabelBehavior.alwaysHide',
          _ => 'NavigationDestinationLabelBehavior.alwaysShow',
        };
        final shape = switch (props['indicatorShape']) {
          'circle' => 'const CircleBorder()',
          'rectangle' =>
            'RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))',
          _ => 'const StadiumBorder()',
        };
        final message = _escape(props['eventMessage'] as String? ?? '');
        final onChange = props['onChangeAction'] == 'message'
            ? 'ScaffoldMessenger.of(context).showSnackBar('
                  "const SnackBar(content: Text('$message')));"
            : '';
        final args = <String>[
          'selectedIndex: $selected',
          'destinations: [\n${destinations.join('\n')}\n  ]',
          if (background != null) 'backgroundColor: $background',
          if (indicator != null) 'indicatorColor: $indicator',
          'height: ${_number(height)}',
          if (elevation != 8) 'elevation: ${_number(elevation)}',
          if (shadow != null) 'shadowColor: $shadow',
          'indicatorShape: $shape',
          'labelBehavior: $labelBehavior',
          'animationDuration: const Duration(milliseconds: $duration)',
          'onDestinationSelected: (index) {\n$onChange\n  }',
        ];
        final selectedIconColor =
            colorExpressionFor(props['selectedIconColor'] as String?) ??
            'Theme.of(context).colorScheme.primary';
        final unselectedIconColor =
            colorExpressionFor(props['unselectedIconColor'] as String?) ??
            'Theme.of(context).colorScheme.onSurfaceVariant';
        final selectedLabelColor =
            colorExpressionFor(props['selectedLabelColor'] as String?) ??
            'Theme.of(context).colorScheme.primary';
        final unselectedLabelColor =
            colorExpressionFor(props['unselectedLabelColor'] as String?) ??
            'Theme.of(context).colorScheme.onSurfaceVariant';
        return 'NavigationBarTheme(\n'
            '  data: NavigationBarThemeData(\n'
            '    iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(\n'
            '      color: states.contains(WidgetState.selected)\n'
            '          ? $selectedIconColor\n'
            '          : $unselectedIconColor,\n'
            '    )),\n'
            '    labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(\n'
            '      fontSize: 12,\n'
            '      fontWeight: states.contains(WidgetState.selected)\n'
            '          ? FontWeight.w600\n'
            '          : FontWeight.w500,\n'
            '      color: states.contains(WidgetState.selected)\n'
            '          ? $selectedLabelColor\n'
            '          : $unselectedLabelColor,\n'
            '    )),\n'
            '  ),\n'
            '  child: NavigationBar(\n'
            '${args.map((arg) => _indent('$arg,', '    ')).join('\n')}\n'
            '  ),\n'
            ')';

      case 'tabs':
        const tabLabels = ['Uno', 'Dos', 'Tres', 'Cuatro', 'Cinco'];
        final count = int.tryParse(props['count'] as String? ?? '3') ?? 3;
        final selected = ((props['selected'] as num?)?.round() ?? 0).clamp(
          0,
          count - 1,
        );
        final tabs = List.generate(
          count,
          (index) => "    Tab(text: '${tabLabels[index]}'),",
        ).join('\n');
        return 'DefaultTabController(\n'
            '  length: $count,\n'
            '  initialIndex: $selected,\n'
            '  child: TabBar(\n'
            '    tabs: const [\n$tabs\n    ],\n'
            '  ),\n'
            ')';

      case 'drawer':
      case 'endDrawer':
        return 'Drawer(\n  child: ListView(\n    children: const [\n'
            "      ListTile(title: Text('Elemento 1')),\n"
            "      ListTile(title: Text('Elemento 2')),\n"
            '    ],\n  ),\n)';

      case 'fab':
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final foreground = colorExpressionFor(
          props['foregroundColor'] as String?,
        );
        final elevation = (props['elevation'] as num?)?.toDouble() ?? 6;
        final iconSize = (props['iconSize'] as num?)?.toDouble() ?? 24;
        final tooltip = props['tooltip'] as String? ?? '';
        final label = props['extendedLabel'] as String? ?? '';
        final icon = _iconName(props['icon'] as String?);
        if (label.isNotEmpty) {
          return 'FloatingActionButton.extended(\n'
              '  onPressed: () {},\n'
              '  icon: const Icon($icon),\n'
              "  label: const Text('${_escape(label)}'),\n"
              '${background == null ? '' : '  backgroundColor: $background,\n'}'
              '${foreground == null ? '' : '  foregroundColor: $foreground,\n'}'
              '  elevation: ${_number(elevation)},\n'
              '${tooltip.isEmpty ? '' : "  tooltip: '${_escape(tooltip)}',\n"}'
              ')';
        }
        return 'FloatingActionButton(\n'
            '  onPressed: () {},\n'
            '${props['mini'] == true ? '  mini: true,\n' : ''}'
            '${background == null ? '' : '  backgroundColor: $background,\n'}'
            '${foreground == null ? '' : '  foregroundColor: $foreground,\n'}'
            '  elevation: ${_number(elevation)},\n'
            '${tooltip.isEmpty ? '' : "  tooltip: '${_escape(tooltip)}',\n"}'
            '  child: Icon($icon, size: ${_number(iconSize)}),\n'
            ')';

      case 'image':
        final url = (props['url'] as String? ?? '').trim();
        final width = (props['width'] as num?)?.toDouble() ?? 0;
        final height = (props['height'] as num?)?.toDouble() ?? 160;
        final radius = (props['radius'] as num?)?.toDouble() ?? 12;
        final opacity =
            ((props['opacity'] as num?)?.toDouble() ?? 1).clamp(0.0, 1.0);
        final fit = switch (props['fit']) {
          'contain' => 'BoxFit.contain',
          'fill' => 'BoxFit.fill',
          'fitWidth' => 'BoxFit.fitWidth',
          _ => 'BoxFit.cover',
        };
        final placeholder = 'Container('
            '${width == 0 ? '' : 'width: ${_number(width)}, '}'
            'height: ${_number(height)}, '
            'decoration: BoxDecoration('
            'color: Theme.of(context).colorScheme.surfaceContainerHighest, '
            'borderRadius: BorderRadius.circular(${_number(radius)})), '
            'child: Icon(Icons.image_outlined, '
            'color: Theme.of(context).colorScheme.onSurfaceVariant))';
        final content = url.isEmpty
            ? placeholder
            : 'Image.network('
                  "'${_escape(url)}', "
                  '${width == 0 ? '' : 'width: ${_number(width)}, '}'
                  'height: ${_number(height)}, '
                  'fit: $fit, '
                  'errorBuilder: (context, error, stackTrace) => $placeholder)';
        return 'ClipRRect(\n'
            '  borderRadius: BorderRadius.circular(${_number(radius)}),\n'
            '  child: Opacity(\n'
            '    opacity: ${_number(opacity)},\n'
            '    child: ${_inline('', content, '    ')},\n'
            '  ),\n'
            ')';

      case 'stack':
        final fit = switch (props['fit']) {
          'expand' => 'StackFit.expand',
          'passthrough' => 'StackFit.passthrough',
          _ => 'StackFit.loose',
        };
        final list = children.isEmpty
            ? ''
            : '  children: [\n'
                  '${children.map((child) => _inline('', child, '    ')).join(',\n')},\n'
                  '  ],\n';
        return 'Stack(\n'
            '  alignment: ${_alignmentName(props['alignment'] as String?)},\n'
            '  fit: $fit,\n'
            '${props['clipBehavior'] == null || props['clipBehavior'] == 'hardEdge' ? '' : '  clipBehavior: ${switch (props['clipBehavior']) {
              'antiAlias' => 'Clip.antiAlias',
              'none' => 'Clip.none',
              _ => 'Clip.hardEdge',
            }},\n'}'
            '$list'
            ')';

      case 'wrap':
        final list = children.isEmpty
            ? ''
            : '  children: [\n'
                  '${children.map((child) => _inline('', child, '    ')).join(',\n')},\n'
                  '  ],\n';
        final alignment = switch (props['alignment']) {
          'center' => 'WrapAlignment.center',
          'end' => 'WrapAlignment.end',
          'spaceBetween' => 'WrapAlignment.spaceBetween',
          'spaceEvenly' => 'WrapAlignment.spaceEvenly',
          _ => 'WrapAlignment.start',
        };
        return 'Wrap(\n'
            '  spacing: ${_number((props['spacing'] as num?)?.toDouble() ?? 8)},\n'
            '  runSpacing: ${_number((props['runSpacing'] as num?)?.toDouble() ?? 8)},\n'
            '  alignment: $alignment,\n'
            '  crossAxisAlignment: ${switch (props['crossAxisAlignment']) {
              'center' => 'WrapCrossAlignment.center',
              'end' => 'WrapCrossAlignment.end',
              _ => 'WrapCrossAlignment.start',
            }},\n'
            '  direction: ${props['direction'] == 'vertical' ? 'Axis.vertical' : 'Axis.horizontal'},\n'
            '$list'
            ')';

      case 'align':
        final width = (props['widthFactor'] as num?)?.toDouble() ?? 0;
        final height = (props['heightFactor'] as num?)?.toDouble() ?? 0;
        final child = children.isEmpty
            ? 'const SizedBox.shrink()'
            : _inline('', children.first, '  ');
        return 'Align(\n'
            '  alignment: ${_alignmentName(props['alignment'] as String?)},\n'
            '${width != 0 ? '  widthFactor: ${_number(width)},\n' : ''}'
            '${height != 0 ? '  heightFactor: ${_number(height)},\n' : ''}'
            '  child: $child,\n'
            ')';

      case 'sizedBox':
        final width = (props['width'] as num?)?.toDouble() ?? 0;
        final height = (props['height'] as num?)?.toDouble() ?? 0;
        final child = children.isEmpty
            ? null
            : _inline('', children.first, '  ');
        return 'SizedBox(\n'
            '${width != 0 ? '  width: ${_number(width)},\n' : ''}'
            '${height != 0 ? '  height: ${_number(height)},\n' : ''}'
            '${child != null ? '  child: $child,\n' : ''}'
            ')';

      case 'chip':
        final label = _escape(props['label'] as String? ?? '');
        final icon = props['avatarIcon'] as String? ?? '';
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final foreground = colorExpressionFor(
          props['textColor'] as String?,
        );
        return 'Chip(\n'
            '${icon.isNotEmpty ? '  avatar: const Icon(${_iconName(icon)}),\n' : ''}'
            "  label: Text('$label'),\n"
            '${background == null ? '' : '  backgroundColor: $background,\n'}'
            '${foreground == null ? '' : '  labelStyle: TextStyle(color: $foreground),\n'}'
            '  elevation: ${_number((props['elevation'] as num?)?.toDouble() ?? 0)},\n'
            '${props['showDeleteIcon'] == true ? '  onDeleted: () {},\n' : ''}'
            ')';

      case 'avatar':
        final initials = _escape(props['initials'] as String? ?? '');
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final foreground = colorExpressionFor(
          props['textColor'] as String?,
        );
        final fontSize =
            (props['fontSize'] as num?)?.toDouble() ?? 16;
        final imageUrl = (props['imageUrl'] as String? ?? '').trim();
        final borderWidth = (props['borderWidth'] as num?)?.toDouble() ?? 0;
        final borderColor = colorExpressionFor(
          props['borderColor'] as String?,
        );
        final radius = (props['radius'] as num?)?.toDouble() ?? 20;
        final avatar = 'CircleAvatar(\n'
            '  radius: ${_number(borderWidth > 0 ? radius - borderWidth : radius)},\n'
            '${background == null ? '' : '  backgroundColor: $background,\n'}'
            '${imageUrl.isEmpty ? '' : "  backgroundImage: NetworkImage('${_escape(imageUrl)}'),\n"}'
            '  child: Text(\n'
            "    '$initials',\n"
            '    style: TextStyle(fontSize: ${_number(fontSize)}'
            '${foreground == null ? '' : ', color: $foreground'}'
            '),\n'
            '  ),\n'
            ')';
        if (borderWidth <= 0) {
          return avatar;
        }
        return 'Container(\n'
            '  padding: EdgeInsets.all(${_number(borderWidth)}),\n'
            '  decoration: BoxDecoration(\n'
            '    shape: BoxShape.circle,\n'
            '    color: ${borderColor ?? 'Theme.of(context).colorScheme.primary'},\n'
            '  ),\n'
            '  child: ${_inline('', avatar, '  ')},\n'
            ')';

      case 'segmentedButton':
        final labels = [
          _escape(props['option1'] as String? ?? 'Uno'),
          _escape(props['option2'] as String? ?? 'Dos'),
          _escape(props['option3'] as String? ?? 'Tres'),
        ];
        final selected = int.tryParse(
              props['selectedIndex'] as String? ?? '0',
            ) ??
            0;
        final segments = StringBuffer('  segments: const [\n');
        for (var index = 0; index < labels.length; index++) {
          segments.write(
            "    ButtonSegment(value: $index, label: Text('${labels[index]}')),\n",
          );
        }
        segments.write('  ],\n');
        final fontSize = _number(
          (props['fontSize'] as num?)?.toDouble() ?? 13,
        );
        return 'SegmentedButton<int>(\n'
            '${segments.toString()}'
            '  selected: {${selected.clamp(0, labels.length - 1)}},\n'
            '  showSelectedIcon: ${props['showSelectedIcon'] != false},\n'
            '  style: ButtonStyle(\n'
            '    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: $fontSize)),\n'
            '    visualDensity: VisualDensity.compact,\n'
            '  ),\n'
            '${props['direction'] == 'vertical' ? '  direction: Axis.vertical,\n' : ''}'
            '  onSelectionChanged: (_) {},\n'
            ')';

      case 'verticalDivider':
        return 'VerticalDivider('
            'thickness: ${_number((props['thickness'] as num?)?.toDouble() ?? 1)}, '
            'indent: ${_number((props['indent'] as num?)?.toDouble() ?? 0)})';

      case 'opacity':
        return 'Opacity(\n'
            '  opacity: ${_number(((props['opacity'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0))},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'aspectRatio':
        return 'AspectRatio(\n'
            '  aspectRatio: ${_number(((props['ratio'] as num?)?.toDouble() ?? 1.5).clamp(0.1, 4.0))},\n'
            '  child: Align(\n'
            '    alignment: ${_alignmentName(props['alignment'] as String?)},\n'
            '    child: ${_firstChildCode(children)},\n'
            '  ),\n'
            ')';

      case 'visibility':
        return 'Visibility(\n'
            '  visible: ${props['isVisible'] != false},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'safeArea':
        return 'SafeArea(\n'
            '  top: ${props['top'] != false},\n'
            '  bottom: ${props['bottom'] != false},\n'
            '  left: ${props['left'] != false},\n'
            '  right: ${props['right'] != false},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'radioTile':
        final title = _escape(props['title'] as String? ?? 'Opción');
        final subtitle = _escape(props['subtitle'] as String? ?? '');
        final enabled = props['enabled'] != false;
        final fontSize = (props['fontSize'] as num?)?.toDouble() ?? 13;
        final radio = 'RadioGroup<bool>(\n'
            '  groupValue: ${props['selected'] == true},\n'
            '  onChanged: (_) {},\n'
            '  child: RadioListTile<bool>(\n'
            '    value: true,\n'
            '    dense: true,\n'
            '    contentPadding: EdgeInsets.zero,\n'
            "    title: Text('$title', style: TextStyle(fontSize: ${_number(fontSize)})),\n"
            '${subtitle.isEmpty ? '' : "    subtitle: Text('$subtitle', style: TextStyle(fontSize: ${_number((fontSize - 1).clamp(8, 22))})),\n"}'
            '  ),\n'
            ')';
        if (enabled) {
          return radio;
        }
        return 'IgnorePointer(ignoring: true, child: ${_inline('', radio, '  ')})';

      case 'dropdownField':
        final label = _escape(props['label'] as String? ?? '');
        final options = (props['options'] as String? ?? '')
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        final values = options.isEmpty ? const ['Opción 1'] : options;
        final value = values.contains(props['value'])
            ? props['value'] as String
            : values.first;
        final items = StringBuffer('  items: [\n');
        for (final option in values) {
          final escaped = _escape(option);
          items.write(
            "    DropdownMenuItem(value: '$escaped', child: Text('$escaped')),\n",
          );
        }
        items.write('  ],\n');
        return 'DropdownButtonFormField<String>(\n'
            "  initialValue: '${_escape(value)}',\n"
            "  decoration: InputDecoration(labelText: '$label'),\n"
            '${items.toString()}'
            '  onChanged: (_) {},\n'
            ')';

      case 'searchBar':
        return 'SearchBar(\n'
            "  hintText: '${_escape(props['hint'] as String? ?? '')}',\n"
            '  leading: const Icon(Icons.search),\n'
            ')';

      case 'switchTile':
        final title = _escape(props['title'] as String? ?? '');
        final subtitle = _escape(props['subtitle'] as String? ?? '');
        final fontSize = (props['fontSize'] as num?)?.toDouble() ?? 13;
        return 'SwitchListTile(\n'
            '  value: ${props['value'] == true},\n'
            "  title: Text('$title', style: TextStyle(fontSize: ${_number(fontSize)})),\n"
            '${subtitle.isEmpty ? '' : "  subtitle: Text('$subtitle', style: TextStyle(fontSize: ${_number((fontSize - 1).clamp(8, 22))})),\n"}'
            '  onChanged: (_) {},\n'
            '  dense: true,\n'
            '  contentPadding: EdgeInsets.zero,\n'
            ')';

      case 'iconButton':
        final event = _eventBody(
          props['onTap'] as String?,
          props['eventMessage'] as String? ?? '',
          targetScreen: props['targetScreen'] as String?,
        );
        final callback = event == null ? '() {}' : '() {\n    $event\n  }';
        final color = colorExpressionFor(props['color'] as String?);
        final tooltip = props['tooltip'] as String? ?? '';
        return 'IconButton(\n'
            '${tooltip.isEmpty ? '' : "  tooltip: '${_escape(tooltip)}',\n"}'
            '  iconSize: ${_number((props['size'] as num?)?.toDouble() ?? 24)},\n'
            '${color == null ? '' : '  color: $color,\n'}'
            '  onPressed: $callback,\n'
            '  icon: const Icon(${_iconName(props['icon'] as String?)}),\n'
            ')';

      case 'tooltip':
        final wait = (props['waitDuration'] as num?)?.toInt() ?? 500;
        final show = (props['showDuration'] as num?)?.toInt() ?? 1500;
        final offset = (props['verticalOffset'] as num?)?.toDouble() ?? 0;
        final padding = (props['padding'] as num?)?.toDouble() ?? 0;
        return 'Tooltip(\n'
            "  message: '${_escape(props['message'] as String? ?? '')}',\n"
            '  waitDuration: const Duration(milliseconds: $wait),\n'
            '  showDuration: const Duration(milliseconds: $show),\n'
            '${props['preferBelow'] == false ? '  preferBelow: false,\n' : ''}'
            '${offset == 0 ? '' : '  verticalOffset: ${_number(offset)},\n'}'
            '${padding == 0 ? '' : '  padding: EdgeInsets.all(${_number(padding)}),\n'}'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'selectableText':
        final align = switch (props['align']) {
          'center' => 'TextAlign.center',
          'right' => 'TextAlign.right',
          _ => 'TextAlign.left',
        };
        final weight = switch (props['fontWeight']) {
          'normal' => 'FontWeight.w400',
          'w600' => 'FontWeight.w600',
          'bold' => 'FontWeight.bold',
          _ => null,
        };
        final color = colorExpressionFor(props['color'] as String?);
        final maxLines = (props['maxLines'] as num?)?.toInt() ?? 0;
        final styleParts = <String>[
          'fontSize: ${_number((props['fontSize'] as num?)?.toDouble() ?? 14)}',
          if (weight != null) 'fontWeight: $weight',
          if (color != null) 'color: $color',
        ];
        return 'SelectableText(\n'
            "  '${_escape(props['text'] as String? ?? '')}',\n"
            '${maxLines > 0 ? '  maxLines: $maxLines,\n' : ''}'
            '  style: TextStyle(${styleParts.join(', ')}),\n'
            '  textAlign: $align,\n'
            ')';

      case 'listView':
        final gap = (props['gap'] as num?)?.toDouble() ?? 8;
        final entries = <String>[];
        for (var index = 0; index < children.length; index++) {
          if (index > 0 && gap > 0) {
            entries.add('    SizedBox(height: ${_number(gap)}),');
          }
          entries.add('    ${_inline('', children[index], '    ')},');
        }
        return 'ListView(\n'
            '  shrinkWrap: true,\n'
            '  physics: const NeverScrollableScrollPhysics(),\n'
            '  children: [\n'
            '${entries.join('\n')}\n'
            '  ],\n'
            ')';

      case 'gridView':
        final gap = (props['gap'] as num?)?.toDouble() ?? 8;
        return 'GridView.count(\n'
            '  crossAxisCount: ${(props['columns'] as num?)?.toInt() ?? 2},\n'
            '  shrinkWrap: true,\n'
            '  physics: const NeverScrollableScrollPhysics(),\n'
            '  mainAxisSpacing: ${_number(gap)},\n'
            '  crossAxisSpacing: ${_number(gap)},\n'
            '  children: [\n'
            '${children.map((child) => '    ${_inline('', child, '    ')},').join('\n')}\n'
            '  ],\n'
            ')';

      case 'clipRRect':
        return 'ClipRRect(\n'
            '  borderRadius: BorderRadius.circular(${_number((props['radius'] as num?)?.toDouble() ?? 12)}),\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'clipOval':
        return 'ClipOval(\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'coloredBox':
        final color = colorExpressionFor(props['color'] as String?);
        return 'ColoredBox(\n'
            '  color: ${color ?? 'Theme.of(context).colorScheme.surfaceContainerLow'},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'decoratedBox':
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final radius = (props['radius'] as num?)?.toDouble() ?? 12;
        final border = (props['borderWidth'] as num?)?.toDouble() ?? 0;
        return 'DecoratedBox(\n'
            '  decoration: BoxDecoration(\n'
            '${background == null ? '' : '    color: $background,\n'}'
            '    borderRadius: BorderRadius.circular(${_number(radius)}),\n'
            '${border <= 0 ? '' : '    border: Border.all(width: ${_number(border)}),\n'}'
            '  ),\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'offstage':
        return 'Offstage(\n'
            '  offstage: ${props['offstage'] == true},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'badge':
        final label = _escape(props['label'] as String? ?? '');
        final background = colorExpressionFor(
          props['backgroundColor'] as String?,
        );
        final foreground = colorExpressionFor(
          props['textColor'] as String?,
        );
        final child = children.isEmpty
            ? 'const Icon(Icons.notifications_outlined)'
            : _inline('', children.first, '  ');
        return 'Badge(\n'
            "  label: Text('$label'${foreground == null ? '' : ', style: TextStyle(color: $foreground)'}),\n"
            '${background == null ? '' : '  backgroundColor: $background,\n'}'
            '  child: $child,\n'
            ')';

      case 'bottomAppBar':
        final color = colorExpressionFor(props['color'] as String?);
        final icons = children.isEmpty
            ? 'const []'
            : '[\n${children.map((child) => '      ${_inline('', child, '      ')},').join('\n')}\n    ]';
        return 'BottomAppBar(\n'
            '  height: ${_number((props['height'] as num?)?.toDouble() ?? 64)},\n'
            '${color == null ? '' : '  color: $color,\n'}'
            '  elevation: ${_number((props['elevation'] as num?)?.toDouble() ?? 3)},\n'
            '  child: Row(\n'
            '    mainAxisAlignment: MainAxisAlignment.spaceAround,\n'
            '    children: $icons,\n'
            '  ),\n'
            ')';

      case 'expansionTile':
        final subtitle = _escape(props['subtitle'] as String? ?? '');
        return 'ExpansionTile(\n'
            "  title: Text('${_escape(props['title'] as String? ?? '')}'),\n"
            '${subtitle.isEmpty ? '' : "  subtitle: Text('$subtitle'),\n"}'
            '  initiallyExpanded: ${props['initiallyExpanded'] != false},\n'
            '  children: [\n'
            '${children.map((child) => '    ${_inline('', child, '    ')},').join('\n')}\n'
            '  ],\n'
            ')';

      case 'banner':
        final color = colorExpressionFor(props['backgroundColor'] as String?);
        return 'MaterialBanner(\n'
            "  content: Text('${_escape(props['message'] as String? ?? '')}'),\n"
            '${color == null ? '' : '  backgroundColor: $color,\n'}'
            '  actions: [\n'
            "    TextButton(onPressed: () {}, child: Text('${_escape(props['actionLabel'] as String? ?? '')}')),\n"
            '  ],\n'
            ')';

      case 'toggleButtons':
        final labels = [
          _escape(props['option1'] as String? ?? 'Uno'),
          _escape(props['option2'] as String? ?? 'Dos'),
          _escape(props['option3'] as String? ?? 'Tres'),
        ];
        final selected = int.tryParse(
              props['selectedIndex'] as String? ?? '0',
            ) ??
            0;
        final flags = [
          for (var index = 0; index < labels.length; index++)
            index == selected.clamp(0, labels.length - 1),
        ];
        return 'ToggleButtons(\n'
            '  isSelected: $flags,\n'
            '  onPressed: (_) {},\n'
            '  children: [\n'
            '${labels.map((label) => "    Text('$label'),").join('\n')}\n'
            '  ],\n'
            ')';

      case 'fittedBox':
        final fit = switch (props['fit']) {
          'cover' => 'BoxFit.cover',
          'fill' => 'BoxFit.fill',
          'scaleDown' => 'BoxFit.scaleDown',
          _ => 'BoxFit.contain',
        };
        return 'FittedBox(\n'
            '  fit: $fit,\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'fractionallySizedBox':
        return 'FractionallySizedBox(\n'
            '  widthFactor: ${_number(((props['widthFactor'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0))},\n'
            '  heightFactor: ${_number(((props['heightFactor'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0))},\n'
            '  alignment: ${_alignmentName(props['alignment'] as String?)},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'constrainedBox':
        return 'ConstrainedBox(\n'
            '  constraints: const BoxConstraints(\n'
            '    maxWidth: ${_number((props['maxWidth'] as num?)?.toDouble() ?? 240)},\n'
            '    maxHeight: ${_number((props['maxHeight'] as num?)?.toDouble() ?? 160)},\n'
            '  ),\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'limitedBox':
        return 'LimitedBox(\n'
            '  maxWidth: ${_number((props['maxWidth'] as num?)?.toDouble() ?? 200)},\n'
            '  maxHeight: ${_number((props['maxHeight'] as num?)?.toDouble() ?? 120)},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'rotatedBox':
        return 'RotatedBox(\n'
            '  quarterTurns: ${(props['quarterTurns'] as num?)?.toInt() ?? 1},\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      case 'inkWell':
        final event = _eventBody(
          props['onTap'] as String?,
          props['eventMessage'] as String? ?? '',
          targetScreen: props['targetScreen'] as String?,
        );
        final callback = event == null ? '() {}' : '() {\n    $event\n  }';
        return 'InkWell(\n'
            '  onTap: $callback,\n'
            '  child: ${_firstChildCode(children)},\n'
            ')';

      default:
        return '// TODO: código pendiente para ${node.type}\nPlaceholder()';
    }
  }

  /// Expresión Dart del estado vacío de una pantalla.
  static const String _emptyStateCode =
      'Center(\n'
      '  child: Column(\n'
      '    mainAxisSize: MainAxisSize.min,\n'
      '    children: [\n'
      '      Container(\n'
      '        width: 56,\n'
      '        height: 56,\n'
      '        decoration: BoxDecoration(\n'
      '          color: Theme.of(context).colorScheme.surfaceContainerHighest,\n'
      '          borderRadius: BorderRadius.circular(16),\n'
      '        ),\n'
      '        child: Icon(\n'
      '          Icons.dashboard_customize_outlined,\n'
      '          color: Theme.of(context).colorScheme.onSurfaceVariant,\n'
      '        ),\n'
      '      ),\n'
      '      const SizedBox(height: 14),\n'
      '      Text(\n'
      "        'Tu pantalla está vacía',\n"
      '        textAlign: TextAlign.center,\n'
      '        style: Theme.of(context).textTheme.titleSmall,\n'
      '      ),\n'
      '      const SizedBox(height: 6),\n'
      '      Text(\n'
      "        'Arrastra un widget desde la biblioteca o haz clic en uno "
      "para empezar.',\n"
      '        textAlign: TextAlign.center,\n'
      '        style: Theme.of(context).textTheme.bodySmall,\n'
      '      ),\n'
      '    ],\n'
      '  ),\n'
      ')';

  /// Código del primer hijo, o un hueco vacío.
  static String _firstChildCode(List<String> children) => children.isEmpty
      ? 'const SizedBox.shrink()'
      : _inline('', children.first, '  ');

  static String _flexBox(
    String kind,
    List<String> children, {
    num? gap,
    String? mainAxisAlignment,
    String? crossAxisAlignment,
  }) {
    if (children.isEmpty) {
      return '$kind(children: const [])';
    }
    final spacing = gap?.toDouble() ?? 0;
    final args = <String>[
      if (mainAxisAlignment != null)
        '  mainAxisAlignment: ${_mainAxisName(mainAxisAlignment)},',
      if (crossAxisAlignment != null)
        '  crossAxisAlignment: ${_crossAxisName(crossAxisAlignment)},',
    ];
    final entries = <String>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0 && spacing > 0) {
        entries.add(
          kind == 'Row'
              ? '  SizedBox(width: ${_number(spacing)}),'
              : '  SizedBox(height: ${_number(spacing)}),',
        );
      }
      entries.add(_indent('${children[index]},', '  '));
    }
    return '$kind(\n${args.join('\n')}\n  children: [\n${entries.join('\n')}\n  ],\n)';
  }

  static String _mainAxisName(String value) => switch (value) {
    'center' => 'MainAxisAlignment.center',
    'end' => 'MainAxisAlignment.end',
    'spaceBetween' => 'MainAxisAlignment.spaceBetween',
    _ => 'MainAxisAlignment.start',
  };

  static String _crossAxisName(String value) => switch (value) {
    'center' => 'CrossAxisAlignment.center',
    'end' => 'CrossAxisAlignment.end',
    'stretch' => 'CrossAxisAlignment.stretch',
    _ => 'CrossAxisAlignment.start',
  };

  /// Argumentos comunes de `AppBar`/`SliverAppBar`.
  static List<String> _appBarArgs(CanvasNode node) {
    final definition = standardCatalog[node.type]!;
    final props = <String, Object?>{
      for (final spec in definition.properties)
        spec.key: spec.coerce(node.properties[spec.key]),
    };

    final title = _escape(props['title'] as String? ?? '');
    final args = <String>[
      "title: FittedBox(fit: BoxFit.scaleDown, child: const Text('$title'))",
    ];
    if (props['centerTitle'] == true) {
      args.add('centerTitle: true');
    }
    final elevation = (props['elevation'] as num?)?.toDouble() ?? 0;
    if (elevation != 0) {
      args.add('elevation: ${_number(elevation)}');
    }
    final scrolled = (props['scrolledUnderElevation'] as num?)?.toDouble() ?? 3;
    if (scrolled != 3) {
      args.add('scrolledUnderElevation: ${_number(scrolled)}');
    }
    final height = (props['toolbarHeight'] as num?)?.toDouble() ?? 56;
    if (height != 56) {
      args.add('toolbarHeight: ${_number(height)}');
    }
    final background = colorExpressionFor(props['backgroundColor'] as String?);
    if (background != null) {
      args.add('backgroundColor: $background');
    }
    final foreground = colorExpressionFor(props['foregroundColor'] as String?);
    if (foreground != null) {
      args.add('foregroundColor: $foreground');
    }
    if (props['gradient'] == true) {
      final end =
          colorExpressionFor(props['gradientColor'] as String?) ??
          'Theme.of(context).colorScheme.secondaryContainer';
      args.add('backgroundColor: Colors.transparent');
      args.add(
        'flexibleSpace: Container(\n'
        '  decoration: BoxDecoration(\n'
        '    gradient: LinearGradient(\n'
        '      begin: Alignment.topLeft,\n'
        '      end: Alignment.bottomRight,\n'
        '      colors: [\n'
        '        Theme.of(context).colorScheme.primary,\n'
        '        $end,\n'
        '      ],\n'
        '    ),\n'
        '  ),\n'
        ')',
      );
    }
    final radius = (props['bottomRadius'] as num?)?.toDouble() ?? 0;
    if (radius > 0) {
      args.add(
        'shape: RoundedRectangleBorder(borderRadius: '
        'BorderRadius.vertical(bottom: Radius.circular(${_number(radius)})))',
      );
    }

    final leadingNodes = <CanvasNode>[];
    final actionNodes = <CanvasNode>[];
    for (final child in node.children) {
      final isLeading =
          child.type == 'icon' && child.properties['position'] == 'leading';
      (isLeading ? leadingNodes : actionNodes).add(child);
    }

    if (leadingNodes.isNotEmpty) {
      final items = leadingNodes
          .map(
            (child) => 'IconButton(onPressed: () {}, icon: ${_widgetInline(child)}),',
          )
          .join('\n');
      args.add(
        'leading: Row(\n  mainAxisSize: MainAxisSize.min,\n'
        '  children: [\n${_indent(items, '    ')}\n  ],\n)',
      );
      args.add('leadingWidth: ${56 * leadingNodes.length}');
    } else if (props['automaticallyImplyLeading'] == false) {
      args.add('automaticallyImplyLeading: false');
    }
    if (actionNodes.isNotEmpty) {
      final actions = actionNodes
          .map(
            (child) => 'IconButton(onPressed: () {}, icon: ${_widgetInline(child)}),',
          )
          .join('\n');
      args.add('actions: [\n${_indent(actions, '  ')}\n]');
    }
    return args;
  }

  static String _appBarWidget(
    String name,
    List<String> args, {
    List<String> extra = const [],
  }) {
    final all = [...extra, ...args];
    return '$name(\n${all.map((arg) => _indent('$arg,', '  ')).join('\n')}\n)';
  }

  /// Cuerpo de la pantalla: placeholder, un widget o columna con separación,
  /// envuelto en `Padding` cuando el editor aplica relleno.
  /// Código de un hijo del body, respetando su alineación horizontal.
  static String _bodyItem(CanvasNode node, {required bool single}) {
    final definition = standardCatalog[node.type];
    final widthSpec = definition?.propertyFor('widthMode');
    final widthMode = widthSpec?.coerce(node.properties['widthMode']);
    final raw = single ? _widgetBlock(node) : _widget(node);

    if (widthMode != 'fit' || definition == null) {
      if (!single) {
        return raw;
      }
      // El lienzo estira el hijo único a todo el ancho del cuerpo.
      return 'SizedBox(\n'
          '  width: double.infinity,\n'
          '  child: ${_inline('', raw, '  ')},\n'
          ')';
    }

    final alignSpec =
        definition.propertyFor('bodyAlignment') ??
        (node.type == 'icon' ? definition.propertyFor('alignment') : null);
    final value = alignSpec == null
        ? 'start'
        : alignSpec.coerce(node.properties[alignSpec.key]);
    final alignment = switch (value) {
      'center' => 'Alignment.center',
      'end' => 'Alignment.centerRight',
      _ => 'Alignment.centerLeft',
    };
    final inner = definition.acceptsChildren
        ? raw
        : 'IntrinsicWidth(\n  child: ${_inline('', raw, '  ')},\n)';
    return 'Align(\n'
        '  alignment: $alignment,\n'
        '  heightFactor: 1,\n'
        '  child: ${_inline('', inner, '  ')},\n'
        ')';
  }

  static String _bodyCode(
    List<CanvasNode> body, {
    Object? gap,
    Object? padding,
  }) {
    final gapValue = (gap as num?)?.toDouble() ?? 0;
    final paddingValue = (padding as num?)?.toDouble() ?? 0;

    String content;
    if (body.isEmpty) {
      content = _emptyStateCode;
    } else if (body.length == 1) {
      content = _bodyItem(body.first, single: true);
    } else {
      final children = body
          .map(
            (node) =>
                _indent('${_bodyItem(node, single: false)},', '    '),
          )
          .join('\n');
      content = 'Column(\n'
          '  spacing: ${_number(gapValue)},\n'
          '  crossAxisAlignment: CrossAxisAlignment.stretch,\n'
          '  children: [\n$children\n  ],\n)';
    }

    if (paddingValue > 0) {
      content = 'Padding(\n'
          '  padding: const EdgeInsets.all(${_number(paddingValue)}),\n'
          '  child: ${_inline('', content, '    ')},\n'
          ')';
    }
    return content;
  }

  static String _iconName(String? value) => switch (value) {
    'home' => 'Icons.home',
    'settings' => 'Icons.settings',
    'favorite' => 'Icons.favorite',
    'add' => 'Icons.add',
    'search' => 'Icons.search',
    'edit' => 'Icons.edit',
    'save' => 'Icons.save',
    'folder' => 'Icons.folder_outlined',
    'mail' => 'Icons.mail_outline',
    'person' => 'Icons.person',
    'arrow_back' => 'Icons.arrow_back',
    'menu' => 'Icons.menu',
    'close' => 'Icons.close',
    'more_vert' => 'Icons.more_vert',
    'arrow_forward' => 'Icons.arrow_forward',
    'chevron_right' => 'Icons.chevron_right',
    'check' => 'Icons.check_circle_outline',
    'lock' => 'Icons.lock_outline',
    'visibility' => 'Icons.visibility_outlined',
    'calendar' => 'Icons.calendar_today_outlined',
    'download' => 'Icons.download_outlined',
    _ => 'Icons.star',
  };

  /// Indenta todas las líneas de un bloque.
  static String _indent(String code, String indent) {
    return code
        .split('\n')
        .map((line) => line.isEmpty ? line : '$indent$line')
        .join('\n');
  }

  /// Expresión Dart de una alineación del catálogo.
  static String _alignmentName(String? value) => switch (value) {
    'topCenter' => 'Alignment.topCenter',
    'topRight' => 'Alignment.topRight',
    'centerLeft' => 'Alignment.centerLeft',
    'center' => 'Alignment.center',
    'centerRight' => 'Alignment.centerRight',
    'bottomLeft' => 'Alignment.bottomLeft',
    'bottomCenter' => 'Alignment.bottomCenter',
    'bottomRight' => 'Alignment.bottomRight',
    _ => 'Alignment.topLeft',
  };

  static String _escape(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll("'", r"\'");

  /// Código Dart de una acción de evento, o `null` si no hace nada.
  static String? _eventBody(
    String? action,
    String message, {
    String? targetScreen,
  }) {
    final text = _escape(message.isEmpty ? 'Acción ejecutada' : message);
    return switch (action) {
      'message' =>
        "ScaffoldMessenger.of(context).showSnackBar("
            "const SnackBar(content: Text('$text')));",
      'navigate' =>
        targetScreen == null || targetScreen.isEmpty
            ? null
            : "Navigator.pushNamed(context, '/screen/$targetScreen');",
      'drawer' => 'Scaffold.of(context).openDrawer();',
      'endDrawer' => 'Scaffold.of(context).openEndDrawer();',
      'back' => 'Navigator.of(context).maybePop();',
      _ => null,
    };
  }

  static String _number(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  static String _baseName(String fileName) {
    var base = fileName.trim();
    if (base.toLowerCase().endsWith('.dart')) {
      base = base.substring(0, base.length - 5);
    }
    base = base.replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '_');
    base = base.replaceAll(RegExp(r'_+'), '_');
    base = base.replaceAll(RegExp(r'^_+|_+$'), '');
    return base.isEmpty ? 'pantalla' : base.toLowerCase();
  }

  static String _pascalCase(String value) {
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();
  }
}
