import 'package:flutter/material.dart';

import '../catalog/color_value.dart';
import '../catalog/component_catalog.dart';
import '../catalog/standard_catalog.dart';
import '../catalog/widget_definition.dart';
import '../domain/canvas_node.dart';
import 'editor_drag_data.dart';

/// Construye widgets reales a partir de un [CanvasNode].
///
/// El JSON del lienzo **no es confiable**: aquí se filtra por catálogo, se
/// coaccionan propiedades y se acotan profundidad y cantidad de hijos. Lo que
/// no cumple no se ejecuta: se sustituye por un marcador visual.
class WidgetRenderer extends StatelessWidget {
  /// Crea el renderizador.
  const WidgetRenderer({
    required this.node,
    this.catalog,
    this.maxDepth = 40,
    this.maxChildren = 50,
    this.selectedNodeId,
    this.onNodeTap,
    this.onNodeDrop,
    this.onComponentDrop,
    this.screenScrollController,
    this.showDrawer = false,
    this.showEndDrawer = false,
    super.key,
  });

  /// Nodo raíz a dibujar.
  final CanvasNode node;

  /// Catálogo a usar; por defecto, el estándar.
  final ComponentCatalog? catalog;

  /// Profundidad máxima permitida.
  final int maxDepth;

  /// Hijos máximos por contenedor.
  final int maxChildren;

  /// Nodo resaltado como seleccionado.
  final String? selectedNodeId;

  /// Se invoca al tocar un nodo (para seleccionarlo en el editor).
  final void Function(CanvasNode node)? onNodeTap;

  /// Se invoca al soltar un nodo arrastrado sobre otro: `(dragged, target)`.
  final void Function(String draggedId, String targetId)? onNodeDrop;

  /// Se invoca al soltar un componente de la paleta sobre un nodo:
  /// `(tipo, targetId)`; se inserta antes del destino.
  final void Function(String componentType, String targetId)? onComponentDrop;

  /// Controlador para el scroll del cuerpo de la pantalla (lo aporta el editor
  /// para poder mostrar la barra de desplazamiento).
  final ScrollController? screenScrollController;

  /// Muestra el menú lateral (`overlay`) al costado; cerrado está oculto.
  final bool showDrawer;

  /// Muestra el menú lateral derecho (`drawerEnd`).
  final bool showEndDrawer;

  @override
  Widget build(BuildContext context) => _build(context, node, 0);

  /// Pantalla: barra superior fija, cuerpo con scroll y barra inferior al pie.
  Widget _buildScreen(
    BuildContext context,
    CanvasNode screen,
    int depth,
    ComponentCatalog activeCatalog,
  ) {
    final definition = activeCatalog[screen.type]!;
    final values = <String, Object?>{
      for (final spec in definition.properties)
        spec.key: spec.coerce(screen.properties[spec.key]),
    };
    final padding = (values['padding'] as num?)?.toDouble() ?? 16;
    final gap = (values['gap'] as num?)?.toDouble() ?? 12;
    final scroll = values['scroll'] as bool? ?? true;
    // `resizeToAvoidBottomInset` no cambia la vista previa (depende del
    // teclado en tiempo de ejecución); se guarda como dato del modelo.

    final top = <CanvasNode>[];
    final bottom = <CanvasNode>[];
    final overlay = <CanvasNode>[];
    final drawerEnd = <CanvasNode>[];
    final fab = <CanvasNode>[];
    final body = <CanvasNode>[];

    for (final child in screen.children.take(maxChildren)) {
      if (child.properties['visible'] == false) {
        continue;
      }
      switch (activeCatalog[child.type]?.slot ?? ComponentSlot.body) {
        case ComponentSlot.top:
          top.add(child);
        case ComponentSlot.bottom:
          bottom.add(child);
        case ComponentSlot.overlay:
          overlay.add(child);
        case ComponentSlot.drawerEnd:
          drawerEnd.add(child);
        case ComponentSlot.fab:
          fab.add(child);
        case ComponentSlot.body:
          body.add(child);
      }
    }

    final bodyWidgets = [
      for (final child in body) _build(context, child, depth + 1),
    ];
    final theme = Theme.of(context);
    final isEmpty = bodyWidgets.isEmpty;

    Widget bodyContent = isEmpty
        ? Center(child: _EmptyCanvasState(theme: theme))
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _withGaps(bodyWidgets, gap),
          );

    if (!isEmpty) {
      bodyContent = Padding(
        padding: EdgeInsets.all(padding),
        child: bodyContent,
      );

      final responsive = values['responsive'] as bool? ?? true;
      final contentWidth = (values['contentWidth'] as num?)?.toDouble() ?? 480;
      if (!responsive) {
        bodyContent = Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: bodyContent,
          ),
        );
      }
    }

    final scrolled = isEmpty
        ? bodyContent
        : scroll
        ? (screenScrollController != null
              ? Scrollbar(
                  controller: screenScrollController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: screenScrollController,
                    child: bodyContent,
                  ),
                )
              : SingleChildScrollView(child: bodyContent))
        : bodyContent;

    final content = Column(
      children: [
        for (final node in top) _build(context, node, depth + 1),
        Expanded(child: scrolled),
        for (final node in bottom) _build(context, node, depth + 1),
      ],
    );

    Widget composed = content;

    if (showDrawer && overlay.isNotEmpty) {
      composed = Row(
        children: [
          _build(context, overlay.first, depth + 1),
          Expanded(child: composed),
        ],
      );
    }
    if (showEndDrawer && drawerEnd.isNotEmpty) {
      composed = Row(
        children: [
          Expanded(child: composed),
          _build(context, drawerEnd.first, depth + 1),
        ],
      );
    }
    if (fab.isNotEmpty) {
      composed = Stack(
        children: [
          Positioned.fill(child: composed),
          Positioned(
            right: 16,
            bottom: 16,
            child: _build(context, fab.first, depth + 1),
          ),
        ],
      );
    }

    final scheme = theme.colorScheme;
    final background = colorForValue(
      values['background'] as String?,
      scheme,
    );

    return ColoredBox(color: background, child: composed);
  }

  /// Barra inferior con un ítem por cada nodo `navItem`.
  Widget _buildBottomNavContent(
    BuildContext context,
    CanvasNode node,
    Map<String, Object?> values,
    ComponentCatalog activeCatalog,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final items = <BottomNavigationBarItem>[];

    for (final child in node.children) {
      if (child.type != 'icon' && child.type != 'navItem') {
        continue;
      }
      final definition = activeCatalog[child.type];
      if (definition == null) {
        continue;
      }
      final childValues = <String, Object?>{
        for (final spec in definition.properties)
          spec.key: spec.coerce(child.properties[spec.key]),
      };
      items.add(
        BottomNavigationBarItem(
          icon: Icon(iconDataFor(childValues['icon'] as String? ?? 'home')),
          label: childValues['label'] as String? ?? '',
        ),
      );
    }

    if (items.isEmpty) {
      // Compatibilidad con pantallas viejas que guardaban solo la cantidad.
      final fallback = int.tryParse(
        node.properties['items']?.toString() ?? '3',
      )?.clamp(2, 5) ?? 3;
      const labels = ['Inicio', 'Buscar', 'Favorito', 'Ajustes', 'Perfil'];
      const icons = [
        Icons.home,
        Icons.search,
        Icons.favorite,
        Icons.settings,
        Icons.person,
      ];
      for (var index = 0; index < fallback; index++) {
        items.add(
          BottomNavigationBarItem(
            icon: Icon(icons[index]),
            label: labels[index],
          ),
        );
      }
    }

    Color? colorFor(String key) {
      final value = values[key] as String? ?? '';
      return value.isEmpty ? null : colorForValue(value, scheme);
    }

    final selected = ((values['selected'] as num?)?.round() ?? 0)
        .clamp(0, items.length - 1)
        .toInt();

    return BottomNavigationBar(
      currentIndex: selected,
      type: values['type'] == 'shifting'
          ? BottomNavigationBarType.shifting
          : BottomNavigationBarType.fixed,
      backgroundColor: colorFor('backgroundColor'),
      selectedItemColor: colorFor('selectedItemColor'),
      unselectedItemColor: colorFor('unselectedItemColor'),
      elevation: (values['elevation'] as num?)?.toDouble() ?? 8,
      iconSize: (values['iconSize'] as num?)?.toDouble() ?? 24,
      selectedFontSize:
          (values['selectedFontSize'] as num?)?.toDouble() ?? 14,
      unselectedFontSize:
          (values['unselectedFontSize'] as num?)?.toDouble() ?? 12,
      showSelectedLabels: values['showSelectedLabels'] as bool? ?? true,
      showUnselectedLabels: values['showUnselectedLabels'] as bool? ?? true,
      items: items,
    );
  }

  /// AppBar con sus hijos separados por `position` (leading / acciones).
  Widget _buildAppBarContent(
    BuildContext context,
    CanvasNode node,
    int depth,
    ComponentCatalog activeCatalog,
    Map<String, Object?> values,
  ) {
    final leading = <Widget>[];
    final actions = <Widget>[];
    final foregroundValue = values['foregroundColor'] as String? ?? '';
    final foreground = foregroundValue.isEmpty
        ? null
        : colorForValue(
            foregroundValue,
            Theme.of(context).colorScheme,
          );

    for (final child in node.children.take(maxChildren)) {
      final isLeading =
          child.type == 'icon' && child.properties['position'] == 'leading';
      // Los íconos con color "heredar" toman el `foregroundColor` de la barra.
      final widget = foreground == null
          ? _build(context, child, depth + 1)
          : IconTheme(
              data: IconThemeData(color: foreground),
              child: Builder(
                builder: (inner) => _build(inner, child, depth + 1),
              ),
            );
      if (isLeading) {
        leading.add(widget);
      } else {
        actions.add(widget);
      }
    }

    final rawBar = buildAppBarWidget(
      context,
      Props(values),
      leading: leading,
      actions: actions,
    );

    // El lienzo apila la barra dentro de una Column (altura no acotada); la
    // AppBar con `bottom`/`flexibleSpace` necesita altura finita, así que le
    // damos exactamente su `preferredSize`.
    final toolbar = (values['toolbarHeight'] as num?)?.toDouble() ?? 56;
    final bar = SizedBox(
      height: toolbar <= 0 ? 56 : toolbar,
      child: rawBar,
    );

    final controller = screenScrollController;
    if (values['hideOnScroll'] == true && controller != null) {
      return _CollapsibleAppBar(controller: controller, child: bar);
    }
    return bar;
  }

  /// Separa widgets con un hueco vertical.
  static List<Widget> _withGaps(List<Widget> children, double gap) {
    if (gap <= 0 || children.length < 2) {
      return children;
    }
    final result = <Widget>[];
    for (var index = 0; index < children.length; index++) {
      if (index > 0) {
        result.add(SizedBox(height: gap));
      }
      result.add(children[index]);
    }
    return result;
  }

  Widget _build(BuildContext context, CanvasNode current, int depth) {
    final activeCatalog = catalog ?? standardCatalog;
    final definition = activeCatalog[current.type];

    if (definition == null) {
      return _InvalidComponent(
        nodeId: current.id,
        message: 'Componente desconocido: ${current.type}',
      );
    }
    if (depth >= maxDepth) {
      return _InvalidComponent(
        nodeId: current.id,
        message: 'Árbol demasiado profundo',
      );
    }

    // La pantalla tiene semántica propia: barra superior fija, cuerpo
    // desplazable y barra inferior al pie; el menú lateral se superpone.
    if (definition.type == 'screen') {
      return _buildScreen(context, current, depth, activeCatalog);
    }

    final values = <String, Object?>{
      for (final spec in definition.properties)
        spec.key: spec.coerce(current.properties[spec.key]),
    };

    final children = definition.acceptsChildren
        ? current.children
              .take(maxChildren)
              .map((child) => _build(context, child, depth + 1))
              .toList(growable: false)
        : const <Widget>[];

    final built = switch (definition.type) {
      'appBar' => _buildAppBarContent(
        context,
        current,
        depth,
        activeCatalog,
        values,
      ),
      'bottomNav' => _buildBottomNavContent(
        context,
        current,
        values,
        activeCatalog,
      ),
      _ => definition.builder(context, Props(values), children),
    };
    final isSelected = current.id == selectedNodeId;

    // En modo edición, los componentes hoja (botón, campo, ícono…) no deben
    // consumir el toque: si no, su InkWell gana la arena de gestos y el nodo
    // nunca se selecciona. Los contenedores NO se absorben para que sus hijos
    // sigan siendo seleccionables.
    final content = (onNodeTap != null && !definition.acceptsChildren)
        ? AbsorbPointer(child: built)
        : built;

    final selectable = (onNodeTap == null && !isSelected)
        ? content
        : GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onNodeTap == null ? null : () => onNodeTap!(current),
            child: DecoratedBox(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : const BoxDecoration(),
              child: content,
            ),
          );

    var wrapped = selectable;

    if (onNodeDrop != null || onComponentDrop != null) {
      final inner = wrapped;
      wrapped = DragTarget<EditorDragData>(
        onWillAcceptWithDetails: (details) {
          final id = details.data.nodeId;
          if (id != null) {
            return onNodeDrop != null && id != current.id;
          }
          final type = details.data.componentType;
          if (onComponentDrop == null || type == null) {
            return false;
          }
          if (activeCatalog[type] == null) {
            return false;
          }
          // Solo se sueltan componentes en el cuerpo; en la AppBar, íconos
          // (acciones). Las demás barras son de sistema.
          if (definition.slot == ComponentSlot.top) {
            return type == 'icon';
          }
          if (definition.slot == ComponentSlot.bottom) {
            return type == 'icon' || type == 'navItem';
          }
          if (definition.slot != ComponentSlot.body) {
            return false;
          }
          return true;
        },
        onAcceptWithDetails: (details) {
          final id = details.data.nodeId;
          if (id != null) {
            onNodeDrop?.call(id, current.id);
            return;
          }
          final type = details.data.componentType;
          if (type != null) {
            onComponentDrop?.call(type, current.id);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final hovering = candidateData.isNotEmpty;
          return DecoratedBox(
            decoration: hovering
                ? BoxDecoration(
                    // Línea superior: indica "se inserta antes de este nodo".
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  )
                : const BoxDecoration(),
            child: inner,
          );
        },
      );

      // La raíz no se arrastra (no tiene padre donde reinsertarse).
      if (depth > 0) {
        final target = wrapped;
        wrapped = Draggable<EditorDragData>(
          data: EditorDragData.node(current.id),
          feedback: _NodeDragFeedback(label: definition.label),
          childWhenDragging: Opacity(opacity: 0.4, child: target),
          child: target,
        );
      }
    }

    return KeyedSubtree(key: ValueKey(current.id), child: wrapped);
  }
}

/// Etiqueta que sigue al puntero mientras se arrastra un nodo.
class _NodeDragFeedback extends StatelessWidget {
  const _NodeDragFeedback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

/// Marcador visible cuando un nodo no se puede construir.
class _InvalidComponent extends StatelessWidget {
  const _InvalidComponent({required this.nodeId, required this.message});

  final String nodeId;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey('invalid.$nodeId'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.error),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.report_problem_outlined, size: 16, color: scheme.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra que se pliega al bajar el scroll y vuelve al subir.
class _CollapsibleAppBar extends StatefulWidget {
  const _CollapsibleAppBar({required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  State<_CollapsibleAppBar> createState() => _CollapsibleAppBarState();
}

class _CollapsibleAppBarState extends State<_CollapsibleAppBar> {
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(_CollapsibleAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final hidden = widget.controller.offset > 24;
    if (hidden != _hidden) {
      setState(() => _hidden = hidden);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedAlign(
        alignment: Alignment.topCenter,
        heightFactor: _hidden ? 0 : 1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Estado vacío del lienzo: icono, título e instrucción centrados.
class _EmptyCanvasState extends StatelessWidget {
  const _EmptyCanvasState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.dashboard_customize_outlined,
              size: 26,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Tu pantalla está vacía',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Arrastra un widget desde la biblioteca o haz clic en uno '
            'para empezar.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
