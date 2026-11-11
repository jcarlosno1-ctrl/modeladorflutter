import 'package:flutter/material.dart';

import 'color_value.dart';
import 'component_catalog.dart';
import 'property_spec.dart';
import 'widget_definition.dart';

/// Acciones disponibles para los eventos de los controles.
const _eventChoices = [
  PropertyChoice('none', 'Ninguna'),
  PropertyChoice('message', 'Mostrar mensaje'),
  PropertyChoice('drawer', 'Abrir menú'),
  PropertyChoice('endDrawer', 'Abrir menú derecho'),
  PropertyChoice('back', 'Volver atrás'),
];

/// Alineaciones compartidas por Stack y Align.
const _alignmentChoices = [
  PropertyChoice('topLeft', 'Superior izquierda'),
  PropertyChoice('topCenter', 'Superior centro'),
  PropertyChoice('topRight', 'Superior derecha'),
  PropertyChoice('centerLeft', 'Centro izquierda'),
  PropertyChoice('center', 'Centro'),
  PropertyChoice('centerRight', 'Centro derecha'),
  PropertyChoice('bottomLeft', 'Inferior izquierda'),
  PropertyChoice('bottomCenter', 'Inferior centro'),
  PropertyChoice('bottomRight', 'Inferior derecha'),
];

Alignment _alignmentFor(String value) => switch (value) {
  'topCenter' => Alignment.topCenter,
  'topRight' => Alignment.topRight,
  'centerLeft' => Alignment.centerLeft,
  'center' => Alignment.center,
  'centerRight' => Alignment.centerRight,
  'bottomLeft' => Alignment.bottomLeft,
  'bottomCenter' => Alignment.bottomCenter,
  'bottomRight' => Alignment.bottomRight,
  _ => Alignment.topLeft,
};

/// Acción de vista previa: muestra un SnackBar sin tocar el editor.
VoidCallback? _previewAction(BuildContext context, Props props, String key) {
  final action = props.choice(key);
  if (action.isEmpty || action == 'none') {
    return null;
  }
  final message = props.text('eventMessage');
  final label = switch (action) {
    'drawer' => 'Abrir menú',
    'endDrawer' => 'Abrir menú derecho',
    'back' => 'Volver atrás',
    _ => message.isEmpty ? 'Acción ejecutada' : message,
  };

  return () => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(label)),
  );
}

/// Catálogo estándar (solo Flutter/Dart por ahora).
///
/// Agregar un widget = agregar una [WidgetDefinition] aquí. No hay forma de
/// que un usuario cree componentes arbitrarios: el JSON solo puede referenciar
/// estos `type`.
final ComponentCatalog standardCatalog = ComponentCatalog(_definitions);

final List<WidgetDefinition> _definitions = [
  // --------------------------------------------------------------- pantalla
  WidgetDefinition(
    type: 'screen',
    label: 'Pantalla',
    category: ComponentCategory.layout,
    icon: Icons.smartphone,
    acceptsChildren: true,
    insertable: false,
    flutterClass: 'Scaffold',
    properties: const [
      // El dispositivo se elige desde la barra del lienzo; se mantiene en el
      // modelo (validación incluida) pero no se duplica en el panel.
      PropertySpec.choice(
        'device',
        'Dispositivo',
        hidden: true,
        choices: [
          PropertyChoice('phone', 'Móvil (390×844)'),
          PropertyChoice('tablet', 'Tablet (768×1024)'),
          PropertyChoice('desktop', 'Escritorio (1280×800)'),
          PropertyChoice('web', 'Web (1440×900)'),
        ],
        defaultValue: 'phone',
      ),
      PropertySpec.boolean(
        'scroll',
        'Scroll interno',
        group: 'Comportamiento',
        hint: 'El cuerpo se desplaza si el contenido no entra.',
        defaultValue: true,
      ),
      PropertySpec.color(
        'background',
        'Color de fondo',
        group: 'Colores',
        hint: 'Fondo del Scaffold (detrás del contenido).',
        choices: [
          PropertyChoice('surface', 'Superficie'),
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('secondary', 'Secundario'),
          PropertyChoice('tertiary', 'Terciario'),
        ],
      ),
      PropertySpec.boolean(
        'resizeToAvoidBottomInset',
        'Ajustar con el teclado',
        group: 'Comportamiento',
        hint: 'El body se encoge cuando aparece el teclado.',
        defaultValue: true,
      ),
      PropertySpec.number(
        'padding',
        'Relleno del body (editor)',
        group: 'Diseño',
        suffix: 'px',
        hint: 'Espacio interior entre el borde y el contenido.',
        defaultValue: 16,
        min: 0,
        max: 48,
      ),
      PropertySpec.number(
        'gap',
        'Separación entre hijos (editor)',
        group: 'Diseño',
        suffix: 'px',
        hint: 'Hueco vertical entre los hijos del body.',
        defaultValue: 12,
        min: 0,
        max: 48,
      ),
      PropertySpec.boolean(
        'responsive',
        'Diseño adaptable',
        group: 'Diseño',
        hint:
            'Activado: el contenido ocupa todo el ancho. Desactivado: se '
            'centra con un ancho máximo y se ve bien en pantallas grandes.',
        defaultValue: true,
      ),
      PropertySpec.number(
        'contentWidth',
        'Ancho máximo del contenido',
        group: 'Diseño',
        hint: 'Solo se aplica cuando el diseño adaptable está desactivado.',
        suffix: 'px',
        min: 280,
        max: 900,
        step: 10,
        integer: true,
        defaultValue: 480,
      ),
    ],
    builder: (context, props, children) {
      final content = children.isEmpty
          ? const _EmptySlot()
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _spaced(
                children,
                props.number('gap'),
                horizontal: false,
              ),
            );

      return Padding(
        padding: EdgeInsets.all(props.number('padding')),
        child: content,
      );
    },
  ),

  // ---------------------------------------------------------------- básicos
  WidgetDefinition(
    type: 'text',
    label: 'Texto',
    category: ComponentCategory.basic,
    icon: Icons.text_fields,
    properties: const [
      PropertySpec.text('text', 'Texto', defaultValue: 'Texto de ejemplo'),
      PropertySpec.choice(
        'style',
        'Estilo',
        choices: [
          PropertyChoice('body', 'Cuerpo'),
          PropertyChoice('title', 'Título'),
          PropertyChoice('headline', 'Encabezado'),
        ],
        defaultValue: 'body',
      ),
      PropertySpec.choice(
        'align',
        'Alineación',
        choices: [
          PropertyChoice('left', 'Izquierda'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('right', 'Derecha'),
        ],
        defaultValue: 'left',
      ),
      PropertySpec.number(
        'fontSize',
        'Tamaño',
        group: 'Tipografía',
        defaultValue: 0,
        min: 0,
        max: 72,
        integer: true,
        suffix: 'px',
        hint: '0 = tamaño del estilo elegido.',
      ),
      PropertySpec.color(
        'color',
        'Color',
        group: 'Tipografía',
        choices: [
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('onSurfaceVariant', 'Texto secundario'),
          PropertyChoice('primary', 'Primario suave'),
        ],
        defaultValue: 'onSurface',
      ),
      PropertySpec.choice(
        'fontWeight',
        'Grosor',
        group: 'Tipografía',
        choices: [
          PropertyChoice('inherit', 'Heredar'),
          PropertyChoice('normal', 'Regular'),
          PropertyChoice('w500', 'Medium'),
          PropertyChoice('w600', 'Semibold'),
          PropertyChoice('bold', 'Bold'),
          PropertyChoice('w800', 'Extra bold'),
        ],
        defaultValue: 'inherit',
      ),
      PropertySpec.number(
        'lineHeight',
        'Altura de línea',
        group: 'Tipografía',
        defaultValue: 0,
        min: 0,
        max: 3,
        step: 0.1,
        hint: '0 = automática.',
      ),
      PropertySpec.number(
        'letterSpacing',
        'Espaciado entre letras',
        group: 'Tipografía',
        defaultValue: 0,
        min: -2,
        max: 10,
        step: 0.1,
        suffix: 'px',
      ),
      PropertySpec.choice(
        'fontStyle',
        'Estilo de fuente',
        group: 'Tipografía',
        choices: [
          PropertyChoice('inherit', 'Heredar'),
          PropertyChoice('normal', 'Normal'),
          PropertyChoice('italic', 'Cursiva'),
        ],
        defaultValue: 'inherit',
      ),
      PropertySpec.choice(
        'decoration',
        'Decoración',
        group: 'Tipografía',
        choices: [
          PropertyChoice('none', 'Ninguna'),
          PropertyChoice('underline', 'Subrayado'),
          PropertyChoice('lineThrough', 'Tachado'),
          PropertyChoice('overline', 'Sobrelineado'),
        ],
        defaultValue: 'none',
      ),
      PropertySpec.number(
        'maxLines',
        'Máximo de líneas',
        group: 'Alineación',
        defaultValue: 0,
        min: 0,
        max: 10,
        integer: true,
        hint: '0 = sin límite.',
      ),
      PropertySpec.choice(
        'overflow',
        'Desbordamiento',
        group: 'Alineación',
        choices: [
          PropertyChoice('ellipsis', 'Puntos suspensivos'),
          PropertyChoice('clip', 'Recortar'),
          PropertyChoice('fade', 'Desvanecer'),
          PropertyChoice('visible', 'Visible'),
        ],
        defaultValue: 'ellipsis',
      ),
      PropertySpec.text(
        'semanticLabel',
        'Descripción accesible',
        group: 'Accesibilidad',
        hint: 'Lo que lee el lector de pantalla.',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      var style =
          _textStyle(context, props.choice('style')) ?? const TextStyle();
      if (props.number('fontSize') > 0) {
        style = style.copyWith(fontSize: props.number('fontSize'));
      }
      final weight = _fontWeight(props.choice('fontWeight'));
      if (weight != null) {
        style = style.copyWith(fontWeight: weight);
      }
      if (props.number('lineHeight') > 0) {
        style = style.copyWith(height: props.number('lineHeight'));
      }
      if (props.number('letterSpacing') != 0) {
        style = style.copyWith(
          letterSpacing: props.number('letterSpacing'),
        );
      }
      if (props.choice('fontStyle') == 'italic') {
        style = style.copyWith(fontStyle: FontStyle.italic);
      } else if (props.choice('fontStyle') == 'normal') {
        style = style.copyWith(fontStyle: FontStyle.normal);
      }
      final decoration = _textDecoration(props.choice('decoration'));
      if (decoration != null) {
        style = style.copyWith(decoration: decoration);
      }
      final maxLines = props.number('maxLines').round();
      final semantic = props.text('semanticLabel');

      return Text(
        props.text('text'),
        textAlign: _textAlign(props.choice('align')),
        maxLines: maxLines == 0 ? null : maxLines,
        overflow: _textOverflow(props.choice('overflow')),
        semanticsLabel: semantic.isEmpty ? null : semantic,
        style: style.copyWith(
          color: colorForValue(props.choice('color'), scheme),
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'button',
    label: 'Botón',
    category: ComponentCategory.basic,
    icon: Icons.smart_button_outlined,
    properties: const [
      PropertySpec.text('label', 'Etiqueta', defaultValue: 'Continuar'),
      PropertySpec.choice(
        'variant',
        'Estilo',
        choices: [
          PropertyChoice('filled', 'Relleno'),
          PropertyChoice('outlined', 'Contorno'),
          PropertyChoice('text', 'Texto'),
        ],
        defaultValue: 'filled',
      ),
      PropertySpec.boolean('enabled', 'Habilitado', defaultValue: true),
      PropertySpec.color(
        'backgroundColor',
        'Color de fondo',
        group: 'Colores',
        choices: [
          PropertyChoice('primarySolid', 'Primario'),
          PropertyChoice('secondary', 'Secundario suave'),
          PropertyChoice('tertiary', 'Terciario suave'),
          PropertyChoice('high', 'Superficie alta'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.color(
        'foregroundColor',
        'Color del texto',
        group: 'Colores',
        choices: [
          PropertyChoice('onPrimarySolid', 'Sobre primario'),
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('primarySolid', 'Primario'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.number(
        'borderRadius',
        'Radio',
        group: 'Forma',
        defaultValue: 0,
        min: 0,
        max: 40,
        integer: true,
        suffix: 'px',
        hint: '0 = radio del tema.',
      ),
      PropertySpec.number(
        'padding',
        'Relleno',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 32,
        integer: true,
        suffix: 'px',
        hint: '0 = relleno del tema.',
      ),
      PropertySpec.number(
        'fontSize',
        'Tamaño del texto',
        group: 'Tipografía',
        defaultValue: 0,
        min: 0,
        max: 24,
        integer: true,
        suffix: 'px',
        hint: '0 = tamaño del tema.',
      ),
      PropertySpec.choice(
        'icon',
        'Icono',
        group: 'Contenido',
        defaultValue: '',
        choices: [
          PropertyChoice('', 'Ninguno'),
          PropertyChoice('add', 'Agregar'),
          PropertyChoice('arrow_forward', 'Avanzar'),
          PropertyChoice('check', 'Check'),
          PropertyChoice('download', 'Descargar'),
          PropertyChoice('search', 'Buscar'),
        ],
      ),
      PropertySpec.boolean(
        'fullWidth',
        'Ancho completo',
        group: 'Dimensiones',
      ),
      PropertySpec.choice(
        'onTap',
        'Al tocar',
        group: 'Eventos',
        hint: 'Acción que se ejecuta al presionar el botón.',
        choices: _eventChoices,
        defaultValue: 'none',
      ),
      PropertySpec.text(
        'eventMessage',
        'Mensaje del evento',
        group: 'Eventos',
        hint: 'Texto del SnackBar cuando la acción es Mensaje.',
        defaultValue: 'Acción ejecutada',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final action = _previewAction(context, props, 'onTap');
      final onPressed = props.flag('enabled') ? (action ?? () {}) : null;
      final background = props.choice('backgroundColor');
      final foreground = props.choice('foregroundColor');
      final radius = props.number('borderRadius');
      final padding = props.number('padding');
      final fontSize = props.number('fontSize');
      final icon = props.choice('icon');

      var style = const ButtonStyle();
      if (background.isNotEmpty) {
        style = style.copyWith(
          backgroundColor: WidgetStatePropertyAll(
            colorForValue(background, scheme),
          ),
        );
      }
      if (foreground.isNotEmpty) {
        style = style.copyWith(
          foregroundColor: WidgetStatePropertyAll(
            colorForValue(foreground, scheme),
          ),
        );
      }
      if (radius > 0) {
        style = style.copyWith(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        );
      }
      if (padding > 0) {
        style = style.copyWith(
          padding: WidgetStatePropertyAll(EdgeInsets.all(padding)),
        );
      }
      if (fontSize > 0) {
        style = style.copyWith(
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: fontSize)),
        );
      }

      final label = Text(props.text('label'));
      final child = icon.isEmpty
          ? label
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconDataFor(icon), size: 18),
                const SizedBox(width: 8),
                label,
              ],
            );

      final button = switch (props.choice('variant')) {
        'outlined' => OutlinedButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
        'text' => TextButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
        _ => FilledButton(
          onPressed: onPressed,
          style: style,
          child: child,
        ),
      };

      return props.flag('fullWidth')
          ? SizedBox(width: double.infinity, child: button)
          : button;
    },
  ),
  WidgetDefinition(
    type: 'icon',
    label: 'Ícono',
    category: ComponentCategory.basic,
    icon: Icons.star_outline,
    properties: const [
      PropertySpec.choice(
        'icon',
        'Ícono',
        choices: [
          PropertyChoice('star', 'Estrella'),
          PropertyChoice('home', 'Inicio'),
          PropertyChoice('settings', 'Ajustes'),
          PropertyChoice('favorite', 'Favorito'),
          PropertyChoice('add', 'Agregar'),
          PropertyChoice('search', 'Buscar'),
          PropertyChoice('arrow_back', 'Atrás'),
          PropertyChoice('menu', 'Menú'),
          PropertyChoice('close', 'Cerrar'),
          PropertyChoice('more_vert', 'Más'),
          PropertyChoice('person', 'Perfil'),
          PropertyChoice('folder', 'Carpeta'),
          PropertyChoice('mail', 'Correo'),
        ],
        defaultValue: 'star',
      ),
      PropertySpec.number(
        'size',
        'Tamaño',
        group: 'Diseño',
        suffix: 'px',
        defaultValue: 24,
        min: 12,
        max: 96,
      ),
      PropertySpec.choice(
        'position',
        'Ubicación en la barra',
        group: 'Barra superior',
        choices: [
          PropertyChoice('actions', 'Derecha (acciones)'),
          PropertyChoice('leading', 'Izquierda (leading)'),
        ],
        defaultValue: 'actions',
      ),
      PropertySpec.choice(
        'color',
        'Color',
        group: 'Colores',
        choices: [
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('onPrimary', 'Sobre primario'),
          PropertyChoice('inherit', 'Heredar del contenedor'),
        ],
        defaultValue: 'primary',
      ),
      PropertySpec.text(
        'label',
        'Etiqueta en la barra',
        group: 'Barra inferior',
        hint: 'Se usa como etiqueta del ítem en la barra inferior.',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final color = switch (props.choice('color')) {
        'inherit' => IconTheme.of(context).color,
        'onSurface' => scheme.onSurface,
        'onPrimary' => scheme.onPrimary,
        _ => scheme.primary,
      };
      return Icon(
        iconDataFor(props.choice('icon')),
        size: props.number('size'),
        color: color,
      );
    },
  ),
  WidgetDefinition(
    type: 'progress',
    label: 'Progreso',
    category: ComponentCategory.basic,
    icon: Icons.linear_scale,
    properties: const [
      PropertySpec.number('value', 'Valor', defaultValue: 0.6, min: 0, max: 1),
      PropertySpec.choice(
        'style',
        'Estilo',
        choices: [
          PropertyChoice('linear', 'Lineal'),
          PropertyChoice('circular', 'Circular'),
        ],
        defaultValue: 'linear',
      ),
      PropertySpec.boolean(
        'indeterminate',
        'Indeterminado',
        group: 'Estado',
        hint: 'Animación continua sin valor fijo.',
      ),
      PropertySpec.color(
        'color',
        'Color',
        group: 'Estilo',
        choices: [
          PropertyChoice('primarySolid', 'Primario'),
          PropertyChoice('tertiary', 'Terciario suave'),
          PropertyChoice('onSurfaceVariant', 'Texto secundario'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.color(
        'backgroundColor',
        'Color de fondo',
        group: 'Estilo',
        choices: [
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.number(
        'strokeWidth',
        'Grosor',
        group: 'Dimensiones',
        defaultValue: 4,
        min: 1,
        max: 12,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'borderRadius',
        'Radio',
        group: 'Forma',
        defaultValue: 0,
        min: 0,
        max: 12,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final value = props.number('value').clamp(0.0, 1.0);
      final indeterminate = props.flag('indeterminate');
      final color = props.choice('color');
      final background = props.choice('backgroundColor');
      final stroke = props.number('strokeWidth');
      final radius = props.number('borderRadius');
      final resolved = color.isEmpty ? null : colorForValue(color, scheme);
      final resolvedBackground = background.isEmpty
          ? null
          : colorForValue(background, scheme);

      if (props.choice('style') == 'circular') {
        return SizedBox(
          width: 32 + stroke,
          height: 32 + stroke,
          child: CircularProgressIndicator(
            value: indeterminate ? null : value,
            strokeWidth: stroke,
            color: resolved,
            backgroundColor: resolvedBackground,
          ),
        );
      }
      return LinearProgressIndicator(
        value: indeterminate ? null : value,
        minHeight: stroke,
        color: resolved,
        backgroundColor: resolvedBackground,
        borderRadius: BorderRadius.circular(radius),
      );
    },
  ),
  WidgetDefinition(
    type: 'listTile',
    label: 'Fila de lista',
    category: ComponentCategory.material,
    icon: Icons.view_list,
    properties: const [
      PropertySpec.text('title', 'Título', defaultValue: 'Elemento'),
      PropertySpec.text(
        'subtitle',
        'Subtítulo',
        defaultValue: 'Descripción breve',
      ),
      PropertySpec.choice(
        'icon',
        'Ícono',
        choices: [
          PropertyChoice('person', 'Persona'),
          PropertyChoice('folder', 'Carpeta'),
          PropertyChoice('mail', 'Correo'),
          PropertyChoice('settings', 'Ajustes'),
        ],
        defaultValue: 'person',
      ),
      PropertySpec.boolean('showChevron', 'Mostrar flecha', defaultValue: true),
      PropertySpec.color(
        'leadingIconColor',
        'Color del ícono',
        group: 'Estilo',
        choices: [
          PropertyChoice('primarySolid', 'Primario'),
          PropertyChoice('onSurfaceVariant', 'Texto secundario'),
          PropertyChoice('tertiary', 'Terciario suave'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.choice(
        'trailingIcon',
        'Ícono final',
        group: 'Contenido',
        defaultValue: '',
        choices: [
          PropertyChoice('', 'Ninguno'),
          PropertyChoice('chevron_right', 'Flecha'),
          PropertyChoice('arrow_forward', 'Avanzar'),
          PropertyChoice('more_vert', 'Más'),
          PropertyChoice('favorite', 'Corazón'),
          PropertyChoice('check', 'Check'),
        ],
      ),
      PropertySpec.boolean(
        'selected',
        'Seleccionada',
        group: 'Estado',
      ),
      PropertySpec.boolean('dense', 'Compacta', group: 'Dimensiones'),
      PropertySpec.number(
        'shapeRadius',
        'Radio',
        group: 'Forma',
        defaultValue: 0,
        min: 0,
        max: 28,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'tileColor',
        'Color de fondo',
        group: 'Estilo',
        choices: [
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('primary', 'Primario suave'),
        ],
        hint: 'Vacío = color del tema.',
      ),
    ],
    builder: (context, props, children) {
      const icons = {
        'folder': Icons.folder_outlined,
        'mail': Icons.mail_outline,
        'settings': Icons.settings_outlined,
        'person': Icons.person_outline,
      };
      final scheme = Theme.of(context).colorScheme;
      final leadingColor = props.choice('leadingIconColor');
      final trailing = props.choice('trailingIcon');
      final radius = props.number('shapeRadius');
      final tileColor = props.choice('tileColor');

      return ListTile(
        leading: Icon(
          icons[props.choice('icon')] ?? Icons.person_outline,
          color: leadingColor.isEmpty
              ? null
              : colorForValue(leadingColor, scheme),
        ),
        title: Text(props.text('title')),
        subtitle: Text(props.text('subtitle')),
        trailing: trailing.isNotEmpty
            ? Icon(iconDataFor(trailing), size: 20)
            : props.flag('showChevron')
            ? const Icon(Icons.chevron_right, size: 20)
            : null,
        selected: props.flag('selected'),
        dense: props.flag('dense'),
        tileColor: tileColor.isEmpty
            ? null
            : colorForValue(tileColor, scheme),
        shape: radius > 0
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              )
            : null,
        contentPadding: EdgeInsets.zero,
      );
    },
  ),
  WidgetDefinition(
    type: 'divider',
    label: 'Separador',
    category: ComponentCategory.basic,
    icon: Icons.horizontal_rule,
    properties: const [
      PropertySpec.number(
        'thickness',
        'Grosor',
        group: 'Estilo',
        defaultValue: 1,
        min: 0.5,
        max: 8,
      ),
      PropertySpec.number(
        'height',
        'Alto',
        group: 'Dimensiones',
        defaultValue: 16,
        min: 0,
        max: 64,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'color',
        'Color',
        group: 'Estilo',
        choices: [
          PropertyChoice('outline', 'Borde del tema'),
          PropertyChoice('onSurfaceVariant', 'Texto secundario'),
          PropertyChoice('primarySolid', 'Primario'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.number(
        'indent',
        'Margen inicial',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 64,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'endIndent',
        'Margen final',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 64,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final color = props.choice('color');
      return Divider(
        thickness: props.number('thickness'),
        height: props.number('height'),
        color: color.isEmpty ? null : colorForValue(color, scheme),
        indent: props.number('indent'),
        endIndent: props.number('endIndent'),
      );
    },
  ),

  // ----------------------------------------------------------------- layout
  WidgetDefinition(
    type: 'column',
    label: 'Columna',
    category: ComponentCategory.layout,
    icon: Icons.view_agenda_outlined,
    acceptsChildren: true,
    properties: const [
      PropertySpec.choice(
        'align',
        'Alineación',
        choices: [
          PropertyChoice('start', 'Inicio'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('end', 'Fin'),
          PropertyChoice('spaceBetween', 'Espaciado'),
        ],
        defaultValue: 'start',
      ),
      PropertySpec.number('gap', 'Separación', defaultValue: 8, min: 0, max: 64),
      PropertySpec.choice(
        'crossAlign',
        'Alineación transversal',
        group: 'Alineación',
        choices: [
          PropertyChoice('start', 'Inicio'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('end', 'Fin'),
          PropertyChoice('stretch', 'Estirar'),
        ],
        defaultValue: 'start',
      ),
    ],
    builder: (context, props, children) {
      if (children.isEmpty) {
        return const _EmptySlot();
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: _mainAxis(props.choice('align')),
        crossAxisAlignment: _crossAxis(props.choice('crossAlign')),
        children: _spaced(children, props.number('gap'), horizontal: false),
      );
    },
  ),
  WidgetDefinition(
    type: 'row',
    label: 'Fila',
    category: ComponentCategory.layout,
    icon: Icons.view_column_outlined,
    acceptsChildren: true,
    properties: const [
      PropertySpec.number('gap', 'Separación', defaultValue: 8, min: 0, max: 64),
      PropertySpec.choice(
        'align',
        'Alineación principal',
        group: 'Alineación',
        choices: [
          PropertyChoice('start', 'Inicio'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('end', 'Fin'),
          PropertyChoice('spaceBetween', 'Espaciado'),
        ],
        defaultValue: 'start',
      ),
      PropertySpec.choice(
        'crossAlign',
        'Alineación transversal',
        group: 'Alineación',
        choices: [
          PropertyChoice('start', 'Inicio'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('end', 'Fin'),
          PropertyChoice('stretch', 'Estirar'),
        ],
        defaultValue: 'start',
      ),
    ],
    builder: (context, props, children) {
      if (children.isEmpty) {
        return const _EmptySlot();
      }
      // Cada hijo ocupa una fracción igual del ancho: así dos campos se
      // colocan a la misma altura y ninguno queda sin ancho acotado.
      final gap = props.number('gap');
      return Row(
        mainAxisAlignment: _mainAxis(props.choice('align')),
        crossAxisAlignment: _crossAxis(props.choice('crossAlign')),
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) SizedBox(width: gap),
            Expanded(child: children[index]),
          ],
        ],
      );
    },
  ),
  WidgetDefinition(
    type: 'container',
    label: 'Contenedor',
    category: ComponentCategory.layout,
    icon: Icons.crop_square,
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'padding',
        'Relleno',
        defaultValue: 16,
        min: 0,
        max: 64,
      ),
      PropertySpec.number(
        'radius',
        'Radio',
        defaultValue: 12,
        min: 0,
        max: 40,
      ),
      PropertySpec.color(
        'backgroundColor',
        'Fondo',
        group: 'Estilo',
        choices: [
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('surface', 'Superficie'),
          PropertyChoice('primary', 'Primario suave'),
        ],
        defaultValue: 'low',
      ),
      PropertySpec.boolean(
        'gradient',
        'Gradiente',
        group: 'Estilo',
        hint: 'Degradado del fondo al color final.',
      ),
      PropertySpec.color(
        'gradientColor',
        'Color final del gradiente',
        group: 'Estilo',
        choices: [
          PropertyChoice('secondary', 'Secundario'),
          PropertyChoice('tertiary', 'Terciario'),
          PropertyChoice('high', 'Superficie alta'),
        ],
        defaultValue: 'secondary',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final background = colorForValue(
        props.choice('backgroundColor'),
        scheme,
      );
      final gradient = props.flag('gradient');
      return Container(
        padding: EdgeInsets.all(props.number('padding')),
        decoration: BoxDecoration(
          color: gradient ? null : background,
          gradient: gradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    background,
                    colorForValue(props.choice('gradientColor'), scheme),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(props.number('radius')),
        ),
        child: children.isEmpty
            ? const _EmptySlot()
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
      );
    },
  ),
  WidgetDefinition(
    type: 'center',
    label: 'Centrar',
    category: ComponentCategory.layout,
    icon: Icons.filter_center_focus,
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'widthFactor',
        'Factor de ancho',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 4,
        step: 0.1,
        hint: '0 = ocupa todo el ancho.',
      ),
      PropertySpec.number(
        'heightFactor',
        'Factor de alto',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 4,
        step: 0.1,
        hint: '0 = ocupa todo el alto.',
      ),
    ],
    builder: (context, props, children) {
      final width = props.number('widthFactor');
      final height = props.number('heightFactor');
      return Center(
        widthFactor: width == 0 ? null : width,
        heightFactor: height == 0 ? null : height,
        child: children.isEmpty
            ? const _EmptySlot()
            : Column(mainAxisSize: MainAxisSize.min, children: children),
      );
    },
  ),
  WidgetDefinition(
    type: 'padding',
    label: 'Relleno',
    category: ComponentCategory.layout,
    icon: Icons.padding,
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'padding',
        'Relleno',
        defaultValue: 16,
        min: 0,
        max: 64,
      ),
    ],
    builder: (context, props, children) {
      return Padding(
        padding: EdgeInsets.all(props.number('padding')),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'card',
    label: 'Tarjeta',
    category: ComponentCategory.material,
    icon: Icons.crop_16_9,
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'elevation',
        'Elevación',
        group: 'Estilo',
        defaultValue: 0,
        min: 0,
        max: 12,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'color',
        'Fondo',
        group: 'Colores',
        choices: [
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('surface', 'Superficie'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('primary', 'Primario suave'),
        ],
        defaultValue: 'low',
      ),
      PropertySpec.number(
        'radius',
        'Radio',
        group: 'Forma',
        defaultValue: 12,
        min: 0,
        max: 40,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'margin',
        'Margen',
        group: 'Dimensiones',
        defaultValue: 4,
        min: 0,
        max: 32,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'padding',
        'Relleno interior',
        group: 'Dimensiones',
        defaultValue: 8,
        min: 0,
        max: 32,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'borderWidth',
        'Grosor del borde',
        group: 'Forma',
        defaultValue: 0,
        min: 0,
        max: 4,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'borderColor',
        'Color del borde',
        group: 'Forma',
        choices: [
          PropertyChoice('outline', 'Borde del tema'),
          PropertyChoice('primarySolid', 'Primario'),
        ],
        defaultValue: 'outline',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final radius = props.number('radius');
      final borderWidth = props.number('borderWidth');
      return Card(
        elevation: props.number('elevation'),
        color: colorForValue(props.choice('color'), scheme),
        margin: EdgeInsets.all(props.number('margin')),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: borderWidth > 0
              ? BorderSide(
                  color: colorForValue(props.choice('borderColor'), scheme),
                  width: borderWidth,
                )
              : BorderSide.none,
        ),
        child: Padding(
          padding: EdgeInsets.all(props.number('padding')),
          child: children.isEmpty
              ? const _EmptySlot()
              : Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );
    },
  ),

  // ------------------------------------------------------------- navegación
  WidgetDefinition(
    type: 'appBar',
    label: 'Barra superior',
    category: ComponentCategory.navigation,
    icon: Icons.web_asset,
    slot: ComponentSlot.top,
    flutterClass: 'AppBar',
    acceptsChildren: true,
    properties: const [
      PropertySpec.boolean(
        'visible',
        'Visible',
        group: 'Barra superior',
        hint: 'Si lo apagás, la barra no se dibuja ni se exporta.',
        defaultValue: true,
      ),
      PropertySpec.text(
        'title',
        'Título',
        group: 'Barra superior',
        defaultValue: 'Mi pantalla',
      ),
      PropertySpec.boolean(
        'centerTitle',
        'Centrar título',
        group: 'Barra superior',
        hint: 'El título se centra en la barra.',
      ),
      PropertySpec.boolean(
        'automaticallyImplyLeading',
        'Mostrar atrás automático',
        group: 'Barra superior',
        hint: 'Muestra la flecha cuando se puede volver.',
        defaultValue: true,
      ),
      PropertySpec.number(
        'bottomRadius',
        'Esquinas inferiores',
        group: 'Diseño',
        suffix: 'px',
        hint: 'Redondea las esquinas de abajo de la barra.',
        defaultValue: 0,
        min: 0,
        max: 32,
      ),
      PropertySpec.boolean(
        'hideOnScroll',
        'Ocultar al desplazar',
        group: 'Comportamiento',
        hint: 'La barra se pliega al bajar el contenido.',
      ),
      PropertySpec.number(
        'elevation',
        'Elevación',
        group: 'Diseño',
        suffix: 'px',
        hint: 'Sombra de la barra en reposo.',
        defaultValue: 0,
        min: 0,
        max: 24,
      ),
      PropertySpec.number(
        'scrolledUnderElevation',
        'Elevación al desplazar',
        group: 'Diseño',
        suffix: 'px',
        hint: 'Sombra cuando el contenido pasa por debajo.',
        defaultValue: 3,
        min: 0,
        max: 24,
      ),
      PropertySpec.number(
        'toolbarHeight',
        'Alto de la barra',
        group: 'Diseño',
        suffix: 'px',
        defaultValue: 56,
        min: 40,
        max: 96,
      ),
      PropertySpec.color(
        'backgroundColor',
        'Color de fondo',
        group: 'Colores',
        choices: [
          PropertyChoice('surface', 'Superficie'),
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('tertiary', 'Terciario'),
        ],
      ),
      PropertySpec.color(
        'foregroundColor',
        'Color de texto e íconos',
        group: 'Colores',
        hint: 'Aplica al título, la flecha y las acciones.',
        choices: [
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('onPrimary', 'Sobre primario'),
          PropertyChoice('onPrimaryContainer', 'Sobre primario suave'),
        ],
      ),
      PropertySpec.boolean(
        'gradient',
        'Gradiente',
        group: 'Colores',
        hint: 'Degradado de primario al color final.',
      ),
      PropertySpec.color(
        'gradientColor',
        'Color final del gradiente',
        group: 'Colores',
        choices: [
          PropertyChoice('secondary', 'Secundario'),
          PropertyChoice('tertiary', 'Terciario'),
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('high', 'Superficie alta'),
        ],
      ),
    ],
    builder: (context, props, children) =>
        buildAppBarWidget(context, props, actions: children),
  ),
  WidgetDefinition(
    type: 'tabs',
    label: 'Barra de pestañas',
    category: ComponentCategory.navigation,
    icon: Icons.tab,
    flutterClass: 'TabBar',
    properties: const [
      PropertySpec.choice(
        'count',
        'Cantidad',
        group: 'Pestañas',
        choices: [
          PropertyChoice('2', '2'),
          PropertyChoice('3', '3'),
          PropertyChoice('4', '4'),
          PropertyChoice('5', '5'),
        ],
        defaultValue: '3',
      ),
      PropertySpec.number(
        'selected',
        'Seleccionada',
        group: 'Pestañas',
        defaultValue: 0,
        min: 0,
        max: 4,
      ),
    ],
    builder: (context, props, children) {
      const labels = ['Uno', 'Dos', 'Tres', 'Cuatro', 'Cinco'];
      final count = int.tryParse(props.choice('count')) ?? 3;
      final selected = props.number('selected').round().clamp(0, count - 1);

      return DefaultTabController(
        length: count,
        initialIndex: selected,
        child: SizedBox(
          height: 48,
          child: TabBar(
            tabs: [
              for (var index = 0; index < count; index++)
                Tab(text: labels[index]),
            ],
          ),
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'navItem',
    label: 'Ítem de barra (heredado)',
    category: ComponentCategory.navigation,
    icon: Icons.tab_unselected,
    flutterClass: 'BottomNavigationBarItem',
    insertable: false,
    properties: const [
      PropertySpec.choice(
        'icon',
        'Ícono',
        choices: [
          PropertyChoice('home', 'Inicio'),
          PropertyChoice('search', 'Buscar'),
          PropertyChoice('favorite', 'Favorito'),
          PropertyChoice('settings', 'Ajustes'),
          PropertyChoice('person', 'Perfil'),
          PropertyChoice('add', 'Agregar'),
          PropertyChoice('mail', 'Correo'),
          PropertyChoice('folder', 'Carpeta'),
        ],
        defaultValue: 'home',
      ),
      PropertySpec.text('label', 'Etiqueta', defaultValue: 'Inicio'),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconDataFor(props.choice('icon')),
              size: 20,
              color: scheme.primary,
            ),
            const SizedBox(width: 6),
            Text(props.text('label'), style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'bottomNav',
    label: 'Barra inferior',
    category: ComponentCategory.navigation,
    icon: Icons.space_dashboard_outlined,
    slot: ComponentSlot.bottom,
    flutterClass: 'BottomNavigationBar',
    acceptsChildren: true,
    properties: const [
      PropertySpec.boolean(
        'visible',
        'Visible',
        group: 'Barra inferior',
        hint: 'Si lo apagás, la barra no se dibuja ni se exporta.',
        defaultValue: true,
      ),
      PropertySpec.number(
        'selected',
        'Seleccionado',
        group: 'Barra inferior',
        hint: 'Índice del ítem resaltado.',
        defaultValue: 0,
        min: 0,
        max: 4,
      ),
      PropertySpec.choice(
        'type',
        'Tipo',
        group: 'Barra inferior',
        choices: [
          PropertyChoice('fixed', 'Fijo'),
          PropertyChoice('shifting', 'Desplazable'),
        ],
        defaultValue: 'fixed',
      ),
      PropertySpec.color(
        'backgroundColor',
        'Color de fondo',
        group: 'Colores',
        choices: [
          PropertyChoice('surface', 'Superficie'),
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('primary', 'Primario'),
        ],
      ),
      PropertySpec.color(
        'selectedItemColor',
        'Color del ítem activo',
        group: 'Colores',
        choices: [
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('tertiary', 'Terciario'),
        ],
      ),
      PropertySpec.color(
        'unselectedItemColor',
        'Color del ítem inactivo',
        group: 'Colores',
        choices: [
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('low', 'Superficie baja'),
        ],
      ),
      PropertySpec.number(
        'elevation',
        'Elevación',
        group: 'Diseño',
        suffix: 'px',
        defaultValue: 8,
        min: 0,
        max: 24,
      ),
      PropertySpec.number(
        'iconSize',
        'Tamaño de ícono',
        group: 'Diseño',
        suffix: 'px',
        defaultValue: 24,
        min: 16,
        max: 36,
      ),
      PropertySpec.number(
        'selectedFontSize',
        'Tamaño etiqueta activa',
        group: 'Diseño',
        suffix: 'px',
        defaultValue: 14,
        min: 10,
        max: 20,
      ),
      PropertySpec.number(
        'unselectedFontSize',
        'Tamaño etiqueta inactiva',
        group: 'Diseño',
        suffix: 'px',
        defaultValue: 12,
        min: 10,
        max: 20,
      ),
      PropertySpec.boolean(
        'showSelectedLabels',
        'Mostrar etiqueta activa',
        group: 'Barra inferior',
        defaultValue: true,
      ),
      PropertySpec.boolean(
        'showUnselectedLabels',
        'Mostrar etiquetas inactivas',
        group: 'Barra inferior',
        defaultValue: true,
      ),
    ],
    builder: (context, props, children) {
      const labels = ['Inicio', 'Buscar', 'Favorito', 'Ajustes', 'Perfil'];
      const icons = [
        Icons.home,
        Icons.search,
        Icons.favorite,
        Icons.settings,
        Icons.person,
      ];
      final fallback = (children.length >= 2 ? children.length : 3).clamp(
        2,
        5,
      );
      final selected = props.number('selected').round().clamp(
        0,
        fallback - 1,
      );

      return BottomNavigationBar(
        currentIndex: selected,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: props.flag('showSelectedLabels'),
        showUnselectedLabels: props.flag('showUnselectedLabels'),
        items: [
          for (var index = 0; index < fallback; index++)
            BottomNavigationBarItem(
              icon: Icon(icons[index]),
              label: labels[index],
            ),
        ],
      );
    },
  ),
  WidgetDefinition(
    type: 'drawer',
    label: 'Menú lateral',
    category: ComponentCategory.navigation,
    icon: Icons.menu_open,
    slot: ComponentSlot.overlay,
    properties: const [
      PropertySpec.number(
        'width',
        'Ancho',
        defaultValue: 220,
        min: 160,
        max: 320,
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      return Container(
        width: props.number('width'),
        padding: const EdgeInsets.all(12),
        color: scheme.surfaceContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < 4; index++) ...[
              if (index > 0) const SizedBox(height: 6),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Elemento ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  ),

  WidgetDefinition(
    type: 'endDrawer',
    label: 'Menú derecho',
    category: ComponentCategory.navigation,
    icon: Icons.menu_open,
    slot: ComponentSlot.drawerEnd,
    flutterClass: 'EndDrawer',
    properties: const [
      PropertySpec.number(
        'width',
        'Ancho',
        defaultValue: 220,
        min: 160,
        max: 320,
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      return Container(
        width: props.number('width'),
        padding: const EdgeInsets.all(12),
        color: scheme.surfaceContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < 4; index++) ...[
              if (index > 0) const SizedBox(height: 6),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Elemento ${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'fab',
    label: 'Botón flotante',
    category: ComponentCategory.navigation,
    icon: Icons.add_circle_outline,
    slot: ComponentSlot.fab,
    flutterClass: 'FloatingActionButton',
    properties: const [
      PropertySpec.choice(
        'icon',
        'Ícono',
        choices: [
          PropertyChoice('add', 'Agregar'),
          PropertyChoice('edit', 'Editar'),
          PropertyChoice('save', 'Guardar'),
        ],
        defaultValue: 'add',
      ),
      PropertySpec.text(
        'extendedLabel',
        'Etiqueta (FAB extendido)',
        group: 'Contenido',
        hint: 'Si tiene texto, el botón se muestra extendido.',
      ),
      PropertySpec.boolean('mini', 'Pequeño', group: 'Dimensiones'),
      PropertySpec.color(
        'backgroundColor',
        'Color de fondo',
        group: 'Colores',
        choices: [
          PropertyChoice('primarySolid', 'Primario'),
          PropertyChoice('secondary', 'Secundario suave'),
          PropertyChoice('tertiary', 'Terciario suave'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.color(
        'foregroundColor',
        'Color del icono',
        group: 'Colores',
        choices: [
          PropertyChoice('onPrimarySolid', 'Sobre primario'),
          PropertyChoice('onSurface', 'Texto del tema'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.number(
        'elevation',
        'Elevación',
        group: 'Estilo',
        defaultValue: 6,
        min: 0,
        max: 12,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'iconSize',
        'Tamaño del icono',
        group: 'Dimensiones',
        defaultValue: 24,
        min: 16,
        max: 40,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.text('tooltip', 'Tooltip', group: 'Contenido'),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final background = props.choice('backgroundColor');
      final foreground = props.choice('foregroundColor');
      final icon = Icon(
        switch (props.choice('icon')) {
          'edit' => Icons.edit,
          'save' => Icons.save,
          _ => Icons.add,
        },
        size: props.number('iconSize'),
      );
      final label = props.text('extendedLabel');
      final tooltip = props.text('tooltip');

      if (label.isNotEmpty) {
        return FloatingActionButton.extended(
          onPressed: () {},
          icon: icon,
          label: Text(label),
          backgroundColor: background.isEmpty
              ? null
              : colorForValue(background, scheme),
          foregroundColor: foreground.isEmpty
              ? null
              : colorForValue(foreground, scheme),
          elevation: props.number('elevation'),
          tooltip: tooltip.isEmpty ? null : tooltip,
        );
      }
      return FloatingActionButton(
        onPressed: () {},
        mini: props.flag('mini'),
        backgroundColor: background.isEmpty
            ? null
            : colorForValue(background, scheme),
        foregroundColor: foreground.isEmpty
            ? null
            : colorForValue(foreground, scheme),
        elevation: props.number('elevation'),
        tooltip: tooltip.isEmpty ? null : tooltip,
        child: icon,
      );
    },
  ),

  // ------------------------------------------------------------ formularios
  WidgetDefinition(
    type: 'textField',
    label: 'Campo de texto',
    category: ComponentCategory.input,
    icon: Icons.input,
    properties: const [
      PropertySpec.text('label', 'Etiqueta', defaultValue: 'Nombre'),
      PropertySpec.text('hint', 'Texto de referencia'),
      PropertySpec.boolean('obscure', 'Máscara de caracteres'),
      PropertySpec.text(
        'helperText',
        'Texto de ayuda',
        group: 'Contenido',
        hint: 'Se muestra debajo del campo.',
      ),
      PropertySpec.choice(
        'keyboardType',
        'Tipo de teclado',
        group: 'Comportamiento',
        choices: [
          PropertyChoice('text', 'Texto'),
          PropertyChoice('number', 'Número'),
          PropertyChoice('email', 'Correo'),
          PropertyChoice('phone', 'Teléfono'),
          PropertyChoice('multiline', 'Multilínea'),
        ],
        defaultValue: 'text',
      ),
      PropertySpec.number(
        'maxLines',
        'Máximo de líneas',
        group: 'Comportamiento',
        defaultValue: 1,
        min: 1,
        max: 8,
        integer: true,
      ),
      PropertySpec.choice(
        'prefixIcon',
        'Icono inicial',
        group: 'Estilo',
        defaultValue: '',
        choices: [
          PropertyChoice('', 'Ninguno'),
          PropertyChoice('person', 'Persona'),
          PropertyChoice('mail', 'Correo'),
          PropertyChoice('lock', 'Candado'),
          PropertyChoice('search', 'Buscar'),
          PropertyChoice('calendar', 'Calendario'),
        ],
      ),
      PropertySpec.choice(
        'suffixIcon',
        'Icono final',
        group: 'Estilo',
        defaultValue: '',
        choices: [
          PropertyChoice('', 'Ninguno'),
          PropertyChoice('visibility', 'Ver'),
          PropertyChoice('close', 'Cerrar'),
          PropertyChoice('check', 'Check'),
          PropertyChoice('arrow_forward', 'Avanzar'),
        ],
      ),
      PropertySpec.boolean(
        'filled',
        'Relleno de fondo',
        group: 'Estilo',
        defaultValue: true,
      ),
      PropertySpec.color(
        'fillColor',
        'Color del relleno',
        group: 'Estilo',
        choices: [
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('surface', 'Superficie'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.number(
        'borderRadius',
        'Radio',
        group: 'Forma',
        defaultValue: 0,
        min: 0,
        max: 28,
        integer: true,
        suffix: 'px',
        hint: '0 = radio del tema.',
      ),
      PropertySpec.boolean(
        'readOnly',
        'Solo lectura',
        group: 'Comportamiento',
      ),
      PropertySpec.choice(
        'onFocus',
        'Al recibir foco',
        group: 'Eventos',
        hint: 'Acción cuando el campo queda enfocado.',
        choices: _eventChoices,
        defaultValue: 'none',
      ),
      PropertySpec.choice(
        'onBlur',
        'Al perder foco',
        group: 'Eventos',
        hint: 'Acción cuando el campo deja de estar enfocado.',
        choices: _eventChoices,
        defaultValue: 'none',
      ),
      PropertySpec.text(
        'eventMessage',
        'Mensaje del evento',
        group: 'Eventos',
        hint: 'Texto del SnackBar cuando la acción es Mensaje.',
        defaultValue: 'Acción ejecutada',
      ),
    ],
    builder: (context, props, children) {
      final hint = props.text('hint');
      final onFocus = _previewAction(context, props, 'onFocus');
      final onBlur = _previewAction(context, props, 'onBlur');
      final scheme = Theme.of(context).colorScheme;
      final radius = props.number('borderRadius');
      final fillColor = props.choice('fillColor');
      final prefix = props.choice('prefixIcon');
      final suffix = props.choice('suffixIcon');
      final keyboardType = switch (props.choice('keyboardType')) {
        'number' => TextInputType.number,
        'email' => TextInputType.emailAddress,
        'phone' => TextInputType.phone,
        'multiline' => TextInputType.multiline,
        _ => TextInputType.text,
      };
      final maxLines = props.number('maxLines').round().clamp(1, 8);

      return Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            onFocus?.call();
          } else {
            onBlur?.call();
          }
        },
        child: TextField(
          obscureText: props.flag('obscure'),
          keyboardType: keyboardType,
          maxLines: props.flag('obscure') ? 1 : maxLines,
          readOnly: props.flag('readOnly'),
          decoration: InputDecoration(
            labelText: props.text('label'),
            hintText: hint.isEmpty ? null : hint,
            helperText: props.text('helperText').isEmpty
                ? null
                : props.text('helperText'),
            prefixIcon: prefix.isEmpty ? null : Icon(iconDataFor(prefix)),
            suffixIcon: suffix.isEmpty ? null : Icon(iconDataFor(suffix)),
            filled: props.flag('filled'),
            fillColor: fillColor.isEmpty
                ? null
                : colorForValue(fillColor, scheme),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'checkbox',
    label: 'Casilla',
    category: ComponentCategory.input,
    icon: Icons.check_box_outlined,
    properties: const [
      PropertySpec.text('label', 'Etiqueta', defaultValue: 'Aceptar términos'),
      PropertySpec.boolean('checked', 'Marcada', defaultValue: false),
      PropertySpec.number(
        'fontSize',
        'Tamaño del texto',
        group: 'Tipografía',
        defaultValue: 13,
        min: 8,
        max: 24,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return CheckboxListTile(
        value: props.flag('checked'),
        onChanged: (_) {},
        title: Text(
          props.text('label'),
          style: TextStyle(fontSize: props.number('fontSize')),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
    },
  ),
  WidgetDefinition(
    type: 'switch',
    label: 'Interruptor',
    category: ComponentCategory.input,
    icon: Icons.toggle_on_outlined,
    properties: const [
      PropertySpec.text('label', 'Etiqueta', defaultValue: 'Notificaciones'),
      PropertySpec.boolean('value', 'Activo', defaultValue: true),
      PropertySpec.number(
        'fontSize',
        'Tamaño del texto',
        group: 'Tipografía',
        defaultValue: 13,
        min: 8,
        max: 24,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return SwitchListTile(
        value: props.flag('value'),
        onChanged: (_) {},
        title: Text(
          props.text('label'),
          style: TextStyle(fontSize: props.number('fontSize')),
        ),
        contentPadding: EdgeInsets.zero,
        dense: true,
      );
    },
  ),
  WidgetDefinition(
    type: 'slider',
    label: 'Deslizador',
    category: ComponentCategory.input,
    icon: Icons.tune,
    properties: const [
      PropertySpec.number('value', 'Valor', defaultValue: 0.5, min: 0, max: 1),
      PropertySpec.text('label', 'Etiqueta', defaultValue: 'Volumen'),
    ],
    builder: (context, props, children) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            props.text('label'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Slider(
            value: props.number('value').clamp(0.0, 1.0),
            onChanged: (_) {},
          ),
        ],
      );
    },
  ),

  // ----------------------------------------------------------------- media
  WidgetDefinition(
    type: 'image',
    label: 'Imagen',
    category: ComponentCategory.media,
    icon: Icons.image_outlined,
    properties: const [
      PropertySpec.text(
        'url',
        'URL de la imagen',
        group: 'Imagen',
        hint: 'Si está vacía, se muestra un marcador.',
      ),
      PropertySpec.number(
        'width',
        'Ancho',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 600,
        integer: true,
        suffix: 'px',
        hint: '0 = ocupa el ancho disponible.',
      ),
      PropertySpec.number(
        'height',
        'Alto',
        group: 'Dimensiones',
        defaultValue: 160,
        min: 40,
        max: 400,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.choice(
        'fit',
        'Ajuste',
        group: 'Estilo',
        choices: [
          PropertyChoice('cover', 'Cubrir'),
          PropertyChoice('contain', 'Contener'),
          PropertyChoice('fill', 'Rellenar'),
          PropertyChoice('fitWidth', 'Ancho completo'),
        ],
        defaultValue: 'cover',
      ),
      PropertySpec.number(
        'radius',
        'Radio',
        group: 'Estilo',
        defaultValue: 12,
        min: 0,
        max: 60,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'opacity',
        'Opacidad',
        group: 'Estilo',
        defaultValue: 1,
        min: 0,
        max: 1,
        step: 0.05,
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final url = props.text('url');
      final width = props.number('width');
      final height = props.number('height');
      final radius = props.number('radius');
      final fit = switch (props.choice('fit')) {
        'contain' => BoxFit.contain,
        'fill' => BoxFit.fill,
        'fitWidth' => BoxFit.fitWidth,
        _ => BoxFit.cover,
      };

      final placeholder = Container(
        width: width == 0 ? null : width,
        height: height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
        ),
      );

      final content = Opacity(
        opacity: props.number('opacity').clamp(0.0, 1.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: url.isEmpty
              ? placeholder
              : Image.network(
                  url,
                  width: width == 0 ? null : width,
                  height: height,
                  fit: fit,
                  errorBuilder: (context, error, stackTrace) => placeholder,
                ),
        ),
      );
      // En una columna los hijos se estiran: Align evita que el ancho
      // configurado se ignore en la vista previa.
      if (width <= 0) {
        return content;
      }
      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(width: width, child: content),
      );
    },
  ),

  // -------------------------------------------- portados de Flutter Studio
  WidgetDefinition(
    type: 'stack',
    label: 'Stack',
    category: ComponentCategory.layout,
    icon: Icons.layers_outlined,
    flutterClass: 'Stack',
    acceptsChildren: true,
    properties: const [
      PropertySpec.choice(
        'alignment',
        'Alineación',
        group: 'Alineación',
        hint: 'Cómo se acomodan los hijos dentro de la pila.',
        choices: _alignmentChoices,
        defaultValue: 'topLeft',
      ),
      PropertySpec.choice(
        'fit',
        'Ajuste',
        group: 'Alineación',
        choices: [
          PropertyChoice('loose', 'Suelto'),
          PropertyChoice('expand', 'Expandir'),
          PropertyChoice('passthrough', 'Pass through'),
        ],
        defaultValue: 'loose',
      ),
      PropertySpec.choice(
        'clipBehavior',
        'Recorte',
        group: 'Alineación',
        choices: [
          PropertyChoice('hardEdge', 'Recortar'),
          PropertyChoice('antiAlias', 'Recorte suavizado'),
          PropertyChoice('none', 'Sin recorte'),
        ],
        defaultValue: 'hardEdge',
      ),
    ],
    builder: (context, props, children) {
      return Stack(
        alignment: _alignmentFor(props.choice('alignment')),
        fit: switch (props.choice('fit')) {
          'expand' => StackFit.expand,
          'passthrough' => StackFit.passthrough,
          _ => StackFit.loose,
        },
        clipBehavior: switch (props.choice('clipBehavior')) {
          'antiAlias' => Clip.antiAlias,
          'none' => Clip.none,
          _ => Clip.hardEdge,
        },
        children: children.isEmpty ? const [_EmptySlot()] : children,
      );
    },
  ),
  WidgetDefinition(
    type: 'wrap',
    label: 'Wrap',
    category: ComponentCategory.layout,
    icon: Icons.wrap_text_rounded,
    flutterClass: 'Wrap',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'spacing',
        'Separación horizontal',
        group: 'Alineación',
        defaultValue: 8,
        min: 0,
        max: 48,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'runSpacing',
        'Separación vertical',
        group: 'Alineación',
        defaultValue: 8,
        min: 0,
        max: 48,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.choice(
        'alignment',
        'Alineación',
        group: 'Alineación',
        choices: [
          PropertyChoice('start', 'Inicio'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('end', 'Final'),
          PropertyChoice('spaceBetween', 'Espacio entre'),
          PropertyChoice('spaceEvenly', 'Espacio uniforme'),
        ],
        defaultValue: 'start',
      ),
      PropertySpec.choice(
        'direction',
        'Dirección',
        group: 'Alineación',
        choices: [
          PropertyChoice('horizontal', 'Horizontal'),
          PropertyChoice('vertical', 'Vertical'),
        ],
        defaultValue: 'horizontal',
      ),
      PropertySpec.choice(
        'crossAxisAlignment',
        'Alineación transversal',
        group: 'Alineación',
        choices: [
          PropertyChoice('start', 'Inicio'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('end', 'Fin'),
        ],
        defaultValue: 'start',
      ),
    ],
    builder: (context, props, children) {
      return Wrap(
        spacing: props.number('spacing'),
        runSpacing: props.number('runSpacing'),
        crossAxisAlignment: _wrapCross(
          props.choice('crossAxisAlignment'),
        ),
        alignment: switch (props.choice('alignment')) {
          'center' => WrapAlignment.center,
          'end' => WrapAlignment.end,
          'spaceBetween' => WrapAlignment.spaceBetween,
          'spaceEvenly' => WrapAlignment.spaceEvenly,
          _ => WrapAlignment.start,
        },
        direction: props.choice('direction') == 'vertical'
            ? Axis.vertical
            : Axis.horizontal,
        children: children.isEmpty ? const [_EmptySlot()] : children,
      );
    },
  ),
  WidgetDefinition(
    type: 'align',
    label: 'Alinear',
    category: ComponentCategory.layout,
    icon: Icons.align_horizontal_center_rounded,
    flutterClass: 'Align',
    acceptsChildren: true,
    properties: const [
      PropertySpec.choice(
        'alignment',
        'Alineación',
        group: 'Alineación',
        choices: _alignmentChoices,
        defaultValue: 'center',
      ),
      PropertySpec.number(
        'widthFactor',
        'Factor de ancho',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 4,
        step: 0.1,
        hint: '0 = automático',
      ),
      PropertySpec.number(
        'heightFactor',
        'Factor de alto',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 4,
        step: 0.1,
        hint: '0 = automático',
      ),
    ],
    builder: (context, props, children) {
      return Align(
        alignment: _alignmentFor(props.choice('alignment')),
        widthFactor: props.number('widthFactor') == 0
            ? null
            : props.number('widthFactor'),
        heightFactor: props.number('heightFactor') == 0
            ? null
            : props.number('heightFactor'),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'sizedBox',
    label: 'Caja',
    category: ComponentCategory.layout,
    icon: Icons.aspect_ratio_outlined,
    flutterClass: 'SizedBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'width',
        'Ancho',
        group: 'Dimensiones',
        defaultValue: 200,
        min: 0,
        max: 800,
        integer: true,
        suffix: 'px',
        hint: '0 = automático',
      ),
      PropertySpec.number(
        'height',
        'Alto',
        group: 'Dimensiones',
        defaultValue: 100,
        min: 0,
        max: 800,
        integer: true,
        suffix: 'px',
        hint: '0 = automático',
      ),
    ],
    builder: (context, props, children) {
      final width = props.number('width');
      final height = props.number('height');
      final box = SizedBox(
        width: width == 0 ? null : width,
        height: height == 0 ? null : height,
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
      // Igual que la imagen: evita que la columna estire y anule el ancho.
      if (width == 0) {
        return box;
      }
      return Align(alignment: Alignment.centerLeft, child: box);
    },
  ),
  WidgetDefinition(
    type: 'chip',
    label: 'Chip',
    category: ComponentCategory.material,
    icon: Icons.label_outline,
    flutterClass: 'Chip',
    properties: const [
      PropertySpec.text(
        'label',
        'Etiqueta',
        group: 'Contenido',
        defaultValue: 'En camino',
      ),
      PropertySpec.choice(
        'avatarIcon',
        'Icono',
        group: 'Estilo',
        defaultValue: '',
        choices: [
          PropertyChoice('', 'Ninguno'),
          PropertyChoice('person', 'Persona'),
          PropertyChoice('folder', 'Carpeta'),
          PropertyChoice('mail', 'Correo'),
          PropertyChoice('check', 'Check'),
          PropertyChoice('star', 'Estrella'),
        ],
      ),
      PropertySpec.color(
        'backgroundColor',
        'Fondo',
        group: 'Estilo',
        choices: [
          PropertyChoice('primary', 'Primario suave'),
          PropertyChoice('secondary', 'Secundario suave'),
          PropertyChoice('tertiary', 'Terciario suave'),
          PropertyChoice('low', 'Superficie baja'),
        ],
        defaultValue: 'primary',
      ),
      PropertySpec.color(
        'textColor',
        'Texto',
        group: 'Estilo',
        choices: [
          PropertyChoice('onPrimaryContainer', 'Sobre primario'),
          PropertyChoice('onSurface', 'Texto del tema'),
        ],
        defaultValue: 'onPrimaryContainer',
      ),
      PropertySpec.number(
        'labelFontSize',
        'Tamaño de etiqueta',
        group: 'Tipografía',
        defaultValue: 14,
        min: 10,
        max: 24,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'elevation',
        'Elevación',
        group: 'Estilo',
        defaultValue: 0,
        min: 0,
        max: 12,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.boolean(
        'showDeleteIcon',
        'Mostrar borrar',
        group: 'Estado',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final icon = props.choice('avatarIcon');
      return Chip(
        label: Text(
          props.text('label'),
          style: TextStyle(
            fontSize: props.number('labelFontSize'),
            color: colorForValue(props.choice('textColor'), scheme),
          ),
        ),
        avatar: icon.isEmpty
            ? null
            : Icon(
                iconDataFor(icon),
                size: 16,
                color: colorForValue(props.choice('textColor'), scheme),
              ),
        backgroundColor: colorForValue(
          props.choice('backgroundColor'),
          scheme,
        ),
        elevation: props.number('elevation'),
        onDeleted: props.flag('showDeleteIcon') ? () {} : null,
      );
    },
  ),
  WidgetDefinition(
    type: 'avatar',
    label: 'Avatar',
    category: ComponentCategory.basic,
    icon: Icons.account_circle_outlined,
    flutterClass: 'CircleAvatar',
    properties: const [
      PropertySpec.text(
        'initials',
        'Iniciales',
        group: 'Contenido',
        defaultValue: 'SP',
      ),
      PropertySpec.number(
        'radius',
        'Radio',
        group: 'Tamaño',
        defaultValue: 20,
        min: 8,
        max: 64,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'backgroundColor',
        'Fondo',
        group: 'Colores',
        choices: [
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('secondary', 'Secundario'),
          PropertyChoice('tertiary', 'Terciario'),
          PropertyChoice('high', 'Superficie alta'),
        ],
        defaultValue: 'primary',
      ),
      PropertySpec.color(
        'textColor',
        'Texto',
        group: 'Colores',
        choices: [
          PropertyChoice('onPrimaryContainer', 'Sobre primario'),
          PropertyChoice('onSurface', 'Texto del tema'),
        ],
        defaultValue: 'onPrimaryContainer',
      ),
      PropertySpec.number(
        'fontSize',
        'Tamaño de iniciales',
        group: 'Tipografía',
        defaultValue: 16,
        min: 8,
        max: 40,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.text(
        'imageUrl',
        'URL de la imagen',
        group: 'Imagen',
        hint: 'Opcional; si falla se muestran las iniciales.',
      ),
      PropertySpec.number(
        'borderWidth',
        'Grosor del borde',
        group: 'Forma',
        defaultValue: 0,
        min: 0,
        max: 8,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'borderColor',
        'Color del borde',
        group: 'Forma',
        choices: [
          PropertyChoice('primarySolid', 'Primario'),
          PropertyChoice('outline', 'Borde del tema'),
          PropertyChoice('tertiary', 'Terciario suave'),
        ],
        hint: 'Vacío = primario.',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final radius = props.number('radius');
      final borderWidth = props.number('borderWidth');
      final borderColor = props.choice('borderColor');
      final imageUrl = props.text('imageUrl');

      Widget avatar = CircleAvatar(
        radius: borderWidth > 0 ? radius - borderWidth : radius,
        backgroundColor: colorForValue(
          props.choice('backgroundColor'),
          scheme,
        ),
        backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
        onBackgroundImageError: imageUrl.isEmpty ? null : (_, _) {},
        child: Text(
          props.text('initials'),
          style: TextStyle(
            fontSize: props.number('fontSize'),
            color: colorForValue(props.choice('textColor'), scheme),
          ),
        ),
      );

      if (borderWidth > 0) {
        avatar = Container(
          padding: EdgeInsets.all(borderWidth),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorForValue(
              borderColor.isEmpty ? 'primarySolid' : borderColor,
              scheme,
            ),
          ),
          child: avatar,
        );
      }
      return avatar;
    },
  ),
  WidgetDefinition(
    type: 'segmentedButton',
    label: 'Segmentado',
    category: ComponentCategory.input,
    icon: Icons.view_week_outlined,
    flutterClass: 'SegmentedButton',
    properties: const [
      PropertySpec.text(
        'option1',
        'Opción 1',
        group: 'Contenido',
        defaultValue: 'Día',
      ),
      PropertySpec.text(
        'option2',
        'Opción 2',
        group: 'Contenido',
        defaultValue: 'Semana',
      ),
      PropertySpec.text(
        'option3',
        'Opción 3',
        group: 'Contenido',
        defaultValue: 'Mes',
      ),
      PropertySpec.choice(
        'selectedIndex',
        'Opción activa',
        group: 'Estado',
        choices: [
          PropertyChoice('0', 'Opción 1'),
          PropertyChoice('1', 'Opción 2'),
          PropertyChoice('2', 'Opción 3'),
        ],
        defaultValue: '0',
      ),
      PropertySpec.boolean(
        'showSelectedIcon',
        'Mostrar check',
        group: 'Estado',
        defaultValue: true,
      ),
      PropertySpec.number(
        'fontSize',
        'Tamaño del texto',
        group: 'Tipografía',
        defaultValue: 13,
        min: 8,
        max: 20,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.choice(
        'direction',
        'Dirección',
        group: 'Diseño',
        choices: [
          PropertyChoice('horizontal', 'Horizontal'),
          PropertyChoice('vertical', 'Vertical'),
        ],
        defaultValue: 'horizontal',
      ),
    ],
    builder: (context, props, children) {
      final labels = [
        props.text('option1').isEmpty ? 'Uno' : props.text('option1'),
        props.text('option2').isEmpty ? 'Dos' : props.text('option2'),
        props.text('option3').isEmpty ? 'Tres' : props.text('option3'),
      ];
      final selected = int.tryParse(props.choice('selectedIndex')) ?? 0;
      return SegmentedButton<int>(
        segments: [
          for (var index = 0; index < labels.length; index++)
            ButtonSegment(value: index, label: Text(labels[index])),
        ],
        selected: {selected.clamp(0, labels.length - 1)},
        showSelectedIcon: props.flag('showSelectedIcon'),
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: props.number('fontSize')),
          ),
          visualDensity: VisualDensity.compact,
        ),
        direction: props.choice('direction') == 'vertical'
            ? Axis.vertical
            : Axis.horizontal,
        onSelectionChanged: (_) {},
      );
    },
  ),

  // ------------------------------------------ lote 2: layout y formularios
  WidgetDefinition(
    type: 'verticalDivider',
    label: 'Divisor vertical',
    category: ComponentCategory.layout,
    icon: Icons.vertical_split_outlined,
    flutterClass: 'VerticalDivider',
    properties: const [
      PropertySpec.number(
        'thickness',
        'Grosor',
        group: 'Estilo',
        defaultValue: 1,
        min: 0.5,
        max: 8,
        step: 0.5,
        suffix: 'px',
      ),
      PropertySpec.number(
        'indent',
        'Separación superior',
        group: 'Dimensiones',
        defaultValue: 0,
        min: 0,
        max: 64,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return VerticalDivider(
        thickness: props.number('thickness'),
        indent: props.number('indent'),
      );
    },
  ),
  WidgetDefinition(
    type: 'opacity',
    label: 'Opacidad',
    category: ComponentCategory.layout,
    icon: Icons.opacity_outlined,
    flutterClass: 'Opacity',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'opacity',
        'Opacidad',
        group: 'Estilo',
        defaultValue: 0.5,
        min: 0,
        max: 1,
        step: 0.05,
        hint: '0 = invisible, 1 = opaco.',
      ),
    ],
    builder: (context, props, children) {
      return Opacity(
        opacity: props.number('opacity').clamp(0.0, 1.0),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'aspectRatio',
    label: 'Relación de aspecto',
    category: ComponentCategory.layout,
    icon: Icons.crop_16_9_outlined,
    flutterClass: 'AspectRatio',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'ratio',
        'Proporción',
        group: 'Dimensiones',
        defaultValue: 1.5,
        min: 0.1,
        max: 4,
        step: 0.1,
        hint: 'Ancho ÷ alto (1.5 = 3:2).',
      ),
      PropertySpec.choice(
        'alignment',
        'Alineación',
        group: 'Dimensiones',
        choices: _alignmentChoices,
        defaultValue: 'center',
      ),
    ],
    builder: (context, props, children) {
      return AspectRatio(
        aspectRatio: props.number('ratio').clamp(0.1, 4.0),
        child: Align(
          alignment: _alignmentFor(props.choice('alignment')),
          child: children.isEmpty ? const _EmptySlot() : children.first,
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'visibility',
    label: 'Visibilidad',
    category: ComponentCategory.layout,
    icon: Icons.visibility_outlined,
    flutterClass: 'Visibility',
    acceptsChildren: true,
    properties: const [
      PropertySpec.boolean(
        'isVisible',
        'Visible',
        group: 'Estado',
        hint: 'Al ocultarse, el espacio se colapsa en la vista previa.',
        defaultValue: true,
      ),
    ],
    builder: (context, props, children) {
      return Visibility(
        visible: props.flag('isVisible'),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'safeArea',
    label: 'Área segura',
    category: ComponentCategory.layout,
    icon: Icons.shield_outlined,
    flutterClass: 'SafeArea',
    acceptsChildren: true,
    properties: const [
      PropertySpec.boolean('top', 'Proteger arriba', defaultValue: true),
      PropertySpec.boolean('bottom', 'Proteger abajo', defaultValue: true),
      PropertySpec.boolean('left', 'Proteger izquierda', defaultValue: true),
      PropertySpec.boolean('right', 'Proteger derecha', defaultValue: true),
    ],
    builder: (context, props, children) {
      return SafeArea(
        top: props.flag('top'),
        bottom: props.flag('bottom'),
        left: props.flag('left'),
        right: props.flag('right'),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'radioTile',
    label: 'Radio',
    category: ComponentCategory.input,
    icon: Icons.radio_button_checked,
    flutterClass: 'RadioListTile',
    properties: const [
      PropertySpec.text(
        'title',
        'Título',
        group: 'Contenido',
        defaultValue: 'Opción',
      ),
      PropertySpec.text('subtitle', 'Subtítulo', group: 'Contenido'),
      PropertySpec.boolean('selected', 'Seleccionada', group: 'Estado'),
      PropertySpec.boolean(
        'enabled',
        'Habilitada',
        group: 'Estado',
        defaultValue: true,
      ),
      PropertySpec.number(
        'fontSize',
        'Tamaño del texto',
        group: 'Tipografía',
        defaultValue: 13,
        min: 8,
        max: 24,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      final fontSize = props.number('fontSize');
      return RadioGroup<bool>(
        groupValue: props.flag('selected') ? true : null,
        onChanged: (_) {},
        child: IgnorePointer(
          ignoring: !props.flag('enabled'),
          child: RadioListTile<bool>(
            value: true,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              props.text('title'),
              style: TextStyle(fontSize: fontSize),
            ),
            subtitle: props.text('subtitle').isEmpty
                ? null
                : Text(
                    props.text('subtitle'),
                    style: TextStyle(
                      fontSize: (fontSize - 1).clamp(8, 22),
                    ),
                  ),
          ),
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'dropdownField',
    label: 'Desplegable',
    category: ComponentCategory.input,
    icon: Icons.arrow_drop_down_circle_outlined,
    flutterClass: 'DropdownButtonFormField',
    properties: const [
      PropertySpec.text(
        'label',
        'Etiqueta',
        group: 'Contenido',
        defaultValue: 'Categoría',
      ),
      PropertySpec.text(
        'options',
        'Opciones (separadas por coma)',
        group: 'Contenido',
        defaultValue: 'Opción 1, Opción 2, Opción 3',
      ),
      PropertySpec.text(
        'value',
        'Valor seleccionado',
        group: 'Estado',
        defaultValue: 'Opción 1',
      ),
    ],
    builder: (context, props, children) {
      final items = props
          .text('options')
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      final options = items.isEmpty ? const ['Opción 1'] : items;
      final value = options.contains(props.text('value'))
          ? props.text('value')
          : options.first;

      return DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: props.text('label')),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: (_) {},
      );
    },
  ),
  WidgetDefinition(
    type: 'searchBar',
    label: 'Barra de búsqueda',
    category: ComponentCategory.input,
    icon: Icons.search,
    flutterClass: 'SearchBar',
    properties: const [
      PropertySpec.text(
        'hint',
        'Texto de ayuda',
        group: 'Contenido',
        defaultValue: 'Buscar…',
      ),
      PropertySpec.number(
        'elevation',
        'Elevación',
        group: 'Estilo',
        defaultValue: 0,
        min: 0,
        max: 12,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return SearchBar(
        hintText: props.text('hint'),
        elevation: WidgetStatePropertyAll(props.number('elevation')),
        leading: const Icon(Icons.search),
      );
    },
  ),
  WidgetDefinition(
    type: 'switchTile',
    label: 'Switch con título',
    category: ComponentCategory.input,
    icon: Icons.toggle_on_outlined,
    flutterClass: 'SwitchListTile',
    properties: const [
      PropertySpec.text(
        'title',
        'Título',
        group: 'Contenido',
        defaultValue: 'Notificaciones',
      ),
      PropertySpec.text('subtitle', 'Subtítulo', group: 'Contenido'),
      PropertySpec.boolean('value', 'Activado', group: 'Estado'),
      PropertySpec.number(
        'fontSize',
        'Tamaño del texto',
        group: 'Tipografía',
        defaultValue: 13,
        min: 8,
        max: 24,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return SwitchListTile(
        value: props.flag('value'),
        title: Text(
          props.text('title'),
          style: TextStyle(fontSize: props.number('fontSize')),
        ),
        subtitle: props.text('subtitle').isEmpty
            ? null
            : Text(
                props.text('subtitle'),
                style: TextStyle(
                  fontSize: (props.number('fontSize') - 1).clamp(8, 22),
                ),
              ),
        onChanged: (_) {},
        dense: true,
        contentPadding: EdgeInsets.zero,
      );
    },
  ),
  WidgetDefinition(
    type: 'iconButton',
    label: 'Botón de icono',
    category: ComponentCategory.basic,
    icon: Icons.touch_app_outlined,
    flutterClass: 'IconButton',
    properties: const [
      PropertySpec.choice(
        'icon',
        'Icono',
        group: 'Contenido',
        choices: [
          PropertyChoice('favorite', 'Corazón'),
          PropertyChoice('settings', 'Ajustes'),
          PropertyChoice('search', 'Buscar'),
          PropertyChoice('add', 'Agregar'),
          PropertyChoice('person', 'Persona'),
          PropertyChoice('more_vert', 'Más'),
          PropertyChoice('close', 'Cerrar'),
        ],
        defaultValue: 'favorite',
      ),
      PropertySpec.text(
        'tooltip',
        'Tooltip',
        group: 'Contenido',
        defaultValue: 'Acción',
      ),
      PropertySpec.number(
        'size',
        'Tamaño',
        group: 'Estilo',
        defaultValue: 24,
        min: 12,
        max: 64,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'color',
        'Color',
        group: 'Estilo',
        choices: [
          PropertyChoice('primary', 'Primario'),
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('high', 'Superficie alta'),
        ],
        defaultValue: 'primary',
      ),
      PropertySpec.choice(
        'onTap',
        'Al tocar',
        group: 'Eventos',
        choices: _eventChoices,
        defaultValue: 'none',
      ),
      PropertySpec.text(
        'eventMessage',
        'Mensaje del evento',
        group: 'Eventos',
        defaultValue: 'Acción ejecutada',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final action = _previewAction(context, props, 'onTap');
      return IconButton(
        tooltip: props.text('tooltip'),
        iconSize: props.number('size'),
        color: colorForValue(props.choice('color'), scheme),
        onPressed: action ?? () {},
        icon: Icon(iconDataFor(props.choice('icon'))),
      );
    },
  ),

  // ------------------------------ lote 3: visuales, listas y contenedores
  WidgetDefinition(
    type: 'tooltip',
    label: 'Tooltip',
    category: ComponentCategory.basic,
    icon: Icons.info_outline,
    flutterClass: 'Tooltip',
    acceptsChildren: true,
    properties: const [
      PropertySpec.text(
        'message',
        'Mensaje',
        group: 'Contenido',
        defaultValue: 'Más información',
      ),
      PropertySpec.number(
        'waitDuration',
        'Espera antes de mostrarse',
        group: 'Comportamiento',
        defaultValue: 500,
        min: 0,
        max: 2000,
        integer: true,
        suffix: 'ms',
      ),
      PropertySpec.number(
        'showDuration',
        'Duración visible',
        group: 'Comportamiento',
        defaultValue: 1500,
        min: 500,
        max: 10000,
        integer: true,
        suffix: 'ms',
      ),
      PropertySpec.boolean(
        'preferBelow',
        'Mostrar debajo',
        group: 'Posición',
        defaultValue: true,
      ),
      PropertySpec.number(
        'verticalOffset',
        'Desplazamiento vertical',
        group: 'Posición',
        defaultValue: 0,
        min: -40,
        max: 40,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'padding',
        'Relleno',
        group: 'Estilo',
        defaultValue: 0,
        min: 0,
        max: 16,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return Tooltip(
        message: props.text('message'),
        waitDuration: Duration(
          milliseconds: props.number('waitDuration').round(),
        ),
        showDuration: Duration(
          milliseconds: props.number('showDuration').round(),
        ),
        preferBelow: props.flag('preferBelow'),
        verticalOffset: props.number('verticalOffset'),
        padding: EdgeInsets.all(props.number('padding')),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'selectableText',
    label: 'Texto seleccionable',
    category: ComponentCategory.basic,
    icon: Icons.text_fields,
    flutterClass: 'SelectableText',
    properties: const [
      PropertySpec.text(
        'text',
        'Contenido',
        group: 'Contenido',
        defaultValue: 'Texto que se puede copiar',
      ),
      PropertySpec.number(
        'fontSize',
        'Tamaño',
        group: 'Tipografía',
        defaultValue: 14,
        min: 8,
        max: 72,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.choice(
        'align',
        'Alineación',
        group: 'Tipografía',
        choices: [
          PropertyChoice('left', 'Izquierda'),
          PropertyChoice('center', 'Centro'),
          PropertyChoice('right', 'Derecha'),
        ],
        defaultValue: 'left',
      ),
      PropertySpec.choice(
        'fontWeight',
        'Grosor',
        group: 'Tipografía',
        choices: [
          PropertyChoice('inherit', 'Heredar'),
          PropertyChoice('normal', 'Regular'),
          PropertyChoice('w600', 'Semibold'),
          PropertyChoice('bold', 'Bold'),
        ],
        defaultValue: 'inherit',
      ),
      PropertySpec.color(
        'color',
        'Color',
        group: 'Tipografía',
        choices: [
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('onSurfaceVariant', 'Texto secundario'),
          PropertyChoice('primarySolid', 'Primario'),
        ],
        hint: 'Vacío = color del tema.',
      ),
      PropertySpec.number(
        'maxLines',
        'Máximo de líneas',
        group: 'Tipografía',
        defaultValue: 0,
        min: 0,
        max: 10,
        integer: true,
        hint: '0 = sin límite.',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final weight = _fontWeight(props.choice('fontWeight'));
      final color = props.choice('color');
      final maxLines = props.number('maxLines').round();
      return SelectableText(
        props.text('text'),
        maxLines: maxLines == 0 ? null : maxLines,
        style: TextStyle(
          fontSize: props.number('fontSize'),
          fontWeight: weight,
          color: color.isEmpty ? null : colorForValue(color, scheme),
        ),
        textAlign: switch (props.choice('align')) {
          'center' => TextAlign.center,
          'right' => TextAlign.right,
          _ => TextAlign.left,
        },
      );
    },
  ),
  WidgetDefinition(
    type: 'listView',
    label: 'Lista desplazable',
    category: ComponentCategory.layout,
    icon: Icons.view_list_outlined,
    flutterClass: 'ListView',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'gap',
        'Separación',
        group: 'Diseño',
        defaultValue: 8,
        min: 0,
        max: 32,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      final gap = props.number('gap');
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: children.isEmpty ? 1 : children.length,
        separatorBuilder: (context, index) =>
            gap == 0 ? const SizedBox.shrink() : SizedBox(height: gap),
        itemBuilder: (context, index) =>
            children.isEmpty ? const _EmptySlot() : children[index],
      );
    },
  ),
  WidgetDefinition(
    type: 'gridView',
    label: 'Cuadrícula',
    category: ComponentCategory.layout,
    icon: Icons.grid_view_outlined,
    flutterClass: 'GridView',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'columns',
        'Columnas',
        group: 'Diseño',
        defaultValue: 2,
        min: 1,
        max: 6,
        integer: true,
      ),
      PropertySpec.number(
        'gap',
        'Separación',
        group: 'Diseño',
        defaultValue: 8,
        min: 0,
        max: 32,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      final gap = props.number('gap');
      return GridView.count(
        crossAxisCount: props.number('columns').round().clamp(1, 6),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: gap,
        crossAxisSpacing: gap,
        children: children.isEmpty ? const [_EmptySlot()] : children,
      );
    },
  ),
  WidgetDefinition(
    type: 'clipRRect',
    label: 'Recorte redondeado',
    category: ComponentCategory.layout,
    icon: Icons.rounded_corner,
    flutterClass: 'ClipRRect',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'radius',
        'Radio',
        group: 'Estilo',
        defaultValue: 12,
        min: 0,
        max: 80,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(props.number('radius')),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'clipOval',
    label: 'Recorte ovalado',
    category: ComponentCategory.layout,
    icon: Icons.circle_outlined,
    flutterClass: 'ClipOval',
    acceptsChildren: true,
    properties: const [],
    builder: (context, props, children) {
      return ClipOval(
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'coloredBox',
    label: 'Caja de color',
    category: ComponentCategory.layout,
    icon: Icons.format_color_fill,
    flutterClass: 'ColoredBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.color(
        'color',
        'Color',
        group: 'Estilo',
        choices: [
          PropertyChoice('primary', 'Primario suave'),
          PropertyChoice('secondary', 'Secundario suave'),
          PropertyChoice('tertiary', 'Terciario suave'),
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
        ],
        defaultValue: 'low',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      return ColoredBox(
        color: colorForValue(props.choice('color'), scheme),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'decoratedBox',
    label: 'Caja decorada',
    category: ComponentCategory.layout,
    icon: Icons.crop_square,
    flutterClass: 'DecoratedBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.color(
        'backgroundColor',
        'Fondo',
        group: 'Estilo',
        choices: [
          PropertyChoice('surface', 'Superficie'),
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('primary', 'Primario suave'),
        ],
        defaultValue: 'low',
      ),
      PropertySpec.number(
        'radius',
        'Radio',
        group: 'Estilo',
        defaultValue: 12,
        min: 0,
        max: 80,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'borderWidth',
        'Grosor del borde',
        group: 'Estilo',
        defaultValue: 0,
        min: 0,
        max: 8,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      final borderWidth = props.number('borderWidth');
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colorForValue(props.choice('backgroundColor'), scheme),
          borderRadius: BorderRadius.circular(props.number('radius')),
          border: borderWidth > 0
              ? Border.all(color: scheme.outlineVariant, width: borderWidth)
              : null,
        ),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'offstage',
    label: 'Fuera de escena',
    category: ComponentCategory.layout,
    icon: Icons.visibility_off_outlined,
    flutterClass: 'Offstage',
    acceptsChildren: true,
    properties: const [
      PropertySpec.boolean(
        'offstage',
        'Oculto',
        group: 'Estado',
        hint: 'Oculto no ocupa espacio ni se dibuja.',
      ),
    ],
    builder: (context, props, children) {
      return Offstage(
        offstage: props.flag('offstage'),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'badge',
    label: 'Insignia',
    category: ComponentCategory.material,
    icon: Icons.badge_outlined,
    flutterClass: 'Badge',
    acceptsChildren: true,
    properties: const [
      PropertySpec.text(
        'label',
        'Etiqueta',
        group: 'Contenido',
        defaultValue: '3',
      ),
      PropertySpec.color(
        'backgroundColor',
        'Fondo',
        group: 'Estilo',
        choices: [
          PropertyChoice('tertiary', 'Terciario suave'),
          PropertyChoice('primary', 'Primario suave'),
          PropertyChoice('high', 'Superficie alta'),
        ],
        defaultValue: 'tertiary',
      ),
      PropertySpec.color(
        'textColor',
        'Texto',
        group: 'Estilo',
        choices: [
          PropertyChoice('onSurface', 'Texto del tema'),
          PropertyChoice('onPrimaryContainer', 'Sobre primario'),
        ],
        defaultValue: 'onSurface',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      return Badge(
        label: Text(
          props.text('label'),
          style: TextStyle(
            color: colorForValue(props.choice('textColor'), scheme),
          ),
        ),
        backgroundColor: colorForValue(
          props.choice('backgroundColor'),
          scheme,
        ),
        child: children.isEmpty ? const Icon(Icons.notifications_outlined) : children.first,
      );
    },
  ),

  // ------------------------------------ lote 4: navegación y ajuste fino
  WidgetDefinition(
    type: 'bottomAppBar',
    label: 'Barra inferior M3',
    category: ComponentCategory.navigation,
    icon: Icons.space_bar,
    flutterClass: 'BottomAppBar',
    slot: ComponentSlot.bottom,
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'height',
        'Alto',
        group: 'Dimensiones',
        defaultValue: 64,
        min: 40,
        max: 120,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.color(
        'color',
        'Color de fondo',
        group: 'Colores',
        choices: [
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('high', 'Superficie alta'),
          PropertyChoice('primary', 'Primario suave'),
        ],
        defaultValue: 'low',
      ),
      PropertySpec.number(
        'elevation',
        'Elevación',
        group: 'Estilo',
        defaultValue: 3,
        min: 0,
        max: 12,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      return BottomAppBar(
        height: props.number('height'),
        color: colorForValue(props.choice('color'), scheme),
        elevation: props.number('elevation'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: children,
        ),
      );
    },
  ),
  WidgetDefinition(
    type: 'expansionTile',
    label: 'Panel expandible',
    category: ComponentCategory.material,
    icon: Icons.expand_more,
    flutterClass: 'ExpansionTile',
    acceptsChildren: true,
    properties: const [
      PropertySpec.text(
        'title',
        'Título',
        group: 'Contenido',
        defaultValue: 'Detalles',
      ),
      PropertySpec.text('subtitle', 'Subtítulo', group: 'Contenido'),
      PropertySpec.boolean(
        'initiallyExpanded',
        'Expandido al inicio',
        group: 'Estado',
        defaultValue: true,
      ),
    ],
    builder: (context, props, children) {
      return ExpansionTile(
        title: Text(props.text('title')),
        subtitle: props.text('subtitle').isEmpty
            ? null
            : Text(props.text('subtitle')),
        initiallyExpanded: props.flag('initiallyExpanded'),
        children: children,
      );
    },
  ),
  WidgetDefinition(
    type: 'banner',
    label: 'Banner',
    category: ComponentCategory.material,
    icon: Icons.campaign_outlined,
    flutterClass: 'MaterialBanner',
    properties: const [
      PropertySpec.text(
        'message',
        'Mensaje',
        group: 'Contenido',
        defaultValue: 'Hay una actualización disponible.',
      ),
      PropertySpec.text(
        'actionLabel',
        'Acción',
        group: 'Contenido',
        defaultValue: 'Entendido',
      ),
      PropertySpec.color(
        'backgroundColor',
        'Fondo',
        group: 'Estilo',
        choices: [
          PropertyChoice('low', 'Superficie baja'),
          PropertyChoice('primary', 'Primario suave'),
          PropertyChoice('tertiary', 'Terciario suave'),
        ],
        defaultValue: 'primary',
      ),
    ],
    builder: (context, props, children) {
      final scheme = Theme.of(context).colorScheme;
      return MaterialBanner(
        content: Text(props.text('message')),
        backgroundColor: colorForValue(
          props.choice('backgroundColor'),
          scheme,
        ),
        actions: [
          TextButton(onPressed: () {}, child: Text(props.text('actionLabel'))),
        ],
      );
    },
  ),
  WidgetDefinition(
    type: 'toggleButtons',
    label: 'Botones alternables',
    category: ComponentCategory.input,
    icon: Icons.toggle_on,
    flutterClass: 'ToggleButtons',
    properties: const [
      PropertySpec.text(
        'option1',
        'Opción 1',
        group: 'Contenido',
        defaultValue: 'Día',
      ),
      PropertySpec.text(
        'option2',
        'Opción 2',
        group: 'Contenido',
        defaultValue: 'Semana',
      ),
      PropertySpec.text(
        'option3',
        'Opción 3',
        group: 'Contenido',
        defaultValue: 'Mes',
      ),
      PropertySpec.choice(
        'selectedIndex',
        'Opción activa',
        group: 'Estado',
        choices: [
          PropertyChoice('0', 'Opción 1'),
          PropertyChoice('1', 'Opción 2'),
          PropertyChoice('2', 'Opción 3'),
        ],
        defaultValue: '0',
      ),
    ],
    builder: (context, props, children) {
      final labels = [
        props.text('option1').isEmpty ? 'Uno' : props.text('option1'),
        props.text('option2').isEmpty ? 'Dos' : props.text('option2'),
        props.text('option3').isEmpty ? 'Tres' : props.text('option3'),
      ];
      final selected = int.tryParse(props.choice('selectedIndex')) ?? 0;
      return ToggleButtons(
        isSelected: [
          for (var index = 0; index < labels.length; index++)
            index == selected.clamp(0, labels.length - 1),
        ],
        onPressed: (_) {},
        children: [for (final label in labels) Text(label)],
      );
    },
  ),
  WidgetDefinition(
    type: 'fittedBox',
    label: 'Ajustar contenido',
    category: ComponentCategory.layout,
    icon: Icons.fit_screen,
    flutterClass: 'FittedBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.choice(
        'fit',
        'Ajuste',
        group: 'Dimensiones',
        choices: [
          PropertyChoice('contain', 'Contener'),
          PropertyChoice('cover', 'Cubrir'),
          PropertyChoice('fill', 'Rellenar'),
          PropertyChoice('scaleDown', 'Reducir'),
        ],
        defaultValue: 'contain',
      ),
    ],
    builder: (context, props, children) {
      return FittedBox(
        fit: switch (props.choice('fit')) {
          'cover' => BoxFit.cover,
          'fill' => BoxFit.fill,
          'scaleDown' => BoxFit.scaleDown,
          _ => BoxFit.contain,
        },
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'fractionallySizedBox',
    label: 'Tamaño fraccional',
    category: ComponentCategory.layout,
    icon: Icons.photo_size_select_large,
    flutterClass: 'FractionallySizedBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'widthFactor',
        'Factor de ancho',
        group: 'Dimensiones',
        defaultValue: 0.5,
        min: 0.1,
        max: 1,
        step: 0.05,
      ),
      PropertySpec.number(
        'heightFactor',
        'Factor de alto',
        group: 'Dimensiones',
        defaultValue: 0.5,
        min: 0.1,
        max: 1,
        step: 0.05,
      ),
      PropertySpec.choice(
        'alignment',
        'Alineación',
        group: 'Dimensiones',
        choices: _alignmentChoices,
        defaultValue: 'center',
      ),
    ],
    builder: (context, props, children) {
      return FractionallySizedBox(
        widthFactor: props.number('widthFactor').clamp(0.1, 1.0),
        heightFactor: props.number('heightFactor').clamp(0.1, 1.0),
        alignment: _alignmentFor(props.choice('alignment')),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'constrainedBox',
    label: 'Caja restringida',
    category: ComponentCategory.layout,
    icon: Icons.crop_free,
    flutterClass: 'ConstrainedBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'maxWidth',
        'Ancho máximo',
        group: 'Dimensiones',
        defaultValue: 240,
        min: 40,
        max: 900,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'maxHeight',
        'Alto máximo',
        group: 'Dimensiones',
        defaultValue: 160,
        min: 40,
        max: 900,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: props.number('maxWidth'),
          maxHeight: props.number('maxHeight'),
        ),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'limitedBox',
    label: 'Caja limitada',
    category: ComponentCategory.layout,
    icon: Icons.crop_din,
    flutterClass: 'LimitedBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'maxWidth',
        'Ancho máximo',
        group: 'Dimensiones',
        defaultValue: 200,
        min: 20,
        max: 900,
        integer: true,
        suffix: 'px',
      ),
      PropertySpec.number(
        'maxHeight',
        'Alto máximo',
        group: 'Dimensiones',
        defaultValue: 120,
        min: 20,
        max: 900,
        integer: true,
        suffix: 'px',
      ),
    ],
    builder: (context, props, children) {
      return LimitedBox(
        maxWidth: props.number('maxWidth'),
        maxHeight: props.number('maxHeight'),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),
  WidgetDefinition(
    type: 'rotatedBox',
    label: 'Caja rotada',
    category: ComponentCategory.layout,
    icon: Icons.screen_rotation,
    flutterClass: 'RotatedBox',
    acceptsChildren: true,
    properties: const [
      PropertySpec.number(
        'quarterTurns',
        'Giros de 90°',
        group: 'Dimensiones',
        defaultValue: 1,
        min: 0,
        max: 4,
        integer: true,
      ),
    ],
    builder: (context, props, children) {
      return RotatedBox(
        quarterTurns: props.number('quarterTurns').round().clamp(0, 4),
        child: children.isEmpty ? const _EmptySlot() : children.first,
      );
    },
  ),

  WidgetDefinition(
    type: 'inkWell',
    label: 'Área táctil',
    category: ComponentCategory.input,
    icon: Icons.touch_app,
    flutterClass: 'InkWell',
    acceptsChildren: true,
    properties: const [
      PropertySpec.choice(
        'onTap',
        'Al tocar',
        group: 'Eventos',
        choices: _eventChoices,
        defaultValue: 'none',
      ),
      PropertySpec.text(
        'eventMessage',
        'Mensaje del evento',
        group: 'Eventos',
        defaultValue: 'Acción ejecutada',
      ),
    ],
    builder: (context, props, children) {
      final action = _previewAction(context, props, 'onTap');
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action ?? () {},
          child: children.isEmpty ? const _EmptySlot() : children.first,
        ),
      );
    },
  ),
];

TextAlign _textAlign(String value) => switch (value) {
  'center' => TextAlign.center,
  'right' => TextAlign.right,
  _ => TextAlign.left,
};

FontWeight? _fontWeight(String value) => switch (value) {
  'normal' => FontWeight.w400,
  'w500' => FontWeight.w500,
  'w600' => FontWeight.w600,
  'bold' => FontWeight.bold,
  'w800' => FontWeight.w800,
  _ => null,
};

TextDecoration? _textDecoration(String value) => switch (value) {
  'underline' => TextDecoration.underline,
  'lineThrough' => TextDecoration.lineThrough,
  'overline' => TextDecoration.overline,
  _ => null,
};

TextOverflow _textOverflow(String value) => switch (value) {
  'clip' => TextOverflow.clip,
  'fade' => TextOverflow.fade,
  'visible' => TextOverflow.visible,
  _ => TextOverflow.ellipsis,
};

WrapCrossAlignment _wrapCross(String value) => switch (value) {
  'center' => WrapCrossAlignment.center,
  'end' => WrapCrossAlignment.end,
  _ => WrapCrossAlignment.start,
};

CrossAxisAlignment _crossAxis(String value) => switch (value) {  'center' => CrossAxisAlignment.center,
  'end' => CrossAxisAlignment.end,
  'stretch' => CrossAxisAlignment.stretch,
  _ => CrossAxisAlignment.start,
};

MainAxisAlignment _mainAxis(String value) => switch (value) {  'center' => MainAxisAlignment.center,
  'end' => MainAxisAlignment.end,
  'spaceBetween' => MainAxisAlignment.spaceBetween,
  _ => MainAxisAlignment.start,
};

TextStyle? _textStyle(BuildContext context, String value) => switch (value) {
  'title' => Theme.of(context).textTheme.titleLarge,
  'headline' => Theme.of(context).textTheme.headlineSmall,
  _ => Theme.of(context).textTheme.bodyMedium,
};

/// Construye la barra superior con sus zonas `leading` y `actions`.
///
/// El editor la usa con las listas ya separadas por posición del ícono; el
/// catálogo la usa con un render simple.
Widget buildAppBarWidget(
  BuildContext context,
  Props props, {
  List<Widget> leading = const [],
  List<Widget> actions = const [],
}) {
  final scheme = Theme.of(context).colorScheme;
  final auto = props.flag('automaticallyImplyLeading');

  Widget? leadingWidget;
  double? leadingWidth;
  if (leading.isNotEmpty) {
    leadingWidget = Row(mainAxisSize: MainAxisSize.min, children: leading);
    leadingWidth = 56.0 * leading.length;
  } else if (auto) {
    // En el lienzo no hay ruta padre: se simula el back de Flutter.
    leadingWidget = IconButton(
      onPressed: () {},
      tooltip: 'Atrás',
      icon: const Icon(Icons.arrow_back),
    );
  }

  final bottomRadius = props.number('bottomRadius');
  final foreground = props.choice('foregroundColor').isEmpty
      ? null
      : colorForValue(props.choice('foregroundColor'), scheme);

  return AppBar(
    // FittedBox reduce el tamaño del texto si no entra: nunca se pierde.
    title: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        props.text('title'),
        maxLines: 1,
        // El estilo explícito evita que `appBarTheme.titleTextStyle` (que
        // trae color del tema) pise el `foregroundColor` de esta barra.
        style: foreground == null ? null : TextStyle(color: foreground),
      ),
    ),
    centerTitle: props.flag('centerTitle'),
    elevation: props.number('elevation'),
    scrolledUnderElevation: props.number('scrolledUnderElevation'),
    toolbarHeight: props.number('toolbarHeight') == 0
        ? 56
        : props.number('toolbarHeight'),
    backgroundColor: props.flag('gradient')
        ? Colors.transparent
        : props.choice('backgroundColor').isEmpty
        ? null
        : colorForValue(props.choice('backgroundColor'), scheme),
    foregroundColor: foreground,
    automaticallyImplyLeading: false,
    leading: leadingWidget,
    leadingWidth: leadingWidth,
    actions: actions.isEmpty ? null : actions,
    flexibleSpace: props.flag('gradient')
        ? DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.primary,
                  colorForValue(
                    props.choice('gradientColor').isEmpty
                        ? 'secondary'
                        : props.choice('gradientColor'),
                    scheme,
                  ),
                ],
              ),
            ),
          )
        : null,
    shape: bottomRadius > 0
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(bottomRadius),
            ),
          )
        : null,
  );
}

IconData iconDataFor(String value) => switch (value) {
  'home' => Icons.home,
  'settings' => Icons.settings,
  'favorite' => Icons.favorite,
  'add' => Icons.add,
  'search' => Icons.search,
  'arrow_back' => Icons.arrow_back,
  'menu' => Icons.menu,
  'close' => Icons.close,
  'more_vert' => Icons.more_vert,
  'person' => Icons.person,
  'folder' => Icons.folder_outlined,
  'mail' => Icons.mail_outline,
  'check' => Icons.check_circle_outline,
  'lock' => Icons.lock_outline,
  'visibility' => Icons.visibility_outlined,
  'calendar' => Icons.calendar_today_outlined,
  'download' => Icons.download_outlined,
  'arrow_forward' => Icons.arrow_forward,
  'chevron_right' => Icons.chevron_right,
  _ => Icons.star,
};

/// Zona visible para soltar componentes dentro de un contenedor vacío.
///
/// Sin esto, un contenedor sin hijos mide 0 px y es imposible usarlo como
/// destino de arrastre.
class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Suelta widgets aquí',
            style: TextStyle(
              fontSize: 11.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Inserta separación entre hijos.
List<Widget> _spaced(
  List<Widget> children,
  double gap, {
  required bool horizontal,
}) {
  if (gap <= 0 || children.length < 2) {
    return children;
  }
  final result = <Widget>[];
  for (var index = 0; index < children.length; index++) {
    if (index > 0) {
      result.add(
        horizontal ? SizedBox(width: gap) : SizedBox(height: gap),
      );
    }
    result.add(children[index]);
  }
  return result;
}
