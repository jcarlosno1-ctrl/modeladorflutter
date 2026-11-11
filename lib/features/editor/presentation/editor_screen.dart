import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/app/app_theme.dart';
import 'package:modeladorflutter/app/main_layout.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';

import '../application/editor_session.dart';
import '../catalog/color_value.dart';
import '../catalog/property_spec.dart';
import '../catalog/standard_catalog.dart';
import '../catalog/widget_definition.dart';
import '../codegen/dart_code_generator.dart';
import '../codegen/project_export.dart';
import '../domain/canvas_node.dart';
import '../../projects/domain/project_theme.dart';
import '../../projects/presentation/project_theme_data.dart';
import 'editor_drag_data.dart';
import 'widget_renderer.dart';

/// Claves usadas por los tests del editor.
abstract final class EditorKeys {
  /// Categoría de la paleta (pestaña del riel izquierdo).
  static Key category(String name) => ValueKey<String>('editor.category.$name');

  /// Componente de la paleta (arrastrable e insertable con toque).
  static Key paletteItem(String type) =>
      ValueKey<String>('editor.palette.$type');

  /// Lienzo (artboard) con la pantalla.
  static const Key canvas = Key('editor.canvas');

  /// Mensaje de error de carga/guardado.
  static const Key error = Key('editor.error');

  /// Estado de guardado ("Guardado", "Guardando…").
  static const Key status = Key('editor.status');

  /// Campo del panel de propiedades para una clave concreta.
  static Key propertyField(String key) => ValueKey<String>('editor.prop.$key');

  /// Fila del árbol de componentes en el panel izquierdo.
  static Key nodeTile(String id) => ValueKey<String>('editor.node.$id');

  /// Acción para eliminar el nodo seleccionado.
  static const Key deleteNode = Key('editor.delete.node');

  /// Pestaña de una pantalla.
  static Key screenTab(String id) => ValueKey<String>('editor.screen.$id');

  /// Acción "+" para crear una pantalla.
  static const Key addScreen = Key('editor.addScreen');

  /// Botón "subir" de una fila del árbol.
  static Key moveUp(String id) => ValueKey<String>('editor.up.$id');

  /// Botón "bajar" de una fila del árbol.
  static Key moveDown(String id) => ValueKey<String>('editor.down.$id');

  /// Botón "eliminar" de una fila del árbol.
  static Key deleteLayer(String id) => ValueKey<String>('editor.layer.delete.$id');

  /// Deshacer / rehacer desde la barra del lienzo.
  static const Key undoAction = Key('editor.undo');
  static const Key redoAction = Key('editor.redo');

  /// Botón "sacar un nivel" de una fila del árbol.
  static Key outdentNode(String id) => ValueKey<String>('editor.outdent.$id');

  /// Botón "meter dentro del anterior" de una fila del árbol.
  static Key indentNode(String id) => ValueKey<String>('editor.indent.$id');

  /// Muestra u oculta el menú lateral en la vista previa.
  static const Key toggleDrawer = Key('editor.drawer.toggle');

  /// Muestra u oculta el menú lateral derecho.
  static const Key toggleEndDrawer = Key('editor.endDrawer.toggle');

  /// Barra de modo Diseño/Código.
  static const Key canvasModeBar = Key('editor.mode.bar');

  /// Nota con la ruta del archivo exportado.
  static const Key codeNote = Key('editor.code.note');

  /// Código generado.
  static const Key codeView = Key('editor.code.view');

  /// Botón copiar código.
  static const Key copyCode = Key('editor.code.copy');

  /// Diálogo de renombrado del archivo.
  static const Key renameField = Key('editor.rename.field');

  /// Abre el tema del proyecto.
  static const Key theme = Key('editor.theme');

  /// Guarda el tema.
  static const Key themeSave = Key('editor.theme.save');

  /// Campo hex del tema.
  static Key themeHex(String key) => ValueKey<String>('editor.theme.$key');

  /// Acción de renombrar una pestaña.
  static Key renameScreen(String id) => ValueKey<String>('editor.rename.$id');

  /// Lista del panel de propiedades.
  static const Key propertiesList = Key('editor.properties.list');

  /// Título del componente seleccionado en el panel.
  static const Key propertiesTitle = Key('editor.properties.title');

  /// Estado de guardado en la barra superior.
  static const Key topStatus = Key('editor.top.status');

  /// Copiar código desde la barra superior.
  static const Key copyFromTop = Key('editor.top.copy');

  /// Exportar main.dart y screens/*.dart en un ZIP.
  static const Key exportFiles = Key('editor.top.export');

  /// Buscador de la biblioteca.
  static const Key librarySearch = Key('editor.library.search');

  /// Contador de capas del árbol.
  static const Key layersCount = Key('editor.layers.count');

  /// Selector de dispositivo del lienzo.
  static const Key deviceSelector = Key('editor.device.selector');

  /// Opción de dispositivo del lienzo.
  static Key deviceOption(String device) =>
      ValueKey<String>('editor.device.$device');

  /// Salta a la pantalla (raíz) desde el árbol de capas.
  static const Key jumpToScreen = Key('editor.layers.screen');

  /// Abre el selector de color de una propiedad.
  static Key colorPalette(String key) =>
      ValueKey<String>('editor.color.$key.palette');

  /// Campo Hex del diálogo de color.
  static const Key dialogHex = Key('editor.color.dialog.hex');

  /// Aplica el color elegido en el diálogo.
  static const Key applyColor = Key('editor.color.apply');

  /// Muestra u oculta las propiedades avanzadas.
  static const Key advancedToggle = Key('editor.properties.advanced');

  /// Controles de zoom del lienzo.
  static const Key zoomIn = Key('editor.zoom.in');
  static const Key zoomOut = Key('editor.zoom.out');
  static const Key zoomReset = Key('editor.zoom.reset');
  static const Key zoomLabel = Key('editor.zoom.label');
}

/// Editor de un proyecto.
///
/// Carga la primera pantalla (`project_screens`), la dibuja con
/// [WidgetRenderer] y guarda cada cambio en el backend.
class EditorScreen extends ConsumerStatefulWidget {
  /// Crea el editor para [project].
  const EditorScreen({required this.project, super.key});

  /// Proyecto abierto.
  final Project project;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  @override
  void initState() {
    super.initState();
    // Después del primer frame: abrir no debe mutar providers durante build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(editorSessionProvider.notifier).openProject(widget.project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorSessionProvider);
    final root = state.root;

    String? code;
    if (root != null) {
      final isEntry =
          state.screens.isNotEmpty && state.screens.first.id == state.screenId;
      final fileName =
          state.screenName ?? (isEntry ? 'main.dart' : 'pantalla.dart');
      code = DartCodeGenerator.generate(
        screen: root,
        fileName: fileName,
        isEntry: isEntry,
        theme: state.theme,
      );
    }

    final compact = MediaQuery.sizeOf(context).width < 900;

    Future<void> copyCode() async {
      final codeToCopy = code;
      if (codeToCopy == null) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: codeToCopy));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código copiado al portapapeles')),
        );
      }
    }

    final statusLabel = state.isSaving
        ? 'Guardando…'
        : state.isDirty
        ? 'Cambios sin guardar'
        : 'Guardado';

    void deleteSelected() {
      final current = ref.read(editorSessionProvider);
      final id = current.selectedNodeId;
      if (id == null || id == current.root?.id) {
        return;
      }
      ref.read(editorSessionProvider.notifier).removeNode(id);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.delete): deleteSelected,
        const SingleActivator(LogicalKeyboardKey.backspace): deleteSelected,
      },
      child: Focus(
        autofocus: true,
        child: MainLayout(
      title: widget.project.name,
      projectStatus: root == null ? null : _SaveStatusPill(label: statusLabel),
      appBarActions: [
        if (root != null) ...[
          IconButton(
            key: EditorKeys.exportFiles,
            tooltip: 'Exportar archivos .dart',
            icon: const Icon(Icons.download_outlined),
            onPressed: state.screens.isEmpty
                ? null
                : () async {
                    final count = await exportProjectZip(
                      screens: state.screens,
                      entryScreenId: state.screens.first.id,
                      projectName: widget.project.name,
                      theme: state.theme,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          count == 0
                              ? 'Nada para exportar'
                              : 'ZIP con $count archivos .dart',
                        ),
                      ),
                    );
                  },
          ),
          const SizedBox(width: 4),
          if (!compact)
            FilledButton.icon(
              key: EditorKeys.copyFromTop,
              onPressed: code == null ? null : copyCode,
              icon: const Icon(Icons.copy_all_outlined, size: 15),
              label: const Text('Copiar código'),
            )
          else
            IconButton(
              key: EditorKeys.copyFromTop,
              tooltip: 'Copiar código',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: code == null ? null : copyCode,
            ),
        ],
      ],
      toolsContent: const _EditorTools(),
      canvasContent: const _EditorCanvas(),
      propertiesContent: const _EditorProperties(),
        ),
      ),
    );
  }
}

/// Indicador de guardado con icono de nube, junto al nombre del proyecto.
class _SaveStatusPill extends StatelessWidget {
  const _SaveStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_done_outlined,
            size: 13,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            key: EditorKeys.status,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel de herramientas: paleta por categorías + árbol de componentes.
class _EditorTools extends ConsumerStatefulWidget {
  const _EditorTools();

  @override
  ConsumerState<_EditorTools> createState() => _EditorToolsState();
}

class _EditorToolsState extends ConsumerState<_EditorTools> {
  double _paletteShare = 0.6;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorSessionProvider);
    final theme = Theme.of(context);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.screenName ?? 'Sin pantalla',
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: EditorKeys.theme,
                    tooltip: 'Tema del proyecto',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(Icons.palette_outlined, size: 18),
                    onPressed: () => _openTheme(context, ref),
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.error!,
                  key: EditorKeys.error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final total = (constraints.maxHeight - 8).clamp(
                120.0,
                double.infinity,
              );
              return Column(
                children: [
                  SizedBox(
                    height: total * _paletteShare,
                    child: const _EditorPalette(),
                  ),
                  _HorizontalResizeHandle(
                    onDrag: (delta) => setState(
                      () => _paletteShare = (_paletteShare + delta / total)
                          .clamp(0.35, 0.8),
                    ),
                  ),
                  const Expanded(child: _EditorTree()),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Abre el tema del proyecto y lo guarda si el usuario confirma.
  Future<void> _openTheme(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(editorSessionProvider.notifier);
    final current = ref.read(editorSessionProvider).theme;
    final result = await showDialog<ProjectTheme>(
      context: context,
      builder: (_) => _ThemeDialog(initial: current),
    );
    if (result != null) {
      await notifier.saveTheme(result);
    }
  }
}

/// Diálogo del tema del proyecto: colores, tipografías y botones.
class _ThemeDialog extends StatefulWidget {
  const _ThemeDialog({required this.initial});

  final ProjectTheme initial;

  @override
  State<_ThemeDialog> createState() => _ThemeDialogState();
}

class _ThemeDialogState extends State<_ThemeDialog> {
  late ProjectTheme _theme = widget.initial;
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controllerFor(String key, String value) =>
      _controllers.putIfAbsent(key, () => TextEditingController(text: value));

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateColor(
    String key,
    String value,
    ProjectTheme Function(ProjectTheme, String) apply,
  ) {
    if (value.isEmpty || RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
      setState(() => _theme = apply(_theme, value.toUpperCase()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Tema del proyecto'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Colores', style: theme.textTheme.titleSmall),
              _hexRow(
                'primary',
                'Primario',
                _theme.primary,
                (t, v) => t.copyWith(primary: v),
              ),
              _hexRow(
                'secondary',
                'Secundario',
                _theme.secondary,
                (t, v) => t.copyWith(secondary: v),
              ),
              _hexRow(
                'tertiary',
                'Terciario',
                _theme.tertiary,
                (t, v) => t.copyWith(tertiary: v),
              ),
              const SizedBox(height: 12),
              Text('AppBar', style: theme.textTheme.titleSmall),
              _hexRow(
                'appBarBackground',
                'Fondo (opcional)',
                _theme.appBarBackground,
                (t, v) => t.copyWith(appBarBackground: v),
              ),
              _hexRow(
                'appBarForeground',
                'Texto/íconos (opcional)',
                _theme.appBarForeground,
                (t, v) => t.copyWith(appBarForeground: v),
              ),
              _sliderRow(
                'Tamaño del título',
                _theme.appBarTitleSize,
                12,
                32,
                (v) => _theme = _theme.copyWith(appBarTitleSize: v),
              ),
              const SizedBox(height: 12),
              Text('Textos', style: theme.textTheme.titleSmall),
              _sliderRow(
                'Texto normal',
                _theme.bodySize,
                10,
                24,
                (v) => _theme = _theme.copyWith(bodySize: v),
              ),
              _sliderRow(
                'Títulos',
                _theme.titleSize,
                12,
                40,
                (v) => _theme = _theme.copyWith(titleSize: v),
              ),
              _sliderRow(
                'Etiquetas y botones',
                _theme.labelSize,
                10,
                24,
                (v) => _theme = _theme.copyWith(labelSize: v),
              ),
              _sliderRow(
                'Campos de texto',
                _theme.inputSize,
                10,
                28,
                (v) => _theme = _theme.copyWith(inputSize: v),
              ),
              const SizedBox(height: 12),
              Text('Líneas y botones', style: theme.textTheme.titleSmall),
              _hexRow(
                'dividerColor',
                'Color de líneas (opcional)',
                _theme.dividerColor,
                (t, v) => t.copyWith(dividerColor: v),
              ),
              _sliderRow(
                'Radio de botones',
                _theme.buttonRadius,
                0,
                32,
                (v) => _theme = _theme.copyWith(buttonRadius: v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: EditorKeys.themeSave,
          onPressed: () => Navigator.of(context).pop(_theme),
          child: const Text('Guardar tema'),
        ),
      ],
    );
  }

  Widget _hexRow(
    String key,
    String label,
    String value,
    ProjectTheme Function(ProjectTheme, String) apply,
  ) {
    final parsed = value.startsWith('#')
        ? int.tryParse(value.substring(1), radix: 16)
        : null;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              key: EditorKeys.themeHex(key),
              controller: _controllerFor(key, value),
              onChanged: (raw) => _updateColor(key, raw.trim(), apply),
              decoration: const InputDecoration(
                hintText: '#RRGGBB',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: parsed == null ? null : Color(0xFF000000 | parsed),
              shape: BoxShape.circle,
              border: Border.all(color: scheme.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderRow(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
        Text(value.round().toString(), style: theme.textTheme.labelSmall),
        SizedBox(
          width: 160,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (next) => setState(() => onChanged(next)),
          ),
        ),
      ],
    );
  }
}

/// Paleta: riel de categorías a la izquierda y componentes a la derecha.
class _EditorPalette extends StatefulWidget {
  const _EditorPalette();

  @override
  State<_EditorPalette> createState() => _EditorPaletteState();
}

class _EditorPaletteState extends State<_EditorPalette> {
  // Solo estado de UI (qué pestaña se ve), por eso vive en el widget.
  ComponentCategory _category = ComponentCategory.basic;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final items = query.isEmpty
        ? standardCatalog.byCategory(_category)
        : (standardCatalog.definitions
                .where(
                  (definition) =>
                      definition.insertable &&
                      (definition.label.toLowerCase().contains(query) ||
                          definition.type.contains(query) ||
                          (definition.flutterClass?.toLowerCase().contains(
                                query,
                              ) ??
                              false)),
                )
                .toList()
              ..sort((a, b) => a.label.compareTo(b.label)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextField(
            key: EditorKeys.librarySearch,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Buscar widget…',
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: theme.colorScheme.surfaceContainer,
                child: SizedBox(
                  width: 48,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final category in ComponentCategory.values)
                          IconButton(
                            key: EditorKeys.category(category.name),
                            tooltip: _categoryLabel(category),
                            isSelected: category == _category,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            iconSize: 18,
                            icon: Icon(_categoryIcon(category)),
                            onPressed: () =>
                                setState(() => _category = category),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
                      child: Text(
                        (query.isEmpty
                                ? _categoryLabel(_category)
                                : 'Resultados')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Sin resultados',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisExtent: 42,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (context, index) => _PaletteItem(
                                definition: items[index],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Componente arrastrable de la paleta (también se inserta con un toque).
class _PaletteItem extends ConsumerWidget {
  const _PaletteItem({required this.definition});

  final WidgetDefinition definition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Draggable<EditorDragData>(
      data: EditorDragData.component(definition.type),
      // El lienzo está a la derecha: el arrastre es horizontal para no
      // pelearse con el scroll vertical de la lista.
      affinity: Axis.horizontal,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        color: theme.colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(definition.icon, size: 18),
              const SizedBox(width: 8),
              Text(definition.label),
            ],
          ),
        ),
      ),
      child: Tooltip(
        message: definition.flutterClass ?? definition.label,
        child: Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            key: EditorKeys.paletteItem(definition.type),
            borderRadius: BorderRadius.circular(8),
            // Doble clic para insertar (el arrastre sigue disponible).
            onDoubleTap: () => ref
                .read(editorSessionProvider.notifier)
                .addComponent(definition.type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      definition.icon,
                      size: 13,
                      color: AppTheme.textStrong,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      definition.label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textStrong,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Árbol de componentes del lienzo.
class _EditorTree extends ConsumerStatefulWidget {
  const _EditorTree();

  @override
  ConsumerState<_EditorTree> createState() => _EditorTreeState();
}

class _EditorTreeState extends ConsumerState<_EditorTree> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorSessionProvider);
    final root = state.root;
    if (root == null) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(editorSessionProvider.notifier);
    final nodes = _flatten(root);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(
                Icons.account_tree_outlined,
                size: 15,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              const Text(
                'Capas',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textStrong,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${nodes.length - 1}',
                key: EditorKeys.layersCount,
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
              const Spacer(),
              IconButton(
                key: EditorKeys.jumpToScreen,
                tooltip: 'Ir a la pantalla',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 26,
                  minHeight: 26,
                ),
                iconSize: 15,
                icon: const Icon(Icons.smartphone, color: AppTheme.textMuted),
                onPressed: () {
                  notifier.selectNode(root.id);
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 6),
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final entry = nodes[index];
              final selected = entry.node.id == state.selectedNodeId;
              final definition = standardCatalog[entry.node.type];
              final position = root.siblingPositionOf(entry.node.id);
              var canIndent = false;
              if (position != null && position.index > 0) {
                final parent = root.findNode(position.parentId);
                final previous = parent?.children[position.index - 1];
                canIndent =
                    previous != null &&
                    (standardCatalog[previous.type]?.acceptsChildren ?? false);
              }
              final canOutdent =
                  position != null && position.parentId != root.id;

              return InkWell(
                key: EditorKeys.nodeTile(entry.node.id),
                onTap: () => notifier.selectNode(entry.node.id),
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.primarySoft : null,
                    border: Border(
                      left: BorderSide(
                        color: selected
                            ? AppTheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.only(
                    left: 8 + entry.depth * 12,
                    right: 2,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        definition?.icon ?? Icons.widgets_outlined,
                        size: 13,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          _nodeLabel(entry.node),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textStrong,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _OrderButtons(
                        nodeId: entry.node.id,
                        position: position,
                        selected: selected,
                        canIndent: canIndent,
                        canOutdent: canOutdent,
                      ),
                      if (selected && entry.node.id != root.id)
                        IconButton(
                          key: EditorKeys.deleteLayer(entry.node.id),
                          tooltip: 'Eliminar',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          iconSize: 12,
                          onPressed: () =>
                              notifier.removeNode(entry.node.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Asa horizontal para ajustar el alto de la paleta y las capas.
class _HorizontalResizeHandle extends StatefulWidget {
  const _HorizontalResizeHandle({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  State<_HorizontalResizeHandle> createState() =>
      _HorizontalResizeHandleState();
}

class _HorizontalResizeHandleState extends State<_HorizontalResizeHandle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) => widget.onDrag(details.delta.dy),
        child: SizedBox(
          height: 8,
          child: Center(
            child: Container(
              height: 1,
              color: _hover ? AppTheme.primary : AppTheme.border,
            ),
          ),
        ),
      ),
    );
  }
}

/// Botones ↑/↓ para reordenar un nodo entre sus hermanos.
class _OrderButtons extends ConsumerWidget {
  const _OrderButtons({
    required this.nodeId,
    required this.position,
    required this.selected,
    required this.canIndent,
    required this.canOutdent,
  });

  final String nodeId;
  final ({int index, int count, String parentId})? position;
  final bool selected;
  final bool canIndent;
  final bool canOutdent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = this.position;
    if (position == null || !selected) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(editorSessionProvider.notifier);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: EditorKeys.moveUp(nodeId),
          tooltip: 'Subir',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          iconSize: 12,
          onPressed: position.index > 0
              ? () => notifier.moveNodeWithinParent(nodeId, -1)
              : null,
          icon: const Icon(Icons.keyboard_arrow_up_rounded),
        ),
        IconButton(
          key: EditorKeys.moveDown(nodeId),
          tooltip: 'Bajar',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          iconSize: 12,
          onPressed: position.index < position.count - 1
              ? () => notifier.moveNodeWithinParent(nodeId, 1)
              : null,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        IconButton(
          key: EditorKeys.outdentNode(nodeId),
          tooltip: 'Sacar un nivel',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          iconSize: 12,
          onPressed: canOutdent
              ? () => notifier.outdentNode(nodeId)
              : null,
          icon: const Icon(Icons.format_indent_decrease_rounded),
        ),
        IconButton(
          key: EditorKeys.indentNode(nodeId),
          tooltip: 'Mover dentro del anterior',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          iconSize: 12,
          onPressed: canIndent ? () => notifier.indentNode(nodeId) : null,
          icon: const Icon(Icons.format_indent_increase_rounded),
        ),
      ],
    );
  }
}

/// Lienzo central: artboard de tamaño fijo con scroll interno, selección y drop.
class _EditorCanvas extends ConsumerStatefulWidget {
  const _EditorCanvas();

  @override
  ConsumerState<_EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends ConsumerState<_EditorCanvas> {
  final _scrollController = ScrollController();
  bool _showCode = false;
  double? _zoom;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorSessionProvider);
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(editorSessionProvider.notifier);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final root = state.root;
    if (root == null) {
      return Center(child: Text(state.error ?? 'Sin pantalla'));
    }

    final canvasArea = DragTarget<EditorDragData>(
      onWillAcceptWithDetails: (details) {
        final componentType = details.data.componentType;
        if (componentType != null) {
          return standardCatalog[componentType] != null;
        }
        final nodeId = details.data.nodeId;
        return nodeId != null && nodeId != root.id;
      },
      onAcceptWithDetails: (details) {
        final componentType = details.data.componentType;
        if (componentType != null) {
          notifier.addComponent(componentType);
          return;
        }
        final nodeId = details.data.nodeId;
        if (nodeId != null) {
          // Soltado fuera de un nodo: se mueve al final de la raíz.
          notifier.moveNode(nodeId, root.id);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final accepting = candidateData.isNotEmpty;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => notifier.selectNode(null),
          child: DecoratedBox(
            decoration: accepting
                ? BoxDecoration(
                    border: Border.all(color: scheme.primary, width: 2),
                  )
                : const BoxDecoration(),
            child: CustomPaint(
              painter: const _DotGridPainter(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // El tamaño y el scroll son propiedades del nodo `screen`;
                  // el editor solo los aplica y acota al espacio disponible.
                  final device = _deviceSize(root);
                  final availableWidth = constraints.maxWidth - 48;
                  final availableHeight = constraints.maxHeight - 48 - 30;
                  final fitWidth = availableWidth / device.width;
                  final fitHeight = availableHeight / device.height;
                  final fitScale = (fitWidth < fitHeight
                          ? fitWidth
                          : fitHeight)
                      .clamp(0.2, 1.0);
                  final scale = (_zoom ?? fitScale).clamp(0.2, 1.6);
                  final content = WidgetRenderer(
                    node: root,
                    selectedNodeId: state.selectedNodeId,
                    onNodeTap: (node) => notifier.selectNode(node.id),
                    onNodeDrop: (draggedId, targetId) =>
                        notifier.moveNode(draggedId, targetId),
                    onComponentDrop: (type, targetId) =>
                        notifier.addComponentAt(type, targetId),
                    screenScrollController: _scrollController,
                    showDrawer: state.drawerOpen,
                    showEndDrawer: state.endDrawerOpen,
                  );

                  final themedContent = Theme(
                    data: buildProjectThemeData(state.theme),
                    child: content,
                  );

                  final selected = state.selectedNodeId == null
                      ? null
                      : root.findNode(state.selectedNodeId!);
                  final label = selected == null
                      ? state.screenName ?? 'Pantalla'
                      : _nodeLabel(selected);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _ZoomViewport(
                          scale: scale,
                          contentSize: Size(
                            device.width + 20,
                            device.height + 20,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1220),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                key: EditorKeys.canvas,
                                width: device.width,
                                height: device.height,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned.fill(child: themedContent),
                                    if (_hasSlot(root, ComponentSlot.overlay))
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: IconButton.filledTonal(
                                          key: EditorKeys.toggleDrawer,
                                          tooltip: state.drawerOpen
                                              ? 'Ocultar menú'
                                              : 'Mostrar menú',
                                          icon: Icon(
                                            state.drawerOpen
                                                ? Icons.close
                                                : Icons.menu,
                                          ),
                                          onPressed: () =>
                                              notifier.toggleDrawer(),
                                        ),
                                      ),
                                    if (_hasSlot(root, ComponentSlot.drawerEnd))
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton.filledTonal(
                                          key: EditorKeys.toggleEndDrawer,
                                          tooltip: state.endDrawerOpen
                                              ? 'Ocultar menú derecho'
                                              : 'Mostrar menú derecho',
                                          icon: Icon(
                                            state.endDrawerOpen
                                                ? Icons.close
                                                : Icons.menu_open,
                                          ),
                                          onPressed: () =>
                                              notifier.toggleEndDrawer(),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _CanvasStatusBar(
                        label: label,
                        scale: scale,
                        onZoomOut: () => setState(
                          () => _zoom = (scale - 0.1).clamp(0.2, 1.6),
                        ),
                        onZoomIn: () => setState(
                          () => _zoom = (scale + 0.1).clamp(0.2, 1.6),
                        ),
                        onReset: () => setState(() => _zoom = null),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    final isEntry =
        state.screens.isNotEmpty && state.screens.first.id == state.screenId;
    final fileName =
        state.screenName ?? (isEntry ? 'main.dart' : 'pantalla.dart');
    final code = DartCodeGenerator.generate(
      screen: root,
      fileName: fileName,
      isEntry: isEntry,
      theme: state.theme,
    );
    final path = DartCodeGenerator.pathFor(
      fileName: fileName,
      isEntry: isEntry,
    );

    return Column(
      children: [
        if (state.screens.isNotEmpty) const _ScreenTabs(),
        _CanvasToolbar(
          showCode: _showCode,
          onChanged: (value) => setState(() => _showCode = value),
        ),
        Expanded(
          child: _showCode
              ? _CodeView(code: code, path: path)
              : canvasArea,
        ),
      ],
    );
  }
}

/// Barra del lienzo: dispositivo, tamaño, estado "en vivo" y Diseño/Código.
class _CanvasToolbar extends ConsumerWidget {
  const _CanvasToolbar({required this.showCode, required this.onChanged});

  final bool showCode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorSessionProvider);
    final root = state.root;
    if (root == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final device = (root.properties['device'] as String?) ?? 'phone';
    final size = _deviceSize(root);
    final notifier = ref.read(editorSessionProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;

        return Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(bottom: BorderSide(color: AppTheme.border)),
          ),
          child: Row(
            children: [
              if (!compact) ...[
                Text('Dispositivo', style: theme.textTheme.labelSmall),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _DeviceSelector(
                  device: device,
                  onChanged: (value) =>
                      notifier.updateProperty(root.id, 'device', value),
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Text(
                  '${size.width.round()}×${size.height.round()}',
                  style: theme.textTheme.labelSmall,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'En vivo',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              IconButton(
                key: EditorKeys.undoAction,
                tooltip: 'Deshacer',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: () => ref
                    .read(editorSessionProvider.notifier)
                    .undo(),
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: EditorKeys.redoAction,
                tooltip: 'Rehacer',
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: () => ref
                    .read(editorSessionProvider.notifier)
                    .redo(),
                icon: const Icon(Icons.redo),
              ),
              const SizedBox(width: 4),
              SegmentedButton<bool>(
                segments: [
                  const ButtonSegment(
                    value: false,
                    icon: Icon(Icons.design_services_outlined, size: 14),
                    label: Text('Diseño'),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.code, size: 14),
                    label: const Text('Código'),
                  ),
                ],
                selected: {showCode},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => onChanged(selection.first),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Selector de dispositivo con iconos, estilo control segmentado.
class _DeviceSelector extends StatelessWidget {
  const _DeviceSelector({required this.device, required this.onChanged});

  final String device;
  final ValueChanged<String> onChanged;

  static const List<(String, String, IconData)> _items = [
    ('phone', 'Móvil', Icons.phone_iphone),
    ('tablet', 'Tablet', Icons.tablet_mac),
    ('desktop', 'Escritorio', Icons.desktop_windows_outlined),
    ('web', 'Web', Icons.language),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = constraints.maxWidth < 360;

        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (value, label, icon) in _items)
                    _DeviceChip(
                      key: EditorKeys.deviceOption(value),
                      icon: icon,
                      label: label,
                      selected: value == device,
                      iconOnly: iconOnly,
                      onTap: () => onChanged(value),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeviceChip extends StatelessWidget {
  const _DeviceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.iconOnly,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool iconOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.textStrong : AppTheme.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: iconOnly ? 8 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: selected ? AppTheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: AppTheme.border) : null,
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              if (!iconOnly) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Área del artboard con escala manual y scroll cuando no entra.
class _ZoomViewport extends StatelessWidget {
  const _ZoomViewport({
    required this.scale,
    required this.contentSize,
    required this.child,
  });

  final double scale;
  final Size contentSize;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scaledWidth = contentSize.width * scale;
        final scaledHeight = contentSize.height * scale;
        final boxWidth = scaledWidth < constraints.maxWidth
            ? constraints.maxWidth
            : scaledWidth;
        final boxHeight = scaledHeight < constraints.maxHeight
            ? constraints.maxHeight
            : scaledHeight;

        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: boxWidth,
              height: boxHeight,
              child: Center(
                child: SizedBox(
                  width: scaledWidth,
                  height: scaledHeight,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: contentSize.width,
                      height: contentSize.height,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pie del lienzo con la selección y el control de escala.
class _CanvasStatusBar extends StatelessWidget {
  const _CanvasStatusBar({
    required this.label,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final String label;
  final double scale;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: scheme.surfaceContainer,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Vista previa · $label',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            key: EditorKeys.zoomOut,
            tooltip: 'Alejar',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            iconSize: 14,
            icon: const Icon(Icons.remove),
            onPressed: onZoomOut,
          ),
          const SizedBox(width: 4),
          Text(
            '${(scale * 100).round()}%',
            key: EditorKeys.zoomLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            key: EditorKeys.zoomIn,
            tooltip: 'Acercar',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            iconSize: 14,
            icon: const Icon(Icons.add),
            onPressed: onZoomIn,
          ),
          const SizedBox(width: 6),
          TextButton(
            key: EditorKeys.zoomReset,
            onPressed: onReset,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Ajustar', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

/// Barra Diseño / Código del lienzo.
/// Vista de código exportable con nota de ruta y copiado.
class _CodeView extends StatelessWidget {
  const _CodeView({required this.code, required this.path});

  final String code;
  final String path;

  // Paleta fija de editor de código (independiente del tema de la app).
  static const _background = Color(0xFF1E1E1E);
  static const _surface = Color(0xFF252526);
  static const _border = Color(0xFF3C3C3C);
  static const _codeColor = Color(0xFFD4D4D4);
  static const _muted = Color(0xFF858585);

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    final fileName = path.split('/').last;
    const codeStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.5,
      color: _codeColor,
    );
    const gutterStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12.5,
      height: 1.5,
      color: _muted,
    );

    return ColoredBox(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            color: _surface,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: _muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _codeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${lines.length} líneas',
                  style: const TextStyle(fontSize: 10, color: _muted),
                ),
                const Spacer(),
                IconButton(
                  key: EditorKeys.copyCode,
                  tooltip: 'Copiar código',
                  icon: const Icon(
                    Icons.copy_all_outlined,
                    size: 18,
                    color: _codeColor,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: _background,
            child: Text(
              'Pega este código en $path',
              key: EditorKeys.codeNote,
              style: const TextStyle(fontSize: 10.5, color: _muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var index = 1; index <= lines.length; index++)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 10,
                            ),
                            child: Text('$index', style: gutterStyle),
                          ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    SelectableText.rich(
                      _highlightDart(code, codeStyle),
                      key: EditorKeys.codeView,
                      style: codeStyle,
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: _surface,
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 12,
                  color: Color(0xFF86EFAC),
                ),
                SizedBox(width: 6),
                Text(
                  'Sincronizado',
                  style: TextStyle(fontSize: 10, color: _muted),
                ),
                Spacer(),
                Text(
                  'Dart 3 · Material 3',
                  style: TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestañas de pantallas + botón para crear una nueva.
class _ScreenTabs extends ConsumerWidget {
  const _ScreenTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorSessionProvider);
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(editorSessionProvider.notifier);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final screen in state.screens)
                  _ScreenTab(
                    key: EditorKeys.screenTab(screen.id),
                    screenId: screen.id,
                    label: screen.name,
                    selected: screen.id == state.screenId,
                    onTap: () => notifier.selectScreen(screen.id),
                    onRename: () => _rename(context, ref, screen.name),
                  ),
              ],
            ),
          ),
          IconButton(
            key: EditorKeys.addScreen,
            tooltip: 'Nueva pantalla',
            icon: const Icon(Icons.add),
            onPressed: () => notifier.createScreen(),
          ),
        ],
      ),
    );
  }

  /// Pide el nuevo nombre del archivo y lo guarda.
  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: current),
    );
    if (name == null || name.trim().isEmpty) {
      return;
    }
    await ref.read(editorSessionProvider.notifier).renameScreen(name);
  }
}

/// Diálogo para renombrar el archivo de la pantalla.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nombre de la pantalla'),
      content: TextField(
        key: EditorKeys.renameField,
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Archivo',
          helperText: 'Ej. main.dart o login.dart',
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
class _ScreenTab extends StatelessWidget {
  const _ScreenTab({
    required this.screenId,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onRename,
    super.key,
  });

  final String screenId;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: Tooltip(
        message: 'Renombrar con el lápiz',
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 4),
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: scheme.primary, width: 2),
                    ),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
                if (selected)
                  IconButton(
                    key: EditorKeys.renameScreen(screenId),
                    tooltip: 'Renombrar',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    iconSize: 14,
                    onPressed: onRename,
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Panel derecho: propiedades del nodo seleccionado.
class _EditorProperties extends ConsumerStatefulWidget {
  const _EditorProperties();

  @override
  ConsumerState<_EditorProperties> createState() => _EditorPropertiesState();
}

class _EditorPropertiesState extends ConsumerState<_EditorProperties> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorSessionProvider);
    final theme = Theme.of(context);
    final root = state.root;
    final selectedId = state.selectedNodeId;

    if (root == null || selectedId == null) {
      return const Center(child: Text('Sin selección'));
    }

    final node = root.findNode(selectedId);
    if (node == null) {
      return const Center(child: Text('Selección no válida'));
    }
    final definition = standardCatalog[node.type];
    if (definition == null) {
      return const Center(child: Text('Componente desconocido'));
    }

    final sections = <String, List<PropertySpec>>{};
    for (final spec in definition.properties) {
      if (spec.hidden) {
        continue;
      }
      // Las propiedades neutras se ocultan hasta activar el modo Avanzado,
      // salvo que el usuario ya las haya cambiado.
      final isNeutral =
          spec.isAdvancedByDefault &&
          (node.properties[spec.key] == null ||
              node.properties[spec.key] == spec.defaultValue);
      if (isNeutral && !_showAdvanced) {
        continue;
      }
      sections.putIfAbsent(_sectionOf(node, spec), () => []).add(spec);
    }
    final orderedSections = sections.entries.toList()
      ..sort((a, b) => _sectionRank(a.key).compareTo(_sectionRank(b.key)));

    return ListView(
      key: EditorKeys.propertiesList,
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(definition.icon, size: 19, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.label,
                    key: EditorKeys.propertiesTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    definition.flutterClass == null
                        ? definition.type
                        : 'Flutter · ${definition.flutterClass}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            if (definition.flutterClass != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  definition.flutterClass!,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: EditorKeys.advancedToggle,
            onPressed: () =>
                setState(() => _showAdvanced = !_showAdvanced),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 26),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(
              _showAdvanced ? Icons.tune : Icons.tune_outlined,
              size: 14,
            ),
            label: Text(
              _showAdvanced ? 'Ocultar avanzado' : 'Mostrar avanzado',
              style: const TextStyle(fontSize: 10.5),
            ),
          ),
        ),
        for (final section in orderedSections) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Row(
              children: [
                Text(
                  section.key.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Divider(height: 1, thickness: 1),
                ),
              ],
            ),
          ),
          for (final spec in section.value) ...[
            if (node.type == 'appBar' &&
                spec.key == 'scrolledUnderElevation' &&
                node.properties['hideOnScroll'] == true)
              // No aplica cuando la barra se oculta al desplazar.
              Text(
                'No aplica: la barra se oculta al desplazar.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              _PropertyField(
                key: ValueKey<String>('${node.id}.${spec.key}'),
                node: node,
                spec: spec,
              ),
              if (spec.hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    spec.hint!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      color: AppTheme.hint,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 12),
          ],
        ],
        if (definition.properties.isEmpty)
          Text(
            'Este componente no tiene propiedades.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Haz clic en los nodos del árbol de capas para editar '
                  'la barra superior, la navegación o cualquier widget.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        TextButton.icon(
          key: EditorKeys.deleteNode,
          onPressed: node.id == root.id
              ? null
              : () => ref
                    .read(editorSessionProvider.notifier)
                    .removeNode(node.id),
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          label: Text(
            'Eliminar componente',
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ),
      ],
    );
  }
}

/// Control de una propiedad, generado desde su [PropertySpec].
class _PropertyField extends ConsumerStatefulWidget {
  const _PropertyField({required this.node, required this.spec, super.key});

  final CanvasNode node;
  final PropertySpec spec;

  @override
  ConsumerState<_PropertyField> createState() => _PropertyFieldState();
}

class _PropertyFieldState extends ConsumerState<_PropertyField> {
  late final TextEditingController _controller;

  Object? get _value =>
      widget.node.properties[widget.spec.key] ?? widget.spec.defaultValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _asText(_value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _asText(Object? value) {
    if (value is double && value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value?.toString() ?? '';
  }

  void _update(Object? value) {
    ref
        .read(editorSessionProvider.notifier)
        .updateProperty(widget.node.id, widget.spec.key, value);
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;

    return switch (spec.type) {
      PropertyType.text || PropertyType.multilineText => _FieldLabel(
        label: spec.label,
        child: TextFormField(
          key: EditorKeys.propertyField(spec.key),
          controller: _controller,
          maxLength: spec.maxLength,
          minLines: spec.type == PropertyType.multilineText ? 3 : 1,
          maxLines: spec.type == PropertyType.multilineText ? 5 : 1,
          onChanged: _update,
          decoration: const InputDecoration(counterText: ''),
        ),
      ),
      PropertyType.number => _FieldLabel(
        label: spec.label,
        child: TextFormField(
          key: EditorKeys.propertyField(spec.key),
          controller: _controller,
          keyboardType: TextInputType.numberWithOptions(
            decimal: !spec.integer,
          ),
          inputFormatters: spec.integer
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          onChanged: (value) {
            final parsed = double.tryParse(value.replaceAll(',', '.'));
            if (parsed != null) {
              _update(parsed);
            }
          },
          decoration: InputDecoration(
            suffixText: spec.suffix,
            helperText: _rangeLabel(spec),
          ),
        ),
      ),
      PropertyType.boolean => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Expanded(
              child: Text(
                spec.label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Switch(
              key: EditorKeys.propertyField(spec.key),
              value: _value as bool? ?? false,
              onChanged: _update,
            ),
          ],
        ),
      ),
      PropertyType.choice => _FieldLabel(
        label: spec.label,
        child: DropdownButtonFormField<String>(
          key: EditorKeys.propertyField(spec.key),
          initialValue: _value as String?,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 12),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
          ),
          items: [
            for (final choice in spec.choices)
              DropdownMenuItem(
                value: choice.value,
                child: Text(
                  choice.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              _update(value);
            }
          },
        ),
      ),
      PropertyType.color => _ColorPropertyField(
        key: ValueKey<String>('${widget.node.id}.${widget.spec.key}.color'),
        spec: spec,
        value: _value as String? ?? '',
        onChanged: _update,
      ),
    };
  }

  static String? _rangeLabel(PropertySpec spec) {
    if (spec.min == null && spec.max == null) {
      return null;
    }
    final min = spec.min?.toStringAsFixed(0) ?? '';
    final max = spec.max?.toStringAsFixed(0) ?? '';
    return '$min – $max';
  }
}

/// Etiqueta pequeña arriba del control, como en las herramientas de diseño.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

/// Selector de color: paleta de tokens del theme + campo hex opcional.
class _ColorPropertyField extends StatefulWidget {
  const _ColorPropertyField({
    required this.spec,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PropertySpec spec;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_ColorPropertyField> createState() => _ColorPropertyFieldState();
}

class _ColorPropertyFieldState extends State<_ColorPropertyField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_syncOnBlur);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _controller.text = _hexFor(widget.value);
      _ready = true;
    }
  }

  @override
  void didUpdateWidget(_ColorPropertyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refleja cambios externos (paleta u otra pantalla) sin pelear con el
    // cursor mientras el usuario escribe.
    if (widget.value != oldWidget.value && !_focus.hasFocus) {
      _controller.text = _hexFor(widget.value);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_syncOnBlur);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncOnBlur() {
    if (!_focus.hasFocus && mounted) {
      setState(() => _controller.text = _hexFor(widget.value));
    }
  }

  /// Hex visible del valor actual (token del theme o hex propio).
  String _hexFor(String value) {
    final color = colorForValue(value, Theme.of(context).colorScheme);
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _onHexChanged(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      setState(() => _error = null);
      widget.onChanged('');
      return;
    }
    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
      setState(() => _error = null);
      widget.onChanged(value.toUpperCase());
    } else {
      setState(() => _error = 'Formato #RRGGBB');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.spec.label, style: theme.textTheme.labelMedium),
        const SizedBox(height: 5),
        Row(
          children: [
            InkWell(
              onTap: _openPicker,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorForValue(current, scheme),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: EditorKeys.propertyField('${widget.spec.key}.hex'),
                controller: _controller,
                focusNode: _focus,
                onChanged: _onHexChanged,
                decoration: InputDecoration(
                  hintText: '#RRGGBB',
                  errorText: _error,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              key: EditorKeys.colorPalette(widget.spec.key),
              tooltip: 'Elegir color',
              icon: const Icon(Icons.palette_outlined, size: 18),
              onPressed: _openPicker,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openPicker() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _ColorPickerDialog(initial: _hexFor(widget.value)),
    );
    if (picked == null) {
      return;
    }
    setState(() => _error = null);
    _controller.text = picked;
    widget.onChanged(picked);
  }
}

/// Paleta rápida del selector de color.
const _quickPalette = <String>[
  '#FFFFFF', '#F8FAFC', '#F1F5F9', '#E2E8F0', '#CBD5E1', '#94A3B8',
  '#64748B', '#475569', '#334155', '#1E293B', '#0F172A', '#000000',
  '#FDE2E4', '#FBCFE8', '#F87171', '#DC2626', '#FEE2E2', '#FED7AA',
  '#FB923C', '#EA580C', '#FEF3C7', '#FDE68A', '#F59E0B', '#B45309',
  '#D1FAE5', '#A7F3D0', '#34D399', '#059669', '#065F46', '#ECFDF5',
  '#99F6E4', '#2DD4BF', '#0F766E', '#CCFBF1', '#E0F2FE', '#BAE6FD',
  '#60A5FA', '#2563EB', '#1E3A8A', '#EDE9FE', '#DDD6FE', '#A78BFA',
  '#7C3AED', '#F5E6F8', '#F472B6', '#DB2777',
];

/// Diálogo para elegir un color con hex y paleta rápida.
class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});

  final String initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late String _selected = widget.initial.toUpperCase();
  late final TextEditingController _hex = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _select(String value) {
    setState(() => _selected = value);
    _hex.text = value;
  }

  Color _parse(String hex) {
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xFFFFFF;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = _parse(_selected);

    return AlertDialog(
      title: const Text('Elegir color'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: preview,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: EditorKeys.dialogHex,
                      controller: _hex,
                      decoration: const InputDecoration(
                        labelText: 'Hex',
                        isDense: true,
                      ),
                      onChanged: (raw) {
                        final value = raw.trim().toUpperCase();
                        if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(value)) {
                          setState(() => _selected = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Paleta rápida', style: theme.textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final hex in _quickPalette)
                    _PaletteSwatch(
                      hex: hex,
                      selected: hex == _selected,
                      onTap: () => _select(hex),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: EditorKeys.applyColor,
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Aplicar color'),
        ),
      ],
    );
  }
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = colorForValue(hex, scheme);
    final checkColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? scheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: selected ? Icon(Icons.check, size: 14, color: checkColor) : null,
      ),
    );
  }
}

/// Nodo aplanado con su profundidad, para el árbol del panel izquierdo.
class _FlatNode {
  const _FlatNode(this.node, this.depth);

  final CanvasNode node;
  final int depth;
}

/// Recorre el árbol en profundidad (preorden).
///
/// En la pantalla se respeta el orden visual de los slots (arriba, cuerpo,
/// menús, FAB y abajo), no el orden en que se insertaron.
List<_FlatNode> _flatten(CanvasNode root, [int depth = 0]) {
  final result = <_FlatNode>[_FlatNode(root, depth)];
  for (final child in _orderedChildren(root)) {
    result.addAll(_flatten(child, depth + 1));
  }
  return result;
}

/// Hijos de [node] en el orden en que se ven en el lienzo.
List<CanvasNode> _orderedChildren(CanvasNode node) {
  if (node.type != 'screen') {
    return node.children;
  }

  const order = {
    ComponentSlot.top: 0,
    ComponentSlot.body: 1,
    ComponentSlot.overlay: 2,
    ComponentSlot.drawerEnd: 3,
    ComponentSlot.fab: 4,
    ComponentSlot.bottom: 5,
  };

  final entries = node.children.indexed.toList();
  entries.sort((a, b) {
    final slotA =
        order[standardCatalog[a.$2.type]?.slot ?? ComponentSlot.body] ?? 1;
    final slotB =
        order[standardCatalog[b.$2.type]?.slot ?? ComponentSlot.body] ?? 1;
    final bySlot = slotA.compareTo(slotB);
    return bySlot != 0 ? bySlot : a.$1.compareTo(b.$1);
  });
  return entries.map((entry) => entry.$2).toList(growable: false);
}

/// Etiqueta legible de un nodo para el árbol.
String _nodeLabel(CanvasNode node) {
  final label = standardCatalog[node.type]?.label ?? node.type;
  final preview = switch (node.type) {
    'text' => node.properties['text'] as String?,
    'button' => node.properties['label'] as String?,
    _ => null,
  };
  if (preview == null || preview.isEmpty) {
    return label;
  }
  return '$label: $preview';
}

/// Nombre visible de la categoría.
String _categoryLabel(ComponentCategory category) => switch (category) {
  ComponentCategory.layout => 'Diseño',
  ComponentCategory.basic => 'Básicos',
  ComponentCategory.input => 'Formularios',
  ComponentCategory.media => 'Media',
  ComponentCategory.navigation => 'Navegación',
  ComponentCategory.material => 'Material',
};

/// Ícono de la categoría en el riel.
IconData _categoryIcon(ComponentCategory category) => switch (category) {
  ComponentCategory.layout => Icons.dashboard_outlined,
  ComponentCategory.basic => Icons.widgets_outlined,
  ComponentCategory.input => Icons.input,
  ComponentCategory.media => Icons.image_outlined,
  ComponentCategory.navigation => Icons.menu_open,
  ComponentCategory.material => Icons.layers_outlined,
};

/// Tamaño lógico del dispositivo declarado en la raíz `screen`.
({double width, double height}) _deviceSize(CanvasNode root) {
  final device = root.properties['device'];
  return switch (device) {
    'tablet' => (width: 768, height: 1024),
    'desktop' => (width: 1280, height: 800),
    'web' => (width: 1440, height: 900),
    _ => (width: 390, height: 844),
  };
}

/// `true` si la pantalla tiene un hijo en el slot indicado.
bool _hasSlot(CanvasNode root, ComponentSlot slot) =>
    root.children.any((child) => standardCatalog[child.type]?.slot == slot);

/// Orden de las secciones del panel de propiedades.
const _sectionOrder = [
  'Pantalla',
  'Barra superior',
  'Barra inferior',
  'Pestañas',
  'Contenido',
  'Colores',
  'Diseño',
  'Comportamiento',
  'General',
];

/// Sección a la que pertenece [spec] en [node].
///
/// Usa `spec.group` cuando está definido; si no, deduce una sección razonable
/// para que todo el catálogo quede agrupado.
String _sectionOf(CanvasNode node, PropertySpec spec) {
  if (spec.group != 'General') {
    return spec.group;
  }
  if (spec.type == PropertyType.color) {
    return 'Colores';
  }
  if (spec.type == PropertyType.boolean) {
    return 'Comportamiento';
  }
  const content = {
    'title',
    'label',
    'text',
    'hint',
    'icon',
    'style',
    'align',
    'obscure',
    'value',
    'checked',
    'active',
    'subtitle',
  };
  if (content.contains(spec.key)) {
    return 'Contenido';
  }
  return 'General';
}

int _sectionRank(String title) {
  final index = _sectionOrder.indexOf(title);
  return index < 0 ? _sectionOrder.length : index;
}

/// Palabras reservadas de Dart (color azul).
const _dartKeywords = {
  'import', 'export', 'library', 'part', 'as', 'show', 'hide', 'class',
  'extends', 'implements', 'with', 'mixin', 'abstract', 'interface',
  'const', 'final', 'var', 'late', 'static', 'void', 'return', 'new',
  'this', 'super', 'if', 'else', 'for', 'while', 'do', 'switch', 'case',
  'default', 'break', 'continue', 'try', 'catch', 'finally', 'throw',
  'rethrow', 'async', 'await', 'yield', 'in', 'is', 'enum', 'factory',
  'get', 'set', 'operator', 'external', 'covariant', 'typedef', 'dynamic',
  'required', 'assert', 'deferred',
};

/// Constantes y literales especiales (color violeta).
const _dartConstants = {'true', 'false', 'null'};

/// Resalta el código Dart con los colores del panel oscuro.
TextSpan _highlightDart(String code, TextStyle base) {
  final pattern = RegExp(
    r'''//[^\n]*|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"|\b\d+(?:\.\d+)?\b|\b[A-Za-z_][A-Za-z0-9_]*\b|[\s\S]''',
  );

  const comment = Color(0xFF6A9955);
  const string = Color(0xFFCE9178);
  const keyword = Color(0xFF569CD6);
  const constant = Color(0xFF569CD6);
  const type = Color(0xFF4EC9B0);
  const number = Color(0xFFB5CEA8);

  final spans = <TextSpan>[];
  final buffer = StringBuffer();
  TextStyle? currentStyle;

  void flush() {
    if (buffer.isEmpty) {
      return;
    }
    spans.add(TextSpan(text: buffer.toString(), style: currentStyle));
    buffer.clear();
  }

  void add(String text, TextStyle? style) {
    if (currentStyle != style) {
      flush();
      currentStyle = style;
    }
    buffer.write(text);
  }

  for (final match in pattern.allMatches(code)) {
    final text = match[0]!;

    if (text.startsWith('//')) {
      add(text, base.copyWith(color: comment, fontStyle: FontStyle.italic));    } else if (text.startsWith("'") || text.startsWith('"')) {
      add(text, base.copyWith(color: string));
    } else if (RegExp(r'^\d').hasMatch(text)) {
      add(text, base.copyWith(color: number));
    } else if (_dartKeywords.contains(text)) {
      add(text, base.copyWith(color: keyword));
    } else if (_dartConstants.contains(text)) {
      add(text, base.copyWith(color: constant));
    } else if (RegExp(r'^[A-Z]').hasMatch(text)) {
      add(text, base.copyWith(color: type));
    } else {
      add(text, base);
    }
  }
  flush();

  return TextSpan(style: base, children: spans);
}

/// Fondo del lienzo: gris claro con puntos de guía.
class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const double _spacing = 18;
  static const double _radius = 1;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.background,
    );

    final dot = Paint()..color = const Color(0xFFD7DBE2);
    for (var x = _spacing / 2; x < size.width; x += _spacing) {
      for (var y = _spacing / 2; y < size.height; y += _spacing) {
        canvas.drawCircle(Offset(x, y), _radius, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}
