import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/editor/domain/canvas_node.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen.dart';
import 'package:modeladorflutter/features/editor/domain/project_screen_repository.dart';

/// Doble de pruebas de [ProjectScreenRepository].
class FakeProjectScreenRepository implements ProjectScreenRepository {
  /// Crea el doble con pantallas iniciales.
  FakeProjectScreenRepository({List<ProjectScreen>? screens})
    : screens = [...?screens];

  /// Pantallas en memoria.
  final List<ProjectScreen> screens;

  /// Errores inyectables.
  Failure? listError;
  Failure? createError;
  Failure? saveError;

  /// Contadores e inspección.
  int listCalls = 0;
  int createCalls = 0;
  int saveCalls = 0;
  int renameCalls = 0;
  CanvasNode? lastSaved;
  String? lastSavedScreenId;

  @override
  Future<Result<List<ProjectScreen>>> listForProject(String projectId) async {
    listCalls++;
    final error = listError;
    if (error != null) {
      return Err(error);
    }
    final items = screens.where((s) => s.projectId == projectId).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return Ok(items);
  }

  @override
  Future<Result<ProjectScreen>> create({
    required String projectId,
    required String name,
    required int position,
    required CanvasNode root,
  }) async {
    createCalls++;
    final error = createError;
    if (error != null) {
      return Err(error);
    }
    final screen = ProjectScreen(
      id: 's-${screens.length + 1}',
      projectId: projectId,
      name: name,
      position: position,
      canvas: root,
    );
    screens.add(screen);
    return Ok(screen);
  }

  @override
  Future<Result<void>> saveCanvas({
    required String screenId,
    required CanvasNode root,
  }) async {
    saveCalls++;
    lastSaved = root;
    lastSavedScreenId = screenId;
    final error = saveError;
    if (error != null) {
      return Err(error);
    }

    final index = screens.indexWhere((screen) => screen.id == screenId);
    if (index >= 0) {
      final screen = screens[index];
      screens[index] = ProjectScreen(
        id: screen.id,
        projectId: screen.projectId,
        name: screen.name,
        position: screen.position,
        canvas: root,
      );
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> rename({
    required String screenId,
    required String name,
  }) async {
    renameCalls++;
    final index = screens.indexWhere((screen) => screen.id == screenId);
    if (index >= 0) {
      final screen = screens[index];
      screens[index] = ProjectScreen(
        id: screen.id,
        projectId: screen.projectId,
        name: name,
        position: screen.position,
        canvas: screen.canvas,
      );
    }
    return const Ok(null);
  }
}
