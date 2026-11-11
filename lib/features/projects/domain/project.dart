import 'project_theme.dart';

/// Proyecto del modelador, en el vocabulario del dominio.
///
/// No expone tipos de Supabase ni el `owner_id`: el dueño lo garantiza RLS y
/// la UI nunca necesita mostrarlo.
class Project {
  /// Crea un proyecto.
  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    this.theme = const ProjectTheme(),
  });

  /// Identificador (`tenant_app.projects.id`).
  final String id;

  /// Nombre visible (1–120 caracteres, validado en la base).
  final String name;

  /// Fecha de creación.
  final DateTime createdAt;

  /// Tema visual del proyecto.
  final ProjectTheme theme;

  /// Construye el modelo a partir de una fila de PostgREST.
  factory Project.fromJson(Map<String, dynamic> json) {
    final theme = json['theme'];
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      theme: theme is Map<String, dynamic>
          ? ProjectTheme.fromJson(theme)
          : const ProjectTheme(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Project &&
      other.id == id &&
      other.name == name &&
      other.createdAt == createdAt &&
      other.theme == theme;

  @override
  int get hashCode => Object.hash(id, name, createdAt, theme);

  @override
  String toString() => 'Project($id, $name)';
}
