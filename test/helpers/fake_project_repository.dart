import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/projects/domain/project.dart';
import 'package:modeladorflutter/features/projects/domain/project_repository.dart';
import 'package:modeladorflutter/features/projects/domain/project_theme.dart';

/// Doble de pruebas de [ProjectRepository].
class FakeProjectRepository implements ProjectRepository {
  /// Crea el doble con una lista inicial y errores opcionales.
  FakeProjectRepository({
    List<Project>? initial,
    this.listError,
    this.createError,
  }) : _projects = [...?initial];

  final List<Project> _projects;

  /// Si no es `null`, `list` devuelve este fallo.
  Failure? listError;

  /// Si no es `null`, `create` devuelve este fallo.
  Failure? createError;

  /// Veces que se listó.
  int listCalls = 0;

  /// Veces que se intentó crear.
  int createCalls = 0;

  /// Veces que se guardó el tema.
  int saveThemeCalls = 0;

  /// Veces que se eliminó un proyecto.
  int deleteCalls = 0;

  /// Último tema guardado.
  ProjectTheme? lastTheme;

  /// Proyectos actuales (copia).
  List<Project> get projects => List.unmodifiable(_projects);

  @override
  Future<Result<List<Project>>> list() async {
    listCalls++;
    final error = listError;
    if (error != null) {
      return Err(error);
    }
    return Ok(List.unmodifiable(_projects));
  }

  @override
  Future<Result<Project>> create({required String name}) async {
    createCalls++;
    final error = createError;
    if (error != null) {
      return Err(error);
    }

    final project = Project(
      id: 'p-${_projects.length + 1}',
      name: name,
      createdAt: DateTime.utc(2026, 11, 7),
    );
    _projects.insert(0, project);
    return Ok(project);
  }

  @override
  Future<Result<void>> saveTheme({
    required String projectId,
    required ProjectTheme theme,
  }) async {
    saveThemeCalls++;
    lastTheme = theme;
    final index = _projects.indexWhere((project) => project.id == projectId);
    if (index >= 0) {
      final current = _projects[index];
      _projects[index] = Project(
        id: current.id,
        name: current.name,
        createdAt: current.createdAt,
        theme: theme,
      );
    }
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String projectId) async {
    deleteCalls++;
    _projects.removeWhere((project) => project.id == projectId);
    return const Ok(null);
  }
}
