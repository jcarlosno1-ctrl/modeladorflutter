import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Claves de widget que forman el contrato entre [MainLayout] y sus tests.
///
/// Se declaran aquí, y no como cadenas sueltas en los tests, para que el
/// contrato no dependa de textos visibles (que cambian con la traducción) ni
/// del árbol interno (que cambia al refactorizar).
abstract final class MainLayoutKeys {
  /// Panel de herramientas, alineado a la izquierda del lienzo.
  static const Key toolsPanel = Key('main_layout.tools_panel');

  /// Panel de propiedades, alineado a la derecha del lienzo.
  static const Key propertiesPanel = Key('main_layout.properties_panel');

  /// Acción que abre el panel de herramientas en modo compacto.
  static const Key openToolsButton = Key('main_layout.open_tools');

  /// Acción que abre el panel de propiedades como [EndDrawer].
  static const Key openPropertiesButton = Key('main_layout.open_properties');

  /// Asa para redimensionar el panel de herramientas.
  static const Key toolsResize = Key('main_layout.tools_resize');

  /// Asa para redimensionar el panel de propiedades.
  static const Key propertiesResize = Key('main_layout.properties_resize');
}

/// Modos de layout derivados del ancho disponible.
///
/// Es privado a propósito: el resto de la app no debe ramificar por ancho
/// (regla del proyecto: el corte se calcula **una sola vez** en [MainLayout]).
enum _LayoutMode {
  /// `<600`: ambos paneles en cajones.
  compact,

  /// `600–1024`: herramientas fijas, propiedades en [EndDrawer].
  medium,

  /// `>1024`: ambos paneles fijos.
  expanded,
}

/// Shell responsivo: herramientas, lienzo y propiedades.
///
/// Responsabilidades (y nada más):
/// - Medir el ancho con [LayoutBuilder].
/// - Elegir el [_LayoutMode].
/// - Componer paneles y cajones.
///
/// El contenido es inyectable ([toolsContent], [canvasContent],
/// [propertiesContent]); si no se pasa, se muestran los placeholders. Así el
/// shell no conoce el editor ni el negocio.
///
/// Contrato: `docs/aceptacion/layout_responsivo.feature` y
/// `test/main_layout_test.dart`.
class MainLayout extends StatefulWidget {
  /// Crea el shell del modelador.
  ///
  /// [title] se muestra en la barra superior (por defecto, "Modelador"; el
  /// editor lo reemplaza por el nombre del proyecto).
  const MainLayout({
    super.key,
    this.title = 'Modelador',
    this.toolsContent,
    this.canvasContent,
    this.propertiesContent,
    this.appBarActions = const [],
    this.projectStatus,
  });

  /// Título de la barra superior.
  final String title;

  /// Acciones extra en la barra superior (copiar, etc.).
  final List<Widget> appBarActions;

  /// Indicador de guardado que se muestra junto al nombre del proyecto.
  final Widget? projectStatus;

  /// Contenido del panel de herramientas.
  final Widget? toolsContent;

  /// Contenido del área central.
  final Widget? canvasContent;

  /// Contenido del panel de propiedades.
  final Widget? propertiesContent;

  /// Ancho mínimo (exclusivo) a partir del cual se considera modo expandido.
  static const double expandedMinWidth = 1024;

  /// Ancho por debajo del cual todo se colapsa en cajones.
  static const double compactMaxWidth = 600;

  /// Ancho fijo de cada panel lateral.
  static const double panelWidth = 280;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  double _toolsWidth = MainLayout.panelWidth;
  double _propertiesWidth = MainLayout.panelWidth;

  void _resizeTools(double delta, double maxWidth) {
    setState(() {
      final max = (maxWidth - _propertiesWidth - 340).clamp(220.0, 480.0);
      _toolsWidth = (_toolsWidth + delta).clamp(220.0, max);
    });
  }

  void _resizeProperties(double delta, double maxWidth) {
    setState(() {
      final max = (maxWidth - _toolsWidth - 340).clamp(220.0, 480.0);
      _propertiesWidth = (_propertiesWidth - delta).clamp(220.0, max);
    });
  }

  /// Traduce un ancho lógico a su modo de layout.
  ///
  /// Los umbrales son inclusivos por abajo: `600` y `1024` caen en [medium].
  static _LayoutMode _modeFor(double width) {
    if (width < MainLayout.compactMaxWidth) {
      return _LayoutMode.compact;
    }
    if (width <= MainLayout.expandedMinWidth) {
      return _LayoutMode.medium;
    }
    return _LayoutMode.expanded;
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final toolsContent = widget.toolsContent;
    final canvasContent = widget.canvasContent;
    final propertiesContent = widget.propertiesContent;
    final appBarActions = widget.appBarActions;
    final projectStatus = widget.projectStatus;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = _modeFor(constraints.maxWidth);
        final showTools = mode != _LayoutMode.compact;
        final showProperties = mode == _LayoutMode.expanded;
        final canPop = Navigator.of(context).canPop();
        final showMenu = mode == _LayoutMode.compact;

        final tools = _SidePanel(
          key: MainLayoutKeys.toolsPanel,
          title: 'Biblioteca',
          icon: Icons.grid_view_rounded,
          child: toolsContent ?? const _PanelPlaceholder(text: 'Paleta de componentes'),
        );
        final properties = _SidePanel(
          key: MainLayoutKeys.propertiesPanel,
          title: 'Propiedades',
          icon: Icons.tune_outlined,
          child: propertiesContent ?? const _PanelPlaceholder(text: 'Sin selección'),
        );
        final canvas = canvasContent ?? const _CanvasPlaceholder();

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 64,
            titleSpacing: 0,
            title: LayoutBuilder(
              builder: (context, titleConstraints) {
                final width = titleConstraints.maxWidth;
                final showBrand = width > 300;
                final showProject = width > 540 && title.isNotEmpty;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Marca con el punto amarillo, como la referencia.
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.widgets_rounded,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFACC15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showBrand) ...[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Flutter Studio Apps',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textStrong,
                              ),
                            ),
                            const Text(
                              'Modelador visual de apps',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (showProject) ...[
                      const SizedBox(width: 18),
                      Container(
                        width: 1,
                        height: 34,
                        color: AppTheme.border,
                      ),
                      const SizedBox(width: 18),
                      const Icon(
                        Icons.folder_outlined,
                        size: 17,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textStrong,
                          ),
                        ),
                      ),
                      if (projectStatus != null) ...[
                        const SizedBox(width: 10),
                        projectStatus,
                      ],
                    ],
                  ],
                );
              },
            ),
            // El cajón izquierdo solo existe en compacto; el botón también.
            // Si el shell está dentro de otra ruta, se agrega "atrás".
            leading: (canPop || showMenu)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canPop) const BackButton(),
                      if (showMenu)
                        Builder(
                          builder: (context) => IconButton(
                            key: MainLayoutKeys.openToolsButton,
                            tooltip: 'Herramientas',
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                    ],
                  )
                : null,
            leadingWidth: (canPop && showMenu) ? 96 : null,
            actions: [
              ...appBarActions,
              if (!showProperties)
                Builder(
                  builder: (context) => IconButton(
                    key: MainLayoutKeys.openPropertiesButton,
                    tooltip: 'Propiedades',
                    icon: const Icon(Icons.tune),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              const SizedBox(width: 8),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: SizedBox(
                height: 1,
                child: ColoredBox(color: AppTheme.border),
              ),
            ),
          ),
          drawer: mode == _LayoutMode.compact
              ? Drawer(child: tools)
              : null,
          endDrawer: showProperties ? null : Drawer(child: properties),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTools) ...[
                SizedBox(width: _toolsWidth, child: tools),
                _ResizeHandle(
                  key: MainLayoutKeys.toolsResize,
                  onDrag: (delta) =>
                      _resizeTools(delta, constraints.maxWidth),
                ),
              ],
              Expanded(child: canvas),
              if (showProperties) ...[
                _ResizeHandle(
                  key: MainLayoutKeys.propertiesResize,
                  onDrag: (delta) =>
                      _resizeProperties(delta, constraints.maxWidth),
                ),
                SizedBox(width: _propertiesWidth, child: properties),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Asa vertical para redimensionar un panel arrastrando.
class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({required this.onDrag, super.key});

  final ValueChanged<double> onDrag;

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: (details) => widget.onDrag(details.delta.dx),
        child: SizedBox(
          width: 7,
          child: Center(
            child: Container(
              width: 1,
              color: _hover ? AppTheme.primary : AppTheme.border,
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel lateral con título y contenido desplazable.
///
/// Es la pieza DRY que comparten herramientas y propiedades: mismo ancho,
/// mismo fondo, misma cabecera.
class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textStrong,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Material transparente: el panel pinta sobre ColoredBox y los
          // ListTile/SwitchListTile necesitan un Material para su tinta.
          Expanded(
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ],
      ),
    );
  }
}

/// Mensaje centrado para paneles aún vacíos.
class _PanelPlaceholder extends StatelessWidget {
  const _PanelPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Lienzo central (placeholder cuando no hay editor conectado).
class _CanvasPlaceholder extends StatelessWidget {
  const _CanvasPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Center(
        child: Text(
          'Lienzo',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
