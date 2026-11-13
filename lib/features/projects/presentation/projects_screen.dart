import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modeladorflutter/core/result.dart';
import 'package:modeladorflutter/features/auth/application/auth_providers.dart';
import 'package:modeladorflutter/features/auth/domain/auth_user.dart';

import '../application/projects_controller.dart';
import '../../admin/application/admin_providers.dart';
import '../domain/project.dart';
import '../../editor/presentation/editor_screen.dart';
import '../../admin/presentation/admin_screen.dart';
import '../../../app/app_theme.dart';

/// Claves usadas por los tests de la pantalla.
abstract final class ProjectsKeys {
  /// Acción de cerrar sesión.
  static const Key logout = Key('projects.logout');

  /// Botón flotante "Nuevo proyecto".
  static const Key newProject = Key('projects.new');

  /// Botón de estado vacío para crear el primero.
  static const Key newProjectEmpty = Key('projects.new_empty');

  /// Campo de nombre en el diálogo.
  static const Key dialogName = Key('projects.dialog.name');

  /// Confirmar creación en el diálogo.
  static const Key dialogCreate = Key('projects.dialog.create');

  /// Confirmar eliminación en el diálogo.
  static const Key dialogDelete = Key('projects.dialog.delete');

  /// Botón de eliminar de un proyecto.
  static Key deleteFor(String id) => ValueKey<String>('projects.delete.$id');

  /// Lista de proyectos.
  static const Key list = Key('projects.list');

  /// Estado de error.
  static const Key error = Key('projects.error');

  /// Botón reintentar del estado de error.
  static const Key retry = Key('projects.retry');

  /// Clave de la tarjeta de un proyecto concreto.
  static Key tileFor(String id) => ValueKey<String>('projects.tile.$id');
}

/// Listado de proyectos del usuario.
///
/// Los datos vienen de `tenant_app.projects`; RLS garantiza que solo se vean
/// los del usuario autenticado, así que la pantalla no filtra nada.
class ProjectsScreen extends ConsumerStatefulWidget {
  /// Crea la pantalla para [user].
  const ProjectsScreen({required this.user, super.key});

  /// Usuario autenticado; lo inyecta [AuthGate].
  final SessionUser user;

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  int _section = 0;
  bool _isAdmin = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAdmin();
  }

  Future<void> _loadAdmin() async {
    final result = await ref.read(adminRepositoryProvider).isAdmin();
    if (!mounted) {
      return;
    }
    if (result case Ok(value: final value)) {
      setState(() => _isAdmin = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsControllerProvider);
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final content = switch (projects) {
      AsyncData(:final value) => value.isEmpty
          ? _EmptyState(
              user: widget.user,
              onCreate: () => _createProject(context, ref),
            )
          : _ProjectList(
              projects: value,
              onCreate: () => _createProject(context, ref),
            ),
      AsyncError(:final error) => _ErrorState(
        message: error is Failure
            ? error.message
            : 'No se pudieron cargar tus proyectos.',
        onRetry: () => ref.read(projectsControllerProvider.notifier).reload(),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
    final body = _section <= 1
        ? content
        : _ComingSoon(
            section: _section,
            onGoProjects: () => setState(() => _section = 1),
          );
    void openAdmin() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminScreen()),
    );
    void selectSection(int index) {
      if (index == 5) {
        openAdmin();
        return;
      }
      setState(() => _section = index);
    }
    void logout() => ref.read(authRepositoryProvider).signOut();

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: _DashboardSidebar(
                  section: _section,
                  user: widget.user,
                  showAdmin: _isAdmin,
                  onSelect: (index) {
                    Navigator.of(context).pop();
                    if (index == 5) {
                      openAdmin();
                    } else {
                      selectSection(index);
                    }
                  },
                  onLogout: logout,
                ),
              ),
            ),
      appBar: AppBar(
        leading: wide
            ? null
            : IconButton(
                tooltip: 'Secciones',
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        titleSpacing: 12,
        title: wide
            ? Text(
                const [
                  'Inicio',
                  'Mis Proyectos',
                  'Recursos',
                  'Configuración',
                  'Ayuda',
                ][_section.clamp(0, 4)],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textStrong,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.widgets_rounded,
                      size: 18,
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
            const SizedBox(width: 10),
            const Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Flutter Studio Apps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textStrong,
                    ),
                  ),
                  Text(
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
        ),
        actions: [
          IconButton(
            key: ProjectsKeys.logout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      floatingActionButton: _section <= 1
          ? FloatingActionButton.extended(
              key: ProjectsKeys.newProject,
              onPressed: () => _createProject(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo proyecto'),
            )
          : null,
      body: wide
          ? Row(
              children: [
                _DashboardSidebar(
                  section: _section,
                  user: widget.user,
                  showAdmin: _isAdmin,
                  onSelect: selectSection,
                  onLogout: logout,
                ),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }

  /// Abre el diálogo de creación y, si se confirma, crea el proyecto.
  Future<void> _createProject(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewProjectDialog(),
    );

    if (name == null || name.isEmpty || !context.mounted) {
      return;
    }

    final result = await ref
        .read(projectsControllerProvider.notifier)
        .create(name: name);

    if (result is Err && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.failure.message)));
    }
  }
}

/// Diálogo para nombrar el proyecto.
///
/// Es un [StatefulWidget] propio porque **es dueño** del
/// `TextEditingController`: destruirlo desde el llamador mientras la ruta aún
/// se anima provoca "used after being disposed".
class _NewProjectDialog extends StatefulWidget {
  const _NewProjectDialog();

  @override
  State<_NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<_NewProjectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo proyecto'),
      content: TextField(
        key: ProjectsKeys.dialogName,
        controller: _controller,
        autofocus: true,
        maxLength: 120,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(labelText: 'Nombre'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: ProjectsKeys.dialogCreate,
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

/// Lista de proyectos.
class _ProjectList extends ConsumerStatefulWidget {
  const _ProjectList({required this.projects, required this.onCreate});

  final List<Project> projects;
  final VoidCallback onCreate;

  @override
  ConsumerState<_ProjectList> createState() => _ProjectListState();
}

class _ProjectListState extends ConsumerState<_ProjectList> {
  String _query = '';
  bool _grid = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final projects = widget.projects
        .where((project) => query.isEmpty || project.name.toLowerCase().contains(query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(context),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
          child: Text(
            'Mis Proyectos',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.textStrong,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar proyecto…',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.grid_view, size: 16),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.view_list, size: 16),
                  ),
                ],
                selected: {_grid},
                showSelectedIcon: false,
                onSelectionChanged: (value) =>
                    setState(() => _grid = value.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1500
                  ? 4
                  : width >= 1100
                  ? 3
                  : width >= 700
                  ? 2
                  : 1;
              if (_grid) {
                return GridView.builder(
                  key: ProjectsKeys.list,
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) =>
                      _card(context, projects[index], compact: columns < 3),
                );
              }
              return ListView.separated(
                key: ProjectsKeys.list,
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 96),
                itemCount: projects.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _card(context, projects[index], compact: columns < 3),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B5F59), Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Tu plataforma de desarrollo',
                    style: TextStyle(fontSize: 10.5, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Flutter Studio Apps',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gestiona tus proyectos, desarrolla aplicaciones '
                  'increíbles con Flutter y Dart.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xD9FFFFFF),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: widget.onCreate,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                  ),
                  icon: const Icon(Icons.rocket_launch_outlined, size: 17),
                  label: const Text('Nuevo Proyecto'),
                ),
              ],
            ),
          ),
          if (wide) ...[
            const SizedBox(width: 24),
            Icon(
              Icons.phone_iphone_rounded,
              size: 110,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    Project project, {
    bool compact = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: ProjectsKeys.tileFor(project.id),
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context, project),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.widgets_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textStrong,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _tag('Flutter'),
                        _tag('Dart'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Creado el ${_formatDate(project.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: ProjectsKeys.deleteFor(project.id),
                    tooltip: 'Eliminar proyecto',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _confirmDelete(context, ref, project),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.tonal(
                    onPressed: () => _open(context, project),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(fontSize: 11.5),
                    ),
                    child: Text(compact ? 'Abrir' : 'Abrir en Modelador'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.primarySoft,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        color: AppTheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _open(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(project: project),
      ),
    );
  }

  /// Pide confirmación y elimina el proyecto.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar proyecto?'),
        content: Text(
          'Se eliminará «${project.name}» y todas sus pantallas. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: ProjectsKeys.dialogDelete,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final result = await ref
        .read(projectsControllerProvider.notifier)
        .delete(project.id);

    if (result case Err(:final failure)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      }
    }
  }

  /// Formato simple dd/mm/aaaa (sin dependencia de `intl`).
  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// Estado sin proyectos.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.user, required this.onCreate});

  final SessionUser user;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Aún no tienes proyectos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              key: ProjectsKeys.newProjectEmpty,
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear tu primer proyecto'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado de error con reintento.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      key: ProjectsKeys.error,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: scheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              key: ProjectsKeys.retry,
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marca cuadrada de Flutter Studio Apps.
class _AppMark extends StatelessWidget {
  const _AppMark({this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Icon(
              Icons.widgets_rounded,
              size: size * 0.52,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: const Color(0xFFFACC15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel lateral del dashboard.
class _DashboardSidebar extends StatelessWidget {
  const _DashboardSidebar({
    required this.section,
    required this.user,
    required this.showAdmin,
    required this.onSelect,
    required this.onLogout,
  });

  final int section;
  final SessionUser user;
  final bool showAdmin;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  static const _items = [
    (Icons.home_rounded, 'Inicio'),
    (Icons.folder_outlined, 'Mis Proyectos'),
    (Icons.menu_book_outlined, 'Recursos'),
    (Icons.settings_outlined, 'Configuración'),
    (Icons.help_outline, 'Ayuda'),
    (Icons.admin_panel_settings_outlined, 'Administración'),
  ];

  @override
  Widget build(BuildContext context) {
    final initials = user.email.length >= 2
        ? user.email.substring(0, 2).toUpperCase()
        : 'FS';
    final visibleItems = showAdmin ? _items : _items.sublist(0, 5);

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
            child: Row(
              children: [
                const _AppMark(size: 36),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flutter Studio Apps',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textStrong,
                        ),
                      ),
                      Text(
                        'Diseña • Crea • Innova',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < visibleItems.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: index == section
                    ? AppTheme.primarySoft
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(index),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 20,
                          decoration: BoxDecoration(
                            color: index == section
                                ? AppTheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Icon(
                          visibleItems[index].$1,
                          size: 18,
                          color: index == section
                              ? AppTheme.primary
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            visibleItems[index].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: index == section
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: index == section
                                  ? AppTheme.primary
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primarySoft,
                    const Color(0xFFE6FFFB),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AppMark(size: 30),
                  const SizedBox(height: 8),
                  const Text(
                    'Flutter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textStrong,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Build beautiful apps for everyone',
                    style: TextStyle(
                      fontSize: 9.5,
                      height: 1.3,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppTheme.primary,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: const Icon(
                Icons.logout,
                size: 17,
                color: AppTheme.textMuted,
              ),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              onTap: onLogout,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Sección en construcción.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.section, required this.onGoProjects});

  final int section;
  final VoidCallback onGoProjects;

  static const _titles = [
    'Inicio',
    'Mis Proyectos',
    'Recursos',
    'Configuración',
    'Ayuda',
  ];

  @override
  Widget build(BuildContext context) {
    final title = _titles[section.clamp(0, _titles.length - 1)];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _AppMark(size: 64),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'En construcción',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Estamos trabajando en esta sección. Muy pronto vas a '
              'poder usarla.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            FilledButton.tonal(
              onPressed: onGoProjects,
              child: const Text('Ir a Mis Proyectos'),
            ),
          ],
        ),
      ),
    );
  }
}
