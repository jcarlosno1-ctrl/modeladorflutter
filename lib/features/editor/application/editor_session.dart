import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/projects/application/project_providers.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';
import 'package:modeladorflutter/features/projects/domain/project_theme.dart';

import '../catalog/standard_catalog.dart';
import '../catalog/widget_definition.dart';
import '../data/supabase_project_screen_repository.dart';
import '../domain/canvas_node.dart';
import '../domain/project_screen.dart';
import '../domain/project_screen_repository.dart';

/// Repositorio de pantallas (inyectable en tests).
final projectScreenRepositoryProvider = Provider<ProjectScreenRepository>(
  (ref) => SupabaseProjectScreenRepository(ref.watch(supabaseClientProvider)),
);

/// Estado de una sesión de edición.
class EditorState {
  /// Crea el estado.
  const EditorState({
    this.projectId,
    this.screenId,
    this.screenName,
    this.root,
    this.screens = const [],
    this.selectedNodeId,
    this.isLoading = false,
    this.isSaving = false,
    this.isDirty = false,
    this.drawerOpen = false,
    this.endDrawerOpen = false,
    this.theme = const ProjectTheme(),
    this.error,
  });

  /// Proyecto abierto.
  final String? projectId;

  /// Pantalla abierta.
  final String? screenId;

  /// Nombre de la pantalla.
  final String? screenName;

  /// Árbol actual.
  final CanvasNode? root;

  /// Pantallas del proyecto (para las pestañas).
  final List<ProjectScreen> screens;

  /// Nodo seleccionado, si hay.
  final String? selectedNodeId;

  /// Cargando desde el backend.
  final bool isLoading;

  /// Guardando en el backend.
  final bool isSaving;

  /// Hay cambios sin guardar.
  final bool isDirty;

  /// Menú lateral visible (solo vista previa del editor).
  final bool drawerOpen;

  /// Menú lateral derecho visible (solo vista previa del editor).
  final bool endDrawerOpen;

  /// Tema visual del proyecto.
  final ProjectTheme theme;

  /// Mensaje de error, si lo hay.
  final String? error;

  /// `true` si hay una pantalla lista para dibujar.
  bool get hasScreen => screenId != null && root != null;

  /// Copia con cambios; `clearError` limpia el error explícitamente y
  /// `clearSelection` quita la selección.
  EditorState copyWith({
    String? screenId,
    String? screenName,
    CanvasNode? root,
    List<ProjectScreen>? screens,
    String? selectedNodeId,
    bool? isLoading,
    bool? isSaving,
    bool? isDirty,
    bool? drawerOpen,
    bool? endDrawerOpen,
    ProjectTheme? theme,
    String? error,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return EditorState(
      projectId: projectId,
      screenId: screenId ?? this.screenId,
      screenName: screenName ?? this.screenName,
      root: root ?? this.root,
      screens: screens ?? this.screens,
      selectedNodeId: clearSelection
          ? null
          : (selectedNodeId ?? this.selectedNodeId),
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDirty: isDirty ?? this.isDirty,
      drawerOpen: drawerOpen ?? this.drawerOpen,
      endDrawerOpen: endDrawerOpen ?? this.endDrawerOpen,
      theme: theme ?? this.theme,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Sesión de edición de un proyecto: carga, crea y guarda su pantalla.
class EditorSession extends Notifier<EditorState> {
  Timer? _saveTimer;
  final List<CanvasNode> _undoHistory = [];
  final List<CanvasNode> _redoHistory = [];

  @override
  EditorState build() {
    ref.onDispose(() => _saveTimer?.cancel());
    return const EditorState();
  }

  /// Agenda el guardado con un pequeño debounce.
  void _recordHistory() {
    final root = state.root;
    if (root == null) {
      return;
    }
    _undoHistory.add(root);
    if (_undoHistory.length > 60) {
      _undoHistory.removeAt(0);
    }
    _redoHistory.clear();
  }

  /// Deshace la última acción sobre el árbol.
  Future<void> undo() async {
    final root = state.root;
    if (root == null || _undoHistory.isEmpty) {
      return;
    }
    _redoHistory.add(root);
    final previous = _undoHistory.removeLast();
    state = state.copyWith(
      root: previous,
      isDirty: true,
      clearSelection: true,
      clearError: true,
    );
    await save();
  }

  /// Rehace la acción deshecha.
  Future<void> redo() async {
    final root = state.root;
    if (root == null || _redoHistory.isEmpty) {
      return;
    }
    _undoHistory.add(root);
    final next = _redoHistory.removeLast();
    state = state.copyWith(
      root: next,
      isDirty: true,
      clearSelection: true,
      clearError: true,
    );
    await save();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      unawaited(save());
    });
  }

  /// Selecciona un nodo del lienzo (o limpia la selección con `null`).
  void selectNode(String? nodeId) {
    state = state.copyWith(
      selectedNodeId: nodeId,
      clearSelection: nodeId == null,
    );
  }

  /// Actualiza una propiedad de un nodo, validándola contra su esquema.
  ///
  /// Un valor inválido se ignora: ni se guarda ni rompe el árbol. El guardado
  /// se agenda con un pequeño debounce para no escribir en cada tecla.
  void updateProperty(String nodeId, String key, Object? value) {
    final root = state.root;
    if (root == null) {
      return;
    }
    final node = root.findNode(nodeId);
    if (node == null) {
      return;
    }
    final spec = standardCatalog[node.type]?.propertyFor(key);
    if (spec == null || !spec.accepts(value)) {
      return;
    }

    _recordHistory();
    final updated = root.withProperty(nodeId, key, value);
    if (identical(updated, root)) {
      return;
    }

    state = state.copyWith(root: updated, isDirty: true, clearError: true);
    _scheduleSave();
  }

  /// Reordena un nodo arrastrándolo antes de [targetId].
  ///
  /// Si [targetId] es la raíz, el nodo se mueve al final. Se rechaza mover un
  /// nodo dentro de sí mismo (evita ciclos) y mover la raíz.
  void moveNode(String draggedId, String targetId) {
    final root = state.root;
    if (root == null || draggedId == targetId || draggedId == root.id) {
      return;
    }

    final dragged = root.findNode(draggedId);
    if (dragged == null) {
      return;
    }
    if (dragged.findNode(targetId) != null) {
      return;
    }
    // Las barras fijas y el menú no se reordenan arrastrando.
    if ((standardCatalog[dragged.type]?.slot ?? ComponentSlot.body) !=
        ComponentSlot.body) {
      return;
    }
    final targetNode = root.findNode(targetId);
    if (standardCatalog[dragged.type]?.requiresFlexParent ?? false) {
      if (!_canHostFlex(root, targetId)) {
        return;
      }
    }
    if (targetNode != null) {      final targetSlot =
          standardCatalog[targetNode.type]?.slot ?? ComponentSlot.body;
      // Un ítem de navegación solo puede vivir dentro de la barra inferior.
      if (dragged.type == 'navItem' && targetSlot != ComponentSlot.bottom) {
        return;
      }
      final intoAppBar =
          targetSlot == ComponentSlot.top && dragged.type == 'icon';
      final intoBottomNav =
          targetSlot == ComponentSlot.bottom &&
          (dragged.type == 'navItem' || dragged.type == 'icon');
      if (targetSlot != ComponentSlot.body && !intoAppBar && !intoBottomNav) {
        return;
      }
    }

    final without = root.removeById(draggedId);
    if (without == null) {
      return;
    }

    final moved = _place(without, targetId, dragged);
    if (moved == null || identical(moved, root)) {
      return;
    }

    _recordHistory();
    state = state.copyWith(root: moved, isDirty: true, clearError: true);
    _scheduleSave();
  }

  /// Sube o baja un nodo dentro de su padre (±1 posición).
  ///
  /// Si el nodo es un contenedor, todo su subárbol se mueve con él.
  Future<void> moveNodeWithinParent(String nodeId, int delta) async {
    final root = state.root;
    if (root == null || nodeId == root.id) {
      return;
    }

    final node = root.findNode(nodeId);
    if (node == null) {
      return;
    }
    // Solo el cuerpo se reordena: las barras quedan clavadas en su slot.
    if ((standardCatalog[node.type]?.slot ?? ComponentSlot.body) !=
        ComponentSlot.body) {
      return;
    }

    _recordHistory();
    final updated = root.moveWithinParent(
      nodeId,
      delta,
      canMoveNextTo: (sibling) =>
          (standardCatalog[sibling.type]?.slot ?? ComponentSlot.body) ==
          ComponentSlot.body,
    );
    if (identical(updated, root)) {
      return;
    }

    state = state.copyWith(root: updated, isDirty: true, clearError: true);
    await save();
  }

  /// Mueve el nodo a ser hijo del hermano anterior (un nivel adentro).
  Future<void> indentNode(String nodeId) async {
    final root = state.root;
    if (root == null || nodeId == root.id) {
      return;
    }
    final position = root.siblingPositionOf(nodeId);
    if (position == null || position.index == 0) {
      return;
    }
    final node = root.findNode(nodeId);
    final parent = root.findNode(position.parentId);
    if (node == null || parent == null) {
      return;
    }
    final previous = parent.children[position.index - 1];
    if (!(standardCatalog[previous.type]?.acceptsChildren ?? false)) {
      return;
    }
    final without = root.removeById(nodeId);
    if (without == null) {
      return;
    }
    final moved = without.appendChild(previous.id, node);
    if (moved == null) {
      return;
    }
    _recordHistory();
    state = state.copyWith(root: moved, isDirty: true, clearError: true);
    await save();
  }

  /// Saca el nodo un nivel, justo después de su padre.
  Future<void> outdentNode(String nodeId) async {
    final root = state.root;
    if (root == null || nodeId == root.id) {
      return;
    }
    final position = root.siblingPositionOf(nodeId);
    if (position == null || position.parentId == root.id) {
      return;
    }
    final node = root.findNode(nodeId);
    if (node == null) {
      return;
    }
    if ((standardCatalog[node.type]?.slot ?? ComponentSlot.body) !=
        ComponentSlot.body) {
      return;
    }
    final parentPosition = root.siblingPositionOf(position.parentId);
    if (parentPosition == null) {
      return;
    }

    final without = root.removeById(nodeId);
    if (without == null) {
      return;
    }
    final grandparent = without.findNode(parentPosition.parentId);
    if (grandparent == null) {
      return;
    }
    final parentIndex = grandparent.children.indexWhere(
      (child) => child.id == position.parentId,
    );
    final next = parentIndex >= 0 && parentIndex + 1 < grandparent.children.length
        ? grandparent.children[parentIndex + 1]
        : null;

    final moved = next == null
        ? without.appendChild(grandparent.id, node)
        : without.insertBefore(next.id, node);
    if (moved == null) {
      return;
    }
    _recordHistory();
    state = state.copyWith(root: moved, isDirty: true, clearError: true);
    await save();
  }

  /// Agrega un destino al final de la barra inferior (máximo 6).
  Future<void> addDestination() async {
    final root = state.root;
    if (root == null) {
      return;
    }
    CanvasNode? bar;
    for (final child in root.children) {
      if (child.type == 'bottomNav') {
        bar = child;
      }
    }
    if (bar == null || bar.children.length >= 6) {
      return;
    }
    _recordHistory();
    const labels = ['Inicio', 'Buscar', 'Favorito', 'Perfil', 'Ajustes', 'Más'];
    const icons = [
      'home',
      'search',
      'favorite',
      'person',
      'settings',
      'more_vert',
    ];
    // Si la barra viene vacía, siembra dos destinos para que sea válida.
    final count = bar.children.isEmpty ? 2 : 1;
    var updated = root;
    CanvasNode? last;
    for (var step = 0; step < count; step++) {
      if (bar.children.length + step >= 6) {
        break;
      }
      final number = bar.children.length + step + 1;
      final index = (number - 1) % labels.length;
      final destination = CanvasNode(
        id: _newId(),
        type: 'icon',
        properties: {'icon': icons[index], 'label': labels[index]},
      );
      final next = updated.appendChild(bar.id, destination);
      if (next == null) {
        break;
      }
      updated = next;
      last = destination;
    }
    if (last == null) {
      return;
    }
    state = state.copyWith(
      root: updated,
      isDirty: true,
      selectedNodeId: last.id,
      clearError: true,
    );
    await save();
  }

  /// Quita el último destino (mínimo 2).
  Future<void> removeLastDestination() async {
    final root = state.root;
    if (root == null) {
      return;
    }
    CanvasNode? bar;
    for (final child in root.children) {
      if (child.type == 'bottomNav') {
        bar = child;
      }
    }
    if (bar == null || bar.children.length <= 2) {
      return;
    }
    _recordHistory();
    final updated = root.removeById(bar.children.last.id);
    if (updated == null) {
      return;
    }
    state = state.copyWith(
      root: updated,
      isDirty: true,
      clearSelection: true,
      clearError: true,
    );
    await save();
  }

  /// Guarda el tema del proyecto y lo refleja en el estado.
  Future<void> saveTheme(ProjectTheme theme) async {
    final projectId = state.projectId;
    if (projectId == null) {
      return;
    }

    state = state.copyWith(theme: theme, clearError: true);

    final result = await ref
        .read(projectRepositoryProvider)
        .saveTheme(projectId: projectId, theme: theme);

    if (result case Err(:final failure)) {
      state = state.copyWith(error: failure.message);
    }
  }

  /// Muestra u oculta el menú lateral en la vista previa.
  void toggleDrawer() {
    state = state.copyWith(drawerOpen: !state.drawerOpen);
  }

  /// Muestra u oculta el menú lateral derecho en la vista previa.
  void toggleEndDrawer() {
    state = state.copyWith(endDrawerOpen: !state.endDrawerOpen);
  }

  /// Carga la primera pantalla del proyecto o crea una por defecto.
  ///
  /// Nunca deja el estado en `isLoading`: cualquier fallo inesperado (por
  /// ejemplo, un cliente sin inicializar) termina en `error`.
  Future<void> openProject(Project project) async {
    state = EditorState(projectId: project.id, isLoading: true);

    try {
      final repository = ref.read(projectScreenRepositoryProvider);
      final result = await repository.listForProject(project.id);
      switch (result) {
        case Err(:final failure):
          state = EditorState(projectId: project.id, error: failure.message);
        case Ok(:final value):
          if (value.isEmpty) {
            await _createDefaultScreen(project, repository);
            return;
          }
          final ordered = _initialFirst(value);
          final screen = ordered.first;
          state = EditorState(
            projectId: project.id,
            screens: ordered,
            screenId: screen.id,
            screenName: screen.name,
            root: _normalizeRoot(screen.canvas ?? _defaultRoot()),
            theme: project.theme,
          );
      }
    } on Object {
      state = EditorState(
        projectId: project.id,
        error: 'No se pudo abrir el proyecto.',
      );
    }
  }

  /// Pantallas con la inicial primero; conserva el resto del orden.
  List<ProjectScreen> _initialFirst(List<ProjectScreen> screens) {
    ProjectScreen? initial;
    for (final screen in screens) {
      if (screen.canvas?.properties['initial'] == true) {
        initial = screen;
        break;
      }
    }
    if (initial == null) {
      return screens;
    }
    return [
      initial,
      for (final screen in screens)
        if (screen.id != initial.id) screen,
    ];
  }

  /// Marca una pantalla como inicial y la mueve al primer lugar.
  Future<void> setInitialScreen(String screenId, bool value) async {
    final root = state.root;
    if (root == null || state.screenId != screenId) {
      return;
    }
    _recordHistory();
    final updated = root.withProperty(root.id, 'initial', value);
    var screens = <ProjectScreen>[
      for (final screen in state.screens)
        if (screen.id == screenId)
          ProjectScreen(
            id: screen.id,
            projectId: screen.projectId,
            name: screen.name,
            position: screen.position,
            canvas: updated,
          )
        else
          screen,
    ];
    if (value) {
      final current = screens.firstWhere((screen) => screen.id == screenId);
      screens = [
        current,
        for (final screen in screens)
          if (screen.id != screenId) screen,
      ];
    }
    state = state.copyWith(
      root: updated,
      screens: screens,
      isDirty: true,
      clearError: true,
    );
    await save();
    if (value) {
      await _clearInitialFlagsExcept(screenId);
    }
  }

  Future<void> _clearInitialFlagsExcept(String screenId) async {
    final repository = ref.read(projectScreenRepositoryProvider);
    final changed = <ProjectScreen>[];
    for (final screen in state.screens) {
      if (screen.id == screenId) {
        continue;
      }
      final canvas = screen.canvas;
      if (canvas == null || canvas.properties['initial'] != true) {
        continue;
      }
      final cleared = canvas.withProperty(canvas.id, 'initial', false);
      final updated = ProjectScreen(
        id: screen.id,
        projectId: screen.projectId,
        name: screen.name,
        position: screen.position,
        canvas: cleared,
      );
      changed.add(updated);
      try {
        await repository.saveCanvas(screenId: screen.id, root: cleared);
      } on Object {
        // La limpieza visual no debe bloquear el cambio de pantalla inicial.
      }
    }
    if (changed.isEmpty) {
      return;
    }
    final byId = {for (final screen in changed) screen.id: screen};
    state = state.copyWith(
      screens: [
        for (final screen in state.screens) byId[screen.id] ?? screen,
      ],
    );
  }

  /// Migra raíces antiguas (`column`/`container`) al nodo `screen`.  ///
  /// Conserva hijos y `gap` para no alterar el diseño existente. Las pantallas
  /// nuevas ya nacen con `screen`.
  CanvasNode _normalizeRoot(CanvasNode root) {
    if (root.type == 'screen') {
      return root;
    }
    return CanvasNode(
      id: root.id,
      type: 'screen',
      properties: {
        'device': 'phone',
        'scroll': true,
        'padding': 16,
        'gap': (root.properties['gap'] as num?)?.toDouble() ?? 12,
      },
      children: root.children,
    );
  }

  /// Renombra la pantalla activa (nombre de archivo).
  Future<void> renameScreen(String name) async {
    final screenId = state.screenId;
    final clean = name.trim();
    if (screenId == null || clean.isEmpty) {
      return;
    }

    final result = await ref
        .read(projectScreenRepositoryProvider)
        .rename(screenId: screenId, name: clean);

    state = switch (result) {
      Ok() => state.copyWith(
        screenName: clean,
        screens: [
          for (final screen in state.screens)
            if (screen.id == screenId)
              ProjectScreen(
                id: screen.id,
                projectId: screen.projectId,
                name: clean,
                position: screen.position,
                canvas: screen.canvas,
              )
            else
              screen,
        ],
        clearError: true,
      ),
      Err(:final failure) => state.copyWith(error: failure.message),
    };
  }

  /// Cambia de pantalla, guardando antes los cambios pendientes.
  Future<void> selectScreen(String screenId) async {
    if (state.screenId == screenId) {
      return;
    }

    ProjectScreen? target;
    for (final screen in state.screens) {
      if (screen.id == screenId) {
        target = screen;
        break;
      }
    }
    if (target == null) {
      return;
    }

    if (state.isDirty) {
      await save();
    }
    if (state.screenId == screenId) {
      return;
    }

    state = state.copyWith(
      screenId: target.id,
      screenName: target.name,
      root: _normalizeRoot(target.canvas ?? _defaultRoot()),
      isDirty: false,
      clearSelection: true,
      clearError: true,
    );
  }

  /// Crea una pantalla nueva y la activa.
  Future<void> createScreen() async {
    final name = 'pantalla_${state.screens.length + 1}.dart';
    await _createScreen(name: name, root: _defaultRoot());
  }

  /// Crea una pantalla nueva a partir de una plantilla.
  Future<void> createScreenFromTemplate({
    required String name,
    required CanvasNode root,
  }) async {
    var candidate = name;
    var suffix = 2;
    while (state.screens.any(
      (screen) => screen.name.toLowerCase() == candidate.toLowerCase(),
    )) {
      final base = name.replaceAll('.dart', '');
      candidate = '${base}_$suffix.dart';
      suffix++;
    }
    await _createScreen(name: candidate, root: root);
  }

  Future<void> _createScreen({
    required String name,
    required CanvasNode root,
  }) async {
    final projectId = state.projectId;
    if (projectId == null) {
      return;
    }

    if (state.isDirty) {
      await save();
    }

    final position = state.screens.isEmpty
        ? 0
        : state.screens
                  .map((screen) => screen.position)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    final result = await ref
        .read(projectScreenRepositoryProvider)
        .create(
          projectId: projectId,
          name: name,
          position: position,
          root: root,
        );

    state = switch (result) {
      Ok(:final value) => state.copyWith(
        screens: root.properties['initial'] == true
            ? [value, ...state.screens]
            : [...state.screens, value],
        screenId: value.id,
        screenName: value.name,
        root: root,
        isDirty: false,
        clearSelection: true,
        clearError: true,
      ),
      Err(:final failure) => state.copyWith(error: failure.message),
    };
    if (root.properties['initial'] == true && state.screenId != null) {
      await _clearInitialFlagsExcept(state.screenId!);
    }
  }

  /// Agrega un componente al final del árbol y lo persiste.
  Future<void> addComponent(String type) async {
    final root = state.root;
    if (root == null) {
      return;
    }
    _insertComponent(type, root.id);
    await save();
  }

  /// Inserta un componente justo antes de [targetId] (o al final si es la raíz).
  ///
  /// Es lo que permite soltar la paleta **entre** controles y no solo al final.
  Future<void> addComponentAt(String type, String targetId) async {
    _insertComponent(type, targetId);
    await save();
  }

  /// Elimina un nodo del árbol (la raíz no se puede eliminar).
  Future<void> removeNode(String nodeId) async {
    final root = state.root;
    if (root == null || nodeId == root.id) {
      return;
    }
    final updated = root.removeById(nodeId);
    if (updated == null) {
      return;
    }

    state = state.copyWith(
      root: updated,
      isDirty: true,
      clearError: true,
      clearSelection: true,
    );
    await save();
  }

  /// Inserta el nodo respetando el slot del componente.
  ///
  /// - `top`/`bottom`/`overlay` van a la raíz de la pantalla, uno por slot.
  /// - los `body` se insertan en el cuerpo (nunca antes de una barra).
  void _insertComponent(String type, String targetId) {
    final root = state.root;
    if (root == null) {
      return;
    }
    final definition = standardCatalog[type];
    if (definition == null || !definition.insertable) {
      return;
    }
    if (definition.requiresFlexParent && !_canHostFlex(root, targetId)) {
      return;
    }

    final child = CanvasNode(
      id: _newId(),
      type: type,
      properties: Map<String, Object?>.from(definition.defaultProperties),
    );

    // Los íconos sueltos sobre la barra inferior se convierten en ítems.
    if (type == 'icon') {
      final target = root.findNode(targetId);
      if (target != null &&
          (target.type == 'bottomNav' || target.type == 'bottomAppBar')) {
        if (target.type == 'bottomAppBar' && type != 'icon') {
          return;
        }
        final updated = root.appendChild(target.id, child);
        if (updated == null) {
          return;
        }
        state = state.copyWith(root: updated, isDirty: true, clearError: true);
        return;
      }
    }

    final slot = definition.slot;
    if (slot != ComponentSlot.body) {
      final alreadyThere = root.children.any(
        (child) => standardCatalog[child.type]?.slot == slot,
      );
      if (alreadyThere) {
        return;
      }
    }

    if (slot != ComponentSlot.body) {
      final fixed = root.appendChild(root.id, child);
      if (fixed == null) {
        return;
      }
      state = state.copyWith(root: fixed, isDirty: true, clearError: true);
      return;
    }

    final target = root.findNode(targetId);
    if (target != null) {
      final targetSlot =
          standardCatalog[target.type]?.slot ?? ComponentSlot.body;
      if (targetSlot == ComponentSlot.top) {
        // En la barra superior solo entran íconos (acciones).
        if (type != 'icon') {
          return;
        }
      } else if (targetSlot != ComponentSlot.body) {
        return;
      }
    }

    final updated = _place(root, targetId, child);
    if (updated == null) {
      return;
    }

    state = state.copyWith(root: updated, isDirty: true, clearError: true);
  }

  bool _isFlexType(String type) => type == 'row' || type == 'column';

  CanvasNode? _parentOf(CanvasNode node, String id) {
    for (final child in node.children) {
      if (child.id == id) {
        return node;
      }
      final found = _parentOf(child, id);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// `true` si [targetId] puede hospedar Expanded/Flexible/Spacer.
  bool _canHostFlex(CanvasNode root, String targetId) {
    final target = root.findNode(targetId);
    if (target != null) {
      final definition = standardCatalog[target.type];
      if (definition != null && definition.acceptsChildren) {
        return _isFlexType(target.type);
      }
    }
    final parent = _parentOf(root, targetId);
    return parent != null && _isFlexType(parent.type);
  }

  /// Coloca [node] dentro de [targetId] si es un contenedor; si no, antes de él.
  CanvasNode? _place(CanvasNode root, String targetId, CanvasNode node) {    final target = root.findNode(targetId);
    if (target != null &&
        (standardCatalog[target.type]?.acceptsChildren ?? false)) {
      return root.appendChild(targetId, node);
    }
    if (targetId == root.id) {
      return root.appendChild(root.id, node);
    }
    return root.insertBefore(targetId, node);
  }

  /// Persiste el árbol actual.
  Future<void> save() async {
    _saveTimer?.cancel();
    _saveTimer = null;

    final screenId = state.screenId;
    final root = state.root;
    if (screenId == null || root == null) {
      return;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final result = await ref
          .read(projectScreenRepositoryProvider)
          .saveCanvas(screenId: screenId, root: root);

      state = switch (result) {
        Ok() => state.copyWith(
          isSaving: false,
          isDirty: false,
          // Mantiene sincronizada la lista en memoria: al volver a esta
          // pantalla se carga el árbol recién guardado, no el viejo.
          screens: [
            for (final screen in state.screens)
              if (screen.id == screenId)
                ProjectScreen(
                  id: screen.id,
                  projectId: screen.projectId,
                  name: screen.name,
                  position: screen.position,
                  canvas: root,
                )
              else
                screen,
          ],
        ),
        Err(:final failure) => state.copyWith(
          isSaving: false,
          error: failure.message,
        ),
      };
    } on Object {
      state = state.copyWith(
        isSaving: false,
        error: 'No se pudo guardar el lienzo.',
      );
    }
  }

  Future<void> _createDefaultScreen(
    Project project,
    ProjectScreenRepository repository,
  ) async {
    final root = _defaultRoot();
    final created = await repository.create(
      projectId: project.id,
      name: 'main.dart',
      position: 0,
      root: root,
    );

    state = switch (created) {
      Ok(:final value) => EditorState(
        projectId: project.id,
        screens: [value],
        screenId: value.id,
        screenName: value.name,
        root: root,
        theme: project.theme,
      ),
      Err(:final failure) => EditorState(
        projectId: project.id,
        error: failure.message,
      ),
    };
  }

  /// Árbol inicial de una pantalla nueva.
  CanvasNode _defaultRoot() {
    return CanvasNode(
      id: _newId(),
      type: 'screen',
      properties: const {
        'device': 'phone',
        'scroll': true,
        'padding': 16,
        'gap': 12,
      },
      children: const [],
    );
  }

  static int _sequence = 0;

  /// Id local único para nodos nuevos.
  static String _newId() {
    _sequence++;
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return 'n$stamp$_sequence';
  }
}

/// Sesión de edición activa.
final editorSessionProvider = NotifierProvider<EditorSession, EditorState>(
  EditorSession.new,
);
